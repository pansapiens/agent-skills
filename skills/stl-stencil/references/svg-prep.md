# Getting an SVG into OpenSCAD

## What OpenSCAD actually reads

OpenSCAD 2021.01's `import()` for SVG understands **filled paths with their
transforms already applied**, and little else. It is not a renderer. In
particular it does not:

- fill strokes - a `stroke="#000" fill="none"` path contributes nothing
- resolve `<use>` / `xlink:href` clones
- reliably handle bare `<circle>`, `<rect>`, `<ellipse>`, `<polygon>` elements
- apply CSS from a `<style>` block
- follow `<image>` or embedded rasters

Most logo SVGs in the wild hit at least one of these. The failure is silent: the
import succeeds, the render is empty, and the difference against the plate
produces a plain disc with no cut-outs. Nothing warns you.

**Always render the flattened SVG on its own and look at the PNG before
building the stencil.**

## Worked example: the SCP emblem

The Wikimedia Commons file is 810 bytes and manages to trip three limitations at
once:

```xml
<circle cx="67.7" cy="71.5" r="33" fill="none" stroke="#000" stroke-width="6"/>
<path d="m51.9 11.9h31.7..." fill="none" stroke="#000" stroke-width="4"/>
<path id="b" d="m64.7 30.6v24h-5.08l8.08 14 8.08-14h-5.08l-.000265-24h-5.99"/>
<use id="a" transform="rotate(120 67.7 71.5)" xlink:href="#b"/>
<use transform="rotate(120 67.7 71.5)" xlink:href="#a"/>
```

- the inner ring is a `<circle>`, unfilled, drawn entirely by its 6-unit stroke
- the outer gear ring is a `<path>`, also unfilled, drawn by a 4-unit stroke
- only one of the three arrows is a real path; the other two are `<use>` clones,
  the second one cloning the first clone

Imported raw it renders as nothing. After flattening it is a single `<path>`
with every subpath explicit, and imports correctly with its holes intact.

## The flatten

`scripts/flatten_svg.sh` runs:

```bash
inkscape in.svg --export-type=svg --export-plain-svg --export-filename=out.svg \
    --actions="select-all:all;object-stroke-to-path;select-all:all;path-union"
```

- `object-stroke-to-path` converts each stroke into a filled outline. A stroked
  circle becomes an annulus - two subpaths, outer and inner - which is exactly
  what the stencil wants.
- `path-union` merges everything into one path and, usefully, unlinks `<use>`
  clones on the way through. There is no separate unlink step: the
  `unlink-clone` action does not exist in Inkscape 1.4 (`clone-unlink` is the
  GUI verb, not a CLI action name), and `path-union` makes it unnecessary.
- `--export-plain-svg` strips the Inkscape namespace so the output is a clean
  SVG.

Union also resolves overlaps. Without it, two overlapping subpaths can cancel
under OpenSCAD's even-odd fill and punch a hole where the artwork is solid.

## Checking the result

```bash
grep -c '<path' out.svg        # expect 1
grep -c '<use\|<circle\|<rect' out.svg   # expect 0
```

Then render it:

```bash
echo 'linear_extrude(1) import("'$PWD'/out.svg");' > /tmp/check.scad
openscad -o /tmp/check.png --projection=o --camera=0,0,200,0,0,0,200 \
    --viewall --autocenter --imgsize=600,600 /tmp/check.scad
```

Look at the PNG:

| What you see | Cause |
| --- | --- |
| blank | strokes not converted, or everything was `<use>` clones |
| solid blobs, no holes | subpath winding lost; re-run `path-union` |
| holes where the artwork should be solid | overlapping subpaths cancelling under even-odd; `path-union` fixes it |
| mirrored | not a real failure - OpenSCAD already flips SVG's y-down axis |
| right shape, wrong size | see scale, below |

## Scale

OpenSCAD converts SVG user units to millimetres at `dpi` (default 96), so an SVG
authored in mm with a matching `width` usually lands close to 1:1. Do not rely on
it. The template scales the artwork explicitly so its enclosing circle sits `rim`
millimetres inside the disc edge, which makes the import scale irrelevant -
`art_r` from `analyse_outline.py` is in whatever units the import produced, and
the ratio is what matters.

## Other sources

- **DXF**: `import("art.dxf")` is better supported than SVG. Closed polylines
  only; open ones are ignored.
- **PNG or JPG**: trace first, then treat as SVG.
  `potrace -s -o art.svg art.pbm` (convert to PBM first with ImageMagick).
  Trace quality sets the stencil quality, so tune `potrace -a` (corner
  threshold) and `-O` (curve optimisation) before proceeding.
- **Font glyphs**: skip SVG entirely. OpenSCAD's `text()` is a 2D primitive and
  can be used directly as the artwork child, with `font=` and `size=`. Letter
  counters are the textbook island case, so the analysis step still applies.
