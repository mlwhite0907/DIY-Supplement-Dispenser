// parts/leg.scad: OWNER group BAR. Contract: cad/v5/README.md
// LEG: a vertical panel in the y-z plane, BAR_LEG_T thick, shared by the two
// bays on either side (N bays = N+1 identical legs). Trestle form: the outer
// edges lean out to two toes (more toe at the front, where a drawer pull tips
// the bar), and a large arch with soft R28 shoulders keeps it light.
// The top beam carries the two plate SLOTS (one per face, matching the plate
// tongue) and the blind M4 pilots (staggered per face). Two TPU feet press into
// recesses under the toes.
// leg() = the leg at x = 0 in bar coordinates (bar_assembly places it at
// x = (j - 0.5)*BAY_W). Shared BAR_* constants live in parts/bay.scad.
include <../params.scad>

BAR_FLARE_F0 = 42;               // front toe reach beyond the plate front (nominal)
BAR_FLARE_R0 = 20;               // rear toe reach (the wall stop)
BAR_LEG_DMAX = 246;              // leg footprint limit so it prints flat on the bed
_bar_fs      = min(1, (BAR_LEG_DMAX - BAY_D)/(BAR_FLARE_F0 + BAR_FLARE_R0));
BAR_FLARE_F  = BAR_FLARE_F0*_bar_fs;
BAR_FLARE_R  = BAR_FLARE_R0*_bar_fs;
BAR_FOOT_PROUD = 2.0;            // TPU pad below the leg (leg bottom z)
BAR_COL_T    = 22;               // column width at the top (horizontal)
BAR_COL_B    = 30;               // column width at the toe
BAR_BEAM_H   = 44;               // top beam height (arch apex below BAR_H)
BAR_ARCH_R   = 28;               // arch shoulder radius
BAR_EDGE_R   = 3;                // convex corner radius in the side view
BAR_LEG_CH   = 0.8;              // face edge chamfer (0.2 mm print steps)
// TPU foot key + recess (pressed in, crush ribs on the key)
BAR_FOOT_L   = 26;               // pad length (y)
BAR_FOOT_W   = BAR_LEG_T - 0.8;  // pad width (x), 0.4 inset each side
BAR_KEY      = [18, 4.4, 3.0];   // key [y, x, z]
BAR_RECESS   = [18.4, 4.8, 3.3];
function bar_toe_y(front) = front ? -BAY_D/2 - BAR_FLARE_F + BAR_COL_B/2
                                  :  BAY_D/2 + BAR_FLARE_R - BAR_COL_B/2;

// side-view outline in (y, z)
module leg_2d() {
    z0 = BAR_FOOT_PROUD; zt = BAR_H; d2 = BAY_D/2;
    zo = BAR_H - BAR_BEAM_H;
    // inner edges: lines from (col_t at zt) to (col_b at z0)
    function fy(z) = let(t = (zt - z)/(zt - z0)) (-d2 + BAR_COL_T) + t*((-d2 - BAR_FLARE_F + BAR_COL_B) - (-d2 + BAR_COL_T));
    function ry(z) = let(t = (zt - z)/(zt - z0)) ( d2 - BAR_COL_T) + t*(( d2 + BAR_FLARE_R - BAR_COL_B) - ( d2 - BAR_COL_T));
    zb = z0 - 10;
    offset(r=BAR_EDGE_R) offset(delta=-BAR_EDGE_R)
    offset(r=-BAR_ARCH_R) offset(delta=BAR_ARCH_R)
    difference() {
        polygon([[-d2 - BAR_FLARE_F, z0], [d2 + BAR_FLARE_R, z0], [d2, zt], [-d2, zt]]);
        polygon([[fy(zb), zb], [ry(zb), zb], [ry(zo), zo], [fy(zo), zo]]);
    }
}
// solid panel x in [-T/2, T/2] with stepped 45 deg face chamfers
module leg_panel() {
    c = BAR_LEG_CH; st = 0.2; n = round(c/st); t = BAR_LEG_T;
    rotate([90, 0, 90]) {
        translate([0, 0, -t/2 + c - EPS]) linear_extrude(t - 2*c + 2*EPS) leg_2d();
        for (k = [0:n-1]) {
            translate([0, 0, -t/2 + k*st]) linear_extrude(st + EPS) offset(delta=-(c - (k + 0.5)*st)) leg_2d();
            translate([0, 0,  t/2 - (k + 1)*st - EPS]) linear_extrude(st + EPS) offset(delta=-(c - (k + 0.5)*st)) leg_2d();
        }
    }
}
// slot section in (s, z), s = depth into the leg from its face
module leg_slot_section(cl=0) {
    zt = BAR_H - BAR_TG_TOP;
    sd = BAR_TG_D + BAR_TG_CLX;
    // tongue bottom line: z = zt - TIP - (REVEAL + TG_D - s')  at s' measured from the plate edge
    zb_tip = zt - BAR_TG_TIP - BAR_TG_CL;                // at s = sd... (45 deg line)
    polygon([[-1, zt + BAR_TG_CL - cl], [sd - cl, zt + BAR_TG_CL - cl],
             [sd - cl, zt - BAR_TG_TIP - BAR_TG_CL + BAR_TG_CLX + cl],
             [-1, zt - BAR_TG_TIP - BAR_TG_CL - BAR_TG_D - 1 + cl]]);
}
module leg_slot_cut(sd) {   // sd = +1: slot in the +x face, -1: in the -x face
    L = BAY_D - 2*BAR_SLOT_END;
    mirror([sd < 0 ? 1 : 0, 0, 0]) translate([BAR_LEG_T/2, 0, 0]) mirror([1, 0, 0])
        rotate([90, 0, 0]) linear_extrude(L, center=true) leg_slot_section();
}
module leg_pilot(y, sd) {
    mirror([sd < 0 ? 1 : 0, 0, 0]) translate([BAR_LEG_T/2 + 1, y, BAR_SCREW_Z])
        rotate([0, -90, 0]) cylinder(d=M4_PILOT, h=BAR_PILOT_L + 1, $fn=24);
}
module leg_recess(front) {
    translate([-BAR_RECESS[1]/2, bar_toe_y(front) - BAR_RECESS[0]/2, BAR_FOOT_PROUD - 1])
        cube([BAR_RECESS[1], BAR_RECESS[0], BAR_RECESS[2] + 1]);
}

module leg() {
    difference() {
        leg_panel();
        leg_slot_cut(1);
        leg_slot_cut(-1);
        for (y = BAR_SCREWS_NEG) leg_pilot(y, 1);    // +x face: plate on the right, its -x side screws
        for (y = BAR_SCREWS_POS) leg_pilot(y, -1);   // -x face: plate on the left, its +x side screws
        leg_recess(true);
        leg_recess(false);
    }
}
// Print: FLAT, -x face on the textured plate (fits 246 x 230 mm). Pilots are
// vertical; the slot in the bed-side face bridges <= 3 mm and its other wall is
// 45 deg; the foot recesses are 4.8 mm horizontal pockets. Print each END leg
// with its outward face down so both ends of the bar show the same texture.
module leg_print() {
    translate([0, 0, BAR_LEG_T/2]) rotate([0, -90, 0]) translate([0, 0, -(BAR_H + BAR_FOOT_PROUD)/2]) rotate([0, 0, 0]) leg();
}

// END-LEG SLOT TRIM (PLA, body color): fills the unused slot in the outer face
// of the two end legs, flush. Light press fit (+0.05 per face). Shown on the
// +x face of a leg at x = 0; bar_assembly mirrors it for the left end.
module leg_slot_trim() {
    L = BAY_D - 2*BAR_SLOT_END - 0.3;
    translate([BAR_LEG_T/2, 0, 0]) mirror([1, 0, 0]) rotate([90, 0, 0])
        linear_extrude(L, center=true) intersection() {
            leg_slot_section(-0.05);
            translate([0, 0]) square([BAR_TG_D + 1, 2*BAR_H]);
        }
}
// Print: outer (visible) face on the bed.
module leg_slot_trim_print() { rotate([0, 90, 0]) translate([-BAR_LEG_T/2, 0, -BAR_H + BAR_TG_TOP]) leg_slot_trim(); }
