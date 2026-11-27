#!/usr/bin/env python3
"""Dose Bar v5: product-photo renders of the head, the dial and a row of heads.

Usage:
  python3 cad/v5/tools/render_all.py                    # every scene in tools/render/scenes/
  python3 cad/v5/tools/render_all.py --scenes hero,dial
  python3 cad/v5/tools/render_all.py --draft            # half size, 16 samples, to build/renders_draft/
  python3 cad/v5/tools/render_all.py --list

Options:
  --scenes a,b   only these scenes (file names in tools/render/scenes/, without .json)
  --samples N    override the sample count (more = smoother shadows; ~1 s per sample at 1600 x 1200)
  --draft        quick look: half resolution, 16 samples, written to cad/v5/build/renders_draft/
  --out DIR      output folder (default cad/v5/renders)
  --jobs N       parallel OpenSCAD exports (default 3)
  --force        ignore the export cache

Pipeline:
  1. Each scene (tools/render/scenes/<name>.json) lists heads (preset, state, name
     text, jar, powder fill, explode offsets), optionally a row (joiners), and a camera.
  2. Every part in the PARTS registry is exported in its ASSEMBLED pose
     (-D 'PART="posed:<part>"', cached in build/fit/<preset>/ and shared with
     fitcheck.py). Stub parts are skipped, so a scene renders whatever exists.
  3. The jar comes from jar_ghost() in dosebar.scad (rendered as glass); the
     powder is an opaque off-white fill of the jar's inner cavity.
  4. STLs are converted to binary into tools/render/assets/cache/ (the renderer
     only serves files inside tools/render) and a resolved scene is written to
     tools/render/assets/scenes/<name>.json.
  5. node tools/render/render.mjs renders it to <out>/<name>.png.

Colors follow the PARTS color roles in dosebar.scad (body / accent / ink / tpu).
Ink is drawn in the contrast color of the part it is inlaid in, so dial numerals
and name text stay readable even when the ink role shares the parent's color.

Scene file keys (all optional except heads):
  title, width, height, samples, look {render.html keys: exposure, key, dome, ...}
  heads: [{preset, state {STATE_PULL, DIAL_ML, CHUCK_CLOSE}, name, at [x,y,z] | "row:<i>",
           jar (bool), powder (0..1 fill or false), only [...], hide [...],
           explode {part: dz | [dx,dy,dz]}, explode_scale k, explode_jar dz}]
  layout: "row" (heads without "at" are placed side by side, gap in mm: layout_gap)
  row: {preset, n}: add the joiners of row_assembly(n); row_origin: OpenSCAD expression of i
       for "row:<i>" placement (default [i*ROW_PITCH, 0, 0])
  camera: {dir, fov, fill, tags, shift} (see render.html)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import common as C  # noqa: E402

SCENES = C.RENDER_DIR / "scenes"
ASSETS = C.RENDER_DIR / "assets"
OUT = C.V5 / "renders"
DRAFT_OUT = C.BUILD / "renders_draft"
# Heads in a row (docs/v5/BUILD_BRIEFS.md, PEDESTAL): head i at x = i*ROW_PITCH, each on its own
# pedestal (part of the head assembly); row_assembly() adds the joiners between them.
ROW_ORIGIN = "[i*ROW_PITCH, 0, 0]"

# Studio look shared by every scene (a scene's "look" overrides keys).
LOOK = {
    "toneMapping": "neutral", "exposure": 0.9, "env": 0.3,
    "background": {"top": "#EFEBE4", "bottom": "#DAD4CA", "vignette": 0.12, "glow": [0.5, 0.46], "glowAmount": 0.07},
    "key": {"dir": [-0.55, 0.78, 0.5], "intensity": 3.0, "soft": 0.2, "color": "#FFF9F2"},
    "dome": {"intensity": 1.1, "minElevation": 14, "color": "#F4F7FF"},
    "fill": {"dir": [0.95, 0.1, 0.55], "intensity": 0.12, "color": "#FFF3E6"},
    "rim": {"dir": [0.25, 0.65, -1.0], "intensity": 0.9, "color": "#F3F6FF"},
    "ground": {"shadow": 0.75},
    "creaseAngle": 32, "glassBackdrop": 0.8,
}
MATERIAL = {   # color role -> render material
    "body": {"kind": "plastic", "rough": 0.5},
    "accent": {"kind": "plastic", "rough": 0.42},
    "ink": {"kind": "plastic", "rough": 0.45},
    "tpu": {"kind": "rubber", "rough": 0.85},
}
POWDER_COLOR = "#F2ECDF"


def deep_merge(a, b):
    out = dict(a)
    for k, v in (b or {}).items():
        out[k] = deep_merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out


def asset_for(path, sha):
    """Binary copy of an STL under tools/render/assets/cache/, keyed by content hash."""
    dst = ASSETS / "cache" / f"{sha[:20]}.stl"
    if not dst.exists():
        C.stl_to_binary(path, dst)
    return dst.relative_to(C.RENDER_DIR).as_posix()


def ink_parent(part, names):
    base = part.replace("_inlay", "")
    for cand in (base, base + "_plate"):
        if cand in names:
            return cand
    return None


def role_colors(text, registry):
    colors = C.color_table(text)
    roles = {r["name"]: r["color"] for r in registry}
    ink = {}
    for r in registry:
        if r["color"] != "ink":
            continue
        parent = ink_parent(r["name"], roles)
        prole = roles.get(parent, "accent")
        pc = colors.get(prole, "#2F3237")
        c = colors.get("ink", "#2F3237")
        if c.lower() == pc.lower():                  # no contrast: use the other main color
            c = colors.get("body" if prole != "body" else "accent", "#ECE8DF")
        ink[r["name"]] = c
    return colors, roles, ink


class Scenes:
    def __init__(self, args):
        self.args = args
        self.text = C.entry_text()
        self.registry = C.parts_registry(self.text)
        self.colors, self.roles, self.ink = role_colors(self.text, self.registry)
        self.caches = {}

    def cache(self, preset, name):
        key = (C.preset_label(preset), name)
        if key not in self.caches:
            self.caches[key] = C.PosedCache(preset, name=name, jobs=self.args.jobs, force=self.args.force, quiet=True)
        return self.caches[key]

    def head(self, h, at):
        """Resolved render parts of one head."""
        cache = self.cache(h.get("preset", "std"), h.get("name"))
        V = float(cache.params["V_MAX"])
        st = {"STATE_PULL": 0, "DIAL_ML": V / 2, "CHUCK_CLOSE": 1}
        st.update({k: float(v) for k, v in (h.get("state") or {}).items()})
        st["DIAL_ML"] = min(V, max(0.0, st["DIAL_ML"]))
        names = list(cache.head_parts)
        if h.get("only"):
            names = [n for n in names if n in h["only"]]
        names = [n for n in names if n not in (h.get("hide") or [])]
        res = cache.export_states([(n, st) for n in names])
        explode = h.get("explode") or {}
        k_ex = float(h.get("explode_scale", 1.0))
        out, missing = [], []
        for n in names:
            r = res.get((n, C.state_key(st)))
            if not r or r.get("status") != "ok":
                missing.append(n)
                continue
            role = self.roles.get(n, "body")
            off = explode.get(n, 0)
            off = [0, 0, off] if isinstance(off, (int, float)) else list(off)
            off = [k_ex * o for o in off]
            color = self.ink.get(n) or self.colors.get(role, "#dddddd")
            out.append({"file": asset_for(r["path"], r["sha"]), "color": color, **MATERIAL.get(role, {}),
                        "pos": [at[0] + off[0], at[1] + off[1], at[2] + off[2]], "tag": n})
        if h.get("jar", True):
            dz = k_ex * float(h.get("explode_jar", 0))
            j = cache.export_jar()
            if j["status"] == "ok":
                out.append({"file": asset_for(j["path"], j["sha"]), "kind": "glass", "tag": "jar",
                            "pos": [at[0], at[1], at[2] + dz]})
            fill = h.get("powder", 0.62)
            if fill:
                p = cache.export_powder(float(fill))
                if p["status"] == "ok":
                    out.append({"file": asset_for(p["path"], p["sha"]), "kind": "powder", "color": POWDER_COLOR,
                                "tag": "powder", "pos": [at[0], at[1], at[2] + dz]})
        return out, missing, cache, st

    def resolve(self, name, sc):
        look = deep_merge(LOOK, sc.get("look"))
        parts, missing = [], set()
        heads = sc.get("heads") or []
        # placement: explicit "at", "row:<i>" (ROW_PITCH apart), or side by side by size ("layout": "row")
        row = sc.get("row")
        row_cache = self.cache(row.get("preset", "std"), None) if row else None
        x_cursor = None
        for h in heads:
            at = h.get("at")
            if isinstance(at, str) and at.startswith("row:"):
                i = int(at.split(":")[1])
                expr = re.sub(r"\bi\b", f"({i})", sc.get("row_origin", ROW_ORIGIN))
                c = row_cache or self.cache(h.get("preset", "std"), h.get("name"))
                at = C.eval_scad([expr], c.base_defs, c.dir / "_scad")[expr]
            if at is None and sc.get("layout") == "row":
                c = self.cache(h.get("preset", "std"), h.get("name"))
                pr = C.eval_scad(["max(PUCK_R, BODY_OD/2)"], c.base_defs, c.dir / "_scad")["max(PUCK_R, BODY_OD/2)"]
                gap = sc.get("layout_gap", 40)
                if x_cursor is None:
                    at, x_cursor = [0, 0, 0], pr
                else:
                    at = [x_cursor + gap + pr, 0, 0]
                    x_cursor = at[0] + pr
            at = at or [0, 0, 0]
            p, miss, _, _ = self.head(h, at)
            parts += p
            missing |= set(miss)
        if row:                                   # joiners between the heads (row_assembly without heads)
            r = row_cache.export_row(int(row.get("n", len(heads) or 3)))
            if r["status"] == "ok":
                parts.append({"file": asset_for(r["path"], r["sha"]), "color": self.colors.get(self.roles.get("joiner", "body"), "#ECE8DF"),
                              **MATERIAL.get(self.roles.get("joiner", "body"), {}), "tag": "joiner", "pos": [0, 0, 0]})
            else:
                missing.add("joiner")
        scene = {**look, "width": sc.get("width", 1600), "height": sc.get("height", 1200),
                 "samples": sc.get("samples", 64), "parts": parts, "camera": sc.get("camera", {})}
        if self.args.draft:
            scene["width"], scene["height"] = scene["width"] // 2, scene["height"] // 2
            scene["samples"] = 16
        if self.args.samples:
            scene["samples"] = self.args.samples
        return scene, sorted(missing)


def find_node():
    node = shutil.which("node")
    if not node:
        raise SystemExit("node not found (Node 18+ and Playwright with Chromium are needed for renders)")
    return node


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog=__doc__.split("\n\n", 1)[1])
    ap.add_argument("--scenes", default="")
    ap.add_argument("--samples", type=int, default=0)
    ap.add_argument("--draft", action="store_true")
    ap.add_argument("--out", default="")
    ap.add_argument("--jobs", type=int, default=3)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args(argv)
    all_scenes = sorted(p.stem for p in SCENES.glob("*.json"))
    if args.list:
        for s in all_scenes:
            sc = json.loads((SCENES / f"{s}.json").read_text())
            print(f"{s:<12} {sc.get('title', '')}")
        return 0
    want = [s.strip() for s in args.scenes.split(",") if s.strip()] or all_scenes
    unknown = [s for s in want if s not in all_scenes]
    if unknown:
        raise SystemExit(f"unknown scene(s): {', '.join(unknown)}  (have: {', '.join(all_scenes)})")
    C.require("trimesh")
    node = find_node()
    out_dir = Path(args.out) if args.out else (DRAFT_OUT if args.draft else OUT)
    out_dir.mkdir(parents=True, exist_ok=True)
    (ASSETS / "scenes").mkdir(parents=True, exist_ok=True)
    S = Scenes(args)
    failures = 0
    for name in want:
        t0 = time.time()
        sc = json.loads((SCENES / f"{name}.json").read_text())
        try:
            scene, missing = S.resolve(name, sc)
        except Exception as e:  # noqa: BLE001
            C.say(f"[render] {name}: could not resolve scene: {e}")
            failures += 1
            continue
        if not scene["parts"]:
            C.say(f"[render] {name}: nothing to render yet (all parts are stubs), skipped")
            continue
        sp = ASSETS / "scenes" / f"{name}.json"
        sp.write_text(json.dumps(scene, indent=1))
        png = out_dir / f"{name}.png"
        cmd = [node, str(C.RENDER_DIR / "render.mjs"), str(sp), str(png), "--quiet"]
        p = subprocess.run(cmd, cwd=str(C.RENDER_DIR), capture_output=True, text=True)
        if p.returncode != 0 or not png.exists():
            C.say(f"[render] {name}: FAILED\n{(p.stdout + p.stderr)[-2000:]}")
            failures += 1
            continue
        C.say(f"[render] {name}: {os.path.relpath(png)}  ({len(scene['parts'])} meshes, {scene['samples']} samples, "
              f"{time.time() - t0:.0f}s)" + (f"  missing: {', '.join(missing)}" if missing else ""))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
