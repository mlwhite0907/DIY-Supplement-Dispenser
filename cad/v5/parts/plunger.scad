// parts/plunger.scad: OWNER group DRAWER (unit: drive). Contract: cad/v5/README.md
// Plunger + rack rod, ONE PLA part.
//  - Block: the chamber's movable front wall. Rear face flat, square, crisp.
//    Top flush (0.15 below the slide top) and smooth.
//  - Rod: from the block's front face to u = U_ROD_FRONT0 + CH_L, with
//    involute rack teeth (lib/gears.scad rack_2d) facing -x toward the pinion.
//    Teeth are phased so the rack meshes with the posed pinion at every dial
//    setting: at DIAL_ANGLE = 0 a pinion tooth points at +x, so a rack GAP sits
//    on the pinion axis (u = U_DIAL + CH_L), teeth at +/- p/2.
include <../params.scad>
include <../lib/gears.scad>

PLUNGER_Z0     = Z_FLOOR + 0.15;            // block AND rod bottom: one bed plane
PLUNGER_Z1     = Z_SLIDE_TOP - 0.15;        // block top
PLUNGER_HW     = CH_W/2 - CL_PLUNGER;       // block half width
PLUNGER_FRONT_GAP = 0.5;                    // block front stays 0.5 short of the bulkhead at max
PLUNGER_ROD_Z1 = Z_ROD + ROD_H/2;
PLUNGER_P      = PI*G_M;                    // rack pitch
PLUNGER_HF     = G_M*(G_ADD + G_CK);        // dedendum (tooth root depth)
PLUNGER_TEETH_L = 2*RACK_FWD + L_MAX;       // toothed length, ending at the rod front
PLUNGER_R_REAR = 0.6;                       // rear vertical corners (tolerates tiny slot fillets)
PLUNGER_R_FRONT = 1.5;
PLUNGER_CT     = 0.3;                       // small top chamfer on sides/front (rear stays sharp)

// ---- plan helpers (slide-local plan: x, y_local = -u) ----------------------
module plunger_block_plan(inset=0) {
    u0 = CH_L; u1 = CH_L + PLUNGER_L - PLUNGER_FRONT_GAP;
    hw = PLUNGER_HW - inset;
    hull() for (sx=[-1,1]) {
        translate([sx*(hw - PLUNGER_R_REAR), -(u0 + PLUNGER_R_REAR)])
            circle(r=PLUNGER_R_REAR, $fn=16);
        translate([sx*(hw - PLUNGER_R_FRONT), -(u1 - inset - PLUNGER_R_FRONT)])
            circle(r=PLUNGER_R_FRONT, $fn=24);
    }
}

// Block: side + front edges chamfered (C_BED bottom, PLUNGER_CT top); the
// rear face stays full-size and its edges sharp (it is the chamber wall).
module plunger_block() {
    h = PLUNGER_Z1 - PLUNGER_Z0;
    translate([0,0,PLUNGER_Z0]) hull() {
        linear_extrude(EPS) plunger_block_plan(C_BED);
        translate([0,0,C_BED]) linear_extrude(h - C_BED - PLUNGER_CT) plunger_block_plan(0);
        translate([0,0,h - EPS]) linear_extrude(EPS) plunger_block_plan(PLUNGER_CT);
    }
    // square, crisp rear face: a full-height 1 mm slab at the rear
    translate([0,0,PLUNGER_Z0]) linear_extrude(h) intersection() {
        plunger_block_plan(0);
        translate([-PLUNGER_HW, -(CH_L + 1)]) square([2*PLUNGER_HW, 1]);
    }
}

// Rack teeth in plan (x, y_local), clipped to the toothed zone.
module plunger_teeth_plan() {
    front = U_ROD_FRONT0 + CH_L;
    zone0 = front - PLUNGER_TEETH_L;
    c0 = U_DIAL + CH_L + PLUNGER_P/2;               // a tooth centre (gap on the pinion axis)
    k0 = ceil((zone0 - c0)/PLUNGER_P);
    k1 = floor((front - c0)/PLUNGER_P + 0.25);
    u_first = c0 + k0*PLUNGER_P;
    n = k1 - k0 + 1;
    intersection() {
        translate([X_RACK_PITCH, -u_first]) mirror([1,0]) rotate(-90)
            rack_2d(m=G_M, n=n, pa=G_PA, bl=BACKLASH, ck=G_CK, add=G_ADD, back=RACK_BACK);
        translate([ROD_X0 - 1, -front]) square([ROD_X1 - ROD_X0 + 2, PLUNGER_TEETH_L]);
    }
}

// Rod plan: back strip (root line -> ROD_X1) along its whole length, full
// section (tips -> back) behind the toothed zone, teeth in the toothed zone.
module plunger_rod_plan() {
    front = U_ROD_FRONT0 + CH_L;
    zone0 = front - PLUNGER_TEETH_L;
    rear  = CH_L + PLUNGER_L - PLUNGER_FRONT_GAP - 1;   // 1 mm into the block
    xr = X_RACK_PITCH + PLUNGER_HF;                     // tooth root line
    union() {
        translate([xr, -front]) square([ROD_X1 - xr, front - rear]);
        translate([ROD_X0, -zone0]) square([ROD_X1 - ROD_X0, zone0 - rear]);
        plunger_teeth_plan();
    }
}

module plunger_rod() {
    h = PLUNGER_ROD_Z1 - PLUNGER_Z0;
    front = U_ROD_FRONT0 + CH_L;
    difference() {
        translate([0,0,PLUNGER_Z0]) linear_extrude(h, convexity=8) plunger_rod_plan();
        // 0.6 chamfers round the rod's front end so it enters the tunnel cleanly
        for (zz=[PLUNGER_Z0, PLUNGER_ROD_Z1]) translate([(ROD_X0 + ROD_X1)/2, -front, zz])
            rotate([45,0,0]) cube([ROD_X1 - ROD_X0 + 2, 0.85, 0.85], center=true);
        // C_BED on the rod's back bottom edge
        translate([ROD_X1, -front/2, PLUNGER_Z0]) rotate([0,45,0])
            cube([C_BED*1.414, front + 2, C_BED*1.414], center=true);
    }
}

// Plunger in slide-local coordinates.
module plunger_local() {
    union() { plunger_block(); plunger_rod(); }
}

// Assembled pose: rides on the slide; honors CH_L (DIAL_ML) and STATE_PULL.
module plunger() {
    translate([0, SLIDE_Y0, 0]) plunger_local();
}

// Print: UPRIGHT, as assembled. Bed side = the underside (block + rod on one
// plane, rack teeth are vertical extrusions: crisp involutes, no supports).
// Top side = the block top, flush with the slide top: iron it.
module plunger_print() {
    u_mid = (2*CH_L + U_ROD_FRONT0)/2;
    translate([0, u_mid, -PLUNGER_Z0]) plunger_local();
}
