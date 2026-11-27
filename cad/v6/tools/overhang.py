#!/usr/bin/env python3
"""Printability audit: for each part in its print pose, list downward faces steeper than ~47 degrees
from vertical that do not sit on the bed. Small flat spans are bridges; 0.2 mm steps are chamfers.

  python3 tools/overhang.py --preset std"""
import argparse, os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import preset_defs, render, registry
if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('--preset', default='std'); ap.add_argument('--class', dest='cls'); a = ap.parse_args()
    defs = preset_defs(a.preset, a.cls)
    for part in [n for n, *_ in registry() if n != 'name_inlay'] :
        m, _ = render(part, defs + (['NAME="WHEY"'] if part == 'name_plate' else []))
        if m is None: print(part, 'RENDER FAILED'); continue
        n, c, ar = m.face_normals, m.triangles_center, m.area_faces
        down = (n[:, 2] < -0.73) & (c[:, 2] > 0.25)
        print(f'{part:12s} size {np.round(m.extents, 1)}  unsupported-facing area {ar[down].sum():7.1f} mm2')
        zs = np.round(c[down][:, 2], 1)
        for z in np.unique(zs):
            sel = down.copy(); sel[down] = (zs == z)
            if ar[sel].sum() < 3: continue
            v = m.triangles[sel].reshape(-1, 3); e = v.max(0) - v.min(0)
            kind = 'flat' if (n[sel][:, 2] < -0.99).mean() > 0.5 else 'sloped'
            print(f'      z={z:5.1f}  {ar[sel].sum():6.0f} mm2  region {e[0]:.0f} x {e[1]:.0f} mm  {kind}')
