#!/usr/bin/env bash
# get-gopher2600.sh - make sure the gopher2600 emulator is available.
#
# Prints the path to the binary on stdout (and nothing else), so it can be
# used inline:   EMU=$(scripts/get-gopher2600.sh)
#
# The binary is cached outside the skill directory so it never lands in a
# git working tree. Override the location with BB_CACHE.
set -euo pipefail

CACHE="${BB_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/batari-basic}"
BIN="$CACHE/gopher2600"
URL="https://github.com/jetsetilly/gopher2600/releases/latest/download/gopher2600_linux_amd64"

# already have one?
if [ -n "${BB_GOPHER2600:-}" ] && [ -x "${BB_GOPHER2600}" ]; then
    echo "$BB_GOPHER2600"; exit 0
fi
if [ -x "$BIN" ]; then
    echo "$BIN"; exit 0
fi
if command -v gopher2600 >/dev/null 2>&1; then
    command -v gopher2600; exit 0
fi

# The project publishes one binary: linux/amd64. Fail loudly anywhere else
# rather than downloading something that cannot run.
os=$(uname -s)
arch=$(uname -m)
if [ "$os" != "Linux" ] || [ "$arch" != "x86_64" ]; then
    cat >&2 <<EOF
get-gopher2600: no published binary for $os/$arch (only linux/amd64 is released).
Build it from source instead:
    go install github.com/jetsetilly/gopher2600@latest
then re-run with BB_GOPHER2600=/path/to/gopher2600.
EOF
    exit 1
fi

mkdir -p "$CACHE"
echo "downloading gopher2600 -> $BIN" >&2
if ! curl -sfL -o "$BIN.part" "$URL"; then
    rm -f "$BIN.part"
    echo "get-gopher2600: download failed: $URL" >&2
    exit 1
fi
chmod +x "$BIN.part"
mv "$BIN.part" "$BIN"
echo "$BIN"
