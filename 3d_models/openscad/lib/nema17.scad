// ============================================================================
// Shared NEMA17 mounting hole pattern and plate helpers
// Pulls shared dims from constants.scad (safe with include or use).
// ============================================================================

include <constants.scad>

// Four M3 clearance holes on 31 mm square, centred on origin.
// Plate lies in XY; holes extrude along +Z by default.
module nema17_holes(h = 20, d = NEMA17_HOLE_D) {
    s = NEMA17_HOLE_SPACE / 2;
    for (x = [-s, s], y = [-s, s])
        translate([x, y, 0])
            cylinder(d = d, h = h, $fn = 24);
}

// Full motor-face plate: square body, centre pilot, 4× M3, optional shaft hole.
// Origin at plate centre, plate from z=0 to z=t (motor side is z=0 by convention).
module nema17_plate(
    t          = NEMA17_PLATE_T,
    face       = NEMA17_FACE,
    pilot_d    = NEMA17_PILOT_D,
    pilot_depth= 2.0,
    shaft_d    = NEMA17_SHAFT_CLEAR,
    hole_d     = NEMA17_HOLE_D
) {
    difference() {
        // Body — slight corner chamfer via minkowski optional; keep simple
        hull() {
            r = 3;
            for (x = [-1, 1], y = [-1, 1])
                translate([x*(face/2 - r), y*(face/2 - r), 0])
                    cylinder(r = r, h = t, $fn = 24);
        }
        // Shaft through-hole
        translate([0, 0, -0.1])
            cylinder(d = shaft_d, h = t + 0.2, $fn = 48);
        // Pilot recess on motor face (z=0)
        translate([0, 0, -0.05])
            cylinder(d = pilot_d, h = pilot_depth + 0.05, $fn = 48);
        // Mounting holes
        translate([0, 0, -0.1])
            nema17_holes(h = t + 0.2, d = hole_d);
    }
}

// 2D outline of NEMA17 face (for extrusions / boolean bases)
module nema17_face_2d(face = NEMA17_FACE, r = 3) {
    hull() {
        for (x = [-1, 1], y = [-1, 1])
            translate([x*(face/2 - r), y*(face/2 - r)])
                circle(r = r, $fn = 24);
    }
}

// Preview: four hole centres as points (debug)
module nema17_hole_centres() {
    s = NEMA17_HOLE_SPACE / 2;
    for (x = [-s, s], y = [-s, s])
        translate([x, y, 0])
            sphere(d = 1, $fn = 12);
}
