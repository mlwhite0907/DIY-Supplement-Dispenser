// ============================================================================
// hopper_lid_v01.scad – snap/screw lid for powder hopper top flange
// DIY Supplement Dispenser
//
// Mates top flange: bolt circle 100 mm, 4× M3, OD ≈ 90 + 2*7 = 104 mm outer
// Print: flat, PETG. Optional desiccant well on underside (simple pocket).
// ============================================================================

include <lib/constants.scad>

top_id       = HOPPER_TOP_ID;
flange_w     = HOPPER_FLANGE_W;
bolt_circle  = HOPPER_BOLT_CIRCLE;
m3_d         = HOPPER_M3_D;
wall         = 2.0;
deck_t       = 3.0;
lip_h        = LID_LIP_H;
lip_clear    = LID_LIP_CLEAR;
// Outer diameter of top flange ring
flange_od    = top_id + 2*flange_w;
// Lip seats inside hopper top ID with clearance
lip_od       = top_id - lip_clear;
desiccant_d  = 28;
desiccant_h  = 4;

$fn = 72;

module hopper_lid() {
    difference() {
        union() {
            // Flat deck covering flange
            cylinder(d = flange_od, h = deck_t);
            // Downward lip into hopper mouth
            translate([0, 0, -lip_h])
                difference() {
                    cylinder(d = lip_od, h = lip_h + 0.05);
                    translate([0, 0, -0.1])
                        cylinder(d = lip_od - 2*wall, h = lip_h + 0.3);
                }
            // Finger grip boss on top
            translate([0, 0, deck_t - 0.05])
                cylinder(d = 22, h = 4, $fn = 32);
        }
        // M3 through holes matching hopper flange
        r = bolt_circle / 2;
        for (a = [45, 135, 225, 315])
            translate([r*cos(a), r*sin(a), -lip_h - 0.1])
                cylinder(d = m3_d, h = deck_t + lip_h + 5, $fn = 20);
        // Optional desiccant / handle recess underside of deck
        translate([0, 0, -0.05])
            cylinder(d = desiccant_d, h = desiccant_h, $fn = 40);
        // Finger hole through grip (vent + lift)
        translate([0, 0, -0.1])
            cylinder(d = 10, h = deck_t + 5, $fn = 24);
    }
}

hopper_lid();

echo("lid flange OD =", flange_od, " lip OD =", lip_od, " BCD =", bolt_circle);
