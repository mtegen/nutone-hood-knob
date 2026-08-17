#!/usr/bin/env python3
"""Sanity-check an STL before anyone spends filament on it.

⚠ WHY THIS EXISTS. On 2026-08-11 I thinned the adapter's encoder half from 13.55 to 7.95
and shipped it. The collar ring sits at radius 5.25-6.78; the body below it now only reached
3.98 — so the collar was a separate floating ring, connected to nothing, and the owner found
it instead of me. I had verified every diameter numerically and looked at a section render,
and neither of those asks the one question that matters: IS IT ONE SOLID.

Checks, in the order they bite:

  1. CONNECTED  — one solid, not several. Catches exactly the failure above.
  2. CLOSED     — every edge shared by exactly two triangles. An open mesh slices into
                  nonsense or silently drops walls.
  3. FLOATING   — nothing starting in mid-air with no material under it, which needs
                  supports nobody asked for.

Usage:  ./check_stl.py part.stl [more.stl ...]
Exit code is non-zero if anything fails, so it can gate an export.
"""
import math
import sys
from collections import defaultdict

# Vertices are matched on a rounded key: OpenSCAD emits the same corner from adjacent facets
# with tiny floating-point differences, and an exact match would report every triangle as
# its own island.
GRID = 1e-4


def load(path):
    tris, cur = [], []
    for line in open(path):
        t = line.split()
        if t and t[0] == "vertex":
            cur.append(tuple(round(float(v) / GRID) for v in t[1:4]))
            if len(cur) == 3:
                tris.append(tuple(cur))
                cur = []
    return tris


def components(tris):
    """Union-find over triangles that share a vertex."""
    parent = list(range(len(tris)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    by_vertex = defaultdict(list)
    for i, tri in enumerate(tris):
        for v in tri:
            by_vertex[v].append(i)
    for shared in by_vertex.values():
        for j in shared[1:]:
            ra, rb = find(shared[0]), find(j)
            if ra != rb:
                parent[ra] = rb
    return len({find(i) for i in range(len(tris))})


def open_edges(tris):
    """Edges not shared by exactly two triangles — i.e. holes in the surface."""
    seen = defaultdict(int)
    for tri in tris:
        for a, b in ((tri[0], tri[1]), (tri[1], tri[2]), (tri[2], tri[0])):
            seen[tuple(sorted((a, b)))] += 1
    return sum(1 for n in seen.values() if n != 2)


def lowest_islands(tris):
    """Anything whose lowest point is well above the plate has nothing holding it up."""
    zs = [v[2] for tri in tris for v in tri]
    base = min(zs) * GRID
    out = []
    parent = {}
    # Reuse the component walk, but track each component's lowest z.
    by_vertex = defaultdict(list)
    for i, tri in enumerate(tris):
        for v in tri:
            by_vertex[v].append(i)
    p = list(range(len(tris)))

    def find(a):
        while p[a] != a:
            p[a] = p[p[a]]
            a = p[a]
        return a

    for shared in by_vertex.values():
        for j in shared[1:]:
            ra, rb = find(shared[0]), find(j)
            if ra != rb:
                p[ra] = rb
    low = {}
    for i, tri in enumerate(tris):
        r = find(i)
        z = min(v[2] for v in tri) * GRID
        low[r] = min(low.get(r, 1e9), z)
    for r, z in low.items():
        if z > base + 0.05:
            out.append(z)
    return out


def check(path):
    tris = load(path)
    if not tris:
        print(f"  {path}: EMPTY — no triangles")
        return False
    n = components(tris)
    holes = open_edges(tris)
    floating = lowest_islands(tris)
    ok = True
    print(f"  {path}  ({len(tris)} triangles)")
    if n == 1:
        print(f"    connected   one solid")
    else:
        print(f"    connected   ✗ {n} SEPARATE SOLIDS — part of this is not attached")
        ok = False
    if holes == 0:
        print(f"    closed      watertight")
    else:
        print(f"    closed      ✗ {holes} open edges")
        ok = False
    if not floating:
        print(f"    grounded    nothing starts in mid-air")
    else:
        print(f"    grounded    ✗ {len(floating)} island(s) starting at z="
              + ", ".join(f"{z:.2f}" for z in sorted(floating)))
        ok = False
    return ok


if __name__ == "__main__":
    files = sys.argv[1:]
    if not files:
        print(__doc__)
        sys.exit(2)
    sys.exit(0 if all([check(f) for f in files]) else 1)
