#!/usr/bin/env bash
# bb-headless.sh <rom.bin> <steps.txt> [seconds]
#
# Runs a ROM under gopher2600 HEADLESS, feeding it a script of debugger
# commands, and reports any commands the emulator did not understand.
#
# The *steps file is yours to write* - it is the part that differs for every
# game (how long the title screen takes, which switch starts it, what the
# controls do). This script only wraps the fragile bits: the SCRIPT-file
# pattern, the startup/teardown timing, and the error grep.
#
#   STEPS=/tmp/steps.txt
#   { for i in $(seq 1 60); do echo "STEP FRAME"; done
#     echo "SCREENSHOT /tmp/title.png"
#     echo "STICK LEFT FIRE";  echo "STEP FRAME"
#     echo "STICK LEFT NOFIRE"
#     for i in $(seq 1 120); do echo "STEP FRAME"; done
#     echo "SCREENSHOT /tmp/play.png"
#     echo "QUIT"; } > "$STEPS"
#   scripts/bb-headless.sh game.bas.bin "$STEPS"
#
# Command vocabulary and the STICK syntax quirks: references/running-in-an-emulator.md
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "usage: bb-headless.sh <rom.bin> <steps.txt> [seconds]" >&2
    exit 2
fi

ROM=$1
STEPS=$2
WAIT=${3:-10}

[ -f "$ROM" ]   || { echo "bb-headless: no such ROM: $ROM" >&2; exit 1; }
[ -f "$STEPS" ] || { echo "bb-headless: no such steps file: $STEPS" >&2; exit 1; }

# Everything must be absolute: the emulator does not resolve paths the way
# your shell does, and this script does not control its working directory.
ROM=$(readlink -f "$ROM")
STEPS=$(readlink -f "$STEPS")

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
EMU=$("$HERE/get-gopher2600.sh")

# A relative SCREENSHOT path silently lands somewhere you are not looking.
if grep -qE '^[[:space:]]*SCREENSHOT[[:space:]]+[^/]' "$STEPS"; then
    echo "bb-headless: warning - SCREENSHOT with a relative path in $STEPS;" >&2
    echo "             use absolute paths or you will not find the files." >&2
fi

if ! grep -qiE '^[[:space:]]*QUIT' "$STEPS"; then
    echo "bb-headless: warning - no QUIT in $STEPS; relying on the timeout." >&2
fi

# sleep 2 lets the emulator finish booting before SCRIPT is sent; the second
# sleep gives the script time to run before the fallback QUIT. Commands piped
# straight in (without SCRIPT) get swallowed after any command that runs the
# emulation - hence the file.
OUT=$( { sleep 2; echo "SCRIPT $STEPS"; sleep "$WAIT"; echo "QUIT"; } \
        | timeout $((WAIT + 30)) "$EMU" HEADLESS "$ROM" 2>&1 ) || true

SHOTS=$(printf '%s\n' "$OUT" | grep -c "saving screenshot" || true)
# The debugger prefixes every rejected command with "* " and never uses the
# word "error", so match the prefix. Grepping for "unrecognis|error" misses the
# whole "* ... required" family - notably a one-argument STICK, which is a port
# with no action and sends nothing to the ROM.
ERRS=$(printf '%s\n' "$OUT" | grep '^\*' || true)

if [ -n "$ERRS" ]; then
    echo "bb-headless: the emulator rejected some commands:" >&2
    printf '%s\n' "$ERRS" >&2
    exit 1
fi

WANTED=$(grep -ciE '^[[:space:]]*SCREENSHOT' "$STEPS" || true)
echo "bb-headless: ran cleanly, $SHOTS/$WANTED screenshot(s) written"

if [ "$WANTED" -gt 0 ] && [ "$SHOTS" -lt "$WANTED" ]; then
    echo "bb-headless: fewer screenshots than requested - the script probably" >&2
    echo "             ran out of time; raise the seconds argument." >&2
    exit 1
fi
