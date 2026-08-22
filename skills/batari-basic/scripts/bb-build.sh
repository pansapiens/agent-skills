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

if ! CC=$(find_compiler); then
    cat >&2 <<'EOF'
bb-build: 2600bas not found.
Set BB_HOME=/path/to/batari-Basic, or install it - see references/installation.md.
EOF
    exit 1
fi

# 2600bas scatters intermediates (bB.asm, includes.bB,
# 2600basic_variable_redefs.h) into the *current* directory while writing the
# ROM next to the source. Compile from a scratch directory so those land
# somewhere disposable instead of in the project.
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/bb-build.XXXXXX")
trap 'rm -rf "$SCRATCH"' EXIT

set +e
OUT=$(cd "$SCRATCH" && "$CC" "$BAS" "$@" 2>&1)
RC=$?
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
