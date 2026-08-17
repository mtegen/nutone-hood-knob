// NuTone range-hood control knob — replacement
//
// Standalone. Nothing here is shared with any other project.
//
// ⚠ THE SHAPE IS STEPPED. A NARROW STEM carries the D socket; behind it a MUCH WIDER KNURLED
// GRIP is the part a person touches. An early version modelled the whole thing as one 10.8
// tube. That was wrong and the owner caught it.
//
// ⚠ SIZES ARE MEASURED, NOT SCALED OFF PHOTOGRAPHS. An earlier version derived the grip from
// the photos and got 22.7 against a real 27.35 — 20% out. Photographs settle the SHAPE here;
// they have no business setting a SIZE.
//
// ⚠ THE OVERALL HEIGHT IS DERIVED, NOT ENTERED. It is grip_t + stem_l and nothing else, so
// the two heights can never disagree with a third number. Asking for an overall reading when
// both pieces were already given was my mistake, not a missing measurement.
//
//        <-------- grip_d 27.35 back -------->    the part you touch, knurled,
//         ___________________________________     tapering to 25.80 at the front
//        |                                   |    grip_t 9.50
//        |___________________________________|
//                    |         |                  <- stem_d 11.00, parallel
//                    |         |                     stem_l 17.00
//                    |  O7.00  |                     2.00 of wall around the bore
//                    |  D bore |
//                    |         |
//                    |_________|
//
//                    overall 26.50 = 9.50 + 17.00
//
// Exports:
//   openscad -D 'part="knob"'  -o nutone_knob.stl       nutone_knob.scad
//   openscad -D 'part="gauge"' -o nutone_knob_gauge.stl nutone_knob.scad

part = "knob";              // "knob" | "gauge" | "section"

/* ---- MEASURED by the owner, with calipers ------------------------------------------ */
shaft_d      = 7.00;       // MEASURED on the hood's shaft itself, across the round part at
                           // its widest. Measured on the SHAFT, not the broken socket — a
                           // cracked socket splays open and reads oversize.
stem_d       = 11.00;      // MEASURED. Parallel — it does NOT taper.
stem_l       = 17.00;      // MEASURED, how far the stem stands off the back of the dial
grip_d_back  = 27.35;      // MEASURED, at the back — the widest end, against the panel
grip_d_front = 25.80;      // MEASURED, at the front — the face you look at
grip_t       =  9.50;      // MEASURED, the dial's own height

/* ---- STILL NOT MEASURED — each is one variable ------------------------------------- */
shaft_flat   = 3.50;       // ⚠ ASSUMED a TRUE half-round: the flat through the shaft's
                           // centre, which is what "a half circle" encodes. If the flat is
                           // cut shallower this number is bigger and the socket will not go
                           // on. Measure flat face -> opposite arc. The gauge's round
                           // control station exists to catch exactly this.
front_wall   = 5.00;       // ⚠ CHOSEN, not measured. Sets the socket depth, and the error is
                           // ONE-SIDED: a socket deeper than the shaft costs nothing — the
                           // shaft just does not reach the bottom and the D drives the knob
                           // the same — while a socket shallower than the shaft stops the
                           // knob seating flush to the panel. So this errs deep on purpose.

/* ---- WHAT THE PRINTER DOES TO THESE NUMBERS -----------------------------------------
   Bambu A1 mini, 0.4 nozzle. Not published ranges — what this printer was measured doing:
     HOLES SHRINK   0.20 at O6, 0.15 at O10. Scales with hole-to-nozzle ratio, so O7 is
                    interpolated rather than taking the small-hole figure.
     OUTSIDES GROW  0.15.
     ELEPHANT FOOT  first layers splay; the front chamfer is sized for it, not decorative.
   ⚠ If you switch these on in Bambu Studio instead, zero them here or they apply twice. */
hole_shrink  = 0.19;
ext_grow     = 0.15;
foot_chamfer = 0.60;
edge_chamfer = 0.50;

socket_fit   = 0.15;       // diametral clearance, socket over shaft — a light press. The
                           // knob is held on by friction; the original has no set screw.

/* ---- APPEARANCE ---------------------------------------------------------------------- */
flutes       = 48;         // knurl count on the GRIP. 48 around 27.35 is a 1.79 mm pitch,
                           // which a 0.4 nozzle can actually render. Finer just blobs.
flute_depth  = 0.45;
fillet       = 1.50;       // gusset where the stem meets the grip. Not cosmetic — this is
                           // the junction that carries all the torque, and the original
                           // broke at the stem.
insert_recess= false;      // the original's white printed disc; see NUTONE-KNOB.md
insert_d     = 21.00;
insert_deep  = 0.80;

$fn = 128;

/* ==== DERIVED ========================================================================= */
total_h   = grip_t + stem_l;                 // 26.50 — the owner's two heights, added
socket_depth = total_h - front_wall;         // 21.50 — through the stem, into the grip

bore_d    = shaft_d + hole_shrink + socket_fit;
bore_r    = bore_d / 2;
bore_flat = shaft_flat + (hole_shrink + socket_fit) / 2;
flat_y    = bore_r - bore_flat;              // 0 when it is a true half-round

gd_front  = grip_d_front - ext_grow;
gd_back   = grip_d_back  - ext_grow;
sd        = stem_d       - ext_grow;

/* ==== PARTS =========================================================================== */

// The D socket, as a solid to subtract. Origin at its mouth, growing +z.
module d_socket(depth) {
    intersection() {
        cylinder(d = bore_d, h = depth);
        translate([-bore_d, flat_y, 0]) cube([2 * bore_d, 2 * bore_d, depth]);
    }
}

// Removes everything outside a 45-degree cone, giving a chamfer in a thin z band.
// grow=true chamfers a bottom edge, false chamfers a top edge.
module chamfer_ring(z0, d, ch, grow = true) {
    translate([0, 0, z0]) difference() {
        cylinder(d = d + 10, h = ch);
        if (grow) cylinder(d1 = d - 2 * ch, d2 = d + 0.01, h = ch);
        else      cylinder(d1 = d + 0.01,   d2 = d - 2 * ch, h = ch);
    }
}

// The knurled grip, tapering front to back. Knurl on the grip only — the stem is smooth,
// as on the original.
// ⚠ The flute cutters get their OWN low segment count. Left on $fn=128 a 1.4 mm circle is
// tessellated far finer than the printer can resolve, and where those arcs cross the body's
// arc they produce zero-area sliver triangles.
module grip() {
    linear_extrude(height = grip_t, scale = gd_back / gd_front, convexity = 10)
        difference() {
            circle(d = gd_front);
            for (i = [0 : flutes - 1])
                rotate([0, 0, i * 360 / flutes])
                    translate([gd_front / 2 + 0.70 - flute_depth, 0])
                        circle(d = 1.40, $fn = 16);
        }
}

module knob() {
    difference() {
        union() {
            grip();
            translate([0, 0, grip_t]) cylinder(d = sd, h = stem_l);          // the stem
            translate([0, 0, grip_t])                                        // the gusset
                cylinder(d1 = sd + 2 * fillet, d2 = sd, h = fillet);
        }

        // The socket, opening at the stem tip and reaching down into the grip.
        translate([0, 0, total_h - socket_depth]) d_socket(socket_depth + 0.1);

        // Lead-in at the mouth so the knob starts onto the shaft square. 45 degrees, which
        // prints as a self-supporting overhang.
        translate([0, 0, total_h - 0.80])
            cylinder(d1 = bore_d, d2 = bore_d + 1.60, h = 0.81);

        // Front face: elephant-foot relief. This face goes on the plate.
        chamfer_ring(0, gd_front, foot_chamfer, true);
        // Back of the grip, and the stem tip.
        chamfer_ring(grip_t - edge_chamfer, gd_back, edge_chamfer, false);
        chamfer_ring(total_h - edge_chamfer, sd, edge_chamfer, false);

        if (insert_recess)
            translate([0, 0, -0.01]) cylinder(d = insert_d + hole_shrink, h = insert_deep);
    }
}

/* ==== THE FIT GAUGE ==================================================================
   Six stations: five D sockets stepping the bore, plus one plain ROUND hole as a control.
     - A D station grips firmly and square -> that is your number.
     - None of the D stations go on but the round one does -> the bore is fine and the FLAT
       is wrong. Measure flat-to-far-arc and raise shaft_flat.
   Labels are the modelled bore in hundredths, dropping the leading 7. "34" is the default. */
gauge_bores  = [7.14, 7.24, 7.34, 7.44, 7.54];
gauge_labels = ["14", "24", "34", "44", "54"];

module gauge() {
    pitch = 13; n = len(gauge_bores) + 1;
    span  = (n - 1) * pitch;
    difference() {
        union() {
            translate([-span / 2 - 7, -10, 0]) cube([span + 14, 20, 2]);
            for (i = [0 : n - 1]) translate([-span / 2 + i * pitch, 3, 0]) cylinder(d = 11, h = 7);
        }
        for (i = [0 : len(gauge_bores) - 1])
            translate([-span / 2 + i * pitch, 3, -0.1])
                intersection() {
                    cylinder(d = gauge_bores[i], h = 7.2);
                    translate([-8, 0, 0]) cube([16, 16, 7.2]);   // flat on y = 0
                }
        translate([-span / 2 + 5 * pitch, 3, -0.1]) cylinder(d = 7.34, h = 7.2);
    }
    for (i = [0 : len(gauge_bores) - 1])
        translate([-span / 2 + i * pitch, -8.5, 2])
            linear_extrude(0.6) text(gauge_labels[i], size = 4, halign = "center");
    translate([-span / 2 + 5 * pitch, -8.5, 2])
        linear_extrude(0.6) text("RND", size = 4, halign = "center");
}

// ⚠ Cut on x, NOT on y: the socket's flat lies on y = 0, so a y-cut is coplanar with it and
// renders as a blank wall showing nothing. Look at this one, never print it.
module section() {
    difference() { knob(); translate([0, -25, -1]) cube([30, 50, total_h + 2]); }
}

if      (part == "knob")    knob();
else if (part == "gauge")   gauge();
else if (part == "section") section();
