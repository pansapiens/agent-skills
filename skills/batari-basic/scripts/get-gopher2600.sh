#!/usr/bin/env bash
# get-gopher2600.sh - make sure the gopher2600 emulator is available.
#
# Prints the path to the binary on stdout (and nothing else), so it can be
# used inline:   EMU=$(scripts/get-gopher2600.sh)
#
# The binary is cached outside the skill directory so it never lands in a
# git working tree. Override the location with BB_CACHE.
#
# By default this fetches a FORK build, pansapiens/Gopher2600, which carries a
# single documentation fix: upstream's HELP STICK and HELP KEYPAD tell you to
# "specify the player with the 0 or 1 arguments", but the parser rejects that
# and takes [LEFT|RIGHT] - the console PORT, where LEFT is Player 0. Following
# the upstream help sends you looking for a direction in the first argument,
# which is the single most expensive mistake in scripted input (see
# references/running-in-an-emulator.md). Emulation is byte-for-byte upstream
# behaviour; only help strings differ.
#
# Set BB_GOPHER2600_UPSTREAM=1 to take upstream's release instead.
set -euo pipefail

CACHE="${BB_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/batari-basic}"

if [ -n "${BB_GOPHER2600_UPSTREAM:-}" ]; then
    BIN="$CACHE/gopher2600-upstream"
    URL="https://github.com/jetsetilly/gopher2600/releases/latest/download/gopher2600_linux_amd64"
else
    # Separate cache name, so a previously cached upstream binary is not
    # silently reused in place of the fork (and vice versa).
    BIN="$CACHE/gopher2600-fork"
    URL="https://github.com/pansapiens/Gopher2600/releases/latest/download/gopher2600_linux_amd64"
fi

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

# Only linux/amd64 is published (by upstream or by the fork). Fail loudly
# anywhere else rather than downloading something that cannot run.
os=$(uname -s)
arch=$(uname -m)
if [ "$os" != "Linux" ] || [ "$arch" != "x86_64" ]; then
    cat >&2 <<EOF
get-gopher2600: no published binary for $os/$arch (only linux/amd64 is released).
Build it from source instead:
    go install github.com/jetsetilly/gopher2600@latest
then re-run with BB_GOPHER2600=/path/to/gopher2600.

Note: go install always builds UPSTREAM - the fork's module path is still
github.com/jetsetilly/gopher2600, so it cannot be go-installed by its fork
path. To get the corrected STICK/KEYPAD help on another platform, clone
https://github.com/pansapiens/Gopher2600 (master carries the fix) and run
'make release'. You will need SDL2 and OpenGL development headers; see
.github/workflows/release-linux.yml in that repo for the exact package list.
The difference is help text only; upstream is fine for everything else.
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
