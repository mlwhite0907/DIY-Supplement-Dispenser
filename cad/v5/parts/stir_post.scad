// parts/stir_post.scad: OWNER group BODY. Contract: cad/v5/README.md
// STIR POST (PLA, accent): rides in the slide's square socket at slide-local
// u = POST_U0, passes up through the ceiling slot and the funnel keyway, then a
// crossbar sweeps the funnel and a tall tine reaches into the jar neck. It is a
// planar part (all features in the x-z plane, constant 4 mm thick in y), so it
// prints lying flat with a clean square section and no supports.
include <../params.scad>

STIR_T     = POST_D;                        // thickness along the pull (y), 4.0
STIR_W     = POST_PEG;                      // stem / peg width (x), 4.0 (<= 2*SLOT_HW - 1)
STIR_PEG_L = POST_SOCKET_DEPTH - 0.5;       // peg length below the slide top
STIR_Z0    = Z_SLIDE_TOP - STIR_PEG_L;      // bottom of the peg
STIR_BAR_H = 4.5;                           // crossbar section height (z)
STIR_TINE_W = 4.0;                          // tine width (x)
STIR_TINE_TOP = Z_RIM + 50;                 // tine reaches ~50 mm into the jar
STIR_FILLET = 3.0;                          // fillets at the junctions
STIR_CH    = 0.4;                           // edge chamfer all round
STIR_CLR   = 3.0;                           // required clearance to funnel / bore / mouth
// Crossbar height: above the keyway and high enough that the stem clears the
// funnel's rear wall at rest by STIR_CLR.
STIR_ZC    = Z_CEIL_TOP + max(KEYWAY_H + 6, 0.5*FUNNEL_H);
// Funnel section at height z is (1-t)*throat (+) disc(t*MOUTH_R): half width in x at |y|.
function stir_t(z) = max(0, min(1, (z - Z_CEIL_TOP)/FUNNEL_H));
function stir_fx(z, y) = let(t = stir_t(z), ry = (1-t)*T_LEN/2, rr = t*MOUTH_R, dy = max(0, abs(y) - ry))
    (1-t)*T_WID/2 + sqrt(max(0, rr*rr - dy*dy));
// Worst case is the rest position (post nearest the rear wall), at the bar's underside.
STIR_YR    = hy(POST_U0) + STIR_T/2;
STIR_BAR_L = min(T_WID/2 - 4,
    stir_fx(STIR_ZC - STIR_BAR_H/2 - STIR_CLR, STIR_YR + STIR_CLR) - STIR_CLR - 1);  // half length

// Short side tines rise from the crossbar ends (a trident / rake): they plow the
// funnel side walls where powder hangs up.
STIR_SIDE_X   = STIR_BAR_L - STIR_TINE_W/2;
STIR_SIDE_TOP = STIR_ZC + 14;
STIR_SIDES    = STIR_SIDE_X - STIR_TINE_W >= 2*STIR_FILLET + 1;   // small funnels: plain T
module stir_post_2d() {   // in (x, z) of head coordinates
    offset(r=-STIR_FILLET) offset(delta=STIR_FILLET) union() {
        translate([-STIR_W/2, STIR_Z0]) square([STIR_W, STIR_ZC - STIR_Z0]);
        hull() for (s=[-1, 1]) translate([s*(STIR_BAR_L - STIR_BAR_H/2), STIR_ZC])
            circle(d=STIR_BAR_H, $fn=40);
        if (STIR_SIDES) for (s=[-1, 1]) translate([s*STIR_SIDE_X, 0]) {
            translate([-STIR_TINE_W/2, STIR_ZC]) square([STIR_TINE_W, STIR_SIDE_TOP - STIR_TINE_W/2 - STIR_ZC]);
            translate([0, STIR_SIDE_TOP - STIR_TINE_W/2]) circle(d=STIR_TINE_W, $fn=40);
        }
        translate([-STIR_TINE_W/2, STIR_ZC]) square([STIR_TINE_W, STIR_TINE_TOP - STIR_TINE_W/2 - STIR_ZC]);
        translate([0, STIR_TINE_TOP - STIR_TINE_W/2]) circle(d=STIR_TINE_W, $fn=40);
    }
}
module stir_octa(c) {
    polyhedron([[c,0,0],[-c,0,0],[0,c,0],[0,-c,0],[0,0,c],[0,0,-c]],
        [[0,2,4],[2,1,4],[1,3,4],[3,0,4],[2,0,5],[1,2,5],[3,1,5],[0,3,5]]);
}
// Planar body: profile in local (X, Y), thickness along local Z, centred on Z = 0.
module stir_post_local() {
    minkowski() {
        linear_extrude(STIR_T - 2*STIR_CH, center=true) offset(delta=-STIR_CH) stir_post_2d();
        stir_octa(STIR_CH);
    }
}
module stir_post() {
    translate([0, SLIDE_Y0 - POST_U0, 0]) rotate([90, 0, 0]) stir_post_local();
}
// Print lying flat on one 4 x 4 face: the x-z plane on the bed, tine along +x.
module stir_post_print() {
    translate([0, 0, STIR_T/2]) rotate([0, 0, -90])
        translate([0, -(STIR_Z0 + STIR_TINE_TOP)/2, 0]) stir_post_local();
}
