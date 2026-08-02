// ============================================================================
// loadcell_fixed_base_v01.scad – fixed end of 5 kg bar load cell
// Stack: table → THIS → cell fixed end → (live end) → scale_platform → cup
// Verify hole spacing on your cell (default 15 mm M4).
// ============================================================================

include <lib/constants.scad>

cell_w     = LOADCELL_W;
hole_space = LOADCELL_HOLE_SPACE;
hole_d     = LOADCELL_HOLE_D;
base_x     = 40;
base_y     = cell_w + 14;
base_h     = 12;
m4_cbore_d = 8;

$fn = 48;

module loadcell_fixed_base() {
    difference() {
        hull() {
            for (x = [3, base_x - 3], y = [3, base_y - 3])
                translate([x - base_x/2, y - base_y/2, 0])
                    cylinder(d = 6, h = base_h);
        }
        // Cell seat pocket on top
        translate([-base_x/2 - 0.1, -cell_w/2 - 0.25, base_h - LOADCELL_H + 1.5])
            cube([base_x + 0.2, cell_w + 0.5, LOADCELL_H]);
        // M4 holes
        for (dx = [-hole_space/2, hole_space/2])
            translate([dx, 0, -0.1])
                cylinder(d = hole_d, h = base_h + 0.2, $fn = 24);
        // Counterbore from bottom for bolt heads
        for (dx = [-hole_space/2, hole_space/2])
            translate([dx, 0, -0.05])
                cylinder(d = m4_cbore_d, h = 3.2, $fn = 24);
        // Table mount M3
        for (dx = [-14, 14])
            translate([dx, base_y/2 - 5, -0.1])
                cylinder(d = 3.3, h = base_h + 0.2, $fn = 16);
    }
}

loadcell_fixed_base();
