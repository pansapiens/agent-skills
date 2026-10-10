#!/usr/bin/env python3
# /// script
# dependencies = ["pynostr"]
# ///
"""buzz-invite.py - mint and claim Buzz relay invites over the REST API.

No SSH to the relay host is needed. Both calls are NIP-98-signed POSTs:

  mint   <admin-env> [--ttl SECS] [--max-uses N]
         POST /api/invites as an owner/admin identity. Prints the invite JSON
         ({code, url, expires_at, max_uses, uses_remaining}).
  claim  <env> <invite-url-or-code> [--relay-url URL]
         POST /api/invites/claim as the joining identity. If <env> does not
         exist, a fresh keypair is generated and written there first (mode
         600), so a subagent can self-register with one command.
  keygen <env> --relay-url URL
         Write a fresh identity env file (mode 600) and print its pubkey.

Env files use the skill's format (BUZZ_RELAY_URL, BUZZ_PRIVATE_KEY). The
private key is never printed. Run with `uv run buzz-invite.py ...` or any
python that has pynostr installed (e.g. ~/.local/share/buzz/venv).
"""
import argparse
import base64
import hashlib
import json
import os
import sys
import urllib.error
import urllib.request
import uuid
from urllib.parse import urlparse

from pynostr.event import Event
from pynostr.key import PrivateKey


def read_env(path):
    env = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip().strip("'\"")
    return env


def load_key(raw):
    return PrivateKey.from_nsec(raw) if raw.startswith("nsec") else PrivateKey.from_hex(raw)


def http_base(relay_url):
    """https://host from wss://host, https://host or a bare host."""
    u = urlparse(relay_url if "://" in relay_url else f"https://{relay_url}")
    scheme = "http" if u.scheme in ("ws", "http") else "https"
    return f"{scheme}://{u.netloc}"


def write_env(path, relay_url, key):
    os.makedirs(os.path.dirname(os.path.abspath(path)), mode=0o700, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(f"BUZZ_RELAY_URL={http_base(relay_url)}\nBUZZ_PRIVATE_KEY={key.bech32()}\n")


def post(base, path, key, payload):
    """NIP-98 signed POST: u = exact URL, payload = sha256(body)."""
    url = base + path
    body = json.dumps(payload).encode()
    ev = Event(kind=27235, content="", tags=[
        ["u", url], ["method", "POST"],
        ["payload", hashlib.sha256(body).hexdigest()], ["nonce", str(uuid.uuid4())],
    ])
    ev.sign(key.hex())
    auth = "Nostr " + base64.b64encode(json.dumps(ev.to_dict()).encode()).decode()
    req = urllib.request.Request(url, data=body, method="POST", headers={
        "Authorization": auth, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"buzz-invite: {path} -> HTTP {e.code}: {e.read().decode(errors='replace')}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("mint")
    m.add_argument("env")
    m.add_argument("--ttl", type=int, help="lifetime in seconds (relay default 72h)")
    m.add_argument("--max-uses", type=int, help="uses before exhaustion (default unlimited)")
    c = sub.add_parser("claim")
    c.add_argument("env")
    c.add_argument("invite", help="invite URL (https://host/invite/CODE) or bare code")
    c.add_argument("--relay-url", help="needed with a bare code when <env> does not exist")
    g = sub.add_parser("keygen")
    g.add_argument("env")
    g.add_argument("--relay-url", required=True)
    a = p.parse_args()

    if a.cmd == "keygen":
        key = PrivateKey()
        write_env(a.env, a.relay_url, key)
        print(json.dumps({"env": a.env, "pubkey": key.public_key.hex(), "npub": key.public_key.bech32()}))
        return

    if a.cmd == "mint":
        env = read_env(a.env)
        req = {k: v for k, v in (("ttl_secs", a.ttl), ("max_uses", a.max_uses)) if v is not None}
        print(json.dumps(post(http_base(env["BUZZ_RELAY_URL"]), "/api/invites",
                              load_key(env["BUZZ_PRIVATE_KEY"]), req)))
        return

    # claim
    code, relay = a.invite, a.relay_url
    if "/invite/" in code:
        relay = relay or code.split("/invite/")[0]
        code = code.rsplit("/invite/", 1)[1].strip("/")
    if not os.path.exists(a.env):
        if not relay:
            sys.exit("buzz-invite: <env> does not exist; pass an invite URL or --relay-url")
        write_env(a.env, relay, PrivateKey())
    env = read_env(a.env)
    key = load_key(env["BUZZ_PRIVATE_KEY"])
    result = post(http_base(relay or env["BUZZ_RELAY_URL"]), "/api/invites/claim", key, {"code": code})
    print(json.dumps({**result, "pubkey": key.public_key.hex(), "env": a.env}))


if __name__ == "__main__":
    main()
