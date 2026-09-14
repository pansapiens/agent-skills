#!/usr/bin/env bash
# Flatten an SVG into something OpenSCAD's import() can read.
#
# OpenSCAD 2021.01 only handles filled paths with their transforms already
# applied. It ignores strokes, drops <use> clones, and does not resolve
# xlink:href. The SCP emblem uses all three: both rings are stroked with
# fill="none", and two of the three arrows are <use> clones of the first with a
# rotate() transform. Imported raw it renders as nothing at all.
#
# Inkscape fixes all of it in one pass. path-union implicitly unlinks the clones
# on the way through, so no separate unlink step is needed (the unlink-clone
# action does not exist in Inkscape 1.4 anyway).
#
# Usage: flatten_svg.sh in.svg out.svg

set -euo pipefail

in=${1:?usage: flatten_svg.sh in.svg out.svg}
out=${2:?usage: flatten_svg.sh in.svg out.svg}

# Inkscape 1.4 opens a GUI window for --actions even when the output is a file,
# so on a desktop this flashes windows up and steals focus - unwelcome when it
# happens inside an automated run the user is not watching. xvfb-run gives it a
# throwaway virtual display to do that on. Fall back to a bare call where Xvfb
# is not installed, since the export itself works either way.
if command -v xvfb-run >/dev/null 2>&1; then
    run=(xvfb-run -a)
else
    run=()
fi

"${run[@]}" inkscape "$in" \
    --export-type=svg --export-plain-svg --export-filename="$out" \
    --actions="select-all:all;object-stroke-to-path;select-all:all;path-union"

echo "wrote $out"
echo "check it imports:  openscad -o /tmp/check.png --viewall --autocenter \\"
echo "    <(echo 'linear_extrude(1) import(\"$(realpath "$out")\");')"
