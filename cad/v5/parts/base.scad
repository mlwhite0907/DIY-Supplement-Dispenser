// parts/base.scad: OWNER group BODY. Contract: cad/v5/README.md
// BASE (PLA, body colour): the puck's lower shell. Floor (slide running surface),
// drop hole, channel walls with hook slots, drawer mouth, stop-pin bayonet,
// band posts, join-screw columns, dock holes and the bottom deboss.
// The stop-pin bayonet constants (STOP_PIN_*) live in parts/stop_pin.scad.
include <../params.scad>

BASE_IN_R     = PUCK_R - SKIN_T;          // inner skin radius
BASE_REVEAL_C = 0.5;                      // half of the 1 mm reveal V at the joint
BASE_RELIEF   = 0.4;                      // floor relief outside the sealing zone
BASE_WALL_X0  = CHAN_HW;                  // channel wall inner face |x|
BASE_WALL_X1  = CHAN_HW + RAIL_W;         // channel wall outer face |x|
BASE_MOUTH_HW = CHAN_HW + 0.5;            // drawer mouth half width
BASE_MOUTH_Z0 = Z_FLOOR - 0.5;            // mouth bottom (the deck cuts its top to Z_CEIL + 0.5)
BASE_MOUTH_C  = 0.5;                      // chamfer on the mouth's outer edges
BASE_SEAL_HW  = CH_W/2 + 3;
BASE_SEAL_Y   = [hy(HOLE_U1 + 4), hy(-4)];
BASE_DRIP_C   = 0.8;
BASE_HOOK_Y_REST = T_LEN/2 - U_HOOK_S;    // head y of the slide hooks at rest
BASE_HOOK_Y   = [BASE_HOOK_Y_REST - STROKE - 4, BASE_HOOK_Y_REST + 4];
BASE_HOOK_Z0  = Z_ROD - HOOK_SLOT_H/2;    // slot floor; open above to the joint (see base_hook_slots)
BASE_HOOK_KEYWAYS = false;               // true: hook keyways through the front skin, so the
                                          // drawer can be pulled out past full stroke to unhook
                                          // the bands (cleaning without removing the deck)
BASE_POST_TOP = Z_CEIL - 0.5;
BASE_REAR_POST  = [BAND_X + BAND_POST_D/2, Y_BAND_ANCHOR];
BASE_FRONT_POST = [BAND_X_OUT, Y_BAND_FRONT];
BASE_FRONT_POST_D = 6;
BASE_COL_OD   = 10;                       // join-screw column
BASE_CB       = [6.5, 3.5];               // screw head counterbore [d, depth] from the bottom
// Join screw: M3 x (Z_CEIL - 3.5 + ~11) socket head, i.e. M3x35 (std/template), M3x45 (pro);
// it threads ~11 mm into the deck's 12 mm pilots.
BASE_DOCK_DEPTH = 3;
BASE_DOCK_BOSS  = DOCK_PIN_D + CL_PIN + 3.2;   // 1.6 wall around the dock hole
BASE_RIB_T    = 2.0;
BASE_TXT      = 5;                        // Inter Medium 5 mm
BASE_TXT_D    = 0.6;
// (STOP_PIN_* are assigned later in the include order, so derived values are functions)
function base_pin_land_r() = STOP_PIN_EAR_R + STOP_PIN_RAD_CL + 2.2;   // unrelieved land over the bayonet

// ---------------------------------------------------------------- shell
module base_shell() {
    R = PUCK_R; c = BASE_REVEAL_C;
    rotate_extrude($fn=240) polygon([
        [0,0], [R - C_BED, 0], [R, C_BED], [R, Z_CEIL - c], [R - c, Z_CEIL],
        [BASE_IN_R, Z_CEIL], [BASE_IN_R, FLOOR_T + 1.5], [BASE_IN_R - 1.5, FLOOR_T], [0, FLOOR_T]]);
}

module base_inside_clip(h = Z_CEIL) {
    cylinder(r = BASE_IN_R + 0.2, h = h, $fn=240);
}

// ---------------------------------------------------------------- channel
module base_channel_walls() {
    intersection() {
        base_inside_clip();
        union() {
            for (s=[-1,1]) translate([s > 0 ? BASE_WALL_X0 : -BASE_WALL_X1, -PUCK_R, 0])
                cube([RAIL_W, Y_REAR_WALL + RAIL_W + PUCK_R, Z_CEIL]);
            translate([-BASE_WALL_X1, Y_REAR_WALL, 0]) cube([2*BASE_WALL_X1, RAIL_W + PUCK_R, Z_CEIL]);
        }
    }
}

// ---------------------------------------------------------------- band posts
module base_post(d, lip_max_r) {
    r = d/2; top = BASE_POST_TOP;
    rl = max(r + 0.4, min(r + 1.5, lip_max_r));     // retaining lip
    rotate_extrude($fn=96) polygon([
        [0, 1], [r + 1.2, 1], [r + 1.2, FLOOR_T], [r, FLOOR_T + 1.2],
        [r, top - 1.0 - (rl - r)], [rl, top - 1.0], [rl, top - 0.4], [rl - 0.4, top], [0, top]]);
}
module base_posts() {
    p = BASE_REAR_POST; q = BASE_FRONT_POST;
    for (s=[-1,1]) {
        translate([s*p[0], p[1], 0]) base_post(BAND_POST_D, BASE_IN_R - norm(p) - 0.6);
        translate([s*q[0], q[1], 0]) base_post(BASE_FRONT_POST_D, BASE_IN_R - norm(q) - 0.6);
    }
}

// ---------------------------------------------------------------- columns, bosses, ribs
module base_columns() {
    for (j = JOIN_SCREWS) translate([j[0], j[1], 0]) {
        cylinder(d = BASE_COL_OD, h = Z_CEIL, $fn=64);
        rotate(atan2(j[1], j[0])) translate([0, -BASE_RIB_T/2, 0])
            cube([PUCK_R - norm(j) - 0.5, BASE_RIB_T, Z_CEIL]);       // rib out to the skin
    }
    for (d = DOCK_PINS) translate([d[0], d[1], 0]) {
        cylinder(d = BASE_DOCK_BOSS, h = BASE_DOCK_DEPTH + 1.6, $fn=64);
        translate([0,0,BASE_DOCK_DEPTH + 1.6 - EPS])
            cylinder(d1 = BASE_DOCK_BOSS, d2 = BASE_DOCK_BOSS - 2.4, h = 1.2, $fn=64);
    }
}

module base_solid() {
    base_shell();
    base_channel_walls();
    base_posts();
    intersection() { base_inside_clip(); base_columns(); }
}

// ---------------------------------------------------------------- cuts
module base_drop_hole() {
    y0 = hy(HOLE_U1); y1 = hy(HOLE_U0); c = BASE_DRIP_C;
    translate([0, (y0 + y1)/2, 0]) {
        translate([0,0,-1]) linear_extrude(FLOOR_T + 2) rrect([CH_W, y1 - y0], HOLE_R);
        hull() {                                    // 0.8 drip chamfer on the bottom edge
            translate([0,0,-1]) linear_extrude(1 + EPS) offset(delta = c) rrect([CH_W, y1 - y0], HOLE_R);
            linear_extrude(c) rrect([CH_W, y1 - y0], HOLE_R);
        }
    }
}

module base_relief() {
    translate([0, 0, Z_FLOOR - BASE_RELIEF]) linear_extrude(BASE_RELIEF + 1)
    difference() {
        translate([-CHAN_HW - EPS, -PUCK_R - 1]) square([2*CHAN_HW + 2*EPS, Y_REAR_WALL + PUCK_R + 1 + EPS]);
        translate([-BASE_SEAL_HW, BASE_SEAL_Y[0]]) square([2*BASE_SEAL_HW, BASE_SEAL_Y[1] - BASE_SEAL_Y[0]]);
        translate([0, STOP_PIN_Y]) circle(r = base_pin_land_r(), $fn=64);
    }
}

module base_mouth() {
    w = BASE_MOUTH_HW; z0 = BASE_MOUTH_Z0; c = BASE_MOUTH_C; R = PUCK_R;
    ys = -sqrt(R*R - w*w);                       // outer skin y at the mouth's side
    // the opening, through the skin only
    intersection() {
        translate([-w, -R - 2, z0]) cube([2*w, R, Z_CEIL + 1 - z0]);
        difference() { cylinder(r = R + 1, h = Z_CEIL + 1, $fn=240);
                       translate([0,0,-1]) cylinder(r = BASE_IN_R - 0.01, h = Z_CEIL + 3, $fn=240); }
    }
    // 0.5 chamfer along the curved bottom edge
    intersection() {
        translate([-w, -R - 2, 0]) cube([2*w, R, Z_CEIL]);
        rotate_extrude($fn=240) polygon([[R - c, z0 + EPS], [R + 1, z0 + EPS], [R + 1, z0 - c - 1], [R, z0 - c]]);
    }
    // 0.5 chamfer on the two vertical edges
    t = [-ys/R, w/R];                            // tangent along the skin, toward +x
    for (m=[0,1]) mirror([m, 0, 0]) translate([0, 0, z0 - c]) linear_extrude(Z_CEIL + 1)
        polygon([[w - EPS, ys + c], [w, ys] + c*t + [w, ys]/R*0.6, [w - EPS, ys - 2]]);
}

module base_hook_slots() {
    // Open-topped notch: a ~40 mm horizontal bridge over a closed slot would not
    // print; the deck ceiling closes the top. Notch floor = Z_ROD - HOOK_SLOT_H/2.
    intersection() {
        cylinder(r = BASE_IN_R - 0.01, h = Z_CEIL + 2, $fn=240);
        for (s=[-1,1]) translate([s > 0 ? BASE_WALL_X0 - 0.5 : -BASE_WALL_X1 - 0.01, BASE_HOOK_Y[0], BASE_HOOK_Z0])
            cube([RAIL_W + 0.51, BASE_HOOK_Y[1] - BASE_HOOK_Y[0], Z_CEIL - BASE_HOOK_Z0 + 1]);
    }
    if (BASE_HOOK_KEYWAYS) for (s=[-1,1]) {
        xo = BAND_X + 1.8 + 0.6;
        translate([s > 0 ? BASE_WALL_X0 - 0.5 : -xo, -PUCK_R - 2, BASE_HOOK_Z0])
            cube([xo - BASE_WALL_X0 + 0.5, BASE_HOOK_Y[1] + PUCK_R + 2, HOOK_SLOT_H]);
    }
}

// Stop-pin bayonet recess, in the pin's frame (axis on z, z = 0 = base bottom).
function base_ledge_z(r) = STOP_PIN_SEAT_Z - 0.1 + (r - STOP_PIN_HUB_D/2);   // 0.1 under the seated ear cone
module base_stop_recess() {
    rc = STOP_PIN_HUB_D/2 + STOP_PIN_RAD_CL;
    rp = STOP_PIN_EAR_R + STOP_PIN_RAD_CL;
    ztop = STOP_PIN_SEAT_Z + STOP_PIN_HUB_H + STOP_PIN_LIFT;     // pocket roof
    half = asin((STOP_PIN_EAR_W/2 + STOP_PIN_RAD_CL)/rp) + 3;    // ear half angle + margin
    translate([0,0,-1]) cylinder(d = STOP_D + CL_PIN, h = FLOOR_T + 2, $fn=48);
    translate([0,0,-1]) cylinder(r = rc, h = ztop + 1, $fn=96);
    translate([0,0,-EPS]) cylinder(r1 = rc + C_BED, r2 = rc, h = C_BED, $fn=96);
    translate([0,0,ztop - EPS]) cylinder(r1 = (STOP_D + CL_PIN)/2 + 0.8, r2 = (STOP_D + CL_PIN)/2, h = 0.8, $fn=48);   // clears the pin's root fillet
    for (k=[0,180]) {
        rotate(STOP_PIN_A_ENTRY + k - half) translate([0,0,-1])           // entry notch
            rotate_extrude(angle = 2*half, $fn=96) translate([rc - 0.5, 0]) square([rp - rc + 0.5, ztop + 1]);
        rotate(STOP_PIN_A_ENTRY + k - half)                                // turning pocket
            rotate_extrude(angle = STOP_PIN_TURN + 2*half, $fn=96)
                polygon([[rc - 0.5, base_ledge_z(rc - 0.5)], [rp, base_ledge_z(rp)], [rp, ztop], [rc - 0.5, ztop]]);
    }
}

module base_screws() {
    for (j = JOIN_SCREWS) translate([j[0], j[1], 0]) {
        translate([0,0,-1]) cylinder(d = M3_CLEAR, h = Z_CEIL + 2, $fn=32);
        translate([0,0,-1]) cylinder(d = BASE_CB[0], h = BASE_CB[1] + 1, $fn=48);
        translate([0,0,-EPS]) cylinder(d1 = BASE_CB[0] + 2*C_BED, d2 = BASE_CB[0], h = C_BED, $fn=48);
    }
    for (d = DOCK_PINS) translate([d[0], d[1], 0]) {
        translate([0,0,-1]) cylinder(d = DOCK_PIN_D + CL_PIN, h = BASE_DOCK_DEPTH + 1, $fn=48);
        translate([0,0,-EPS]) cylinder(d1 = DOCK_PIN_D + CL_PIN + 2*C_BED, d2 = DOCK_PIN_D + CL_PIN, h = C_BED, $fn=48);
    }
}

// Bottom deboss, mirrored so it reads with the puck turned over (front toward you).
module base_text() {
    y = (STOP_PIN_Y + base_pin_land_r() + Y_REAR_WALL)/2;
    translate([0, 0, -1]) linear_extrude(BASE_TXT_D + 1) mirror([1,0,0]) {
        translate([0, y + 3.5]) text("DOSE BAR", size = BASE_TXT, font = FONT_MED, halign="center", valign="center", spacing=1.15, $fn=24);
        translate([0, y - 4.5]) text(JAR_NAME, size = BASE_TXT*0.8, font = FONT_MED, halign="center", valign="center", spacing=1.1, $fn=24);
    }
    // two dimples marking the stop-pin entry direction
    for (k=[0,180]) translate([0, STOP_PIN_Y, 0]) rotate(STOP_PIN_A_ENTRY + k)
        translate([STOP_PIN_EAR_R + STOP_PIN_RAD_CL + 1.3, 0, -1]) cylinder(d = 1.2, h = 1.4, $fn=16);
}

// The channel void: keeps the skin's inner fillet (and anything else) out of the
// slide's path; the skin itself is untouched (the slide's rear corners are chamfered).
module base_channel_void() {
    intersection() {
        cylinder(r = BASE_IN_R - 0.01, h = Z_CEIL + 2, $fn=240);
        translate([-CHAN_HW, -PUCK_R - 1, Z_FLOOR - EPS]) cube([2*CHAN_HW, Y_REAR_WALL + PUCK_R + 1, Z_CEIL]);
    }
}

module base_cuts() {
    base_channel_void();
    base_drop_hole();
    base_relief();
    base_mouth();
    base_hook_slots();
    translate([0, STOP_PIN_Y, 0]) base_stop_recess();
    base_screws();
    base_text();
}

module base() {
    difference() { base_solid(); base_cuts(); }
}

// Print UPRIGHT: the bottom face (deboss, dock holes, screw counterbores, pin
// recess) is bed-side on textured PEI; the floor top (slide running surface) is
// a top surface and is ironed. No supports: the counterbore and bayonet roofs are
// short bridges (< 14 mm), hook slots are open-topped, post lips are 45 degrees.
module base_print() {
    base();
}

// v5.1: TPU stop sleeves on M4 screws (see params STOP_*)
module stop_sleeve() {}
module stop_sleeve_print() {}
