// Countertop carousel visual massing study, 2026-11-27.
// NOT a functional design, structural mount, food-contact part, or print file.
// Units mm. Open in OpenSCAD and preview; individual solids intentionally overlap.
$fn = 64;
stations = 5;
station_radius = 105;
cartridge_d = 100;
cartridge_h = 150;
tier_h = 170;
base_h = 35;
tier_count = 2; // 1 for an independent single-tier visual study
tier_d = 320;

module cartridge() {
    color([0.83,0.81,0.76]) cylinder(d=cartridge_d,h=cartridge_h);
    // Simplified front-facing visual markers, not a working dial or window.
    color([0.15,0.16,0.16]) translate([0,-cartridge_d/2-2,28]) rotate([90,0,0]) cylinder(d=34,h=6,center=true);
    color([0.35,0.48,0.48]) translate([-16,-cartridge_d/2-1,70]) cube([32,4,45]);
}
module tier() {
    color([0.16,0.17,0.17]) cylinder(d=tier_d,h=10);
    color([0.16,0.17,0.17]) translate([0,0,tier_h-10]) cylinder(d=tier_d,h=10);
    color([0.25,0.25,0.24]) cylinder(d=45,h=tier_h);
    for (i=[0:stations-1])
        rotate([0,0,i*360/stations]) translate([0,-station_radius,10]) cartridge();
}
color([0.10,0.11,0.11]) cylinder(d=330,h=base_h);
for (level=[0:tier_count-1]) translate([0,0,base_h+level*tier_h]) tier();
