// parts/coupon.scad: tolerance test coupon (print this FIRST, ~45 min).
// Owner: lead. Uses the same params as the real parts, so what fits here fits there.
//
// What it tests                        how to read it
// A  slide in channel (3 clearances)   pick the channel where the block glides with no wobble
//    (features below start 0.5 mm above the bed so no faces are coplanar with the plate bottom)
// B  pins in holes (3 clearances)      jaw / stop pins: snug but turns by hand
// C  rack driven by the real pinion    turn the pinion: rack moves smoothly, no skipping
// D  pinion on the dial's hex key      slides on by hand, no rocking
// E  jaw dovetail                      slides freely, can't lift out
// F  M3 / M4 self-tap pilots           screws bite, don't split the boss
// G  two-color inlay "0 5 10"          crisp numerals, flush surface
// Labels "-", "0", "+" = clearance -0.1 / nominal / +0.1 mm.
include <../params.scad>
include <../lib/gears.scad>

CP_T = 3;                    // base plate thickness
CP_W = 150; CP_D = 110;      // base plate footprint
CP_TXT = 3.2;

module _cp_label(t) { translate([0,0,CP_T - 0.6]) linear_extrude(0.6 + EPS) text(t, size=CP_TXT, font=FONT, halign="center", valign="center"); }

// A: slide channels (inner width 20 + 2*cl), block 20 wide
module _cp_channels() {
    for (k=[0:2]) let(cl = CL_SLIDE + (k-1)*0.1) translate([k*26, 0, 0]) {
        difference() {
            translate([-(10+cl+2.4), 0, 0]) cube([2*(10+cl+2.4), 34, CP_T + 9]);
            translate([-(10+cl), -1, CP_T]) cube([2*(10+cl), 36, 10]);
        }
    }
}
// B: pin holes
module _cp_pinholes() {
    for (k=[0:2]) let(cl = CL_PIN + (k-1)*0.1) translate([k*12, 0, 0])
        translate([0,0,-1]) cylinder(d=PIN_D + cl, h=CP_T + 7, $fn=40);
}
module _cp_pinbosses() { for (k=[0:2]) translate([k*12, 0, 0]) cylinder(d=PIN_D + 5, h=CP_T + 6, $fn=40); }
// C: rack channel + pinion post (rack slides along x, pinion spins on a round post)
CP_RACK_N = 10;
module _cp_rack_channel_cut() { translate([-4, -RACK_BACK - G_M*(G_ADD+G_CK) - CL_SLIDE, CP_T]) cube([PI*G_M*CP_RACK_N + 8, RACK_BACK + G_M*(G_ADD+G_CK) + 2*CL_SLIDE + 2*G_M*G_ADD, 10]); }
module _cp_rack_walls() {
    w = RACK_BACK + G_M*(G_ADD+G_CK) + 2*CL_SLIDE;
    translate([-6, -w - 2.4, 0]) cube([PI*G_M*CP_RACK_N + 12, 2.4, CP_T + 7]);   // back wall
}
// round spin post: the pinion's hex bore turns freely on it while it drives the rack
module _cp_pinion_post() { translate([PI*G_M*CP_RACK_N/2, pinion_center_dist(G_M, G_Z), 0.5]) cylinder(d=DIAL_KEY_AF - 0.4, h=CP_T + PIN_FW + 0.5, $fn=40); }
// D: hex key post = the dial shaft's key; the pinion must slide on by hand without rocking
module _cp_hex_post() { translate([0,0,0.5]) cylinder(d=DIAL_KEY_AF/cos(30), h=CP_T + PIN_FW + 0.5, $fn=6); }
// E: dovetail track (cut into a raised block)
module _cp_dovetail_block() { translate([-12, 0, 0]) cube([24, 40, CP_T + DOVETAIL[2]]); }
module _cp_dovetail_cut() {
    translate([0, -1, CP_T]) rotate([-90,0,0]) linear_extrude(42)
        polygon([[-DOVETAIL[1]/2 - 0.25, 0], [DOVETAIL[1]/2 + 0.25, 0], [DOVETAIL[0]/2 + 0.25, -DOVETAIL[2] - EPS], [-DOVETAIL[0]/2 - 0.25, -DOVETAIL[2] - EPS]]);
}
// F: screw pilot bosses
module _cp_pilots() {
    for (s=[[M3_PILOT, 8], [M4_PILOT, 10]]) translate([s[1] == 8 ? 0 : 18, 0, 0])
        difference() { cylinder(d=2*s[1] - 4, h=CP_T + 10, $fn=40); translate([0,0,2]) cylinder(d=s[0], h=CP_T + 10, $fn=24); }
}
// G: inlay tile
module _cp_inlay_txt() { linear_extrude(0.6 + EPS) text("0  5  10", size=4, font=FONT, halign="center", valign="center"); }

module coupon() {
    difference() {
        union() {
            rbox([CP_W, CP_D, CP_T], r=4, ct=0.6, cb=C_BED, center=false);
            translate([18, 8, 0.5]) _cp_channels();
            translate([100, 12, 0.5]) _cp_pinbosses();
            translate([14, 66, 0.5]) _cp_rack_walls();
            translate([14, 66, 0]) _cp_pinion_post();
            translate([68, 74, 0]) _cp_hex_post();
            translate([132, 58, 0.5]) _cp_dovetail_block();
            translate([100, 34, 0.5]) _cp_pilots();
        }
        translate([100, 12, 0]) _cp_pinholes();
        translate([132, 58, 0.5]) _cp_dovetail_cut();
        translate([75, 100, CP_T - 0.6]) _cp_inlay_txt();
        for (k=[0:2]) translate([18 + k*26, 4.5, 0]) _cp_label(k == 0 ? "-" : (k == 1 ? "0" : "+"));
        for (k=[0:2]) translate([100 + k*12, 4.5, 0]) _cp_label(k == 0 ? "-" : (k == 1 ? "0" : "+"));
        translate([30, 100, 0]) _cp_label("DOSE BAR FIT");
    }
}
// loose pieces: 3 slide blocks, 3 pins, pinion, rack, dovetail tongue
module coupon_parts() {
    for (k=[0:2]) translate([k*26, 0, 0]) rbox([20, 30, 6], r=1, ct=0.4, cb=C_BED, center=false);
    for (k=[0:2]) translate([86 + k*10, 6, 0]) cylinder(d=PIN_D, h=12, $fn=40);
    translate([126, 10, 0]) linear_extrude(PIN_FW) difference() {
        pinion_2d(m=G_M, z=G_Z, pa=G_PA, add=G_ADD, ck=G_CK, $fn=48);
        circle(d=(DIAL_KEY_AF + 2*PINION_BORE_CL)/cos(30), $fn=6);
    }
    translate([0, 40, 0]) linear_extrude(PIN_FW) rack_2d(m=G_M, n=CP_RACK_N + 4, pa=G_PA, add=G_ADD, ck=G_CK, back=RACK_BACK);
    translate([90, 40, 0]) rotate([90,0,0]) translate([0,0,-28]) linear_extrude(28)
        polygon([[-DOVETAIL[0]/2 + 0.25, 0], [DOVETAIL[0]/2 - 0.25, 0], [DOVETAIL[1]/2 - 0.25, DOVETAIL[2] - 0.2], [-DOVETAIL[1]/2 + 0.25, DOVETAIL[2] - 0.2]]);
    translate([90, 40, 0]) translate([-DOVETAIL[1]/2, -28, DOVETAIL[2] - 0.2]) cube([DOVETAIL[1], 28, 5]);
}
module coupon_inlay() { translate([75, 100, CP_T - 0.6]) _cp_inlay_txt(); }
module coupon_print() { coupon(); }
module coupon_parts_print() { coupon_parts(); }
module coupon_inlay_print() { coupon_inlay(); }
