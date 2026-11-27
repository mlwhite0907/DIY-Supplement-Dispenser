// parts/jaw.scad: OWNER group CHUCK. Contract: cad/v5/README.md
// JAW (PLA, accent, x3 identical). Rides a radial dovetail track in the guide
// plate top; its pin drops through the plate's pin slot into the ring's scroll
// groove, so twisting the ring drives all three jaws together. The concave grip
// face carries a TPU pad (jaw_pad.scad) keyed in a vertical dovetail slot.
//
// JAW-LOCAL FRAME (shared with jaw_pad.scad):
//   x = radial (outward), y = tangential, z = height above the guide-plate top.
//   The jaw is modelled at its NOMINAL position (pin at x = R_PIN_NOM), so the
//   grip face is a cylinder of radius R_FACE_NOM about the origin. Posing adds
//   the radial shift R_PIN - R_PIN_NOM, the rotation JAW_ANGLES[i] and Z_GP_TOP.
include <../params.scad>

// ---- private constants ---------------------------------------------------------
JAW_RT      = 1.6;                    // top-edge round (back + sides)
JAW_RC      = 2.0;                    // plan corner radius at the back
JAW_RF      = 0.8;                    // plan round on the face/side corners
JAW_DRAFT   = 3.5;                    // back face leans in: top is this much shorter
JAW_X_FACE  = R_FACE_NOM;             // PLA face radius at nominal
JAW_X_BACK  = R_FACE_NOM + JAW_L;     // back of the jaw at nominal
// Underside relief over the gasket: the jaw front may travel over the gasket
// (smaller necks), so the front JAW_RELIEF_L mm of the underside stand clear of
// the gasket top + bead.
JAW_RELIEF_H = GASKET_PROUD + 0.5 + 0.4;                                   // 1.5
JAW_RELIEF_L = (GASKET_OD/2 + 0.2 + 0.6) - (R_PIN_MIN - PIN_OFF);          // ~4.3
// Dovetail tongue, radial span measured from the PLA face (see params request).
JAW_TONGUE  = [JAW_RELIEF_L + 1.7, JAW_L - 1.0];
JAW_DT_CL   = 0.25;                   // dovetail clearance per side and at the floor
// Pad key slot: vertical dovetail in the face, open at the bottom, blind at top.
JAW_KEY     = [3.0, 5.0, 1.8];        // [neck width at face, width at depth, depth]
JAW_KEY_LIP = 0.5;                    // straight neck before the dovetail flare
JAW_KEY_TOP = JAW_H - 1.6;            // key slot stops 1.6 below the jaw top
JAW_PAD_Z0  = JAW_RELIEF_H;           // pad bottom (flush with the relief ceiling)
JAW_PAD_TOP = JAW_H - 0.5;            // pad top: 0.5 shadow step under the jaw top
JAW_PAD_W   = JAW_W - 2.0;            // pad tangential width
// Pin (relative to the guide-plate top)
JAW_PIN_BOT = (Z_RING_TOP - SCROLL_DEPTH + 0.4) - Z_GP_TOP;   // 0.4 above the groove floor
JAW_TNG_BOT = -DOVETAIL[2] + JAW_DT_CL;                         // tongue bottom

function jaw_track_w(z) = DOVETAIL[0] + (DOVETAIL[1] - DOVETAIL[0])*(-z)/DOVETAIL[2];

// ---- plan shapes (2D) -----------------------------------------------------------
// Convex outline: tangential strip clipped by the back arc, front extended past
// the face so hull() works; the concave face is cut afterwards.
module _jaw_plan_convex(inset=0, trim=0) {
    offset(delta=-inset)
    offset(r=JAW_RC) offset(delta=-JAW_RC)
    intersection() {
        circle(r=JAW_X_BACK - trim, $fa=0.5);
        translate([JAW_X_FACE - 6, -JAW_W/2]) square([JAW_L + 8, JAW_W]);
    }
}
// True plan: face cut, face corners softened.
module _jaw_plan() {
    offset(r=JAW_RF) offset(delta=-JAW_RF)
    difference() { _jaw_plan_convex(); circle(r=JAW_X_FACE, $fa=0.5); }
}
// Pad key profile in plan: x from the face outward. grow = extra per side.
module _jaw_key_2d(grow=0, x_in=-0.5) {
    k = JAW_KEY;
    polygon([
        [x_in,                 -k[0]/2 - grow],
        [JAW_KEY_LIP,          -k[0]/2 - grow],
        [JAW_KEY_LIP + k[2],   -k[1]/2 - grow],
        [JAW_KEY_LIP + k[2],    k[1]/2 + grow],
        [JAW_KEY_LIP,           k[0]/2 + grow],
        [x_in,                  k[0]/2 + grow]]);
}

// ---- body -------------------------------------------------------------------------
module _jaw_block() {
    n = 6;
    hull() {
        linear_extrude(EPS) _jaw_plan_convex(C_TOP);              // underside chamfer
        translate([0,0,C_TOP]) linear_extrude(EPS) _jaw_plan_convex(0);
        translate([0,0,JAW_H - JAW_RT]) linear_extrude(EPS)
            _jaw_plan_convex(0, JAW_DRAFT*(JAW_H - JAW_RT)/JAW_H);
        for (k=[1:n]) let(a = 90*k/n, z = JAW_H - JAW_RT + JAW_RT*sin(a))
            translate([0,0,z - (k==n ? EPS : 0)])
                linear_extrude(EPS) _jaw_plan_convex(JAW_RT*(1 - cos(a)), JAW_DRAFT*z/JAW_H);
    }
}
module _jaw_body() {
    difference() {
        intersection() {
            _jaw_block();
            translate([0,0,-1]) linear_extrude(JAW_H + 2) _jaw_plan();
        }
        // underside relief over the gasket
        translate([0,0,-1]) linear_extrude(1 + JAW_RELIEF_H)
            intersection() {
                circle(r=JAW_X_FACE + JAW_RELIEF_L, $fa=0.5);
                translate([JAW_X_FACE - 8, -JAW_W]) square([JAW_L, 2*JAW_W]);
            }
        // pad key slot, open at the bottom
        translate([JAW_X_FACE, 0, -1]) linear_extrude(1 + JAW_KEY_TOP) _jaw_key_2d(0);
    }
}

// ---- tongue + pin ---------------------------------------------------------------------
module _jaw_tongue() {
    zb = JAW_TNG_BOT;
    c  = 0.4;
    x0 = JAW_X_FACE + JAW_TONGUE[0];
    x1 = JAW_X_FACE + JAW_TONGUE[1];
    hb = jaw_track_w(zb)/2 - JAW_DT_CL;          // half width at the tongue bottom
    hc = jaw_track_w(zb + c)/2 - JAW_DT_CL;
    ht = jaw_track_w(0)/2 - JAW_DT_CL;           // half width at the plate top
    intersection() {
        translate([x0 - 1, 0, 0]) rotate([90,0,90]) linear_extrude(x1 - x0 + 2)
            polygon([[-hb + c, zb], [hb - c, zb], [hc, zb + c], [ht, 0], [ht, 0.6],
                     [-ht, 0.6], [-ht, 0], [-hc, zb + c]]);
        hull() {                                  // chamfered radial ends
            translate([x0 + c, -10, zb]) cube([x1 - x0 - 2*c, 20, EPS]);
            translate([x0, -10, zb + c]) cube([x1 - x0, 20, 0.6 - zb - c]);
        }
    }
}
module _jaw_pin() {
    zt = JAW_TNG_BOT + 0.3;
    zb = JAW_PIN_BOT;
    translate([R_PIN_NOM, 0, 0])
        rotate_extrude($fn=40) polygon([
            [0, zb], [PIN_D/2 - 0.4, zb], [PIN_D/2, zb + 0.4], [PIN_D/2, zt], [0, zt]]);
}

// Whole jaw in the jaw-local frame (z relative to the guide-plate top).
module _jaw_rel() { union() { _jaw_body(); _jaw_tongue(); _jaw_pin(); } }

// ---- contract modules -------------------------------------------------------------------
module jaw_place(i) {
    rotate([0,0,JAW_ANGLES[i]]) translate([R_PIN - R_PIN_NOM, 0, Z_GP_TOP]) children();
}
module jaw(i) { jaw_place(i) _jaw_rel(); }

// Print: TOP FACE DOWN on the textured plate, pin pointing up. The visible
// rounded top is bed-side (texture, and the round doubles as the bed chamfer).
// The underside that slides on the guide plate is the last-printed top face:
// iron it. Dovetail flanks overhang 27 deg from vertical: no supports.
// Use 4+ walls / 100% infill so the scroll pin is solid.
module jaw_print() {
    translate([-(JAW_X_FACE + JAW_L/2), 0, JAW_H]) mirror([0,0,1]) _jaw_rel();
}
