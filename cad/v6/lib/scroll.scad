// ============================================================================
// Dose Bar v5 — Archimedean scroll (multi-start partial spirals) for the chuck
// r(t) = r0 + lead * (t - t0) / 360    (t in degrees)
// Each start is a groove of width w from angle t0 to t1, rounded ends.
// ============================================================================
include <style.scad>

function scroll_r(r0, lead, t0, t) = r0 + lead*(t - t0)/360;

module scroll_grooves_2d(r0, lead, t0, t1, w, starts=3, step=2) {
    for (k=[0:starts-1]) rotate(k*360/starts) {
        polygon(concat(
            [for (t=[t0:step:t1]) polar(scroll_r(r0, lead, t0, t) + w/2, t)],
            [for (t=[t1:-step:t0]) polar(scroll_r(r0, lead, t0, t) - w/2, t)]));
        translate(polar(scroll_r(r0, lead, t0, t0), t0)) circle(d=w, $fn=24);
        translate(polar(scroll_r(r0, lead, t0, t1), t1)) circle(d=w, $fn=24);
    }
}
