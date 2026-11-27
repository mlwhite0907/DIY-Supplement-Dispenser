// ============================================================================
// Dose Bar v6 — entry point. Select what to render with -D 'PART="..."'.
//   PART="assembly"        whole head on its tub (+ jar ghost) in the current state
//   PART="<name>"          one part, in PRINT orientation (for STL export)
//   PART="posed:<name>"    one part, in ASSEMBLED pose (for fit checks and the viewer)
// State: -D STATE_PULL=0..1  -D DIAL_ML=<mL>  -D CHUCK_CLOSE=0..1  -D DRAWER_OUT=0..1
// Jar:   tools/build.py passes the preset values with -D.
// ============================================================================
include <params.scad>
include <lib/gears.scad>
include <lib/scroll.scad>
include <parts/chassis.scad>
include <parts/slide.scad>
include <parts/plunger.scad>
include <parts/dial.scad>
include <parts/funnel.scad>
include <parts/shell.scad>
include <parts/chuck.scad>
include <parts/tub.scad>
include <parts/scoop.scad>
include <parts/wand.scad>
include <parts/soft.scad>
include <parts/coupon.scad>

PART = "assembly";
NAME = "WHEY";
SHOW_JAR = true;

echo(str("[dosebar] ", JAR_NAME, " class ", CLASS_NAME, " 0-", V_MAX, " mL @ ", ML_PER_CLICK,
    " mL/click | chamber ", CH_W, " x ", CH_H, " x ", L_MAX, " | throat ", T_WID, " x ", T_LEN,
    " | stroke ", STROKE, " (seal window ", SEAL_WINDOW, ") | body ", BODY_W, " x ", BODY_LEN,
    " | rim z ", Z_RIM, " | tub H ", PED_H, " | scroll lead ", SCROLL_LEAD, " / ", SCROLL_LEAD_ANGLE, " deg"));
assert(SEAL_WINDOW >= 5, "sealed transit: the chamber must be closed on top before it reaches the drop hole");
assert(REAR_L >= STROKE + 5, "the rear section must keep the throat covered at full pull");

// Part registry: [name, material, qty per head, color role]
PARTS = [
    ["tub",         "PLA", 1, "body"],
    ["scoop",       "PLA", 1, "body"],
    ["chassis",     "PLA", 1, "body"],
    ["funnel",      "PLA", 1, "body"],
    ["shell",       "PLA", 1, "body"],
    ["slide",       "PLA", 1, "body"],
    ["plunger",     "PLA", 1, "body"],
    ["dial",        "PLA", 1, "accent"],
    ["dial_inlay",  "PLA", 1, "ink"],
    ["pawl",        "PLA", 1, "body"],
    ["name_plate",  "PLA", 1, "accent"],
    ["name_inlay",  "PLA", 1, "ink"],
    ["ring",        "PLA", 1, "accent"],
    ["guide_plate", "PLA", 1, "body"],
    ["jaw",         "PLA", 3, "body"],
    ["wand",        "PLA", 1, "body"],
    ["wand_arm",    "PLA", 1, "body"],
    ["wand_finger", "TPU", 1, "tpu"],
    ["seal",        "TPU", 1, "tpu"],
    ["gasket",      "TPU", 1, "tpu"],
    ["jaw_boot",    "TPU", 3, "tpu"],
    ["stop_boot",   "TPU", 2, "tpu"],
    ["bumper",      "TPU", 1, "tpu"],
    ["pawl_spring", "TPU", 1, "tpu"],
    ["latch",       "TPU", 2, "tpu"],
    ["mat",         "TPU", 1, "tpu"],
];
COLORS = [["body", "#ECE8DF"], ["accent", "#2F3237"], ["ink", "#ECE8DF"], ["tpu", "#3A3D42"]];
function _col(k) = COLORS[search([k], COLORS)[0]][1];
function _pcol(n) = _col(PARTS[search([n], PARTS)[0]][3]);

module posed(name) {
    if      (name == "tub")         tub();
    else if (name == "scoop")       scoop();
    else if (name == "chassis")     chassis();
    else if (name == "funnel")      funnel();
    else if (name == "shell")       shell();
    else if (name == "slide")       slide();
    else if (name == "plunger")     plunger();
    else if (name == "dial")        dial();
    else if (name == "dial_inlay")  dial_inlay();
    else if (name == "pawl")        pawl();
    else if (name == "name_plate")  name_plate(NAME);
    else if (name == "name_inlay")  name_inlay(NAME);
    else if (name == "ring")        ring();
    else if (name == "guide_plate") guide_plate();
    else if (name == "jaw")         for (i=[0:2]) jaw(i);
    else if (name == "jaw_boot")    for (i=[0:2]) jaw_boot(i);
    else if (name == "wand")        wand();
    else if (name == "wand_arm")    wand_arm();
    else if (name == "wand_finger") wand_finger();
    else if (name == "seal")        seal();
    else if (name == "gasket")      gasket();
    else if (name == "stop_boot")   for (s=[-1,1]) stop_boot(s);
    else if (name == "bumper")      bumper();
    else if (name == "pawl_spring") pawl_spring();
    else if (name == "latch")       latch();
    else if (name == "mat")         mat();
    else if (name == "jar")         jar_ghost();
}
module printed(name) {
    if      (name == "tub")         tub_print();
    else if (name == "scoop")       scoop_print();
    else if (name == "chassis")     chassis_print();
    else if (name == "funnel")      funnel_print();
    else if (name == "shell")       shell_print();
    else if (name == "slide")       slide_print();
    else if (name == "plunger")     plunger_print();
    else if (name == "dial")        dial_print();
    else if (name == "dial_inlay")  dial_inlay_print();
    else if (name == "pawl")        pawl_print();
    else if (name == "name_plate")  name_plate_print(NAME);
    else if (name == "name_inlay")  name_inlay_print(NAME);
    else if (name == "ring")        ring_print();
    else if (name == "guide_plate") guide_plate_print();
    else if (name == "jaw")         jaw_print();
    else if (name == "jaw_boot")    jaw_boot_print();
    else if (name == "wand")        wand_print();
    else if (name == "wand_arm")    wand_arm_print();
    else if (name == "wand_finger") wand_finger_print();
    else if (name == "seal")        seal_print();
    else if (name == "gasket")      gasket_print();
    else if (name == "stop_boot")   stop_boot_print();
    else if (name == "bumper")      bumper_print();
    else if (name == "pawl_spring") pawl_spring_print();
    else if (name == "latch")       latch_print();
    else if (name == "latch_soft")  latch_print(1.7);
    else if (name == "latch_firm")  latch_print(2.4);
    else if (name == "mat")         mat_print();
    else if (name == "joiner")      joiner_print();
    else if (name == "coupon")      coupon_print();
    else if (name == "coupon_tpu")  coupon_tpu_print();
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
    for (p = PARTS) color(_pcol(p[0])) posed(p[0]);
    if (SHOW_JAR) %jar_ghost();
}
if (PART == "assembly") head_assembly();
else if (len(PART) > 6 && search("posed:", PART) == [0,1,2,3,4,5])
    posed(chr([for (i=[6:len(PART)-1]) ord(PART[i])]));
else printed(PART);
