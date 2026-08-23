#!/usr/bin/env bash
# bb-build.sh <game.bas> [extra 2600bas args...]
#
# Compiles a batari Basic program and checks that a plausible ROM came out.
# Exits non-zero if the compile failed or produced no ROM, so it can gate a
# test run:   scripts/bb-build.sh game.bas && scripts/bb-headless.sh ...
#
# Finding the compiler, in order:
#   $BB_HOME/2600bas
#   batari-Basic/2600bas in the .bas file's directory or any parent
#   2600bas on $PATH
#
# BB_TOOLCHAIN selects how to compile:
#   auto   (default) native if a native bB is findable, else wasm
#   native only the native binaries
#   wasm   the wasm build under wasmtime - portable, no build step, and
#          verified to produce byte-identical ROMs (scripts/get-bb-wasm.sh
#          fetches it). From v1.9 upstream publishes ONLY wasm artifacts.
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: bb-build.sh <game.bas> [2600bas args...]" >&2
    exit 2
fi
BAS=$1; shift
[ -f "$BAS" ] || { echo "bb-build: no such file: $BAS" >&2; exit 1; }
BAS=$(readlink -f "$BAS")

find_compiler() {
    if [ -n "${BB_HOME:-}" ] && [ -x "$BB_HOME/2600bas" ]; then
        echo "$BB_HOME/2600bas"; return 0
    fi
    local d
    d=$(dirname "$BAS")
    while [ "$d" != "/" ]; do
        if [ -x "$d/batari-Basic/2600bas" ]; then echo "$d/batari-Basic/2600bas"; return 0; fi
        if [ -x "$d/2600bas" ]; then echo "$d/2600bas"; return 0; fi
        d=$(dirname "$d")
    done
    command -v 2600bas 2>/dev/null && return 0
    return 1
}

# A wasm bB dir: has the .wasm modules and upstream's 2600basic.sh launcher.
find_wasm_bB() {
    if [ -n "${bB:-}" ] && [ -f "$bB/2600basic.wasm" ]; then echo "$bB"; return 0; fi
    if [ -n "${BB_HOME:-}" ] && [ -f "$BB_HOME/2600basic.wasm" ]; then echo "$BB_HOME"; return 0; fi
    local c="${BB_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/batari-basic}/bB"
    if [ -f "$c/2600basic.wasm" ]; then echo "$c"; return 0; fi
    return 1
}

TOOLCHAIN="${BB_TOOLCHAIN:-auto}"
CC=""; WASM_BB=""
case "$TOOLCHAIN" in
    native) CC=$(find_compiler) || true ;;
    wasm)   WASM_BB=$(find_wasm_bB) || true ;;
    auto)   CC=$(find_compiler) || WASM_BB=$(find_wasm_bB) || true ;;
    *) echo "bb-build: BB_TOOLCHAIN must be auto, native or wasm" >&2; exit 2 ;;
esac

if [ -z "$CC" ] && [ -z "$WASM_BB" ]; then
    cat >&2 <<'EOF'
bb-build: no batari Basic toolchain found.
Either:
  - set BB_HOME=/path/to/batari-Basic (a native build), or
  - run scripts/get-bb-wasm.sh to fetch the portable wasm toolchain
See references/installation.md.
EOF
    exit 1
fi

set +e
if [ -n "$CC" ]; then
    # 2600bas scatters intermediates (bB.asm, includes.bB,
    # 2600basic_variable_redefs.h) into the *current* directory while writing
    # the ROM next to the source. Compile from a scratch directory so those
    # land somewhere disposable instead of in the project.
    SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/bb-build.XXXXXX")
    trap 'rm -rf "$SCRATCH"' EXIT
    OUT=$(cd "$SCRATCH" && "$CC" "$BAS" "$@" 2>&1)
    RC=$?
else
    # The wasm build runs under wasmtime, which only exposes the directories
    # it is given (--dir). Upstream's launcher passes `--dir=.`, so the
    # compile has to happen *in* the source directory: from anywhere else
    # wasmtime cannot read the .bas, resolve the user's own `include` files,
    # or write the ROM. Intermediates therefore land next to the source, so
    # remove the ones we created and leave any that were already there.
    if [ -n "${BB_WASMTIME:-}" ]; then
        PATH="$(dirname "$BB_WASMTIME"):$PATH"
    else
        PATH="${BB_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/batari-basic}:$PATH"
    fi
    export PATH
    if ! command -v wasmtime >/dev/null 2>&1; then
        echo "bb-build: wasmtime not found (needed for BB_TOOLCHAIN=wasm)." >&2
        echo "Run scripts/get-bb-wasm.sh, or set BB_WASMTIME=/path/to/wasmtime." >&2
        exit 1
    fi
    DIR=$(dirname "$BAS")
    PRE=$(mktemp "${TMPDIR:-/tmp}/bb-build.XXXXXX")
    trap 'rm -f "$PRE"' EXIT
    for f in bB.asm includes.bB 2600basic_variable_redefs.h; do
        [ -e "$DIR/$f" ] && echo "$f" >> "$PRE"
    done
    OUT=$(cd "$DIR" && bB="$WASM_BB" sh "$WASM_BB/2600basic.sh" "$(basename "$BAS")" "$@" 2>&1)
    RC=$?
    for f in bB.asm includes.bB 2600basic_variable_redefs.h; do
        grep -qx "$f" "$PRE" 2>/dev/null || rm -f "$DIR/$f"
    done
fi
set -e

BIN="$BAS.bin"

# The compiler exits 0 on some failures, so judge it on its output and on
# whether a ROM actually appeared.
if [ $RC -ne 0 ] || ! printf '%s' "$OUT" | grep -q "Complete. (0)"; then
    printf '%s\n' "$OUT" | tail -20 >&2
    echo "bb-build: FAILED to compile $BAS" >&2
    exit 1
fi

if [ ! -f "$BIN" ]; then
    printf '%s\n' "$OUT" | tail -20 >&2
    echo "bb-build: compiler reported success but produced no ROM: $BIN" >&2
    exit 1
fi

SIZE=$(stat -c%s "$BIN")

# a real 2600 ROM is a power of two, at least 4K
if [ "$SIZE" -lt 4096 ] || [ $(( SIZE & (SIZE - 1) )) -ne 0 ]; then
    echo "bb-build: suspicious ROM size $SIZE bytes (expected a power of 2 >= 4096)" >&2
    exit 1
fi

# surface the line worth watching while a game grows
printf '%s\n' "$OUT" | grep -E "bytes of ROM space left" || true
echo "ROM: $BIN ($SIZE bytes)"
