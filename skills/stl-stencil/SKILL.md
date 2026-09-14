---
name: stl-stencil
description: Turn flat artwork - an SVG logo, a DXF, or an already-extruded STL - into a 3D-printable paint stencil with OpenSCAD. Handles the hard part automatically, which is finding the islands that fall out because they are ringed by cut-outs, and tying them back to the frame with half-torus arch bridges. Use this whenever someone wants to cut, mask, spray, airbrush or paint a logo or symbol, or asks for a stencil, spray template, paint mask, sign template, or to print a logo so they can paint with it, or has a shape they want turned into holes in a plate. Also use when a stencil already exists and is falling apart, has floating pieces, or needs bridges, tabs, webs or ties added; when someone needs to know why the middle of their O or A drops out; or when they want to preview and inspect the resulting STL in a browser before printing.
---

# Flat artwork to printable stencil

A stencil is artwork subtracted from a plate: the logo becomes holes, the plate
becomes the mask. The geometry is trivial. What makes stencils fail is
**islands** - regions of plate completely ringed by cut-outs, which fall out the
moment the print finishes. The inside of an "O", the middle of an "A", the space
between two concentric rings. Typographers call the fix a bridge or a tie.

This skill's job is to find those islands before printing and hold them with
half-torus arches that rise from the top face, leaving the underside flat so the
stencil still sits flush against whatever is being painted.

## Workflow

1. Get the artwork into a 2D shape OpenSCAD can subtract
2. Measure it with `scripts/analyse_outline.py` - islands, enclosing circle,
   and a radial profile showing where the solid bands sit
3. Write the `.scad` from `assets/stencil.scad` plus the template below
4. Pick bridge positions from the radial profile
5. Export, verify manifold and body count, preview in the viewer

Do not skip step 2. The island count is not something to eyeball - the SCP
emblem looks like it has four islands and actually has two, because the three
arrows stop just short of meeting at the centre.

## Step 1: artwork into OpenSCAD

| Source | How |
| --- | --- |
| SVG | `import("art.svg")` - **flatten first**, see below |
| DXF | `import("art.dxf")` - already 2D, usually works as-is |
| STL of an extrusion | `projection(cut = false) import("art.stl")` |
| Bitmap | trace to SVG with `potrace` first, then as SVG |

OpenSCAD 2021.01's SVG import is narrow: it reads **filled paths with their
transforms already baked in**. It ignores strokes, skips `<use>` clones, does
not resolve `xlink:href`, and often drops bare `<circle>`/`<rect>` elements. Most
real-world logo SVGs use at least one of those, and import as *nothing at all* -
a silently empty render.

`scripts/flatten_svg.sh in.svg out.svg` fixes all of it via Inkscape in one
pass (stroke-to-path, then union, which unlinks clones on the way through).
Always run it, and always check the result actually renders:

```bash
scripts/flatten_svg.sh art.svg art_flat.svg
echo 'linear_extrude(1) import("'$PWD'/art_flat.svg");' > /tmp/check.scad
openscad -o /tmp/check.png --viewall --autocenter --projection=o \
    --camera=0,0,200,0,0,0,200 --imgsize=600,600 /tmp/check.scad
```

Then look at the PNG. If it shows the artwork, move on - you do not need
`references/svg-prep.md`. **If it is blank, or partial, or the shapes are
outlines rather than solids, read `references/svg-prep.md` in full before
trying anything else.** It maps each of those three appearances back to the
specific SVG construct that caused it, which is much faster than guessing at
Inkscape flags.

## Step 2: measure it

`analyse_outline.py` takes an STL of the artwork extruded from z = 0. For an SVG
or DXF, make one first:

```bash
echo 'linear_extrude(1) import("'$PWD'/art_flat.svg");' > /tmp/prism.scad
openscad --export-format binstl -o /tmp/prism.stl /tmp/prism.scad
python3 scripts/analyse_outline.py /tmp/prism.stl
```

It reports the outline loops, the smallest circle enclosing the artwork (centre
and radius, in the artwork's own units - both go straight into the `.scad`), the
island count with each island's area and extent, and a radial profile listing
the solid runs along rays at chosen angles.

The radial profile is what bridge placement is read off. Each row is one ray:

```
  30.0  22.65-27.85 (w5.20)  39.65-42.00 (w2.35)
  90.0  1.85-32.10 (w30.25)  44.85-47.10 (w2.25)
```

At 30 degrees the ray crosses two narrow bands of artwork. At 90 degrees it runs
straight down an arrow for 30 mm - a useless angle for a bridge. Use `--angles`
to probe more finely once you have a candidate.

## Step 3 and 4: write the .scad and place bridges

Copy `assets/stencil.scad` next to the design file.

**Pick a plate shape first.** `stencil_plate()` is round, which suits a logo.
For artwork much wider than it is tall - a word, a wordmark - use
`stencil_plate_rect()`: a disc enclosing 156 mm of lettering is 200 mm across
and mostly empty plate. `analyse_outline.py` prints the artwork's bbox and says
so when the aspect ratio is lopsided.

The round case:

```openscad
use <stencil.scad>

art_file = "art_flat.svg";
art_r    = 85.772;              // enclosing radius, artwork's own units
art_c    = [90.707, 84.838];    // its centre, likewise

disc_d      = 150;   // finished outer diameter
rim         = 7;     // plate left outside the artwork at its closest point
thickness   = 1.0;   // 0.8-1.2 mm is plenty; a stencil wants to be thin
hole_offset = 0.0;   // + widens every cut-out, - narrows it

bridges  = true;     // false to print the islands loose and align by hand
foot     = 3.5;      // how far each arch foot lands clear of its band
bridge_r = 2.0;      // arch tube radius

// [band inner edge, band outer edge, angle] - edges as a fraction of art_r
bridge_spec = [
    [0.4652, 0.5643,  30], [0.4652, 0.5643, 150], [0.4652, 0.5643, 270],
];

$fa = 2; $fs = 0.3;

union() {
    stencil_plate(disc_d, thickness, art_r, art_c, rim, hole_offset)
        import(art_file);
    if (bridges)
        stencil_bridges(disc_d, thickness, art_r, bridge_spec, rim, foot,
                        bridge_r);
}
```

Band edges are given as a **fraction of the enclosing radius** rather than in
millimetres, so the table survives a change of `disc_d`. Divide the radii from
the radial profile by `art_r`.

Placing the bridges:

- **Every island needs a path back to the rim.** Work outward: bridge the
  outermost island to the rim, then each inner island to the one outside it.
  Three bridges per island is a good default - one is a hinge, two is a
  see-saw, three holds it flat.
- **Cross the narrowest part of the artwork.** A bridge spans a band of
  cut-out; shorter span means a shorter, stiffer arch.
- **Pick angles that miss the detail.** If the artwork has n-fold symmetry with
  features at some angles, put the bridges midway between them.
- **Keep the feet on solid plate.** `foot` is measured from the band edge to the
  foot centre, and the tube adds `bridge_r` beyond that. `foot = 3.5` with the
  default `bridge_r = 2` leaves ~1.5 mm of clear plate between the tube and the
  cut-out edge - grow `foot` alongside `bridge_r` to keep that margin.

### Artwork with no single centre

`stencil_bridges()` measures every band from one origin, which only works when
the artwork is arranged around a centre. A word is not: each counter needs its
own ray origin, somewhere inside it.

Use `bridge()` directly for those. It takes an explicit origin, so the band
radii still come straight off `analyse_outline.py` run with `--centre` at that
same point - measure from inside the island, then place from inside the island:

```openscad
// radii and origin in the artwork's units, scaled to the finished plate
s  = (plate_w - 2 * margin) / art_size[0];
oc = [(65.65 - art_c[0]) * s, (29.30 - art_c[1]) * s];   // the O's centre

for (b = [[90, 12.00, 18.75], [270, 12.05, 18.80], [20, 9.50, 19.00]])
    bridge(oc, b[0], b[1] * s, b[2] * s, thickness, foot, bridge_r);
```

Work one island at a time: find its centre from the island list, run
`analyse_outline.py --centre <x> <y>` to get the band radii around it, then pick
three angles whose bands are narrow.

The rules above cover the ordinary case. **Read `references/bridges.md` when
one of these applies:** the artwork has no band wide enough to land a foot on;
an island's only neighbour is across a wide gap; `verify_stl.py` reports more
bodies than expected and you need to work out which bridge missed; or you are
changing `arch()` / `bridge()` rather than calling them. It has the arch
geometry, the printability argument for a half torus, and a ranked list of
options when there is no good crossing. Skip it otherwise - placing bridges on
well-behaved artwork needs nothing beyond this page.

### The unbridged alternative

Bridges leave a visible break in the painted line. Sometimes the better answer
is to print the islands loose and let the user place them by hand, which is why
`bridges = false` is a parameter and not a fork in the file. Export both. The
loose version comes out as several disjoint bodies in one STL, which slicers
handle fine.

Offer both rather than picking for the user.

## Step 5: export and verify

```bash
openscad --export-format binstl -o out_bridged.stl design.scad
openscad --export-format binstl -o out_loose.stl -D 'bridges=false' design.scad
```

Note `--export-format binstl`. OpenSCAD writes ASCII STL by default, which is
five times the size for the same mesh.

Then check the result rather than assuming:

```bash
python3 scripts/verify_stl.py out_bridged.stl --expect-bodies 1 --expect-diameter 150
python3 scripts/verify_stl.py out_loose.stl --expect-bodies 3 --expect-diameter 150
```

It exits non-zero on a failed expectation. What the numbers mean:

- **the bridged version must be 1 body.** More than one means a bridge missed
  its landing and an island is still loose - exactly the failure bridging
  exists to prevent, and invisible in a top-down render. OpenSCAD's own
  `Volumes: 2` line on stderr says the same thing (it counts the infinite outer
  volume as one, so 2 is the good case).
- **the loose version has 1 + (island count) bodies**, matching step 2.
- **no non-manifold edges** in either, or the slicer's repair heuristics decide
  what your stencil looks like. If this fails and you have edited the bridge
  geometry, suspect tangency before anything else: a torus seated exactly on
  the plate's top plane touches it without crossing it, and CGAL tessellates
  that contact into slivers. It reports the union as simple and still exports a
  broken mesh. `bridge()` avoids it by sinking the arch 0.05 mm, so leave
  `sink` alone unless you are prepared to re-verify at several thicknesses -
  seated flush it fails at 0.6, 0.7, 0.8, 0.9 and 1.2 mm and passes only at
  1.0.
- **diameter equals `disc_d`.**

Do not run `analyse_outline.py` on the finished stencil. It measures islands *of
artwork*, and on a stencil the artwork and the plate have swapped places, so the
island count it reports means something else entirely.

## Step 6: preview in the browser

`assets/viewer/` is a self-contained three.js STL viewer. Copy it into the
project, vendor the three.js files, point `models.json` at the STLs, and serve
it - ES modules will not load over `file://`, so a plain HTTP server is needed:

```bash
cp -r assets/viewer .
mkdir -p viewer/lib && V=0.169.0
for f in build/three.module.js examples/jsm/controls/OrbitControls.js \
         examples/jsm/loaders/STLLoader.js; do
    curl -sSL -o "viewer/lib/$(basename $f)" "https://unpkg.com/three@$V/$f"
done
cat > viewer/models.json <<'JSON'
{
  "title": "My stencil",
  "bed": 220,
  "models": [
    { "label": "Bridged", "file": "../out_bridged.stl" },
    { "label": "Loose",   "file": "../out_loose.stl" }
  ]
}
JSON
PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')
python3 -m http.server $PORT --bind 127.0.0.1 &
curl -s http://127.0.0.1:$PORT/viewer/models.json   # confirm it is *your* config
xdg-open http://127.0.0.1:$PORT/viewer/index.html
```

Let the OS pick the port rather than hardcoding one. A stale server left running
on a port you guessed will happily serve someone else's project, and the
screenshot you take to check your work then shows their model - plausible, wrong,
and easy to miss. Fetching `models.json` over HTTP before trusting the page
costs nothing and rules it out.

`models.json` is the only file to edit. The viewer gives camera presets,
wireframe and crease edges, a printer bed grid at 10 mm cells (set `bed` to the
printer's build area, not its glass - an Ender 3 V2 is 220, not 235), a body /
triangle / size readout, and an explode slider that separates the loose
version's pieces so the islands are obvious.

The **Under** preset is the one that matters for review: it confirms the arches
left the underside flat. An arch foot poking through the bottom face will hold
the stencil off the surface and let paint bleed.

Before opening a browser for the user, render it headless once and look at the
PNG yourself - a JS error gives a blank page, and the user should not be the one
to find it:

```bash
google-chrome --headless=new --disable-gpu --enable-unsafe-swiftshader \
    --virtual-time-budget=12000 --window-size=1100,780 \
    --screenshot=/tmp/check.png http://127.0.0.1:$PORT/viewer/index.html
```

Check the body/triangle/size readout in the screenshot against what
`verify_stl.py` reported. If they disagree you are looking at the wrong model.

## Printing notes worth passing on

- Print flat, no supports. A half-torus arch of 2 mm section bridges itself.
- 0.8-1.2 mm thick. Thicker does not help and starts to lift the stencil off
  the surface at the edges of each cut-out, which causes bleed.
- Check the narrowest cut-out in the radial profile. Under about 1.5 mm the
  paint will not flow through cleanly and the slicer may drop the feature
  entirely at typical nozzle widths.
- `hole_offset` is the adjustment after a test print: positive if the lines came
  out too fine, negative if the paint bled.

## Files

- `scripts/analyse_outline.py` - island detection, enclosing circle, radial
  profile. Needs numpy, scipy and matplotlib.
- `scripts/flatten_svg.sh` - Inkscape SVG flattening.
- `scripts/verify_stl.py` - body count, manifold check, dimensions.
- `scripts/setup_viewer.sh` - installs the viewer and vendors three.js.
- `assets/stencil.scad` - `stencil_plate()`, `stencil_bridges()`, `arch()`.
- `assets/viewer/` - the three.js viewer; see step 6.
- `references/bridges.md` - arch geometry and bridge placement in depth.
- `references/svg-prep.md` - SVG import failure modes and fixes.
