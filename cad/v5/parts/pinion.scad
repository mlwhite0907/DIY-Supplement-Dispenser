// parts/pinion.scad: OWNER group DRAWER (unit: drive). Contract: cad/v5/README.md
// Pinion: involute stub-tooth spur gear (lib/gears.scad), hex bore keyed on
// the dial shaft, clamped from below by an M3 x 12 screw + washer against the
// shaft shoulder. Its top face is the THRUST face of the dial stack: the TPU
// detent pushes the dial up and the pinion top bears on the pinion-cavity
// roof underside (PINION_TOP_Z), so the detent preload comes from fixed
// dimensions, never from screw torque.
include <../params.scad>
include <../lib/gears.scad>

// ---- drive constants shared by plunger / dial / pinion / detent -------------
PINION_TOP_Z  = Z_ROD + PIN_FW/2 + 0.5;    // = slide pinion-cavity roof underside (thrust face)
PINION_BOT_Z  = PINION_TOP_Z - PIN_FW;
PINION_RA     = pinion_ra(G_M, G_Z, 0, G_ADD);
PINION_RF     = G_RP - G_M*(G_ADD + G_CK);
PINION_HEX_AF = DIAL_KEY_AF + 2*PINION_BORE_CL;
PINION_CHAMF  = 0.3;                        // tooth-tip chamfer on both faces
function drive_axis() = [0, SLIDE_Y0 - U_DIAL, 0];   // dial/pinion axis (head x,y)

// 2D tooth outline, tooth 0 centred on +x (meshes with the rack at x = +G_CD)
module pinion_profile() {
    pinion_2d(m=G_M, z=G_Z, pa=G_PA, x=0, bl=BACKLASH, ck=G_CK, add=G_ADD, steps=12);
}

// Local pinion: axis on z, z in [0, PIN_FW]. Hex vertex on +x, same as the dial key.
module pinion_local() {
    h = PIN_FW; c = PINION_CHAMF;
    hex_d = PINION_HEX_AF/cos(30);
    difference() {
        intersection() {
            linear_extrude(h, convexity=6) pinion_profile();
            // chamfer the tooth tips on both faces (kills elephant's foot, eases mesh)
            rotate_extrude($fn=96) polygon([[0,0],[PINION_RA - c,0],[PINION_RA + 0.01,c],
                [PINION_RA + 0.01,h - c],[PINION_RA - c,h],[0,h]]);
        }
        // hex bore (6 orientations all keep the tooth phase: 60 deg = 2 teeth)
        translate([0,0,-EPS]) cylinder(d=hex_d, h=h + 2*EPS, $fn=6);
        // lead-in chamfers on the bore
        translate([0,0,-EPS]) cylinder(d1=hex_d + 0.8, d2=hex_d, h=0.4 + EPS, $fn=6);
        translate([0,0,h - 0.4]) cylinder(d1=hex_d, d2=hex_d + 0.8, h=0.4 + EPS, $fn=6);
    }
}

// Assembled: on the dial axis, rotated with the dial.
module pinion() {
    translate(drive_axis()) rotate([0,0,DIAL_ANGLE])
        translate([0,0,PINION_BOT_Z]) pinion_local();
}

// Print: flat, either face on the bed (symmetric). Bed edge = tooth chamfer.
module pinion_print() {
    pinion_local();
}
