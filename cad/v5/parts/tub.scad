// TUB — the base the head sits on. It houses the scoop drawer. Open top with an inward
// rim flange (the chassis rests on it) and a locating lip. Prints upright, no supports.
module tub() {
    zb = -PED_H;
    ohw = HANDLE_W/2 + REVEAL;                       // front opening half-width
    difference() {
        union() {
            difference() {                           // skin + floor + rim flange on a 45-degree corbel
                translate([0, 0, zb]) cx(PED_H, cb=1.0, ct=0.4) body_2d(0);
                translate([0, 0, zb + TUB_FLOOR_T]) linear_extrude(PED_H - TUB_FLOOR_T - FLANGE_T - FLANGE_W + 0.01) body_2d(SKIN_T);
                hull() {
                    translate([0, 0, -FLANGE_T - FLANGE_W]) linear_extrude(0.01) body_2d(SKIN_T);
                    translate([0, 0, -FLANGE_T]) linear_extrude(0.01) body_2d(SKIN_T + FLANGE_W);
                }
                translate([0, 0, -FLANGE_T]) linear_extrude(FLANGE_T + 1) body_2d(SKIN_T + FLANGE_W);
            }
            // locating lip: shell skin outside, chassis floor inside
            translate([0, 0, -0.5]) linear_extrude(LIP_H + 0.5) difference() {
                body_2d(SKIN_T + LIP_CL);
                body_2d(SKIN_T + LIP_CL + LIP_T);
            }
            // scoop rails, each with a small bump that clicks into the scoop's side at home
            for (s = [-1, 1]) translate([s*(SCOOP_HW + SCOOP_CL + 0.9), SCOOP_DETENT_Y, zb + 0.6]) cylinder(r=1.5, h=TUB_FLOOR_T + 4.4, $fn=32);
            for (s = [-1, 1]) bx([s*(SCOOP_HW + SCOOP_CL), BODY_Y_FRONT + 14, zb + 0.6],
                                 [s*(SCOOP_HW + SCOOP_CL + 2), SCOOP_Y_REAR + 12, zb + TUB_FLOOR_T + 5]);
        }
        // (scoop home detent bumps are added below)
        // front opening for the scoop and the slide face
        bx([-ohw, BODY_Y_FRONT - 1, zb + TUB_FLOOR_T], [ohw, BODY_Y_FRONT + SKIN_T + FLANGE_W + 2.5, LIP_H + 1]);
    }
}
module tub_print() { translate([0, 0, PED_H]) tub(); }
