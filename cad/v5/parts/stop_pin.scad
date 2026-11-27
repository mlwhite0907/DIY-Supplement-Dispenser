// parts/stop_pin.scad: OWNER group BODY. Contract: cad/v5/README.md
// STOP PIN (PLA, accent). Pushed up from below through the base floor at body
// u = U_STOP, x = 0. Its shank rides in the slide-underside groove (STOP_GROOVE);
// the groove ends are the rest and full-pull stops.
//
// Retention: a bayonet that fits inside the 3 mm floor.
//   - The head is a flush disc (STOP_PIN_HUB_D) with two ears whose undersides
//     are 45-degree cones (so the pin prints head-down without supports).
//   - The base has a counterbore with two entry notches at STOP_PIN_A_ENTRY and,
//     STOP_PIN_TURN degrees further on, a 45-degree conical ledge the ears rest
//     on, ending in a hard stop.
//   - Install: grip slot on the two dimples on the base bottom, push up, turn
//     STOP_PIN_TURN degrees clockwise (seen from below) to the stop, let go.
//     Gravity seats the ears on the cones.
//   - Remove (tool-free: thumbnail or coin in the grip slot): push up, turn back.
// The STOP_PIN_* constants are shared with parts/base.scad (it cuts the recess).
include <../params.scad>

STOP_PIN_HUB_D   = 10.0;   // flush head disc
STOP_PIN_HUB_H   = 1.4;    // head disc height
STOP_PIN_EAR_R   = 6.2;    // ear tip radius
STOP_PIN_EAR_W   = 3.6;    // ear width (tangential)
STOP_PIN_SEAT_Z  = 0.2;    // seated head bottom sits this far above the base bottom (never proud)
STOP_PIN_TOP_Z   = Z_FLOOR + 3.5;   // reaches 3.5 mm into the 4 mm slide groove
STOP_PIN_LEN     = STOP_PIN_TOP_Z - STOP_PIN_SEAT_Z;
STOP_PIN_A_ENTRY = 0;      // ear angle (from +x, seen from above) for insertion
STOP_PIN_TURN    = 60;     // locking turn (+ = CCW from above = CW seen from below)
STOP_PIN_A_LOCK  = STOP_PIN_A_ENTRY + STOP_PIN_TURN;
STOP_PIN_RAD_CL  = 0.30;   // radial clearance of disc and ears in the recess
STOP_PIN_LIFT    = 0.30;   // push-up travel that clears the ledge while turning
STOP_PIN_SLOT    = [1.4, 0.8];   // grip slot [width, depth] in the head face
STOP_PIN_Y       = hy(U_STOP);

// Pin in its own frame: head bottom at z = 0, axis on z, ears along +-x.
module stop_pin_body() {
    r  = STOP_D/2;
    rh = STOP_PIN_HUB_D/2;
    re = STOP_PIN_EAR_R;
    hs = STOP_PIN_LEN - STOP_PIN_HUB_H;     // shank length above the disc
    difference() {
        union() {
            rotate_extrude($fn=96) polygon([[0,0],[rh-C_BED,0],[rh,C_BED],[rh,STOP_PIN_HUB_H],[0,STOP_PIN_HUB_H]]);
            intersection() {
                rotate_extrude($fn=96) polygon([[rh-0.6,0],[rh,0],[re,re-rh],[re,STOP_PIN_HUB_H],[rh-0.6,STOP_PIN_HUB_H]]);
                linear_extrude(STOP_PIN_HUB_H) offset(r=0.6, $fn=24) offset(delta=-0.6)
                    square([2*re + 2, STOP_PIN_EAR_W], center=true);
            }
            translate([0,0,STOP_PIN_HUB_H - EPS])
                rotate_extrude($fn=64) polygon([[0,0],[r+0.6,0],[r,0.6],[r,hs-0.6],[r-0.6,hs],[0,hs]]);
        }
        // grip slot across the face, in line with the ears (thumbnail / coin)
        translate([0,0,-EPS]) linear_extrude(STOP_PIN_SLOT[1] + EPS)
            square([STOP_PIN_HUB_D + 1, STOP_PIN_SLOT[0]], center=true);
    }
}

// Assembled: locked and seated.
module stop_pin() {
    translate([0, STOP_PIN_Y, STOP_PIN_SEAT_Z]) rotate(STOP_PIN_A_LOCK) stop_pin_body();
}

// Print: head face down on the textured plate (the 1.4 mm grip slot bridges);
// ear undersides are 45-degree cones; the shank top is the last layer.
module stop_pin_print() {
    stop_pin_body();
}
