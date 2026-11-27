// FIT-TEST COUPON — print this first (about 1 hour, ~35 g). It is cut from the real parts, so what
// fits here fits in the head. Test, in this order:
//   1 dial block  : drop the real dial + pawl + TPU spring in, slide the rack stub past: smooth clicks, no skipping
//   2 rail strip  : the slide stub must glide between the rails with a little play and no rattle
//   3 jaw track   : a real jaw must slide in the dovetail without binding
//   4 latch corner: the TPU latch root must push into its dovetail and stay
//   5 seal block  : the TPU seal's root must press into the groove
module _clip(x0, x1, y0, y1, z0=-1, z1=200) { intersection() { children(); translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]); } }
module coupon_print() {
    // 1 dial block (slide, printed upside down like the real one: u runs along +y)
    translate([0, -U_DIAL, 0]) _clip(-SLIDE_W/2 - 1, SLIDE_W/2 + 1, U_DIAL - 21, U_DIAL + 28) slide_print();
    translate([ROD_X0 - 4, 21, 0]) cube([ROD_X1 - ROD_X0 + 8, 7, 4]);      // tie across the rod channel (the real slide is tied by its ends)
    //   rack stub (front of the plunger's rod)
    translate([SLIDE_W/2 + 4 - ROD_X0, U_DIAL + 30, 0]) _clip(ROD_X0 - 1, ROD_X1 + 1, -(U_ROD_FRONT0 + 1), -(U_ROD_FRONT0 - 44)) plunger_print();
    // 2 rail strip (chassis) + slide stub
    translate([SLIDE_W + 14, -40, 0]) _clip(-SLIDE_W/2 - 5, SLIDE_W/2 + 5, 28, 58, -1, Z_FLOOR + RAIL[1] + 0.01) chassis_print();
    translate([SLIDE_W + 14, 86, 0]) _clip(-SLIDE_W/2 - 1, SLIDE_W/2 + 1, -64, -42) slide_print();
    // 3 jaw track (guide plate, printed upside down)
    translate([-SLIDE_W/2 - 20, R_PIN_NOM, 0]) _clip(-13, 13, -(R_PIN_MAX + JAW_TAIL + 3), -(R_PIN_MIN - PIN_OFF + FOOT_IN - 3.5)) rotate(180) guide_plate_print();
    // 4 latch corner (scoop)
    translate([-SLIDE_W/2 - 42 - HANDLE_W/2, -BODY_Y_FRONT - 30, 0]) _clip(FLAP[0] - 5, HANDLE_W/2 + 1, BODY_Y_FRONT - 1, BODY_Y_FRONT + 18) scoop_print();
    // 5 seal block (funnel insert: the throat's rear edge)
    translate([-SLIDE_W/2 - 34, 40, 0]) _clip(-14, 14, hy(0) - 6, hy(0) + 12, -1, 9) funnel_print();
}
module coupon_tpu_print() {            // latch in two stiffnesses + the pawl spring
    latch_print(2.0);
    translate([14, 0, 0]) latch_print(2.4);
    translate([28, 0, 0]) pawl_spring_print();
}
