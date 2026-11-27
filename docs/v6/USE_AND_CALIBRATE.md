# Dose Bar v6: use, calibrate, clean

## Every day

1. Hook a finger in the half-moon and **pull the scoop**. The dose slide comes with it.
2. At the soft stop the dose has dropped into the scoop. **Tug** once more: the scoop lets go.
3. Hold the scoop by its front and **pour** off the far end into your cup.
4. **Push the scoop back in** until it is flush. That also pushes the slide home and refills the chamber.

One pull is one dose. For a double dose, push in and pull again.

## Set the dial (once per powder)

1. Pull the scoop to the soft stop. The dial is now in the open, on top of the slide.
2. Turn the pinch bar. **Clockwise is more.** The number at the triangle is the dose in mL.
3. Push back in. The dial disappears inside the body and cannot be bumped.

| Head | Range | One click |
|---|---|---|
| S | 0–20 mL | 0.5 mL |
| M | 0–40 mL | 1 mL |
| L | 0–100 mL | 2.5 mL |

## Calibrate by weight (10 minutes per powder)

The dial is in mL. Your label is in grams. Powders differ, so weigh once:

1. Set the dial to the starting point from the table below.
2. Throw away the first two pulls after a refill (they settle the powder).
3. Pull three doses onto a kitchen scale and take the average.
4. New setting = old setting × target grams ÷ measured grams. Round to a click.
5. Pull three more to confirm, then write the click number inside the name band or on the jar.

| Powder (typical) | Loose density | Example dose | Start at | Head |
|---|---|---|---|---|
| Whey / protein blend | 0.40–0.50 g/mL | 30 g | 65 mL | L |
| Collagen peptides | 0.30–0.40 | 10 g | 28 mL | M |
| BCAA / EAA drink mix | 0.35–0.50 | 13 g | 30 mL | M |
| Greens powder | 0.40–0.50 | 7 g | 15 mL | M or S |
| Fiber (psyllium blend) | 0.50–0.60 | 6 g | 11 mL | S |
| Fiber (wheat dextrin) | about 0.40 | 4 g | 10 mL | S |
| Creatine monohydrate | 0.55–0.70 | 5 g | 8 mL | S |
| Glutamine | 0.50–0.65 | 5 g | 8.5 mL | S |
| Pre-workout | 0.60–0.80 | read the label | grams ÷ 0.7 | S |
| Electrolyte mix | 0.70–0.90 | 3 g | 4 mL | S |

Densities are typical values, not your product's. The scale has the last word. Expect about ±3 % on free-flowing powders and ±5 % on sticky ones (whey, collagen).

## Caffeine and other potent powders

- Use the **S head** (0.5 mL clicks), and calibrate before the first real dose.
- Fit a **limit block**: `python3 cad/v6/tools/build.py --preset std --class S --limit 10` makes one that physically stops the dial at 10 mL. It drops into the slot in front of the plunger.
- One pull per serving. If the scoop was pulled and pushed back without pouring, empty it before the next pull.
- Never put pure caffeine powder in a volumetric dispenser.

## Refill

1. Lift the head and jar off the tub, hold the head, and turn it over so the jar stands on the counter.
2. Twist the ring counter-clockwise and lift the head off.
3. Refill, lay the gasket on the rim, put the head back, twist clockwise until snug, turn over, set on the tub.

## Clean

- Weekly: pull the scoop out and wipe it. Lift the head and wipe the tub (fine dust that gets behind the slide is designed to fall there).
- When changing powders: undo the 6 screws on the insert, lift it off, lift out the slide, brush everything dry.
- Wash PLA parts in lukewarm water only (below 40 °C) and dry them fully before refilling. Damp powder cakes.

## If something feels wrong

| Symptom | Cause | Fix |
|---|---|---|
| Scoop comes out but the slide stays | Latch too soft | Print `latch_firm` |
| Tug to release is too hard | Latch too stiff | Print `latch_soft` |
| Doses run light with whey or collagen | Powder bridging | Tap the jar; check the gate rocks at the end of each pull |
| Slide feels gritty | Powder under the slide | Lift the insert, brush the floor and rails |
| Jar wobbles | Chuck loosened | Twist the ring clockwise (refill pose) a little further |
| Dial number and dose drifted after cleaning | Dial put back one tooth off | At 0 the plunger must touch the chamber's back wall; refit the dial |
