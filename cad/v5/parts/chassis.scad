// CHASSIS — the floor the slide runs on, with the box walls that carry the funnel insert.
// One piece: floor + drop hole + guide rails + side/rear walls + stop piers + screw bosses.
// Prints upright (floor on the bed), no supports.
Z_EMB = 1.0;      // added solids start inside the floor (no coincident faces)
module chassis() {
    y_wall_f = BODY_Y_FRONT + CH_INSET + 0.6;         // box side walls start here
    difference() {
        union() {
            cx(FLOOR_T, cb=C_BED) body_2d(CH_INSET);
            // box side walls + rear wall (carry the funnel insert at Z_CEIL)
            for (s = [-1, 1]) bx([s*BOX_X, y_wall_f, Z_EMB], [s*(BOX_X + BOX_WALL), Y_BOX_REAR + BOX_WALL, Z_CEIL]);
            bx([-(BOX_X + BOX_WALL), Y_BOX_REAR, Z_EMB], [BOX_X + BOX_WALL, Y_BOX_REAR + BOX_WALL, Z_CEIL]);
            // guide rails
            for (s = [-1, 1]) bx([s*(SLIDE_W/2 + CL_SLIDE), hy(U_FLOOR_FRONT) + 0.3, Z_EMB],
                                 [s*(SLIDE_W/2 + CL_SLIDE + RAIL[0]), Y_BOX_REAR + 0.5, Z_FLOOR + RAIL[1]]);
            // stop piers: solid PLA tied into the floor and the side wall; each wears a TPU boot
            for (s = [-1, 1]) bx([s*PIER_X0, hy(PIER_U0), Z_EMB], [s*(BOX_X + 0.5), hy(PIER_U0 + PIER_T), Z_CEIL - 1.0]);
            // rear bumper block (wears the TPU bumper cap)
            bx([-BUMP[0]/2, Y_BOX_REAR - BUMP[1], Z_EMB], [BUMP[0]/2, Y_BOX_REAR + 0.5, Z_CEIL - 1.0]);
            // screw bosses for the funnel insert
            for (p = BOSS_XY) {
                translate([p[0], p[1], Z_EMB]) cylinder(d=9, h=Z_CEIL - Z_EMB);
                bx([p[0], p[1] - 4.5, Z_EMB], [sign(p[0])*(BOX_X + 0.5), p[1] + 4.5, Z_CEIL]);
            }
        }
        for (p = BOSS_XY) translate([p[0], p[1], Z_CEIL - 14]) cylinder(d=M3_PILOT, h=15);
        // front notch: the slide's face block and the scoop latch live here
        bx([-(HANDLE_W/2 + REVEAL), BODY_Y_FRONT - 1, -1], [HANDLE_W/2 + REVEAL, hy(U_FLOOR_FRONT), Z_CEIL + 1]);
        // drop hole, with a release chamfer underneath
        bx([-(CH_W + 1)/2, hy(HOLE_U1), 1.0], [(CH_W + 1)/2, hy(HOLE_U0), FLOOR_T + 1]);
        hull() {
            translate([-(CH_W + 1)/2, hy(HOLE_U1), 1.4]) cube([CH_W + 1, HOLE_U1 - HOLE_U0, 0.01]);
            translate([-(CH_W + 4)/2, hy(HOLE_U1) - 1.5, -0.1]) cube([CH_W + 4, HOLE_U1 - HOLE_U0 + 3, 0.01]);
        }
        // purge slots: powder that works its way behind the slide falls into the tub, not into the stroke
        for (s = [-1, 1]) bx([s*(BUMP[0]/2 + 3.4), hy(-REAR_L) + 0.6, -1], [s*SLIDE_W/2, Y_BOX_REAR - 0.3, FLOOR_T + 0.6]);
    }
}
module chassis_print() { chassis(); }
