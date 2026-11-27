// DIAL — flush, hidden inside the body until the slide is pulled. One piece:
// rim with 48 detent notches + relief cone + journal + pinion + spigot.
// Turn it by the recessed pinch bar; nothing stands proud of the slide.
// Prints top face down with its inlay (numerals, ticks), no supports. Dial-local frame:
// axis = z, angle 0 = +x, numerals read at the index mark toward the user (270 deg).
DIAL_LABEL_EVERY = V_MAX == 40 ? 5 : V_MAX == 20 ? 10 : 8;      // clicks between numerals
DIAL_INK = 1.2;                                                  // inlay depth
function _dial_phi(click) = 270 + click*CLICK_DEG;               // where a click's mark sits on the dial
module dial_marks_2d() {
    for (c = [0:CLICKS]) rotate(_dial_phi(c)) translate([DIAL_D/2 - 1.0 - (c % 5 == 0 ? 2.6 : 1.5), -0.45]) square([c % 5 == 0 ? 2.6 : 1.5, 0.9]);
    for (c = [0:DIAL_LABEL_EVERY:CLICKS]) rotate(_dial_phi(c)) translate([DIAL_D/2 - 6.9, 0]) rotate(90)
        text(str(c*ML_PER_CLICK), size=txt_size(3.4), font=FONT_BOLD, halign="center", valign="center");
}
module dial_solid() {
    zt = Z_DIAL_TOP;
    difference() {
        union() {
            translate([0, 0, Z_RIM_BOT]) cylinder(d=DIAL_D, h=DIAL_RIM);
            translate([0, 0, Z_CONE_BOT]) cylinder(d1=JOURNAL_D, d2=DIAL_D, h=CONE_H + 0.01);
            translate([0, 0, Z_PIN0 + PINION_FACE - 0.01]) cylinder(d=JOURNAL_D, h=Z_CONE_BOT - Z_PIN0 - PINION_FACE + 0.02);
            translate([0, 0, Z_PIN0]) linear_extrude(PINION_FACE) pinion_2d(G_M, G_Z, G_PA, 0, BACKLASH, G_CK, G_ADD);
            translate([0, 0, Z_CAV - SPIGOT[1]]) cylinder(d=SPIGOT[0], h=SPIGOT[1] + 0.5);
            translate([0, 0, Z_CAV - 0.01]) cylinder(r=G_RP - G_M*(G_ADD + G_CK) + 0.01, h=0.5);
        }
        // 48 detent notches round the rim
        for (i = [0:NOTCHES-1]) rotate(i*CLICK_DEG) translate([DIAL_D/2, 0, Z_RIM_BOT - 1])
            linear_extrude(DIAL_RIM + 2) polygon([[0.3, -NOTCH_DEPTH - 0.3], [-NOTCH_DEPTH, 0], [0.3, NOTCH_DEPTH + 0.3]]);
        // two half-moon recesses leave a pinch bar across the middle (nothing stands proud)
        translate([0, 0, zt - GRIP[2]]) linear_extrude(GRIP[2] + 1) difference() {
            circle(r=GRIP[1]);
            square([2*GRIP[1] + 1, GRIP[0]], center=true);
        }
        // screw pilot from below
        translate([0, 0, Z_CAV - SPIGOT[1] - 1]) cylinder(d=M3_PILOT, h=14);
    }
}
module dial_body() { difference() { dial_solid(); translate([0, 0, Z_DIAL_TOP - DIAL_INK]) linear_extrude(DIAL_INK + 1) dial_marks_2d(); } }
module dial_inlay_body() { intersection() { dial_solid(); translate([0, 0, Z_DIAL_TOP - DIAL_INK]) linear_extrude(DIAL_INK + 1) dial_marks_2d(); } }
module _dial_pose() { translate([0, SLIDE_Y0 - U_DIAL, 0]) rotate(DIAL_ANGLE) children(); }
module dial() { _dial_pose() dial_body(); }
module dial_inlay() { _dial_pose() dial_inlay_body(); }
module dial_print() { translate([0, 0, Z_DIAL_TOP]) rotate([180, 0, 0]) dial_body(); }
module dial_inlay_print() { translate([0, 0, Z_DIAL_TOP]) rotate([180, 0, 0]) dial_inlay_body(); }
// PAWL — clicks on the rim. PLA, with a TPU tube behind it as the spring.
module pawl_body() {   // nose at +x = 0, body extends to -x... built pointing at the dial axis from +x
    translate([0, 0, PAWL_POCKET_Z + 0.2]) linear_extrude(PAWL[2]) polygon([
        [-NOTCH_DEPTH + 0.1, -0.15], [0.4, -1.05], [0.4, -PAWL[1]/2], [PAWL[0] - NOTCH_DEPTH, -PAWL[1]/2],
        [PAWL[0] - NOTCH_DEPTH, PAWL[1]/2], [0.4, PAWL[1]/2], [0.4, 1.05], [-NOTCH_DEPTH + 0.1, 0.15]]);
}
module pawl() { translate([0, SLIDE_Y0 - U_DIAL, 0]) rotate(PAWL_ANG) translate([DIAL_D/2, 0, 0]) pawl_body(); }
module pawl_print() { translate([0, 0, -(PAWL_POCKET_Z + 0.2)]) pawl_body(); }
