// SCOOP — the pull-out drawer that IS the measuring scoop. Pull it: it brings the dose
// slide with it (two TPU latch flaps), the dose drops in, a firmer tug releases it.
// Hold it by the front and pour off the ramped far end. Prints upright, no supports.
SCOOP_LEN = SCOOP_Y_REAR - BODY_Y_FRONT;
module scoop_shape(hw, zb, ramp, ext=0) {      // tray solid: box + tapered end (ramp=1 raises the floor to the lip)
    hull() {
        bx([-hw, BODY_Y_FRONT + SCOOP_FRONT_T - 0.2, zb], [hw, SCOOP_Y_TAPER, SCOOP_RIM_Z + ext]);
        bx([-(SPOUT_W/2 + (hw - (SCOOP_HW - SCOOP_WALL))), SCOOP_Y_REAR - 0.01 + ext, zb + ramp*SPOUT_RISE],
           [SPOUT_W/2 + (hw - (SCOOP_HW - SCOOP_WALL)), SCOOP_Y_REAR + ext, SCOOP_RIM_Z + ext]);
    }
}
module scoop_body() {
    yf = BODY_Y_FRONT;  z0 = SCOOP_Z0;  yc = yf + 9.8;       // yc: centre of the latch root
    difference() {
        union() {
            hull() {                                     // front wall, 0.6 chamfers
                bx([-HANDLE_W/2, yf + 0.6, z0], [HANDLE_W/2, yf + SCOOP_FRONT_T, SCOOP_FRONT_Z]);
                bx([-HANDLE_W/2 + 0.6, yf, z0 + 0.6], [HANDLE_W/2 - 0.6, yf + SCOOP_FRONT_T, SCOOP_FRONT_Z - 0.6]);
            }
            difference() {
                scoop_shape(SCOOP_HW, z0, 0);
                scoop_shape(SCOOP_HW - SCOOP_WALL, z0 + SCOOP_WALL, 1, 1);
            }
            // latch pedestals in the two front corners
            for (s = [-1, 1]) bx([s*(FLAP[0] - 2.5), yf + SCOOP_FRONT_T - 0.5, z0 + 0.5], [s*(SCOOP_HW - 0.5), yf + 15.8, LATCH_Z]);
        }
        for (s = [-1, 1]) {
            // dovetail socket for the latch root (slides in from the middle)
            hull() {
                bx([s*(FLAP[0] - 3.5), yc - LATCH_DOVE[0]/2, LATCH_Z - 0.01], [s*(FLAP[1] + 0.3), yc + LATCH_DOVE[0]/2, LATCH_Z + 0.01]);
                bx([s*(FLAP[0] - 3.5), yc - LATCH_DOVE[1]/2, LATCH_Z - LATCH_DOVE[2]], [s*(FLAP[1] + 0.3), yc + LATCH_DOVE[1]/2, LATCH_Z - LATCH_DOVE[2] + 0.01]);
            }
            // room in the front wall for the flap to fold forward when the scoop goes back in
            bx([s*(FLAP[0] - 0.5), yf + SCOOP_FRONT_T - 2.5, LATCH_Z], [s*(FLAP[1] + 0.5), yf + SCOOP_FRONT_T + 0.1, 1]);
        }
        // home detent grooves (the tub rail bumps click in)
        for (s = [-1, 1]) translate([s*(SCOOP_HW + 0.95), SCOOP_DETENT_Y, z0 - 1]) cylinder(r=1.6, h=8, $fn=32);
        // half-moon finger notch in the top edge
        translate([0, yf - 1, SCOOP_FRONT_Z]) rotate([-90, 0, 0]) cylinder(r=NOTCH_R, h=SCOOP_FRONT_T + 2, $fn=96);
        translate([0, yf - 0.01, SCOOP_FRONT_Z]) rotate([-90, 0, 0]) cylinder(r1=NOTCH_R + 1.2, r2=NOTCH_R, h=1.2, $fn=96);
        translate([0, yf + SCOOP_FRONT_T - 1.2, SCOOP_FRONT_Z]) rotate([-90, 0, 0]) cylinder(r1=NOTCH_R, r2=NOTCH_R + 1.2, h=1.21, $fn=96);
    }
}
function scoop_dy() = -(PULL_D + DRAWER_OUT*(SCOOP_LEN + 20));
module scoop() { translate([0, scoop_dy(), 0]) scoop_body(); }
module scoop_print() { translate([0, 0, -SCOOP_Z0]) scoop_body(); }
