// ============================================================================
// auger_housing_v02 (file name kept _v01 for path stability)
// Phase 1 auger barrel + NEMA17 + closed free end + coupler zone
//
// Stack-up (motor at x=0 plate inner face → free end at x=barrel_len):
//   [plate][coupler bore ~17 mm][flight zone][bushing endcap CLOSED]
//
// Assembly (CRITICAL):
//   1. Insert auger from FREE END (bushing end) — flights first, coupler last
//   2. Coupler seats in motor-end enlarged bore
//   3. Mount NEMA17; shaft enters coupler through 6 mm plate hole
//   4. Tighten set-screw through side access hole
//   NEVER try to slide the 16.8 mm auger through the motor plate.
// ============================================================================

include <lib/constants.scad>
use <lib/nema17.scad>

barrel_id        = BARREL_ID;
barrel_od        = BARREL_OD;
barrel_len       = BARREL_LENGTH;
wall             = WALL_T;
inlet_id         = INLET_ID;
inlet_bore_h     = INLET_BORE_H;
outlet_id        = OUTLET_ID;
outlet_l         = OUTLET_L;
outlet_wall      = OUTLET_WALL;
inlet_flange_od  = HOPPER_BOT_FLANGE_OD;
inlet_flange_t   = 4.0;
inlet_bcd        = HOPPER_BOT_BOLT_CIRCLE;
spigot_clear_d   = HOPPER_SPIGOT_OD + CLEARANCE_LOOSE;
spigot_seat_h    = HOPPER_SPIGOT_H + 0.5;
outlet_x         = barrel_len - 14;
vibe_d           = VIBE_MOTOR_D + 0.4;
vibe_h           = VIBE_MOTOR_H + 0.3;
coupler_bore_d   = COUPLER_BORE_D;
coupler_zone_l   = COUPLER_ZONE_L;
bushing_id       = BUSHING_ID;
bushing_depth    = BUSHING_DEPTH;
plate_t          = NEMA17_PLATE_T;
endcap_t         = 6;
inlet_x          = 22;
inlet_throat_od  = max(spigot_clear_d + 2*wall, inlet_id + 2*wall + 2);

$fn = 64;

module housing_body() {
    // Barrel outer
    rotate([0, 90, 0])
        cylinder(d = barrel_od, h = barrel_len);

    // Inlet throat + flange
    hull() {
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

    // Outlet nozzle
    hull() {
        translate([outlet_x, 0, 0])
            sphere(d = barrel_od * 0.9, $fn = 36);
        translate([outlet_x, 0, -barrel_od/2 - outlet_l + 0.5])
            cylinder(d = outlet_id + 2*outlet_wall, h = 0.5);
    }
    translate([outlet_x, 0, -barrel_od/2 - outlet_l])
        cylinder(d = outlet_id + 2*outlet_wall, h = outlet_l + 0.1);

    // NEMA17 plate
    translate([-plate_t, -NEMA17_FACE/2, -NEMA17_FACE/2])
        cube([plate_t, NEMA17_FACE, NEMA17_FACE]);
    hull() {
        translate([-0.1, 0, 0])
            rotate([0, 90, 0])
                cylinder(d = barrel_od, h = 0.1);
        translate([-0.1, -NEMA17_FACE/2 + 2, -NEMA17_FACE/2 + 2])
            cube([0.1, NEMA17_FACE - 4, NEMA17_FACE - 4]);
    }

    // CLOSED free-end endcap (solid outer; bushing cut later)
    translate([barrel_len, 0, 0])
        rotate([0, 90, 0])
            cylinder(d = barrel_od + 3, h = endcap_t);

    // Vibe pad
    translate([inlet_x - vibe_d/2 - 1, barrel_od/2 - 2, -vibe_d/2 - 1])
        cube([vibe_d + 2, 4, vibe_d + 2]);

    // Set-screw access boss on +Y near coupler zone
    translate([coupler_zone_l/2 - 4, barrel_od/2 - 1, -5])
        cube([8, 5, 10]);
}

module housing_cavities() {
    // Main flight bore: starts AFTER coupler zone, stops BEFORE endcap bushing
    // Leaves closed end with only bushing_id open
    flight_start = coupler_zone_l;
    flight_len   = barrel_len - coupler_zone_l - 0.5;
    translate([flight_start, 0, 0])
        rotate([0, 90, 0])
            cylinder(d = barrel_id, h = flight_len);

    // Coupler pocket (enlarged, motor end of barrel)
    translate([0.05, 0, 0])
        rotate([0, 90, 0])
            cylinder(d = coupler_bore_d, h = coupler_zone_l + 0.1);

    // Blend step coupler → flight (short cone to avoid powder shelf)
    translate([coupler_zone_l - 0.5, 0, 0])
        rotate([0, 90, 0])
            cylinder(d1 = coupler_bore_d, d2 = barrel_id, h = 1.2);

    // Free-end bushing ONLY (tip of auger) — NOT full barrel ID
    translate([barrel_len - 0.2, 0, 0])
        rotate([0, 90, 0])
            cylinder(d = bushing_id, h = endcap_t + 0.5);

    // Tiny vent (0.8 mm) so air escapes; powder will not dump
    translate([barrel_len + endcap_t - 0.5, 0, barrel_od/2 - 2])
        rotate([0, 90, 0])
            cylinder(d = 0.9, h = 2, $fn = 12);

    // Shaft through plate only (6 mm) — coupler does not pass plate
    translate([0.05, 0, 0])
        rotate([0, -90, 0])
            cylinder(d = NEMA17_SHAFT_CLEAR, h = plate_t + 0.3, $fn = 36);

    // Pilot recess motor face
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

    // Spigot counterbore
    translate([inlet_x, 0, barrel_od/2 + inlet_bore_h + inlet_flange_t - spigot_seat_h])
        cylinder(d = spigot_clear_d, h = spigot_seat_h + 0.2);

    // Inlet flange M3
    r = inlet_bcd / 2;
    for (a = [0, 90, 180, 270])
        translate([inlet_x + r*cos(a), r*sin(a), barrel_od/2 + inlet_bore_h - 0.1])
            cylinder(d = HOPPER_M3_D, h = inlet_flange_t + 0.4, $fn = 20);

    // Outlet bore into barrel flight zone
    translate([outlet_x, 0, -barrel_od/2 - outlet_l - 0.2])
        cylinder(d = outlet_id, h = outlet_l + barrel_od/2 + barrel_id/2 + 1);

    // Set-screw access (radial) into coupler zone centre
    translate([AUGER_COUPLER_L/2, barrel_od/2 - 0.5, 0])
        rotate([-90, 0, 0])
            cylinder(d = SETSCREW_ACCESS_D, h = 8, $fn = 20);

    // Vibe pocket
    translate([inlet_x, barrel_od/2 - 0.5, 0])
        rotate([-90, 0, 0])
            cylinder(d = vibe_d, h = vibe_h + 2, $fn = 36);

    // Wire channel
    translate([6, barrel_od/2 - 0.5, -VIBE_WIRE_W/2])
        cube([inlet_x - 4, 3, VIBE_WIRE_W]);
}

module auger_housing() {
    difference() {
        housing_body();
        housing_cavities();
    }
}

auger_housing();

echo("v02 housing: coupler zone L=", coupler_zone_l, " bore D=", coupler_bore_d);
echo("flight bore starts at x=", coupler_zone_l, " bushing ID=", bushing_id);
echo("ASSEMBLE AUGER FROM FREE END — see PRINT_GUIDE.md");
