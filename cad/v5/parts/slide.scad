// parts/slide.scad: OWNER group DRAWER (unit: slide). Contract: cad/v5/README.md
// ----------------------------------------------------------------------------
// SLIDE: the drawer. PLA, body colour. One piece: rear seal section, chamber +
// plunger slot, bulkhead, neck, and the drawer front ("tongue") with the dial
// seat, the pinion cavity, the index mark, the finger pull and the name-plate
// recess.
//
// Slide-local frame (README 1): origin on the chamber's fixed rear wall,
// slide-local u = -y. Everything is modelled in that frame by slide_local()
// and placed with translate([0, SLIDE_Y0, 0]).
//
// PRINT: UPRIGHT. The bottom (running face on the base floor) is on the bed
// (textured PEI, C_BED chamfers on every bed edge, also inside the chamber slot,
// the rod tunnel and the stop groove); the top (sealing face under the ceiling,
// the "live bottom" of the powder) is the last layer and is IRONED. Every
// downward opening (chamber slot, rod tunnel, pinion cavity, stop groove) is
// open at the bottom, so nothing needs support. Bridges: rod tunnel 6.2 mm,
// stop groove 5.6 mm, pinion cavity roof 2*PINION_CAVITY_R (15.3 mm std).
// Band hooks have 45-degree undersides; the name-plate recess a 45-degree roof.
//
// Design notes / deviations (see the unit report):
//  * Drawer-front bottom = Z_FLOOR (HANDLE_Z0 = 0.8 is below the running face
//    and could not print upright without supports). SLIDE_Z0 follows HANDLE_Z0
//    automatically if it is ever raised to >= Z_FLOOR.
//  * Finger pull = a soft capsule groove in the drawer-front TOP, in front of
//    the index mark: the rack-rod tunnel fills the lower drawer front to 2 mm
//    behind the front face, so a lower-front scoop would open into it.
//  * Front plan corners SLIDE_FRONT_R (4 mm std): the name plate
//    (NAME_PLATE[0] = HANDLE_W - 10) needs a flat front that wide.
//  * Band hooks at U_HOOK_S (the base cuts its wall slots there). The params
//    formula only checks x = 0, so at full pull the hooks reach the puck skin;
//    SLIDE_HOOK_U_SAFE is the largest u that clears it (params request).
//  * The drawer front's rear face is concave and follows the puck skin at
//    REVEAL_H, so the shadow gap is uniform across the full width.
// ----------------------------------------------------------------------------
include <../params.scad>

// ---------- private constants ------------------------------------------------
SLIDE_Z0      = max(HANDLE_Z0, Z_FLOOR);           // bottom of the whole slide
SLIDE_H       = Z_SLIDE_TOP - SLIDE_Z0;
SLIDE_U_FRONT = U_HANDLE0 + HANDLE_L;               // drawer front face (slide-local u)
SLIDE_FRONT_R = max(R_V, min(12, (HANDLE_W - NAME_PLATE[0])/2 - 1));
SLIDE_REAR_FACE_R = PUCK_R + REVEAL_H;              // concave drawer-front rear face

// rack-rod tunnel (open at the bottom) and bulkhead notch
SLIDE_TUN_X0 = ROD_X0 - ROD_CL;
SLIDE_TUN_X1 = ROD_X1 + ROD_CL;
SLIDE_TUN_Z1 = Z_ROD + ROD_H/2 + ROD_CL;
SLIDE_TUN_U1 = U_ROD_FRONT0 + L_MAX + 1;
SLIDE_PIN_Z1 = Z_ROD + PIN_FW/2 + 0.5;              // pinion cavity roof
SLIDE_SHAFT_D = DIAL_SHAFT_D + 0.4;

// band hooks: arm through the base's wall slot, eye zone, lip at the tip
SLIDE_HOOK_HH    = (HOOK_SLOT_H - 1.5)/2;           // half height inside the wall slot
SLIDE_HOOK_W     = 4.4;                             // arm width along y
SLIDE_HOOK_XT    = BAND_X + 1.8;                    // tip |x|
SLIDE_HOOK_XW    = CHAN_HW + RAIL_W + 0.5;          // first |x| clear of the channel wall
SLIDE_HOOK_REACH = 4.6;                             // half y-extent incl. band eyelet
SLIDE_HOOK_U_SAFE = T_LEN/2 - STROKE
    + sqrt(pow(PUCK_R - SKIN_T - 1.5, 2) - pow(SLIDE_HOOK_XT, 2)) - SLIDE_HOOK_REACH;
SLIDE_HOOK_U  = U_HOOK_S;    // the base's wall slots are cut for U_HOOK_S
if (U_HOOK_S > SLIDE_HOOK_U_SAFE + 0.01)
    echo(str("[slide] WARNING: hooks at U_HOOK_S = ", U_HOOK_S, " reach the puck skin at full pull; ",
             "U_HOOK_S <= ", SLIDE_HOOK_U_SAFE, " is needed (params request)."));
SLIDE_HOOK_ZB = Z_ROD - SLIDE_HOOK_HH;
SLIDE_HOOK_ZT = Z_ROD + SLIDE_HOOK_HH;
SLIDE_EYE_ZU  = SLIDE_HOOK_ZB + (BAND_X - SLIDE_W/2);    // arm underside at |x| = BAND_X
SLIDE_EYE_TOP = SLIDE_EYE_ZU + 2.6;                      // arm top in the eye zone
SLIDE_LIP_TOP = SLIDE_EYE_TOP + 2.0;                     // retaining lip
SLIDE_EYE_ZC  = SLIDE_EYE_ZU + 1.3;                      // band eyelet centre height

// drawer-front top: index triangle + finger groove
SLIDE_TRI_U0  = U_DIAL + DIAL_WELL_D/2 + DIAL_WELL_KEY[1] + 1.0;   // tip (points at the dial)
SLIDE_TRI_L   = 3.2;
SLIDE_TRI_W   = 4.0;
SLIDE_GR_U0   = SLIDE_TRI_U0 + SLIDE_TRI_L + 1.6;       // groove rear edge
SLIDE_GR_HW   = min(6.7, (SLIDE_U_FRONT - 2.4 - SLIDE_GR_U0)/2);
SLIDE_GR_D    = min(5.0, Z_SLIDE_TOP - (SLIDE_TUN_Z1 + 1.6));
SLIDE_GR_R    = (SLIDE_GR_HW*SLIDE_GR_HW + SLIDE_GR_D*SLIDE_GR_D)/(2*SLIDE_GR_D);
SLIDE_GR_UC   = SLIDE_GR_U0 + SLIDE_GR_HW;
SLIDE_GR_LEN  = min(44, HANDLE_W - 2*SLIDE_FRONT_R - 12);  // along x, end to end

// name-plate recess (front face)
SLIDE_NP_ZC   = (SLIDE_Z0 + Z_SLIDE_TOP)/2;
SLIDE_NP_CH   = 1.0;                                   // 45-degree roof chamfer

function slide_hook_y(pull=PULL_D) = T_LEN/2 - pull - SLIDE_HOOK_U;   // head y of the hooks

// ---------- helpers -------------------------------------------------------------
// Extrude a 2D outline with bed and top chamfers, stepped at the 0.2 mm layer
// pitch (works for any non-convex outline, no minkowski).
module slide_cham_extrude(h, cb=C_BED, ct=C_TOP, step=0.2) {
    nb = round(cb/step); nt = round(ct/step);
    for (k=[0:nb-1]) translate([0,0,k*step])
        linear_extrude(step + EPS) offset(delta=-(cb - (k + 0.5)*step)) children();
    translate([0,0,cb]) linear_extrude(h - cb - ct + EPS) children();
    for (k=[0:nt-1]) translate([0,0,h - ct + k*step])
        linear_extrude(step + (k < nt-1 ? EPS : 0)) offset(delta=-(k + 0.5)*step) children();
}

// Upward cutter of a 2D outline from below z0 to z1, flared C_BED at z0.
module slide_cut_up(z0, z1, flare=C_BED) {
    translate([0,0,z0 - 1]) linear_extrude(z1 - z0 + 1) children();
    hull() {
        translate([0,0,z0 - 1]) linear_extrude(1 + EPS) offset(delta=flare) children();
        translate([0,0,z0 + flare]) linear_extrude(EPS) children();
    }
}
// Downward cutter from above the top to z0, chamfered c at the top edge.
module slide_cut_down(z0, c=0.4) {
    translate([0,0,z0]) linear_extrude(Z_SLIDE_TOP - z0 + 1) children();
    hull() {
        translate([0,0,Z_SLIDE_TOP - c]) linear_extrude(EPS) children();
        translate([0,0,Z_SLIDE_TOP]) linear_extrude(1) offset(delta=c + EPS) children();
    }
}

// ---------- plan outline ----------------------------------------------------------
module slide_body_2d() {
    c = SLIDE_REAR_CHAMFER; w = SLIDE_W/2;
    polygon([[-w, -(U_HANDLE0 + 2)], [w, -(U_HANDLE0 + 2)], [w, REAR_L - c],
             [w - c, REAR_L], [-w + c, REAR_L], [-w, REAR_L - c]]);
}
module slide_handle_2d() {
    u0 = U_HANDLE0 - 24;
    difference() {
        translate([0, -(SLIDE_U_FRONT + u0)/2]) rrect([HANDLE_W, SLIDE_U_FRONT - u0], SLIDE_FRONT_R);
        translate([0, -T_LEN/2]) circle(r=SLIDE_REAR_FACE_R, $fn=360);
    }
}
module slide_plan_2d() {
    offset(r=R_V, $fn=32) offset(delta=-R_V) union() { slide_body_2d(); slide_handle_2d(); }
}

// ---------- band hook (one side, +x) ----------------------------------------------
module slide_hook_section_2d() {
    x0 = SLIDE_W/2;
    polygon([[x0 - 1.5, SLIDE_HOOK_ZB], [x0, SLIDE_HOOK_ZB],
             [SLIDE_HOOK_XT, SLIDE_HOOK_ZB + (SLIDE_HOOK_XT - x0)],      // 45-degree underside
             [SLIDE_HOOK_XT, SLIDE_LIP_TOP], [SLIDE_HOOK_XT - 1.0, SLIDE_LIP_TOP],
             [SLIDE_HOOK_XT - 1.0, SLIDE_EYE_TOP], [SLIDE_HOOK_XW, SLIDE_EYE_TOP],
             [SLIDE_HOOK_XW, SLIDE_HOOK_ZT], [x0 - 1.5, SLIDE_HOOK_ZT]]);
}
module slide_hook_one() {
    x0 = SLIDE_W/2 - 1.5;
    intersection() {
        rotate([90,0,0]) linear_extrude(SLIDE_HOOK_W, center=true) slide_hook_section_2d();
        translate([0,0,SLIDE_HOOK_ZB - 1]) linear_extrude(SLIDE_LIP_TOP - SLIDE_HOOK_ZB + 2)
            translate([(x0 + SLIDE_HOOK_XT)/2 - 1, 0])
                rrect([SLIDE_HOOK_XT - x0 + 2, SLIDE_HOOK_W], 1.2, $fn=24);
    }
}
module slide_hooks() {
    translate([0, -SLIDE_HOOK_U, 0]) { slide_hook_one(); mirror([1,0,0]) slide_hook_one(); }
}

// ---------- cutters (slide-local) ---------------------------------------------------
module slide_chamber_cut() {          // chamber + plunger slot, open top and bottom
    slide_cut_up(SLIDE_Z0, Z_SLIDE_TOP + 1)
        translate([-CH_W/2, -SLOT_L]) square([CH_W, SLOT_L]);
}
module slide_rod_cut() {              // bulkhead notch + rod tunnel, open at the bottom
    slide_cut_up(SLIDE_Z0, SLIDE_TUN_Z1)
        translate([SLIDE_TUN_X0, -SLIDE_TUN_U1]) square([SLIDE_TUN_X1 - SLIDE_TUN_X0, SLIDE_TUN_U1 - SLOT_L + 1]);
}
module slide_dial_seat_cut() {
    translate([0, -U_DIAL, 0]) {
        // pinion cavity, open to the drawer-front bottom (pinion + M3 screw go in from below)
        slide_cut_up(SLIDE_Z0, SLIDE_PIN_Z1) circle(r=PINION_CAVITY_R, $fn=96);
        // dial shaft hole
        translate([0,0,SLIDE_PIN_Z1 - 1]) cylinder(d=SLIDE_SHAFT_D, h=Z_SLIDE_TOP - SLIDE_PIN_Z1 + 2, $fn=64);
        // dial well (+ two anti-rotation key notches for the detent), chamfered rim
        slide_cut_down(Z_SLIDE_TOP - DIAL_WELL_DEPTH, 0.4) {
            circle(d=DIAL_WELL_D, $fn=128);
            for (a = DIAL_WELL_KEYS) rotate(a)
                translate([DIAL_WELL_D/2 - 0.5, -DIAL_WELL_KEY[0]/2]) square([DIAL_WELL_KEY[1] + 0.5, DIAL_WELL_KEY[0]]);
        }
    }
}
module slide_stop_post() {            // dial hard stop, standing on the well floor
    zf = Z_SLIDE_TOP - DIAL_WELL_DEPTH;
    translate([0, -U_DIAL, 0]) translate(concat(polar(STOP_POST[0], STOP_TAB_ANGLE), [zf - EPS]))
        rotate_extrude($fn=32) polygon([[0,0], [STOP_POST[1]/2, 0], [STOP_POST[1]/2, STOP_POST[2] + EPS - 0.3],
                                        [STOP_POST[1]/2 - 0.3, STOP_POST[2] + EPS], [0, STOP_POST[2] + EPS]]);
}
module slide_post_socket_cut() {      // stir-post socket
    translate([0, -POST_U0, 0]) slide_cut_down(Z_SLIDE_TOP - POST_SOCKET_DEPTH, 0.4)
        square(POST_SOCKET, center=true);
}
module slide_stop_groove_cut() {      // underside groove; its ends are the rest and full-pull stops
    r = (STOP_D + 0.6)/2;
    slide_cut_up(SLIDE_Z0, SLIDE_Z0 + 4) hull() {
        translate([0, -(STOP_GROOVE[0] + r)]) circle(r=r, $fn=48);
        translate([0, -(STOP_GROOVE[1] - r)]) circle(r=r, $fn=48);
    }
}
module slide_index_cut() {            // engraved index triangle, points at the dial
    translate([0, 0, Z_SLIDE_TOP - 0.6]) linear_extrude(1)
        polygon([[0, -SLIDE_TRI_U0], [SLIDE_TRI_W/2, -(SLIDE_TRI_U0 + SLIDE_TRI_L)],
                 [-SLIDE_TRI_W/2, -(SLIDE_TRI_U0 + SLIDE_TRI_L)]]);
}
module slide_grip_cut() {             // finger groove (capsule) in the drawer-front top
    zc = Z_SLIDE_TOP - SLIDE_GR_D + SLIDE_GR_R;
    e  = SLIDE_GR_LEN/2 - SLIDE_GR_HW;
    hull() for (s=[-1,1]) translate([s*e, -SLIDE_GR_UC, zc]) sphere(r=SLIDE_GR_R, $fn=72);
}
module slide_name_pocket_cut() {      // name-plate recess, 45-degree roof (prints without support)
    w = NAME_PLATE[0]; h = NAME_PLATE[1]; t = NAME_PLATE[2]; c = SLIDE_NP_CH;
    translate([0, -SLIDE_U_FRONT, SLIDE_NP_ZC]) rotate([90,0,0]) mirror([0,0,1]) hull() {
        translate([0,0,-1]) linear_extrude(1 + t - c) rrect([w, h], 2, $fn=24);
        translate([0,-c/2,0]) linear_extrude(t) rrect([w, h - c], 2, $fn=24);
    }
    // The tunnel ends 0.4 mm behind the recess floor: merge the two rather than
    // leave a sliver wall; the plate's back closes the tunnel (rod clears it).
    if (SLIDE_U_FRONT - t - SLIDE_TUN_U1 < 1.2)
        translate([SLIDE_TUN_X0, -(SLIDE_U_FRONT - t + EPS), max(SLIDE_Z0 - 1, SLIDE_NP_ZC - h/2 + c)])
            cube([SLIDE_TUN_X1 - SLIDE_TUN_X0, SLIDE_U_FRONT - t - SLIDE_TUN_U1 + 2*EPS + 1,
                  min(SLIDE_TUN_Z1, SLIDE_NP_ZC + h/2 - c) - max(SLIDE_Z0 - 1, SLIDE_NP_ZC - h/2 + c)]);
}

// ---------- the slide ---------------------------------------------------------------
module slide_local() {
    union() {
        difference() {
            union() {
                translate([0,0,SLIDE_Z0]) slide_cham_extrude(SLIDE_H) slide_plan_2d();
                slide_hooks();
            }
            slide_chamber_cut();
            slide_rod_cut();
            slide_dial_seat_cut();
            slide_post_socket_cut();
            slide_stop_groove_cut();
            slide_index_cut();
            slide_grip_cut();
            slide_name_pocket_cut();
        }
        slide_stop_post();
    }
}

module slide() { translate([0, SLIDE_Y0, 0]) slide_local(); }

// Print: upright, running face (bottom) on the textured bed, top ironed.
module slide_print() {
    translate([0, (SLIDE_U_FRONT - REAR_L)/2, -SLIDE_Z0]) slide_local();
}

// v5.1: drawer front printed separately (see params SLIDE_SPLIT_U)
module drawer_front() {}
module drawer_front_print() {}
