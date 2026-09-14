#!/usr/bin/env python3
"""Check an exported stencil STL before anyone wastes filament on it.

Reports, per file: triangle count, separate bodies, non-manifold edges, overall
size and the diameter of the smallest circle about the z axis.

What the numbers should be:

  bridged version   1 body. More means a bridge missed its landing and an
                    island is still loose - the whole point of bridging.
  loose version     1 + (island count) bodies, matching analyse_outline.py.
  either            0 non-manifold edges, or slicers will do something
                    arbitrary with it.
  diameter          equal to disc_d.

Usage: verify_stl.py out_bridged.stl [out_loose.stl ...] [--expect-bodies N]
"""

import argparse
import struct
import sys
from collections import Counter

import numpy as np

STL_DTYPE = np.dtype([("n", "<3f4"), ("v", "<3,3f4"), ("a", "<u2")])


def read_stl(path):
    data = open(path, "rb").read()
    if data[:5] == b"solid" and b"facet normal" in data[:2048]:
        nums = [
            [float(x) for x in line.split()[1:4]]
            for line in data.decode("ascii", "replace").splitlines()
            if line.strip().startswith("vertex")
        ]
        v = np.array(nums, dtype=np.float64)
        return len(v) // 3, v
    n = struct.unpack("<I", data[80:84])[0]
    tris = np.frombuffer(data[84 : 84 + n * 50], dtype=STL_DTYPE)
    return n, tris["v"].reshape(-1, 3).astype(np.float64)


def inspect(path):
    n, verts = read_stl(path)
    # Weld vertices by rounded position: STL stores each triangle independently,
    # so shared corners only line up once they are snapped together.
    uniq, inv = np.unique(np.round(verts, 3), axis=0, return_inverse=True)
    inv = inv.reshape(n, 3)

    parent = np.arange(len(uniq))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    edges = Counter()
    for tri in inv:
        for i in range(3):
            a, b = int(tri[i]), int(tri[(i + 1) % 3])
            edges[(a, b) if a < b else (b, a)] += 1
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[ra] = rb

    roots = {find(i) for i in range(len(uniq))}
    bad = sum(1 for c in edges.values() if c != 2)
    sx, sy, sz = (uniq.max(0) - uniq.min(0)).tolist()
    dia = float(2 * np.hypot(uniq[:, 0], uniq[:, 1]).max())
    return dict(tris=n, bodies=len(roots), nonmanifold=bad,
                sx=sx, sy=sy, sz=sz, dia=dia)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stl", nargs="+")
    ap.add_argument("--expect-bodies", type=int, default=None)
    ap.add_argument("--expect-diameter", type=float, default=None)
    args = ap.parse_args()

    ok = True
    for path in args.stl:
        r = inspect(path)
        print(f"{path}")
        print(f"  triangles      {r['tris']}")
        print(f"  bodies         {r['bodies']}")
        print(f"  non-manifold   {r['nonmanifold']} edges")
        print(f"  size           {r['sx']:.2f} x {r['sy']:.2f} x "
              f"{r['sz']:.2f} mm")
        print(f"  diameter       {r['dia']:.2f} mm")

        if r["nonmanifold"]:
            print("  FAIL: not watertight", file=sys.stderr)
            ok = False
        if args.expect_bodies is not None and r["bodies"] != args.expect_bodies:
            print(f"  FAIL: expected {args.expect_bodies} bodies", file=sys.stderr)
            ok = False
        if args.expect_diameter is not None and \
                abs(r["dia"] - args.expect_diameter) > 0.05:
            print(f"  FAIL: expected diameter {args.expect_diameter}",
                  file=sys.stderr)
            ok = False

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
