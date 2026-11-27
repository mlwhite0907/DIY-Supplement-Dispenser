#!/usr/bin/env python3
"""Dose Bar v5: export printable STLs for a jar preset, with a parts list and grams.

Usage (from the repo root or anywhere):
  python3 cad/v5/tools/build.py --preset std
  python3 cad/v5/tools/build.py --preset pro --parts slide,dial,dial_inlay
  python3 cad/v5/tools/build.py --preset all --jobs 3
  python3 cad/v5/tools/build.py --preset std --name WHEY,CREATINE,COLLAGEN   # one name plate each
  python3 cad/v5/tools/build.py --preset _template                          # small-jar template

Options:
  --preset P      std | pro | <name> (presets/<name>.scad) | path/to/preset.scad | all
                  ("all" = every preset whose name does not start with "_")
  --parts a,b     only these parts (any name in dosebar.scad's printed() dispatch)
  --name TXT      name-plate text (default: NAME in dosebar.scad); a comma list exports
                  one name_plate/name_inlay pair per name (name_plate__WHEY.stl ...)
  --jobs N        parallel OpenSCAD processes (default 3)
  --out DIR       output root (default cad/v5/build); files go to <out>/<preset>/
  --no-extras     skip printable extras that are not in the PARTS registry (test coupon)
  --force         re-export even if the sources did not change
  --strict        exit non-zero if any registry part is still a stub
  --timeout S     per-part OpenSCAD timeout in seconds (default 900)

What it does:
  * Reads presets/<name>.scad and passes each NAME = value; line as -D NAME=value
    (argument list, no shell; string values keep their quotes).
  * Parses the PARTS registry in dosebar.scad and exports every printed part with
    -D 'PART="<part>"' in a process pool, to <out>/<preset>/<part>.stl.
  * Checks every STL with trimesh: watertight, volume > 0, bbox fits 250 x 250 x 250,
    sits on z = 0; estimates grams:
        shell = min(V, surface_area * 1.2 mm); grams = density * (shell + 0.15 * (V - shell))
        density PLA 1.24, TPU 1.21 g/cm3.
  * Writes <out>/<preset>/manifest.json and PARTS.md (part, material, color role,
    qty, grams each/total, bbox, status) with totals per head and per bay.
  * A part whose module is still an empty stub (OpenSCAD: "Current top level object
    is empty") is listed as "not implemented" and skipped.
  * Unchanged parts are not re-exported: each STL is keyed by a fingerprint of the
    sources it depends on (entry, params, lib, preset values, its part file(s)).

Exit code: 0 when every implemented registry part is OK; 1 otherwise.
"""
from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common as C  # noqa: E402

NAME_PARTS_HINT = ("name_plate", "name_inlay")


def name_dependent(text: str) -> set:
    """Parts whose printed() dispatch passes NAME (name plate + its ink)."""
    t = text
    m = re.search(r"\bmodule\s+printed\s*\(\s*name\s*\)\s*\{", t)
    out = set()
    if m:
        body = t[m.end():C._match(t, m.end() - 1)]
        for part, call in re.findall(r'name\s*==\s*"([^"]+)"\s*\)\s*([^;]*);', body):
            if re.search(r"\bNAME\b", call):
                out.add(part)
    return out or set(NAME_PARTS_HINT)


def _export_job(job: dict) -> dict:
    """Runs in a worker process: OpenSCAD export + STL metrics."""
    out = Path(job["out"])
    rec = {k: job[k] for k in ("preset", "part", "file", "material", "color", "qty", "registry", "name", "fingerprint")}
    res = C.run_openscad(out, job["defs"], timeout=job["timeout"])
    rec.update(seconds=round(res.seconds, 1), warnings=res.warnings[:10], errors=res.errors[:10])
    rec["dims"] = next((e for e in res.echoes if "[dosebar]" in e), None)
    if res.status == "empty":
        rec.update(status="not implemented", issues=["module is an empty stub (nothing to export)"])
        return rec
    if res.status != "ok":
        rec.update(status=res.status, issues=res.errors[:6] or [res.status])
        return rec
    try:
        met = C.stl_metrics(out, job["material"])
    except Exception as e:  # noqa: BLE001
        rec.update(status="error", issues=[f"could not read STL: {e}"])
        return rec
    rec.update(met)
    issues, warns = [], []
    if not met["watertight"]:
        issues.append("not watertight")
    if met["volume_mm3"] <= 0:
        issues.append("volume <= 0")
    if not met["fits_bed"]:
        issues.append("bbox exceeds 250 x 250 x 250")
    lo, hi = met["bounds_mm"] or ([0, 0, 0], [0, 0, 0])
    if abs(lo[2]) > 0.05 and job["color"] != "ink":     # ink shares its parent's pose
        warns.append(f"not on the bed: z min = {lo[2]:.2f} (print pose should sit on z = 0)")
    cx, cy = (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2
    if max(abs(lo[0]), abs(hi[0]), abs(lo[1]), abs(hi[1])) > C.BED_MM / 2 + 3:
        warns.append(f"not centred: bbox centre at ({cx:.0f}, {cy:.0f})")
    if any("2-manifold" in w for w in res.warnings):
        warns.append("OpenSCAD: object may not be a valid 2-manifold")
    rec["warnings_geom"] = warns
    rec["status"] = "ok" if not issues else "FAIL"
    rec["issues"] = issues
    return rec


def plan(preset: str, args, text: str) -> tuple:
    label = C.preset_label(preset)
    vals = C.read_preset(preset)
    reg = C.parts_registry(text)
    printable = C.dispatch_names("printed", text)
    posed = set(C.dispatch_names("posed", text))
    reg_names = [r["name"] for r in reg]
    by = {r["name"]: r for r in reg}
    if args.parts:
        want = [p.strip() for p in args.parts.split(",") if p.strip()]
        unknown = [p for p in want if p not in printable and p not in by]
        if unknown:
            raise SystemExit(f"unknown part(s): {', '.join(unknown)}\n  printable: {', '.join(printable)}")
    else:
        want = reg_names + ([] if args.no_extras else [p for p in printable if p not in by])
    names = [n.strip() for n in (args.name.split(",") if args.name else [C.default_name(text)]) if n.strip()]
    named = name_dependent(text)
    outdir = Path(args.out) / label
    outdir.mkdir(parents=True, exist_ok=True)
    src = C.SourceIndex()
    try:
        old = {(p["part"], p.get("name")): p for p in json.loads((outdir / "manifest.json").read_text())["parts"]}
    except Exception:  # noqa: BLE001
        old = {}
    jobs, reused = [], []
    base = C.defs_from(vals)
    for part in want:
        r = by.get(part)
        if r is None:
            mat = "PLA"
            role = "ink" if "inlay" in part else "body"
            r = {"name": part, "material": mat, "qty": 0, "color": role}
        for nm in (names if part in named else [None]):
            suffix = f"__{re.sub(r'[^A-Za-z0-9_-]+', '_', nm)}" if (nm is not None and len(names) > 1) else ""
            fname = f"{part}{suffix}.stl"
            defs = base + [f"NAME={C.scad_str(nm if nm is not None else names[0])}", f"PART={C.scad_str(part)}"]
            fp = src.fingerprint([f"{part}_print", part], defs)
            job = dict(preset=label, part=part, file=fname, out=str(outdir / fname), defs=defs,
                       material=r["material"], color=r["color"], qty=r["qty"], registry=part in by,
                       name=nm, fingerprint=fp, timeout=args.timeout, head=part in posed)
            prev = old.get((part, nm))
            if (not args.force and prev and prev.get("fingerprint") == fp and prev.get("status") in ("ok", "not implemented")
                    and (prev.get("status") != "ok" or (outdir / fname).exists())):
                reused.append({**prev, "cached": True, "head": part in posed, "registry": part in by,
                               "qty": r["qty"], "color": r["color"], "material": r["material"]})
            else:
                jobs.append(job)
    return label, vals, outdir, jobs, reused, names


def per_copy(rec: dict) -> tuple:
    """(grams per piece, STL files to print per head). An STL that already holds all
    `qty` pieces (bodies == qty) is printed once."""
    g, q, b = rec.get("grams") or 0.0, rec.get("qty") or 0, rec.get("bodies") or 1
    if isinstance(q, (int, float)) and q > 1 and b == q:
        return g / q, 1
    return g, q


PLATE_GAP = 6.0      # mm between parts on a plate


def plate_plan(rows, colors, bed=C.BED_MM):
    """Group one head's (or bay's) STLs into build plates by filament and pack their
    footprints with a simple shelf packer. Ink STLs ride with their parent."""
    groups = {}
    for r in rows:
        if r.get("status") != "ok" or r.get("color") == "ink" or not r.get("bbox_mm"):
            continue
        _, copies = per_copy(r)
        w, h = r["bbox_mm"][0] + PLATE_GAP, r["bbox_mm"][1] + PLATE_GAP
        key = (r["material"], r["color"])
        for _ in range(int(copies or 0)):
            groups.setdefault(key, []).append((r["file"], max(w, h), min(w, h)))
    plates = []
    for (mat, role), items in sorted(groups.items()):
        items.sort(key=lambda t: (-t[2], -t[1]))
        bins = []                                   # each: {"shelves": [[y, height, x_used]], "files": [...]}
        for f, w, h in items:
            placed = False
            for b in bins:
                for sh in b["shelves"]:
                    if sh[2] + w <= bed + PLATE_GAP and h <= sh[1]:
                        sh[2] += w
                        b["files"].append(f)
                        b["area"] += (w - PLATE_GAP) * (h - PLATE_GAP)
                        placed = True
                        break
                if not placed:
                    top = sum(sh[1] for sh in b["shelves"])
                    if top + h <= bed + PLATE_GAP and w <= bed + PLATE_GAP:
                        b["shelves"].append([top, h, w])
                        b["files"].append(f)
                        b["area"] += (w - PLATE_GAP) * (h - PLATE_GAP)
                        placed = True
                if placed:
                    break
            if not placed:
                bins.append({"shelves": [[0, h, w]], "files": [f], "area": (w - PLATE_GAP) * (h - PLATE_GAP)})
        for b in bins:
            counts = {}
            for f in b["files"]:
                counts[f] = counts.get(f, 0) + 1
            plates.append({"material": mat, "color": role, "hex": colors.get(role, ""),
                           "files": [f"{f} x{n}" if n > 1 else f for f, n in counts.items()],
                           "fill": round(100 * b["area"] / (bed * bed))})
    return plates


def summarize(label, vals, outdir, recs, names, colors, args, dims):
    recs.sort(key=lambda r: (not r.get("registry", True), r.get("order", 999), r.get("name") or ""))
    head = [r for r in recs if r.get("registry") and r.get("head")]
    bay = [r for r in recs if r.get("registry") and not r.get("head")]

    def totals(rows):
        t = {"PLA": 0.0, "TPU": 0.0}
        roles = {}
        seen_named = set()
        for r in rows:
            if r.get("status") != "ok":
                continue
            if r["part"] in seen_named:      # several names: count one plate per head
                continue
            if r.get("name") is not None:
                seen_named.add(r["part"])
            each, _ = per_copy(r)
            g = each * (r.get("qty") or 0)
            t[r["material"]] = t.get(r["material"], 0.0) + g
            roles[r["color"]] = roles.get(r["color"], 0.0) + g
        return {"grams_by_material": {k: round(v, 1) for k, v in t.items()},
                "grams_by_color": {k: round(v, 1) for k, v in sorted(roles.items())},
                "grams": round(sum(t.values()), 1)}

    missing = [r["part"] for r in recs if r.get("registry") and r.get("status") == "not implemented"]
    failed = [r["part"] for r in recs if r.get("registry") and r.get("status") not in ("ok", "not implemented")]
    manifest = {
        "preset": label, "preset_values": vals, "names": names,
        "built_utc": _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        "openscad": C.openscad_version(), "dimension_report": dims,
        "grams_model": {"density_g_cm3": C.DENSITY, "shell_mm": C.SHELL_MM, "infill": C.INFILL},
        "bed_mm": C.BED_MM, "colors": colors,
        "totals": {"per_head": totals(head), "per_bay": totals(bay),
                   "note": "a bar of N bays needs N bay plates and N+1 legs"},
        "not_implemented": missing, "failed": failed,
        "parts": [{k: v for k, v in r.items() if k not in ("defs", "out", "timeout")} for r in recs],
    }
    (outdir / "manifest.json").write_text(json.dumps(manifest, indent=1))

    def fmt_g(x):
        return "" if x is None else f"{x:.1f}"

    lines = [f"# Dose Bar v5: printed parts, preset `{label}`", ""]
    if dims:
        lines += [f"`{dims.replace('ECHO: ', '').strip(chr(34))}`", ""]
    pv = ", ".join(f"{k} {v}" for k, v in vals.items())
    lines += [f"Preset values: {pv}.  ",
              f"Built {manifest['built_utc']} with {manifest['openscad']}. Name plate text: {', '.join(names)}.", ""]
    lines += ["| Part | Material | Color | Qty | g each | g total | BBox x × y × z (mm) | Status |",
              "|---|---|---|---:|---:|---:|---|---|"]
    for r in recs:
        if not r.get("registry"):
            continue
        each, _ = per_copy(r) if r.get("status") == "ok" else (None, None)
        tot = each * (r.get("qty") or 0) if each is not None else None
        bb = " × ".join(f"{e:.1f}" for e in r["bbox_mm"]) if r.get("bbox_mm") else ""
        st = r.get("status", "?")
        notes = list(r.get("issues") or []) + list(r.get("warnings_geom") or [])
        if r.get("status") == "ok" and isinstance(r.get("qty"), (int, float)) and r["qty"] > 1 and r.get("bodies") == r["qty"]:
            notes.append(f"STL holds all {r['qty']}")
        if st == "ok" and not notes:
            st = "OK"
        elif st == "ok":
            st = "OK (" + "; ".join(notes) + ")"
        elif notes and st != "not implemented":
            st = f"{st}: " + "; ".join(notes)
        label_ = f"`{r['file']}`" + (f" ({r['name']})" if r.get("name") is not None and len(names) > 1 else "")
        lines.append(f"| {label_} | {r['material']} | {r['color']} {colors.get(r['color'], '')} | "
                     f"{r['qty']} | {fmt_g(each)} | {fmt_g(tot)} | {bb} | {st} |")
    extras = [r for r in recs if not r.get("registry")]
    if extras:
        lines += ["", "Extras (not per head):", "",
                  "| File | Material | g | BBox (mm) | Status |", "|---|---|---:|---|---|"]
        for r in extras:
            bb = " × ".join(f"{e:.1f}" for e in r["bbox_mm"]) if r.get("bbox_mm") else ""
            st = r.get("status", "?") if r.get("status") != "ok" else "OK"
            lines.append(f"| `{r['file']}` | {r['material']} | {fmt_g(r.get('grams'))} | {bb} | {st} |")
    for title, key in (("Per head", "per_head"), ("Per bay", "per_bay")):
        t = manifest["totals"][key]
        gm = t["grams_by_material"]
        lines += ["", f"## {title}", "",
                  f"- PLA {gm.get('PLA', 0):.0f} g, TPU {gm.get('TPU', 0):.0f} g, total {t['grams']:.0f} g"
                  + (" (parts still stubs are not counted)" if missing else ""),
                  "- By color (AMS slots): " + (", ".join(f"{k} {v:.0f} g ({colors.get(k, '')})"
                                                         for k, v in t["grams_by_color"].items()) or "none yet")]
    for title, rows in (("Plates per head", head), ("Plates per bay", bay)):
        pl = plate_plan(rows, colors)
        if not pl:
            continue
        lines += ["", f"## {title}", "",
                  "Footprints packed on a 250 × 250 mm plate (a starting point: use Arrange in Bambu Studio). "
                  "Ink STLs print together with their parent as one multi-color object.", ""]
        for i, p in enumerate(pl, 1):
            lines.append(f"{i}. **{p['material']} {p['color']}** ({p['hex']}): {', '.join(p['files'])}  (~{p['fill']}% of the bed)")
        manifest["plates_" + ("head" if rows is head else "bay")] = pl
    (outdir / "manifest.json").write_text(json.dumps(manifest, indent=1))
    lines += ["", "A bar of N bays needs N bay plates and N + 1 legs.", "",
              f"Grams are estimates: shell = min(V, area × {C.SHELL_MM} mm); "
              f"g = density × (shell + {C.INFILL:.2f} × (V − shell)); PLA {C.DENSITY['PLA']}, TPU {C.DENSITY['TPU']} g/cm³.",
              ""]
    if missing:
        lines += [f"Not implemented yet (empty stubs): {', '.join(missing)}.", ""]
    (outdir / "PARTS.md").write_text("\n".join(lines))
    return manifest


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    ap.add_argument("--preset", default="std")
    ap.add_argument("--parts", default="")
    ap.add_argument("--name", default="")
    ap.add_argument("--jobs", type=int, default=3)
    ap.add_argument("--out", default=str(C.BUILD))
    ap.add_argument("--no-extras", action="store_true")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--timeout", type=int, default=900)
    args = ap.parse_args(argv)
    C.require("trimesh")
    C.find_openscad()

    text = C.entry_text()
    presets = C.list_presets() if args.preset == "all" else [args.preset]
    order = {r["name"]: i for i, r in enumerate(C.parts_registry(text))}
    colors = C.color_table(text)
    plans = [plan(p, args, text) for p in presets]
    jobs = [j for pl in plans for j in pl[3]]
    n_reused = sum(len(pl[4]) for pl in plans)
    C.say(f"[build] {', '.join(pl[0] for pl in plans)}: {len(jobs)} export(s), {n_reused} unchanged, jobs={args.jobs}")
    results = {pl[0]: list(pl[4]) for pl in plans}
    if jobs:
        with ProcessPoolExecutor(max_workers=max(1, args.jobs)) as ex:
            futs = {ex.submit(_export_job, j): j for j in jobs}
            for f in as_completed(futs):
                j = futs[f]
                try:
                    r = f.result()
                except Exception as e:  # noqa: BLE001
                    r = {k: j[k] for k in ("preset", "part", "file", "material", "color", "qty", "registry", "name", "fingerprint")}
                    r.update(status="error", issues=[repr(e)])
                r["head"] = j["head"]
                results[r["preset"]].append(r)
                msg = r["status"]
                if r["status"] == "ok":
                    msg = f"ok  {r['grams']:.1f} g  {' x '.join(f'{e:.0f}' for e in r['bbox_mm'])} mm  {r['seconds']:.0f}s"
                elif r.get("issues"):
                    msg += "  " + "; ".join(r["issues"])[:160]
                C.say(f"  {r['preset']}/{r['file']:<22} {msg}")
    worst = 0
    for label, vals, outdir, _, _, names in plans:
        recs = results[label]
        for r in recs:
            r["order"] = order.get(r["part"], 999)
        dims = next((r.get("dims") for r in recs if r.get("dims")), None)
        man = summarize(label, vals, outdir, recs, names, colors, args, dims)
        ph = man["totals"]["per_head"]
        ok = sum(1 for r in recs if r.get("registry") and r.get("status") == "ok")
        reg = sum(1 for r in recs if r.get("registry"))
        C.say(f"[build] {label}: {ok}/{reg} registry parts OK, per head ≈ {ph['grams']:.0f} g "
              f"(PLA {ph['grams_by_material'].get('PLA', 0):.0f} g, TPU {ph['grams_by_material'].get('TPU', 0):.0f} g)"
              f"  ->  {os.path.relpath(outdir / 'PARTS.md')}")
        if man["not_implemented"]:
            C.say(f"        not implemented: {', '.join(man['not_implemented'])}")
        if man["failed"]:
            C.say(f"        FAILED: {', '.join(man['failed'])}")
            worst = 1
        if args.strict and man["not_implemented"]:
            worst = 1
    return worst


if __name__ == "__main__":
    sys.exit(main())
