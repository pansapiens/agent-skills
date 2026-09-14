# Bridges: why arches, and where to put them

## The problem

Subtract artwork from a plate and some of the plate may end up completely
enclosed by cut-out. Those pieces - islands - have nothing holding them. The
classic case is the counter of a letter: the middle of an O, D, A, P, or the two
counters of a B. Logos with concentric rings have the same problem one level up,
where the whole annulus between two rings is an island.

Traditional stencils solve this with a **bridge** (or tie): a deliberate gap in
the artwork that connects the island to the frame, leaving a small unpainted
break in the line. That is a change to the artwork, and on a logo with any
recognisability it is usually unwelcome.

A 3D print offers a second option that paper does not: leave the artwork intact
and connect the islands **over the top** of the cut-out, in the third dimension.
The painted result is then the unmodified logo.

## Why a half torus

The arch has to leave the underside flat. Any material on the bottom face holds
the stencil off the surface, and paint wicks under the gap.

A half torus - a tube bent through 180 degrees, standing on its two ends -
satisfies that, and prints well on an FDM machine without supports:

- at the springing, the outer surface is vertical: no overhang
- the overhang angle increases smoothly toward the apex
- at the apex the underside is horizontal, but the tube is only `2 * bridge_r`
  across, so each layer advances by at most `bridge_r` over unsupported air -
  a bridge distance any printer handles

A flat tab spanning the same gap would need supports or would sag; a triangular
gusset would print but looks like a mistake. The arch reads as deliberate.

`arch(span, r)` in `stencil.scad` builds it:

```openscad
module arch(span, r) {
    R = span / 2;
    intersection() {
        rotate([90, 0, 0])
            rotate_extrude()
                translate([R, 0, 0]) circle(r = r);
        translate([-(R + r), -r, -r]) cube([2 * (R + r), 2 * r, R + 2 * r]);
    }
}
```

`rotate_extrude()` makes a torus in the XY plane; `rotate([90,0,0])` stands it
up in XZ; the cube keeps `z >= -r`, which is the arch plus its two full-round
feet. `span` is measured **foot centre to foot centre**, so the tube reaches
`span/2 + r` either side and `span/2 + r` high.

## Sitting it on the plate

`bridge()` seats each arch at `z = thickness - sink` and then intersects it with
`z >= 0`. Both halves of that matter, and neither is obvious:

**The sink.** Seated exactly at `z = thickness`, the torus is *tangent* to the
plate's top plane. CGAL reports the union as simple, but the STL tessellation
emits slivers all around each foot and the exported mesh is non-manifold. Swept
across plate thicknesses it fails at 0.6, 0.7, 0.8, 0.9 and 1.2 mm and passes
only at 1.0 - the value that happens to put the arch's own trim plane exactly on
the plate's bottom face. A skill validated at one thickness would look perfect
and break the moment anyone changed it. Dropping the arch a few hundredths of a
millimetre turns the tangency into a genuine overlap and the export is clean at
every thickness.

**The clamp.** Intersecting with `z >= 0` means a tube fatter than the plate no
longer punches through the underside; it just gets cut off flush. Without it,
`bridge_r > thickness` silently produces feet that stand proud of the bottom
face, hold the stencil off the surface, and let paint wick under. With it,
`bridge_r` is a free choice rather than a constraint to remember.

The **Under** view in the viewer is still worth a look, but it should now never
show anything.

## Choosing positions

`stencil_bridges()` takes `[inner edge, outer edge, angle]` per arch, where the
edges are the two sides of the band of artwork to cross, as a fraction of the
artwork's enclosing radius. It derives the span as
`(outer - inner) * printed_radius + 2 * foot` and centres the arch on the band.
Expressing the band as a fraction means the table stays correct when `disc_d`
changes.

Read the fractions off `analyse_outline.py`'s radial profile - each row lists
the solid runs along one ray. Divide by the enclosing radius it printed.

Rules of thumb:

**Work outward.** Each island needs a connected path to the rim, not just to
some other island. Bridge the outermost island to the rim first, then each inner
island to the island immediately outside it. Two islands connected only to each
other are still one loose piece.

**Three per island.** One bridge is a hinge and the island rotates. Two on
opposite sides is a see-saw and it still rocks. Three at roughly 120 degrees
holds it flat. For a long thin island, spread them along its length instead.

**Cross the narrowest point.** A shorter span is a shorter, stiffer arch that is
also less conspicuous. If the band varies in width, probe with `--angles` to
find the thin spot.

**Miss the detail.** If the artwork has n-fold symmetry with features at certain
angles, put the bridges midway between them. On the SCP emblem the arrows sit at
90 / 210 / 330 degrees, so bridges go at 30 / 150 / 270 - and because the inner
and outer bridges share those angles, they line up radially and read as
deliberate rather than scattered.

**Keep the feet clear.** `foot` is the distance from the band edge to the foot
centre; the tube extends `bridge_r` further. The default `foot = 3.5` with
`bridge_r = 2` puts 1.5 mm of clear plate between the tube and the cut-out
edge.

**Measure from inside the island.** Band radii and ray origin have to agree. For
a centred logo that origin is the artwork centre and `stencil_bridges()` handles
it. For anything else - letters, a scattered wordmark - pass the island's own
centre to `bridge()` and take the band radii from
`analyse_outline.py --centre <that point>`. Radii measured from one origin and
applied from another put the feet in the wrong place, usually landing the whole
arch inside the island where it connects nothing.

## When there is no good crossing

Sometimes an island's only neighbours are across a wide cut-out, or the artwork
is so fine there is nowhere to land a foot. Options, roughly in order of how
much they change the design:

1. **Widen the disc and reach from the rim.** A single long arch from the rim to
   a deep island is legitimate; it just gets tall. An arch spanning 40 mm stands
   21 mm high, which is fine to print but easy to knock.
2. **Chain through another island.** Rim to island A, then A to island B, even
   if A and B are not adjacent in the obvious sense.
3. **Thicken the artwork slightly** with a negative `hole_offset` so a foot
   fits. A tenth of a millimetre of line weight is invisible in paint.
4. **Give up on bridging that island** and ship it loose in the `bridges=false`
   version. For a single small island in an otherwise well-connected stencil
   this is often the better answer anyway.

## The unbridged option

`bridges = false` leaves the islands as separate bodies in the same STL. The
user places them by hand before painting, usually with a dab of low-tack
adhesive, and gets an unbroken painted line with no arches to work around.

It is worth exporting both every time. The bridged version is more convenient;
the loose version is more faithful. Which matters more is the user's call, and
it costs one extra `-D 'bridges=false'` to give them the choice.
