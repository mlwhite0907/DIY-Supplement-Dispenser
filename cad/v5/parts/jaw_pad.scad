// parts/jaw_pad.scad: OWNER group CHUCK. Contract: cad/v5/README.md
// JAW PAD (TPU 95A, x3). A PAD_T thick curved pad on each jaw face. Its rib
// tips form a cylinder of radius NECK_OD/2 when the chuck is at nominal close,
// so the three pads just touch a NECK_OD neck; further twist squeezes the TPU.
// Fine horizontal ribs (0.4 mm) bite into the glass thread. A dovetail key on
// the back slides UP into the jaw's blind slot from below; once the jaw sits
// in its track the guide plate under it captures the pad.
include <../params.scad>
include <jaw.scad>

JP_RIB_D   = 0.4;     // rib height (groove depth)
JP_RIB_P   = 1.2;     // rib pitch: 0.4 flat tip + 45 deg V groove
JP_KEY_CL  = 0.05;    // key clearance per side (snug TPU press fit)
JP_RE      = 1.0;     // plan round on the pad's side ends
JP_CT      = 0.5;     // chamfer on the grip-face top/bottom edges

// Ribbed r-z profile (jaw-local radius, height above the guide-plate top).
module _jp_profile() {
    r_tip = NECK_OD/2;                 // rib tips
    r_bk  = JAW_X_FACE;                // back, against the PLA face
    z0 = JAW_PAD_Z0; z1 = JAW_PAD_TOP;
    zr0 = z0 + JP_CT + 0.3; zr1 = z1 - JP_CT - 0.3;
    n  = floor((zr1 - zr0 - 0.4)/JP_RIB_P);
    zs = zr0 + ((zr1 - zr0) - (n*JP_RIB_P + 0.4))/2;   // centre the rib field
    pts = concat(
        [[r_bk, z0], [r_tip + JP_CT, z0], [r_tip, z0 + JP_CT]],
        [for (k=[0:n-1]) each [
            [r_tip, zs + k*JP_RIB_P],
            [r_tip, zs + k*JP_RIB_P + 0.4],
            [r_tip + JP_RIB_D, zs + k*JP_RIB_P + 0.8]]],
        [[r_tip, zs + n*JP_RIB_P], [r_tip, zs + n*JP_RIB_P + 0.4],
         [r_tip, z1 - JP_CT], [r_tip + JP_CT, z1], [r_bk, z1]]);
    polygon(pts);
}

module _jp_rel() {
    union() {
        intersection() {
            rotate_extrude($fa=0.5, $fs=0.2) _jp_profile();
            translate([0,0,-1]) linear_extrude(JAW_H + 2)
                translate([JAW_X_FACE - PAD_T - 0.5, -JAW_PAD_W/2])
                    rrect([PAD_T + 1.5, JAW_PAD_W], r=JP_RE, center=false);
        }
        // key: from inside the pad body into the jaw slot
        translate([JAW_X_FACE, 0, JAW_PAD_Z0])
            linear_extrude(JAW_KEY_TOP - 0.3 - JAW_PAD_Z0)
                intersection() {
                    _jaw_key_2d(-JP_KEY_CL, -0.6);
                    translate([-1, -5]) square([JAW_KEY_LIP + JAW_KEY[2] - 0.15 + 1, 10]);
                }
    }
}

module jaw_pad(i) { jaw_place(i) _jp_rel(); }

// Print UPRIGHT, standing on its bottom end (ribs are horizontal layers, 45 deg
// flanks need no support). Bed side = the bottom end (hidden on the plate).
module jaw_pad_print() {
    translate([-JAW_X_FACE, 0, -JAW_PAD_Z0]) _jp_rel();
}
