// parts/gasket.scad: OWNER group CHUCK. Contract: cad/v5/README.md
// GASKET (TPU 95A). Flat annulus GASKET_ID..GASKET_OD, GASKET_T thick, set in
// the guide-plate pocket and standing GASKET_PROUD proud. A soft half-round
// sealing bead on top, under the jar rim, compresses first and seals the mouth
// against fines. Bottom at Z_GP_TOP - (GASKET_T - GASKET_PROUD); top at Z_RIM.
include <../params.scad>

GASKET_BEAD_H = 0.5;                       // bead height above the gasket top
GASKET_BEAD_W = 1.8;                       // bead base width
GASKET_BEAD_R = (GASKET_ID + GASKET_OD)/4; // bead centre radius (mid rim land)
GASKET_CE     = 0.4;                       // edge chamfers (bed side = C_BED)

module _gasket_profile() {
    ri = GASKET_ID/2; ro = GASKET_OD/2; t = GASKET_T; c = GASKET_CE;
    n = 10;
    union() {
        polygon([[ri + c, 0], [ro - c, 0], [ro, c], [ro, t - 0.3], [ro - 0.3, t],
                 [ri + 0.3, t], [ri, t - 0.3], [ri, c]]);
        // half-round bead: elliptical arc, base width GASKET_BEAD_W, height GASKET_BEAD_H
        polygon(concat(
            [[GASKET_BEAD_R - GASKET_BEAD_W/2, t - EPS]],
            [for (k=[0:n]) let(a = 180 - 180*k/n)
                [GASKET_BEAD_R + GASKET_BEAD_W/2*cos(a), t + GASKET_BEAD_H*sin(a)]],
            [[GASKET_BEAD_R + GASKET_BEAD_W/2, t - EPS]]));
    }
}

module _gasket_rel() { rotate_extrude($fa=1, $fs=0.5) _gasket_profile(); }

module gasket() { translate([0, 0, Z_GP_TOP - (GASKET_T - GASKET_PROUD)]) _gasket_rel(); }

// Print FLAT, bead up. The flat bed-side face sits in the pocket; the bead is
// the last-printed top (smooth). TPU 95A, 100% infill, slow (25 mm/s).
module gasket_print() { _gasket_rel(); }
