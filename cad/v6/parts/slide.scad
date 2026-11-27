// SLIDE — carries the dose chamber, the plunger and the hidden dial. One piece.
// Prints UPSIDE DOWN (top face on the bed): the sealing face gets the smooth plate finish
// and nothing needs support. Written in the slide-local frame (see params.scad).
module slide_body() {
    U_FB = U_FACE - FACE_T;                       // rear of the face block
    difference() {
        union() {
            // bar: rear section + chamber frame + neck (rear corners chamfered in plan)
            hull() {
                ubx(-REAR_L + 4, U_FB + 0.5, -SLIDE_W/2, SLIDE_W/2, Z_FLOOR, Z_SLIDE_TOP);
                ubx(-REAR_L, -REAR_L + 5, -SLIDE_W/2 + 4, SLIDE_W/2 - 4, Z_FLOOR, Z_SLIDE_TOP);
            }
            // face block, 0.6 chamfer on its front edges
            hull() {
                ubx(U_FB, U_FACE - 0.6, -HANDLE_W/2, HANDLE_W/2, Z_FACE0, Z_FACE1);
                ubx(U_FB, U_FACE, -HANDLE_W/2 + 0.6, HANDLE_W/2 - 0.6, Z_FACE0 + 0.6, Z_FACE1 - 0.6);
            }
            // two dogs under the face block: the scoop pulls them (TPU latch flaps) and pushes them (front wall)
            for (sg = [-1, 1]) hull() {
                ubx(U_DOG1 - DOG[2], U_DOG1, min(sg*DOG[0], sg*DOG[1]), max(sg*DOG[0], sg*DOG[1]), Z_FACE0 - DOG[3] + 1, Z_FACE0 + 1);
                ubx(U_DOG1 - DOG[2] + 1, U_DOG1, min(sg*DOG[0], sg*DOG[1]), max(sg*DOG[0], sg*DOG[1]), Z_FACE0 - DOG[3], Z_FACE0 + 1);
            }
            // stop lugs (they start on the bed in the print; 45-degree lead underneath)
            for (s = [-1, 1]) hull() {
                ubx(LUG_U0, LUG_U0 + LUG[1], min(s*(SLIDE_W/2 - 1), s*(SLIDE_W/2 + LUG[0])), max(s*(SLIDE_W/2 - 1), s*(SLIDE_W/2 + LUG[0])), Z_LUG0, Z_SLIDE_TOP);
                ubx(LUG_U0, LUG_U0 + LUG[1], min(s*(SLIDE_W/2 - 1), s*(SLIDE_W/2 - 0.5)), max(s*(SLIDE_W/2 - 1), s*(SLIDE_W/2 - 0.5)), Z_LUG0 - LUG[0] - 0.5, Z_SLIDE_TOP);
            }
        }
        // chamber + plunger slot (through), 45-degree wings along the top edges
        ubx(0, SLOT_L, -CH_W/2, CH_W/2, Z_FLOOR - 1, Z_SLIDE_TOP + 1);
        for (s = [-1, 1]) hull() {
            ubx(0, SLOT_L, min(s*(CH_W/2 - 0.1), s*CH_W/2), max(s*(CH_W/2 - 0.1), s*CH_W/2), Z_SLIDE_TOP - WING, Z_SLIDE_TOP - WING + 0.01);
            ubx(0, SLOT_L, min(s*(CH_W/2 - 0.1), s*(CH_W/2 + WING + 1)), max(s*(CH_W/2 - 0.1), s*(CH_W/2 + WING + 1)), Z_SLIDE_TOP + 1, Z_SLIDE_TOP + 1.01);
        }
        // rod channel: open at the top, tight behind the rack near the pinion, a tunnel inside the face block
        for (seg = [[SLOT_L - 0.1, U_DIAL - 10, ROD_CL], [U_DIAL - 10.01, U_DIAL + 10.01, ROD_BACK_CL], [U_DIAL + 10, U_FB + 0.01, ROD_CL]])
            ubx(seg[0], seg[1], ROD_X0 - ROD_CL, ROD_X1 + seg[2], Z_FLOOR - 1, Z_SLIDE_TOP + 1);
        ubx(U_FB, U_ROD_FRONT0 + L_MAX + 1.0, ROD_X0 - ROD_CL, ROD_X1 + ROD_CL, Z_FACE0 - 1, ROD_Z1 + 0.6);
        // dial: well for the rim, relief cone, journal bore, pinion cavity, spigot seat, screw
        translate([0, -U_DIAL, 0]) {
            translate([0, 0, Z_RIM_BOT - 0.4]) cylinder(d=WELL_D, h=10);
            translate([0, 0, Z_CONE_BOT - 0.4]) cylinder(d1=JOURNAL_D + 0.3, d2=WELL_D, h=CONE_H + 0.01);
            translate([0, 0, Z_PIN0 + PINION_FACE - 0.2]) cylinder(d=JOURNAL_D + 0.3, h=Z_CONE_BOT - Z_PIN0 - PINION_FACE);
            translate([0, 0, Z_CAV]) cylinder(d=2*PINION_RA + 1.2, h=PINION_FACE + 0.3);
            translate([0, 0, Z_CAV - SPIGOT[1] - 0.1]) cylinder(d=SPIGOT[0] + 0.3, h=SPIGOT[1] + 0.2);
            translate([0, 0, Z_FLOOR - 1]) cylinder(d=M3_CLEAR, h=CAV_FLOOR + 1.1);
            if (CAV_FLOOR > 5) translate([0, 0, Z_FLOOR - 1]) cylinder(d=6.4, h=1 + 3.0);
            // pawl + spring pocket (open at the top), front-left of the dial
            rotate(PAWL_ANG) {
                translate([WELL_D/2 - 1, -(PAWL[1] + 0.3)/2, PAWL_POCKET_Z]) cube([PAWL[0] + 1.2, PAWL[1] + 0.3, 10]);
                translate([PAWL_SPRING_R, 0, PAWL_POCKET_Z]) cylinder(d=PAWL_TUBE[0] + 0.1, h=10);
            }
            // index mark in front of the well
            translate([0, -WELL_D/2 - 0.9, Z_SLIDE_TOP - 0.4]) linear_extrude(1) polygon([[0, 0], [-1.6, -2.8], [1.6, -2.8]]);
        }
        // name band: 45-degree dovetail groove across the whole face
        translate([-HANDLE_W/2 - 1, -U_FACE, Z_BAND]) rotate([90, 0, 90]) linear_extrude(HANDLE_W + 2)
            polygon([[-0.01, NAME_BAND[0]/2], [NAME_BAND[1], NAME_BAND[0]/2 + NAME_BAND[1]], [NAME_BAND[1], -NAME_BAND[0]/2 - NAME_BAND[1]], [-0.01, -NAME_BAND[0]/2]]);
        // wand peg notch on the +x side (45-degree lower face: prints without support)
        hull() {
            ubx(NOTCH_U0, NOTCH_U1, SLIDE_W/2 - NOTCH_DEPTH_X, SLIDE_W/2 + 1, NOTCH_Z[0], NOTCH_Z[1]);
            ubx(NOTCH_U0, NOTCH_U1, SLIDE_W/2, SLIDE_W/2 + 1, NOTCH_Z[0] - NOTCH_DEPTH_X, NOTCH_Z[1]);
        }
        // home catch: the bumper's TPU tube snaps into this slot (blind at the top: the sealing face stays whole)
        ubx(-REAR_L - 1, -REAR_L + HOME_GRIP[2], -HOME_GRIP[1]/2, HOME_GRIP[1]/2, Z_FLOOR - 1, Z_FLOOR + HOME_GRIP[3]);
        hull() {                                         // lead-in
            ubx(-REAR_L - 1, -REAR_L + 0.01, -HOME_GRIP[1]/2 - 1.2, HOME_GRIP[1]/2 + 1.2, Z_FLOOR - 1, Z_FLOOR + HOME_GRIP[3]);
            ubx(-REAR_L - 1, -REAR_L + 1.2, -HOME_GRIP[1]/2, HOME_GRIP[1]/2, Z_FLOOR - 1, Z_FLOOR + HOME_GRIP[3]);
        }
        // underside relief behind the chamber: less rubbing area, lands all round
        for (s = [-1, 1]) ubx(-REAR_L + 6, -7, min(s*8, s*(SLIDE_W/2 - 6)), max(s*8, s*(SLIDE_W/2 - 6)), Z_FLOOR - 1, Z_FLOOR + 0.6);
    }
}
module slide() { translate([0, SLIDE_Y0, 0]) slide_body(); }
module slide_print() { translate([0, 0, Z_SLIDE_TOP]) rotate([180, 0, 0]) slide_body(); }
