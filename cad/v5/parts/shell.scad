// SHELL — the outer skin of the head: one clean rounded block with a flat deck.
// It drops over the funnel insert (rests on the hub step) and is trapped under the twist ring.
// Prints UPSIDE DOWN (deck on the bed): the visible top gets the plate finish. No supports.
module shell() {
    zs = Z_SHOULDER;
    difference() {
        translate([0, 0, zs]) mirror([0, 0, 1]) cx(zs - SHELL_Z0, cb=2.0, ct=0.4) body_2d(0);
        translate([0, 0, SHELL_Z0 - 1]) linear_extrude(zs - SHOULDER_T - SHELL_Z0 + 1) body_2d(SKIN_T);
        translate([0, 0, zs - SHOULDER_T - 1]) cylinder(d=HUB_OD + 0.6, h=SHOULDER_T + 2);
        // front opening for the slide face (1 mm reveal all round)
        bx([-(HANDLE_W/2 + REVEAL), BODY_Y_FRONT - 1, SHELL_Z0 - 1], [HANDLE_W/2 + REVEAL, BODY_Y_FRONT + SKIN_T + 1, Z_SLIDE_TOP + REVEAL]);
    }
}
module shell_print() { translate([0, 0, Z_SHOULDER]) rotate([180, 0, 0]) shell(); }
