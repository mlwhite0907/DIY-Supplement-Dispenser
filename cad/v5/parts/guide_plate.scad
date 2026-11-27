// parts/guide_plate.scad: OWNER group CHUCK. Contract: cad/v5/README.md
// GUIDE PLATE: fixed annulus on the hub top. Carries the 3 radial dovetail
// tracks for the jaws, the pin slots down to the ring's scroll, the gasket
// pocket under the jar rim and the lock / open marks.
include <../params.scad>

// ---- private constants -------------------------------------------------------
GP_POCKET_R   = GASKET_OD/2 + 0.2;              // gasket pocket outer radius
GP_POCKET_DEPTH = GASKET_T - GASKET_PROUD;
GP_TRACK_R0   = GP_POCKET_R + 1.2;              // inner (closed) end of each dovetail track
// Tracks and pin slots run out through the rim: the jaws slide in from the
// outside before the plate is lowered onto the ring; once the pins sit in the
// scroll they can never reach the rim again (the scroll run-out stops them).
GP_TRACK_R1   = GP_OD/2 + 1;
GP_SLOT_W     = PIN_D + CL_PIN;
GP_SLOT_R0    = R_PIN_MIN - PIN_D/2 - 0.6;      // inner end of the pin slot (edge)
GP_CSK_D      = M3_HEAD_D;                      // countersink for M3 flat heads (ISO 10642, dk <= 5.54)
GP_MARK_DEPTH = 0.4;                            // engraved lock / open marks
GP_MARK_W     = 1.0;
GP_MARK_R     = GP_OD/2 - 4.5;                  // radius of the mark arcs
GP_MARK_A0    = 9;                              // gap each side of the front track (deg from 270, at GP_MARK_R)
GP_MARK_SPAN  = 14;                             // arc length of each arrow (deg)

// ---- body: chamfered annulus ---------------------------------------------------
module gp_body() {
    ri = MOUTH_R;  ro = GP_OD/2;  t = GP_T;
    rotate_extrude($fa=1.5) polygon([
        [ri + C_BED, 0], [ro - C_BED, 0], [ro, C_BED], [ro, t - C_TOP],
        [ro - C_TOP, t], [ri, t], [ri, C_BED]]);
}

// gasket pocket: a rebate open to the bore, 45 deg C_BED on its outer edge
module gp_pocket_cut() {
    t = GP_T;  d = GP_POCKET_DEPTH;
    rotate_extrude($fa=1.5) polygon([
        [MOUTH_R - 1, t - d], [GP_POCKET_R, t - d], [GP_POCKET_R, t - C_BED],
        [GP_POCKET_R + C_BED, t + EPS], [GP_POCKET_R + C_BED, t + 1], [MOUTH_R - 1, t + 1]]);
}

// one dovetail track along +x (wide at the bottom), mouth chamfered C_BED
module gp_track_cut() {
    wt = DOVETAIL[0]/2;  wb = DOVETAIL[1]/2;  dp = DOVETAIL[2];  t = GP_T;
    k = (wb - wt)/dp;                  // half-width growth per mm of depth
    dc = C_BED/(1 + k);                // depth where the 45 deg mouth chamfer meets the flank
    prof = [[-wb, t - dp], [wb, t - dp], [wt + k*dc, t - dc], [wt + C_BED, t + EPS],
            [wt + C_BED, t + 1], [-wt - C_BED, t + 1], [-wt - C_BED, t + EPS],
            [-wt - k*dc, t - dc]];
    translate([GP_TRACK_R0, 0, 0]) rotate([90, 0, 90])
        linear_extrude(GP_TRACK_R1 - GP_TRACK_R0) polygon(prof);
}

// pin slot through the plate floor, open to the rim (see GP_TRACK_R1)
module gp_slot_cut() {
    w = GP_SLOT_W;
    translate([0, 0, -1]) linear_extrude(GP_T + 2) hull() {
        translate([GP_SLOT_R0 + w/2, 0]) circle(d=w, $fn=32);
        translate([GP_TRACK_R1 + 2, -w/2]) square([EPS, w]);
    }
    // 45 deg relief on the slot's bottom edge (last-printed face, pin lead-in)
    translate([0, 0, -EPS]) hull() {
        translate([GP_SLOT_R0 + w/2, 0, 0]) cylinder(d1=w + 0.8, d2=w, h=0.4, $fn=32);
        translate([GP_TRACK_R1 + 2, 0, 0]) cylinder(d1=w + 0.8, d2=w, h=0.4, $fn=32);
    }
}

// M3 flat-head screw into the hub pilot; head flush with the pocket floor
module gp_screw_cut() {
    zf = GP_T - GP_POCKET_DEPTH;
    hc = (GP_CSK_D - M3_CLEAR)/2;      // 90 deg countersink height
    translate([0, 0, -1]) cylinder(d=M3_CLEAR, h=GP_T + 2, $fn=24);
    translate([0, 0, zf - hc]) cylinder(d1=M3_CLEAR, d2=GP_CSK_D, h=hc + EPS, $fn=32);
    translate([0, 0, zf]) cylinder(d=GP_CSK_D, h=GP_T, $fn=32);
}

// ---- lock / open marks (2D) ---------------------------------------------------
// Turning CLOCKWISE (from above) locks. At the front of the plate a clockwise
// turn moves right -> left, so the LOCK arrow sits left of the front jaw and
// points left; it starts from a filled dot (closed). The OPEN arrow sits on
// the right, points right and starts from a ring (open).
module gp_arc_2d(r, a0, a1, w) {
    n = max(4, ceil(abs(a1 - a0)/1.5));
    polygon(concat(
        [for (i=[0:n]) polar(r + w/2, a0 + (a1 - a0)*i/n)],
        [for (i=[n:-1:0]) polar(r - w/2, a0 + (a1 - a0)*i/n)]));
}
module gp_arrow_2d(dir) {           // dir = -1: lock (clockwise), +1: open
    r = GP_MARK_R;  w = GP_MARK_W;
    a_tail = 270 + dir*GP_MARK_A0;
    a_tip  = a_tail + dir*GP_MARK_SPAN;
    head_l = 3.0;  head_w = 3.0;                 // arrow head (mm)
    da = head_l/r*180/PI;
    a_base = a_tip - dir*da;
    // shaft
    gp_arc_2d(r, a_tail + dir*(2.6/r*180/PI), a_base + dir*0.2, w);
    // head: triangle tangent to the arc
    polygon([polar(r + head_w/2, a_base), polar(r - head_w/2, a_base), polar(r, a_tip)]);
    // tail symbol
    translate(polar(r, a_tail)) {
        if (dir < 0) circle(d=2.6, $fn=32);
        else difference() { circle(d=2.8, $fn=32); circle(d=1.2, $fn=32); }
    }
}
module gp_marks_cut() {
    translate([0, 0, GP_T - GP_MARK_DEPTH]) linear_extrude(GP_MARK_DEPTH + 1) {
        gp_arrow_2d(-1);
        gp_arrow_2d(+1);
    }
}

// Plate in its own frame: bottom (hub-top face) at z = 0.
module guide_plate_local() {
    difference() {
        gp_body();
        gp_pocket_cut();
        for (a = JAW_ANGLES) rotate(a) { gp_track_cut(); gp_slot_cut(); }
        for (a = GP_SCREW_ANGLES) rotate(a) translate([GP_SCREW_R, 0, 0]) gp_screw_cut();
        gp_marks_cut();
    }
}

module guide_plate() {
    translate([0, 0, Z_GP_BOT]) guide_plate_local();
}

// Print: TOP FACE DOWN on the textured PEI plate (the visible top comes out
// matte-textured, the marks crisp). The bottom (hub / ring side) is the last
// printed face. Dovetail flanks overhang 27 deg; the track floors are 11 mm
// bridges. The gasket-pocket floor is a ~4 mm annular overhang hidden under
// the gasket (see report).
module guide_plate_print() {
    translate([0, 0, GP_T]) rotate([180, 0, 0]) guide_plate_local();
}
