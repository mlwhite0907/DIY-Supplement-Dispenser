// parts/wiper.scad: OWNER group BODY. Contract: cad/v5/README.md
// WIPER (TPU 95A): U-shaped strip pressed into the deck's ceiling groove. It
// wipes the slide top as the slide returns rearward. Section 2.0 wide, tapering
// at the bottom to a 0.8 lip that reaches WIPER_PROUD below the slide-top
// contact plane (Z_CEIL - CL_VT), a light interference.
include <../params.scad>
// The groove path is defined once in deck.scad (deck_wg_path, DECK_WG_*).

WIPER_PROUD = 0.35;
WIPER_H     = DECK_WG_D + CL_VT + WIPER_PROUD;   // 2.65 total
WIPER_LIP   = 0.8;
WIPER_TAPER_TOP = 0.3;                             // taper ends 0.3 mm inside the groove
// Section: v = 0 at the lip (bottom), v = WIPER_H at the flat back (top).
function wiper_section() = let(w = DECK_WG_W/2, l = WIPER_LIP/2,
    vt = WIPER_H - DECK_WG_D + WIPER_TAPER_TOP)
    [[-l, 0], [l, 0], [w, vt], [w, WIPER_H], [-w, WIPER_H], [-w, vt]];

// One straight run from a to b (axis aligned), extended by half the width at both
// ends so the runs meet square in the corners, like the groove.
module wiper_run(a, b) {
    d = b - a;  L = norm(d);  ang = atan2(d[1], d[0]);
    translate([a[0], a[1], 0]) rotate([0, 0, ang])
        translate([-DECK_WG_W/2, 0, 0]) rotate([90, 0, 90])
            linear_extrude(L + DECK_WG_W) polygon(wiper_section());
}
module wiper_local() {   // lip at z = 0, flat back at z = WIPER_H
    p = deck_wg_path();
    for (i=[0:len(p)-2]) wiper_run(p[i], p[i+1]);
}
module wiper() { translate([0, 0, Z_CEIL + DECK_WG_D - WIPER_H]) wiper_local(); }
// Print standing on its flat back (the groove-bottom face on the bed), lip up.
module wiper_print() {
    p = deck_wg_path();
    translate([0, -(p[0][1] + p[2][1])/2, WIPER_H]) mirror([0, 0, 1]) wiper_local();
}
