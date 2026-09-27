#!/usr/bin/env python3
"""buzz-listen - realtime Buzz relay listener (receive-only daemon).

Emits one `BUZZ {json}` line per message that needs the agent's attention:
  * mentions this identity (a `p` tag equal to our pubkey)
  * lands in a DM channel
  * replies to a thread this identity has already posted in (an `e`/thread
    reference to one of our own messages) - even without a fresh @-mention
  * optionally: EVERY message in the channels we are a member of, so the
    agent can engage in an active channel (`--watch-channels`; throttled
    per-channel to avoid waking on every single message)

Everything else (logs) goes to stderr, so a stream-matching monitor only
wakes on real signal. Each emitted line carries a `"reason"` field
(`mention` | `dm` | `thread` | `watch`) so the agent knows why it woke.

Usage:
    buzz-listen.py <env-file> [--watch-channels] [--test seconds]

The env file defines BUZZ_RELAY_URL + BUZZ_PRIVATE_KEY (same as the skill).
Channel discovery happens at startup and on every reconnect via the `buzz`
CLI. Messages are kind 9 (channel stream messages). To detect replies to our
own messages, recent per-channel messages are scanned at startup and our own
post ids tracked live.

Sending is deliberately NOT handled here - reply using the `buzz` CLI
(`scripts/buzz.sh`), which signs, threads, and mention-tags correctly.
"""
import asyncio
import json
import os
import random
import signal
import subprocess
import sys
import time

RELAY_URL = os.environ.get("BUZZ_RELAY_URL", "")
PRIV_KEY = os.environ.get("BUZZ_PRIVATE_KEY", "")
MY_PUBKEY = os.environ.get("BUZZ_MY_PUBKEY", "")  # filled by main()

KIND_CHANNEL_MSG = 9
KIND_AUTH = 22242

WATCH_ALL = "--watch-channels" in sys.argv  # emit every channel message


def _opt_value(flag):
    return sys.argv[sys.argv.index(flag) + 1] if flag in sys.argv else None


# Channel names or UUIDs to skip during discovery (comma-separated).
IGNORE_CHANNELS = set((_opt_value("--ignore-channels") or "").replace(" ", "").split(",")) - {""}
WATCH_COOLDOWN = 15  # seconds between watch-only emits per channel
SELF_IDS = set()  # ids of messages we authored, for thread-reply detection
_watch_last = {}  # last watch-only emit time per channel id
_conn_state = {"frames": 0, "events": 0, "last_frame": 0.0}
# Force reconnect if no WS frame at all for this long (quiet channels send
# nothing; a dead NAT/proxy that still answers pings would otherwise hang
# forever). Each reconnect has a ~5s since-window gap, so keep this coarse.
STALE_AFTER_SECS = 1800


def log(*a):
    print("buzz-listen:", *a, file=sys.stderr, flush=True)


def die(msg):
    log("FATAL:", msg)
    sys.exit(1)


def bech32_decode_nsec(s):
    CHARS = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
    pos = s.rfind("1")
    words = [CHARS.index(c) for c in s[pos + 1:]][:-6]
    acc = bits = 0
    out = bytearray()
    for w in words:
        acc = (acc << 5) | w
        bits += 5
        while bits >= 8:
            bits -= 8
            out.append((acc >> bits) & 0xFF)
    return bytes(out).hex()


# --- signing -----------------------------------------------------------
_KEY = {}


def signer():
    if not _KEY:
        from pynostr.key import PrivateKey

        raw = PRIV_KEY.strip()
        if raw.startswith("nsec"):
            raw = bech32_decode_nsec(raw)
        _KEY["pk"] = PrivateKey(bytes.fromhex(raw))
        _KEY["hex"] = raw
    return _KEY["pk"], _KEY["hex"]


def sign_auth_event(challenge, relay_ws_url):
    from pynostr.event import Event

    pk, priv_hex = signer()
    ev = Event(kind=KIND_AUTH, content="")
    ev.created_at = int(time.time())
    ev.pubkey = pk.public_key.hex()
    ev.tags = [["relay", relay_ws_url], ["challenge", challenge]]
    ev.sign(priv_hex)
    return {
        "id": ev.id, "pubkey": ev.pubkey, "created_at": ev.created_at,
        "kind": ev.kind, "tags": ev.tags, "content": ev.content, "sig": ev.sig,
    }


# --- discovery via the buzz CLI ----------------------------------------
BUZZ_BIN = None


def find_buzz():
    global BUZZ_BIN
    if BUZZ_BIN:
        return BUZZ_BIN
    from shutil import which
    for cand in (which("buzz"), os.path.expanduser("~/.local/bin/buzz"), "/usr/local/bin/buzz"):
        if cand and os.access(cand, os.X_OK):
            BUZZ_BIN = cand
            return BUZZ_BIN
    die("buzz CLI not found on PATH or ~/.local/bin")


def buzz(*args):
    out = subprocess.run(
        [find_buzz(), *args], capture_output=True, text=True, timeout=30,
    )
    if out.returncode != 0:
        raise RuntimeError(f"buzz {' '.join(args)}: {out.stderr.strip()[:200]}")
    return json.loads(out.stdout)


async def query_added_channels():
    """Query kind 44100 (relay-signed member-added notifications, #p = me).

    The relay never publishes kind 41001 DM confirmations, so `buzz dms list`
    always returns empty. 44100 carries the real channel UUID in its h-tag for
    every channel/DM I was added to (both directions), making it the reliable
    discovery source for DM channels.
    """
    import websockets

    ws_url = RELAY_URL.replace("https://", "wss://").replace("http://", "ws://")
    pk, _ = signer()
    me = pk.public_key.hex()
    found = set()
    loop = asyncio.get_event_loop()
    async with websockets.connect(ws_url, ping_interval=20) as ws:
        authed = False
        deadline = loop.time() + 15
        while loop.time() < deadline:
            try:
                raw = await asyncio.wait_for(
                    ws.recv(), timeout=max(0.1, deadline - loop.time()))
            except asyncio.TimeoutError:
                break
            msg = json.loads(raw)
            typ = msg[0] if msg else ""
            if typ == "AUTH" and not authed:
                ev = sign_auth_event(msg[1], ws_url)
                await ws.send(json.dumps(["AUTH", ev]))
            elif typ == "OK" and not authed and len(msg) > 2 and msg[2]:
                authed = True
                await ws.send(json.dumps(["REQ", "dm-disc",
                                          {"kinds": [44100], "#p": [me], "limit": 50}]))
            elif typ == "EVENT":
                tags = (msg[2] if len(msg) > 2 else {}).get("tags", [])
                h = next((t[1] for t in tags
                          if t and t[0] == "h" and len(t) > 1), None)
                if h:
                    found.add(h)
            elif typ == "EOSE":
                break
    return found


async def discover():
    chans = buzz("channels", "list")
    ids = []
    names = {}
    for c in chans or []:
        cid = c.get("channel_id") or c.get("id")
        if not cid:
            continue
        name = c.get("name", "?")
        if name in IGNORE_CHANNELS or cid in IGNORE_CHANNELS:
            log(f"ignoring channel {name} ({cid[:8]}) per --ignore-channels")
            continue
        ids.append(cid)
        names[cid] = name
    # DMs (and any added channels missing from `channels list`) via 44100.
    try:
        added = await query_added_channels()
    except Exception as e:
        log(f"dm discovery failed: {e!r}")
        added = set()
    dm_ids = set()
    for cid in added:
        if cid in IGNORE_CHANNELS or names.get(cid) in IGNORE_CHANNELS:
            continue
        if cid not in ids:
            ids.append(cid)
            names[cid] = "dm"
        if names.get(cid) == "dm":
            dm_ids.add(cid)
    return ids, dm_ids, names


def seed_self_ids(channel_ids):
    """Collect our own recent message ids so thread replies are recognised."""
    found = set()
    for cid in channel_ids:
        try:
            msgs = buzz("messages", "get", "--channel", cid, "--limit", "20")
        except Exception:
            continue
        for m in msgs or []:
            if m.get("pubkey") == MY_PUBKEY and m.get("id"):
                found.add(m["id"])
    if found:
        log(f"seeded {len(found)} self message id(s) for thread-reply detection")
    return found


# --- websocket loop -----------------------------------------------------
async def run_once(duration=None):
    import websockets

    ws_url = RELAY_URL.replace("https://", "wss://").replace("http://", "ws://")
    channel_ids, dm_ids, names = await discover()
    if not channel_ids:
        die("no channels discovered (is this identity a relay member?)")
    if not SELF_IDS:
        SELF_IDS.update(seed_self_ids(channel_ids))
    log(f"subscribing to {len(channel_ids)} channel(s), {len(dm_ids)} dm(s): "
        + ", ".join(names.get(c, c[:8]) for c in channel_ids))

    started = time.time()
    async with websockets.connect(
        ws_url, ping_interval=20, ping_timeout=20, max_queue=4096
    ) as ws:
        auth_ev_id = None
        authed = False

        async def send_req():
            await ws.send(json.dumps(["REQ", "buzz-listen", {
                "kinds": [KIND_CHANNEL_MSG],
                "#h": channel_ids,
                "since": int(time.time()) - 5,
            }]))

        async def resub():
            # Periodically re-discover channels/DMs so conversations opened
            # after startup (e.g. a new DM) are covered without a reconnect.
            nonlocal channel_ids, dm_ids, names
            while True:
                await asyncio.sleep(300)
                log(f"heartbeat: {_conn_state['frames']} frames / "
                    f"{_conn_state['events']} events, last frame "
                    f"{int(time.time() - _conn_state['last_frame'])}s ago")
                if not authed:
                    continue
                try:
                    new_ids, new_dms, new_names = await discover()
                except Exception as e:
                    log(f"rediscover failed: {e!r}")
                    continue
                if new_ids != channel_ids or new_dms != dm_ids:
                    channel_ids, dm_ids, names = new_ids, new_dms, new_names
                    log(f"channel set changed; re-subscribed to "
                        f"{len(channel_ids)} channel(s)")
                # Always re-REQ: the relay stops delivering to this
                # subscription a few minutes after AUTH even while the socket
                # stays open (observed: events at startup, then silence).
                # A fresh REQ with the same sub id revives delivery.
                await send_req()

        _conn_state.update(frames=0, events=0, last_frame=time.time())
        resub_task = asyncio.create_task(resub())
        try:
            log("connected; waiting for AUTH challenge")
            while True:
                try:
                    raw = await asyncio.wait_for(ws.recv(), timeout=30)
                except asyncio.TimeoutError:
                    # Quiet channels send nothing; only a fully silent socket
                    # (dead NAT/proxy that still answers pings) is a problem.
                    if time.time() - _conn_state["last_frame"] > STALE_AFTER_SECS:
                        log("no WS frames for "
                            f"{int(time.time() - _conn_state['last_frame'])}s; "
                            "forcing reconnect (stale-socket guard)")
                        return
                    continue
                _conn_state["frames"] += 1
                _conn_state["last_frame"] = time.time()
                try:
                    msg = json.loads(raw)
                except json.JSONDecodeError:
                    continue
                typ = msg[0] if msg else ""
                if typ == "AUTH":
                    ev = sign_auth_event(msg[1], ws_url)
                    auth_ev_id = ev["id"]
                    await ws.send(json.dumps(["AUTH", ev]))
                    log("answered AUTH challenge")
                elif typ == "OK" and not authed and auth_ev_id and msg[1] == auth_ev_id:
                    if len(msg) > 2 and msg[2]:
                        authed = True
                        await send_req()
                        log("auth accepted; subscribed; listening")
                    else:
                        die("relay rejected AUTH: " + str(msg[3] if len(msg) > 3 else ""))
                elif typ == "EVENT":
                    _conn_state["events"] += 1
                    ev = msg[2] if len(msg) > 2 else {}
                    tags = ev.get("tags", [])
                    p_tags = {t[1] for t in tags if t[0] == "p" and len(t) > 1}
                    h = next((t[1] for t in tags if t[0] == "h"), None)
                    reason = None
                    if ev.get("pubkey") == MY_PUBKEY:
                        if ev.get("id"):
                            SELF_IDS.add(ev["id"])  # remember for thread detection
                        continue  # our own posts (echo)
                    if MY_PUBKEY in p_tags:
                        reason = "mention"
                    elif h in dm_ids:
                        reason = "dm"
                    elif any(t[0] == "e" and len(t) > 1 and t[1] in SELF_IDS for t in tags):
                        reason = "thread"  # reply to a thread we've posted in
                    elif WATCH_ALL and h:
                        # throttle watch-only emits per channel to cut noise
                        now = time.time()
                        if now - _watch_last.get(h, 0) >= WATCH_COOLDOWN:
                            _watch_last[h] = now
                            reason = "watch"
                    if reason:
                        line = {
                            "channel": h, "channel_name": names.get(h, "?"),
                            "id": ev.get("id"), "pubkey": ev.get("pubkey"),
                            "content": ev.get("content"), "reason": reason,
                            "created_at": ev.get("created_at"), "tags": tags,
                        }
                        print("BUZZ " + json.dumps(line, ensure_ascii=False), flush=True)
                elif typ == "NOTICE":
                    log("relay NOTICE:", msg[1] if len(msg) > 1 else msg)
                elif typ == "CLOSED":
                    reason = msg[1] if len(msg) > 1 else ""
                    log("relay CLOSED:", reason)
                    if "auth-required" in str(reason) and not authed:
                        continue  # REQ not yet sent - waiting on AUTH handshake
                    return
                if duration and time.time() - started > duration:
                    return
        finally:
            resub_task.cancel()


async def main():
    global RELAY_URL, PRIV_KEY, MY_PUBKEY
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return
    env_file = next((a for a in args if not a.startswith("--")), None)
    if not env_file:
        die("usage: buzz-listen.py <env-file> [--watch-channels] [--ignore-channels csv] [--test seconds]")
    test_secs = None
    if "--test" in args:
        test_secs = int(args[args.index("--test") + 1])
    # source env file
    for line in open(env_file):
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        v = v.strip().strip('"').strip("'")
        os.environ.setdefault(k.strip(), v)
    RELAY_URL = os.environ["BUZZ_RELAY_URL"]
    PRIV_KEY = os.environ["BUZZ_PRIVATE_KEY"]
    pk, _ = signer()
    MY_PUBKEY = pk.public_key.hex()

    backoff = 3
    while True:  # noqa
        try:
            if test_secs:
                await run_once(duration=test_secs)
                log("test window elapsed; exiting")
                return
            await run_once()
            backoff = 3  # clean exit (e.g. CLOSED) - reset
        except asyncio.CancelledError:
            log("cancelled")
            return
        except Exception as e:
            log(f"connection error: {e!r}; reconnecting in {backoff}s")
        await asyncio.sleep(backoff + random.uniform(0, 2))
        backoff = min(backoff * 2, 60)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
