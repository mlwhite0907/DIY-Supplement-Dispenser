# Testing Protocol – Phase 1

Procedures and pass/fail criteria for scale calibration, powder dosing, water volume, and full drinks. Complements [ASSEMBLY_GUIDE.md](ASSEMBLY_GUIDE.md) and [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md).

**Primary success criteria (Phase 1):**

| Quantity | Target tolerance |
|----------|------------------|
| Powder mass (after settle) | **±0.1 g** of target |
| Water volume | **±5–10 ml** of target (tighter if weight-based) |

---

## 0. Lab Notes Template (use every session)

Record at minimum:

- Date, ambient notes (humidity if known)
- Powder type / brand / approximate grind
- Firmware/software commit or version label
- Scale calibration factor and cal weights used
- Target mass/volume, measured results, faults
- Photos only if useful for geometry issues

---

## 1. Scale Calibration Procedure

### 1.1 Prerequisites

- Load cell mounted solidly; cup platform does not rock
- HX711 powered and reading continuously for ≥2 minutes (warm-up)
- No contact with cables during reads
- Known reference masses (prefer class F2 or better kitchen-calibrated weights; at least one mid-range mass, e.g. 100 g, and one near use range if available)

### 1.2 Steps

1. Place the **empty cup** that will be used for dispenses (same cup every cal).
2. Ensure nothing touches the platform; wait for reading to stabilize.
3. **Tare** (software zero) → reading ≈ 0.
4. Place **calibration mass** carefully on the cup center.
5. Wait for settle (same settle filter you will use in production).
6. Set calibration so displayed mass = known mass (single-point or two-point per your software).
7. Remove mass → confirm return to ~0 (± a few tenths of a gram noise band).
8. Spot-check with a **second known mass** if available; record error.
9. Log calibration factor, masses, and date.

### 1.3 Pass criteria (calibration)

| Check | Pass |
|-------|------|
| Return to zero after mass removed | Within noise band (document band; typically < 0.1–0.2 g p-p when settled) |
| Spot-check mass | Within ±0.1 g for masses in the 50–500 g region if cell/quality allows; if not, document actual and do not claim ±0.1 g powder until scale is trustworthy |
| Repeatability | Three placements of same mass: range ≤ 0.1 g preferred |

### 1.4 When to recalibrate

- After mechanical disturbance of the cell or platform
- After cable re-route or HX711 rewire
- If zero drifts more than your acceptance band between sessions
- Before any formal 20× powder campaign

---

## 2. Open-Loop Powder Tests

Purpose: prove flow and roughly linear mass delivery **before** trusting closed-loop.

### 2.1 Setup

1. Calibrated scale; empty cup; tare.
2. Hopper loaded with test powder (note fill level: low / mid / high).
3. Vibe available but start with a fixed policy (e.g. vibe pulse every N bursts).

### 2.2 Procedure

1. Run a fixed command: e.g. **M steps** or **T ms** of auger at fixed speed.
2. Settle ≥ your standard settle window; record Δmass.
3. Repeat **10 times** without changing parameters; empty or account for cup capacity (use large cup or empty between runs).
4. Optionally double the command and confirm roughly double mass (nonlinearity is OK but should be monotonic).

### 2.3 Pass criteria (open-loop)

| Check | Pass |
|-------|------|
| Mass increases every run | No zero-delivery runs (unless intentionally empty) |
| No permanent bridge | At most occasional need for extra vibe; not stuck every shot |
| Coefficient of variation | Record CV; high CV is OK if closed-loop can correct — flag if CV catastrophic |
| No mechanical bind | Motor does not skip/stall under normal fill |

**Fail →** fix geometry/clearance/vibe before closed-loop campaigns ([PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md)).

---

## 3. Closed-Loop Powder Tests

Purpose: prove **±0.1 g after settle** on repeated dispenses.

### 3.1 Algorithm under test

Must match architecture intent:

1. Tare with empty cup  
2. Burst auger (+ optional vibe)  
3. Settle → read  
4. Adapt bursts until target approached  
5. Final settle → **verify**  

See control loop in [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md).

### 3.2 Matrix (required for Phase 1 exit)

| Series | Target | Replicates | Powder |
|--------|--------|------------|--------|
| A | **3.0 g** | **20** | Primary test powder (e.g. creatine monohydrate) |
| B | **5.0 g** | **20** | Same powder, same session if possible |

Optional stretch:

| Series | Target | Replicates | Notes |
|--------|--------|------------|-------|
| C | 1.0 g | 10 | Fine-dose stress |
| D | 10.0 g | 10 | Coarse dose / capacity |
| E | 3.0 g | 10 | Second powder type (flow behavior) |

### 3.3 Per-run procedure

1. Empty and wipe cup if residue affects tare; dry cup.
2. Place cup; **tare**.
3. Start closed-loop job for target.
4. Do not touch cup until software reports complete.
5. Record: `target`, `measured_final`, `error`, `burst_count`, `duration`, `faults`.
6. Optional: independent check — if you have a second scale, weigh cup contents once for audit (not required every run).

### 3.4 Pass criteria (closed-loop)

For **each** of series A and B:

| Metric | Pass |
|--------|------|
| Every run completes without EMPTY/JAM (unless hopper intentionally depleted) | Yes |
| **\|error\| ≤ 0.1 g** after settle | **≥ 18 of 20** runs (90%) preferred for Phase 1 exit; **20 of 20** stretch goal |
| No run with \|error\| > 0.25 g | Hard fail if any (investigate immediately) |
| Mean error | Within ±0.05 g preferred (bias check) |
| Std dev | Document; use for future tuning |

If 18/20 fails: tune settle time, burst schedule, overshoot margin; re-check open-loop flow; only then revise geometry.

### 3.5 Empty / jam injection (minimum)

1. Run closed-loop with **empty hopper** → must fault EMPTY (or JAM) and stop actuation, not spin forever.
2. Induce a soft bridge if possible (tap sides only as test setup) → recovery vibe or clear fault path works.

---

## 4. Water Volume Accuracy Test

### 4.1 Timed pump method

1. Tank filled to a marked level (e.g. half full); note level.
2. Dispense into graduated cylinder or scale (1 g ≈ 1 ml for water).
3. For each target in {100 ml, 200 ml, 300 ml} (adjust to your cup):
   - Run timed dispense **10 times**
   - Record volume or mass each time
4. Compute mean error and range.

### 4.2 Weight-on-scale method (preferred once powder path is stable)

1. Tare empty cup (or tare after powder if combined — for pure water test use empty cup).
2. Pump until Δmass ≈ target grams.
3. Repeat 10× at 200 ml equivalent (200 g).

### 4.3 Pass criteria (water)

| Method | Pass |
|--------|------|
| Timed | Mean within **±10 ml** of target; no single run beyond **±15 ml** without investigation |
| Weight-based | Mean within **±5 ml** preferred; single runs within **±10 ml** |
| Dry-run protection | Pump stops on timeout if no flow/weight change |
| Leaks | No free pooling at fittings during the session |

Phase 1 exit: **±5–10 ml** band met with the strategy you choose to keep.

---

## 5. Combined Drink Test

### 5.1 Procedure

1. Recipe example: **5 g powder + 250 ml water + mix T seconds**.
2. Full sequence automated if possible.
3. Measure powder verification reading (pre-water) and final total if weight-based water.
4. Repeat **≥ 5** successful drinks for Phase 1 exit ([PROJECT_PLAN.md](PROJECT_PLAN.md)).

### 5.2 Pass criteria

| Check | Pass |
|-------|------|
| Powder verify within ±0.1 g before water (or documented policy if combined) | Yes on ≥ 4 of 5 |
| Water within chosen band | Yes on ≥ 4 of 5 |
| No liquid on electronics | Mandatory |
| Mix runs without cup ejection / spill | Yes |

---

## 6. Scale Drift Check (session hygiene)

1. At start: tare empty cup; note zero stability 30 s.
2. Mid-session: place cal mass; note error.
3. End: same cal mass; if error > 0.1 g vs start, recalibrate before formal data.

---

## 7. Phase 1 Test Sign-Off

| Item | Owner initials / date | Pass? |
|------|----------------------|-------|
| Scale calibration logged | | |
| Open-loop OK | | |
| Closed-loop 20× @ 3 g | | |
| Closed-loop 20× @ 5 g | | |
| Water accuracy | | |
| ≥5 full drinks | | |
| Empty/jam stop behavior | | |

When all pass → Phase 1 exit criteria in [PROJECT_PLAN.md](PROJECT_PLAN.md) can be checked off.

---

## 8. What Not to Optimize During Formal Tests

- Do not change hopper geometry mid-series without labeling a new series
- Do not change settle filter mid-20× run
- Do not include runs after an unrecovered jam in the pass count without noting exclusion rules

Failed runs due to operator error (bumped cup) may be excluded if logged as void and replaced.
