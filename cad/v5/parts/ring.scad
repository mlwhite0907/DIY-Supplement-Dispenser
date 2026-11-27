// parts/ring.scad: OWNER group CHUCK. Contract: cad/v5/README.md
// TWIST RING: the knurled band of the head. Rides on the deck flange, its bore
// on the hub. Three Archimedean scroll grooves open on its TOP face drive the
// jaw pins; turning the ring CLOCKWISE seen from above (RING_PHI < 0) closes.
include <../params.scad>
include <../lib/scroll.scad>

// ---- private constants -------------------------------------------------------
RING_TOP_CH   = 1.2;     // upper chamfer (designed feature; carries the index dot)
RING_LAND     = 1.0;     // smooth land above / below the fluted band
RING_FLUTE_PITCH = 3.4;  // target flute pitch on the OD (mm)
RING_FLUTES   = max(110, min(140, round(PI*RING_OD/RING_FLUTE_PITCH)));
RING_FLUTE_SAMPLES = 8;  // polyhedron columns per flute
RING_RUNOUT   = 12;      // scroll run-out at each end (deg)
RING_GROOVE_CH = 0.4;    // lead-in chamfer on the groove edges (top face)
RING_DOT_D    = 1.4;     // engraved index dot
RING_DOT_DEPTH = 0.5;
// Ring-local angle of the index dot: it reads "front" (270 deg, toward the
// user) when the chuck is closed on a NECK_OD jar.
RING_PHI_NOM  = -(R_PIN_MAX - R_PIN_NOM)/SCROLL_LEAD*360;
RING_DOT_A    = 270 - RING_PHI_NOM;

// ---- fluted outer band as one closed polyhedron (fast in CGAL) ---------------
// Scallop radius at angular offset d (deg) from a flute centre, on a ring of
// radius R: intersection of the ray with the cutter circle (diameter FLUTE_W).
function _ring_scallop(R, d) =
    let(a = FLUTE_W/2, c = R + a - FLUTE_DEPTH,
        s = c*sin(d), disc = a*a - s*s)
    disc <= 0 ? R : min(R, c*cos(d) - sqrt(disc));

// rows: [z, inset from R (chamfer), flute factor 0..1]
function _ring_rows(H) = let(zf0 = C_BED + RING_LAND, zf3 = H - RING_TOP_CH - RING_LAND) [
    [0,                 C_BED,       0],
    [C_BED,             0,           0],
    [zf0,               0,           0],
    [zf0 + FLUTE_DEPTH, 0,           1],
    [zf3 - FLUTE_DEPTH, 0,           1],
    [zf3,               0,           0],
    [H - RING_TOP_CH,   0,           0],
    [H,                 RING_TOP_CH, 0]];

module ring_body_poly() {
    R  = RING_OD/2;  Ri = RING_ID/2;  H = RING_T;
    N  = RING_FLUTES*RING_FLUTE_SAMPLES;
    pitch = 360/RING_FLUTES;
    rows = _ring_rows(H);
    nr = len(rows);
    // inner bore rows: [z, r]
    inner = [[0, Ri + C_BED], [C_BED, Ri], [H - C_TOP, Ri], [H, Ri + C_TOP]];
    ni = len(inner);
    function ang(j) = j*360/N;
    // offset from the nearest flute centre (flute centres at (m + 1/2)*pitch)
    function dfl(j) = (ang(j) % pitch) - pitch/2;
    outer_pts = [for (k=[0:nr-1]) for (j=[0:N-1])
        let(rw = rows[k], rs = _ring_scallop(R, dfl(j)),
            r = R - rw[1] - rw[2]*(R - rs))
        [r*cos(ang(j)), r*sin(ang(j)), rw[0]]];
    inner_pts = [for (k=[0:ni-1]) for (j=[0:N-1])
        [inner[k][1]*cos(ang(j)), inner[k][1]*sin(ang(j)), inner[k][0]]];
    pts = concat(outer_pts, inner_pts);
    function oi(k, j) = k*N + (j % N);
    function ii(k, j) = nr*N + k*N + (j % N);
    faces = concat(
        // outer wall
        [for (k=[0:nr-2]) for (j=[0:N-1]) each [
            [oi(k,j), oi(k+1,j+1), oi(k,j+1)], [oi(k,j), oi(k+1,j), oi(k+1,j+1)]]],
        // inner wall
        [for (k=[0:ni-2]) for (j=[0:N-1]) each [
            [ii(k,j), ii(k,j+1), ii(k+1,j+1)], [ii(k,j), ii(k+1,j+1), ii(k+1,j)]]],
        // bottom face (z = 0)
        [for (j=[0:N-1]) each [
            [oi(0,j), oi(0,j+1), ii(0,j+1)], [oi(0,j), ii(0,j+1), ii(0,j)]]],
        // top face (z = H)
        [for (j=[0:N-1]) each [
            [oi(nr-1,j), ii(ni-1,j+1), oi(nr-1,j+1)], [oi(nr-1,j), ii(ni-1,j), ii(ni-1,j+1)]]]
    );
    polyhedron(points=pts, faces=faces, convexity=6);
}

// ---- scroll grooves (ring-local, 2D) ------------------------------------------
// Ring-local angle t: r(t) = R_PIN_MAX - SCROLL_LEAD*(t - a0)/360, a0 = jaw angle.
// Start k sits at JAW_ANGLES[0] + 120k, which equals JAW_ANGLES[k].
module ring_scroll_2d(grow=0) {
    a0 = JAW_ANGLES[0];
    t0 = a0 - RING_RUNOUT;
    t1 = a0 + TWIST + RING_RUNOUT;
    r0 = R_PIN_MAX + SCROLL_LEAD*RING_RUNOUT/360;
    scroll_grooves_2d(r0, -SCROLL_LEAD, t0, t1, GROOVE_W + 2*grow, starts=3, step=1.5);
}

module ring_scroll_cut() {
    H = RING_T;
    translate([0, 0, H - SCROLL_DEPTH]) linear_extrude(SCROLL_DEPTH + 1) ring_scroll_2d();
    // 45 deg lead-in on the groove edges, stepped at layer height
    for (s = [0:1]) {
        g = RING_GROOVE_CH*(2 - s)/2;
        translate([0, 0, H - RING_GROOVE_CH*(s + 1)/2]) linear_extrude(RING_GROOVE_CH) ring_scroll_2d(g);
    }
}

// Engraved index dot, normal to the 45 deg upper chamfer.
module ring_dot_cut() {
    R = RING_OD/2;  H = RING_T;
    rotate(RING_DOT_A) translate([R - RING_TOP_CH/2, 0, H - RING_TOP_CH/2])
        rotate([0, 45, 0]) translate([0, 0, -RING_DOT_DEPTH])
            cylinder(d=RING_DOT_D, h=RING_DOT_DEPTH + 2, $fn=24);
}

// Ring in its own frame: bottom at z = 0, unrotated.
module ring_local() {
    difference() {
        ring_body_poly();
        ring_scroll_cut();
        ring_dot_cut();
    }
}

// Assembled: on the deck flange, rotated by RING_PHI (pins centred in grooves).
module ring() {
    translate([0, 0, Z_RING_BOT]) rotate(RING_PHI) ring_local();
}

// Print: UPRIGHT. The bottom (bearing face on the deck flange) is bed-side,
// textured and C_BED-chamfered; the scroll grooves open upward, no supports.
// The fluted band's upper taper is a 45 deg overhang, the top chamfer 45 deg.
module ring_print() {
    ring_local();
}
