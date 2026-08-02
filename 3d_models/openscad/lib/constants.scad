// ============================================================================
// DIY Supplement Dispenser – shared dimensions (Phase 1 v0.2)
// Source of truth: docs/PHASE1_DESIGN_HANDOFF.md (geometry locks)
// Units: millimetres.
//
// v0.2 stack-up fix:
//   Coupler lives in motor-end bore zone; flights shorter so free end
//   can close with a root-diameter bushing. Assemble auger from free end.
// ============================================================================

// ----- Material / print -----
WALL_T           = 2.2;
CLEARANCE_LOOSE  = 0.4;
CLEARANCE_SLIDE  = 0.25;
CLEARANCE_PRESS  = 0.05;

// ----- Hopper -----
HOPPER_TOP_ID      = 90;
HOPPER_BOT_ID      = 22;
HOPPER_ANGLE_DEG   = 65;
HOPPER_CYL_H       = 40;
HOPPER_WALL        = 2.2;
HOPPER_FLANGE_W    = 7;
HOPPER_FLANGE_T    = 3.5;
HOPPER_BOLT_CIRCLE = 100;
HOPPER_M3_D        = 3.3;
// Cone height: (45 - 11) * tan(65°) ≈ 72.9 mm
HOPPER_CONE_H      = (HOPPER_TOP_ID/2 - HOPPER_BOT_ID/2) * tan(HOPPER_ANGLE_DEG);
// Approximate internal volume (ml): frustum + cylinder ≈ 200 + 254 ≈ 455 ml
HOPPER_SPIGOT_H    = 8;
HOPPER_SPIGOT_OD   = HOPPER_BOT_ID + 2*HOPPER_WALL;
HOPPER_BOT_FLANGE_OD = 42;
HOPPER_BOT_FLANGE_T  = 3.5;
HOPPER_BOT_BOLT_CIRCLE = 34;

// ----- Auger screw (stack-up: coupler zone + flights + tip ≤ barrel) -----
AUGER_OD       = 16.8;
AUGER_ROOT_D   = 8.5;
AUGER_PITCH    = 11;
// Active flights shorter so coupler zone + tip fit in 70 mm barrel
AUGER_LENGTH   = 48;    // was 70 — did not fit with coupler
AUGER_FLIGHT_T = 1.6;
AUGER_SHAFT_D  = 5.0;
AUGER_COUPLER_L = 14;
AUGER_COUPLER_OD = 12;
AUGER_SETSCREW_D = 3.0;
AUGER_TIP_L    = 6;
// Coupler shoulder after coupler body
AUGER_SHOULDER_L = 2.5;

// ----- Barrel / housing -----
BARREL_ID      = 18.0;
BARREL_OD      = BARREL_ID + 2*WALL_T;
BARREL_LENGTH  = 70;
// Motor-end coupler pocket (enlarged bore so 12 mm coupler seats inside barrel)
COUPLER_BORE_D = AUGER_COUPLER_OD + 1.0;  // ~13 mm
COUPLER_ZONE_L = AUGER_COUPLER_L + AUGER_SHOULDER_L + 1; // ~17.5 mm
// Free-end bushing (root + clearance) — CLOSES powder path
BUSHING_ID     = AUGER_ROOT_D + 0.9;  // ~9.4 mm — tip only, not full barrel ID
BUSHING_DEPTH  = 6;
INLET_ID       = HOPPER_BOT_ID;
INLET_BORE_H   = 12;
OUTLET_ID      = 16;
OUTLET_L       = 12;
OUTLET_WALL    = 2.0;
// Side access for M3 set-screw on coupler (radial hole in housing)
SETSCREW_ACCESS_D = 4.0;

// ----- NEMA17 -----
NEMA17_FACE        = 42;
NEMA17_HOLE_SPACE  = 31;
NEMA17_HOLE_D      = 3.3;
NEMA17_PILOT_D     = 22.5;
NEMA17_PLATE_T     = 4.0;
// Shaft pass-through only (coupler does NOT pass the plate)
NEMA17_SHAFT_CLEAR = 6.0;

// ----- Vibration motor -----
VIBE_MOTOR_D   = 12;
VIBE_MOTOR_H   = 3.2;
VIBE_WIRE_W    = 3.5;
VIBE_WIRE_H    = 1.5;

// ----- Load cell / scale platform -----
// Common bar cell ~80×12.7; some Amazon kits are 76×13.5 — verify yours
LOADCELL_L     = 80;
LOADCELL_W     = 12.7;
LOADCELL_H     = 12.7;
LOADCELL_HOLE_SPACE = 15;
LOADCELL_HOLE_D     = 4.2;
CUP_RECESS_D   = 70;
CUP_RECESS_H   = 3;

// ----- Test stand -----
STAND_OUTLET_CLEARANCE = 55;
STAND_FOOT_T   = 4;
STAND_POST_W   = 14;

// ----- Lid -----
LID_LIP_H      = 6;
LID_LIP_CLEAR  = 0.35;

PART_VERSION   = "v02";
