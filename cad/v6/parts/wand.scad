// WAND — a rocking gate inside the funnel that breaks bridges and rat-holes in sticky powders.
// The slide moves it only at the end of each stroke (lost motion in the slide's side notch):
// it rocks while the throat is covered on the way out, and again while the chamber refills.
// The follower is a TPU finger: if packed powder ever jams the gate, the finger flexes out of the
// notch (about 6 N) and drops back in on the next stroke, so the dose pull is never blocked.
// GATE: prints flat. ARM (with axle pin): prints flat, pin up. FINGER (TPU): prints on end. No supports.
WAND_YA = hy(WAND_U);                       // axle line: y, with z = WAND_Z
_WALL_X = T_WID/2 + (MOUTH_R - T_WID/2)*(WAND_Z - 5 - Z_CEIL_TOP)/FUNNEL_H;   // funnel wall at the hub's lower edge
HUB_X = [_WALL_X - 7.0, _WALL_X - 1.0];     // gate hub on the pin's D-end
GATE_HW = T_WID/2 - 4.5;                    // gate half-width
GATE_R = [-7.5, 12, 30];                    // bars: bottom, middle, top (distance from the axle)
module _about_axle(a) { translate([0, WAND_YA, WAND_Z]) rotate([a, 0, 0]) children(); }   // axle-local frame
module d_pin_2d(d, flat) { intersection() { circle(d=d, $fn=40); translate([-d, -d]) square([2*d, d + flat]); } }
module wand_body() {                        // axle-local: x = head x, y = normal to the gate, z = along the gate
    difference() {
        union() {
            translate([HUB_X[0], -5, -5]) cube([HUB_X[1] - HUB_X[0], 10, 10]);
            for (r = GATE_R) translate([-GATE_HW, -5, r - 1.5]) cube([r == GATE_R[0] ? GATE_HW + HUB_X[0] + 1 : 2*GATE_HW + 2, 4, 3]);
            for (x = [-GATE_HW, GATE_HW - 1]) translate([x, -5, GATE_R[0] - 1.5]) cube([3, 4, GATE_R[2] - GATE_R[0] + 3]);
        }
        rotate([-WAND_TILT, 0, 0]) translate([HUB_X[0] + 2, 0, 0]) rotate([0, 90, 0]) rotate(90) linear_extrude(10) d_pin_2d(6.25, 2.15);   // the flat sets the gate's lean
        translate([HUB_X[0] - 1, 0, 0]) rotate([0, 90, 0]) cylinder(d=M3_CLEAR, h=4, $fn=24);
    }
}
module wand_arm_body() {                    // axle-local, arm hanging straight down
    difference() {
        union() {
            hull() {
                translate([ARM_X[0], 0, 0]) rotate([0, 90, 0]) cylinder(r=4.5, h=ARM_X[1] - ARM_X[0], $fn=40);
                translate([ARM_X[0], -4.4, -WAND_ARM - 4.6]) cube([ARM_X[1] - ARM_X[0], 8.8, 9.2]);
            }
            translate([HUB_X[0] + 2.1, 0, 0]) rotate([0, 90, 0]) cylinder(d=6.0, h=ARM_X[0] - HUB_X[0] - 2, $fn=48);
        }
        // D-flat on the pin's end, pilot for the M3 that holds the gate on
        translate([HUB_X[0], -5, 2.0]) cube([HUB_X[1] - HUB_X[0] + 0.6, 10, 5]);
        translate([HUB_X[0], 0, 0]) rotate([0, 90, 0]) cylinder(d=M3_PILOT, h=9, $fn=24);
        // socket for the TPU finger
        translate([ARM_X[0] - 1, -PEG_D/2 - 0.1, -WAND_ARM - FINGER_H/2 - 0.1]) cube([ARM_X[1] - ARM_X[0] + 2, PEG_D + 0.2, FINGER_H + 0.2]);
    }
}
// TPU finger: the follower. It pushes through the arm from outside and reaches into the slide's notch.
module wand_finger_body() {
    x0 = SLIDE_W/2 - NOTCH_DEPTH_X + 0.5;
    union() {
        translate([x0, -PEG_D/2, -WAND_ARM - FINGER_H/2]) cube([ARM_X[1] - x0 + 0.01, PEG_D, FINGER_H]);
        translate([ARM_X[1], -PEG_D/2 - 1.6, -WAND_ARM - FINGER_H/2 - 1.6]) cube([1.6, PEG_D + 3.2, FINGER_H + 3.2]);
    }
}
module wand_finger() { if (WAND_ON) _about_axle(-WAND_ANGLE) wand_finger_body(); }
module wand_finger_print() { translate([0, 0, ARM_X[1] + 1.6]) rotate([0, 90, 0]) translate([0, 0, WAND_ARM]) wand_finger_body(); }
module wand() { if (WAND_ON) _about_axle(WAND_TILT - WAND_ANGLE) wand_body(); }
module wand_arm() { if (WAND_ON) _about_axle(-WAND_ANGLE) wand_arm_body(); }
module wand_print() { translate([0, 0, 5]) rotate([90, 0, 0]) wand_body(); }
module wand_arm_print() { translate([0, 0, ARM_X[1]]) rotate([0, 90, 0]) wand_arm_body(); }
