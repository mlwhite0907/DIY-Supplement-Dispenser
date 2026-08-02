// ============================================================================
// auger_screw_v01.scad – Phase 1 single-start Archimedes powder auger
// DIY Supplement Dispenser
//
// Geometry (locked ranges):
//   OD ~16.5–17.2  → 16.8 mm
//   Root 8–9       → 8.5 mm
//   Pitch 10–12    → 11 mm
//   Active length match barrel 60–80 → 70 mm
//   Drive end: printed coupler for NEMA17 5 mm shaft + M3 set-screw
//
// Helix method: linear_extrude(... twist=...) of a radial flight rectangle.
// This is reliable in OpenSCAD F5/F6 (no polyhedron self-intersections).
//
// Print: vertical (axis = Z), 100% infill or high density, PETG.
// Clearance: barrel ID 18.0 → radial gap (18-16.8)/2 = 0.6 mm.
// ============================================================================

include <lib/constants.scad>

// ----- Parameters -----
od            = AUGER_OD;         // 16.8
root_d        = AUGER_ROOT_D;     // 8.5
pitch         = AUGER_PITCH;      // 11
active_len    = AUGER_LENGTH;     // 70
flight_t      = AUGER_FLIGHT_T;   // 1.6  (profile thickness → flight width)
shaft_d       = AUGER_SHAFT_D;    // 5.0
coupler_l     = AUGER_COUPLER_L;  // 14
setscrew_d    = AUGER_SETSCREW_D; // 3.0
// Tip: short tapered lead into inlet (reduces packing)
tip_taper_l   = 6;
// Coupler outer diameter (must clear NEMA pilot / housing shaft hole)
coupler_od    = 12;

// Derived
root_r        = root_d / 2;
od_r          = od / 2;
flight_depth  = od_r - root_r;
turns         = active_len / pitch;
slices_per_turn = 24;

$fn = 64;

// ---------------------------------------------------------------------------
// Core cylinder (root) through active section + tip
// ---------------------------------------------------------------------------
module auger_core() {
    // Main root
    cylinder(d = root_d, h = active_len + tip_taper_l);
    // Tip blunt point (helps entry, less packing)
    translate([0, 0, active_len + tip_taper_l - 0.01])
        cylinder(d1 = root_d, d2 = root_d * 0.55, h = 4);
}

// ---------------------------------------------------------------------------
// Helical flight via linear_extrude twist
// 2D profile: rectangle from root_r to od_r, thickness flight_t in Y
// Twist: negative = right-hand screw when advancing +Z (standard auger)
// ---------------------------------------------------------------------------
module auger_flight() {
    // Extra half-pitch of flight into the tip taper zone
    h = active_len + tip_taper_l * 0.5;
    n = h / pitch;
    linear_extrude(
        height    = h,
        twist     = -360 * n,   // right-hand helix advancing +Z
        slices    = max(8, ceil(n * slices_per_turn)),
        convexity = 12
    ) {
        // Radial flight bar, centred on Y so thickness is flight_t
        translate([root_r + flight_depth/2, 0])
            square([flight_depth + 0.05, flight_t], center = true);
    }
}

// ---------------------------------------------------------------------------
// Drive coupler (motor end, z < 0 relative to active start)
// Hollow for 5 mm shaft; radial M3 set-screw
// ---------------------------------------------------------------------------
module drive_coupler() {
    difference() {
        // Body — slight hex for grip / wrench
        cylinder(d = coupler_od, h = coupler_l, $fn = 6);
        // Shaft bore (slight clearance)
        translate([0, 0, -0.1])
            cylinder(d = shaft_d + 0.15, h = coupler_l + 0.2, $fn = 32);
        // Set-screw hole through one flat
        translate([0, 0, coupler_l/2])
            rotate([0, 90, 0])
                cylinder(d = setscrew_d, h = coupler_od, $fn = 20);
        // Optional second set-screw 90° (uncomment if wanted)
        // translate([0, 0, coupler_l/2])
        //     rotate([90, 0, 0])
        //         cylinder(d = setscrew_d, h = coupler_od, $fn = 20);
    }
    // Solid bridge from coupler to root (keyed shoulder)
    translate([0, 0, coupler_l - 0.01])
        cylinder(d1 = coupler_od * 0.9, d2 = root_d, h = 3);
}

// ---------------------------------------------------------------------------
// Full auger: coupler at z=0..coupler, flights from coupler end
// ---------------------------------------------------------------------------
module auger_screw() {
    // Coupler at base (motor end)
    drive_coupler();

    // Shift active section so it starts just after coupler shoulder
    z0 = coupler_l + 2.5;
    translate([0, 0, z0]) {
        auger_core();
        auger_flight();
    }
}

// Preview / render
auger_screw();

echo("auger OD =", od, " root =", root_d, " pitch =", pitch);
echo("auger active_len =", active_len, " turns =", turns);
echo("auger total height ≈", coupler_l + 3 + active_len + tip_taper_l + 4);
echo("radial clearance to barrel ID", BARREL_ID, "=", (BARREL_ID - od)/2, "mm");
