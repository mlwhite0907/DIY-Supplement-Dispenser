// ============================================================================
// Dose Bar v5 — involute pinion + rack (2D), tuned for FDM printing
// m  module (mm)          z  tooth count        pa pressure angle (deg)
// x  profile shift coeff  bl total backlash     ck root clearance coeff
// add addendum coeff: 0.85 = stub tooth (wider printable tips, contact ratio ~1.28 at z12/25deg)
// The rack is standard; with a shifted pinion the pitch line of the rack sits
// at (pitch radius + x*m) from the pinion axis: use pinion_center_dist().
// ============================================================================
include <style.scad>

function _inv(a) = tan(a) - a*PI/180;             // involute function (a in deg) -> rad
function pinion_rp(m, z) = m*z/2;
function pinion_ra(m, z, x=0, add=0.85) = m*z/2 + m*(add + x);
function pinion_center_dist(m, z, x=0) = m*z/2 + x*m;

module pinion_2d(m=1, z=12, pa=25, x=0, bl=BACKLASH, ck=0.25, add=0.85, steps=10) {
    rp = m*z/2;
    rb = rp*cos(pa);
    ra = rp + m*(add + x);
    rf = rp - m*(add + ck - x);
    s  = m*(PI/2 + 2*x*tan(pa)) - bl/2;            // tooth thickness at pitch circle
    hp = (s/2)/rp*180/PI;                            // half tooth angle at pitch (deg)
    r0 = max(rb, rf);
    function fa(r) = hp + (_inv(pa) - _inv(acos(min(1, rb/r))))*180/PI;
    tip_half = max(0.5, fa(ra));
    rs = [for (k=[0:steps]) r0 + (ra - r0)*k/steps];
    pts = [for (i=[0:z-1]) let(c = i*360/z) each concat(
        [polar(rf, c - 180/z)],
        [polar(rf, c - fa(r0))],
        [for (r = rs) polar(r, c - max(0.5, fa(r)))],
        [for (r = [for (k=[steps:-1:0]) rs[k]]) polar(r, c + max(0.5, fa(r)))],
        [polar(rf, c + fa(r0))]
    )];
    polygon(pts);
}

// Rack along +x, pitch line on y=0, teeth pointing +y. First tooth centered at x=0.
module rack_2d(m=1, n=20, pa=25, bl=BACKLASH, ck=0.25, add=0.85, back=3) {
    p  = PI*m;
    ha = m*add; hf = m*(add + ck);
    s  = p/2 - bl/2;
    union() {
        for (i=[0:n-1]) translate([i*p, 0])
            polygon([[-s/2 - hf*tan(pa), -hf - EPS], [ s/2 + hf*tan(pa), -hf - EPS],
                     [ s/2 - ha*tan(pa),  ha],       [-s/2 + ha*tan(pa),  ha]]);
        translate([-p/2, -hf - back]) square([n*p, back]);
    }
}
