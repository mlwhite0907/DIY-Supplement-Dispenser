// parts/deck.scad: OWNER group BODY. Contract: cad/v5/README.md
// DECK: upper puck shell. Ceiling plate (throat + strike-off edge, post slot,
// wiper groove, relieved underside), funnel with stir-post keyway, outer skin
// with the upper half of the reveal groove, ring bearing flange on a 45 deg
// support cone, hub with guide-plate pilots, join-screw bosses.
include <../params.scad>

// ---- private constants -------------------------------------------------------
DECK_R_IN      = PUCK_R - SKIN_T;               // skin inner radius
DECK_FUN_WALL  = 2.0;                           // funnel wall (normal)
DECK_FUN_OFF   = DECK_FUN_WALL/sin(FUNNEL_ANGLE);   // horizontal offset giving that normal wall
DECK_FL_T      = 3.0;                           // flange plate thickness at the hub
DECK_HUB_R     = HUB_OD/2;
DECK_REVEAL    = 0.5;                           // upper half of the 1 mm V reveal (0.5 x 45 deg)
DECK_RELIEF    = 0.4;                           // underside relief depth
DECK_LAND      = 5.0;                           // land margin around throat / transport path / slot
DECK_RIB_LAND_W = 1.6;                          // contact ribs inside relieved zones (bridge anchors)
DECK_RIB_PITCH = 11;                            // max relief bridge span ~ pitch - rib
DECK_WG_GAP    = 1.0;                           // wiper groove: gap behind throat rear edge / slot
DECK_WG_W      = 2.0;                           // wiper groove width
DECK_WG_D      = 2.0;                           // wiper groove depth
DECK_WG_END    = T_WID/2 + 2;                   // |x| where the rear-edge groove ends
DECK_BOSS_D    = 8.0;
DECK_PILOT_DEPTH = 12;                          // M3 pilots from the ceiling underside (>= 9)
DECK_GP_PILOT_DEPTH = 9;                        // M3 pilots in the hub top
DECK_RIB_T     = 2.0;                           // radial ribs funnel -> skin
DECK_RIB_ANGLES = [0, 45, 135, 180, 225, 270, 315];
DECK_KW_WALL   = 2.0;                           // wall around the keyway
// 45 deg support cone under the flange: passes (HUB_R, Z_RING_BOT - FL_T) and
// rises toward the axis; it meets the skin (or the ceiling top on small pucks).
DECK_CONE_Z0   = Z_RING_BOT - DECK_FL_T;
function deck_cone_z(r) = DECK_CONE_Z0 + (DECK_HUB_R - r);

// ---- 2D helpers ----------------------------------------------------------------
module deck_throat_2d() { square([T_WID, T_LEN], center=true); }
module deck_slot_2d() {   // ceiling post slot, body u in [SLOT_U0, 0]
    translate([-SLOT_HW, hy(0)]) square([2*SLOT_HW, hy(SLOT_U0) - hy(0)]);
}
// Wiper groove centreline (U path around the post slot), shared with the wiper.
function deck_wg_path() = let(
    yr = hy(0) + DECK_WG_GAP + DECK_WG_W/2,
    xs = SLOT_HW + DECK_WG_GAP + DECK_WG_W/2,
    yb = hy(SLOT_U0) + DECK_WG_GAP + DECK_WG_W/2,
    xe = DECK_WG_END - DECK_WG_W/2)
    [[-xe, yr], [-xs, yr], [-xs, yb], [xs, yb], [xs, yr], [xe, yr]];
module deck_wg_2d() {
    p = deck_wg_path();
    for (i=[0:len(p)-2]) hull() for (q=[p[i], p[i+1]])
        translate(q) square(DECK_WG_W, center=true);
}
// Lands (full contact with the slide top, gap CL_VT).
module deck_lands_2d() {
    // throat +/-LAND and the whole chamber transport path to the drop hole
    translate([-PUCK_R, hy(HOLE_U1 + DECK_LAND)])
        square([2*PUCK_R, hy(-DECK_LAND) - hy(HOLE_U1 + DECK_LAND)]);
    offset(delta=DECK_LAND) deck_slot_2d();
    // contact ribs along the pull direction (bridge anchors for the relief)
    n = ceil(2*CHAN_HW/DECK_RIB_PITCH);
    for (k=[1:n-1]) translate([-CHAN_HW + k*2*CHAN_HW/n - DECK_RIB_LAND_W/2, -PUCK_R])
        square([DECK_RIB_LAND_W, 2*PUCK_R]);
}
module deck_relief_2d() {
    difference() {
        intersection() {
            translate([-CHAN_HW, -PUCK_R]) square([2*CHAN_HW, PUCK_R + Y_REAR_WALL]);
            circle(r=DECK_R_IN - 1.0, $fn=180);
        }
        deck_lands_2d();
    }
}

// ---- 3D pieces -------------------------------------------------------------------
// Funnel void: hull(throat @ Z_CEIL_TOP, MOUTH_R circle @ Z_FUNNEL_TOP), throat through
// the ceiling, plain bore above, keyway box for the stir post.
module deck_funnel_void() {
    hull() {
        translate([0, 0, Z_CEIL_TOP]) linear_extrude(EPS) deck_throat_2d();
        translate([0, 0, Z_FUNNEL_TOP - EPS]) cylinder(r=MOUTH_R, h=EPS, $fn=180);
    }
    translate([0, 0, Z_CEIL - 1]) linear_extrude(CEIL_T + 1 + EPS) deck_throat_2d();
    translate([0, 0, Z_FUNNEL_TOP - EPS]) cylinder(r=MOUTH_R, h=Z_GP_BOT - Z_FUNNEL_TOP + 5, $fn=180);
    translate([0, 0, Z_CEIL - 1]) linear_extrude(CEIL_T + KEYWAY_H + 1) deck_slot_2d();
}
module deck_funnel_solid() {
    hull() {
        translate([0, 0, Z_CEIL]) linear_extrude(Z_CEIL_TOP - Z_CEIL)
            offset(delta=DECK_FUN_OFF) deck_throat_2d();
        translate([0, 0, Z_FUNNEL_TOP - EPS])
            cylinder(r=MOUTH_R + DECK_FUN_OFF, h=EPS, $fn=180);
    }
    // wall continuing around the keyway
    translate([0, 0, Z_CEIL]) linear_extrude(CEIL_T + KEYWAY_H + DECK_KW_WALL)
        offset(delta=DECK_KW_WALL) deck_slot_2d();
}
// Skin, flange, support cone and hub as one revolved profile.
module deck_shell() {
    zc = max(Z_CEIL_TOP, deck_cone_z(DECK_R_IN));          // cone foot height
    rc = DECK_HUB_R - (zc - DECK_CONE_Z0);                  // cone foot radius (<= DECK_R_IN)
    rt = DECK_HUB_R - (Z_GP_BOT - DECK_CONE_Z0);            // cone meets hub-top height
    c = C_TOP;
    rotate_extrude($fn=240) polygon([
        // outer skin: reveal chamfer at the joint, C_TOP at the flange edge
        [DECK_R_IN - EPS, Z_CEIL],
        [PUCK_R - DECK_REVEAL, Z_CEIL],
        [PUCK_R, Z_CEIL + DECK_REVEAL],
        [PUCK_R, Z_RING_BOT - c],
        [PUCK_R - c, Z_RING_BOT],
        // flange top (ring bearing face) -> hub
        [DECK_HUB_R, Z_RING_BOT],
        [DECK_HUB_R, Z_GP_BOT - c],
        [DECK_HUB_R - c, Z_GP_BOT],
        [rt, Z_GP_BOT],
        // 45 deg support cone underside back down to the skin / ceiling
        [rc, zc],
        [DECK_R_IN - EPS, zc]
    ]);
}
module deck_ceiling() {
    translate([0, 0, Z_CEIL]) cylinder(r=DECK_R_IN + EPS, h=CEIL_T, $fn=240);
}
module deck_ribs() {
    for (a = DECK_RIB_ANGLES) rotate(a)
        translate([0, -DECK_RIB_T/2, Z_CEIL_TOP - EPS])
            cube([DECK_R_IN + EPS, DECK_RIB_T, DECK_CONE_Z0 - Z_CEIL_TOP]);
}
module deck_bosses() {
    for (p = JOIN_SCREWS) translate([p[0], p[1], Z_CEIL])
        cylinder(d=DECK_BOSS_D, h=DECK_CONE_Z0 - Z_CEIL, $fn=48);
}
module deck_holes() {
    // join-screw pilots from the ceiling underside up
    for (p = JOIN_SCREWS) translate([p[0], p[1], Z_CEIL - EPS]) {
        cylinder(d=M3_PILOT, h=DECK_PILOT_DEPTH, $fn=24);
        cylinder(d1=M3_PILOT + 0.8, d2=M3_PILOT, h=0.4, $fn=24);   // lead-in
    }
    // guide-plate pilots in the hub top
    for (a = GP_SCREW_ANGLES) translate([GP_SCREW_R*cos(a), GP_SCREW_R*sin(a), Z_GP_BOT - DECK_GP_PILOT_DEPTH])
        cylinder(d=M3_PILOT, h=DECK_GP_PILOT_DEPTH + EPS, $fn=24);
}
module deck_underside_cuts() {
    translate([0, 0, Z_CEIL - EPS]) linear_extrude(DECK_WG_D + EPS) deck_wg_2d();
    translate([0, 0, Z_CEIL - EPS]) linear_extrude(DECK_RELIEF + EPS) deck_relief_2d();
}

// ---- part ------------------------------------------------------------------------
module deck() {
    difference() {
        union() {
            deck_ceiling();
            deck_shell();
            deck_funnel_solid();
            deck_ribs();
            deck_bosses();
        }
        deck_funnel_void();
        deck_holes();
        deck_underside_cuts();
    }
}
// Print UPRIGHT: the ceiling underside (Z_CEIL) is on the bed, so the strike-off
// edge (throat front edge) is a crisp first-layer edge with no chamfer. The lands
// touch the bed; the 0.4 relief areas bridge <= ~9.5 mm between the contact ribs.
// The flange top (ring bearing face) and the hub top are top surfaces: iron them.
// Underside overhangs: support cone 45 deg, funnel outer 52 deg, reveal 45 deg.
module deck_print() { translate([0, 0, -Z_CEIL]) deck(); }
