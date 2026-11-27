// CHUCK — drill-chuck style twist lock for the jar neck: a scroll ring drives three jaws.
// Closing = counter-clockwise seen from above = clockwise for you in the refill pose (like a lid).
// RING: prints grooves-up. GUIDE PLATE and JAWS: print top face down. No supports.
module ring_body() {
    n = round(PI*RING_OD/(2*FLUTE_W + 0.4));
    m = 4;                                             // extra groove angle at both ends
    difference() {
        translate([0, 0, Z_RING_BOT]) cx(RING_T, cb=1.0, ct=0.6) fluted_circle(RING_OD, n);
        translate([0, 0, Z_RING_BOT - 1]) cylinder(d=RING_ID, h=RING_T + 2);
        translate([0, 0, Z_RING_TOP - SCROLL_DEPTH]) linear_extrude(SCROLL_DEPTH + 1)
            scroll_grooves_2d(R_PIN_MIN - SCROLL_LEAD*m/360, SCROLL_LEAD, JAW_ANGLES[0] - TWIST - m, JAW_ANGLES[0] + m, GROOVE_W, 3, 2);
    }
}
module ring() { rotate(RING_PHI) ring_body(); }
module ring_print() { translate([0, 0, -Z_RING_BOT]) ring_body(); }

module jaw_track() {      // along +x; dovetail, narrow at the top
    r0 = R_PIN_MIN - PIN_OFF + FOOT_IN - 0.5;  r1 = R_PIN_MAX + JAW_TAIL + 0.5;
    hull() {
        translate([r0, -DOVE[1]/2 - 0.2, Z_HUB_TOP - 0.02]) cube([r1 - r0, DOVE[1] + 0.4, 0.01]);
        translate([r0, -DOVE[0]/2 - 0.2, Z_GP_TOP + 0.01]) cube([r1 - r0, DOVE[0] + 0.4, 0.01]);
    }
}
module guide_plate() {
    difference() {
        translate([0, 0, Z_HUB_TOP]) cx(GP_T, cb=0.6, ct=0.6) circle(d=GP_OD);
        translate([0, 0, Z_HUB_TOP - 1]) cylinder(r=MOUTH_R, h=GP_T + 2);
        for (a = GP_SCREW_ANGLES) rotate(a) translate([GP_SCREW_R, 0, 0]) {
            translate([0, 0, Z_HUB_TOP - 1]) cylinder(d=M3_CLEAR, h=GP_T + 2);
            translate([0, 0, Z_GP_TOP - 3.2]) cylinder(d=6.4, h=4);
        }
        for (a = JAW_ANGLES) rotate(a) jaw_track();
    }
}
module guide_plate_print() { translate([0, 0, Z_GP_TOP]) rotate([180, 0, 0]) guide_plate(); }

// jaw outline seen from above (jaw along +x, PLA face at radius rf); grooves hold the TPU boot
module jaw_top_2d(rf, grooves=true) {
    difference() {
        polygon([[rf, -JAW_W/2], [rf + 1.2, 0], [rf, JAW_W/2], [rf + JAW_L, JAW_W/2], [rf + JAW_L, -JAW_W/2]]);
        if (grooves) for (s = [-1, 1]) translate([rf + 4.0, s > 0 ? JAW_W/2 - 0.8 : -JAW_W/2 - 0.1]) square([1.4, 0.9]);
    }
}
module jaw_body(rp = R_PIN) {
    rf = rp - PIN_OFF;
    union() {
        translate([0, 0, Z_GP_TOP]) linear_extrude(JAW_H) jaw_top_2d(rf);
        hull() {                                        // dovetail foot
            translate([rf + FOOT_IN, -DOVE[1]/2, Z_HUB_TOP]) cube([JAW_L - FOOT_IN, DOVE[1], 0.01]);
            translate([rf + FOOT_IN, -DOVE[0]/2, Z_GP_TOP]) cube([JAW_L - FOOT_IN, DOVE[0], 0.01]);
        }
        translate([rp, 0, Z_HUB_TOP - PIN_LEN]) cylinder(d1=PIN_D - 0.8, d2=PIN_D, h=0.4, $fn=48);
        translate([rp, 0, Z_HUB_TOP - PIN_LEN + 0.4]) cylinder(d=PIN_D, h=PIN_LEN + 0.6, $fn=48);
    }
}
module jaw(i) { rotate(JAW_ANGLES[i]) jaw_body(); }
module jaw_print() { translate([-R_PIN, 0, Z_GP_TOP + JAW_H]) rotate([180, 0, 0]) jaw_body(); }
// TPU boot: clips over the jaw's face and hooks into the side grooves
module jaw_boot_body(rp = R_PIN) {
    rf = rp - PIN_OFF;
    translate([0, 0, Z_GP_TOP + 0.6]) linear_extrude(JAW_H - 0.6) difference() {
        intersection() {
            offset(delta=PAD_T) jaw_top_2d(rf, false);
            translate([rf - 3, -JAW_W]) square([3 + 5.4, 2*JAW_W]);
        }
        jaw_top_2d(rf, true);
    }
}
module jaw_boot(i) { rotate(JAW_ANGLES[i]) jaw_boot_body(); }
module jaw_boot_print() { translate([-R_PIN, 0, -(Z_GP_TOP + 0.6)]) jaw_boot_body(); }
