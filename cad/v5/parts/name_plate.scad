// parts/name_plate.scad: OWNER group DRAWER (unit: slide). Contract: cad/v5/README.md
// ----------------------------------------------------------------------------
// NAME PLATE (PLA, accent) + NAME INLAY (PLA, ink): the jar's label on the
// drawer front. The plate presses into the slide's front-face recess
// (NAME_PLATE[0] x NAME_PLATE[1] x NAME_PLATE[2], corners R2, 45-degree roof
// chamfer at the back of its top edge). Fit: plate outline 0.1 mm/side under
// the recess + 8 small friction ribs standing 0.2 proud = 0.1 mm interference.
// The text is inlaid 0.6 mm deep, Inter SemiBold, letter-spaced 1.15,
// auto-sized to fit (cap height <= 6 mm), centred.
//
// Plate-local frame: front face on Z = 0, plate body Z in [-t, 0], text reads
// from +Z (X right, Y up).
// PRINT: FACE DOWN (front face on the textured bed: crisp, matte face and text
// edges; the inlay prints in the same pose as a second body/colour).
// ----------------------------------------------------------------------------
include <../params.scad>

NP_W   = NAME_PLATE[0];
NP_H   = NAME_PLATE[1];
NP_T   = NAME_PLATE[2];
NP_R   = 2;                    // plan corner radius
NP_CL  = 0.1;                  // outline clearance per side (ribs give the grip)
NP_RIB = 0.2;                  // rib height above the outline -> 0.1 interference
NP_CH  = 1.0;                  // back-top chamfer, matches the recess roof (slide SLIDE_NP_CH)
NP_INK = 0.6;                  // inlay depth
NP_CAP = min(6, NP_H/2);       // max cap height
NP_MARGIN = 4.5;               // min side margin for the text
// Same placement formulas as slide.scad (SLIDE_U_FRONT, SLIDE_NP_ZC).
NP_U_FRONT = U_HANDLE0 + HANDLE_L;
NP_ZC      = (max(HANDLE_Z0, Z_FLOOR) + Z_SLIDE_TOP)/2;

// Inter SemiBold in OpenSCAD: cap height ~1.01 x size; caps advance
// <= ~1.3 x size per glyph at spacing 1.15 (measured: WHEY 1.16, MMMM 1.35).
function np_text_size(txt) =
    let(n = max(1, len(txt)), s_cap = NP_CAP/1.01, s_fit = (NP_W - 2*NP_MARGIN)/(1.3*n))
    min(s_cap, s_fit);

module np_text_2d(txt) {
    s = np_text_size(txt);
    // vertical centring on the cap height (baseline at -cap/2)
    translate([0, -1.01*s/2]) text(txt, size=s, font=FONT, halign="center", valign="baseline",
                                   spacing=1.15, $fn=48);
}

module np_outline_2d() { rrect([NP_W - 2*NP_CL, NP_H - 2*NP_CL], NP_R - NP_CL, $fn=32); }

module np_rib() {              // friction rib, axis along Z, lead-in at the back
    translate([0,0,-NP_T + 0.2]) cylinder(r1=0.25, r2=0.45, h=0.5, $fn=16);
    translate([0,0,-NP_T + 0.7]) cylinder(r=0.45, h=NP_T - 1.1, $fn=16);
}
module np_ribs() {
    w = NP_W/2 - NP_CL; h = NP_H/2 - NP_CL; d = NP_RIB - 0.45;
    for (x = [-NP_W/3, 0, NP_W/3], s = [-1, 1]) translate([x, s*(h + d), 0]) np_rib();
    for (s = [-1, 1]) translate([s*(w + d), 0, 0]) np_rib();
}

module np_plate_local(txt) {
    difference() {
        union() {
            intersection() {
                translate([0,0,-NP_T]) linear_extrude(NP_T) np_outline_2d();
                // back-top chamfer (fits under the recess roof) + C_BED on the face edge
                hull() {
                    translate([0, 0, -EPS]) linear_extrude(EPS) offset(delta=-C_BED) np_outline_2d();
                    translate([0, 0, -C_BED]) linear_extrude(EPS) np_outline_2d();
                    translate([0, -NP_CH/2, -NP_T]) linear_extrude(EPS)
                        rrect([NP_W - 2*NP_CL, NP_H - 2*NP_CL - NP_CH], NP_R - NP_CL, $fn=32);
                    translate([0, 0, -(NP_T - NP_CH)]) linear_extrude(NP_T - NP_CH - C_BED) np_outline_2d();
                }
            }
            np_ribs();
        }
        translate([0,0,-NP_INK]) linear_extrude(1) np_text_2d(txt);
    }
}
module np_inlay_local(txt) {
    translate([0,0,-NP_INK]) linear_extrude(NP_INK) np_text_2d(txt);
}

// assembled pose: on the drawer front, front face flush with the face
module np_place() {
    translate([0, SLIDE_Y0 - NP_U_FRONT, NP_ZC]) rotate([90,0,0]) children();
}
module name_plate(txt) { np_place() np_plate_local(txt); }
module name_inlay(txt) { np_place() np_inlay_local(txt); }

// print: face down (front face on the bed), same pose for plate and inlay
module name_plate_print(txt) { rotate([180,0,0]) np_plate_local(txt); }
module name_inlay_print(txt) { rotate([180,0,0]) np_inlay_local(txt); }
