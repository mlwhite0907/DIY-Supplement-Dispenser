// ============================================================================
// DIY Supplement Dispenser – shared dimensions (Phase 1 v0.1)
// Source of truth: docs/PHASE1_DESIGN_HANDOFF.md
// All modules under 3d_models/openscad/ should include this file.
// Units: millimetres throughout.
// ============================================================================

// ----- Material / print -----
// Preferred: PETG, wall 2.0–2.4 mm for powder-contact shells
WALL_T           = 2.2;   // nominal shell wall thickness
CLEARANCE_LOOSE  = 0.4;   // free slip fit (printed-to-printed)
CLEARANCE_SLIDE  = 0.25;  // light slip
CLEARANCE_PRESS  = 0.05;  // slight interference target (post-sand)

// ----- Hopper -----
// Conical mass-flow hopper: 65° from horizontal, cylindrical head + flange
HOPPER_TOP_ID      = 90;    // top inner diameter (pour opening)
HOPPER_BOT_ID      = 22;    // bottom / outlet inner diameter
HOPPER_ANGLE_DEG   = 65;    // wall angle from horizontal
HOPPER_CYL_H       = 40;    // cylindrical top section height
HOPPER_WALL        = 2.2;   // wall thickness
HOPPER_FLANGE_W    = 7;     // radial width of top flange ring
HOPPER_FLANGE_T    = 3.5;   // flange thickness
HOPPER_BOLT_CIRCLE = 100;   // M3 bolt circle diameter (4×)
HOPPER_M3_D        = 3.3;   // clearance hole for M3
// Cone height from geometry: (top_r - bot_r) * tan(angle)
// (45 - 11) * tan(65°) ≈ 72.9 mm
HOPPER_CONE_H      = (HOPPER_TOP_ID/2 - HOPPER_BOT_ID/2) * tan(HOPPER_ANGLE_DEG);
// Bottom mate: short cylindrical spigot that drops into housing inlet
HOPPER_SPIGOT_H    = 8;     // length of bottom registration spigot
HOPPER_SPIGOT_OD   = HOPPER_BOT_ID + 2*HOPPER_WALL; // outer of spigot wall
// Flange on hopper bottom for screw/bayonet mate to housing
HOPPER_BOT_FLANGE_OD = 42;
HOPPER_BOT_FLANGE_T  = 3.5;
HOPPER_BOT_BOLT_CIRCLE = 34; // 4× M3 on this circle (mates housing)
// Bayonet optional: 3 lugs; v0.1 uses screw flange (more reliable for cleaning)

// ----- Auger screw -----
AUGER_OD       = 16.8;  // flight outer diameter
AUGER_ROOT_D   = 8.5;   // core / root diameter
AUGER_PITCH    = 11;    // single-start pitch (mm per turn)
AUGER_LENGTH   = 70;    // active flight length (match barrel)
AUGER_FLIGHT_T = 1.6;   // flight thickness along axis of 2D profile
AUGER_SHAFT_D  = 5.0;   // NEMA17 shaft diameter
AUGER_COUPLER_L = 14;   // printed coupler section length
AUGER_SETSCREW_D = 3.0; // M3 set-screw hole

// ----- Barrel / housing -----
BARREL_ID      = 18.0;  // → ~0.6 mm radial clearance to 16.8 OD auger
BARREL_OD      = BARREL_ID + 2*WALL_T;
BARREL_LENGTH  = 70;    // active barrel bore length
INLET_ID       = HOPPER_BOT_ID; // matched throat
INLET_BORE_H   = 12;    // vertical throat depth below hopper mate face
OUTLET_ID      = 16;    // downward nozzle ID
OUTLET_L       = 12;    // nozzle stick-out below barrel
OUTLET_WALL    = 2.0;

// ----- NEMA17 -----
// Face 42×42 mm, mounting holes 31 mm square pattern, pilot ~22 mm
NEMA17_FACE        = 42;
NEMA17_HOLE_SPACE  = 31;   // centre-to-centre of opposite M3 holes
NEMA17_HOLE_D      = 3.3;  // M3 clearance
NEMA17_PILOT_D     = 22.5; // shaft pilot / boss clearance
NEMA17_PLATE_T     = 4.0;  // motor mount plate thickness
NEMA17_SHAFT_CLEAR = 6.0;  // through-hole for shaft + coupler

// ----- Vibration motor (coin / pancake) -----
VIBE_MOTOR_D   = 12;    // pocket diameter (Ø10–12 motors)
VIBE_MOTOR_H   = 3.2;   // pocket depth
VIBE_WIRE_W    = 3.5;   // wire exit channel width
VIBE_WIRE_H    = 1.5;   // wire channel height

// ----- Load cell / scale platform -----
// Common aluminium bar 5 kg load cell (e.g. YZC-133 style)
LOADCELL_L     = 80;
LOADCELL_W     = 12.7;
LOADCELL_H     = 12.7;
LOADCELL_HOLE_SPACE = 15; // typical end-hole centres (verify your cell)
LOADCELL_HOLE_D     = 4.2; // M4 clearance common
CUP_RECESS_D   = 70;    // recess for collection cup base
CUP_RECESS_H   = 3;

// ----- Test stand -----
// Raises housing outlet ~50 mm above table so cup + load cell slide under
STAND_OUTLET_CLEARANCE = 55;
STAND_FOOT_T   = 4;
STAND_POST_W   = 12;

// ----- Version tag (embossed where useful) -----
PART_VERSION   = "v01";
