// ============================================================================
// Dose Bar v5 — entry point. Select what to render with -D 'PART="..."'.
//   PART="assembly"        whole head (+ jar ghost) in the current state
//   PART="<name>"          one part, in PRINT orientation (for STL export)
//   PART="posed:<name>"    one part, in ASSEMBLED pose (for fit checks)
//   PART="bar"             N bays + legs (BAR_BAYS)
// State: -D STATE_PULL=0..1  -D DIAL_ML=<mL>  -D CHUCK_CLOSE=0..1
// Jar:   tools/build.py passes the preset values with -D.
// ============================================================================
include <params.scad>
include <parts/base.scad>
include <parts/deck.scad>
include <parts/slide.scad>
include <parts/plunger.scad>
include <parts/dial.scad>
include <parts/pinion.scad>
include <parts/detent.scad>
include <parts/stir_post.scad>
include <parts/stop_pin.scad>
include <parts/wiper.scad>
include <parts/band.scad>
include <parts/name_plate.scad>
include <parts/ring.scad>
include <parts/guide_plate.scad>
include <parts/jaw.scad>
include <parts/jaw_pad.scad>
include <parts/gasket.scad>
include <parts/bay.scad>
include <parts/leg.scad>
include <parts/foot.scad>
include <parts/coupon.scad>

// dimension report
echo(str("[dosebar] ", JAR_NAME, " class ", CLASS_NAME, " 0-", V_MAX, " mL @ ", ML_PER_CLICK,
    " mL/click | chamber ", CH_W, " x ", CH_H, " x ", L_MAX, " | throat ", T_WID, " x ", T_LEN,
    " | stroke ", STROKE, " | puck D ", PUCK_D, " | rim z ", Z_RIM, " | handle L ", HANDLE_L,
    " | slide L ", REAR_L + U_HANDLE0 + HANDLE_L, " | scroll lead ", SCROLL_LEAD, " / ", SCROLL_LEAD_ANGLE, " deg",
    " | rear chamfer ", SLIDE_REAR_CHAMFER, " | band: direct +", round(100*BAND_STRAIN_ADD), "%, pulley path ", round(BAND_PATH_REST), " mm +", round(100*BAND_STRAIN_ADD_TPU), "%"));

PART = "assembly";
BAR_BAYS = 3;
NAME = "WHEY";
SHOW_JAR = true;

// Part registry: [name, material, qty per head (or per bay), color]
PARTS = [
    ["base",        "PLA", 1, "body"],
    ["deck",        "PLA", 1, "body"],
    ["slide",       "PLA", 1, "body"],
    ["plunger",     "PLA", 1, "accent"],
    ["dial",        "PLA", 1, "accent"],
    ["dial_inlay",  "PLA", 1, "ink"],
    ["pinion",      "PLA", 1, "accent"],
    ["detent",      "TPU", 1, "tpu"],
    ["stir_post",   "PLA", 1, "accent"],
    ["stop_pin",    "PLA", 1, "accent"],
    ["wiper",       "TPU", 1, "tpu"],
    ["band",        "TPU", 2, "tpu"],
    ["name_plate",  "PLA", 1, "accent"],
    ["name_inlay",  "PLA", 1, "ink"],
    ["ring",        "PLA", 1, "accent"],
    ["guide_plate", "PLA", 1, "body"],
    ["jaw",         "PLA", 3, "accent"],
    ["jaw_pad",     "TPU", 3, "tpu"],
    ["gasket",      "TPU", 1, "tpu"],
    ["bay_plate",   "PLA", 1, "body"],
    ["leg",         "PLA", 1, "body"],
    ["foot",        "TPU", 2, "tpu"],
];
COLORS = [["body", "#ECE8DF"], ["accent", "#2F3237"], ["ink", "#ECE8DF"], ["tpu", "#3A3D42"]];
function _col(k) = COLORS[search([k], COLORS)[0]][1];
function _pcol(n) = _col(PARTS[search([n], PARTS)[0]][3]);

module posed(name) {
    if      (name == "base")        base();
    else if (name == "deck")        deck();
    else if (name == "slide")       slide();
    else if (name == "plunger")     plunger();
    else if (name == "dial")        dial();
    else if (name == "dial_inlay")  dial_inlay();
    else if (name == "pinion")      pinion();
    else if (name == "detent")      detent();
    else if (name == "stir_post")   stir_post();
    else if (name == "stop_pin")    stop_pin();
    else if (name == "wiper")       wiper();
    else if (name == "band")        band();
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
    else if (name == "jar")         jar_ghost();
    else if (name == "params_json") cube(0.01);
    else if (name == "gasket")      gasket();
}
module printed(name) {
    if      (name == "base")        base_print();
    else if (name == "deck")        deck_print();
    else if (name == "slide")       slide_print();
    else if (name == "plunger")     plunger_print();
    else if (name == "dial")        dial_print();
    else if (name == "dial_inlay")  dial_inlay_print();
    else if (name == "pinion")      pinion_print();
    else if (name == "detent")      detent_print();
    else if (name == "stir_post")   stir_post_print();
    else if (name == "stop_pin")    stop_pin_print();
    else if (name == "wiper")       wiper_print();
    else if (name == "band")        band_print();
    else if (name == "name_plate")  name_plate_print(NAME);
    else if (name == "name_inlay")  name_inlay_print(NAME);
    else if (name == "ring")        ring_print();
    else if (name == "guide_plate") guide_plate_print();
    else if (name == "jaw")         jaw_print();
    else if (name == "jaw_pad")     jaw_pad_print();
    else if (name == "gasket")      gasket_print();
    else if (name == "bay_plate")   bay_plate_print();
    else if (name == "leg")         leg_print();
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
    for (p = PARTS) if (p[0] != "bay_plate" && p[0] != "leg" && p[0] != "foot")
        color(_pcol(p[0])) posed(p[0]);
    if (SHOW_JAR) %jar_ghost();
}
if (PART == "assembly") head_assembly();
else if (PART == "bar") bar_assembly(BAR_BAYS);
else if (len(PART) > 6 && PART[0]=="p" && PART[1]=="o" && PART[2]=="s" && PART[3]=="e" && PART[4]=="d" && PART[5]==":")
    posed([for (i=[6:len(PART)-1]) PART[i]][0] == undef ? "" : str_join([for (i=[6:len(PART)-1]) PART[i]]));
else printed(PART);
function str_join(v, i=0) = i >= len(v) ? "" : str(v[i], str_join(v, i+1));
