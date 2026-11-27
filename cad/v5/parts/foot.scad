// parts/foot.scad: OWNER group BAR. Contract: cad/v5/README.md
// FOOT (TPU 95A): a grippy pad under each leg toe. The pad is BAR_FOOT_L long,
// 0.4 mm inset from both leg faces (it reads as a dark sole line), and stands
// BAR_FOOT_PROUD below the leg. A key with crush ribs presses into the toe
// recess (0.1 mm interference per side). Shared constants: parts/bay.scad, leg.scad.
include <../params.scad>

BAR_FOOT_RIB = 0.3;   // crush rib height on each long side of the key

module foot_pad() {
    h = BAR_FOOT_PROUD; c = 0.6;
    hull() {
        translate([0, 0, c]) linear_extrude(h - c) rrect([BAR_FOOT_W, BAR_FOOT_L], r=2);
        linear_extrude(EPS) offset(delta=-c) rrect([BAR_FOOT_W, BAR_FOOT_L], r=2);
    }
}
module foot_key() {
    k = BAR_KEY;
    translate([0, 0, BAR_FOOT_PROUD - EPS]) {
        // key with a 0.5 lead-in chamfer at the top
        hull() {
            translate([-k[1]/2, -k[0]/2, 0]) cube([k[1], k[0], k[2] - 0.5]);
            translate([-k[1]/2 + 0.5, -k[0]/2 + 0.5, 0]) cube([k[1] - 1, k[0] - 1, k[2]]);
        }
        // crush ribs (3 per side)
        for (sx = [-1, 1]) for (j = [-1, 0, 1])
            translate([sx*(k[1]/2), j*6, 0])
                cylinder(r=BAR_FOOT_RIB, h=k[2] - 0.8, $fn=16);
    }
}
// one foot, local: pad bottom on z = 0, centred
module foot_one() { union() { foot_pad(); foot_key(); } }

// posed: both feet of the leg at x = 0 (bar coordinates)
module foot() {
    for (f = [true, false]) translate([0, bar_toe_y(f), 0]) foot_one();
}
// Print: pad (gripping face) on the bed, key up.
module foot_print() { foot_one(); }
