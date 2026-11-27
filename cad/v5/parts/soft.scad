// SOFT PARTS (TPU 95A) + the name band. Small, quick prints.
// ---- U-seal: wipes the slide top behind and beside the throat --------------------------
module seal() {
    zr = Z_CEIL + SEAL_REBATE;                       // root starts at the rebate ceiling
    w = 0.8/sin(45);                                 // blade thickness measured horizontally
    union() {
        translate([0, 0, zr - 0.4]) linear_extrude(SEAL_ROOT[1] + 0.4) seal_path_2d(SEAL_OFF, SEAL_OFF + SEAL_ROOT[0]);
        // blade: leans 45 degrees toward the throat, tip 0.3 below the slide top (preload)
        for (z = [Z_SLIDE_TOP - 0.3 : 0.1 : zr - 0.05])
            translate([0, 0, z]) linear_extrude(0.101) seal_path_2d(SEAL_OFF - (zr - z), SEAL_OFF - (zr - z) + w);
    }
}
module seal_print() { translate([0, 0, Z_CEIL + SEAL_REBATE + SEAL_ROOT[1]]) rotate([180, 0, 0]) seal(); }
// ---- gasket: the jar rim sits on its two lips -------------------------------------------
module gasket() {
    translate([0, 0, Z_GP_TOP - 0.6]) rotate_extrude($fn=160) polygon([
        [GASKET_ID/2, 0], [GASKET_OD/2, 0], [GASKET_OD/2, 1.8],
        [GASKET_OD/2 - 0.9, 1.8], [GASKET_OD/2 - 0.9, 2.9], [GASKET_OD/2 - 1.7, 2.9], [GASKET_OD/2 - 1.7, 1.8],
        [GASKET_ID/2 + 1.4, 1.8], [GASKET_ID/2 + 1.4, 2.9], [GASKET_ID/2 + 0.6, 2.9], [GASKET_ID/2 + 0.6, 1.8], [GASKET_ID/2, 1.8]]);
}
module gasket_print() { translate([0, 0, -(Z_GP_TOP - 0.6)]) gasket(); }
// ---- stop boots: cushion the slide's lugs on the stop piers -----------------------------
module boot_cap(x0, x1, y0, y1, z0, z1, open) {      // cap over a block; open = side left open: "x0","x1","y0","y1"
    t = STOP_PAD;
    difference() {
        bx([x0 - (open == "x0" ? 0 : t), y0 - (open == "y0" ? 0 : t), z0], [x1 + (open == "x1" ? 0 : t), y1 + (open == "y1" ? 0 : t), z1 + 0.8]);
        bx([x0 - (open == "x0" ? 1 : 0), y0 - (open == "y0" ? 1 : 0), z0 - 1], [x1 + (open == "x1" ? 1 : 0), y1 + (open == "y1" ? 1 : 0), z1]);
    }
}
module stop_boot(s) {
    xa = s*PIER_X0;  xb = s*(BOX_X - 0.4);
    boot_cap(min(xa, xb), max(xa, xb), hy(PIER_U0 + PIER_T), hy(PIER_U0), Z_LUG0 - 4, Z_CEIL - 1.0, s > 0 ? "x1" : "x0");
}
module stop_boot_print() { translate([-PIER_X0, 0, Z_CEIL - 0.2]) rotate([180, 0, 0]) translate([0, -hy(PIER_U0 + PIER_T/2), 0]) stop_boot(1); }
module bumper() {
    yb = Y_BOX_REAR - BUMP[1] - STOP_PAD;            // the bumper's face = where the slide's rear end rests
    union() {
        boot_cap(-BUMP[0]/2, BUMP[0]/2, Y_BOX_REAR - BUMP[1], Y_BOX_REAR - 0.4, Z_FLOOR + 6, Z_CEIL - 1.0, "y1");
        bx([-5, yb, Z_FLOOR + 0.6], [5, yb + STOP_PAD, Z_FLOOR + 6.5]);
        // home catch: a soft tube that snaps into the slot in the slide's rear end
        translate([0, yb - HOME_GRIP[0]/2 + 0.6, Z_FLOOR + 0.6]) difference() {
            cylinder(d=HOME_GRIP[0], h=HOME_GRIP[3] - 1.2, $fn=48);
            translate([0, 0, -1]) cylinder(d=HOME_GRIP[0] - 1.8, h=HOME_GRIP[3] + 1, $fn=48);
        }
    }
}
module bumper_print() { translate([0, 0, Z_CEIL - 0.2]) rotate([180, 0, 0]) translate([0, -Y_BOX_REAR, 0]) bumper(); }
// ---- pawl spring: a short TPU tube, squeezed across its diameter ---------------------------
module pawl_spring_body() { translate([0, 0, PAWL_POCKET_Z + 0.2]) difference() { cylinder(d=PAWL_TUBE[0], h=PAWL_TUBE[2], $fn=48); translate([0, 0, -1]) cylinder(d=PAWL_TUBE[1], h=PAWL_TUBE[2] + 2, $fn=48); } }
module pawl_spring() { translate([0, SLIDE_Y0 - U_DIAL, 0]) rotate(PAWL_ANG) translate([PAWL_SPRING_R, 0, 0]) pawl_spring_body(); }
module pawl_spring_print() { translate([0, 0, -(PAWL_POCKET_Z + 0.2)]) pawl_spring_body(); }
// ---- latch flaps: couple the scoop to the slide, let go at a firm tug ----------------------
module latch_profile(t = FLAP[2]) {                  // in (y, z), y measured from the scoop front face
    polygon([[5.8, LATCH_Z - LATCH_DOVE[2]], [13.8, LATCH_Z - LATCH_DOVE[2]], [12.8, LATCH_Z], [8.8 + t + 1.0, LATCH_Z],
             [8.8 + t, LATCH_Z + 1.0], [8.8 + t, FLAP_TOP_Z - 0.5], [8.8 + t - 0.5, FLAP_TOP_Z], [8.8, FLAP_TOP_Z],
             [8.8, LATCH_Z + 1.0], [7.8, LATCH_Z], [6.8, LATCH_Z]]);
}
module latch_one(s, t = FLAP[2]) {
    translate([s > 0 ? FLAP[0] : -FLAP[1], BODY_Y_FRONT, 0]) rotate([90, 0, 90]) linear_extrude(FLAP[1] - FLAP[0]) latch_profile(t);
}
module latch() { translate([0, scoop_dy(), 0]) for (s = [-1, 1]) latch_one(s); }
module latch_print(t = FLAP[2]) { rotate([0, -90, 0]) translate([-FLAP[0], -BODY_Y_FRONT - 10, -LATCH_Z]) latch_one(1, t); }
// ---- mat: one TPU tile under each head; grips the counter, catches dust, locks to its neighbours
module mat_2d() { offset(delta=PED_GAP/2) body_2d(0); }
module mat_tab_2d(grow=0) { offset(delta=grow) polygon([[-0.5, -4], [3, -4], [6, -6.5], [6, 6.5], [3, 4], [-0.5, 4]]); }
module mat() {
    zb = -PED_H - MAT_T;
    difference() {
        union() {
            translate([0, 0, zb]) cx(MAT_T, cb=0.4) mat_2d();
            translate([0, 0, zb + MAT_T - 0.2]) linear_extrude(MAT_RIM[1] + 0.2) difference() { mat_2d(); offset(delta=0.4) body_2d(0); }
            for (y = [-55, 55]) translate([ROW_PITCH/2, y, zb]) linear_extrude(MAT_T) mat_tab_2d();
        }
        for (y = [-55, 55]) translate([-ROW_PITCH/2, y, zb - 1]) linear_extrude(MAT_T + MAT_RIM[1] + 2) mat_tab_2d(0.25);
        // the scoop slides out over the front rim
        bx([-(HANDLE_W/2 + REVEAL + 2), BODY_Y_FRONT - PED_GAP, zb + MAT_T], [HANDLE_W/2 + REVEAL + 2, BODY_Y_FRONT + 1, zb + MAT_T + MAT_RIM[1] + 1]);
    }
}
module mat_print() { translate([0, 0, PED_H + MAT_T]) mat(); }
// ---- name band (PLA, accent colour): slides into the dovetail across the slide's face ----
module name_band_solid() {
    c = 0.1;
    translate([-HANDLE_W/2, -U_FACE, Z_BAND]) rotate([90, 0, 90]) linear_extrude(HANDLE_W)
        polygon([[0, NAME_BAND[0]/2 - c], [NAME_BAND[1] - 0.1, NAME_BAND[0]/2 + NAME_BAND[1] - 0.1 - c],
                 [NAME_BAND[1] - 0.1, -NAME_BAND[0]/2 - NAME_BAND[1] + 0.1 + c], [0, -NAME_BAND[0]/2 + c]]);
}
module name_text(name) {
    translate([0, -U_FACE + 1.2, Z_BAND]) rotate([90, 0, 0]) linear_extrude(1.3)
        text(name, size=txt_size(5.0), font=FONT_SEMI, halign="center", valign="center", spacing=1.12);
}
module name_plate(name) { translate([0, SLIDE_Y0, 0]) difference() { name_band_solid(); name_text(name); } }
module name_inlay(name) { translate([0, SLIDE_Y0, 0]) intersection() { name_band_solid(); name_text(name); } }
module name_plate_print(name) { rotate([-90, 0, 0]) translate([0, U_FACE, -Z_BAND]) difference() { name_band_solid(); name_text(name); } }
module name_inlay_print(name) { rotate([-90, 0, 0]) translate([0, U_FACE, -Z_BAND]) intersection() { name_band_solid(); name_text(name); } }
