# Testing Protocol – Phase 1

Procedures and pass/fail criteria for scale calibration, powder dosing, water volume, and full drinks. Complements [ASSEMBLY_GUIDE.md](ASSEMBLY_GUIDE.md) and [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md).

**Primary success criteria (Phase 1):**

| Quantity | Target tolerance | Notes |
|----------|------------------|--------|
| Powder mass (after settle) | **±0.1 g of target** | **Goal** for closed-loop powder; prove with 20× series |
| Water volume | **±5–10 ml of target** | **Open-loop timed** after calibration; verify with graduated cylinder / scale |

Phase 1 water is **not** automatic closed-loop. Success means a **calibrated timed dose** that stays in band when re-checked — not a flow-sensor or weight-of-water controller (those are future options).

Vibration assist: **pulse only** during powder dosing (not continuous vibe for the entire dose). Continuous vibe was removed from the software contract to reduce scale noise and motor wear.

---

## 0. Lab Notes Template (use every session)

Record at minimum:

- Date, ambient notes (humidity if known)
- Powder type / brand / approximate grind
- Firmware/software commit or version label
- Scale calibration factor and cal weights used
- Pump `ml_per_second` calibration (timed water)
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
3. Vibe available with a fixed **pulse** policy (e.g. vibe pulse every N bursts — not continuous on).

### 2.2 Procedure

1. Run a fixed command: e.g. **M steps** or **T ms** of auger at fixed speed.
2. Settle ≥ your standard settle window; record Δmass.
3. Repeat **10 times** without changing parameters; empty or account for cup capacity (use large cup or empty between runs).
4. Optionally double the command and confirm roughly double mass (nonlinearity is OK but should be monotonic).

### 2.3 Pass criteria (open-loop)

| Check | Pass |
|-------|------|
| Mass increases every run | No zero-delivery runs (unless intentionally empty) |
| No permanent bridge | At most occasional need for extra vibe pulse; not stuck every shot |
| Coefficient of variation | Record CV; high CV is OK if closed-loop can correct — flag if CV catastrophic |
| No mechanical bind | Motor does not skip/stall under normal fill |

**Fail →** fix geometry/clearance/vibe before closed-loop campaigns ([PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md)).

---

## 3. Closed-Loop Powder Tests

Purpose: prove **±0.1 g after settle** on repeated dispenses (**goal** for Phase 1 exit).

### 3.1 Algorithm under test

Must match architecture intent:

1. Tare with empty cup  
2. Burst auger (+ **pulse** vibe)  
3. Settle → read  
4. Adapt bursts until target approached  
5. Final settle → **verify**  

See control loop in [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md). Implementation: `PowderDoser` in software.

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
5. Record: `target`, `measured_final`, `error`, `burst_count` / duration, `faults`.
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

If 18/20 fails: tune settle time, burst schedule, overshoot margin, vibe **pulse** timing; re-check open-loop flow; only then revise geometry.

### 3.5 Empty / jam injection (minimum)

1. Run closed-loop with **empty hopper** → must fault EMPTY (or JAM) and stop actuation, not spin forever.
2. Induce a soft bridge if possible (tap sides only as test setup) → recovery reverse/vibe pulse or clear fault path works.

---

## 4. Water Volume Accuracy Test (Open-Loop Timed)

**Important:** Phase 1 software doses water by **time × calibrated ml/s**. There is no closed-loop flow or weight-of-water strategy in the current stack. You **must** measure with a graduated cylinder (or scale, 1 g ≈ 1 ml) to know true volume.

### 4.1 Timed pump method (Phase 1 primary)

1. Tank filled to a marked level (e.g. half full); note level.
2. Dispense into **graduated cylinder** or scale.
3. For each target in {100 ml, 200 ml, 300 ml} (adjust to your cup):
   - Run timed dispense **10 times**
   - Record volume or mass each time
4. Compute mean error and range.
5. Update `ml_per_second` (or pump calibration in software) until mean is in band; re-run confirmation set.

### 4.2 Weight-on-scale method (lab check only)

Using the cup scale as a **lab instrument** to measure water mass is fine for verification. That is **not** the same as software closed-loop weight-based dosing (not implemented in Phase 1).

1. Tare empty cup.
2. Run the same timed water command.
3. Read Δmass ≈ ml; compare to target.

### 4.3 Pass criteria (water)

| Method | Pass |
|--------|------|
| Timed (production path) | Mean within **±10 ml** of target; no single run beyond **±15 ml** without investigation |
| Lab verification on scale | Same band; document any systematic offset and recalibrate rate |
| Dry-run protection | Pump stops on timeout / level empty when interlocks present |
| Leaks | No free pooling at fittings during the session |

Phase 1 exit: **±5–10 ml** band met with **calibrated open-loop timed** dosing. Success is **not** “closed-loop water works out of the box.”

---

## 5. Combined Drink Test

### 5.1 Procedure

1. Recipe example: **5 g powder + 250 ml water** (+ software `mix_delay` sleep; no mixer motor).
2. Full sequence automated if possible.
3. Measure powder verification reading (pre-water) and water volume with cylinder or post-dose scale check.
4. Repeat **≥ 5** successful drinks for Phase 1 exit ([PROJECT_PLAN.md](PROJECT_PLAN.md)).

### 5.2 Pass criteria

| Check | Pass |
|-------|------|
| Powder verify within ±0.1 g before water (goal) | Yes on ≥ 4 of 5 |
| Water within chosen band (calibrated timed) | Yes on ≥ 4 of 5 |
| No liquid on electronics | Mandatory |
| mix_delay completes without cup ejection / spill | Yes |
| Drink quality | Nice to have — **not** a formal pass criterion |

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
| Open-loop powder OK | | |
| Closed-loop 20× @ 3 g (±0.1 g goal) | | |
| Closed-loop 20× @ 5 g (±0.1 g goal) | | |
| Water accuracy (grad cylinder; open-loop timed) | | |
| ≥5 full drinks (powder + water + settle) | | |
| Empty/jam stop behavior | | |

When all pass → Phase 1 exit criteria in [PROJECT_PLAN.md](PROJECT_PLAN.md) can be checked off.

---

## 8. What Not to Optimize During Formal Tests

- Do not change hopper geometry mid-series without labeling a new series
- Do not change settle filter mid-20× run
- Do not re-enable continuous vibe mid-campaign (pulse policy only)
- Do not include runs after an unrecovered jam in the pass count without noting exclusion rules

Failed runs due to operator error (bumped cup) may be excluded if logged as void and replaced.
