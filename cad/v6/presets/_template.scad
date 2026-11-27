// New jar? Copy this file to presets/<name>.scad, fill in your numbers, then
//   python3 cad/v5/tools/build.py --preset <name>
// Measure with the lid OFF (docs/v5/MEASURE_YOUR_JAR.md). Calipers or a ruler is fine.
JAR_NAME    = "myjar";
NECK_OD     = 86;    // across the threads, outside            (60-140 supported)
MOUTH_ID    = 74;    // inside of the opening                  (must be < NECK_OD)
BODY_OD     = 100;   // widest point of the jar
JAR_H       = 150;   // overall height with the lid on
NECK_H      = 12;    // threaded neck height above the rim
DOSE_CLASS  = "auto"; // "auto" picks from MOUTH_ID; or "S" 0-20 | "M" 0-40 | "L" 0-80 mL
