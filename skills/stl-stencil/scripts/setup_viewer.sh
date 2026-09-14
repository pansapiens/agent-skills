#!/usr/bin/env bash
# Drop the STL viewer into a project and vendor three.js beside it.
#
# The viewer is three.js plus one HTML file. three.js is fetched once into
# viewer/lib/ so the page keeps working offline afterwards. ES modules will not
# load over file://, hence the HTTP server.
#
# Usage: setup_viewer.sh [dest-dir] [port]

set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dest=${1:-.}
port=${2:-8731}
version=0.169.0

cp -r "$here/assets/viewer" "$dest/viewer"
mkdir -p "$dest/viewer/lib"

for f in build/three.module.js \
         examples/jsm/controls/OrbitControls.js \
         examples/jsm/loaders/STLLoader.js; do
    out="$dest/viewer/lib/$(basename "$f")"
    [ -s "$out" ] || curl -sSL --max-time 60 -o "$out" \
        "https://unpkg.com/three@$version/$f"
done

echo "viewer installed in $dest/viewer"
echo "now edit $dest/viewer/models.json to point at your STLs, then:"
echo "  python3 -m http.server $port --bind 127.0.0.1 &"
echo "  xdg-open http://127.0.0.1:$port/viewer/index.html"
