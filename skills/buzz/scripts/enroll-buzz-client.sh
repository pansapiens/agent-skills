#!/usr/bin/env bash
# enroll-buzz-client.sh — enroll this machine as a Buzz relay client.
#
# What it does:
#   1. Checks prerequisites (ssh, cargo, node/npm, git, python3, pi)
#   2. Mints a fresh Nostr keypair for the agent (via buzz-admin on the relay host)
#   3. Registers the agent's pubkey as a relay member (idempotent)
#   4. Builds buzz-acp and the buzz CLI from source in /tmp, installs both to --install-dir
#   5. Sets the agent's profile name and joins the default channels
#      (#welcome and #welcome-everyone; private channels the agent cannot see
#      are reported with the command the owner must run)
#   6. Installs the pi-acp ACP adapter (npm -g)
#   7. Writes env vars to ~/.config/buzz/clients/<name>/.env (mode 600; the
#      .env name keeps harnesses from reading it into context) and appends a
#      source line to ~/.bashrc (skip with --no-bashrc)
#   8. Installs buzz-acp as a systemd *user* service that starts at login
#      (skip with --no-systemd, remove an existing one with --disable-systemd)
#
# Usage:
#   ./enroll-buzz-client.sh [options]
#
# Options:
#   --install-dir DIR   Install buzz-acp and buzz here (default: ~/.local/bin)
#   --invite-url URL    Buzz invite link, e.g. https://<relay>/invite/<code>  — the
#                       relay URL is derived from this (required unless --relay-url
#                       is given)
#   --relay-host HOST   SSH host of the relay (default: the relay URL's hostname;
#                       e.g. for wss://buzz.example.com it tries `buzz.example.com`)
#   --relay-url URL     Relay WebSocket URL (required unless --invite-url is given)
#   --owner HEX|NPUB   Pubkey of the agent owner — required (no hardcoded
#                       default). This is the identity YOU chat from; the agent
#                       only responds to DMs/@mentions from it. Find it in the
#                       Buzz desktop: Settings → Profile → Identity. Hex or npub
#                       both accepted (npub converted to hex).
#   --name NAME         Agent display name (default: pi-$(hostname))
#   --no-systemd        Do not create/enable the systemd user service
#   --disable-systemd   Stop, disable and remove any existing buzz-acp user service
#   --no-bashrc         Do not add the env-file sourcing block to ~/.bashrc
#   --dry-run           Run prerequisite checks and print the plan; change nothing
#   -h, --help          Show this help

set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
RELAY_HOST=""
RELAY_URL=""
INVITE_URL=""
# The agent owner: the identity that will chat with the agent (the person who
# generated the invite). No default — must be provided explicitly.
# buzz-acp only answers DMs/@mentions from the owner (or NIP-OA siblings),
# so this must be the pubkey you chat from — not the relay's own key.
OWNER_PUBKEY=""
AGENT_NAME=""
DEFAULT_CHANNELS="welcome welcome-everyone"
NO_BASHRC=0
DRY_RUN=0
NO_SYS=0
DIS_SYS=0
SYSTEMD_MODE="enable"   # enable | none | disable

BUILD_DIR="/tmp/buzz-acp-build"
BASHRC_MARKER="# >>> buzz-acp client env >>>"

usage() { grep '^#   ' "$0" | sed 's/^#   \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir) INSTALL_DIR="$2"; shift 2 ;;
    --invite-url)  INVITE_URL="$2"; shift 2 ;;
    --relay-host)  RELAY_HOST="$2"; shift 2 ;;
    --relay-url)   RELAY_URL="$2"; shift 2 ;;
    --owner)       OWNER_PUBKEY="$2"; shift 2 ;;
    --name)        AGENT_NAME="$2"; shift 2 ;;
    --no-systemd)      SYSTEMD_MODE="none"; NO_SYS=1; shift ;;
    --disable-systemd) SYSTEMD_MODE="disable"; DIS_SYS=1; shift ;;
    --no-bashrc)   NO_BASHRC=1; shift ;;
    --dry-run)     DRY_RUN=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

info()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()   { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

if (( NO_SYS && DIS_SYS )); then die "--no-systemd and --disable-systemd are mutually exclusive"; fi
[[ -n "$AGENT_NAME" ]] || AGENT_NAME="pi-$(hostname)"
# .env filename convention: most agent harnesses refuse/warn before reading
# files named .env, keeping secrets out of prompts.
ENV_FILE="${HOME}/.config/buzz/clients/${AGENT_NAME}/.env"

# ------------------------------------------------------- resolve relay from invite
# The relay URL always comes from the invite link the user was given
# (https://<relay>/invite/<code>) — never a hardcoded server. Accept either a
# --invite-url (preferred) or an explicit --relay-url.
if [[ -n "$INVITE_URL" ]]; then
  if [[ -n "$RELAY_URL" ]]; then
    die "give either --invite-url or --relay-url, not both"
  fi
  # https://<relay>/invite/<code>  (also accept http:// ; reject stray creds/fragments)
  if [[ "$INVITE_URL" =~ ^https://([^/]+)/invite/[^/]+/?$ ]]; then
    RELAY_URL="wss://${BASH_REMATCH[1]}"
  elif [[ "$INVITE_URL" =~ ^http://([^/]+)/invite/[^/]+/?$ ]]; then
    RELAY_URL="ws://${BASH_REMATCH[1]}"
  elif [[ "$INVITE_URL" == buzz://* ]]; then
    # buzz://join?relay=<ws(s)://relay>&code=<code> — pull the relay= param
    RELAY_URL="$(printf '%s' "$INVITE_URL" | sed -n 's/^buzz:\/\/join?relay=\([^&]*\)&code=.*$/\1/p')"
    if [[ -z "$RELAY_URL" || "$RELAY_URL" != ws://* && "$RELAY_URL" != wss://* ]]; then
      die "malformed buzz://join invite (expected buzz://join?relay=wss://…&code=…): $INVITE_URL"
    fi
  else
    die "unrecognised invite URL (expected https://<relay>/invite/<code>): $INVITE_URL"
  fi
fi
if [[ -z "$RELAY_URL" ]]; then
  die "no relay specified: pass --invite-url <https://relay/invite/code> or --relay-url <wss://relay>"
fi
# SSH alias to the relay host defaults to the relay URL's hostname, so nothing
# machine-specific is baked in; override with --relay-host if it differs.
if [[ -z "$RELAY_HOST" ]]; then
  RELAY_HOST="$(printf '%s' "$RELAY_URL" | sed -E 's#^wss?://##; s#[:/].*$##')"
fi
# The relay URL comes from the invite; the OWNER is the person who sent it —
# the identity you'll chat from. Resolve it in order:
#   1. --owner (explicit, hex or npub)
#   2. ~/.config/buzz/owner — cached from a previous enrollment on this machine
#   3. ask the user (Buzz desktop: Settings → Profile → Identity)
# Once validated, it is cached to ~/.config/buzz/owner so future enrollments
# on this machine don't need to ask again.
OWNER_CACHE="${HOME}/.config/buzz/owner"
if [[ -z "$OWNER_PUBKEY" && -s "$OWNER_CACHE" ]]; then
  OWNER_PUBKEY="$(head -c 256 "$OWNER_CACHE" | tr -d '[:space:]')"
  warn "using cached owner pubkey from $OWNER_CACHE (override with --owner)"
fi
one_of_owner=$(cat <<'OWNER_GUIDE'
--owner <pubkey> is required — the identity that will chat with the agent.
Find it in the Buzz desktop app under:  Settings → Profile → Identity
(paste the pubkey or npub shown there).
OWNER_GUIDE
)
[[ -n "$OWNER_PUBKEY" ]] || die "$one_of_owner"
# Accept npub1... and convert to hex (nsec-style bech32 decode, same codebase
# as the keypair encode below).
if [[ "$OWNER_PUBKEY" == npub1* ]]; then
  OWNER_PUBKEY="$(printf '%s' "$OWNER_PUBKEY" | python3 -c '
import sys
CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
s = sys.stdin.read().strip()
pos = s.rfind("1")
words = [CHARSET.index(c) for c in s[pos+1:]][:-6]
acc = bits = 0
out = bytearray()
for w in words:
    acc = (acc << 5) | w; bits += 5
    while bits >= 8:
        bits -= 8; out.append((acc >> bits) & 0xFF)
print(out.hex())
')"
fi
[[ "$OWNER_PUBKEY" =~ ^[0-9a-fA-F]{64}$ ]] || die "$one_of_owner"

# ---------------------------------------------------------------- prerequisites
info "Checking prerequisites"

for cmd in ssh cargo node npm git python3; do
  command -v "$cmd" >/dev/null 2>&1 || die "$cmd not found. Install it and re-run."
done

if ! command -v pi >/dev/null 2>&1; then
  cat >&2 <<'EOF'
error: pi (the coding agent) is not installed. Install it first:

  curl -fsSL https://pi.dev/install.sh | sh
  # or:
  npm install -g --ignore-scripts @earendil-works/pi-coding-agent
EOF
  exit 1
fi

[[ "$OWNER_PUBKEY" =~ ^[0-9a-fA-F]{64}$ ]] || die "$one_of_owner"

if (( ! DRY_RUN )); then
  if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$RELAY_HOST" 'true' 2>/dev/null; then
    die "Cannot reach relay host '$RELAY_HOST' via passwordless ssh. Fix ~/.ssh/config and re-run."
  fi
fi
info "prerequisites OK (pi: $(command -v pi))"

if (( DRY_RUN )); then
  info "dry-run: relay from invite: $RELAY_URL (ssh alias: $RELAY_HOST)"
  info "dry-run: would mint a keypair on '$RELAY_HOST', register it as a member,"
  info "dry-run: would build buzz-acp and the buzz CLI in $BUILD_DIR and install to $INSTALL_DIR,"
  info "dry-run: would set the agent name to '$AGENT_NAME' and join: $DEFAULT_CHANNELS"
  info "dry-run: would npm install -g pi-acp, and write env to $ENV_FILE"
  case "$SYSTEMD_MODE" in
    enable)  info "dry-run: would install+enable the buzz-acp systemd user service (starts at login)" ;;
    disable) info "dry-run: would stop/disable/remove any existing buzz-acp systemd user service" ;;
    none)    info "dry-run: systemd service setup skipped (--no-systemd)" ;;
  esac
  exit 0
fi

# ---------------------------------------------------------------- 1. mint keypair
info "Minting a new Nostr keypair for the agent (on $RELAY_HOST)"

GEN_OUT="$(ssh "$RELAY_HOST" 'cd ~/buzz/deploy/compose && docker compose -f compose.yml -f compose.caddy.yml --env-file .env exec -T relay /usr/local/bin/buzz-admin generate-key')"
AGENT_PUBKEY_HEX="$(printf '%s\n' "$GEN_OUT" | awk '/^Public key:/{print $3}')"
AGENT_PRIVKEY_HEX="$(printf '%s\n' "$GEN_OUT" | awk '/^Secret key:/{print $3}')"
[[ "$AGENT_PUBKEY_HEX" =~ ^[0-9a-fA-F]{64}$ && "$AGENT_PRIVKEY_HEX" =~ ^[0-9a-fA-F]{64}$ ]] \
  || die "Unexpected generate-key output:\n$GEN_OUT"

# Encode keys as bech32 (buzz-acp wants nsec1...; npub for display/roster)
bech32_encode() { # $1=hrp $2=hex
  python3 - "$1" "$2" <<'PY'
import sys
CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
def polymod(v):
    gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
    chk = 1
    for b in v:
        top = chk >> 25
        chk = (chk & 0x1ffffff) << 5 ^ b
        for i in range(5):
            chk ^= gen[i] if (top >> i) & 1 else 0
    return chk ^ 1
def hrp_expand(hrp):
    return [ord(c) >> 5 for c in hrp] + [0] + [ord(c) & 31 for c in hrp]
def convertbits(data, fromb, tob, pad=True):
    acc = bits = 0
    out = []
    for v in data:
        acc = (acc << fromb) | v
        bits += fromb
        while bits >= tob:
            bits -= tob
            out.append((acc >> bits) & ((1 << tob) - 1))
    if pad and bits:
        out.append((acc << (tob - bits)) & ((1 << tob) - 1))
    return out
hrp = sys.argv[1]
raw = bytes.fromhex(sys.argv[2])
words = convertbits(list(raw), 8, 5)
chk = polymod(hrp_expand(hrp) + words + [0] * 6)
out = hrp + "1" + "".join(CHARSET[w] for w in words) + "".join(
    CHARSET[(chk >> (5 * (5 - i))) & 31] for i in range(6)
)
print(out)
PY
}
AGENT_NSEC="$(bech32_encode nsec "$AGENT_PRIVKEY_HEX")" || die "Failed to encode nsec"
AGENT_NPUB="$(bech32_encode npub "$AGENT_PUBKEY_HEX")" || die "Failed to encode npub"

# ---------------------------------------------------------------- 2. add member
info "Registering agent as relay member (idempotent)"
ssh "$RELAY_HOST" "cd ~/buzz/deploy/compose && BUZZ_COMPOSE_TLS=true ./run.sh add-member $AGENT_PUBKEY_HEX" \
  || die "add-member failed"

# ---------------------------------------------------------------- 3. build buzz-acp
info "Building buzz-acp and the buzz CLI in $BUILD_DIR (first build can take several minutes)"
if [[ ! -d "$BUILD_DIR/.git" ]]; then
  rm -rf "$BUILD_DIR"
  git clone --depth 1 https://github.com/block/buzz.git "$BUILD_DIR"
else
  git -C "$BUILD_DIR" fetch --depth 1 origin main
  git -C "$BUILD_DIR" reset --hard origin/main
fi
cargo build --release --manifest-path "$BUILD_DIR/Cargo.toml" -p buzz-acp -p buzz-cli

mkdir -p "$INSTALL_DIR"
install -m 755 "$BUILD_DIR/target/release/buzz-acp" "$INSTALL_DIR/buzz-acp"
install -m 755 "$BUILD_DIR/target/release/buzz" "$INSTALL_DIR/buzz"
info "installed $INSTALL_DIR/buzz-acp ($("$INSTALL_DIR/buzz-acp" --version 2>/dev/null || echo version unknown))"
info "installed $INSTALL_DIR/buzz (Buzz CLI)"

# ---------------------------------------------------------------- 4. name + default channels
info "Setting agent name to '$AGENT_NAME' and joining default channels: $DEFAULT_CHANNELS"
# The buzz CLI talks to the relay's REST API — derive the http(s) URL from the ws(s) one
RELAY_REST_URL="${RELAY_URL/wss:\/\//https://}"
RELAY_REST_URL="${RELAY_REST_URL/ws:\/\//http://}"
buzz_cli() {
  env BUZZ_PRIVATE_KEY="$AGENT_NSEC" BUZZ_RELAY_URL="$RELAY_REST_URL" "$INSTALL_DIR/buzz" "$@"
}

if buzz_cli users set-profile --name "$AGENT_NAME" >/dev/null 2>&1; then
  info "agent name set: $AGENT_NAME"
else
  warn "could not set the agent profile name (relay unreachable?) — you can do it later with:"
  warn "  buzz users set-profile --name $AGENT_NAME   (with BUZZ_PRIVATE_KEY/BUZZ_RELAY_URL set)"
fi

for ch in $DEFAULT_CHANNELS; do
  ch_id="$(buzz_cli channels search --query "$ch" --exact 2>/dev/null \
    | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: d=[]
print(d[0]["channel_id"] if d and d[0].get("channel_id") else "")' 2>/dev/null)" || ch_id=""
  if [[ -n "$ch_id" ]]; then
    if buzz_cli channels join --channel "$ch_id" >/dev/null 2>&1; then
      info "joined #$ch ($ch_id)"
    else
      warn "join of #$ch ($ch_id) failed — retry later with: buzz channels join --channel $ch_id"
    fi
  else
    warn "channel #$ch not found or not visible to the agent (private channels are not searchable)"
    warn "if it exists, the owner must add the agent:"
    warn "  buzz channels search --query $ch          # with the owner's key, to find the channel id"
    warn "  buzz channels add-member --channel <id> --pubkey $AGENT_PUBKEY_HEX"
  fi
done
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) warn "$INSTALL_DIR is not on your PATH — add it if you want to run buzz-acp directly" ;;
esac

# ---------------------------------------------------------------- 5. pi-acp adapter
info "Installing pi-acp ACP adapter (npm -g)"
npm install -g pi-acp
command -v pi-acp >/dev/null 2>&1 || die "pi-acp install failed (is npm's global bin dir on your PATH?)"

# ---------------------------------------------------------------- 6. env file
# Plain KEY=VALUE (no `export`) so systemd's EnvironmentFile can read it too;
# the .bashrc block uses `set -a` to export when sourcing.
mkdir -p "$(dirname "$ENV_FILE")"
umask 077
cat > "$ENV_FILE" <<EOF
# Buzz relay client environment — written by enroll-buzz-client.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)
BUZZ_PRIVATE_KEY="$AGENT_NSEC"
BUZZ_RELAY_URL="$RELAY_URL"
BUZZ_ACP_AGENT_COMMAND="pi-acp"
BUZZ_ACP_AGENT_OWNER="$OWNER_PUBKEY"
EOF
chmod 600 "$ENV_FILE"
info "wrote $ENV_FILE (mode 600)"

# ------------------------------------------------- cache owner for future enrollments
# Remember the validated owner on this machine so a later enrollment doesn't
# have to ask again. A pubkey is public info, so 644 is fine.
mkdir -p "${HOME}/.config/buzz"
printf '%s\n' "$OWNER_PUBKEY" > "$OWNER_CACHE"
chmod 644 "$OWNER_CACHE"
info "cached owner pubkey to $OWNER_CACHE (future enrollments can omit --owner)"

# ---------------------------------------------------------------- 7. systemd user service
UNIT_DIR="${HOME}/.config/systemd/user"
UNIT="$UNIT_DIR/buzz-acp.service"

SYSTEMD_STATE="none"   # active | pending | manual | disabled | none
case "$SYSTEMD_MODE" in
  disable)
    info "Disabling the buzz-acp systemd user service (if present)"
    if command -v systemctl >/dev/null 2>&1 && systemctl --user cat buzz-acp.service >/dev/null 2>&1; then
      systemctl --user disable --now buzz-acp.service 2>/dev/null || true
      rm -f "$UNIT"
      systemctl --user daemon-reload 2>/dev/null || true
      info "stopped, disabled and removed buzz-acp.service"
    elif [[ -f "$UNIT" ]]; then
      rm -f "$UNIT"
      info "removed unit file $UNIT (no user session bus to stop/disable the running service)"
      SYSTEMD_STATE="disabled"
    else
      info "no existing buzz-acp.service found — nothing to disable"
      SYSTEMD_STATE="absent"
    fi
    ;;
  none)
    info "Skipping systemd service setup (--no-systemd) — run buzz-acp manually"
    ;;
  enable)
    info "Installing buzz-acp as a systemd user service (starts at login)"
    mkdir -p "$UNIT_DIR"
    # systemd user services get a minimal PATH — include the dir holding
    # pi-acp/pi (often an nvm node dir that is NOT on the default PATH)
    AGENT_BIN_DIR=""
    for cand in pi-acp pi; do
      if p="$(command -v "$cand" 2>/dev/null)"; then AGENT_BIN_DIR="$(dirname "$p")"; break; fi
    done
    UNIT_PATH_LINE=""
    if [[ -n "$AGENT_BIN_DIR" ]]; then
      UNIT_PATH_LINE="Environment=PATH=$AGENT_BIN_DIR:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    fi
    cat > "$UNIT" <<EOF
# Written by enroll-buzz-client.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)
[Unit]
Description=Buzz ACP agent harness (pi via pi-acp)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
$UNIT_PATH_LINE
EnvironmentFile=%h/.config/buzz/clients/${AGENT_NAME}/.env
WorkingDirectory=%h
ExecStart=$INSTALL_DIR/buzz-acp
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    if command -v systemctl >/dev/null 2>&1 && systemctl --user enable buzz-acp.service 2>/dev/null; then
      info "enabled buzz-acp.service (will start at each login)"
      if systemctl --user start buzz-acp.service 2>/dev/null; then
        info "started buzz-acp.service now"
        SYSTEMD_STATE="active"
      else
        warn "could not start buzz-acp.service right now (no user session bus, e.g. over SSH) — it will start at your next login"
        SYSTEMD_STATE="pending"
      fi
      if command -v loginctl >/dev/null 2>&1; then
        loginctl enable-linger "$(id -un)" 2>/dev/null \
          || warn "run 'loginctl enable-linger $(id -un)' so the service also starts at boot, before you log in"
      fi
    else
      warn "systemctl --user is not available — wrote the unit to $UNIT;"
      warn "enable it manually: systemctl --user enable --now buzz-acp.service"
      SYSTEMD_STATE="manual"
    fi
    ;;
esac

# ---------------------------------------------------------------- 8. .bashrc
BASHRC_SNIPPET="if [ -f \"$ENV_FILE\" ]; then set -a; . \"$ENV_FILE\"; set +a; fi"
if (( NO_BASHRC )); then
  info "skipping .bashrc (per --no-bashrc)"
elif grep -qF "$BASHRC_MARKER" "$HOME/.bashrc" 2>/dev/null; then
  info ".bashrc already has the buzz-acp env block — skipping"
else
  cat >> "$HOME/.bashrc" <<EOF

$BASHRC_MARKER
$BASHRC_SNIPPET
# <<< buzz-acp client env <<<
EOF
  info "appended source line to ~/.bashrc (takes effect in new shells)"
fi

# ---------------------------------------------------------------- done
cat <<EOF

Enrollment complete.

  Agent name:   $AGENT_NAME
  Agent pubkey: $AGENT_PUBKEY_HEX
  Agent npub:   $AGENT_NPUB
  Owner:        $OWNER_PUBKEY
$(case "$SYSTEMD_STATE" in
  active)   printf '  Service:      buzz-acp.service — running now, starts at each login\n  Manage:       systemctl --user status|stop|start|disable buzz-acp.service' ;;
  pending)  printf '  Service:      buzz-acp.service — enabled, starts at your next login\n  Manage:       systemctl --user status|stop|start|disable buzz-acp.service' ;;
  manual)   printf '  Service:      buzz-acp.service — unit written, enable with:\n                 systemctl --user enable --now buzz-acp.service' ;;
  disabled) printf '  Service:      existing buzz-acp.service was stopped/disabled/removed' ;;
  absent)   printf '  Service:      no existing buzz-acp.service was present' ;;
  none)     printf '  Service:      none (--no-systemd) — run buzz-acp manually' ;;
esac)

Save this secret key NOW — it is shown only once and not stored anywhere
except $ENV_FILE:

  $AGENT_NSEC

$(case "$SYSTEMD_STATE" in
  active|pending)
    cat <<'INNER'
Useful commands:

  systemctl --user status buzz-acp.service    # check it
  journalctl --user -u buzz-acp.service -f     # follow logs
  systemctl --user stop buzz-acp.service       # stop it
INNER
    ;;
  *)
  cat <<INNER
To start the agent, in a shell with the env loaded (new shell, or:
  set -a; . $ENV_FILE; set +a):

  cd <working directory for the agent>
  buzz-acp
INNER
    ;;
esac)
It will authenticate to $RELAY_URL and respond to @mentions from the owner.
EOF
