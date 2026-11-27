// Jar preset: 4.5 in (114 mm) lid glass jars.
// Measured with the lid ON: lid OD 114 mm; 7 jars 165 mm tall, 2 jars ~117 mm tall.
// NECK_OD and MOUTH_ID are estimates until measured with the lid OFF
// (see docs/v5/MEASURE_YOUR_JAR.md). The chuck grips NECK_OD +/- CHUCK_RANGE.
JAR_NAME    = "std";
NECK_OD     = 108;   // outside diameter across the threads (lid off)
MOUTH_ID    = 96;    // inside diameter of the opening
BODY_OD     = 116;   // widest point of the jar (sets bay spacing)
JAR_H       = 165;   // tallest jar of this size, lid on
NECK_H      = 14;    // height of the threaded neck above the rim
DOSE_CLASS  = "M";   // "S" 0-20 mL | "M" 0-40 mL | "L" 0-80 mL
