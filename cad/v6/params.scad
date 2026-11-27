// ============================================================================
// Dose Bar v6 — MASTER PARAMETERS. Every part takes its dimensions from here.
//
// HEAD COORDINATES: x = user's right, y = AWAY from the user (front is -y),
// z = up. Origin = jar axis, on the plane where the head sits on its tub
// (z = 0 is the chassis floor underside / the tub's rim).
// "u" = distance toward the user along the pull (u = -y). Body u = 0 is the
// throat's REAR edge; the throat spans u in [0, T_LEN]. hy(u) -> head y.
//
// HOW IT WORKS
//   Jar (upside down) -> chuck -> funnel -> THROAT -> slide with a dose chamber.
//   Pull the scoop drawer: it carries the slide forward STROKE mm. The chamber
//   is struck level at the throat's front edge, travels sealed, and empties
//   through the DROP HOLE into the scoop. Tug through the latch: the scoop
//   comes out. Push it back: it pushes the slide home and the chamber refills.
//   The dial (on the slide, hidden inside the body at home) sets the chamber
//   length through a pinion + rack on the plunger.
//
// Jar preset values come from presets/*.scad (build.py passes them with -D).
// ============================================================================
include <lib/style.scad>
include <presets/std.scad>
use <fonts/Inter-Bold.otf>
use <fonts/Inter-SemiBold.otf>
use <fonts/Inter-Medium.otf>

LH = 0.2;                                  // layer height; Z datums sit on this grid
function zq(z) = ceil(z/LH - 1e-6)*LH;     // round a height UP to the grid
TXT_K = 1.0105;                            // Inter: cap height = TXT_K * text size
function txt_size(cap) = cap/TXT_K;
FONT_BOLD = "Inter:style=Bold";
FONT_SEMI = "Inter:style=SemiBold";
REVEAL = 1.0;                              // the one visible gap everywhere

// ---------- assembly state (for posed exports) --------------------------------
STATE_PULL  = 0;       // slide: 0 = home, 1 = at its out-stop
DIAL_ML     = -1;      // dial setting in mL; -1 = 5/8 of max
CHUCK_CLOSE = 1;       // 0 = jaws fully open, 1 = closed on a NECK_OD jar
DRAWER_OUT  = 0;       // scoop: 0 = home, 1 = fully out. (It also follows the slide.)
WAND_ON     = true;

// ---------- dose class ----------------------------------------------------------
// Pick by the DOSE, not the jar:  S <= 18 mL   M 18-38 mL   L > 38 mL (protein).
// [name, V_max mL, chamber height (= slide thickness), min throat length]
CLASSES = [["S", 20, 18, 30], ["M", 40, 24, 30], ["L", 100, 40, 40]];
function _auto_class(mouth) = mouth >= 104 ? "L" : "M";
CLASS_NAME = DOSE_CLASS == "auto" ? _auto_class(MOUTH_ID) : DOSE_CLASS;
_ci   = search([CLASS_NAME], CLASSES)[0];
V_MAX = CLASSES[_ci][1];
CH_H  = CLASSES[_ci][2];
T_MIN = CLASSES[_ci][3];

// ---------- drivetrain (same on every head) --------------------------------------
G_M = 1.0;  G_Z = 12;  G_PA = 25;  G_ADD = 0.85;  G_CK = 0.25;
CLICKS = 40;  CLICK_DEG = 7.5;             // 40 clicks over 300 degrees
DIAL_TRAVEL  = CLICKS*CLICK_DEG;
ML_PER_CLICK = V_MAX/CLICKS;
NOTCHES = round(360/CLICK_DEG);            // 48 detent notches per revolution
G_RP  = G_M*G_Z/2;                         // pinion pitch radius (6)
L_MAX = G_RP*DIAL_TRAVEL*PI/180;           // plunger travel = max chamber length (31.416)
WING  = 1.6;                               // 45-degree wings along the slot's top edges: they carry the plunger
CH_W  = (V_MAX*1000/L_MAX - WING*WING)/CH_H;   // chamber width so one click is exactly ML_PER_CLICK
DIAL_SET = DIAL_ML < 0 ? V_MAX*0.625 : min(V_MAX, max(0, DIAL_ML));
CH_L  = DIAL_SET/V_MAX*L_MAX;              // current chamber length
DIAL_ANGLE = -DIAL_SET/ML_PER_CLICK*CLICK_DEG;   // clockwise from above = more

// ---------- sealed transit (body u) ----------------------------------------------
T_LEN   = max(L_MAX + 1.0, T_MIN);   // throat length
T_WID   = CH_W;                      // throat width
LAND    = 5.0;                       // chamber is closed top AND bottom for at least this long
OVERTRAVEL = 3.0;
STROKE  = T_LEN + L_MAX + LAND + OVERTRAVEL;
PULL_D  = STATE_PULL*STROKE;
HOLE_U0 = T_LEN + L_MAX + LAND;      // drop hole rear edge
HOLE_U1 = STROKE + L_MAX + 1.0;      // drop hole front edge
SEAL_WINDOW = HOLE_U0 - (T_LEN + L_MAX);
REAR_L  = STROKE + 6;                // solid rear section: keeps the throat covered
PLUNGER_L = T_LEN + 1.0;             // plunger floors whatever throat the chamber doesn't use
SLOT_L  = L_MAX + PLUNGER_L;
BULK_T  = 4.0;
SIDE_W  = 4.0;
SLIDE_W = CH_W + 2*SIDE_W;
function hy(u) = T_LEN/2 - u;        // body u -> head y
SLIDE_Y0 = T_LEN/2 - PULL_D;         // head y of the slide-local origin (chamber rear wall)
// Slide-local frame: head axes, origin at the chamber's rear wall. Slide-local
// u = -(local y). Everything riding on the slide: translate([0, SLIDE_Y0, 0]).

// ---------- vertical stack (0.2 mm grid) --------------------------------------------
FLOOR_T = 2.4;
Z_FLOOR = FLOOR_T;                   // slide runs on this
Z_SLIDE_TOP = Z_FLOOR + CH_H;
CL_VT   = 0.2;
Z_CEIL  = Z_SLIDE_TOP + CL_VT;       // ceiling underside
CEIL_T  = 3.2;
Z_CEIL_TOP = Z_CEIL + CEIL_T;
FUNNEL_ANGLE = 52;
MOUTH_R = MOUTH_ID/2 + 1;            // bore radius (1 mm outside the jar mouth: no ledge)
FUNNEL_H = zq((MOUTH_R - T_LEN/2)*tan(FUNNEL_ANGLE));
Z_HUB_TOP = Z_CEIL_TOP + FUNNEL_H;   // funnel top = hub top = guide plate underside
GP_T    = 5.0;                       // 1.8 mm left under an M3 socket head
Z_GP_TOP = Z_HUB_TOP + GP_T;
RING_T  = 14.0;
Z_RING_TOP = Z_HUB_TOP - 0.4;        // 0.4 axial play under the guide plate
Z_RING_BOT = Z_RING_TOP - RING_T;
RING_LAND = 0.4;                     // proud bearing land on the shoulder
Z_SHOULDER = Z_RING_BOT - 0.2;       // shell's top face (the ring rests on it)
SHOULDER_T = 2.0;
GASKET_FLANGE_T = 1.2;
Z_RIM   = Z_GP_TOP + 2.0;            // jar rim, gasket lips compressed

// ---------- chuck ---------------------------------------------------------------------
// Closing = COUNTER-clockwise seen from above (head coordinates) = clockwise for
// you in the refill pose (jar upright, head on top): it tightens like a lid.
CH_RANGE_D = 20;                     // grips NECK_OD +/- 10 on diameter
PAD_T   = 1.2;                       // TPU boot skin on each jaw
PIN_OFF = 10.0;                      // jaw PLA face -> pin centre
PIN_D   = 6.0;
PIN_LEN = 4.4;                       // pin below the guide plate
GROOVE_W = 6.5;
SCROLL_DEPTH = 5.0;
R_FACE_NOM = NECK_OD/2 + PAD_T;
R_PIN_MIN  = NECK_OD/2 - CH_RANGE_D/4 + PAD_T + PIN_OFF;
R_PIN_MAX  = NECK_OD/2 + CH_RANGE_D/4 + PAD_T + PIN_OFF;
R_PIN_NOM  = R_FACE_NOM + PIN_OFF;
TWIST   = 110;
SCROLL_LEAD = (R_PIN_MAX - R_PIN_MIN)*360/TWIST;
SCROLL_LEAD_ANGLE = atan(SCROLL_LEAD/(PI*(R_PIN_MIN + R_PIN_MAX)));
R_PIN = R_PIN_MAX - CHUCK_CLOSE*(R_PIN_MAX - R_PIN_NOM);
RING_PHI = (R_PIN_MAX - R_PIN)/SCROLL_LEAD*360;      // CCW positive = closing
JAW_ANGLES = [270, 30, 150];
HUB_ID  = 2*MOUTH_R;
HUB_WALL = 5.0;
HUB_OD  = HUB_ID + 2*HUB_WALL;
RING_ID = HUB_OD + 2*CL_ROT;
PUCK_D  = 2*ceil(R_PIN_MAX + GROOVE_W/2 + 4.5);      // ring OD (even number)
PUCK_R  = PUCK_D/2;
RING_OD = PUCK_D;
GP_OD   = RING_OD - 1;               // the plate caps the ring
FOOT_IN = 3.0;                       // jaw foot starts this far behind the jaw face
JAW_TAIL = 4.0;                      // jaw material behind the pin centre
GP_SCREW_R = HUB_ID/2 + HUB_WALL/2;
GP_SCREW_ANGLES = [90, 210, 330];
JAW_W   = 14;
JAW_H   = min(NECK_H - 1, 13);
JAW_L   = PIN_OFF + JAW_TAIL;
DOVE    = [8.0, 11.6, GP_T];         // jaw track: [top width, bottom width, depth] (narrow at the top)
GASKET_ID = 2*MOUTH_R;
GASKET_OD = NECK_OD - 1;             // stays inside the jaws

// ---------- hidden dial (rides on the slide, inside the body at home) -------------
// One piece, printed top face down: rim (detent notches) + relief cone + journal + pinion.
// It drops into the slide from above and is held by one M3 screw from below.
DIAL_D   = 36;                       // rim diameter
DIAL_RIM = 2.4;                      // rim height (the pawl clicks on it)
CONE_H   = 4.6;                      // 60-degree relief cone under the rim (never touches)
JOURNAL_D = 20;                      // the bearing
WELL_D   = DIAL_D + 0.3;             // the rim also runs in the well
Z_DIAL_TOP = Z_SLIDE_TOP - 0.6;      // dial top sits 0.6 below the slide top
Z_RIM_BOT  = Z_DIAL_TOP - DIAL_RIM;
Z_CONE_BOT = Z_RIM_BOT - CONE_H;
CAV_FLOOR = CH_H >= 24 ? 5.1 : 2.1;  // slide floor under the pinion (5.1 hides the screw head)
SPIGOT   = [7.0, 0.8];               // dial's bottom spigot [dia, height]: the lower bearing
Z_CAV   = Z_FLOOR + CAV_FLOOR;
Z_PIN0  = Z_CAV + 0.4;               // pinion bottom
PINION_FACE = min(8.4, Z_CONE_BOT - 2.6 - Z_PIN0);
Z_PIN_C = Z_PIN0 + PINION_FACE/2;
U_DIAL  = SLOT_L + 2.0 + WELL_D/2;   // dial axis, slide-local u
PINION_RA = G_RP + G_M*G_ADD;
RACK_FWD = PI*G_M;                   // rod length past the pinion axis at 0 mL (one tooth pitch)
RACK_N   = ceil((U_DIAL + 0.5*PI*G_M - PLUNGER_L + 1)/(PI*G_M) + 0.5);   // rack teeth: the rack runs back into the block
RACK_BACK = 3.5;
ROD_X0  = G_RP - G_M*G_ADD;          // rack tooth tips (the rack sits on the pinion's +x side)
ROD_X1  = G_RP + G_M*(G_ADD + G_CK) + RACK_BACK;
ROD_CL  = 0.35;
ROD_BACK_CL = 0.15;                  // the channel wall backs the rack so teeth cannot skip
ROD_Z0  = Z_FLOOR + 0.2;             // the rod channel is open top and bottom
ROD_Z1  = Z_PIN0 + PINION_FACE - 0.2;
U_ROD_FRONT0 = U_DIAL + RACK_FWD;    // rod front end at 0 mL (slide-local u)
NOTCH_DEPTH = 0.7;                   // detent notch depth on the rim
PAWL    = [4.6, 5.0, 4.4];           // pawl [length, width, height]
PAWL_TUBE = [5.0, 3.4, 4.4];         // TPU spring tube [OD, ID, height], crushed across its diameter
PAWL_POCKET_Z = Z_SLIDE_TOP - 4.8;   // pocket floor
PAWL_SPRING_R = DIAL_D/2 - NOTCH_DEPTH + PAWL[0] + PAWL_TUBE[0]/2 - 0.5;   // tube centre: 0.5 mm preload
PAWL_ANG = 247.5;                    // pawl direction from the dial axis (front-left); must be a multiple of CLICK_DEG
CL_PLUNGER = 0.15;
GRIP    = [4.0, 9.2, 3.4];           // pinch bar in the dial top: [bar width, recess radius, recess depth]     // finger dimples in the dial: [top dia, bottom dia, depth, radius]

// ---------- slide front + coupling to the scoop --------------------------------------
FACE_T  = 9.0;                       // face block thickness (the rod end tucks into it at big doses)
U_FACE  = U_ROD_FRONT0 + L_MAX + 1.0 + 2.4;   // slide front face (slide-local u) = body front at home
HANDLE_W = SLIDE_W + 6;              // width of the slide face and of the scoop front
Z_FACE0 = 0.5;                       // face block bottom (reveal 1.0 to the scoop front top at -0.5)
Z_FACE1 = Z_SLIDE_TOP;               // flush with the slide top (prints on the bed); the reveal is in the shell
SCOOP_FRONT_T = 5.0;                 // scoop front wall
NOTCH_R = min(14.0, HANDLE_W/2 - 13.5);      // half-moon finger notch in the scoop's top edge
DOG     = [NOTCH_R, HANDLE_W/2 - 3.0, 3.2, 5.0];   // two dogs under the face block: [x inner, x outer, u thickness, drop below Z_FACE0]
U_DOG1  = U_FACE - SCOOP_FRONT_T - 0.3;      // dog front face (0.3 behind the scoop's front wall)
U_FLOOR_FRONT = U_FACE - FACE_T - 0.6;       // the chassis floor stops just behind the face block
FLAP    = [DOG[0] + 4.0, DOG[1] - 2.5, 2.0];   // TPU latch flap behind each dog: [x inner, x outer, thickness]
FLAP_TOP_Z = -2.6;                   // flap top (the dog's bottom edge is at Z_FACE0 - DOG[3])
LATCH_Z = -10.6;                     // pedestal top = flap root
LATCH_DOVE = [6.0, 8.0, 3.0];        // latch root dovetail [top width, bottom width, depth] along u
NAME_BAND = [12.0, 2.0];             // charcoal name band: [height on the face, depth]; 45-degree dovetail, slides in from the side
Z_BAND = (Z_FACE0 + Z_FACE1)/2;
LUG_U0  = 24;                        // stop lugs on both slide sides (slide-local u); always in front of the wand peg
LUG     = [5.0, 6.0];                // [reach, u length]; they run from Z_LUG0 to the slide top
Z_LUG0  = max(Z_SLIDE_TOP - 10.4, Z_FLOOR + 6.0 + LUG[0] + 1.1);   // lugs clear the floor rails
STOP_PAD = 1.6;                      // TPU boot wall on each stop pier
PIER_T  = 8.0;                       // stop pier thickness along u (solid PLA, part of the chassis wall)
PIER_U0 = LUG_U0 + LUG[1] + STROKE + STOP_PAD;   // pier rear face (body u): lug + boot touch at full pull
PIER_X0 = SLIDE_W/2 + 0.6 + STOP_PAD;            // pier inner face

// ---------- agitator wand (rocks only while the throat is covered) ------------------
WAND_U    = 8.0;                     // axle position (body u)
WAND_Z    = zq(Z_CEIL_TOP + 10.2);   // axle height
PEG_D     = 4.4;                     // follower: a TPU finger on the arm, this thick along u (it flexes out of the notch if the gate jams)
FINGER_H  = 5.0;                     // finger height
PEG_Z     = Z_FLOOR + 9.2;           // peg centre at mid-swing (clears the floor rails)
WAND_ARM  = WAND_Z - PEG_Z;          // axle -> follower peg
WAND_SWING = 24.0;                   // follower travel (mm), +/-12 about vertical
WAND_DEG  = asin(WAND_SWING/2/WAND_ARM);
PEG_U_HOME = WAND_U - WAND_SWING/2;  // peg centre (body u) with the slide home
PEG_HW    = (PEG_D/2)*cos(WAND_DEG) + (FINGER_H/2)*sin(WAND_DEG);   // the tilted finger's half-width along u at the ends of its swing
NOTCH_U1  = PEG_U_HOME + PEG_HW + 0.2;                            // notch front end (slide-local u)
NOTCH_U0  = PEG_U_HOME + WAND_SWING - PEG_HW - 0.2 - STROKE;      // notch rear end (slide-local u)
NOTCH_Z   = [PEG_Z - FINGER_H/2 - 0.5, PEG_Z + FINGER_H/2 + WAND_ARM*(1 - cos(WAND_DEG)) + 1.5];
NOTCH_DEPTH_X = 3.2;
ARM_X0    = max(SLIDE_W/2 + 13.5, (HUB_OD + 8)/2 - (Z_RING_BOT - 0.2 - SHOULDER_T - WAND_Z) + 1.0);   // clear of the funnel body's cone
ARM_X     = [ARM_X0, ARM_X0 + 4.0];                    // arm plate (x range)
ARM_SLOT_X = ARM_X0 - 0.5;                             // the ceiling plate is notched from here outward
WAND_TILT = 18;                                        // the gate leans this far toward the user relative to the arm
PEG_U = max(PEG_U_HOME, NOTCH_U0 + PULL_D + PEG_HW + 0.2);    // peg centre (body u) on the pull stroke
WAND_ANGLE = asin((PEG_U - WAND_U)/WAND_ARM);                  // + = peg toward the user

// ---------- body: one rounded-rectangle footprint for tub, chassis and shell ---------
BODY_W   = PUCK_D;
BODY_R   = 34;                       // corner radius
BODY_Y_FRONT = hy(U_FACE);
BODY_Y_REAR  = hy(-REAR_L) + 12.6;
BODY_LEN = BODY_Y_REAR - BODY_Y_FRONT;
module body_2d(inset=0) {
    // rounded rectangle; a positive inset moves the whole outline inward
    translate([0, (BODY_Y_FRONT + BODY_Y_REAR)/2])
        offset(r=max(0.5, BODY_R - inset))
            square([BODY_W - 2*BODY_R, BODY_LEN - 2*BODY_R], center=true);
}
SKIN_T   = 1.6;
LIP_T    = 1.6;  LIP_H = 2.4;  LIP_CL = 0.3;      // tub rim lip: locates shell (outside) and chassis (inside)
CH_INSET = SKIN_T + LIP_CL + LIP_T + LIP_CL;      // chassis floor outline inset from the body outline
BOX_X    = max(SLIDE_W/2 + 19.0, ARM_X[1] + 2.4);   // chassis box side walls (inner face), 2 mm thick
BOX_WALL = 2.0;
RAIL     = [2.4, 6.0];               // floor guide rails [width, height]
Y_BOX_REAR = hy(-REAR_L) + 6.0;      // inner face of the chassis rear wall; the purge slot lies in front of it
BUMP = [20.0, 4.4, 1.6];             // rear bumper: [width, PLA block depth, TPU proud of the block]
HOME_GRIP = [6.6, 6.0, 7.6, 9.0];    // slide home catch: TPU tube OD on the bumper, slot width / depth / height in the slide's rear end
SCOOP_DETENT_Y = 20;                 // scoop home detent (head y): bump on the tub rails, groove in the scoop walls
// Insert screws: 8 x M3 from above. The two middle pairs flank the throat and sit just outside the
// funnel body's overhang (radius > HUB_STEP_OD/2 + 4), so a straight driver reaches every one.
_RSTEP   = (HUB_OD + 8)/2;           // = HUB_STEP_OD/2 (defined below)
BOSS_MID = sqrt(pow(_RSTEP + 4.5, 2) - pow(min(BOX_X - 4, _RSTEP + 4), 2)) + 1.5;
BOSS_Y   = [hy(PIER_U0 - STOP_PAD - 6.5), -BOSS_MID, BOSS_MID, Y_BOX_REAR - 6];
BOSS_XY  = [for (y = BOSS_Y) for (s = [-1, 1]) [s*(BOX_X - 4), y]];
SHELL_Z0 = 0.2;                      // shell skin starts here (never bears on the tub)
HUB_STEP_OD = HUB_OD + 8;            // ledge the shell's shoulder rests on
Z_STEP   = Z_SHOULDER - SHOULDER_T;  // top of that ledge
CONE_BASE = HUB_STEP_OD/2 - (Z_STEP - Z_CEIL_TOP);     // funnel body: 45-degree cone from this half-width
SEAL_OFF = 3.4;                      // U-seal root: distance outside the throat edge
SEAL_ROOT = [2.0, 2.0];              // root [width, height]
SEAL_REBATE = 1.4;                   // relief in the ceiling where the blade lives

// ---------- tub + scoop ------------------------------------------------------------------
PED_H     = 35.0;                    // tub height (z from -PED_H to 0)
TUB_FLOOR_T = 1.2;
FLANGE_W  = 6.0;                     // inward rim flange the chassis rests on
FLANGE_T  = 2.4;
SCOOP_CL  = 0.3;
SCOOP_WALL = 1.6;
SCOOP_HW  = HANDLE_W/2 - 1.0;        // tray outer half-width (the front wall is HANDLE_W wide)
SCOOP_Z0  = -PED_H + TUB_FLOOR_T + 0.2;
SCOOP_RIM_Z = -1.0;                  // side walls' top
SCOOP_FRONT_Z = -0.5;                // front wall top (1 mm reveal under the slide face)
SCOOP_TAPER = 34;                    // length of the tapered, ramped pour end
SCOOP_Y_TAPER = hy(HOLE_U0) + STROKE + 8;      // the landing zone ends 8 mm before the taper starts
SCOOP_Y_REAR = SCOOP_Y_TAPER + SCOOP_TAPER;    // pour lip (head y at home)
SPOUT_W   = CLASS_NAME == "L" ? 44 : 40;       // pour lip width: narrower lips bridge with cohesive powders
SPOUT_RISE = 10;                     // the floor ramps up this much to the lip
PED_GAP   = 6;
ROW_PITCH = BODY_W + PED_GAP;
MAT_T     = 2.0;                     // TPU mat under each head (one tile per head, tiles lock together)
MAT_RIM   = [2.6, 2.0];              // locating rim round the tub [width, height]

// (the dimension report lives in dosebar.scad)

// box in slide-local u coordinates (u toward the user = -y)
module ubx(u0, u1, x0, x1, z0, z1) { translate([x0, -u1, z0]) cube([x1 - x0, u1 - u0, z1 - z0]); }
