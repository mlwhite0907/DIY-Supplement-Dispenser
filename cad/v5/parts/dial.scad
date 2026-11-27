// parts/dial.scad: OWNER group DRAWER (unit: drive). Contract: cad/v5/README.md
// DIAL (PLA accent) + DIAL_INLAY (ink). Single-turn, 40 clicks over 300 deg.
//  - Knob DIAL_D x DIAL_H at Z_DIAL_BOT, scallop flutes, soft 1.2 top chamfer.
//  - Top: numerals every 5 clicks (S: every 10), tops toward the centre,
//    increasing COUNTER-CLOCKWISE; "0" at the front index (-y) at DIAL_ANGLE 0.
//    Long ink tick at each numeral, short engraved tick at every click, a fine
//    engraved ring framing the centre button with an inlaid "mL".
//  - Underside: DETENT_TEETH radial V-grooves (detent.scad pads click into
//    them), the stop tab (hits STOP_POST at 0 mL and at max), a down-stop hub.
//  - Shaft DIAL_SHAFT_D down through the drawer top, hex key DIAL_KEY_AF for
//    the pinion, M3 pilot 2.6 x 10 up its end.
include <../params.scad>

DIAL_Z1      = Z_DIAL_BOT + DIAL_H;          // top face
DIAL_CH_TOP  = 1.2;                          // soft top chamfer
DIAL_FLUTES  = 30;
DIAL_INK     = 0.6;                          // inlay depth
DIAL_ENGRAVE = 0.3;                          // short tick depth
DIAL_CAP     = 3.5;                          // numeral cap height
DIAL_TXT_SIZE = DIAL_CAP/1.037;              // OpenSCAD size -> Inter SemiBold cap height (measured)
DIAL_R_TOP   = DIAL_D/2 - DIAL_CH_TOP;       // flat top radius
DIAL_TICK_R1 = DIAL_R_TOP - 0.45;
DIAL_LTICK_L = 1.9;  DIAL_LTICK_W = 0.8;
DIAL_STICK_L = 1.0;  DIAL_STICK_W = 0.55;
DIAL_NUM_R   = DIAL_TICK_R1 - DIAL_LTICK_L - 0.55 - DIAL_CAP/2;
DIAL_BTN_R   = DIAL_NUM_R - DIAL_CAP/2 - 1.3;   // centre button ring radius
DIAL_ML_CAP  = 3.5;
DIAL_NUM_EVERY = CLASS_NAME == "S" ? 10 : 5;     // clicks between numerals
// stop tab: the post's tangent half-angle at its radius
DIAL_POST_A  = asin((STOP_POST[1]/2)/STOP_POST[0]);
DIAL_TAB_A1  = STOP_TAB_ANGLE - DIAL_POST_A;                     // hits the post at 0 mL
DIAL_TAB_A0  = STOP_TAB_ANGLE + DIAL_POST_A - 360 + DIAL_TRAVEL; // hits it at max
DIAL_TAB_R0  = STOP_POST[0] - STOP_POST[1]/2 + 0.2;
DIAL_TAB_R1  = STOP_POST[0] + 0.5;           // covers the post's tangent point (r ~ STOP_POST[0])
DIAL_TAB_Z0  = Z_SLIDE_TOP - DIAL_WELL_DEPTH + 0.7;   // 0.7 above the well floor
DIAL_HUB_R   = DIAL_SHAFT_D/2 + 2.2;
DIAL_HUB_Z0  = Z_SLIDE_TOP - DIAL_WELL_DEPTH + 0.6;   // down-stop: 0.6 above the well floor
DIAL_KEY_L   = PIN_FW - 0.4;                 // key ends 0.4 above the pinion bottom (screw clamps)
DIAL_PILOT_L = 10;

function dial_click_angle(k) = 270 + k*CLICK_DEG;     // dial-frame angle of click k on the face

// ---- body --------------------------------------------------------------------
module dial_knob() {
    h = DIAL_H; r = DIAL_D/2; ct = DIAL_CH_TOP; cb = C_TOP;
    intersection() {
        translate([0,0,Z_DIAL_BOT]) linear_extrude(h, convexity=4)
            fluted_circle(DIAL_D, DIAL_FLUTES, $fn=120);
        translate([0,0,Z_DIAL_BOT]) rotate_extrude($fn=120)
            polygon([[0,0],[r - cb,0],[r + 0.01,cb],[r + 0.01,h - ct],[r - ct,h],[0,h]]);
    }
}

module dial_tab() {
    translate([0,0,DIAL_TAB_Z0]) linear_extrude(Z_DIAL_BOT - DIAL_TAB_Z0 + EPS)
        detent_sector(DIAL_TAB_R0, DIAL_TAB_R1, DIAL_TAB_A0, DIAL_TAB_A1);
}

module dial_shaft() {
    hex_d = DIAL_KEY_AF/cos(30);
    // hub (down-stop) + round shaft through the drawer top
    translate([0,0,DIAL_HUB_Z0]) cylinder(r=DIAL_HUB_R, h=Z_DIAL_BOT - DIAL_HUB_Z0 + EPS, $fn=64);
    translate([0,0,PINION_TOP_Z]) cylinder(d=DIAL_SHAFT_D, h=Z_DIAL_BOT - PINION_TOP_Z + EPS, $fn=64);
    // hex key with a small lead-in chamfer
    translate([0,0,PINION_TOP_Z - DIAL_KEY_L]) hull() {
        translate([0,0,0.4]) cylinder(d=hex_d, h=DIAL_KEY_L - 0.4 + EPS, $fn=6);
        cylinder(d=hex_d - 0.8, h=EPS, $fn=6);
    }
}

// 48 radial V-grooves (dial frame), notch k centred at k*CLICK_DEG
module dial_grooves() {
    for (k = [0:DETENT_TEETH - 1]) rotate(k*360/DETENT_TEETH)
        translate([0,0,Z_DIAL_BOT - EPS])
            detent_vprism(DETENT_GROOVE_W, DETENT_NOTCH_H + EPS, DETENT_GROOVE_R0, DETENT_GROOVE_R1);
}

// ---- top-face graphics (2D, dial frame) ------------------------------------
module dial_numerals_2d() {
    for (k = [0:DIAL_NUM_EVERY:CLICKS]) {
        a = dial_click_angle(k);
        translate(polar(DIAL_NUM_R, a)) rotate(a + 90)
            text(str(round(k*ML_PER_CLICK*100)/100), size=DIAL_TXT_SIZE, font=FONT,
                 halign="center", valign="center", $fn=24);
    }
}
module dial_long_ticks_2d() {
    for (k = [0:DIAL_NUM_EVERY:CLICKS]) rotate(dial_click_angle(k))
        translate([DIAL_TICK_R1 - DIAL_LTICK_L, -DIAL_LTICK_W/2]) square([DIAL_LTICK_L, DIAL_LTICK_W]);
}
module dial_short_ticks_2d() {
    for (k = [0:CLICKS]) if (k % DIAL_NUM_EVERY != 0) rotate(dial_click_angle(k))
        translate([DIAL_TICK_R1 - DIAL_STICK_L, -DIAL_STICK_W/2]) square([DIAL_STICK_L, DIAL_STICK_W]);
}
module dial_ml_2d() {
    // reads upright from the front (top of the glyphs toward +y)
    text("mL", size=DIAL_ML_CAP/1.037, font=FONT, halign="center", valign="center", $fn=24);
}
module dial_ink_2d() {
    dial_numerals_2d(); dial_long_ticks_2d(); dial_ml_2d();
}

// ---- assembled in the dial frame ----------------------------------------------
module dial_local() {
    difference() {
        union() { dial_knob(); dial_tab(); dial_shaft(); }
        // ink pockets
        translate([0,0,DIAL_Z1 - DIAL_INK]) linear_extrude(DIAL_INK + 1) dial_ink_2d();
        // engraved short ticks
        translate([0,0,DIAL_Z1 - DIAL_ENGRAVE]) linear_extrude(1) dial_short_ticks_2d();
        // engraved ring framing the centre button
        translate([0,0,DIAL_Z1 - 0.4]) linear_extrude(1)
            difference() { circle(r=DIAL_BTN_R + 0.3, $fn=96); circle(r=DIAL_BTN_R - 0.3, $fn=96); }
        // detent grooves in the underside
        dial_grooves();
        // M3 pilot up the key end
        translate([0,0,PINION_TOP_Z - DIAL_KEY_L - EPS]) cylinder(d=M3_PILOT, h=DIAL_PILOT_L, $fn=24);
    }
}

module dial_inlay_local() {
    translate([0,0,DIAL_Z1 - DIAL_INK]) linear_extrude(DIAL_INK) dial_ink_2d();
}

module dial_pose() { translate(drive_axis()) rotate([0,0,DIAL_ANGLE]) children(); }

module dial()       { dial_pose() dial_local(); }
module dial_inlay() { dial_pose() dial_inlay_local(); }

// Print: TOP FACE DOWN on the textured PEI (numerals flush and crisp, the 1.2
// top chamfer is the bed chamfer). The underside (grooves, tab, hub) and the
// shaft + key print last, facing up. Ink shares the same pose.
module dial_print_pose() { translate([0,0,DIAL_Z1]) rotate([180,0,0]) children(); }
module dial_print()       { dial_print_pose() dial_local(); }
module dial_inlay_print() { dial_print_pose() dial_inlay_local(); }
