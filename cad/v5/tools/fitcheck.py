#!/usr/bin/env python3
"""Dose Bar v5: interference matrix of the assembled head across its motion states.

Usage:
  python3 cad/v5/tools/fitcheck.py                     # std preset, full matrix (18 states)
  python3 cad/v5/tools/fitcheck.py --quick             # 5 states that cover every pair of extremes
  python3 cad/v5/tools/fitcheck.py --preset pro --jobs 3
  python3 cad/v5/tools/fitcheck.py --parts slide,plunger,dial,pinion,detent
  python3 cad/v5/tools/fitcheck.py --allow base:stop_pin=3   # one-off extra allowance (mm3)

Options:
  --preset P     std | pro | <name> | path/to/preset.scad          (default std)
  --quick        reduced matrix: (pull, dial, chuck) = (0,0,0) (0,V,1) (1,0,1) (1,V,0) (0.5,V/2,1)
  --parts a,b    only these parts (plus the jar); default: every part in posed()
  --no-jar       leave the jar ghost out
  --no-drop      skip the drop-path check (drop hole -> pedestal opening -> dose drawer)
  --no-row       skip the row check (two heads ROW_PITCH apart + joiners)
  --tol MM3      interference tolerance for non-allowlisted pairs (default 0.5)
  --gap MM       report clearances below this (min_gap search length, default 0.6; 0 = off)
  --allow a:b=V  extra allowlist entry (repeatable)
  --jobs N       parallel OpenSCAD processes (default 3)
  --force        ignore the export cache
  --all          list every pair whose bounding boxes overlap, not only findings

What it does:
  1. Exports every part in its ASSEMBLED pose with -D 'PART="posed:<part>"' over the
     state matrix STATE_PULL {0, 0.5, 1} x DIAL_ML {0, V_MAX/2, V_MAX} x CHUCK_CLOSE {0, 1}.
     Which state variables move a part is found by static analysis of the sources
     (SLIDE_Y0, CH_L, DIAL_ANGLE, R_PIN, RING_PHI, ...); a part that does not move
     with a variable is exported once for all its values. Posed STLs are cached by
     (part, state, preset) under build/fit/<preset>/ and re-exported only when a
     source they depend on changes.
  2. Adds the jar ghost (jar_ghost() from dosebar.scad) as part "jar".
  3. Computes every pairwise intersection volume with manifold3d (bbox prefilter,
     results cached by mesh hash) and, for pairs that do not intersect, the
     minimum gap (to catch zero-clearance sliding fits).
  4. Compares against the ALLOWLIST of intended contacts below; any other
     interference > --tol mm3 is a failure.
  5. Skin check: the slide must stay inside a cylinder of radius PUCK_R from z = 0
     to Z_RING_TOP, except where it passes out through the front drawer opening.
     Drop path: a column the size of the drop hole (inset 1 mm), from the floor down
     to the dose drawer's inner floor, must be clear of every part, so a dose falls
     through the base, the pedestal opening and into the drawer.
     Row: two heads ROW_PITCH apart (plus the joiners of row_assembly) must not touch.
  6. Prints a table, writes build/fit/<preset>/report.json and FITCHECK.md.

Exit code: 0 = clean, 1 = unexpected interference / allowance exceeded / skin
violation / unreadable mesh, 2 = tool error.
"""
from __future__ import annotations

import argparse
import itertools
import json
import math
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common as C  # noqa: E402

# ----------------------------------------------------------------------------- allowlist
# Intended contacts: (part a, part b, max intersection mm3 as a function of params, why).
# Anything not listed must stay below --tol (0.5 mm3).
ALLOWLIST = [
    ("wiper", "slide", lambda P: 0.5 * (2 * P["T_WID"] + 40),
     "TPU wiper lip pressed on the slide top (slight interference)"),
    ("jaw_pad", "jar", lambda P: 3 * P["JAW_W"] * P["JAW_H"] * 0.6,
     "TPU pads squeeze the glass neck (<= 0.6 mm per pad)"),
    ("stir_post", "slide", lambda P: 0.0,
     "peg in socket (clearance fit: ~0)"),
    ("pinion", "plunger", lambda P: 4.0,
     "gear mesh with the rack (tiny: polygonal tooth tips)"),
    ("dial", "pinion", lambda P: 4.0,
     "hex key in the pinion bore"),
    ("gasket", "guide_plate", lambda P: 0.3 * math.pi * (P["GASKET_OD"] + P["GASKET_ID"]) * (P["GASKET_T"] - P["GASKET_PROUD"]),
     "TPU gasket pressed into its pocket"),
    # Not in the original brief: the gasket's half-round sealing bead stands above Z_RIM and is
    # meant to be squashed by the jar rim. Bound: a 0.9 mm2 section around the mean rim circle.
    ("gasket", "jar", lambda P: 0.9 * math.pi * (P["GASKET_OD"] + P["GASKET_ID"]) / 2,
     "sealing bead squashed by the jar rim (gasket.scad)"),
    # The brief's "detent vs dial (preload)" became the locking dial: PLA lock ring + TPU dial spring.
    ("lock_ring", "dial", lambda P: 6.0,
     "dial V-teeth seated in the lock ring (touching)"),
    ("dial_spring", "pinion_cap", lambda P: 40.0,
     "TPU dial spring preload (6-10 N) against the pinion cap"),
    ("dial_spring", "dial", lambda P: 40.0,
     "TPU dial spring preload on the dial shaft end"),
    ("dose_drawer", "pedestal", lambda P: 6.0,
     "soft PLA snap bump that holds the dose drawer in"),
]
PARAMS_NEEDED = ["V_MAX", "PUCK_R", "SKIN_T", "Z_RING_TOP", "CHAN_HW", "HANDLE_W", "T_WID", "JAW_W", "JAW_H",
                 "GASKET_OD", "GASKET_ID", "GASKET_T", "GASKET_PROUD", "STROKE", "CLASS_NAME",
                 "CH_W", "HOLE_R", "Z_FLOOR", "hy(HOLE_U0)", "hy(HOLE_U1)"]
# optional (pedestal era); missing names just disable the checks that need them
PARAMS_OPTIONAL = ["CUP_BOT_Z", "CUP_FLOOR_T", "CUP_TOP_Z", "ROW_PITCH"]
SKIN_PARTS = ["slide"]


def pair_key(a, b):
    return tuple(sorted((a, b)))


def matrix(V, quick=False):
    if quick:
        pts = [(0, 0, 0), (0, V, 1), (1, 0, 1), (1, V, 0), (0.5, V / 2, 1)]
    else:
        pts = list(itertools.product((0, 0.5, 1), (0, V / 2, V), (0, 1)))
    return [dict(zip(C.STATE_VARS, p)) for p in pts]


class Meshes:
    """sha -> (Manifold, bounds, trimesh) with one load per unique STL."""

    def __init__(self):
        import numpy as np
        import manifold3d as m3
        self.np, self.m3 = np, m3
        self.cache, self.bad = {}, {}

    def get(self, sha, path):
        if sha in self.cache:
            return self.cache[sha]
        if sha in self.bad:
            return None
        np, m3 = self.np, self.m3
        try:
            tm = C.load_mesh(path)
            mf = m3.Manifold(m3.Mesh(vert_properties=np.asarray(tm.vertices, dtype=np.float32),
                                     tri_verts=np.asarray(tm.faces, dtype=np.uint32)))
            if mf.status() != m3.Error.NoError or mf.is_empty():
                raise ValueError(f"manifold3d: {mf.status()}")
        except Exception as e:  # noqa: BLE001
            self.bad[sha] = str(e)
            return None
        self.cache[sha] = (mf, tm.bounds.copy(), tm)
        return self.cache[sha]


def boxes_overlap(b1, b2, margin=0.0):
    return all(b1[0][i] <= b2[1][i] + margin and b2[0][i] <= b1[1][i] + margin for i in range(3))


def skin_check(slide_mf, slide_tm, P, m3):
    """Volume of the slide outside the puck cylinder, excluding the drawer opening zone."""
    R, ztop = P["PUCK_R"], P["Z_RING_TOP"]
    hw = P["CHAN_HW"] + 0.5                         # drawer opening half width
    y1 = -math.sqrt(max(R * R - hw * hw, 0.0))     # where the opening's sides meet the skin
    big = 4 * R + 400
    cyl = m3.Manifold.cylinder(ztop, R, R, 720, False)
    out = slide_mf - cyl
    opening = m3.Manifold.cube([2 * hw, big, big], True).translate([0, y1 - big / 2, 0])
    front = m3.Manifold.cube([big, big, big], True).translate([0, -R - big / 2, 0])
    viol = (out - opening) - front
    vol = viol.volume()
    np = C.require("numpy")
    v = np.asarray(slide_tm.vertices)
    inside_zone = ~((np.abs(v[:, 0]) <= hw) & (v[:, 1] <= y1)) & (v[:, 1] >= -R)
    rmax = float(np.sqrt((v[inside_zone, 0] ** 2 + v[inside_zone, 1] ** 2)).max()) if inside_zone.any() else 0.0
    zmin, zmax = float(v[:, 2].min()), float(v[:, 2].max())
    bb = viol.bounding_box() if vol > 1e-6 else None
    return {"outside_mm3": round(vol, 3), "r_max": round(rmax, 2), "skin_inner_r": round(R - P["SKIN_T"], 2),
            "z_range": [round(zmin, 2), round(zmax, 2)], "violation_bbox": bb}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog=__doc__.split("\n\n", 1)[1])
    ap.add_argument("--preset", default="std")
    ap.add_argument("--quick", action="store_true")
    ap.add_argument("--parts", default="")
    ap.add_argument("--no-jar", action="store_true")
    ap.add_argument("--no-drop", action="store_true")
    ap.add_argument("--no-row", action="store_true")
    ap.add_argument("--tol", type=float, default=0.5)
    ap.add_argument("--gap", type=float, default=0.6)
    ap.add_argument("--allow", action="append", default=[])
    ap.add_argument("--jobs", type=int, default=3)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--timeout", type=int, default=900)
    args = ap.parse_args(argv)
    for mod in ("numpy", "trimesh", "manifold3d"):
        C.require(mod)
    import manifold3d as m3

    t0 = time.time()
    cache = C.PosedCache(args.preset, jobs=args.jobs, timeout=args.timeout, force=args.force)
    P = C.eval_scad(PARAMS_NEEDED, cache.base_defs, cache.dir / "_scad")
    opt = C.eval_scad([f"is_undef({k}) ? undef : {k}" for k in PARAMS_OPTIONAL], cache.base_defs, cache.dir / "_scad")
    P.update({k: opt[f"is_undef({k}) ? undef : {k}"] for k in PARAMS_OPTIONAL})
    V = float(P["V_MAX"])
    states = matrix(V, args.quick)
    parts = cache.head_parts
    if args.parts:
        want = [p.strip() for p in args.parts.split(",") if p.strip()]
        bad = [p for p in want if p not in cache.posed_names and p != "jar"]
        if bad:
            raise SystemExit(f"not in posed(): {', '.join(bad)}  (have: {', '.join(parts)})")
        parts = [p for p in want if p != "jar"]
    C.say(f"[fitcheck] {cache.preset} (class {P['CLASS_NAME']}, V_MAX {V:g} mL): {len(parts)} parts x "
          f"{len(states)} states{' (quick)' if args.quick else ''}")

    deps = cache.deps(parts)                      # static: which state variables move each part
    res = cache.export_states([(p, st) for p in parts for st in states], deps)
    stubs, errored, live = [], {}, []
    for p in parts:
        rs = [r for (q, _), r in res.items() if q == p and r is not None]
        if rs and all(r.get("status") == "empty" for r in rs):
            stubs.append(p)
            continue
        bad = [r for r in rs if r.get("status") not in ("ok", "empty")]
        if bad:
            errored[p] = bad[0].get("errors") or [bad[0].get("status")]
        if any(r.get("status") == "ok" for r in rs):
            live.append(p)
    for p in live:
        C.say(f"  {p:<12} moves with: {', '.join(deps[p]) or '(static)'}")
    if stubs:
        C.say(f"  not implemented (skipped): {', '.join(stubs)}")
    for p, e in errored.items():
        C.say(f"  EXPORT ERROR {p}: {'; '.join(e or [])[:300]}")
    jar = None
    if not args.no_jar:
        jr = cache.export_jar()
        if jr["status"] == "ok":
            jar = jr
        else:
            C.say(f"  jar ghost export failed: {jr.get('errors')}")

    meshes = Meshes()
    pairs_file = cache.dir / "pairs.json"
    try:
        pcache = json.loads(pairs_file.read_text())
    except Exception:  # noqa: BLE001
        pcache = {}

    allow = {}
    for a, b, fn, why in ALLOWLIST:
        allow[pair_key(a, b)] = (float(fn(P)), why)
    for spec in args.allow:
        try:
            ab, vol = spec.split("=")
            a, b = ab.split(":")
            allow[pair_key(a.strip(), b.strip())] = (float(vol), "command line --allow")
        except ValueError:
            raise SystemExit(f"bad --allow '{spec}' (use a:b=mm3)")

    findings = {}       # pair -> {max, state, gap_min, gap_state, per_state}
    unreadable = {}
    skin, skin_memo = [], {}
    n_bool = n_gap = 0
    for st in states:
        sk = C.state_key(st)
        items = []
        for p in live:
            r = res.get((p, sk))
            if r is None or r.get("status") != "ok":
                continue
            g = meshes.get(r["sha"], r["path"])
            if g is None:
                unreadable[p] = meshes.bad.get(r["sha"])
                continue
            items.append((p, r["sha"], g))
        if jar is not None:
            g = meshes.get(jar["sha"], jar["path"])
            if g is None:
                unreadable["jar"] = meshes.bad.get(jar["sha"])
            else:
                items.append(("jar", jar["sha"], g))
        for (pa, sa, ga), (pb, sb, gb) in itertools.combinations(items, 2):
            key = "|".join(sorted((sa, sb)))
            ent = pcache.get(key)
            if ent is None or (args.gap > 0 and ent.get("gap_len", 0) < args.gap):
                ent = dict(ent or {})
                if not boxes_overlap(ga[1], gb[1], max(args.gap, 0.01)):
                    ent.update(vol=0.0, gap=None, gap_len=max(args.gap, 0.01))
                else:
                    if "vol" not in ent:
                        ent["vol"] = max(0.0, (ga[0] ^ gb[0]).volume())
                        n_bool += 1
                    if args.gap > 0 and ent["vol"] <= 1e-6:
                        gval = float(ga[0].min_gap(gb[0], args.gap))
                        ent["gap"] = round(gval, 4) if gval < args.gap else None
                        n_gap += 1
                    else:
                        ent["gap"] = 0.0 if ent["vol"] > 1e-6 else None
                    ent["gap_len"] = max(args.gap, 0.01)
                pcache[key] = ent
            pk = pair_key(pa, pb)
            f = findings.setdefault(pk, {"max": 0.0, "state": None, "gap_min": None, "gap_state": None,
                                         "overlap": False, "per_state": {}})
            f["overlap"] |= boxes_overlap(ga[1], gb[1], 0.01)
            v = float(ent["vol"])
            f["per_state"][sk] = round(v, 3)
            if f["state"] is None or v > f["max"] + 1e-6:
                f["max"], f["state"] = v, st
            gp = ent.get("gap")
            if gp is not None and gp < args.gap and (f["gap_min"] is None or gp < f["gap_min"]):
                f["gap_min"], f["gap_state"] = gp, st
        for p in SKIN_PARTS:
            for (pa, sa, ga) in items:
                if pa == p:
                    if sa not in skin_memo:
                        skin_memo[sa] = skin_check(ga[0], ga[2], P, m3)
                    skin.append({**skin_memo[sa], "state": st})
    C.write_json_atomic(pairs_file, pcache, indent=None)

    # --------------------------------------------------------------- drop path: hole -> dose drawer
    # A column the size of the drop hole (inset 1 mm) from the floor down to just above the
    # dose drawer's inner floor must be free of every part: base hole, pedestal opening and
    # drawer cavity line up, so the dose really lands in the drawer.
    drop = []
    if not args.no_drop:
        y0, y1 = sorted((float(P["hy(HOLE_U0)"]), float(P["hy(HOLE_U1)"])))
        w, l = float(P["CH_W"]) - 2.0, (y1 - y0) - 2.0
        r = max(0.5, float(P["HOLE_R"]) - 1.0)
        zb = (float(P["CUP_BOT_Z"]) + float(P["CUP_FLOOR_T"]) + 1.0) if P.get("CUP_BOT_Z") is not None else -1.0
        zt = float(P["Z_FLOOR"]) - 0.05
        cs = m3.CrossSection.square([w, l], True).offset(-r, m3.JoinType.Miter).offset(r, m3.JoinType.Round, 2.0, 48)
        col = m3.Manifold.extrude(cs, zt - zb).translate([0.0, (y0 + y1) / 2, zb])
        worst = {}
        for st in [s_ for s_ in states if s_["STATE_PULL"] in (0, 1)] or states:
            for p in live:
                r_ = res.get((p, C.state_key(st)))
                g = meshes.get(r_["sha"], r_["path"]) if r_ and r_.get("status") == "ok" else None
                if g is None:
                    continue
                v = max(0.0, (col ^ g[0]).volume())
                if v > worst.get(p, (-1.0, None))[0]:
                    worst[p] = (v, st)
        for p, (v, st) in sorted(worst.items(), key=lambda t: -t[1][0]):
            drop.append({"what": p, "mm3": round(v, 3), "state": st, "ok": v <= args.tol})
        drop_info = f"{w:.0f} x {l:.0f} mm column, z {zb:.1f} .. {zt:.1f}"

    # --------------------------------------------------------------- row: two heads side by side
    row = []
    if not args.no_row and P.get("ROW_PITCH") is not None:
        rr = cache.export_row(2)
        gj = meshes.get(rr["sha"], rr["path"]) if rr["status"] == "ok" else None
        pitch = float(P["ROW_PITCH"])
        st = next((s_ for s_ in states if s_["STATE_PULL"] == 0 and s_["CHUCK_CLOSE"] == 1), states[0])
        heads = []
        for p in live:
            r_ = res.get((p, C.state_key(st)))
            g = meshes.get(r_["sha"], r_["path"]) if r_ and r_.get("status") == "ok" else None
            if g is not None:
                heads.append((p, g))
        if jar is not None:
            g = meshes.get(jar["sha"], jar["path"])
            if g is not None:
                heads.append(("jar", g))
        for pa, ga in heads:                       # head 0 against head 1 (one pitch to the right)
            for pb, gb in heads:
                b2 = [[gb[1][0][0] + pitch, gb[1][0][1], gb[1][0][2]], [gb[1][1][0] + pitch, gb[1][1][1], gb[1][1][2]]]
                if not boxes_overlap(ga[1], b2, 0.01):
                    continue
                v = max(0.0, (ga[0] ^ gb[0].translate([pitch, 0.0, 0.0])).volume())
                if v > 1e-3:
                    row.append({"what": f"head0.{pa} x head1.{pb}", "mm3": round(v, 3), "ok": v <= args.tol})
        if gj is not None:
            for p, g in heads:
                for k in (0, 1):
                    v = max(0.0, (gj[0] ^ g[0].translate([k * pitch, 0.0, 0.0])).volume())
                    if v > 1e-3:
                        row.append({"what": f"joiner x head{k}.{p}", "mm3": round(v, 3), "ok": v <= args.tol})
        row_info = (f"pitch {pitch:.1f} mm, joiners {'present' if gj is not None else 'not implemented'}, "
                    f"{len(heads)} parts per head")

    # --------------------------------------------------------------- verdicts
    rows, fails = [], []
    for pk, f in sorted(findings.items()):
        al = allow.get(pk)
        v = f["max"]
        if al is not None:
            lim = max(al[0], args.tol)
            verdict = "OK (intended contact)" if v <= lim else f"FAIL (allowance {lim:.1f} exceeded)"
        else:
            lim = args.tol
            verdict = "OK" if v <= lim else "FAIL (unexpected interference)"
            if v <= lim and v > 1e-3:
                verdict = "OK (touching, below tol)"
        if f["gap_min"] is not None and f["gap_min"] < 0.05 and v <= 1e-6:
            verdict += "; touching (0 gap)"
        show = args.all and f["overlap"] or v > 1e-3 or al is not None or (f["gap_min"] is not None)
        row = {"pair": pk, "max_mm3": round(v, 3), "state": f["state"], "limit": round(lim, 2),
               "allow_why": al[1] if al else None, "gap_min": f["gap_min"], "gap_state": f["gap_state"],
               "verdict": verdict, "per_state": f["per_state"]}
        if verdict.startswith("FAIL"):
            fails.append(row)
        if show:
            rows.append(row)
    for pk, (lim, why) in allow.items():
        if pk not in findings:
            rows.append({"pair": pk, "max_mm3": None, "state": None, "limit": lim, "allow_why": why, "gap_min": None,
                         "gap_state": None, "verdict": "not checked (part missing)", "per_state": {}})
    skin_fail = [s for s in skin if s["outside_mm3"] > args.tol]
    drop_fail = [d for d in drop if not d["ok"]]
    row_fail = [d for d in row if not d["ok"]]

    def fs(st):
        return C.fmt_state(st) if st else "-"

    rows.sort(key=lambda r: (not r["verdict"].startswith("FAIL"), r["max_mm3"] is None, -(r["max_mm3"] or 0)))
    w = max([len(f"{a} x {b}") for a, b in (r["pair"] for r in rows)] + [10])
    C.say("")
    C.say(f"{'pair':<{w}}  {'max mm3':>9}  {'worst state':<34} {'limit':>7}  {'min gap':>7}  verdict")
    C.say("-" * (w + 90))
    for r in rows:
        a, b = r["pair"]
        mv = "-" if r["max_mm3"] is None else f"{r['max_mm3']:.2f}"
        gp = "-" if r["gap_min"] is None else f"{r['gap_min']:.2f}"
        st = fs(r["state"]) if (r["max_mm3"] or 0) > 1e-3 else (fs(r["gap_state"]) if r["gap_min"] is not None else "-")
        C.say(f"{a + ' x ' + b:<{w}}  {mv:>9}  {st:<34} {r['limit']:>7.1f}  {gp:>7}  {r['verdict']}")
    if skin:
        worst = max(skin, key=lambda s: s["outside_mm3"])
        C.say("")
        C.say(f"skin: slide outside the puck (excluding the drawer opening): max {worst['outside_mm3']:.2f} mm3"
              f" at {fs(worst['state'])}; slide reaches r = {max(s['r_max'] for s in skin):.1f} mm behind the front"
              f" (puck R {P['PUCK_R']:.1f}, skin inner R {skin[0]['skin_inner_r']:.1f})")
    elif "slide" in parts:
        C.say("\nskin: slide not available (stub), skipped")
    if not args.no_drop:
        C.say(f"\ndrop path (drop hole -> dose drawer; {drop_info}):")
        blocked = [d for d in drop if d["mm3"] > 1e-3]
        for d in blocked:
            C.say(f"  blocked by {d['what']:<14} {d['mm3']:>9.2f} mm3  {'OK (< tol)' if d['ok'] else 'FAIL'}  ({fs(d['state'])})")
        if not blocked:
            C.say(f"  clear ({len(drop)} parts checked)")
    if row or (not args.no_row and P.get("ROW_PITCH") is not None):
        C.say(f"\nrow (two heads side by side; {row_info}):")
        for d in row:
            C.say(f"  {d['what']:<40} {d['mm3']:>9.2f} mm3  {'OK (< tol)' if d['ok'] else 'FAIL'}")
        if not row:
            C.say("  no contact between neighbouring heads or joiners")
    if stubs:
        C.say(f"\nskipped (not implemented): {', '.join(stubs)}")
    if unreadable:
        C.say("unreadable meshes (not a valid 2-manifold):")
        for p, e in unreadable.items():
            C.say(f"  {p}: {e}")
    for p, e in errored.items():
        C.say(f"export error {p}: {'; '.join(e or [])[:300]}")
    status = 0
    if fails or skin_fail or drop_fail or row_fail or unreadable or errored:
        status = 1
    n_pairs = len(findings)
    C.say(f"\n[fitcheck] {cache.preset}: {len(live)} parts{' + jar' if jar else ''}, {len(states)} states, "
          f"{n_pairs} pairs, {n_bool} new booleans, {n_gap} new gap queries, {time.time() - t0:.0f}s")
    C.say(f"RESULT: {'PASS' if status == 0 else 'FAIL'}"
          + (f"  ({len(fails)} interference failure(s))" if fails else "")
          + (f"  (skin violations in {len(skin_fail)} state(s))" if skin_fail else "")
          + (f"  (drop path blocked by {', '.join(d['what'] for d in drop_fail)})" if drop_fail else "")
          + (f"  ({len(row_fail)} row collision(s))" if row_fail else "")
          + (f"  ({len(unreadable)} unreadable mesh(es))" if unreadable else "")
          + (f"  ({len(errored)} export error(s))" if errored else ""))

    report = {
        "preset": cache.preset, "params": P, "states": states, "quick": args.quick, "tol_mm3": args.tol,
        "parts": live, "stubs": stubs, "export_errors": errored, "unreadable": unreadable,
        "deps": {p: deps.get(p) for p in parts}, "jar": bool(jar),
        "allowlist": {f"{a}|{b}": {"max_mm3": round(v[0], 2), "why": v[1]} for (a, b), v in allow.items()},
        "pairs": [{**r, "pair": list(r["pair"])} for r in rows], "fails": [list(r["pair"]) for r in fails],
        "skin": skin, "drop_path": drop, "row": row, "result": "PASS" if status == 0 else "FAIL",
    }
    C.write_json_atomic(cache.dir / "report.json", report)
    md = [f"# Fit check: preset `{cache.preset}`", "",
          f"{len(live)} parts{' + jar' if jar else ''} over {len(states)} states. Result: **{report['result']}**.", "",
          "| Pair | Max mm³ | Worst state | Limit | Min gap | Verdict |", "|---|---:|---|---:|---:|---|"]
    for r in rows:
        a, b = r["pair"]
        mv = "-" if r["max_mm3"] is None else f"{r['max_mm3']:.2f}"
        gp = "-" if r["gap_min"] is None else f"{r['gap_min']:.2f}"
        st = fs(r["state"]) if (r["max_mm3"] or 0) > 1e-3 else "-"
        md.append(f"| {a} × {b} | {mv} | {st} | {r['limit']:.1f} | {gp} | {r['verdict']} |")
    if skin:
        worst = max(skin, key=lambda s: s["outside_mm3"])
        md += ["", f"Skin: slide outside the puck (drawer opening excluded): max {worst['outside_mm3']:.2f} mm³ "
                   f"({fs(worst['state'])}); max radius behind the front {max(s['r_max'] for s in skin):.1f} mm "
                   f"(puck R {P['PUCK_R']:.1f}, skin inner {skin[0]['skin_inner_r']:.1f})."]
    if drop:
        bl = [d for d in drop if d["mm3"] > 1e-3]
        md += ["", "Drop path (drop hole to dose drawer): " + ("clear." if not bl else
               "; ".join(f"blocked by {d['what']} {d['mm3']:.2f} mm³{'' if d['ok'] else ' **FAIL**'}" for d in bl))]
    if row:
        md += ["", "Row (two heads side by side):", ""] + [
            f"- {d['what']}: {d['mm3']:.2f} mm³ {'OK' if d['ok'] else '**FAIL**'}" for d in row]
    if stubs:
        md += ["", f"Skipped (not implemented): {', '.join(stubs)}."]
    (cache.dir / "FITCHECK.md").write_text("\n".join(md) + "\n")
    return status


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception as e:  # noqa: BLE001
        import traceback
        traceback.print_exc()
        print(f"[fitcheck] tool error: {e}", file=sys.stderr)
        sys.exit(2)
