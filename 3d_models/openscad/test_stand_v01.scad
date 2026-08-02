// ============================================================================
// test_stand_v02 – cradles account for NEMA plate, inlet flange, endcap bulk
// Two U-cradles under bare barrel zones; open bay under outlet for cup/scale.
// ============================================================================

include <lib/constants.scad>

barrel_od     = BARREL_OD;
outlet_clear  = STAND_OUTLET_CLEARANCE;
post_w        = STAND_POST_W;
base_t        = STAND_FOOT_T;
// Axis height: outlet tip clear + nozzle stick-out + radius
barrel_axis_z = outlet_clear + OUTLET_L + barrel_od/2;
// Longer base for plate + endcap + inlet flange footprint
base_x        = 130;
base_y        = 95;
// Cradle under bare barrel: after plate (~4 mm) and before endcap
// Housing: plate at x=-4..0, barrel 0..70, endcap 70..76, inlet flange at x≈22
// Cradle 1: motor-side barrel after plate, before inlet flange (x ~ 8–12 in housing)
// Cradle 2: free-end side before outlet boss (x ~ 50–55)
// Stand local X: 0 at motor end of base
post1_x       = 28;   // under barrel near coupler zone (past plate)
post2_x       = 78;   // under barrel before outlet, past inlet
cradle_depth  = 12;
// Wider cradle radius to tolerate inlet throat nearby (loose hold)
cradle_d      = barrel_od + 1.2;
foot_d        = 12;
foot_recess_h = 1.2;

$fn = 48;

module base_plate() {
    difference() {
        hull() {
            for (x = [6, base_x - 6], y = [6, base_y - 6])
                translate([x, y, 0])
                    cylinder(d = 12, h = base_t);
        }
        for (x = [14, base_x - 14], y = [14, base_y - 14])
            translate([x, y, -0.05])
                cylinder(d = foot_d, h = foot_recess_h + 0.05);
        // Front pass-through for scale platform + cup
        translate([base_x - 48, (base_y - 58)/2, -0.1])
            cube([42, 58, base_t + 0.2]);
        // Motor plate clearance notch at rear (NEMA 42 face hangs down)
        translate([-1, (base_y - 50)/2, base_t - 0.5])
            cube([18, 50, 2]);
    }
}

module post(x) {
    post_h = barrel_axis_z + barrel_od/2 + 6;
    y0 = (base_y - post_w) / 2;
    difference() {
        translate([x - cradle_depth/2, y0, 0])
            cube([cradle_depth, post_w, post_h]);
        translate([x - cradle_depth/2 - 0.1, base_y/2, barrel_axis_z])
            rotate([0, 90, 0])
                cylinder(d = cradle_d, h = cradle_depth + 0.2);
        translate([x - cradle_depth/2 - 0.1, base_y/2 - cradle_d/2, barrel_axis_z])
            cube([cradle_depth + 0.2, cradle_d, barrel_od + 4]);
        translate([x, base_y/2 - post_w/2 - 0.1, barrel_axis_z + barrel_od/2 + 2])
            rotate([-90, 0, 0])
                cylinder(d = 3.3, h = post_w + 0.2, $fn = 16);
    }
    for (side = [-1, 1])
        hull() {
            translate([x - cradle_depth/2, y0 + (side > 0 ? post_w - 2 : 0), 0])
                cube([cradle_depth, 2, 10]);
            translate([x - cradle_depth/2, y0 + post_w/2 + side * 22, 0])
                cube([cradle_depth, 2, base_t]);
        }
}

module cross_brace() {
    y0 = (base_y - 5) / 2;
    translate([post1_x, y0, 10])
        cube([post2_x - post1_x, 5, 7]);
}

// Side stop for NEMA plate (prevents sliding toward free end)
module motor_stop() {
    translate([8, (base_y - 20)/2, base_t])
        cube([4, 20, 18]);
}

module test_stand() {
    base_plate();
    post(post1_x);
    post(post2_x);
    cross_brace();
    motor_stop();
}

test_stand();

echo("barrel axis Z =", barrel_axis_z, " cradle D =", cradle_d);
echo("posts at", post1_x, post2_x, " base", base_x, "x", base_y);
