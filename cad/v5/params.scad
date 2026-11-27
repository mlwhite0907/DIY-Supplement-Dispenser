// ============================================================================
// Dose Bar v5.1 — MASTER PARAMETERS + INTERFACE DATUMS
// Every part file includes this. Nothing about a part's mating features may be
// hard-coded in the part: take it from here so all parts always fit.
//
// HEAD COORDINATES (assembled):  x = user's right, y = AWAY from the user
// (front of the head is -y, like OpenSCAD's front view), z = up.
//   Origin: jar axis, at the head's bottom face (= underside of channel floor).
//   The jar sits upside down on top of the head; the head sits on its pedestal
//   (pedestal occupies z < 0).
//
// "u" = distance along the PULL direction (toward the user, u = -y).
//   Body u = 0 is the throat's REAR edge. The throat spans u in [0, T_LEN].
//   hy(u) converts body u to head y.
//
// v5.1 (design-review fixes): sealed transit (long stroke), push-pull drawer
// (no springs), locking dial, mirrored chuck (closes like a lid when refilling),
// 0.2 mm Z grid, pill-shaped body, pedestal + dose drawer, bundled fonts.
//
// Jar preset values come from presets/*.scad. build.py passes them with -D,
// which overrides the defaults included below (last assignment wins).
// ============================================================================
include <lib/style.scad>
include <presets/std.scad>
use <fonts/Inter-Bold.otf>
use <fonts/Inter-SemiBold.otf>
use <fonts/Inter-Medium.otf>

LH = 0.2;                                  // print layer height; Z datums sit on this grid
function zq(z) = ceil(z/LH - 1e-6)*LH;     // round a height UP to the layer grid
TXT_K = 1.0105;                            // Inter cap height = TXT_K * text size (measured)
function txt_size(cap) = cap/TXT_K;
FONT_BOLD = "Inter:style=Bold";
FONT_SEMI = "Inter:style=SemiBold";

// ---------- assembly state (override with -D for posed exports) -------------
STATE_PULL  = 0;       // 0 = drawer home (pushed in), 1 = pulled out to the stop
DIAL_ML     = -1;      // dial setting in mL; -1 = half of max
CHUCK_CLOSE = 1;       // 0 = fully open, 1 = closed on a NECK_OD jar
DRAWER_OUT  = 0;       // dose drawer: 0 = in, 1 = slid out

// ---------- dose class ----------------------------------------------------------
// One drivetrain for every head (same pinion, rack and dial). The chamber's
// cross-section changes with the class, and so does the minimum throat length.
// Pick the class from the TARGET DOSE (docs/v5/DIAL_SETTINGS.md), not the jar:
//   S: doses <= 18 mL   M: 18-38 mL   L: > 38 mL (protein, big collagen)
// [name, V_max mL, chamber height H (= slide thickness), min throat length]
CLASSES = [
    ["S", 20, 18, 30],
    ["M", 40, 24, 30],
    ["L", 80, 34, 40],
];
function _auto_class(mouth) = mouth >= 104 ? "L" : (mouth >= 70 ? "M" : "S");
CLASS_NAME = DOSE_CLASS == "auto" ? _auto_class(MOUTH_ID) : DOSE_CLASS;
_ci   = search([CLASS_NAME], CLASSES)[0];
V_MAX = CLASSES[_ci][1];
CH_H  = CLASSES[_ci][2];          // chamber height = slide body thickness (multiple of LH)
T_MIN = CLASSES[_ci][3];
G_M   = 1.0;                      // gear module (all classes)
G_Z   = 12;                       // pinion teeth (all classes)
G_PA  = 25;                       // pressure angle (stub teeth, addendum 0.85 m)
G_ADD = 0.85;
G_CK  = 0.25;
CLICKS    = 40;                   // dial positions 0..CLICKS
CLICK_DEG = 7.5;                  // 40 x 7.5 = 300 deg of dial travel
DIAL_TRAVEL  = CLICKS*CLICK_DEG;
ML_PER_CLICK = V_MAX/CLICKS;
LOCK_TEETH   = round(360/CLICK_DEG);   // 48 lock teeth per revolution
DETENT_TEETH = LOCK_TEETH;             // (legacy name)

G_RP  = G_M*G_Z/2;                         // pinion pitch radius
G_CD  = G_RP;                              // pinion axis -> rack pitch line
L_MAX = G_RP*DIAL_TRAVEL*PI/180;           // plunger travel = max chamber length (31.4)
CH_W  = V_MAX*1000/(CH_H*L_MAX);           // width so one click == ML_PER_CLICK exactly
DIAL_SET = DIAL_ML < 0 ? V_MAX/2 : min(V_MAX, max(0, DIAL_ML));
CH_L  = DIAL_SET/V_MAX*L_MAX;              // current chamber length
DIAL_ANGLE = -DIAL_SET/ML_PER_CLICK*CLICK_DEG;   // clockwise (from above) = more
DIAL_ZERO_GAP = 0.10;                      // plunger stops 0.1 mm off the rear wall at 0 (dial stop does it)

// ---------- slide / throat: SEALED TRANSIT (body u) ------------------------------
// The chamber must be closed at the top (past the strike-off edge) BEFORE any
// part of it reaches the drop hole. So the land from the strike-off edge to
// the drop hole is at least L_MAX + LAND, and the stroke carries the whole
// chamber across it. (Draft 0 had a 5 mm land: powder could pour through.)
T_LEN   = max(L_MAX + 1.0, T_MIN);   // throat length along u (>= 30 / 40 mm for flow)
T_WID   = CH_W;                      // throat width along x
LAND    = 5.0;                       // closed window between top-seal and drop hole
OVERTRAVEL = 3.0;
STROKE  = T_LEN + L_MAX + LAND + OVERTRAVEL;   // pull distance (~72 / ~80 mm)
PULL_D  = STATE_PULL*STROKE;
HOLE_U0 = T_LEN + L_MAX + LAND;      // drop hole rear edge
HOLE_U1 = STROKE + L_MAX + 1.0;      // drop hole front edge
HOLE_R  = 4;                         // drop hole corner radius (rear 3 mm square-cornered)
SEAL_WINDOW = HOLE_U0 - (T_LEN + L_MAX);   // = LAND (asserted >= 5)
REAR_L  = STROKE + 6;                // solid rear section keeps the throat covered at full pull
PLUNGER_L = T_LEN + 1.0;             // plunger always floors the rest of the throat
SLOT_L  = L_MAX + PLUNGER_L;         // chamber + plunger slot length
BULK_T  = 4.0;                       // bulkhead between slot and neck
SIDE_W  = 4.0;                       // slide wall beside the chamber
SLIDE_W = CH_W + 2*SIDE_W;
SLIDE_REAR_CHAMFER = 8;              // plan chamfer on the slide's rear corners
function hy(u) = T_LEN/2 - u;        // body u -> head y
SLIDE_Y0 = T_LEN/2 - PULL_D;         // head y of the slide-local origin (chamber rear wall)
// Slide-local frame: same axes as head, origin at chamber rear wall, slide
// extends toward -y (front). Place with translate([0, SLIDE_Y0, 0]).

// ---------- vertical stack (0.2 mm grid) -------------------------------------------
FLOOR_T = 3.0;
CL_VT   = 0.20;                   // slide top -> ceiling (one layer); slide rides on the floor
Z_FLOOR = FLOOR_T;                // slide running surface
Z_SLIDE_TOP = Z_FLOOR + CH_H;
Z_CEIL  = Z_SLIDE_TOP + CL_VT;    // ceiling underside == base/deck joint plane
CEIL_T  = 3.2;
Z_CEIL_TOP = Z_CEIL + CEIL_T;
FUNNEL_ANGLE = 52;                // minimum wall angle (front/back walls are the shallowest)
MOUTH_R = MOUTH_ID/2 + 1;         // bore radius above the funnel (1 mm outside jar mouth: no ledge)
FUNNEL_H = zq((MOUTH_R - T_LEN/2)*tan(FUNNEL_ANGLE));
Z_FUNNEL_TOP = Z_CEIL_TOP + FUNNEL_H;   // == hub top == guide plate bottom
GP_T    = 4.0;                    // guide plate thickness
Z_GP_BOT = Z_FUNNEL_TOP;
Z_GP_TOP = Z_GP_BOT + GP_T;
// Gasket: 1.2 mm flange in a pocket (with a 0.3 mm undercut lip) + a 0.8 x 3.0 mm
// sealing lip leaning 30 deg outward; the jar rim compresses it to ~2.0 mm.
GASKET_POCKET = 1.2;  GASKET_FLANGE_T = 1.2;  GASKET_LIP = [0.8, 3.0, 30];
GASKET_ID = 2*MOUTH_R;
GASKET_OD = NECK_OD - 2;
GASKET_T  = GASKET_FLANGE_T;      // (legacy name)
GASKET_PROUD = 2.0;               // rim height above the guide plate, lip compressed
Z_RIM   = Z_GP_TOP + GASKET_PROUD;  // jar rim rests here
RING_T  = 14.0;                   // twist ring: a 13 mm fluted grip band
Z_RING_TOP = Z_GP_BOT - 0.4;      // two layers of axial play
Z_RING_BOT = Z_RING_TOP - RING_T; // = deck ring seat
SKIN_T  = 2.0;                    // body outer wall

// ---------- chuck (rigid self-locking centring fixture) --------------------------
// Twisting the ring CLOSES the jaws when turned COUNTER-clockwise seen from +z
// in head coordinates = CLOCKWISE for the user in the refill pose (jar upright,
// head on top), exactly like tightening a lid. 110 deg from open to closed.
CH_RANGE_D = 20;                  // grip range on diameter: NECK_OD +/- 10
PAD_T   = 1.2;                    // TPU skin (slip-on boot) on each rigid jaw
PIN_OFF = 10.0;                   // jaw PLA face -> pin centre (radial)
PIN_D   = 6.0;                    // D-section pin, jaw printed on its side
GROOVE_W = 6.5;
SCROLL_DEPTH = 5.0;
R_FACE_NOM = NECK_OD/2 + PAD_T;   // jaw PLA face radius when gripping a NECK_OD jar
R_PIN_MIN  = NECK_OD/2 - CH_RANGE_D/4 + PAD_T + PIN_OFF;
R_PIN_MAX  = NECK_OD/2 + CH_RANGE_D/4 + PAD_T + PIN_OFF;
R_PIN_NOM  = R_FACE_NOM + PIN_OFF;
TWIST   = 110;                    // ring rotation across R_PIN_MAX -> R_PIN_MIN (groove ends = stops)
SCROLL_LEAD = (R_PIN_MAX - R_PIN_MIN)*360/TWIST;   // radial advance per revolution
SCROLL_LEAD_ANGLE = atan(SCROLL_LEAD/(PI*(R_PIN_MIN + R_PIN_MAX)));
CHUCK_CLOSE_DIR = +1;             // +1 = closing turns CCW about +z (head coordinates)
R_PIN = R_PIN_MAX - CHUCK_CLOSE*(R_PIN_MAX - R_PIN_NOM);   // current pin radius
RING_PHI = CHUCK_CLOSE_DIR*(R_PIN_MAX - R_PIN)/SCROLL_LEAD*360;   // ring rotation (deg, CCW +)
JAW_ANGLES = [270, 30, 150];      // front jaw at -y on the centre plane, two at the back
HUB_ID  = 2*MOUTH_R;
HUB_WALL = 5.0;                   // M3 pilots for the guide plate sit in hub bosses
HUB_OD  = HUB_ID + 2*HUB_WALL;
RING_ID = HUB_OD + 2*CL_ROT;
RING_OD_CHUCK = 2*(R_PIN_MAX + GROOVE_W/2 + 4.5);
PUCK_D  = RING_OD_CHUCK;          // round chuck collar / ring diameter
PUCK_R  = PUCK_D/2;
RING_OD = PUCK_D;
GP_OD   = RING_OD - 4;            // guide plate sits 2 mm inside the ring's edge
GP_SCREW_R = HUB_ID/2 + HUB_WALL/2;
GP_SCREW_ANGLES = [90, 210, 330];
JAW_W   = 14;
JAW_H   = min(NECK_H - 1, 13);
JAW_L   = PIN_OFF + 6;
DOVETAIL = [8, 11, 3];            // (legacy) jaw track; v5.1 jaws use a T-foot under the plate

// ---------- body footprint: a PILL (stadium) ------------------------------------------
// The sealed-transit stroke needs more length than a Ø PUCK_D circle gives, so
// the base, the deck's lower skin and the pedestal share one pill outline:
// two semicircles of radius PUCK_R centred at y = PILL_YC_FRONT and PILL_YC_REAR,
// joined by straight sides at x = +/-PUCK_R. The round chuck collar sits on it.
_r_in    = PUCK_R - SKIN_T - 1.5;
_rear_y  = hy(-REAR_L) + 1.0;
_rear_x  = SLIDE_W/2 - SLIDE_REAR_CHAMFER;
PILL_YC_REAR  = max(0, _rear_y - sqrt(max(1, _r_in*_r_in - _rear_x*_rear_x)));
_hole_y  = hy(HOLE_U1) - 3;
_hole_x  = CH_W/2 + 3;
PILL_YC_FRONT = min(0, _hole_y + sqrt(max(1, _r_in*_r_in - _hole_x*_hole_x)));
PILL_Y_FRONT  = PILL_YC_FRONT - PUCK_R;
PILL_Y_REAR   = PILL_YC_REAR + PUCK_R;
PILL_LEN      = PILL_Y_REAR - PILL_Y_FRONT;
module pill_2d(inset=0) {
    hull() {
        translate([0, PILL_YC_FRONT]) circle(r=PUCK_R - inset, $fn=192);
        translate([0, PILL_YC_REAR])  circle(r=PUCK_R - inset, $fn=192);
    }
}

// ---------- channel, stops, seals ----------------------------------------------------
CHAN_HW = SLIDE_W/2 + CL_SLIDE;   // channel half width
RAIL_W  = 3.0;                    // channel wall thickness (full height Z_FLOOR..Z_CEIL)
Y_REAR_WALL = hy(-REAR_L) + 1.0;  // channel rear wall (1 mm behind the slide at home)
// Push-pull: no springs. Two M4 screws (from below, through the floor) wear TPU
// sleeves in the side channels; a lug at the slide's rear corners stops on them
// at full pull (front sleeves) and at home (rear sleeves). Remove the two front
// screws to take the slide out for washing.
STOP_X       = CHAN_HW + RAIL_W + 5.0;    // |x| of the stop screws (side channels)
STOP_SLEEVE  = [4.2, 10.0, 6.0];          // TPU sleeve [ID, OD, height]
STOP_LUG     = [5.0, 6.0];                // lug on the slide's rear corners [x reach, u length]
STOP_U_FRONT = -REAR_L + STOP_LUG[1] + STROKE + STOP_SLEEVE[1]/2;   // body u of front sleeve centres
STOP_U_REAR  = -REAR_L - STOP_SLEEVE[1]/2;                          // body u of rear sleeve centres
HOME_DETENT_HOLD = 3;             // N: a light detent keeps the drawer home
// Rear + side U-seal: TPU blade 0.8 thick, 3.0 free length, 0.30 interference,
// leaning 30 deg toward the throat, bulb in a dovetail groove in the ceiling.
WIPER_BLADE = [0.8, 3.0, 0.30, 30];
WIPER_GROOVE = [2.0, 2.9, 4.5];   // [mouth width, inner width, depth]
WIPER_OFFSET = 2.5;               // groove centreline from the throat's rear/side edges
JOIN_SCREWS = [[-PUCK_R+16, -28], [PUCK_R-16, -28], [-PUCK_R+16, 30], [PUCK_R-16, 30]];  // (legacy)
DOCK_PINS = [[-PUCK_R+20, PILL_YC_REAR + 10], [PUCK_R-20, PILL_YC_REAR + 10]];
DOCK_PIN_D = 6.0;

// ---------- agitator (rocker wand, recommended for whey, collagen, BCAA,
//            pre-workouts, psyllium) --------------------------------------------------
// A loop wand pivots on an axle through the funnel's +x wall and is driven by a
// pin on the slide via a cam arm. It DWELLS while the chamber is filling or
// being struck off (u in [0, T_LEN]) and swings ~45 deg only while the throat is
// covered (u in [T_LEN, STROKE]).
WAND_SIDE   = +1;                             // axle enters through the +x funnel wall
WAND_AXLE_Z = zq(Z_CEIL_TOP + 12);            // axle height
WAND_AXLE_Y = 0;                              // over the jar axis
WAND_PIN    = [SLIDE_W/2, -REAR_L + 14, Z_FLOOR + 3];   // [x, slide-local u, z] M3 pin on the slide side
WAND_SWING  = 45;

// ---------- drawer front / locking dial --------------------------------------------
REVEAL    = 1.0;                  // the one visible gap everywhere
REVEAL_H  = REVEAL;
// The drawer front's rear face is concave, radius PUCK_R + REVEAL, concentric
// with the pill's front semicircle, so the gap to the body is uniform.
U_PUCK_FRONT_S = T_LEN/2 - PILL_Y_FRONT;      // body front (x = 0), slide-local u at home
U_HANDLE0 = U_PUCK_FRONT_S + REVEAL;          // drawer front starts here (slide-local u, x = 0)
DIAL_D    = 36;                   // one dial on every head
DIAL_H    = 13;
U_DIAL    = U_HANDLE0 + DIAL_D/2 + 3.0;       // dial/pinion axis (slide-local u)
RACK_FWD  = 1.6*PI*G_M;           // rack teeth beyond pinion axis at 0 mL
U_ROD_FRONT0 = U_DIAL + RACK_FWD; // rod front end at 0 mL (slide-local u)
HANDLE_L  = (U_ROD_FRONT0 + L_MAX + 3) - U_HANDLE0;
HANDLE_W  = SLIDE_W + 6;
// The slide is printed as TWO parts (bed fit): the slide body and the drawer
// front, joined just inside the body face by a dovetail + 2 x M3 from below.
SLIDE_SPLIT_U = U_HANDLE0 - 6;    // slide-local u of the joint plane
Z_ROD   = Z_FLOOR + CH_H/2;       // rack/pinion mid-plane
ROD_H   = 8;                      // rack face height
RACK_BACK = 3.5;
ROD_X0  = G_CD - G_M*G_ADD;
ROD_X1  = G_CD + G_M*(G_ADD + G_CK) + RACK_BACK;
ROD_CL  = 0.35;
X_RACK_PITCH = G_CD;              // rack on the pinion's right (+x), teeth face -x
// Locking dial: dial knob + Ø DIAL_SHAFT_D shaft + pinion are ONE part (the
// pinion's tip circle fits inside the shaft, so it drops in from above).
// A 48-tooth face crown under the dial meshes with the lock ring in the well:
// 1.0 mm locking height, flanks 5 deg off axial (self-locking in PLA), 0.4 mm
// lead-in chamfer. Lift LOCK_LIFT to turn. A TPU crush tube under the M3
// retaining screw (from below) pulls the dial down: 3-5 N home, <= 8 N lifted.
// Change the dose with the drawer PULLED OUT (chamber empty).
LOCK_TOOTH_H = 1.0;  LOCK_FLANK = 5;  LOCK_CHAMFER = 0.4;  LOCK_LIFT = 1.6;
LOCK_R = [12.0, 17.0];            // crown radial band under the dial
CRUSH_TUBE = [8.0, 5.4, 6.0];     // TPU [OD, ID, length]
DIAL_SHAFT_D = 15;
PIN_FW  = ROD_H + LOCK_LIFT + 0.5;   // pinion face so the rack stays meshed when lifted
DIAL_WELL_D     = DIAL_D + 1.2;
DIAL_WELL_DEPTH = 2.0;
DIAL_WELL_KEYS  = [90, 270];
DIAL_WELL_KEY   = [3.0, 1.5];
LOCK_RING_T     = DIAL_WELL_DEPTH;   // PLA lock ring fills the well, teeth on top
STOP_TAB_ANGLE  = 330;            // dial hard-stop sits in the unused 60 deg (CCW from +x, dial axis)
STOP_POST = [DIAL_D/2 - 4.0, 4.0, 4.0];   // [radius, dia, height >= LOCK_LIFT + 2]: stops work lifted too
Z_DIAL_BOT = Z_SLIDE_TOP + 0.6;
PINION_CAVITY_R = G_RP + G_M*G_ADD + 0.8;
Z_HANDLE_TOP = Z_SLIDE_TOP;
HANDLE_Z0 = 1.0;                  // drawer front bottom: 1 mm above the pedestal's top
NAME_PLATE = [HANDLE_W - 10, 12, 1.6];
CL_PLUNGER = 0.15;                // plunger in its slot (overrides style token for v5.1)
PLUNGER_TONGUE = [1.6, 1.6];      // side tongues in slot-wall grooves; plunger hangs 0.2 mm off the floor

// ---------- pedestal + dose drawer -------------------------------------------------
// Pull the dose handle out to its stop: one dose drops into the DOSE DRAWER in
// the pedestal. Push the handle home. Slide the dose drawer out and pour.
PED_TOP_T   = 3.0;
CUP_WALL    = 2.0;
CUP_FLOOR_T = 2.0;
CUP_IN_H    = 36;
CUP_TOP_Z   = -PED_TOP_T - 1.0;
CUP_BOT_Z   = CUP_TOP_Z - CUP_IN_H - CUP_FLOOR_T;
PED_FLOOR_T = 3.0;
PED_H       = zq(-CUP_BOT_Z + 0.6 + PED_FLOOR_T);
CUP_W       = HANDLE_W;
CUP_Y_REAR  = hy(HOLE_U0) + 8;
CUP_Y_FRONT = T_LEN/2 - (U_HANDLE0 + HANDLE_L);   // lines up with the handle's front at home
CUP_FRONT_TOP_Z = -1.0;
PED_HOLE    = [CH_W + 3, (HOLE_U1 - HOLE_U0) + 3];
PED_HOLE_Y  = (hy(HOLE_U0) + hy(HOLE_U1))/2;
FEET_T      = 2.5;
PED_GAP     = 6;
JOINER_Y    = (PILL_YC_FRONT + PILL_YC_REAR)/2;
ROW_PITCH   = PUCK_D + PED_GAP;

// (the dimension report echo lives in dosebar.scad so it prints once)
