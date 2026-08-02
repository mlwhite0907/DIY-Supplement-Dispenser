// ============================================================================
// powder_hopper_v01.scad – Phase 1 conical powder hopper
// DIY Supplement Dispenser
//
// Geometry (locked, PHASE1_DESIGN_HANDOFF):
//   - Top cylindrical section: 40 mm tall, inner Ø 90 mm
//   - Cone: 65° from horizontal, top ID 90 → bottom ID 22
//   - Wall 2.2 mm; top flange 7 mm wide with 4× M3 on 100 mm BCD
//   - Bottom: registration spigot + screw flange (mates auger_housing inlet)
//
// Interface hopper ↔ housing:
//   Hopper bottom flange sits on housing inlet face.
//   Spigot (OD ≈ 26.4 mm) drops into housing inlet counterbore.
//   4× M3 on 34 mm bolt circle clamp the pair (or bayonet later).
//
// Print: PETG, prefer outlet-on-bed (point-down) for smooth interior.
// Open in OpenSCAD: F5 preview / F6 render. Export STL via scripts/export_stls.sh
// ============================================================================

include <lib/constants.scad>

// ----- Local parameters (override constants if iterating) -----
top_id       = HOPPER_TOP_ID;
bot_id       = HOPPER_BOT_ID;
wall         = HOPPER_WALL;
cyl_h        = HOPPER_CYL_H;
cone_h       = HOPPER_CONE_H;      // ≈ 72.9 mm at 65°
flange_w     = HOPPER_FLANGE_W;
flange_t     = HOPPER_FLANGE_T;
bolt_circle  = HOPPER_BOLT_CIRCLE;
m3_d         = HOPPER_M3_D;
spigot_h     = HOPPER_SPIGOT_H;
spigot_od    = HOPPER_SPIGOT_OD;
bot_flange_od = HOPPER_BOT_FLANGE_OD;
bot_flange_t  = HOPPER_BOT_FLANGE_T;
bot_bcd      = HOPPER_BOT_BOLT_CIRCLE;

// Optional vibration pocket on cone mid-height (off by default — housing has one)
add_hopper_vibe_pocket = false;

$fn = 96;

// ---------------------------------------------------------------------------
// Solid outer envelope (no bores)
// ---------------------------------------------------------------------------
module hopper_outer() {
    top_od = top_id + 2*wall;
    bot_od = bot_id + 2*wall;

    // Top flange ring (outer disc)
    translate([0, 0, cone_h + cyl_h])
        cylinder(d = top_od + 2*flange_w, h = flange_t);

    // Cylindrical head
    translate([0, 0, cone_h])
        cylinder(d = top_od, h = cyl_h);

    // Cone (outer)
    cylinder(d1 = bot_od, d2 = top_od, h = cone_h);

    // Bottom mate flange (at z = 0, extends slightly below into spigot zone)
    translate([0, 0, -bot_flange_t])
        cylinder(d = bot_flange_od, h = bot_flange_t);

    // Registration spigot (below flange)
    translate([0, 0, -bot_flange_t - spigot_h])
        cylinder(d = spigot_od, h = spigot_h + 0.01);
}

// ---------------------------------------------------------------------------
// Inner powder cavity (subtracted)
// ---------------------------------------------------------------------------
module hopper_cavity() {
    // Through the whole height including flange/spigot for clean outlet
    total_below = bot_flange_t + spigot_h;
    translate([0, 0, -total_below - 0.1])
        cylinder(d = bot_id, h = total_below + 0.2);

    // Cone cavity
    translate([0, 0, -0.01])
        cylinder(d1 = bot_id, d2 = top_id, h = cone_h + 0.02);

    // Cylindrical head cavity
    translate([0, 0, cone_h - 0.01])
        cylinder(d = top_id, h = cyl_h + flange_t + 0.1);
}

// ---------------------------------------------------------------------------
// Top flange M3 holes (4× on bolt_circle)
// ---------------------------------------------------------------------------
module top_flange_holes() {
    r = bolt_circle / 2;
    for (a = [45, 135, 225, 315])
        translate([r*cos(a), r*sin(a), cone_h + cyl_h - 0.1])
            cylinder(d = m3_d, h = flange_t + 0.2, $fn = 24);
}

// ---------------------------------------------------------------------------
// Bottom flange M3 holes (mates housing) — 4× on bot_bcd
// ---------------------------------------------------------------------------
module bot_flange_holes() {
    r = bot_bcd / 2;
    for (a = [0, 90, 180, 270])
        translate([r*cos(a), r*sin(a), -bot_flange_t - 0.1])
            cylinder(d = m3_d, h = bot_flange_t + 0.2, $fn = 24);
}

// ---------------------------------------------------------------------------
// Optional coin-motor pocket on cone wall (mid-height, +X side)
// ---------------------------------------------------------------------------
module hopper_vibe_pocket() {
    // Place pocket mid-cone on outer surface; approximate with radial cylinder
    z_mid = cone_h * 0.45;
    // Outer radius at this height (linear from bot_od/2 to top_od/2)
    top_od = top_id + 2*wall;
    bot_od = bot_id + 2*wall;
    r_out = bot_od/2 + (top_od/2 - bot_od/2) * (z_mid / cone_h);
    translate([r_out - VIBE_MOTOR_H*0.4, 0, z_mid])
        rotate([0, 90, 0])
            cylinder(d = VIBE_MOTOR_D + 0.3, h = VIBE_MOTOR_H + 1, $fn = 36);
}

// ---------------------------------------------------------------------------
// Assembly
// ---------------------------------------------------------------------------
module powder_hopper() {
    difference() {
        hopper_outer();
        hopper_cavity();
        top_flange_holes();
        bot_flange_holes();
        if (add_hopper_vibe_pocket)
            hopper_vibe_pocket();
    }
}

// Origin: bottom of cone at z=0 (spigot below, flange at negative z)
// Rotate 180° for bed-on-outlet print orientation if desired in slicer.
powder_hopper();

// Echo key dims for console (OpenSCAD echo)
echo("hopper cone_h mm =", cone_h);
echo("hopper total height mm =", cone_h + cyl_h + flange_t + bot_flange_t + spigot_h);
echo("hopper spigot OD =", spigot_od, " mates housing inlet counterbore");
echo("hopper bot BCD =", bot_bcd, " 4x M3");
