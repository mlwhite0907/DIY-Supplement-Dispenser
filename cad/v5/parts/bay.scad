// parts/bay.scad: OWNER group BAR. Contract: cad/v5/README.md
// Bay plate (one per head) + bar_assembly(n) + optional rear wall tab.
//
// BAR COORDINATES: x along the bar (bay i centred at x = i*BAY_W), y = depth
// (front = -y, toward the user), z = 0 on the counter. Bay plate top = BAR_H.
// The head origin sits at (i*BAY_W, BAY_Y_HEAD, BAR_H).
//
// JOINT: each plate side has a full-length wedge TONGUE (flat top, 45 deg
// underside so the plate prints upright) that slides into the matching SLOT in
// the leg face. The tongue sets the plate height, so plate and leg tops are
// flush with a REVEAL shadow line between them. 2 x M4 x 14 socket-head screws
// per side, driven from INSIDE the bay (under the plate, 3 mm L-key; the open
// waffle cell beside each boss gives the key room) through the plate's side
// boss into a blind pilot in the leg. Nothing shows on the outside of a leg.
// The two faces of a leg use staggered pilot positions (BAR_SCREW_STAG).
// Assembly: leg 0 -> plate 0 (tongue in, 2 screws) -> leg 1 slid on from the
// side -> 2 screws -> plate 1 ... -> press the slot trims into the end legs.
//
// ---------------------------------------------------------------------------
// TIP-OVER (masses from the STL volumes, build.py rule: 1.2 mm shell + 15 %
// infill, PLA 1.24 g/cm3): bay plate 0.137 kg (COM y +21.5), leg 0.098 kg
// (COM y -4.2). Head ~0.45 kg + jar with powder ~1.5 kg = 1.95 kg ("full");
// head + empty glass jar ~0.90 kg ("empty"). Head/jar COM at y = BAY_Y_HEAD.
// Load: 10 N pull toward the user at h = BAR_H + 15 = 247 mm -> 2.47 N*m.
// Pivot = front edge of the front TPU foot (leg toe flared BAR_FLARE_F = 42 mm
// ahead of the plate): y = -130.2. Push pivot = rear foot, y = +108.2.
//                        pull: restoring  margin  tips at | push: margin
//   1 bay,   full jar      3.05 N*m       1.23    12.3 N  |       0.93
//   1 bay,   empty jar     1.65 N*m       0.67     6.7 N  |       0.50
//   3 bays,  all full      8.91 N*m       3.61    36 N    |       2.69
//   3 bays,  all empty     4.70 N*m       1.90    19 N    |       1.41
//   10 bays, all full     29.4  N*m      11.9    119 N    |       8.9
//   10 bays, all empty    15.4  N*m       6.2     62 N    |       4.6
//   (pro preset: within 2 % of these numbers.)
// A single full bay does not tip under the 10 N pull. A single bay that may
// run nearly empty, or anyone who yanks the drawer, should fit the rear WALL
// TAB (bar_wall_tab): it ties the plate to the wall and takes any pull.
// Pushing the drawer closed is done by the bands; the rear toes stop on the
// wall. Sliding: TPU feet (mu ~0.7) hold ~17 N on one full bay, so the bar
// tips before it slides and the table above is the governing case.
// The footprint is limited by the bed: leg depth BAY_D + flares <= 246 mm.
// PLATE STIFFNESS: 2 kg on the plate. Both sides are clamped by full-length
// tongues; behind the cup opening the section is a 16 mm deep waffle (6 mm
// slab + 2 mm ribs, <= 24 mm pitch): I ~ 3e4 mm^4 per 70 mm of depth. Fixed-
// fixed span 158 mm, E ~ 2 GPa: sag = F L^3/(192 E I) ~ 0.007 mm.
// The side strips beside the U are 26 mm wide x 16 deep and are carried by
// the tongues along their whole length. Bridges <= 22.7 mm (waffle cells).
// ---------------------------------------------------------------------------
include <../params.scad>

// ---- bar constants (BAR_ prefix; shared by bay/leg/foot, all owned by BAR) ----
BAR_LEG_T      = 10;                        // leg panel thickness (x)
BAY_Y_HEAD     = (BAY_D/2 - PUCK_R)/2;      // head origin y on the bay (6 mm rear margin, 18 mm front)
BAR_PLATE_X    = BAY_W/2 - BAR_LEG_T/2 - REVEAL;   // plate half width (top edge, REVEAL to the leg)
BAR_PLATE_DEPTH = 16;                       // slab + waffle total depth (bottom plane = print bed)
BAR_Z_BOT      = BAR_H - BAR_PLATE_DEPTH;   // plate bottom plane
BAR_RIB_T      = 2.0;                       // waffle rib / rim thickness
BAR_PITCH_MAX  = 24;                        // waffle pitch (bridges <= 22)
// cup opening (U, open to the front), concentric with the drop hole
BAR_CUP_W      = 105;
BAR_CUP_R      = BAR_CUP_W/2;
BAR_CUP_Y      = BAY_Y_HEAD + hy((HOLE_U0 + HOLE_U1)/2);
BAR_CUP_FILLET = 10;                        // round at the U mouth
BAR_CUP_D      = 90;                        // shaker bottle diameter for the clearance check
// tongue (plate) / slot (leg)
BAR_TG_TOP  = 2.0;    // tongue top below BAR_H
BAR_TG_TIP  = 2.4;    // tongue tip height
BAR_TG_D    = 3.0;    // tongue insertion into the leg (beyond the leg face)
BAR_TG_CL   = 0.15;   // slot clearance on the top/bottom faces
BAR_TG_CLX  = 0.3;    // slot clearance at the tip
BAR_SLOT_END = 8;     // slot is blind: stops this far inside the leg's top front/rear corners
BAR_TG_LEN  = BAY_D - 2*BAR_SLOT_END - 1.0;
// screws
BAR_SCREW_Z    = BAR_H - 11;                // M4 axis height
BAR_SCREW_STAG = 4;                         // +x side screws at cell+4, -x side at cell-4
BAR_BOSS_L     = 9.2;                       // boss length (x) inside the plate edge
BAR_BOSS_W     = 14;                        // boss length (y)
BAR_CB_D       = M4_HEAD_D;                 // socket head counterbore
BAR_CB_L       = 4.0;
BAR_PILOT_L    = 8.6;                       // blind M4 pilot in the leg (1.4 skin)
// waffle grid
BAR_RIB_A   = BAR_PLATE_X - BAR_BOSS_L;     // inner face of the side bosses (= a rib line)
_bar_nx     = ceil(2*BAR_RIB_A/BAR_PITCH_MAX);
BAR_PX      = 2*BAR_RIB_A/_bar_nx;
BAR_RIBS_X  = [for (i=[0:_bar_nx]) -BAR_RIB_A + i*BAR_PX];   // ribs running along y
_bar_ny     = ceil(BAY_D/BAR_PITCH_MAX);
BAR_PY      = BAY_D/_bar_ny;
BAR_RIBS_Y  = [for (i=[0:_bar_ny]) -BAY_D/2 + i*BAR_PY];      // ribs running along x
// screw cells: in the side column x in [RIB_A - PX, RIB_A], not cut by the U (key room)
_bar_xin    = BAR_RIB_A - BAR_PX + BAR_RIB_T/2;
_bar_ymin   = BAR_CUP_Y + sqrt(max(0, pow(BAR_CUP_R + BAR_RIB_T, 2) - pow(_bar_xin, 2)));
_bar_cells  = [for (i=[0:_bar_ny-1]) if (-BAY_D/2 + i*BAR_PY >= _bar_ymin) -BAY_D/2 + (i+0.5)*BAR_PY];
BAR_SCREW_CELLS = [_bar_cells[0], _bar_cells[len(_bar_cells)-1]];
BAR_SCREWS_POS  = [for (c = BAR_SCREW_CELLS) c + BAR_SCREW_STAG];  // plate +x side (leg -x face)
BAR_SCREWS_NEG  = [for (c = BAR_SCREW_CELLS) c - BAR_SCREW_STAG];  // plate -x side (leg +x face)
// wall tab
BAR_TAB_W   = 36;
BAR_TAB_XS  = [-BAR_PX/2, BAR_PX/2];        // M3 bosses in the rear row of cells
BAR_TAB_Y   = BAY_D/2 - BAR_PY/2;
BAR_WALL_TABS = false;                      // show the optional tabs in bar_assembly

// ---------------------------------------------------------------------------
// 2D outlines (plan, bar coordinates relative to the bay centre)
module bay_cup_2d() {
    offset(r=-BAR_CUP_FILLET) offset(delta=BAR_CUP_FILLET) union() {
        translate([0, BAR_CUP_Y]) circle(r=BAR_CUP_R, $fn=144);
        translate([-BAR_CUP_R, -BAY_D/2 - 30]) square([2*BAR_CUP_R, BAR_CUP_Y + BAY_D/2 + 30]);
        translate([-BAR_CUP_R - 40, -BAY_D/2 - 30]) square([2*BAR_CUP_R + 80, 30]);
    }
}
module bay_plate_2d() {
    difference() {
        square([2*BAR_PLATE_X, BAY_D], center=true);
        bay_cup_2d();
    }
}
module bay_ribs_2d() {
    intersection() {
        bay_plate_2d();
        union() {
            for (x = BAR_RIBS_X) translate([x - BAR_RIB_T/2, -BAY_D/2]) square([BAR_RIB_T, BAY_D]);
            for (y = BAR_RIBS_Y) translate([-BAR_PLATE_X, y - BAR_RIB_T/2]) square([2*BAR_PLATE_X, BAR_RIB_T]);
        }
    }
    difference() { bay_plate_2d(); offset(delta=-BAR_RIB_T) bay_plate_2d(); }   // perimeter rim + U rim
}

// tongue section in (s, z): s = distance outward from the plate edge (x = BAR_PLATE_X)
module bay_tongue_section() {
    zt = BAR_H - BAR_TG_TOP;
    s1 = REVEAL + BAR_TG_D;
    polygon([[-0.5, zt], [s1, zt], [s1, zt - BAR_TG_TIP],
             [-0.5, zt - BAR_TG_TIP - s1 - 0.5]]);
}
module bay_tongues() {
    for (sd = [-1, 1]) mirror([sd < 0 ? 1 : 0, 0, 0])
        translate([BAR_PLATE_X, 0, 0]) rotate([90, 0, 0])
            linear_extrude(BAR_TG_LEN, center=true) bay_tongue_section();
}
// side screw boss (+x side), y = screw position
module bay_boss(y) { intersection() { bay_boss_raw(y); translate([-BAY_W/2, -BAY_D/2, 0]) cube([BAY_W, BAY_D, BAR_H]); } }
module bay_boss_raw(y) {
    translate([BAR_RIB_A - BAR_RIB_T/2, y - BAR_BOSS_W/2, BAR_Z_BOT])
        cube([BAR_BOSS_L + BAR_RIB_T/2, BAR_BOSS_W, BAR_PLATE_DEPTH - BAY_T + EPS]);
    // contact pad: touches the leg face, sets the REVEAL (below the tongue)
    translate([BAR_PLATE_X - EPS, y - BAR_BOSS_W/2, BAR_Z_BOT])
        cube([REVEAL + EPS, BAR_BOSS_W, BAR_SCREW_Z - BAR_Z_BOT + 2.4]);
}
// teardrop (point up) for horizontal holes printed upright; axis along +x
module bay_teardrop_x(d, l) {
    rotate([0, 90, 0]) linear_extrude(l)
        hull() { circle(d=d, $fn=36); translate([-d/2*0.7071, 0]) rotate(45) square(d/2, center=true); }
}
module bay_screw_cut(y) {
    // counterbore from the inside face, clearance through the pad
    translate([BAR_RIB_A - BAR_RIB_T/2 - EPS, y, BAR_SCREW_Z]) bay_teardrop_x(BAR_CB_D + 0.4, BAR_CB_L);
    translate([BAR_RIB_A - BAR_RIB_T/2 - 1, y, BAR_SCREW_Z]) rotate([0, 90, 0]) cylinder(d=M4_CLEAR, h=BAR_BOSS_L + REVEAL + 3, $fn=28);
}
module bay_dock_pin() {
    h = 2.5; d = DOCK_PIN_D; c = 0.8;
    rotate_extrude($fn=40) polygon([[0, -EPS], [d/2, -EPS], [d/2, h - c], [d/2 - c, h], [0, h]]);
}

// BAY PLATE in bar coordinates (bay 0, centred at x = 0)
module bay_plate() {
    difference() {
        union() {
            // slab with stepped top chamfer (C_TOP in 0.2 mm layers)
            translate([0, 0, BAR_H - BAY_T]) linear_extrude(BAY_T - C_TOP + EPS) bay_plate_2d();
            for (k = [0:2]) translate([0, 0, BAR_H - C_TOP + k*0.2])
                linear_extrude(0.2 + (k < 2 ? EPS : 0)) offset(delta=-(k + 0.5)*0.2) bay_plate_2d();
            // waffle, bottom 0.4 inset (elephant's foot)
            translate([0, 0, BAR_Z_BOT]) linear_extrude(C_BED + EPS) offset(delta=-C_BED/2) bay_ribs_2d();
            translate([0, 0, BAR_Z_BOT + C_BED]) linear_extrude(BAR_PLATE_DEPTH - BAY_T - C_BED + EPS) bay_ribs_2d();
            // side bosses
            for (y = BAR_SCREWS_POS) bay_boss(y);
            for (y = BAR_SCREWS_NEG) mirror([1, 0, 0]) bay_boss(y);
            // wall-tab bosses (M3 from below)
            for (x = BAR_TAB_XS) translate([x, BAR_TAB_Y, BAR_Z_BOT]) cylinder(d=8, h=BAR_PLATE_DEPTH - BAY_T + EPS, $fn=32);
            bay_tongues();
            // dock pins
            for (p = DOCK_PINS) translate([p[0], p[1] + BAY_Y_HEAD, BAR_H - EPS]) bay_dock_pin();
        }
        for (y = BAR_SCREWS_POS) bay_screw_cut(y);
        for (y = BAR_SCREWS_NEG) mirror([1, 0, 0]) bay_screw_cut(y);
        for (x = BAR_TAB_XS) translate([x, BAR_TAB_Y, BAR_Z_BOT - 1]) cylinder(d=M3_PILOT, h=10, $fn=20);
    }
}
// Print: UPRIGHT. The waffle/rim bottom plane is on the bed; the visible top is
// the last layer (ironed). Every rib reaches the bed, the slab bridges <= 22.7 mm
// between ribs, and the tongue underside is 45 deg.
module bay_plate_print() { translate([0, 0, -BAR_Z_BOT]) bay_plate(); }

// ---------------------------------------------------------------------------
// Optional rear WALL TAB: an L bracket screwed (2 x M3 x 10 from below, hidden)
// into the plate's rear bosses; its flange screws to the wall (one 4 mm
// countersunk wood screw). Bar coordinates, bay 0.
BAR_TAB_T    = 4;
BAR_TAB_DROP = 36;
function bar_wall_y() = BAY_D/2 + BAR_FLARE_R;   // wall plane = rear toes of the legs
module bar_wall_tab_2d() {   // profile in (y, z)
    y0 = BAR_TAB_Y - 10; y1 = bar_wall_y();
    z1 = BAR_Z_BOT - 0.3;
    offset(r=1.5) offset(delta=-1.5) union() {
        translate([y0, z1 - BAR_TAB_T]) square([y1 - y0, BAR_TAB_T]);
        translate([y1 - BAR_TAB_T, z1 - BAR_TAB_DROP]) square([BAR_TAB_T, BAR_TAB_DROP]);
        polygon([[y1 - BAR_TAB_T + 0.1, z1 - BAR_TAB_T + 0.1], [y1 - BAR_TAB_T - 10, z1 - BAR_TAB_T + 0.1],
                 [y1 - BAR_TAB_T + 0.1, z1 - BAR_TAB_T - 10]]);   // 45 deg gusset
    }
}
module bar_wall_tab() {
    z1 = BAR_Z_BOT - 0.3;
    difference() {
        translate([-BAR_TAB_W/2, 0, 0]) rotate([90, 0, 90]) linear_extrude(BAR_TAB_W) bar_wall_tab_2d();
        for (x = BAR_TAB_XS) translate([x, BAR_TAB_Y, z1 - BAR_TAB_T - 1]) {
            cylinder(d=M3_CLEAR, h=BAR_TAB_T + 2, $fn=20);
            translate([0, 0, -20 + 1 + 1.6]) cylinder(d=M3_HEAD_D + 0.4, h=20, $fn=28);   // head recess from below
        }
        // wall screw: countersunk on the bar side
        translate([0, bar_wall_y() + 1, z1 - BAR_TAB_DROP/2 - 4]) rotate([90, 0, 0]) {
            cylinder(d=4.5, h=BAR_TAB_T + 2, $fn=24);
            translate([0, 0, BAR_TAB_T + 1 - 2.25]) cylinder(d1=4.5, d2=9.0, h=2.25 + EPS, $fn=32);
            translate([0, 0, BAR_TAB_T + 1]) cylinder(d=9, h=20, $fn=32);
        }
    }
}
// Print: on its side (the L profile on the bed); no overhangs, no supports.
module bar_wall_tab_print() { translate([0, 0, BAR_TAB_W/2]) rotate([0, 90, 0]) translate([0, -BAR_TAB_Y, -BAR_Z_BOT]) bar_wall_tab(); }

// ---------------------------------------------------------------------------
// BAR ASSEMBLY: n bays, n+1 legs (+ feet), a head on each bay, slot trims on
// the two end legs' outer faces.
module bar_assembly(n) {
    for (i = [0:n-1]) translate([i*BAY_W, 0, 0]) {
        color(_pcol("bay_plate")) bay_plate();
        if (BAR_WALL_TABS) color(_pcol("bay_plate")) bar_wall_tab();
        translate([0, BAY_Y_HEAD, BAR_H]) head_assembly();
    }
    for (j = [0:n]) translate([(j - 0.5)*BAY_W, 0, 0]) {
        color(_pcol("leg")) leg();
        color(_pcol("foot")) foot();
    }
    color(_pcol("leg")) {
        translate([-0.5*BAY_W, 0, 0]) mirror([1, 0, 0]) leg_slot_trim();
        translate([(n - 0.5)*BAY_W, 0, 0]) leg_slot_trim();
    }
}
