// ============================================================================
// test_stand_v01.scad – Phase 1 bench stand for powder module
// DIY Supplement Dispenser
//
// Purpose: raise the auger housing outlet ~55 mm above the table so a
// collection cup sitting on the scale_platform / load cell can slide under.
//
// Layout:
//   - Base plate with rubber-foot recesses
//   - Two upright posts with cradle cutouts that accept the barrel OD
//   - Open front so the cup + scale platform slide under the outlet
//   - Optional M3 holes to pin the housing if needed later
//
// Print: flat on base, no supports if cradle angles stay ≤45°.
// ============================================================================

include <lib/constants.scad>

// ----- Parameters -----
barrel_od     = BARREL_OD;                 // ~22.4
outlet_clear  = STAND_OUTLET_CLEARANCE;    // 55 — air under outlet
post_w        = STAND_POST_W;              // 12
base_t        = STAND_FOOT_T;              // 4
// Cradle: holds barrel centre at height so outlet tip is outlet_clear above table
// Housing outlet extends outlet_l below barrel centreline (−Z of housing).
// Barrel centre height above table:
barrel_axis_z = outlet_clear + OUTLET_L + barrel_od/2;
// Stand overall
base_x        = 110;   // depth (along barrel)
base_y        = 80;    // width
// Post positions (along X, cradle centres)
post1_x       = 22;    // near motor / inlet
post2_x       = 85;    // near outlet end
// Cradle half-depth
cradle_depth  = 10;
wall          = 3.0;
foot_d        = 12;
foot_recess_h = 1.2;

$fn = 48;

// ---------------------------------------------------------------------------
// Base plate
// ---------------------------------------------------------------------------
module base_plate() {
    difference() {
        // Rounded-ish base
        hull() {
            for (x = [6, base_x - 6], y = [6, base_y - 6])
                translate([x, y, 0])
                    cylinder(d = 12, h = base_t);
        }
        // Foot pad recesses (bottom)
        for (x = [12, base_x - 12], y = [12, base_y - 12])
            translate([x, y, -0.05])
                cylinder(d = foot_d, h = foot_recess_h + 0.05);
        // Cable / scale platform pass-through slot at front
        translate([base_x - 35, (base_y - 50)/2, -0.1])
            cube([30, 50, base_t + 0.2]);
    }
}

// ---------------------------------------------------------------------------
// Single upright with U-cradle for barrel
// ---------------------------------------------------------------------------
module post(x) {
    post_h = barrel_axis_z + barrel_od/2 + 4;
    y0 = (base_y - post_w) / 2;

    difference() {
        // Post body
        translate([x - cradle_depth/2, y0, 0])
            cube([cradle_depth, post_w, post_h]);

        // U-cradle: horizontal cylinder cut at barrel axis
        translate([x - cradle_depth/2 - 0.1, base_y/2, barrel_axis_z])
            rotate([0, 90, 0])
                cylinder(d = barrel_od + CLEARANCE_LOOSE, h = cradle_depth + 0.2);

        // Open top of cradle so barrel drops in from above
        translate([x - cradle_depth/2 - 0.1, base_y/2 - (barrel_od + 1)/2, barrel_axis_z])
            cube([cradle_depth + 0.2, barrel_od + 1, barrel_od]);

        // Optional M3 clamp hole through post (zip-tie or screw later)
        translate([x, base_y/2 - post_w/2 - 0.1, barrel_axis_z + barrel_od/2 + 1.5])
            rotate([-90, 0, 0])
                cylinder(d = 3.3, h = post_w + 0.2, $fn = 16);
    }

    // Side wings for stiffness
    for (side = [-1, 1])
        hull() {
            translate([x - cradle_depth/2, y0 + (side > 0 ? post_w - 2 : 0), 0])
                cube([cradle_depth, 2, 8]);
            translate([x - cradle_depth/2, y0 + post_w/2 + side * 18, 0])
                cube([cradle_depth, 2, base_t]);
        }
}

// ---------------------------------------------------------------------------
// Cross brace between posts (keeps spacing, adds stiffness)
// ---------------------------------------------------------------------------
module cross_brace() {
    y0 = (base_y - 4) / 2;
    translate([post1_x, y0, 8])
        cube([post2_x - post1_x, 4, 6]);
}

// ---------------------------------------------------------------------------
// Full stand
// ---------------------------------------------------------------------------
module test_stand() {
    base_plate();
    post(post1_x);
    post(post2_x);
    cross_brace();
}

test_stand();

echo("barrel axis height above table =", barrel_axis_z);
echo("outlet tip clearance above table ≈", outlet_clear);
echo("base footprint =", base_x, "x", base_y);
