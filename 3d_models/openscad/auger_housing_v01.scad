// ============================================================================
// auger_housing_v01.scad – Phase 1 auger barrel + NEMA17 mount + outlet
// DIY Supplement Dispenser
//
// Features:
//   - Horizontal barrel: ID 18 mm, active length 70 mm
//   - NEMA17 rear plate (42 mm face, 31 mm hole spacing, pilot recess)
//   - Top inlet: counterbore for hopper spigot + 4× M3 on 34 mm BCD
//   - Downward outlet nozzle ~16 mm ID near free end
//   - Coin vibration motor pocket on side wall near inlet
//   - Wire exit channel for vibe motor leads
//
// Coordinate frame:
//   - Barrel axis = +X (motor at x=0, free end at x=barrel_len)
//   - Inlet opens +Z
//   - Outlet nozzle points −Z
//
// Interface hopper ↔ housing:
//   Hopper spigot OD (≈26.4) seats in inlet counterbore.
//   Hopper bottom flange bolts to housing inlet flange (4× M3, BCD 34).
//
// Print: motor-face on bed or barrel side-down; bore may need light ream.
// ============================================================================

include <lib/constants.scad>
use <lib/nema17.scad>

// ----- Parameters -----
barrel_id        = BARREL_ID;      // 18
barrel_od        = BARREL_OD;      // ~22.4
barrel_len       = BARREL_LENGTH;  // 70
wall             = WALL_T;
inlet_id         = INLET_ID;       // 22
inlet_bore_h     = INLET_BORE_H;   // 12
outlet_id        = OUTLET_ID;      // 16
outlet_l         = OUTLET_L;       // 12
outlet_wall      = OUTLET_WALL;
inlet_flange_od  = HOPPER_BOT_FLANGE_OD; // 42
inlet_flange_t   = 4.0;
inlet_bcd        = HOPPER_BOT_BOLT_CIRCLE; // 34
spigot_clear_d   = HOPPER_SPIGOT_OD + CLEARANCE_LOOSE; // ~26.8
spigot_seat_h    = HOPPER_SPIGOT_H + 0.5;
outlet_x         = barrel_len - 14;
vibe_d           = VIBE_MOTOR_D + 0.4;
vibe_h           = VIBE_MOTOR_H + 0.3;
bushing_id       = AUGER_ROOT_D + 0.8;
bushing_depth    = 4;
plate_t          = NEMA17_PLATE_T;
endcap_t         = 5;
inlet_x          = 22;
inlet_throat_od  = max(spigot_clear_d + 2*wall, inlet_id + 2*wall + 2);

$fn = 64;

// ---------------------------------------------------------------------------
// Solid body only (no bores) — single union for clean manifold
// ---------------------------------------------------------------------------
module housing_body() {
    // Barrel tube outer
    rotate([0, 90, 0])
        cylinder(d = barrel_od, h = barrel_len);

    // Inlet throat + flange (merged into barrel OD)
    hull() {
        // blend foot on barrel
        translate([inlet_x, 0, 0])
            rotate([0, 90, 0])
                cylinder(d = barrel_od, h = 0.1, center = true);
        translate([inlet_x, 0, barrel_od/2])
            cylinder(d = inlet_throat_od, h = 0.1);
    }
    translate([inlet_x, 0, barrel_od/2])
        cylinder(d = inlet_throat_od, h = inlet_bore_h);
    translate([inlet_x, 0, barrel_od/2 + inlet_bore_h])
        cylinder(d = inlet_flange_od, h = inlet_flange_t);

    // Outlet nozzle boss (hull into barrel)
    hull() {
        translate([outlet_x, 0, 0])
            sphere(d = barrel_od * 0.9, $fn = 36);
        translate([outlet_x, 0, -barrel_od/2 - outlet_l + 0.5])
            cylinder(d = outlet_id + 2*outlet_wall, h = 0.5);
    }
    translate([outlet_x, 0, -barrel_od/2 - outlet_l])
        cylinder(d = outlet_id + 2*outlet_wall, h = outlet_l + 0.1);

    // NEMA17 plate — solid block (holes cut later)
    // Plate occupies x = -plate_t .. 0, centred on barrel axis
    translate([-plate_t, -NEMA17_FACE/2, -NEMA17_FACE/2])
        cube([plate_t, NEMA17_FACE, NEMA17_FACE]);
    // Fillet blend plate → barrel
    hull() {
        translate([-0.1, 0, 0])
            rotate([0, 90, 0])
                cylinder(d = barrel_od, h = 0.1);
        translate([-0.1, -NEMA17_FACE/2 + 2, -NEMA17_FACE/2 + 2])
            cube([0.1, NEMA17_FACE - 4, NEMA17_FACE - 4]);
    }

    // Front endcap solid
    translate([barrel_len, 0, 0])
        rotate([0, 90, 0])
            cylinder(d = barrel_od + 2, h = endcap_t);

    // Vibe motor pad on +Y side
    translate([inlet_x - vibe_d/2 - 1, barrel_od/2 - 2, -vibe_d/2 - 1])
        cube([vibe_d + 2, 4, vibe_d + 2]);
}

// ---------------------------------------------------------------------------
// All cavities as one module
// ---------------------------------------------------------------------------
module housing_cavities() {
    // Main barrel bore (through into plate and endcap slightly)
    translate([-plate_t - 0.2, 0, 0])
        rotate([0, 90, 0])
            cylinder(d = barrel_id, h = barrel_len + plate_t + endcap_t + 0.5);

    // Shaft / coupler clearance (larger near motor)
    translate([0.05, 0, 0])
        rotate([0, -90, 0])
            cylinder(d = NEMA17_SHAFT_CLEAR, h = plate_t + 0.3, $fn = 36);

    // Pilot recess on motor face (outer face of plate at x = -plate_t)
    translate([-plate_t + 2.0, 0, 0])
        rotate([0, -90, 0])
            cylinder(d = NEMA17_PILOT_D, h = 2.2, $fn = 48);

    // NEMA17 M3 holes
    translate([0.05, 0, 0])
        rotate([0, -90, 0])
            translate([0, 0, -0.1])
                nema17_holes(h = plate_t + 0.4);

    // Inlet throat
    translate([inlet_x, 0, -0.5])
        cylinder(d = inlet_id, h = barrel_od/2 + inlet_bore_h + inlet_flange_t + 1);

    // Spigot counterbore (from top of flange downward)
    translate([inlet_x, 0, barrel_od/2 + inlet_bore_h + inlet_flange_t - spigot_seat_h])
        cylinder(d = spigot_clear_d, h = spigot_seat_h + 0.2);

    // Inlet flange M3 holes
    r = inlet_bcd / 2;
    for (a = [0, 90, 180, 270])
        translate([inlet_x + r*cos(a), r*sin(a), barrel_od/2 + inlet_bore_h - 0.1])
            cylinder(d = HOPPER_M3_D, h = inlet_flange_t + 0.4, $fn = 20);

    // Outlet bore
    translate([outlet_x, 0, -barrel_od/2 - outlet_l - 0.2])
        cylinder(d = outlet_id, h = outlet_l + barrel_od/2 + barrel_id/2 + 1);

    // Front bushing (smaller bore in endcap, not full barrel ID)
    // Re-close endcap except bushing + vent: cut less aggressively at end
    // (barrel bore already goes through; add only a note — endcap uses bushing
    //  by leaving a step: we subtract a ring filler? Simpler: leave full bore
    //  and add a separate bushing ring as optional. For v01 full through-bore
    //  is OK for free-spinning tip.)

    // Vibe pocket
    translate([inlet_x, barrel_od/2 - 0.5, 0])
        rotate([-90, 0, 0])
            cylinder(d = vibe_d, h = vibe_h + 2, $fn = 36);

    // Wire channel toward motor
    translate([6, barrel_od/2 - 0.5, -VIBE_WIRE_W/2])
        cube([inlet_x - 4, 3, VIBE_WIRE_W]);
}

// ---------------------------------------------------------------------------
module auger_housing() {
    difference() {
        housing_body();
        housing_cavities();
    }
}

auger_housing();

echo("housing barrel ID/OD/L =", barrel_id, barrel_od, barrel_len);
echo("inlet at x =", inlet_x, " spigot counterbore D =", spigot_clear_d);
echo("outlet at x =", outlet_x, " ID =", outlet_id);
echo("hopper mate: 4x M3 BCD", inlet_bcd);
