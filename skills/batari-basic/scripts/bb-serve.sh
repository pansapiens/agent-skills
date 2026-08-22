#!/usr/bin/env bash
# Serve a directory over HTTP so javatari.js can actually fetch the ROM.
#
# Javatari loads the cartridge with XMLHttpRequest. Browsers refuse XHR on
# file:// URLs, so a page opened by double-clicking it — or with xdg-open,
# or `open` — always fails, no matter how correct the ROM path is. The
# emulator reports it as:
#
#     Could not load file: game.bas.bin
#     Error: 0
#
# "Error: 0" is an XHR status of zero: the request never left the browser.
# It is not a path problem. Serve the directory and the same page works.
#
# Usage: bb-serve.sh [dir] [port]     (defaults: . and 8600)
set -euo pipefail

DIR="${1:-.}"
PORT="${2:-8600}"

[ -d "$DIR" ] || { echo "bb-serve: not a directory: $DIR" >&2; exit 1; }
cd "$DIR"

echo "Serving $(pwd) at http://localhost:$PORT/" >&2
echo "Stop with Ctrl-C. Run under 'timeout' if you only need a smoke test." >&2
exec python3 -m http.server "$PORT"
