// Reusable parts for turning flat artwork into a printable paint stencil.
//
// The artwork is passed in as a 2D shape (an imported SVG, or projection() of
// an extruded STL) and subtracted from a plate, so the artwork becomes the
// cut-outs. Pick a plate to suit the artwork - stencil_plate() for a logo,
// stencil_plate_rect() for lettering, where a disc would be mostly empty - then
// tie the islands back to the frame with bridge() or stencil_bridges().
//
// Sizing: the artwork is scaled to leave a margin of plate around it. Give the
// artwork's extent in its own units (art_r or art_size) and its centre (art_c);
// measure both with analyse_outline.py. thickness, rim/margin, hole_offset,
// foot and tube_r are all real millimetres, so they hold still as the plate
// grows.

// Scale applied to artwork in its own units to land it on a disc of disc_d.
function art_scale(disc_d, rim, art_r) = ((disc_d / 2) - rim) / art_r;

// Round plate with the artwork cut out of it. Artwork is the 2D child.
// art_r is the radius of the smallest circle enclosing the artwork.
module stencil_plate(disc_d, thickness, art_r, art_c = [0, 0], rim = 7,
                     hole_offset = 0) {
    s = art_scale(disc_d, rim, art_r);
    linear_extrude(height = thickness)
        difference() {
            circle(d = disc_d);
            scale([s, s])
                offset(delta = hole_offset / s)
                    translate(-art_c)
                        children();
        }
}

// Rounded-rectangle plate, for artwork that is much wider than it is tall.
// art_size is the artwork's [width, height] in its own units; the plate height
// follows from the artwork's aspect ratio, so only the width is specified.
module stencil_plate_rect(plate_w, thickness, art_size, art_c = [0, 0],
                          margin = 12, corner_r = 6, hole_offset = 0) {
    s = (plate_w - 2 * margin) / art_size[0];
    plate_h = art_size[1] * s + 2 * margin;
    linear_extrude(height = thickness)
        difference() {
            offset(r = corner_r)
                square([plate_w - 2 * corner_r, plate_h - 2 * corner_r],
                       center = true);
            scale([s, s])
                offset(delta = hole_offset / s)
                    translate(-art_c)
                        children();
        }
}

// Half torus lying in the XZ plane: spans `span` between the foot centres,
// tube radius `r`, feet centred on z = 0 and trimmed flat at z = -r.
module arch(span, r) {
    R = span / 2;
    intersection() {
        rotate([90, 0, 0])
            rotate_extrude()
                translate([R, 0, 0]) circle(r = r);
        translate([-(R + r), -r, -r]) cube([2 * (R + r), 2 * r, R + 2 * r]);
    }
}

// One arch straddling a band of cut-out, measured along a ray that leaves
// `origin` at `angle` and crosses the band between radii r0 and r1. The feet
// land `foot` mm clear of each edge.
//
// `origin` is a parameter rather than assumed to be [0,0] because artwork like
// a word has no single useful centre - each island wants its own ray origin,
// somewhere inside it, so the band radii still come straight off
// analyse_outline.py run with --centre at that point.
//
// Two details that are not obvious but matter:
//
// `sink` drops the arch a hair below the top face. Seated exactly at
// z = thickness the torus is tangent to the plate's top plane, and CGAL
// tessellates that contact into slivers - the export comes out non-manifold at
// every thickness except, by luck, 1.0. A few hundredths of a millimetre of
// overlap turns the tangency into a proper intersection and the mesh is clean.
//
// The intersection with z >= 0 guarantees the underside stays flat even when
// tube_r exceeds the plate thickness. Anything protruding below the bottom face
// holds the stencil off the surface and lets paint wick underneath.
module bridge(origin, angle, r0, r1, thickness, foot = 3.5, tube_r = 2.0,
              sink = 0.05) {
    span = (r1 - r0) + 2 * foot;
    big  = span + 2 * tube_r + 2;
    translate([origin[0], origin[1], 0])
        rotate([0, 0, angle])
            intersection() {
                translate([(r0 + r1) / 2, 0, thickness - sink])
                    arch(span, tube_r);
                translate([(r0 + r1) / 2 - big / 2, -big / 2, 0])
                    cube([big, big, big]);
            }
}

// Bridges for a round plate, placed radially from the centre.
//
// spec entries are [inner edge, outer edge, angle]: the two edges of the band
// to cross, as a fraction of the artwork's enclosing radius, so the table stays
// valid at any disc_d. Read the fractions off analyse_outline.py's radial
// profile, using an angle that misses the artwork's detail.
module stencil_bridges(disc_d, thickness, art_r, spec, rim = 7, foot = 3.5,
                       tube_r = 2.0, sink = 0.05) {
    R = (disc_d / 2) - rim;
    for (b = spec)
        bridge([0, 0], b[2], b[0] * R, b[1] * R, thickness, foot, tube_r, sink);
}
