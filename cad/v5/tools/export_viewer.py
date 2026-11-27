#!/usr/bin/env python3
"""Export the interactive 3D viewer models (docs/v5/viewer/models/<key>.glb + .json).

usage:
  python3 cad/v5/tools/export_viewer.py               # std + pro (+ bar if bar parts exist)
  python3 cad/v5/tools/export_viewer.py --keys std    # one preset
  python3 cad/v5/tools/export_viewer.py --placeholder # stand-in shapes for unbuilt parts (UI testing only)

Every part is exported in its ASSEMBLED pose at the reference state (drawer at
rest, dial at 0 mL, chuck fully open). The viewer moves the moving groups
itself from the kinematics written to <key>.json, so the dial, drawer, chuck,
cutaway and exploded view all work live in the browser.
"""
import argparse, json, re, subprocess, sys, os, math
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import numpy as np
import trimesh

CAD = Path(__file__).resolve().parents[1]
REPO = CAD.parents[1]
OUT = REPO / "docs/v5/viewer/models"
TMP = CAD / "build/viewer"

# name: (role, group, label, material, explode_z)
PARTS = {
    "base":        ("body",   "static",  "Base: floor, drop hole, band posts", "PLA", -45),
    "deck":        ("body",   "static",  "Deck: strike-off edge and funnel", "PLA", 42),
    "stop_pin":    ("accent", "static",  "Stop pin (pull it to remove the drawer)", "PLA", -85),
    "wiper":       ("tpu",    "static",  "Wiper seal", "TPU 95A", 28),
    "slide":       ("body",   "slide",   "Drawer (dose chamber inside)", "PLA", 0),
    "plunger":     ("accent", "plunger", "Plunger + rack (sets the dose)", "PLA", 0),
    "lock_ring":   ("accent", "slide",   "Dial lock ring (lift the dial to turn it)", "PLA", 16),
    "dial_spring": ("tpu",    "slide",   "Dial spring (pulls the dial into its lock)", "TPU 95A", -30),
    "pinion_cap":  ("body",   "slide",   "Pinion cap", "PLA", -38),
    "pedestal":    ("body",   "static",  "Pedestal (holds the dose drawer)", "PLA", -95),
    "dose_drawer": ("body",   "drawer",  "Dose drawer: slide out and pour", "PLA", -95),
    "foot":        ("tpu",    "static",  "Feet", "TPU 95A", -110),
    "stir_post":   ("accent", "slide",   "Stir post (keeps powder flowing)", "PLA", 72),
    "name_plate":  ("accent", "slide",   "Name plate (swappable)", "PLA", 0),
    "name_inlay":  ("ink",    "slide",   "Name plate lettering", "PLA", 0),
    "dial":        ("accent", "dial",    "Dose dial (mL)", "PLA", 30),
    "dial_inlay":  ("ink",    "dial",    "Dial numerals", "PLA", 30),
    "pinion":      ("accent", "dial",    "Pinion (drives the rack)", "PLA", -22),
    "band":        ("tpu",    "band",    "Return bands", "TPU 95A", -10),
    "ring":        ("accent", "ring",    "Twist ring (clockwise = lock)", "PLA", 78),
    "guide_plate": ("body",   "static",  "Guide plate", "PLA", 108),
    "gasket":      ("tpu",    "static",  "Gasket (under the jar rim)", "TPU 95A", 122),
    "jaw0":        ("accent", "jaw",     "Jaw", "PLA", 135),
    "jaw1":        ("accent", "jaw",     "Jaw", "PLA", 135),
    "jaw2":        ("accent", "jaw",     "Jaw", "PLA", 135),
    "jaw_pad0":    ("tpu",    "jaw",     "Grip pad", "TPU 95A", 135),
    "jaw_pad1":    ("tpu",    "jaw",     "Grip pad", "TPU 95A", 135),
    "jaw_pad2":    ("tpu",    "jaw",     "Grip pad", "TPU 95A", 135),
}
PARAM_NAMES = ["V_MAX", "ML_PER_CLICK", "CLICKS", "CLICK_DEG", "L_MAX", "STROKE", "PUCK_D", "NECK_OD",
               "MOUTH_ID", "BODY_OD", "JAR_H", "NECK_H", "T_LEN", "U_DIAL", "R_PIN_MAX", "R_PIN_NOM",
               "SCROLL_LEAD", "JAW_ANGLES", "Z_RIM", "PED_H", "ROW_PITCH", "CH_W", "CH_H",
               "CUP_Y_REAR", "CUP_Y_FRONT", "CUP_W", "CUP_IN_H", "CUP_BOT_Z", "CUP_FLOOR_T", "HANDLE_L", "LOCK_LIFT"]


def preset_args(name):
    text = (CAD / "presets" / f"{name}.scad").read_text()
    args = []
    for m in re.finditer(r'^\s*([A-Z_]+)\s*=\s*([^;]+);', text, re.M):
        args += ["-D", f"{m.group(1)}={m.group(2).strip()}"]
    return args


def scad(out, part, preset, extra=()):
    cmd = ["openscad", "-o", str(out), "-D", f'PART="{part}"', "-D", "STATE_PULL=0",
           "-D", "DIAL_ML=0", "-D", "CHUCK_CLOSE=0", *preset_args(preset), *extra, "dosebar.scad"]
    r = subprocess.run(cmd, cwd=CAD, capture_output=True, text=True, timeout=900)
    return r.returncode == 0 and out.exists() and out.stat().st_size > 200, r.stderr


def read_params(preset):
    TMP.mkdir(parents=True, exist_ok=True)
    dump = CAD / "build" / "_params_dump.scad"
    dump.write_text("include <../params.scad>\n" + "".join(
        f'echo(str("P|{n}|", {n}));\n' for n in PARAM_NAMES) + "cube(0.01);\n")
    cmd = ["openscad", "-o", str(TMP / "_p.stl"), *preset_args(preset), str(dump)]
    r = subprocess.run(cmd, cwd=CAD, capture_output=True, text=True, timeout=300)
    p = {}
    for line in r.stderr.splitlines():
        m = re.search(r'"P\|(\w+)\|(.*)"', line)
        if m:
            v = m.group(2)
            try:
                p[m.group(1)] = json.loads(v)
            except json.JSONDecodeError:
                p[m.group(1)] = v
    missing = [n for n in PARAM_NAMES if n not in p]
    if missing:
        sys.exit(f"could not read params {missing}: {r.stderr[-800:]}")
    return p


def revolve(profile, segments=128):
    """Revolve a closed (r, z) polygon about the z axis into a watertight mesh."""
    pts = np.array(profile, dtype=float)
    n = len(pts)
    verts, faces = [], []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        c, s = math.cos(a), math.sin(a)
        for r, z in pts:
            verts.append((r * c, r * s, z))
    for i in range(segments):
        i2 = (i + 1) % segments
        for j in range(n):
            j2 = (j + 1) % n
            a, b = i * n + j, i * n + j2
            c2, d = i2 * n + j, i2 * n + j2
            faces += [(a, c2, b), (b, c2, d)]
    m = trimesh.Trimesh(np.array(verts), np.array(faces), process=True)
    m.fix_normals()
    return m


def jar_meshes(p, fill=0.55):
    """Upside-down glass jar (mouth on the gasket) and the powder inside it."""
    zr, H = p["Z_RIM"], p["JAR_H"] - 8.0           # lid removed
    rn, rb, rm, hn = p["NECK_OD"] / 2, p["BODY_OD"] / 2, p["MOUTH_ID"] / 2, p["NECK_H"]
    t = 3.2
    sh = hn + max(10, (rb - rn) * 1.1)               # shoulder top
    outer = [(rm, 0), (rn - 0.8, 0), (rn, 0.8), (rn, hn), (rb - 3, sh - 2), (rb, sh + 4), (rb, H - 10), (rb - 4, H - 2), (rb - 12, H), (0.01, H)]
    inner = [(0.01, H - t), (rb - 12 - t * 0.5, H - t), (rb - t - 3, H - 3 - t), (rb - t, H - 10), (rb - t, sh + 5), (rb - t - 3, sh - 1), (rm, hn + 2), (rm, 0.6)]
    jar = revolve(outer + inner)
    jar.apply_translation([0, 0, zr])
    top = hn + (H - hn) * fill
    pr = [(0.01, 0.8), (rm - 0.6, 0.8), (rm - 0.6, hn + 1.6), (rb - t - 3.4, sh - 0.6), (rb - t - 0.6, sh + 5), (rb - t - 0.6, top), (0.01, top + 4)]
    powder = revolve(pr)
    powder.apply_translation([0, 0, zr])
    return jar, powder


def placeholder(name, p):
    """Crude stand-ins so the viewer UI can be tested before parts exist."""
    R = p["PUCK_D"] / 2
    if name == "base":  m = trimesh.creation.cylinder(R, 27, sections=96); m.apply_translation([0, 0, 13.5])
    elif name == "deck": m = trimesh.creation.cylinder(R, p["Z_RIM"] - 45, sections=96); m.apply_translation([0, 0, 27 + (p["Z_RIM"] - 45) / 2])
    elif name == "ring": m = trimesh.creation.annulus(p["NECK_OD"] / 2 + 6, R, 10, sections=128); m.apply_translation([0, 0, p["Z_RIM"] - 12])
    elif name == "slide": m = trimesh.creation.box([p["CH_W"] + 8, 200, p["CH_H"]]); m.apply_translation([0, -R + 40, 3 + p["CH_H"] / 2])
    elif name == "dial": m = trimesh.creation.cylinder(16, 11, sections=64); m.apply_translation([0, -(p["U_DIAL"] - p["T_LEN"] / 2), 3 + p["CH_H"] + 6])
    elif name.startswith("jaw") and not name.startswith("jaw_pad"):
        i = int(name[-1]); a = math.radians(p["JAW_ANGLES"][i]); r = p["R_PIN_MAX"] - 6
        m = trimesh.creation.box([16, 14, 12]); m.apply_transform(trimesh.transformations.rotation_matrix(a, [0, 0, 1]))
        m.apply_translation([r * math.cos(a), r * math.sin(a), p["Z_RIM"] + 6])
    else:
        return None
    return m


def export_key(key, preset, use_placeholder, jobs):
    p = read_params(preset)
    tdir = TMP / key
    tdir.mkdir(parents=True, exist_ok=True)

    def one(name):
        out = tdir / f"{name}.stl"
        ok, err = scad(out, f"posed:{name}", preset)
        return name, (out if ok else None)

    with ThreadPoolExecutor(max_workers=jobs) as ex:
        results = dict(ex.map(one, PARTS.keys()))
    scene = trimesh.Scene()
    meta_parts, missing, kept = {}, [], {}
    for name, (role, group, label, material, explode) in PARTS.items():
        path = results.get(name)
        mesh = trimesh.load(path, force="mesh") if path else None
        if (mesh is None or len(mesh.faces) == 0) and use_placeholder:
            mesh = placeholder(name, p)
        if mesh is None or len(mesh.faces) == 0:
            missing.append(name)
            continue
        scene.add_geometry(mesh, node_name=name, geom_name=name)
        kept[name] = mesh
        info = {"role": role, "group": group, "label": label, "material": material, "explode": explode}
        if group == "jaw":
            info["angle"] = p["JAW_ANGLES"][int(name[-1])]
        meta_parts[name] = info
    jar, powder = jar_meshes(p)
    scene.add_geometry(jar, node_name="jar", geom_name="jar")
    scene.add_geometry(powder, node_name="powder", geom_name="powder")
    kept["jar"], kept["powder"] = jar, powder
    meta_parts["jar"] = {"role": "glass", "group": "jar", "label": "Your glass jar, upside down", "material": "glass", "explode": 235}
    meta_parts["powder"] = {"role": "powder", "group": "jar", "label": "Powder", "material": "", "explode": 235}
    ring_closed = -(p["R_PIN_MAX"] - p["R_PIN_NOM"]) / p["SCROLL_LEAD"] * 360
    meta = {
        "key": key, "preset": preset, "class_v": p["V_MAX"],
        "v_max": p["V_MAX"], "ml_per_click": p["ML_PER_CLICK"], "clicks": p["CLICKS"],
        "puck_d": p["PUCK_D"], "stroke": p["STROKE"], "neck_od": p["NECK_OD"],
        "row_pitch": p["ROW_PITCH"], "ped_h": p["PED_H"],
        "cup": {"y_rear": p["CUP_Y_REAR"], "y_front": p["CUP_Y_FRONT"], "w": p["CUP_W"], "in_h": p["CUP_IN_H"],
                "bot_z": p["CUP_BOT_Z"], "floor_t": p["CUP_FLOOR_T"], "travel": abs(p["CUP_Y_FRONT"] - p["CUP_Y_REAR"]) * 0.85},
        "kin": {"stroke": p["STROKE"], "l_max": p["L_MAX"], "v_max": p["V_MAX"], "ml_per_click": p["ML_PER_CLICK"],
                "click_deg": p["CLICK_DEG"], "dial_axis": [0, p["T_LEN"] / 2 - p["U_DIAL"]],
                "ring_phi_open": 0, "ring_phi_closed": ring_closed,
                "r_pin_open": p["R_PIN_MAX"], "r_pin_closed": p["R_PIN_NOM"], "jaw_angles": p["JAW_ANGLES"]},
        "drop_y": p["T_LEN"] / 2 - (p["STROKE"] - 0.5 + p["STROKE"] + p["L_MAX"] + 1.0) / 2,
        "rim_z": p["Z_RIM"], "jar_h": p["JAR_H"],
        "parts": meta_parts, "missing": missing,
    }
    OUT.mkdir(parents=True, exist_ok=True)
    glb = trimesh.exchange.gltf.export_glb(scene)
    (OUT / f"{key}.glb").write_bytes(glb)
    (OUT / f"{key}.json").write_text(json.dumps(meta, indent=1))
    print(f"{key}: {len(meta_parts)} meshes, {len(glb)/1e6:.1f} MB, missing: {missing}")
    return meta, kept


def export_row(meta, kept, n=3):
    """n std heads on pedestals, lined up ROW_PITCH apart."""
    scene = trimesh.Scene()
    parts = {}
    pitch = meta["row_pitch"]
    for i in range(n):
        dx = (i - (n - 1) / 2) * pitch
        for name, mesh in kept.items():
            m = mesh.copy()
            m.apply_translation([dx, 0, 0])
            node = f"h{i}_{name}"
            scene.add_geometry(m, node_name=node, geom_name=node)
            info = dict(meta["parts"][name])
            info["head"] = [dx, 0]
            parts[node] = info
    row = dict(meta)
    row.update({"key": "row", "parts": parts})
    glb = trimesh.exchange.gltf.export_glb(scene)
    (OUT / "row.glb").write_bytes(glb)
    (OUT / "row.json").write_text(json.dumps(row, indent=1))
    print(f"row: {len(parts)} meshes, {len(glb)/1e6:.1f} MB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--keys", default="std,pro", help="comma list of std, pro, row (row is built from std)")
    ap.add_argument("--placeholder", action="store_true")
    ap.add_argument("--jobs", type=int, default=3)
    a = ap.parse_args()
    keys = a.keys.split(",")
    for key in [k for k in keys if k != "row"]:
        meta, kept = export_key(key, {"std": "std", "pro": "pro"}.get(key, key), a.placeholder, a.jobs)
        if key == "std" and ("row" in keys or a.keys == "std,pro"):
            export_row(meta, kept)


if __name__ == "__main__":
    main()
