// ============================================================================
// Dose Bar v5 — MASTER PARAMETERS + INTERFACE DATUMS
// Every part file includes this. Nothing about a part's mating features may be
// hard-coded in the part: take it from here so all parts always fit.
//
// HEAD COORDINATES (assembled):  x = user's right, y = AWAY from the user
// (front of the head is -y, like OpenSCAD's front view), z = up.
//   Origin: jar axis, at the head's bottom face (= underside of channel floor).
//   The jar sits upside down on top of the head.
//
// "u" = distance along the PULL direction (toward the user, u = -y).
//   Body u = 0 is the throat's REAR edge. The throat spans u in [0, T_LEN].
//   hy(u) converts body u to head y.
//
// Jar preset values come from presets/*.scad. build.py passes them with -D,
// which overrides the defaults included below (last assignment wins).
// ============================================================================
include <lib/style.scad>
include <presets/std.scad>

// ---------- assembly state (override with -D for posed exports) -------------
STATE_PULL  = 0;       // 0 = rest, 1 = full pull
DIAL_ML     = -1;      // dial setting in mL; -1 = half of max
CHUCK_CLOSE = 1;       // 0 = fully open, 1 = closed on a NECK_OD jar

// ---------- dose class ----------------------------------------------------------
// One drivetrain for every head (same pinion, rack, stroke and dial travel).
// Only the chamber's cross-section changes with the class.
// [name, V_max mL, chamber height H (= slide thickness), dial diameter]
CLASSES = [
    ["S", 20, 18, 30],
    ["M", 40, 24, 32],
    ["L", 80, 34, 36],
];
function _auto_class(mouth) = mouth >= 104 ? "L" : (mouth >= 70 ? "M" : "S");
CLASS_NAME = DOSE_CLASS == "auto" ? _auto_class(MOUTH_ID) : DOSE_CLASS;
_ci   = search([CLASS_NAME], CLASSES)[0];
V_MAX = CLASSES[_ci][1];
CH_H  = CLASSES[_ci][2];          // chamber height = slide body thickness
DIAL_D = CLASSES[_ci][3];
G_M   = 1.0;                      // gear module (all classes)
G_Z   = 12;                       // pinion teeth (all classes)
G_PA  = 25;                       // pressure angle (stub teeth, addendum 0.85 m)
G_ADD = 0.85;
G_CK  = 0.25;
CLICKS    = 40;                   // detent steps 0..CLICKS
CLICK_DEG = 7.5;                  // 40 x 7.5 = 300 deg of dial travel
DIAL_TRAVEL  = CLICKS*CLICK_DEG;
ML_PER_CLICK = V_MAX/CLICKS;
DETENT_TEETH = round(360/CLICK_DEG);   // 48 notches per revolution

G_RP  = G_M*G_Z/2;                         // pinion pitch radius
G_CD  = G_RP;                              // pinion axis -> rack pitch line
L_MAX = G_RP*DIAL_TRAVEL*PI/180;           // plunger travel = max chamber length
CH_W  = V_MAX*1000/(CH_H*L_MAX);           // width so one click == ML_PER_CLICK exactly
DIAL_SET = DIAL_ML < 0 ? V_MAX/2 : min(V_MAX, max(0, DIAL_ML));
CH_L  = DIAL_SET/V_MAX*L_MAX;              // current chamber length
DIAL_ANGLE = -DIAL_SET/ML_PER_CLICK*CLICK_DEG;   // clockwise (from above) = more

// ---------- slide / throat rules (body u) --------------------------------------
T_LEN   = L_MAX + 1.0;            // throat length along u
T_WID   = CH_W;                   // throat width along x
LAND    = 5.0;                    // seal land: strike-off edge -> drop hole
STROKE  = T_LEN + LAND;           // pull distance
PULL_D  = STATE_PULL*STROKE;
POST_D  = 4.0;                    // stir-post stem diameter
POST_PEG = 4.0;                   // square peg at the post's foot
POST_SOCKET = POST_PEG + 2*CL_PLUNGER;   // square socket in slide top (slide-local u = POST_U0)
POST_SOCKET_DEPTH = 8;
POST_U0 = -LAND - POST_D/2 - 1;   // post centre at rest; at full pull it ends 1 mm short of strike-off
SLOT_U0 = POST_U0 - POST_D/2 - 1.5;   // rear end of the post slot in the ceiling
SLOT_HW = POST_D/2 + 0.75;            // post slot half-width
KEYWAY_H = 16;                    // keyway in funnel rear wall above ceiling top (post clearance)
REAR_L  = STROKE - SLOT_U0 + 6;   // solid rear section behind the chamber rear wall
PLUNGER_L = T_LEN + 1.0;          // plunger always floors the rest of the throat
SLOT_L  = L_MAX + PLUNGER_L;      // chamber + plunger slot length
BULK_T  = 4.0;                    // bulkhead between slot and neck
SIDE_W  = 4.0;                    // slide wall beside the chamber
SLIDE_W = CH_W + 2*SIDE_W;
HOLE_U0 = STROKE - 0.5;           // drop hole rear edge (body u)
HOLE_U1 = STROKE + L_MAX + 1.0;   // drop hole front edge
HOLE_R  = 6;                      // drop hole corner radius
function hy(u) = T_LEN/2 - u;     // body u -> head y
SLIDE_Y0 = T_LEN/2 - PULL_D;      // head y of the slide's local origin (chamber rear wall)
// Slide-local frame: same axes as head, origin at chamber rear wall, slide
// extends toward -y (front). Place with translate([0, SLIDE_Y0, 0]).

// ---------- vertical stack ----------------------------------------------------
FLOOR_T = 3.0;
CL_VT   = 0.30;                   // slide top -> ceiling clearance
Z_FLOOR = FLOOR_T;                // slide running surface
Z_SLIDE_TOP = Z_FLOOR + CH_H;
Z_CEIL  = Z_SLIDE_TOP + CL_VT;    // ceiling underside == base/deck joint plane
CEIL_T  = 3.2;
Z_CEIL_TOP = Z_CEIL + CEIL_T;
FUNNEL_ANGLE = 52;                // minimum funnel wall angle from horizontal
MOUTH_R = MOUTH_ID/2 + 1;         // bore radius above the funnel (1 mm outside jar mouth)
FUNNEL_H = (MOUTH_R - T_LEN/2)*tan(FUNNEL_ANGLE);
Z_FUNNEL_TOP = Z_CEIL_TOP + FUNNEL_H;   // == hub top == guide plate bottom
GP_T    = 4.0;                    // guide plate thickness
Z_GP_BOT = Z_FUNNEL_TOP;
Z_GP_TOP = Z_GP_BOT + GP_T;
GASKET_T = 2.0;  GASKET_PROUD = 0.6;
GASKET_ID = 2*MOUTH_R;
GASKET_OD = NECK_OD - 2;
Z_RIM   = Z_GP_TOP + GASKET_PROUD;  // jar rim rests here
RING_T  = 10.0;                   // twist ring (the knurled band)
Z_RING_TOP = Z_GP_BOT - 0.3;
Z_RING_BOT = Z_RING_TOP - RING_T; // = deck flange top
SKIN_T  = 2.4;                    // puck outer wall

// ---------- chuck ---------------------------------------------------------------
CH_RANGE_D = 20;                  // grip range on diameter: NECK_OD +/- 10
PAD_T   = 2.0;                    // TPU pad thickness
PIN_OFF = 10.0;                   // jaw PLA face -> pin centre (radial)
PIN_D   = 4.0;
GROOVE_W = PIN_D + 0.5;
SCROLL_DEPTH = 3.0;
R_FACE_NOM = NECK_OD/2 + PAD_T;   // jaw PLA face radius when gripping a NECK_OD jar
R_PIN_MIN  = NECK_OD/2 - CH_RANGE_D/4 + PAD_T + PIN_OFF - 1.5;
R_PIN_MAX  = NECK_OD/2 + CH_RANGE_D/4 + PAD_T + PIN_OFF + 1.5;
R_PIN_NOM  = R_FACE_NOM + PIN_OFF;
TWIST   = 150;                    // ring twist across R_PIN_MAX -> R_PIN_MIN
SCROLL_LEAD = (R_PIN_MAX - R_PIN_MIN)*360/TWIST;   // radial advance per revolution
SCROLL_LEAD_ANGLE = atan(SCROLL_LEAD/(PI*(R_PIN_MIN + R_PIN_MAX)));
R_PIN = R_PIN_MAX - CHUCK_CLOSE*(R_PIN_MAX - R_PIN_NOM);   // current pin radius
RING_PHI = -(R_PIN_MAX - R_PIN)/SCROLL_LEAD*360;   // ring rotation (clockwise closes)
JAW_ANGLES = [270, 30, 150];      // front jaw at -y, two at the back corners
HUB_ID  = 2*MOUTH_R;
HUB_WALL = 5.0;                   // thick enough for M3 pilots (guide plate screws)
HUB_OD  = HUB_ID + 2*HUB_WALL;
RING_ID = HUB_OD + 2*CL_ROT;
RING_OD_CHUCK = 2*(R_PIN_MAX + GROOVE_W/2 + 4.0);       // what the chuck needs
// The slide's rear section (needed to keep the throat covered during a pull)
// must fit inside the puck with its corners chamfered <= 8 mm. Small jars get
// a puck sized by the slide; the ring always matches the puck (uniform family).
_rear_reach = T_LEN/2 + (STROKE - (POST_U0 - POST_D/2 - 1.5) + 6);
PUCK_D_SLIDE = 2*(sqrt(pow(_rear_reach, 2) + pow((CH_W + 8)/2 - 8, 2)) + SKIN_T + 1.5);
RING_OD = max(RING_OD_CHUCK, PUCK_D_SLIDE);
PUCK_D  = RING_OD;                // round puck, flush with the ring
PUCK_R  = PUCK_D/2;
GP_OD   = RING_OD - 4;            // guide plate sits 2 mm inside the ring's edge
GP_SCREW_R = HUB_ID/2 + HUB_WALL/2;      // M3 guide-plate screws (under the gasket)
GP_SCREW_ANGLES = [90, 210, 330];
JAW_W   = 14;                     // tangential width
JAW_H   = min(NECK_H - 1, 13);    // jaw height above guide plate
JAW_L   = PIN_OFF + 6;            // radial length (face to back)
DOVETAIL = [8, 11, 3];            // [top width, bottom width, depth] of the jaw track

// ---------- base / deck joint, rails, bands, stops --------------------------------
CHAN_HW = SLIDE_W/2 + CL_SLIDE;   // channel half width (slide guided by rails)
RAIL_H  = 4.0;  RAIL_W = 3.0;     // floor rails + ceiling rails guide the slide sides
Y_REAR_WALL = hy(-REAR_L) + 1.0;  // channel rear wall (1 mm behind slide at rest)
// Slide rear corners are chamfered so the slide always fits inside the puck.
_rear_y = hy(-REAR_L);                         // slide rear end at rest (head y)
_inner_r = PUCK_R - SKIN_T - 1.5;
SLIDE_REAR_CHAMFER = max(2, SLIDE_W/2 - sqrt(max(1, _inner_r*_inner_r - _rear_y*_rear_y)) + 1);
// Return bands: hook on each slide side near the FRONT of the slide's in-puck
// part, band runs backward beside the slide to an anchor near the back of the
// puck. Pulling stretches it. (TPU loop, or a hair tie / rubber band.)
BAND_X  = CHAN_HW + RAIL_W + 3.0;      // band centreline |x|
U_HOOK_S = T_LEN/2 + (PUCK_R - SKIN_T - 5) - STROKE;   // slide-local u of side hooks (stays inside puck at full pull)
Y_BAND_ANCHOR = sqrt(max(1, pow(PUCK_R - SKIN_T - 6, 2) - BAND_X*BAND_X)) - 4;   // rear anchors (head y), x = +/-BAND_X
BAND_SPAN_REST = Y_BAND_ANCHOR - hy(U_HOOK_S);         // hook -> rear post at rest
// Low-strain TPU routing: hook -> around the REAR POST (pulley) -> forward to a
// FRONT ANCHOR on the outside of the post. A hair tie / rubber band instead
// just loops hook <-> rear post (rubber tolerates the higher strain).
BAND_POST_D = 10;                                       // rear post diameter
BAND_X_OUT  = BAND_X + BAND_POST_D;                     // outer strand |x|
Y_BAND_FRONT = -sqrt(max(1, pow(PUCK_R - SKIN_T - 7, 2) - BAND_X_OUT*BAND_X_OUT)) + 3;  // front anchor head y
BAND_PATH_REST = BAND_SPAN_REST + PI*BAND_POST_D/2 + (Y_BAND_ANCHOR - Y_BAND_FRONT);
BAND_STRAIN_ADD = STROKE/BAND_SPAN_REST;                // direct (rubber) routing
BAND_STRAIN_ADD_TPU = STROKE/BAND_PATH_REST;            // pulley routing
U_STOP  = -9;                     // stop pin (body u); rides a groove in slide underside
STOP_D  = 5.0;
STOP_GROOVE = [U_STOP - STROKE - STOP_D/2 - 0.3, U_STOP + STOP_D/2 + 0.3];  // slide-local u range
JOIN_SCREWS = [[-PUCK_R+16, -28], [PUCK_R-16, -28], [-PUCK_R+16, 30], [PUCK_R-16, 30]];  // head x,y; M3 from below
DOCK_PINS = [[-PUCK_R+20, 26], [PUCK_R-20, 26]];   // locating holes in head bottom (pins on bay)
DOCK_PIN_D = 6.0;

// ---------- drawer front / dial --------------------------------------------------
REVEAL_H  = 1.5;                  // gap puck face -> drawer front at rest
U_PUCK_FRONT_S = PUCK_R + T_LEN/2;        // puck front, slide-local u at rest
U_HANDLE0 = U_PUCK_FRONT_S + REVEAL_H;    // drawer front starts here (slide-local u)
U_DIAL    = U_HANDLE0 + DIAL_D/2 + 2.5;   // dial/pinion axis (slide-local u)
RACK_FWD  = 1.6*PI*G_M;           // rack teeth beyond pinion axis at 0 mL
U_ROD_FRONT0 = U_DIAL + RACK_FWD; // rod front end at 0 mL (slide-local u)
HANDLE_L  = (U_ROD_FRONT0 + L_MAX + 3) - U_HANDLE0;
HANDLE_W  = SLIDE_W + 6;
Z_ROD   = Z_FLOOR + CH_H/2;       // rack/pinion mid-plane
ROD_H   = min(8, CH_H - 8);       // rack rod height (z)
RACK_BACK = 3.5;                  // rack body behind tooth roots
ROD_X0  = G_CD - G_M*G_ADD;                       // rack tooth tips (face the pinion)
ROD_X1  = G_CD + G_M*(G_ADD + G_CK) + RACK_BACK;  // back of the rack rod
ROD_CL  = 0.35;                   // rod tunnel clearance per side
X_RACK_PITCH = G_CD;              // rack pitch line at x = +G_CD (rack on pinion's right)
PIN_FW  = ROD_H;                  // pinion face width
DIAL_H  = 11;
Z_DIAL_BOT = Z_SLIDE_TOP + 0.4;
DIAL_SHAFT_D = 2*(G_RP - G_M*(G_ADD + G_CK)) - 1;   // shaft fits inside pinion root
STOP_TAB_ANGLE = 330;             // dial hard-stop post sits in the unused 60 deg
Z_HANDLE_TOP = Z_SLIDE_TOP;       // drawer front top is flush with the slide top
HANDLE_Z0 = 0.8;                  // drawer front bottom clears the bay plate (z=0)
NAME_PLATE = [HANDLE_W - 10, 12, 1.6];   // [w, h, t] recess on the drawer front face

// ---------- bar (modular bench) ----------------------------------------------------
SHAKER_H = 220;                   // your shaker bottle WITHOUT lid (or tallest cup), mm
BAR_H    = SHAKER_H + 12;         // top of bay plate above the counter
BAY_W    = max(PUCK_D, BODY_OD) + 12;
BAY_D    = PUCK_D + 24;
BAY_T    = 6;

// (the dimension report echo lives in dosebar.scad so it prints once)
