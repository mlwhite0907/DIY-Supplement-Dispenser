#!/usr/bin/env python3
"""Interference check: render every part in its assembled pose and report overlaps, across the whole motion.

  python3 tools/fitcheck.py --preset std            # full sweep: home, pull positions, scoop out, chuck open
  python3 tools/fitcheck.py --preset pro --quick

Intended contacts (TPU preloads, parts resting on each other) are listed in ALLOW."""
import argparse, itertools, os, sys
import numpy as np, manifold3d as m3
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import preset_defs, render, registry

ALLOW = {("seal","slide"):60, ("seal","plunger"):30, ("pawl","pawl_spring"):6, ("tub","mat"):40, ("chassis","slide"):5,
         ("slide","dial"):1, ("scoop","tub"):5, ("slide","bumper"):15}
STATES = [("home, dial mid", []), ("home, dial 0", ["DIAL_ML=0"]), ("home, dial max", ["DIAL_ML=1000"]),
          ("pull 25 %", ["DIAL_ML=1000", "STATE_PULL=0.25"]), ("pull 50 %", ["DIAL_ML=1000", "STATE_PULL=0.5"]),
          ("pull 75 %", ["STATE_PULL=0.75"]), ("pull 90 %", ["STATE_PULL=0.9"]), ("full pull, dial max", ["DIAL_ML=1000", "STATE_PULL=1"]),
          ("full pull, dial 0", ["DIAL_ML=0", "STATE_PULL=1"]), ("scoop 30 % out", ["STATE_PULL=1", "DRAWER_OUT=0.3"]),
          ("scoop out", ["STATE_PULL=1", "DRAWER_OUT=1"]), ("chuck open", ["CHUCK_CLOSE=0"])]
def to_m(mesh):
    return m3.Manifold(m3.Mesh(vert_properties=np.asarray(mesh.vertices, dtype=np.float32), tri_verts=np.asarray(mesh.faces, dtype=np.uint32)))
def check(defs):
    names = [n for n, *_ in registry() if n not in ("dial_inlay", "name_inlay")]
    with ThreadPoolExecutor(4) as ex: res = list(ex.map(lambda n: (n, *render('posed:' + n, defs)), names))
    ms = {n: (m, to_m(m)) for n, m, _ in res if m is not None}
    bad = [(n, 'RENDER FAILED', 0) for n, m, _ in res if m is None]
    for a, b in itertools.combinations(ms, 2):
        ba, bb = ms[a][0].bounds, ms[b][0].bounds
        if (ba[0] > bb[1]).any() or (bb[0] > ba[1]).any(): continue
        v = (ms[a][1] ^ ms[b][1]).volume()
        if v > ALLOW.get((a, b), ALLOW.get((b, a), 0.3)): bad.append((a, b, v))
    return bad
if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--preset', default='std'); ap.add_argument('--class', dest='cls'); ap.add_argument('--quick', action='store_true')
    a = ap.parse_args(); base = preset_defs(a.preset, a.cls); total = 0
    for name, st in (STATES[::4] if a.quick else STATES):
        bad = check(base + st); total += len(bad)
        print(f'{name:22s} {"OK" if not bad else str(len(bad)) + " interference(s)"}')
        for x, y, v in bad: print(f'     {x} x {y}: {v:.1f} mm3')
    sys.exit(1 if total else 0)
