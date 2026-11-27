// ============================================================================
// Dose Bar v5 — entry point. Select what to render with -D 'PART="..."'.
//   PART="assembly"        whole head (+ jar ghost) in the current state
//   PART="<name>"          one part, in PRINT orientation (for STL export)
//   PART="posed:<name>"    one part, in ASSEMBLED pose (for fit checks)
//   PART="row"             ROW_N heads on pedestals, lined up
// State: -D STATE_PULL=0..1  -D DIAL_ML=<mL>  -D CHUCK_CLOSE=0..1
// Jar:   tools/build.py passes the preset values with -D.
// ============================================================================
include <params.scad>
include <parts/base.scad>
include <parts/deck.scad>
include <parts/slide.scad>
include <parts/plunger.scad>
include <parts/dial.scad>
include <parts/lock_ring.scad>
include <parts/dial_spring.scad>
include <parts/wiper.scad>
include <parts/wand.scad>
include <parts/name_plate.scad>
include <parts/ring.scad>
include <parts/guide_plate.scad>
include <parts/jaw.scad>
include <parts/jaw_pad.scad>
include <parts/gasket.scad>
include <parts/pedestal.scad>
include <parts/dose_drawer.scad>
include <parts/foot.scad>
include <parts/coupon.scad>

// dimension report
echo(str("[dosebar] ", JAR_NAME, " class ", CLASS_NAME, " 0-", V_MAX, " mL @ ", ML_PER_CLICK,
    " mL/click | chamber ", CH_W, " x ", CH_H, " x ", L_MAX, " | throat ", T_WID, " x ", T_LEN,
    " | stroke ", STROKE, " (seal window ", SEAL_WINDOW, ") | collar D ", PUCK_D, " | pill ", PUCK_D, " x ", PILL_LEN,
    " (y ", PILL_Y_FRONT, "..", PILL_Y_REAR, ") | rim z ", Z_RIM, " | handle L ", HANDLE_L,
    " | slide L ", REAR_L + U_HANDLE0 + HANDLE_L, " | pedestal H ", PED_H,
    " | scroll lead ", SCROLL_LEAD, " / ", SCROLL_LEAD_ANGLE, " deg"));
assert(SEAL_WINDOW >= 5, "sealed transit: chamber must be closed on top before it reaches the drop hole");

PART = "assembly";
ROW_N = 3;              // heads shown by PART="row"
NAME = "WHEY";
SHOW_JAR = true;

// Part registry: [name, material, qty per head (or per bay), color]
PARTS = [
    ["base",        "PLA", 1, "body"],
    ["stop_sleeve", "TPU", 4, "tpu"],
    ["deck",        "PLA", 1, "body"],
    ["wiper",       "TPU", 1, "tpu"],
    ["wand",        "PLA", 1, "accent"],
    ["wand_arm",    "PLA", 1, "accent"],
    ["slide",       "PLA", 1, "body"],
    ["drawer_front","PLA", 1, "body"],
    ["plunger",     "PLA", 1, "accent"],
    ["dial",        "PLA", 1, "accent"],
    ["dial_inlay",  "PLA", 1, "ink"],
    ["lock_ring",   "PLA", 1, "accent"],
    ["dial_spring", "TPU", 1, "tpu"],
    ["name_plate",  "PLA", 1, "accent"],
    ["name_inlay",  "PLA", 1, "ink"],
    ["ring",        "PLA", 1, "accent"],
    ["guide_plate", "PLA", 1, "body"],
    ["jaw",         "PLA", 3, "accent"],
    ["jaw_pad",     "TPU", 3, "tpu"],
    ["gasket",      "TPU", 1, "tpu"],
    ["pedestal",    "PLA", 1, "body"],
    ["dose_drawer", "PLA", 1, "body"],
    ["joiner",      "PLA", 1, "body"],
    ["foot",        "TPU", 4, "tpu"],
];
COLORS = [["body", "#ECE8DF"], ["accent", "#2F3237"], ["ink", "#ECE8DF"], ["tpu", "#3A3D42"]];
function _col(k) = COLORS[search([k], COLORS)[0]][1];
function _pcol(n) = _col(PARTS[search([n], PARTS)[0]][3]);

module posed(name) {
    if      (name == "base")        base();
    else if (name == "stop_sleeve") stop_sleeve();
    else if (name == "deck")        deck();
    else if (name == "wiper")       wiper();
    else if (name == "wand")        wand();
    else if (name == "wand_arm")    wand_arm();
    else if (name == "slide")       slide();
    else if (name == "drawer_front") drawer_front();
    else if (name == "plunger")     plunger();
    else if (name == "dial")        dial();
    else if (name == "dial_inlay")  dial_inlay();
    else if (name == "lock_ring")   lock_ring();
    else if (name == "dial_spring") dial_spring();
    else if (name == "name_plate")  name_plate(NAME);
    else if (name == "name_inlay")  name_inlay(NAME);
    else if (name == "ring")        ring();
    else if (name == "guide_plate") guide_plate();
    else if (name == "jaw")         for (i=[0:2]) jaw(i);
    else if (name == "jaw_pad")     for (i=[0:2]) jaw_pad(i);
    else if (name == "jaw0")        jaw(0);
    else if (name == "jaw1")        jaw(1);
    else if (name == "jaw2")        jaw(2);
    else if (name == "jaw_pad0")    jaw_pad(0);
    else if (name == "jaw_pad1")    jaw_pad(1);
    else if (name == "jaw_pad2")    jaw_pad(2);
    else if (name == "gasket")      gasket();
    else if (name == "pedestal")    pedestal();
    else if (name == "dose_drawer") dose_drawer();
    else if (name == "foot")        foot();
    else if (name == "jar")         jar_ghost();
}
module printed(name) {
    if      (name == "base")        base_print();
    else if (name == "stop_sleeve") stop_sleeve_print();
    else if (name == "deck")        deck_print();
    else if (name == "wiper")       wiper_print();
    else if (name == "wand")        wand_print();
    else if (name == "wand_arm")    wand_arm_print();
    else if (name == "slide")       slide_print();
    else if (name == "drawer_front") drawer_front_print();
    else if (name == "plunger")     plunger_print();
    else if (name == "dial")        dial_print();
    else if (name == "dial_inlay")  dial_inlay_print();
    else if (name == "lock_ring")   lock_ring_print();
    else if (name == "dial_spring") dial_spring_print();
    else if (name == "name_plate")  name_plate_print(NAME);
    else if (name == "name_inlay")  name_inlay_print(NAME);
    else if (name == "ring")        ring_print();
    else if (name == "guide_plate") guide_plate_print();
    else if (name == "jaw")         jaw_print();
    else if (name == "jaw_pad")     jaw_pad_print();
    else if (name == "gasket")      gasket_print();
    else if (name == "pedestal")    pedestal_print();
    else if (name == "dose_drawer") dose_drawer_print();
    else if (name == "joiner")      joiner_print();
    else if (name == "foot")        foot_print();
    else if (name == "coupon")      coupon_print();
    else if (name == "coupon_parts") coupon_parts_print();
    else if (name == "coupon_inlay") coupon_inlay_print();
}
// Simple jar ghost: neck + shoulder + body, upside down on the rim.
module jar_ghost() {
    translate([0,0,Z_RIM]) rotate_extrude($fn=96) polygon([
        [MOUTH_ID/2, 0], [NECK_OD/2, 0], [NECK_OD/2, NECK_H], [BODY_OD/2, NECK_H + 18],
        [BODY_OD/2, JAR_H - 12], [BODY_OD/2 - 8, JAR_H - 2], [0, JAR_H - 2], [0, JAR_H - 6],
        [BODY_OD/2 - 11, JAR_H - 6], [BODY_OD/2 - 3, JAR_H - 14], [BODY_OD/2 - 3, NECK_H + 19],
        [NECK_OD/2 - 3, NECK_H + 2], [MOUTH_ID/2, NECK_H]]);
}
module head_assembly() {
    for (p = PARTS) if (p[0] != "joiner")
        color(_pcol(p[0])) posed(p[0]);
    if (SHOW_JAR) %jar_ghost();
}
if (PART == "assembly") head_assembly();
else if (PART == "row") row_assembly(ROW_N);
else if (len(PART) > 6 && PART[0]=="p" && PART[1]=="o" && PART[2]=="s" && PART[3]=="e" && PART[4]=="d" && PART[5]==":")
    posed([for (i=[6:len(PART)-1]) PART[i]][0] == undef ? "" : str_join([for (i=[6:len(PART)-1]) PART[i]]));
else printed(PART);
function str_join(v, i=0) = i >= len(v) ? "" : str(v[i], str_join(v, i+1));
