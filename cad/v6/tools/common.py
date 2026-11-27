"""Shared helpers for the Dose Bar build tools.

Rendering uses the fast engine when it is installed (cd tools/fast && npm install),
otherwise the system `openscad` (works, but slow on the bigger parts)."""
import json, os, re, shutil, subprocess, sys
import numpy as np, trimesh

TOOLS = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.dirname(TOOLS)                       # cad/v5
REPO = os.path.dirname(os.path.dirname(SRC))
FAST = os.path.join(TOOLS, 'fast')
OUT = os.path.join(SRC, 'build')

def preset_defs(preset, dose_class=None):
    """-D definitions for a jar preset (presets/<name>.scad) and an optional dose class S/M/L."""
    txt = open(os.path.join(SRC, 'presets', preset + '.scad')).read()
    defs = [f'{k}={v.strip()}' for k, v in re.findall(r'^(\w+)\s*=\s*([^;]+);', txt, re.M)]
    if dose_class: defs = [d for d in defs if not d.startswith('DOSE_CLASS=')] + [f'DOSE_CLASS="{dose_class}"']
    return defs

def have_fast():
    return shutil.which('node') and os.path.isdir(os.path.join(FAST, 'node_modules', 'openscad-wasm-prebuilt'))

def render(part, defs=(), out=None):
    """Render dosebar.scad with PART=part. Returns (trimesh or None, messages)."""
    out = out or os.path.join(OUT, 'tmp', re.sub(r'\W+', '_', part + '_' + '_'.join(defs)) [:120] + '.stl')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    dargs = []
    for d in [f'PART="{part}"', *defs]: dargs += ['-D', d]
    if have_fast():
        cmd = ['node', os.path.join(FAST, 'oscad.mjs'), SRC, 'dosebar.scad', out, *dargs]
        env = dict(os.environ, OSCAD_QUIET='1')
    else:
        cmd = ['openscad', '-o', out, *dargs, os.path.join(SRC, 'dosebar.scad')]; env = None
    r = subprocess.run(cmd, capture_output=True, text=True, env=env)
    msgs = [l for l in (r.stdout + r.stderr).splitlines() if re.search(r'ERROR|WARNING|Assert', l) and 'localization' not in l]
    if r.returncode != 0 or not os.path.exists(out): return None, msgs or [r.stderr[-400:]]
    return trimesh.load(out), msgs

def clean(mesh):
    """Merge vertices, drop degenerate faces; returns (mesh, ok) where ok means watertight with consistent winding."""
    mesh.merge_vertices(); mesh.update_faces(mesh.nondegenerate_faces()); mesh.remove_unreferenced_vertices()
    return mesh, bool(mesh.is_watertight and mesh.is_winding_consistent)

def registry():
    """The PARTS table from dosebar.scad: [(name, material, qty, color role)]."""
    txt = open(os.path.join(SRC, 'dosebar.scad')).read()
    return [(n, m, int(q), c) for n, m, q, c in re.findall(r'\["(\w+)",\s*"(\w+)",\s*(\d+),\s*"(\w+)"\]', txt)]
