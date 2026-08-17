#!/usr/bin/env python3
"""Measure the exported STL and compare it to what it was supposed to be.

check_stl.py asks whether the mesh is sane. This asks whether it is the RIGHT SIZE — the
separate question, and the one that decides whether the knob goes on the shaft.

⚠ It reports by Z LEVEL rather than by sampling arbitrary heights. A tapered linear_extrude
only carries vertices at its two ends and at the chamfers, so slicing it at mid-height finds
nothing at all — an earlier version of this script did exactly that, found no outer wall, and
cheerfully reported the BORE as the outer diameter. Levels are what the mesh actually has.

At each level it splits the radii into an inner cluster (the bore) and an outer one (the
flank), so the two never get confused again.

Usage:  ./measure_stl.py nutone_knob.stl
"""
import sys
from collections import defaultdict
from math import hypot

SPLIT = 4.50         # mm: radii below this are bore, above are outer wall. The widest point
                     # of the bore is the lead-in mouth at 4.36; the narrowest outer feature
                     # is the front chamfer's first ring at 4.60. 4.50 sits cleanly between,
                     # so neither column ever picks up the other's vertices.


def load(path):
    out = []
    for line in open(path):
        t = line.split()
        if t and t[0] == "vertex":
            out.append(tuple(float(v) for v in t[1:4]))
    return out


def main(path):
    v = load(path)
    levels = defaultdict(list)
    for p in v:
        levels[round(p[2], 3)].append(p)

    zs = sorted(levels)
    print(f"  height {max(zs) - min(zs):.2f} mm, {len(zs)} distinct z levels\n")
    print("     z      outer dia      bore arc dia   flat y    across flats")
    print("   ------  -------------  --------------  -------  -------------")
    for z in zs:
        pts = levels[z]
        inner = [p for p in pts if hypot(p[0], p[1]) < SPLIT]
        outer = [p for p in pts if hypot(p[0], p[1]) >= SPLIT]
        od = f"{2 * max(hypot(p[0], p[1]) for p in outer):6.2f}" if outer else "     -"
        if inner:
            r = max(hypot(p[0], p[1]) for p in inner)
            fy = min(p[1] for p in inner)
            bd, fys, af = f"{2 * r:6.2f}", f"{fy:6.2f}", f"{r - fy:6.2f}"
        else:
            bd = fys = af = "     -"
        print(f"   {z:6.2f}  {od}         {bd}          {fys}   {af}")

    print()
    print("  Expected (all MODELLED sizes; add 0.15 back for what the outsides print):")
    print("    overall      26.50  = grip 17.00 + stem 9.50")
    print("    grip         25.65 at z=0 front  ->  27.20 at z=17 back")
    print("                   prints 25.80 / 27.35")
    print("    stem         10.85 from z=17 to z=26.5, parallel")
    print("                   prints 11.00")
    print("    bore          7.34 arc, flat on y=0, across flats 3.67")
    print("                   prints ~7.15 over a 7.00 shaft = 0.15 clearance")
    print("    socket floor  z=5.00 (21.50 deep), leaving a 5.00 solid front face")


if __name__ == "__main__":
    for p in sys.argv[1:] or ["nutone_knob.stl"]:
        print(f"\n{p}")
        main(p)
    print()
