// ============================================================================
// scale_platform_v02 – cup recess fully clear of M4 counterbores
// Live-end boss pushed further −X so Ø8 counterbores stay outside Ø70 recess.
// ============================================================================

include <lib/constants.scad>

cell_w        = LOADCELL_W;
hole_space    = LOADCELL_HOLE_SPACE;
hole_d        = LOADCELL_HOLE_D;
deck_x        = 130;
deck_y        = 90;
deck_t        = 5;
cup_d         = CUP_RECESS_D;
cup_recess_h  = CUP_RECESS_H;
boss_x        = 32;
boss_y        = cell_w + 8;
boss_h        = 6;
m4_cbore_d    = 8;
m4_cbore_h    = 2.5;
// Outer edge of counterbore must be outside cup: |boss_cx| - hole_space/2 - cbore_r > cup_r
// |boss_cx| > 35 + 7.5 + 4 + 2 = 48.5 → use 50
boss_cx       = -50;

$fn = 48;

module cell_live_holes(h = 20) {
    for (dx = [-hole_space/2, hole_space/2])
        translate([dx, 0, 0])
            cylinder(d = hole_d, h = h, $fn = 24);
}

module scale_platform() {
    difference() {
        union() {
            translate([-deck_x/2, -deck_y/2, boss_h])
                cube([deck_x, deck_y, deck_t]);
            translate([boss_cx - boss_x/2, -boss_y/2, 0])
                cube([boss_x, boss_y, boss_h + 0.01]);
            // Overload stop pads
            for (sx = [-1, 1], sy = [-1, 1])
                translate([
                    sx * (deck_x/2 - 12) - 4,
                    sy * (deck_y/2 - 12) - 4,
                    boss_h - 2
                ])
                    cube([8, 8, 2.05]);
        }
        translate([0, 0, boss_h + deck_t - cup_recess_h])
            cylinder(d = cup_d, h = cup_recess_h + 0.15);
        translate([boss_cx, 0, -0.2])
            cell_live_holes(h = boss_h + deck_t + 0.5);
        translate([boss_cx, 0, boss_h + deck_t - m4_cbore_h])
            for (dx = [-hole_space/2, hole_space/2])
                translate([dx, 0, 0])
                    cylinder(d = m4_cbore_d, h = m4_cbore_h + 0.2, $fn = 32);
        // Flex relief
        translate([boss_cx - 2, -cell_w/2 + 0.3, -0.05])
            cube([4, cell_w - 0.6, 1.0]);
    }
}

scale_platform();

echo("boss_cx =", boss_cx, " cup R =", cup_d/2);
echo("cbore outer |x| min =", abs(boss_cx) - hole_space/2 - m4_cbore_d/2);
