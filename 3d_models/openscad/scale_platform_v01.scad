// ============================================================================
// scale_platform_v01.scad – platform for 5 kg bar load cell + cup recess
// DIY Supplement Dispenser
//
// Load cell: common aluminium bar style ~80 × 12.7 × 12.7 mm (YZC-133 family).
// Live end bolts to boss under one side of the deck; cup sits in a centre
// recess so dispenses land consistently and M4 heads do not sit under the cup.
//
// Verify hole spacing on YOUR cell before printing — common variants differ.
// Default: 15 mm centres for the two M4 holes at the live end.
//
// Stack (bottom → top):
//   table → fixed base → load cell → THIS platform → cup
//
// Print: deck up for smooth cup recess; PETG; 4 walls; 40% infill.
// ============================================================================

include <lib/constants.scad>

// ----- Parameters -----
cell_w        = LOADCELL_W;          // 12.7
hole_space    = LOADCELL_HOLE_SPACE; // 15
hole_d        = LOADCELL_HOLE_D;     // 4.2 M4 clearance
// Deck long enough that live-end M4 holes sit fully outside the cup recess
deck_x        = 120;
deck_y        = 90;
deck_t        = 5;
cup_d         = CUP_RECESS_D;        // 70
cup_recess_h  = CUP_RECESS_H;        // 3
// Boss offset to −X so both M4 holes clear the Ø70 cup recess
boss_x        = 28;
boss_y        = cell_w + 8;
boss_h        = 6;
// Holes at boss_cx ± hole_space/2 must have |x| > cup_d/2
// → boss_cx <= -(cup_d/2 + hole_space/2 + 1) ≈ -43.5; keep boss on deck
boss_cx       = -(cup_d/2 + hole_space/2 + 2); // ≈ -44
m4_cbore_d    = 8;
m4_cbore_h    = 2.5;

$fn = 48;

// ---------------------------------------------------------------------------
module cell_live_holes(h = 20) {
    for (dx = [-hole_space/2, hole_space/2])
        translate([dx, 0, 0])
            cylinder(d = hole_d, h = h, $fn = 24);
}

// ---------------------------------------------------------------------------
// Single solid difference — manifold-friendly
// ---------------------------------------------------------------------------
module scale_platform() {
    difference() {
        union() {
            // Main deck
            translate([-deck_x/2, -deck_y/2, boss_h])
                cube([deck_x, deck_y, deck_t]);

            // Mounting boss under deck (load-cell live end)
            translate([boss_cx - boss_x/2, -boss_y/2, 0])
                cube([boss_x, boss_y, boss_h + 0.01]);

            // Four corner overload stops (small pads under deck, ~2 mm drop)
            for (sx = [-1, 1], sy = [-1, 1])
                translate([
                    sx * (deck_x/2 - 10) - 4,
                    sy * (deck_y/2 - 10) - 4,
                    boss_h - 2
                ])
                    cube([8, 8, 2.05]);
        }

        // Cup recess (top centre) — does not intersect M4 holes
        translate([0, 0, boss_h + deck_t - cup_recess_h])
            cylinder(d = cup_d, h = cup_recess_h + 0.15);

        // M4 through-holes at boss centre
        translate([boss_cx, 0, -0.2])
            cell_live_holes(h = boss_h + deck_t + 0.5);

        // Counterbores from top (outside cup recess)
        translate([boss_cx, 0, boss_h + deck_t - m4_cbore_h])
            for (dx = [-hole_space/2, hole_space/2])
                translate([dx, 0, 0])
                    cylinder(d = m4_cbore_d, h = m4_cbore_h + 0.2, $fn = 32);

        // Flex relief under boss: leave two pads around holes
        // Cut a shallow trough, then the hole pads remain as full-height boss
        // by cutting only the middle strip between holes
        translate([boss_cx - 2, -cell_w/2 + 0.3, -0.05])
            cube([4, cell_w - 0.6, 1.0]);
    }
}

// ---------------------------------------------------------------------------
// Optional fixed-end base (set render_fixed_base = true)
// ---------------------------------------------------------------------------
module loadcell_fixed_base() {
    base_x = 36;
    base_y = cell_w + 10;
    base_h = 10;
    difference() {
        translate([-base_x/2, -base_y/2, 0])
            cube([base_x, base_y, base_h]);
        // Cell seat pocket
        translate([-base_x/2 - 0.1, -cell_w/2 - 0.2, base_h - LOADCELL_H + 2])
            cube([base_x + 0.2, cell_w + 0.4, LOADCELL_H]);
        translate([0, 0, -0.1])
            cell_live_holes(h = base_h + 0.2);
        translate([0, 0, -0.05])
            for (dx = [-hole_space/2, hole_space/2])
                translate([dx, 0, 0])
                    cylinder(d = m4_cbore_d, h = 3, $fn = 24);
        for (dx = [-12, 12])
            translate([dx, base_y/2 - 4, -0.1])
                cylinder(d = 3.3, h = base_h + 0.2, $fn = 16);
    }
}

render_fixed_base = false;

if (render_fixed_base)
    loadcell_fixed_base();
else
    scale_platform();

echo("scale platform deck =", deck_x, "x", deck_y, "t", deck_t);
echo("cup recess D/H =", cup_d, cup_recess_h);
echo("boss centre X =", boss_cx, " hole space =", hole_space);
echo("Set render_fixed_base=true to export the fixed-end block instead");
