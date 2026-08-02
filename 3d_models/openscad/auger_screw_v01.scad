// ============================================================================
// auger_screw_v02 – stack-up fixed for 70 mm barrel + closed endcap
//
// Layout along Z (motor end at z=0):
//   0 .. coupler_l     : hex coupler (OD 12) for NEMA 5 mm shaft
//   coupler_l .. +sh   : shoulder into root
//   then active flights (AUGER_LENGTH = 48)
//   then tip taper
//
// Insert into housing from FREE END (tip first). Coupler seats in motor-end pocket.
// ============================================================================

include <lib/constants.scad>

od            = AUGER_OD;
root_d        = AUGER_ROOT_D;
pitch         = AUGER_PITCH;
active_len    = AUGER_LENGTH;
flight_t      = AUGER_FLIGHT_T;
shaft_d       = AUGER_SHAFT_D;
coupler_l     = AUGER_COUPLER_L;
coupler_od    = AUGER_COUPLER_OD;
setscrew_d    = AUGER_SETSCREW_D;
tip_taper_l   = AUGER_TIP_L;
shoulder_l    = AUGER_SHOULDER_L;

root_r        = root_d / 2;
od_r          = od / 2;
flight_depth  = od_r - root_r;
turns         = active_len / pitch;
slices_per_turn = 24;

$fn = 64;

module auger_core() {
    cylinder(d = root_d, h = active_len + tip_taper_l);
    translate([0, 0, active_len + tip_taper_l - 0.01])
        cylinder(d1 = root_d, d2 = root_d * 0.55, h = 4);
}

module auger_flight() {
    h = active_len + tip_taper_l * 0.4;
    n = h / pitch;
    linear_extrude(
        height    = h,
        twist     = -360 * n,
        slices    = max(8, ceil(n * slices_per_turn)),
        convexity = 12
    ) {
        translate([root_r + flight_depth/2, 0])
            square([flight_depth + 0.05, flight_t], center = true);
    }
}

module drive_coupler() {
    difference() {
        cylinder(d = coupler_od, h = coupler_l, $fn = 6);
        translate([0, 0, -0.1])
            cylinder(d = shaft_d + 0.15, h = coupler_l + 0.2, $fn = 32);
        translate([0, 0, coupler_l/2])
            rotate([0, 90, 0])
                cylinder(d = setscrew_d, h = coupler_od, $fn = 20);
    }
    translate([0, 0, coupler_l - 0.01])
        cylinder(d1 = coupler_od * 0.9, d2 = root_d, h = shoulder_l);
}

module auger_screw() {
    drive_coupler();
    z0 = coupler_l + shoulder_l - 0.5;
    translate([0, 0, z0]) {
        auger_core();
        auger_flight();
    }
}

auger_screw();

total_h = coupler_l + shoulder_l + active_len + tip_taper_l + 4;
echo("auger OD/root/pitch =", od, root_d, pitch);
echo("active flights =", active_len, " total length ≈", total_h);
echo("must fit: coupler_zone + flights + tip ≤ barrel", BARREL_LENGTH);
echo("coupler OD", coupler_od, " needs housing pocket", COUPLER_BORE_D);
