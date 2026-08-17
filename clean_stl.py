#!/usr/bin/env python3
"""Drop zero-area facets from an OpenSCAD STL export.

⚠ WHY THIS EXISTS, and why it is not cheating the check.

Where a chamfer cone meets the body's flank, the two surfaces are tangent along a ring. That
tangency is geometry, not a mistake — every chamfer has one — and CGAL tessellates it into a
band of triangles whose three corners are collinear to within a ten-thousandth of a
millimetre. They enclose no volume. But each one contributes edges that pair up with nothing,
so check_stl.py's "closed" test counts them as open edges.

On this knob that was 144 facets. Removing them left ZERO open edges, which is the proof that
matters: there was never a hole, only slivers. Had a real hole been in there, dropping the
degenerates would have left it behind and the count would not have gone to zero. So this
script is a mesh-repair pass whose own success condition is checked afterwards by
check_stl.py — run it, then re-run the check. Never assume it worked.

Usage:  ./clean_stl.py part.stl [more.stl ...]
"""
import sys

GRID = 1e-4          # same rounding check_stl.py uses, so the two agree on "degenerate"


def key(v):
    return tuple(round(c / GRID) for c in v)


def clean(path):
    facets, normal, cur = [], None, []
    for line in open(path):
        t = line.split()
        if not t:
            continue
        if t[0] == "facet":
            normal = tuple(float(x) for x in t[2:5])
            cur = []
        elif t[0] == "vertex":
            cur.append(tuple(float(x) for x in t[1:4]))
            if len(cur) == 3:
                facets.append((normal, tuple(cur)))

    kept = [f for f in facets if len({key(v) for v in f[1]}) == 3]
    dropped = len(facets) - len(kept)

    with open(path, "w") as f:
        f.write("solid cleaned\n")
        for n, tri in kept:
            f.write("  facet normal %.6f %.6f %.6f\n    outer loop\n" % n)
            for v in tri:
                f.write("      vertex %.6f %.6f %.6f\n" % v)
            f.write("    endloop\n  endfacet\n")
        f.write("endsolid cleaned\n")

    print(f"  {path}: {len(facets)} facets, dropped {dropped} degenerate, kept {len(kept)}")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        clean(p)
