#!/usr/bin/env python3
"""Analyse a flat prism STL to work out what a stencil made from it needs.

The input is an STL of the artwork extruded straight up from z = 0, which is
what both `linear_extrude(h) import("art.svg")` and a pre-made logo STL give
you. Everything is measured off the z = 0 face.

Reports:
  - the outline loops and the smallest circle enclosing the artwork
  - how many islands a stencil cut from this artwork would have, i.e. how many
    pieces fall out because they are ringed by cut-outs
  - a radial profile from the chosen centre, so you can see where the solid
    bands sit and pick angles for bridges that miss the detail

Usage:
    analyse_outline.py art.stl [--centre X Y] [--angles 0,30,60,...]
"""

import argparse
import struct
import sys
from collections import defaultdict

import numpy as np
from matplotlib.path import Path
from scipy import ndimage
from scipy.optimize import minimize

STL_DTYPE = np.dtype([("n", "<3f4"), ("v", "<3,3f4"), ("a", "<u2")])


def read_stl(path):
    """Return (n_triangles, vertices) for an ASCII or binary STL."""
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet normal" in data[:2048]:
        nums = []
        for line in data.decode("ascii", "replace").splitlines():
            if line.strip().startswith("vertex"):
                nums.append([float(x) for x in line.split()[1:4]])
        v = np.array(nums, dtype=np.float64)
        return len(v) // 3, v
    n = struct.unpack("<I", data[80:84])[0]
    tris = np.frombuffer(data[84 : 84 + n * 50], dtype=STL_DTYPE)
    return n, tris["v"].reshape(-1, 3).astype(np.float64)


def base_loops(verts, n):
    """Closed polygons of the z = 0 face, largest area first.

    Only triangles lying entirely in the base plane are used. Edges shared by
    two such triangles are interior and cancel; what survives is the boundary.
    """
    segs = set()
    for t in verts.reshape(n, 3, 3):
        if not (t[:, 2] == 0).all():
            continue
        for i in range(3):
            a, b = t[i], t[(i + 1) % 3]
            ka = (round(a[0], 4), round(a[1], 4))
            kb = (round(b[0], 4), round(b[1], 4))
            if ka != kb:
                segs ^= {(ka, kb) if ka < kb else (kb, ka)}

    adj = defaultdict(list)
    for a, b in segs:
        adj[a].append(b)
        adj[b].append(a)

    seen, loops = set(), []
    for start in adj:
        if start in seen:
            continue
        loop, prev, cur = [start], None, start
        seen.add(start)
        while True:
            nxt = [x for x in adj[cur] if x != prev and x not in seen]
            if not nxt:
                break
            cur, prev = nxt[0], cur
            loop.append(cur)
            seen.add(cur)
        loops.append(np.array(loop))

    area = lambda p: 0.5 * np.sum(
        p[:, 0] * np.roll(p[:, 1], -1) - np.roll(p[:, 0], -1) * p[:, 1]
    )
    return sorted(loops, key=lambda l: -abs(area(l))), area


def enclosing_circle(loops, guess):
    """Centre and radius of (approximately) the smallest circle over all loops.

    Every loop is included, not just the largest. Artwork made of several
    disjoint shapes - a word, a wordmark, a badge with separate elements - has
    no single loop that encloses it, and fitting only the biggest one silently
    returns the extent of one glyph instead of the whole design.
    """
    pts = np.vstack(loops)
    f = lambda c: np.hypot(pts[:, 0] - c[0], pts[:, 1] - c[1]).max()
    r = minimize(f, guess, method="Nelder-Mead",
                 options={"xatol": 1e-6, "fatol": 1e-9})
    return r.x, r.fun


def rasterise(loops, half, res):
    """Boolean grid of the artwork. Odd crossing count = inside."""
    xs = np.arange(-half, half, res)
    X, Y = np.meshgrid(xs, xs)
    pts = np.c_[X.ravel(), Y.ravel()]
    inside = np.zeros(len(pts), bool)
    for l in loops:
        inside ^= Path(l).contains_points(pts)
    return inside.reshape(X.shape), xs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stl")
    ap.add_argument("--centre", nargs=2, type=float, default=None,
                    help="centre for the radial profile; default is the "
                         "centre of the smallest enclosing circle")
    ap.add_argument("--angles", default=",".join(str(a) for a in range(0, 360, 30)))
    ap.add_argument("--res", type=float, default=0.25, help="raster step in mm")
    args = ap.parse_args()

    n, verts = read_stl(args.stl)
    lo, hi = verts.min(0), verts.max(0)
    print(f"{args.stl}: {n} triangles")
    print(f"  bbox    x {lo[0]:.2f}..{hi[0]:.2f}  y {lo[1]:.2f}..{hi[1]:.2f}"
          f"  z {lo[2]:.2f}..{hi[2]:.2f}")
    if lo[2] != 0:
        print("  note: base is not at z = 0, loop extraction will find nothing",
              file=sys.stderr)

    loops, area = base_loops(verts, n)
    print(f"  outline loops: {len(loops)}")
    for i, l in enumerate(loops):
        print(f"    {i}: {len(l):4d} pts  area {area(l):9.1f}")

    centre, R = enclosing_circle(loops, (lo[:2] + hi[:2]) / 2)
    print(f"  smallest enclosing circle: centre ({centre[0]:.3f}, "
          f"{centre[1]:.3f})  r {R:.3f}")
    aw, ah = hi[0] - lo[0], hi[1] - lo[1]
    print(f"  artwork bbox size: {aw:.3f} x {ah:.3f}  centre "
          f"({(lo[0] + hi[0]) / 2:.3f}, {(lo[1] + hi[1]) / 2:.3f})")
    if aw > 1.8 * ah or ah > 1.8 * aw:
        print("  note: artwork is much wider than tall (or vice versa) - a round "
              "plate would be mostly empty; consider stencil_plate_rect()")

    cx, cy = args.centre if args.centre else centre
    half = float(np.abs(np.r_[lo[:2], hi[:2]]).max()) + 10
    solid, _ = rasterise(loops, half, args.res)

    lab, nlab = ndimage.label(~solid)
    lab = np.asarray(lab)
    # Anything touching the raster border is the surrounding plate, not
    # an island; everything else is a piece that would fall out.
    edge = set(np.r_[lab[0], lab[-1], lab[:, 0], lab[:, -1]].tolist())
    islands = [i for i in range(1, nlab + 1) if i not in edge]
    print(f"  stencil islands: {len(islands)} (pieces that fall out unbridged)")
    for i in islands:
        m = lab == i
        ys, xs_ = np.nonzero(m)
        print(f"    area {m.sum() * args.res ** 2:8.0f} mm2   "
              f"x {xs_.min() * args.res - half:7.1f}..{xs_.max() * args.res - half:7.1f}"
              f"  y {ys.min() * args.res - half:7.1f}..{ys.max() * args.res - half:7.1f}")

    print(f"  radial profile from ({cx:.2f}, {cy:.2f}) - solid runs, r in mm:")
    at = lambda x, y: solid[int(round((y + half) / args.res)),
                            int(round((x + half) / args.res))]
    for adeg in [float(a) for a in args.angles.split(",")]:
        a = np.radians(adeg)
        runs, prev, start = [], False, 0.0
        for r in np.arange(0, R + 5, 0.05):
            s = at(cx + r * np.cos(a), cy + r * np.sin(a))
            if s and not prev:
                start = r
            if prev and not s and r - start > 0.5:
                runs.append((start, r))
            prev = s
        print(f"    {adeg:6.1f}  " +
              "  ".join(f"{a_:.2f}-{b_:.2f} (w{b_ - a_:.2f})" for a_, b_ in runs))


if __name__ == "__main__":
    main()
