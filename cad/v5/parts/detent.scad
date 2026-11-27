// parts/detent.scad: OWNER group DRAWER (unit: drive). Contract: cad/v5/README.md
// DETENT (TPU 95A): a keyed ring in the slide's dial well, in the OUTER band
// between the stop post and the well wall (so the dial's stop tab, which
// sweeps the band at the post radius, never meets it).
//  - 3 pads at DETENT_PADS (120 deg apart = 16 clicks, so all 3 engage at
//    once) press UP into DETENT_TEETH radial V-grooves in the dial underside.
//  - Each pad sits mid-span on a fixed-fixed TPU beam that bridges a shallow
//    gap; the beams are the only springs (no PLA flexure under load).
//  - 2 keys into the well's DIAL_WELL_KEYS notches stop it rotating.
//  - Preload: the TPU lifts the dial until the pinion top meets the cavity
//    roof (PINION_TOP_Z). Pad compression DETENT_PRE is therefore set by fixed
//    dimensions, not by screw torque.
// Torque estimate (E_TPU95A ~ 15-30 MPa, mu TPU/PLA ~ 0.4-0.6):
//   beam k = 16 E b t^3 / L^3 = 1.2-2.3 N/mm per pad (b 3.0, t 1.2, L ~10.5)
//   peak pad deflection = PRE + NOTCH = 0.85 mm -> 1.0-2.0 N per pad, 3-6 N total
//   T = F * tan(flank 28 deg + friction 22-31 deg) * r 15.3 mm
//     ~ 0.06 - 0.15 N*m to click over (target >= 0.05 hold, <= 0.15 turn).
include <../params.scad>

DETENT_R0   = STOP_POST[0] + 0.5 + 0.35;             // inner radius: 0.35 outside the dial's stop tab
DETENT_POST_CLR = STOP_POST[1]/2 + 0.35;             // ring is notched round the stop post
DETENT_R1   = DIAL_WELL_D/2 - 0.15;                  // outer radius (well wall clearance)
DETENT_Z0   = Z_SLIDE_TOP - DIAL_WELL_DEPTH;         // well floor
DETENT_TOP  = Z_SLIDE_TOP;                           // ring top, flush with the drawer top
DETENT_T    = 1.2;                                   // beam thickness (z)
DETENT_GAP  = DETENT_TOP - DETENT_T - DETENT_Z0;     // deflection room under each beam
DETENT_PRE  = 0.35;                                  // pad preload (compression) in use
DETENT_NOTCH_H = 0.5;                                // dial V-groove depth
DETENT_PADS = [0, 120, 240];                         // pad angles about the dial axis (slide frame)
DETENT_SPAN = 10.5;                                  // beam span (arc at the band centre), mm
DETENT_GROOVE_R0 = DETENT_R0 - 0.1;                  // dial groove radial extent
DETENT_GROOVE_R1 = DIAL_D/2 - 0.85;                  // ends inside the flute valleys (hidden)
DETENT_GROOVE_W  = 2*PI*DETENT_GROOVE_R0/DETENT_TEETH;   // = pitch at the inner end
DETENT_PAD_R0 = DETENT_R0 + 0.1;
DETENT_PAD_R1 = DETENT_GROOVE_R1 - 0.15;
DETENT_KEY_R1 = DIAL_WELL_D/2 + DIAL_WELL_KEY[1] - 0.15;
DETENT_KEY_W  = DIAL_WELL_KEY[0] - 0.3;

// Radial V-prism: triangle (base w at z=0, apex height d) in the tangential/z
// plane, extruded radially from r0 to r1 along +x.
module detent_vprism(w, d, r0, r1, tip=0) {
    translate([r0,0,0]) rotate([90,0,90]) linear_extrude(r1 - r0)
        polygon(tip > 0 ? [[-w/2,0],[w/2,0],[tip/2, d*(1 - tip/w)],[-tip/2, d*(1 - tip/w)]]
                        : [[-w/2,0],[w/2,0],[0,d]]);
}

// One pad in the local frame (on +x), free state, from the beam top up.
module detent_pad() {
    wg = DETENT_GROOVE_W; hn = DETENT_NOTCH_H;
    za = Z_DIAL_BOT + hn + DETENT_PRE;          // V apex (free)
    wb = 0.9*wg;                                 // V base width (never touches the next ridge)
    zb = za - hn*wb/wg;                          // where the V reaches its base width
    // V cap, truncated to a 0.3 mm flat tip (printable TPU)
    translate([0,0,zb]) detent_vprism(wb, za - zb, DETENT_PAD_R0, DETENT_PAD_R1, tip=0.3);
    // straight stem from the beam top up to the V base
    translate([DETENT_PAD_R0, -wb/2, DETENT_TOP - EPS])
        cube([DETENT_PAD_R1 - DETENT_PAD_R0, wb, zb - DETENT_TOP + 2*EPS]);
}

// Annular sector (2D)
module detent_sector(r0, r1, a0, a1) {
    n = max(4, ceil(abs(a1 - a0)/2));
    polygon(concat([for (i=[0:n]) polar(r1, a0 + (a1 - a0)*i/n)],
                   [for (i=[n:-1:0]) polar(r0, a0 + (a1 - a0)*i/n)]));
}

// Beam gap under a pad: full span at the floor, 45-deg end walls up to the
// beam underside (so the bridge is shorter and the ends print clean).
module detent_gap(a) {
    rm = (DETENT_R0 + DETENT_R1)/2;
    s  = DETENT_SPAN/rm*180/PI;                  // span, deg
    ds = DETENT_GAP/rm*180/PI;                   // 45-deg end wall, deg
    hull() {
        translate([0,0,DETENT_Z0 - 1]) linear_extrude(1 + EPS)
            detent_sector(DETENT_R0 - 1, DETENT_R1 + 1, a - s/2, a + s/2);
        translate([0,0,DETENT_Z0 + DETENT_GAP - EPS]) linear_extrude(EPS)
            detent_sector(DETENT_R0 - 1, DETENT_R1 + 1, a - s/2 + ds, a + s/2 - ds);
    }
}

// Detent in the dial-axis frame (axis at x=y=0), head z.
module detent_local() {
    h = DETENT_TOP - DETENT_Z0;
    difference() {
        union() {
            translate([0,0,DETENT_Z0]) ctube(2*DETENT_R1, 2*DETENT_R0, h, ct=0.3, cb=0.3, $fn=144);
            // anti-rotation keys into the well notches
            for (a = DIAL_WELL_KEYS) rotate(a)
                translate([DETENT_R1 - 0.4, -DETENT_KEY_W/2, DETENT_Z0])
                    rbox([DETENT_KEY_R1 - DETENT_R1 + 0.4, DETENT_KEY_W, h], r=0.4, ct=0.3, cb=0.3, center=false);
        }
        for (a = DETENT_PADS) detent_gap(a);
        // notch round the stop post
        translate(concat(polar(STOP_POST[0], STOP_TAB_ANGLE), [DETENT_Z0 - 1]))
            cylinder(r=DETENT_POST_CLR, h=10, $fn=48);
    }
    for (a = DETENT_PADS) rotate(a) detent_pad();
}

// Assembled: in the dial well (fixed to the slide; it does not turn).
module detent() {
    translate([0, SLIDE_Y0 - U_DIAL, 0]) detent_local();
}

// Print: upright, flat bottom on the bed (smooth PEI is nicer for TPU).
// The beams bridge DETENT_SPAN - 2*DETENT_GAP (~7 mm); pads print last.
module detent_print() {
    translate([0,0,-DETENT_Z0]) detent_local();
}
