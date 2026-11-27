// ============================================================================
// Dose Bar v5 — design tokens + shape helpers
// One design language for every part. Change a token here, every part follows.
// Units: mm, degrees.
// ============================================================================

// ---- Design tokens ---------------------------------------------------------
R_V      = 2.0;    // radius on vertical edges (boxes, slide, drawer)
C_TOP    = 0.6;    // chamfer on top (last-printed) edges
C_BED    = 0.4;    // chamfer on bed edges (kills elephant's foot)
REVEAL   = 0.8;    // visible gap between adjacent parts (consistent shadow line)
FONT     = "Inter:style=SemiBold";
FONT_MED = "Inter:style=Medium";
FONT_DSP = "Inter Display:style=SemiBold";

// Flute profile family (twist ring + dial use the same scallop shape)
FLUTE_DEPTH = 0.8;  // scallop depth
FLUTE_W     = 2.4;  // scallop chord (cutter diameter)

// Print tolerances (tune with the test coupon; see docs)
CL_SLIDE   = 0.25;  // sliding fit, per side
CL_PLUNGER = 0.20;  // plunger in slot, per side
CL_PIN     = 0.30;  // pin in hole, on diameter
CL_ROT     = 0.30;  // rotating ring on hub, on radius
BACKLASH   = 0.15;  // gear backlash (total)

// Screws (self-tapped into PLA)
M3_PILOT = 2.6;  M3_CLEAR = 3.4;  M3_HEAD_D = 6.0;  M3_HEAD_H = 3.0;
M4_PILOT = 3.5;  M4_CLEAR = 4.5;  M4_HEAD_D = 7.5;  M4_HEAD_H = 4.0;

EPS = 0.01;
$fa = 3; $fs = 0.35;   // default facet resolution (override locally for tiny features)

// ---- 2D helpers --------------------------------------------------------------
function polar(r, a) = [r*cos(a), r*sin(a)];

module rrect(size, r=R_V, center=true) {
    r2 = min(r, size[0]/2 - EPS, size[1]/2 - EPS);
    translate(center ? [0,0] : [size[0]/2, size[1]/2])
        offset(r=r2) square([size[0]-2*r2, size[1]-2*r2], center=true);
}

// Circle with scallop flutes cut into its rim.
module fluted_circle(d, n, depth=FLUTE_DEPTH, w=FLUTE_W) {
    difference() {
        circle(d=d);
        for (i=[0:n-1]) rotate(i*360/n)
            translate([d/2 + w/2 - depth, 0]) circle(d=w, $fn=24);
    }
}

// ---- 3D helpers --------------------------------------------------------------
// Box with rounded vertical edges, chamfered top and bed edges. Sits on z=0.
module rbox(size, r=R_V, ct=C_TOP, cb=C_BED, center=true) {
    x=size[0]; y=size[1]; z=size[2];
    translate(center ? [0,0,0] : [x/2, y/2, 0])
    hull() {
        linear_extrude(EPS) offset(delta=-cb) rrect([x,y], r);
        translate([0,0,cb]) linear_extrude(max(EPS, z-cb-ct)) rrect([x,y], r);
        translate([0,0,z-EPS]) linear_extrude(EPS) offset(delta=-ct) rrect([x,y], r);
    }
}

// Cylinder with chamfered top and bed edges. Sits on z=0.
module ccyl(d, h, ct=C_TOP, cb=C_BED) {
    rotate_extrude() polygon([[0,0],[d/2-cb,0],[d/2,cb],[d/2,h-ct],[d/2-ct,h],[0,h]]);
}

// Tube (annulus) with chamfers on all four circular edges.
module ctube(od, id, h, ct=C_TOP, cb=C_BED) {
    rotate_extrude() polygon([
        [id/2+cb,0],[od/2-cb,0],[od/2,cb],[od/2,h-ct],[od/2-ct,h],
        [id/2+ct,h],[id/2,h-ct],[id/2,cb]]);
}

// Flat-bottom text block, extruded upward from z=0.
module label3d(txt, size, h, font=FONT, halign="center", valign="center", spacing=1) {
    linear_extrude(h) text(txt, size=size, font=font, halign=halign, valign=valign, spacing=spacing);
}

// Countersunk-free socket for a cap screw entering from below (head recess + clearance).
module screw_from_below(d_clear, head_d, head_h, len) {
    translate([0,0,-EPS]) cylinder(d=head_d, h=head_h+EPS, $fn=32);
    cylinder(d=d_clear, h=len, $fn=24);
}

// Extrude a 2D child with stepped chamfers (one step per 0.2 mm layer: exactly what the
// slicer prints). Works for any outline, holes included. cb = bottom, ct = top chamfer.
module cx(h, cb=0, ct=0) {
    L = 0.2; nb = round(cb/L); nt = round(ct/L);
    for (i = [0:1:nb-1]) translate([0,0,i*L]) linear_extrude(L + 0.001) offset(delta=-(cb - i*L)) children();
    translate([0,0,nb*L]) linear_extrude(h - (nb + nt)*L + 0.001) children();
    for (i = [0:1:nt-1]) translate([0,0,h - (i+1)*L - 0.001]) linear_extrude(L + 0.001) offset(delta=-(ct - i*L)) children();
}
// box from [x0,y0,z0] to [x1,y1,z1]
module bx(a, b) { translate([min(a[0],b[0]), min(a[1],b[1]), min(a[2],b[2])]) cube([abs(b[0]-a[0]), abs(b[1]-a[1]), abs(b[2]-a[2])]); }
