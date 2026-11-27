// parts/band.scad: OWNER group DRAWER (unit: slide). Contract: cad/v5/README.md
// ----------------------------------------------------------------------------
// BAND (TPU 95A, x2): the drawer's return springs. Open strip with an eyelet at
// each end. Default routing (README 5): slide hook -> around the base's rear
// post (pulley, BAND_POST_D) -> front anchor post (d 6).
//   * Eye A (hook end) slips over the slide hook's arm from the outside and is
//     kept on by the hook's lip; in use it stands vertical (ring in the y-z
//     plane) and the strip runs on edge, which is how it wraps the rear post.
//   * Eye B (anchor end) drops over the front anchor post from above (the strip
//     takes a 90-degree twist along the outer run; TPU does not mind).
// Free length (eye centre to eye centre) = rest path / BAND_PRELOAD (8 %).
// Section BAND_W x BAND_T: BAND_T = 0.6 / 0.8 / 1.0 = light / medium / firm
// (override with -D BAND_T=...).
// PRINT: flat, one piece, 0.2 mm layers (BAND_T = 3/4/5 layers). Long bands
// (big presets) print folded as a U so they always fit the bed.
// ----------------------------------------------------------------------------
include <../params.scad>

BAND_T   = 0.8;                // thickness: 0.6 light, 0.8 medium, 1.0 firm
BAND_W   = 1.25;               // strip width
BAND_PRELOAD = 1.08;
BAND_EYE_A_ID = 5.6;           // over the hook arm (4.4 x 2.6), snaps past its lip
BAND_EYE_B_ID = 6.4;           // over the d6 front anchor post
BAND_EYE_RW   = 1.5;           // eyelet ring width (TPU >= 1.2)
BAND_POST_R   = BAND_POST_D/2;
// Same formulas as slide.scad (SLIDE_HOOK_U, SLIDE_EYE_ZC): the hook position.
BAND_HOOK_U   = U_HOOK_S;
BAND_Z        = Z_ROD - (HOOK_SLOT_H - 1.5)/2 + (BAND_X - SLIDE_W/2) + 1.3;
function band_hook_y(pull) = T_LEN/2 - pull - BAND_HOOK_U;

// eye-centre to eye-centre path length for a given pull distance
function band_path(pull) = (Y_BAND_ANCHOR - band_hook_y(pull)) + PI*(BAND_POST_R + BAND_T/2)
                           + (Y_BAND_ANCHOR - Y_BAND_FRONT);
BAND_PATH0 = band_path(0);
BAND_FREE  = BAND_PATH0/BAND_PRELOAD;              // printed eye-to-eye length
BAND_STRAIN_MAX = band_path(STROKE)/BAND_FREE - 1; // at full pull
echo(str("[band] path rest ", BAND_PATH0, " mm, free ", BAND_FREE, " mm, strain rest ",
         round(100*(BAND_PRELOAD - 1)), "% / full pull ", round(100*BAND_STRAIN_MAX), "%"));

// ---------- 2D (print plane) -------------------------------------------------
module band_ring_2d(id) { difference() { circle(d=id + 2*BAND_EYE_RW, $fn=64); circle(d=id, $fn=64); } }
module band_neck_2d(id, dir=1) {        // tapered join from ring to strip (toward +x if dir=1)
    ro = id/2 + BAND_EYE_RW;
    difference() {
        hull() {
            translate([dir*(ro - 0.8), 0]) square([1.6, 2*BAND_EYE_RW + 0.6], center=true);
            translate([dir*(ro + 3.5), 0]) square([0.1, BAND_W], center=true);
        }
        circle(d=id, $fn=64);
    }
}
module band_strip_2d(len) { translate([0, -BAND_W/2]) square([len, BAND_W]); }

// straight print layout, eye A at x=0, eye B at x=BAND_FREE
module band_flat_2d() {
    band_ring_2d(BAND_EYE_A_ID); band_neck_2d(BAND_EYE_A_ID, 1);
    translate([BAND_FREE, 0]) { band_ring_2d(BAND_EYE_B_ID); band_neck_2d(BAND_EYE_B_ID, -1); }
    band_strip_2d(BAND_FREE);
}
// U-folded print layout for long bands (legs BAND_U_GAP apart)
BAND_U_GAP = 14;
BAND_U_LEG = (BAND_FREE - PI*BAND_U_GAP/2)/2;
module band_u_2d() {
    band_ring_2d(BAND_EYE_A_ID); band_neck_2d(BAND_EYE_A_ID, 1);
    translate([0, BAND_U_GAP]) { band_ring_2d(BAND_EYE_B_ID); band_neck_2d(BAND_EYE_B_ID, 1); }
    band_strip_2d(BAND_U_LEG);
    translate([0, BAND_U_GAP]) band_strip_2d(BAND_U_LEG);
    translate([BAND_U_LEG, BAND_U_GAP/2]) difference() {
        circle(r=BAND_U_GAP/2 + BAND_W/2, $fn=96); circle(r=BAND_U_GAP/2 - BAND_W/2, $fn=96);
        translate([-50, -50]) square([50, 100]);
    }
}
BAND_STRAIGHT = BAND_FREE + BAND_EYE_A_ID/2 + BAND_EYE_B_ID/2 + 2*BAND_EYE_RW <= 230;

// PRINT: flat on the bed, centred.
module band_print() {
    if (BAND_STRAIGHT)
        translate([-BAND_FREE/2, 0, 0]) linear_extrude(BAND_T) band_flat_2d();
    else
        translate([-BAND_U_LEG/2, -BAND_U_GAP/2, 0]) linear_extrude(BAND_T) band_u_2d();
}

// ---------- assembled pose (both sides, current STATE_PULL) ----------------------
module band_side(s) {
    yh  = band_hook_y(PULL_D);
    xi  = BAND_X - BAND_T/2;                       // inner run (against the post's inner side)
    xo  = BAND_X + BAND_POST_D + BAND_T/2;         // outer run
    xpc = BAND_X + BAND_POST_R;                    // rear post centre
    roA = BAND_EYE_A_ID/2 + BAND_EYE_RW;
    roB = BAND_EYE_B_ID/2 + BAND_EYE_RW;
    mirror([s < 0 ? 1 : 0, 0, 0]) {
        // eye A: vertical ring around the hook arm
        translate([xi, yh, BAND_Z]) rotate([0, 90, 0])
            linear_extrude(BAND_T, center=true) band_ring_2d(BAND_EYE_A_ID);
        // inner run: eye A -> rear post
        translate([xi - BAND_T/2, yh + roA - 0.5, BAND_Z - BAND_W/2])
            cube([BAND_T, Y_BAND_ANCHOR - yh - roA + 0.5 + EPS, BAND_W]);
        // wrap around the rear post (180 degrees, over its rear side)
        translate([xpc, Y_BAND_ANCHOR, BAND_Z - BAND_W/2])
            rotate_extrude(angle=180, $fn=96) translate([BAND_POST_R, 0]) square([BAND_T, BAND_W]);
        // outer run: rear post -> front anchor
        translate([xo - BAND_T/2, Y_BAND_FRONT + roB - 0.5, BAND_Z - BAND_W/2])
            cube([BAND_T, Y_BAND_ANCHOR - Y_BAND_FRONT - roB + 0.5 + EPS, BAND_W]);
        // eye B: flat ring around the front anchor post
        translate([BAND_X_OUT, Y_BAND_FRONT, BAND_Z - BAND_T/2])
            linear_extrude(BAND_T) band_ring_2d(BAND_EYE_B_ID);
    }
}
module band() { band_side(1); band_side(-1); }
