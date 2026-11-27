// FUNNEL INSERT — the ceiling over the slide (with the throat and its strike-off edge),
// the funnel, and the hub the chuck is built on. It carries the jar's weight down to the
// chassis walls. Prints ceiling-down (as posed, lifted off Z_CEIL), no supports.
module funnel_void() {
    hull() {
        translate([-T_WID/2, hy(T_LEN), Z_CEIL_TOP - 0.02]) cube([T_WID, T_LEN, 0.02]);
        translate([0, 0, Z_HUB_TOP]) cylinder(r=MOUTH_R, h=0.02);
    }
}
module seal_path_2d(o0, o1) {      // U-shaped band round the rear and both sides of the throat
    difference() {
        translate([-T_WID/2 - o1, hy(T_LEN) - 1.0]) square([T_WID + 2*o1, T_LEN + 1.0 + o1]);
        translate([-T_WID/2 - o0, hy(T_LEN) - 2.0]) square([T_WID + 2*o0, T_LEN + 2.0 + o0]);
    }
}
module funnel() {
    yf = BODY_Y_FRONT + SKIN_T + 0.5;  yr = Y_BOX_REAR + BOX_WALL;  hw = BOX_X + BOX_WALL;
    difference() {
        union() {
            // ceiling plate
            translate([0, 0, Z_CEIL]) linear_extrude(CEIL_T) intersection() {
                translate([-hw, yf - 5]) square([2*hw, yr - yf + 5]);
                body_2d(SKIN_T + 0.6);          // follows the shell's inside at the corners
            }
            // body: a 45-degree cone from the ceiling up to the hub step
            hull() {
                translate([-CONE_BASE, -CONE_BASE, Z_CEIL_TOP - 1]) cube([2*CONE_BASE, 2*CONE_BASE, 1]);
                translate([0, 0, Z_STEP - 0.02]) cylinder(d=HUB_STEP_OD, h=0.02);
            }
            // hub: the twist ring turns on it, the guide plate screws onto its top
            translate([0, 0, Z_STEP - 1]) cylinder(d=HUB_OD, h=Z_HUB_TOP - Z_STEP + 1);
        }
        funnel_void();
        translate([-T_WID/2, hy(T_LEN), Z_CEIL - 1]) cube([T_WID, T_LEN, CEIL_T + 2]);
        translate([0, 0, Z_HUB_TOP - 0.01]) cylinder(r=MOUTH_R, h=2);
        // seal: rebate for the blade + groove for its root
        translate([0, 0, Z_CEIL - 1]) linear_extrude(1 + SEAL_REBATE) seal_path_2d(-0.01, SEAL_OFF + SEAL_ROOT[0] + 0.2);
        translate([0, 0, Z_CEIL]) linear_extrude(SEAL_REBATE + SEAL_ROOT[1] + 0.2) seal_path_2d(SEAL_OFF - 0.1, SEAL_OFF + SEAL_ROOT[0] + 0.1);
        // screws down into the chassis bosses (heads sit on the plate)
        for (p = BOSS_XY) translate([p[0], p[1], Z_CEIL - 1]) cylinder(d=M3_CLEAR, h=CEIL_T + 2);
        // guide plate screws
        for (a = GP_SCREW_ANGLES) rotate(a) translate([GP_SCREW_R, 0, Z_HUB_TOP - 13]) cylinder(d=M3_PILOT, h=14);
        // wand: plate notch for the arm, pocket for the arm's head, bearing bore
        wand_cuts();
    }
}
module wand_cuts() {
    ya = hy(WAND_U);
    bx([ARM_SLOT_X, ya - 17, Z_CEIL - 1], [BOX_X + BOX_WALL + 1, ya + 17, Z_CEIL_TOP + 0.01]);
    hull() {
        bx([ARM_X[0] - 0.6, ya - 8, Z_CEIL_TOP - 0.5], [ARM_X[1] + 30, ya + 8, WAND_Z + 5]);
        bx([ARM_X[0] - 0.6, ya - 0.5, Z_CEIL_TOP - 0.5], [ARM_X[1] + 30, ya + 0.5, WAND_Z + 12.5]);
    }
    translate([0, ya, WAND_Z]) rotate([0, 90, 0]) cylinder(d=6.3, h=ARM_X[1], $fn=40);
}
module funnel_print() { translate([0, 0, -Z_CEIL]) funnel(); }
