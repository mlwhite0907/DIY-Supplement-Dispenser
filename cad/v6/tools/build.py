#!/usr/bin/env python3
"""Export every part of one head as a print-ready STL (print orientation, on the bed).

  python3 tools/build.py --preset std            # your 4.5 in jars, class M (0-40 mL)
  python3 tools/build.py --preset std --class S  # same jar, small doses (0-20 mL)
  python3 tools/build.py --preset pro            # protein jar, class L (0-100 mL)
  python3 tools/build.py --preset std --names WHEY,CREATINE   # extra name bands

Output: stl/v6/<preset>-<class>/ with a manifest (size, grams, material, quantity)."""
import argparse, json, os, sys
import numpy as np
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import REPO, preset_defs, render, clean, registry

DENS = {'PLA': 1.24, 'TPU': 1.21}
EXTRA = [('mat', 'TPU', 1, 'tpu')] if False else []
def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--preset', default='std'); ap.add_argument('--class', dest='cls', default=None)
    ap.add_argument('--names', default='WHEY'); ap.add_argument('--out', default=None)
    ap.add_argument('--limit', type=float, default=None, help='also export a limit block that caps the dial at this many mL')
    a = ap.parse_args()
    defs = preset_defs(a.preset, a.cls)
    cls = a.cls or next(d.split('=')[1].strip('"') for d in defs if d.startswith('DOSE_CLASS='))
    out = a.out or os.path.join(REPO, 'stl', 'v6', f'{a.preset}-{cls}'); os.makedirs(out, exist_ok=True)
    parts = [p for p in registry() if p[0] not in ('name_plate', 'name_inlay')]
    jobs = [(n, m, q, [], n) for n, m, q, c in parts]
    jobs += [('latch_soft', 'TPU', 0, [], 'latch_soft'), ('latch_firm', 'TPU', 0, [], 'latch_firm'),
             ('coupon', 'PLA', 0, [], 'coupon'), ('coupon_tpu', 'TPU', 0, [], 'coupon_tpu')]      # qty 0 = optional / test pieces
    if a.limit: jobs += [('limit_block', 'PLA', 0, [f'LIMIT_ML={a.limit}'], f'limit_block_{a.limit:g}mL')]
    for nm in [x.strip() for x in a.names.split(',') if x.strip()]:
        jobs += [('name_plate', 'PLA', 1, [f'NAME="{nm}"'], f'name_plate_{nm}'), ('name_inlay', 'PLA', 1, [f'NAME="{nm}"'], f'name_inlay_{nm}')]
    def one(j):
        n, mat, q, extra, fn = j
        m, msgs = render(n, defs + extra)
        if m is None or msgs: return dict(part=fn, error=' | '.join(msgs) or 'render failed')     # any OpenSCAD warning fails the build
        m, ok = clean(m); m.export(os.path.join(out, fn + '.stl'))
        e = m.extents
        return dict(part=fn, material=mat, qty=q, watertight=ok, size_mm=[round(float(x), 1) for x in e],
                    solid_cm3=round(float(m.volume)/1000, 1), solid_g=round(float(m.volume)/1000*DENS[mat], 1), fits_256=bool(max(e[0], e[1]) <= 250))
    with ThreadPoolExecutor(4) as ex: rows = list(ex.map(one, jobs))
    json.dump(dict(preset=a.preset, dose_class=cls, defs=defs, parts=rows), open(os.path.join(out, 'manifest.json'), 'w'), indent=1)
    bad = 0
    print(f'{"part":22s} mat qty  size (mm)              solid g  ok')
    for r in rows:
        if 'error' in r: print(f'{r["part"]:22s} FAILED {r["error"][:120]}'); bad += 1; continue
        ok = r['watertight'] and r['fits_256']; bad += (not ok)
        print(f'{r["part"]:22s} {r["material"]} {r["qty"]:2d}   {str(r["size_mm"]):22s} {r["solid_g"]:7.1f}  {"yes" if ok else "CHECK"}')
    tot = {m: sum(r['solid_g']*r['qty'] for r in rows if r.get('material') == m) for m in DENS}
    print(f'solid totals: PLA {tot["PLA"]:.0f} g, TPU {tot["TPU"]:.0f} g (sliced weight is roughly 45-60 % of solid for the big PLA parts)')
    sys.exit(1 if bad else 0)
if __name__ == '__main__': main()
