// PLUNGER — the movable front wall of the dose chamber, one piece with its rack rod.
// Drops into the slide from above; its 45-degree wings hang on the slot's top edges.
// Prints upright (as posed), no supports. Slide-local frame.
module plunger_body(L = CH_L) {
    hw = CH_W/2 - CL_PLUNGER;
    p = PI*G_M;
    union() {
        // block
        ubx(L, L + PLUNGER_L, -hw, hw, Z_FLOOR + 0.2, Z_SLIDE_TOP - WING);
        hull() {
            ubx(L, L + PLUNGER_L, -hw, hw, Z_SLIDE_TOP - WING - 0.01, Z_SLIDE_TOP - WING);
            ubx(L, L + PLUNGER_L, -hw - WING, hw + WING, Z_SLIDE_TOP - 0.01, Z_SLIDE_TOP);
        }
        // rack rod (toothed along its whole length; its rear end is buried in the block)
        translate([G_RP, -(U_DIAL + L + 0.5*p), ROD_Z0]) linear_extrude(ROD_Z1 - ROD_Z0)
            rotate(90) rack_2d(G_M, RACK_N, G_PA, BACKLASH, G_CK, G_ADD, RACK_BACK);
    }
}
module plunger() { translate([0, SLIDE_Y0, 0]) plunger_body(); }
module plunger_print() { translate([0, 0, -(Z_FLOOR + 0.2)]) plunger_body(0); }
