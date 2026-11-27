#!/usr/bin/env python3
"""Export the interactive viewer's models: docs/v6/viewer/models/<key>.gltf.json + <key>.json

  python3 tools/export_viewer.py            # std, pro and a row of three

Parts are exported in a reference pose (slide home, dial 0, chuck open); the JSON tells the
viewer how each group moves."""
import json, os, re, subprocess, sys
import numpy as np, trimesh
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import SRC, REPO, FAST, preset_defs, render, registry

OUT = os.path.join(REPO, 'docs', 'v6', 'viewer', 'models')
REF = ['STATE_PULL=0', 'DIAL_ML=0', 'CHUCK_CLOSE=0', 'DRAWER_OUT=0']
META = ['STROKE', 'L_MAX', 'V_MAX', 'ML_PER_CLICK', 'CLICKS', 'CLICK_DEG', 'hy(U_DIAL)', 'R_PIN_MAX', 'R_PIN_NOM', 'SCROLL_LEAD', 'PUCK_D', 'NECK_OD',
        'PED_H', 'MAT_T', 'Z_RIM', 'JAR_H', 'ROW_PITCH', 'hy(WAND_U)', 'WAND_Z', 'WAND_ARM', 'PEG_U_HOME', 'NOTCH_U0', 'PEG_HW', 'WAND_U',
        'SCOOP_HW - SCOOP_WALL', 'BODY_Y_FRONT', 'SCOOP_Y_TAPER', 'SCOOP_Z0', 'SCOOP_WALL', 'SCOOP_Y_REAR - BODY_Y_FRONT + 20', 'BODY_W', 'BODY_LEN']
INFO = {  # name: (group, label, explode)
 'mat': ('static', 'Mat tile (TPU): grips the counter, locks to its neighbours', 0), 'tub': ('static', 'Tub: houses the scoop', 0),
 'scoop': ('scoop', 'Scoop drawer: pull it, pour from it', 0), 'latch': ('scoop', 'Latch flaps (TPU): couple scoop and slide, let go at a tug', 0),
 'chassis': ('static', 'Chassis: floor, rails, stop piers', 40), 'stop_boot': ('static', 'Stop boots (TPU)', 40), 'bumper': ('static', 'Bumper and home catch (TPU)', 40),
 'slide': ('slide', 'Dose slide: chamber, dial, name band', 85), 'name_plate': ('slide', 'Name band', 85), 'name_inlay': ('slide', 'Name', 85),
 'pawl': ('slide', 'Click pawl', 85), 'pawl_spring': ('slide', 'Pawl spring (TPU)', 85), 'plunger': ('plunger', 'Plunger + rack: sets the chamber length', 85),
 'dial': ('dial', 'Dose dial (mL): hidden until you pull', 115), 'dial_inlay': ('dial', 'Dial numerals', 115),
 'seal': ('static', 'U-seal (TPU): wipes the slide top', 135), 'funnel': ('static', 'Funnel insert: throat, strike-off edge, hub', 150),
 'wand': ('wand', 'Agitator gate: stops sticky powder bridging', 150), 'wand_arm': ('wand', 'Gate arm', 150), 'wand_finger': ('wand', 'Drive finger (TPU): flexes away if the gate jams', 150),
 'shell': ('static', 'Shell', 215), 'ring': ('ring', 'Twist ring: three jaws close together', 250), 'guide_plate': ('static', 'Guide plate', 275),
 'jaw': ('jaw', 'Jaw', 295), 'jaw_boot': ('jaw', 'Jaw boot (TPU)', 295), 'gasket': ('static', 'Gasket (TPU): the jar rim sits on it', 305), 'jar': ('jar', 'Your glass jar, upside down', 345)}

def meta_values(defs):
    tmp = os.path.join(SRC, '_meta.scad')
    open(tmp, 'w').write('include <params.scad>\necho(META=[' + ', '.join(META) + ']);\ncube(1);\n')
    try:
        dargs = sum((['-D', d] for d in defs), [])
        if os.path.isdir(os.path.join(FAST, 'node_modules')):
            r = subprocess.run(['node', os.path.join(FAST, 'oscad.mjs'), SRC, '_meta.scad', '/tmp/_meta.stl', *dargs], capture_output=True, text=True, env=dict(os.environ, OSCAD_QUIET='1'))
        else:
            r = subprocess.run(['openscad', '-o', '/tmp/_meta.stl', *dargs, tmp], capture_output=True, text=True)
        line = next(l for l in (r.stdout + r.stderr).splitlines() if 'META' in l)
        return dict(zip(META, [float(x) for x in re.search(r'\[(.*)\]', line).group(1).split(',')]))
    finally:
        os.remove(tmp)

def head(preset, cls=None, name='WHEY'):
    defs = preset_defs(preset, cls)
    v = meta_values(defs); zoff = v['PED_H'] + v['MAT_T']
    roles = {n: c for n, m, q, c in registry()}; mats = {n: m for n, m, q, c in registry()}
    names = [n for n in INFO]
    with ThreadPoolExecutor(4) as ex: res = dict(zip(names, ex.map(lambda n: render('posed:' + n, defs + REF + [f'NAME="{name}"'])[0], names)))
    meshes, parts = {}, {}
    for n, m in res.items():
        if m is None: print('missing', n); continue
        m.merge_vertices(); m.apply_translation([0, 0, zoff])
        g, label, ex_ = INFO[n]
        base = dict(role='glass' if n == 'jar' else roles.get(n, 'body'), group=g, label=label, material=mats.get(n, ''), explode=ex_)
        if g == 'jaw':
            for i, c in enumerate(sorted(m.split(only_watertight=False), key=lambda c: np.degrees(np.arctan2(*c.centroid[[1, 0]])) % 360)):
                ang = np.degrees(np.arctan2(c.centroid[1], c.centroid[0])) % 360
                meshes[f'{n}{i}'] = c; parts[f'{n}{i}'] = dict(base, angle=round(float(ang), 1))
        else:
            meshes[n] = m; parts[n] = base
    kin = dict(stroke=v['STROKE'], l_max=v['L_MAX'], v_max=v['V_MAX'], ml_per_click=v['ML_PER_CLICK'], click_deg=v['CLICK_DEG'], dial_axis=[0, v['hy(U_DIAL)']],
               ring_phi_open=0, ring_phi_closed=(v['R_PIN_MAX'] - v['R_PIN_NOM'])/v['SCROLL_LEAD']*360, r_pin_open=v['R_PIN_MAX'], r_pin_closed=v['R_PIN_NOM'],
               wand=dict(y=v['hy(WAND_U)'], z=v['WAND_Z'] + zoff, arm=v['WAND_ARM'], u_home=v['PEG_U_HOME'], notch_u0=v['NOTCH_U0'], hw=v['PEG_HW'], u=v['WAND_U']))
    meta = dict(key=preset, preset=preset, v_max=v['V_MAX'], ml_per_click=v['ML_PER_CLICK'], clicks=int(v['CLICKS']), puck_d=v['PUCK_D'], stroke=v['STROKE'],
                neck_od=v['NECK_OD'], ped_h=zoff, rim_z=v['Z_RIM'], jar_h=v['JAR_H'], row_pitch=v['ROW_PITCH'], body=[v['BODY_W'], v['BODY_LEN']], kin=kin, drop_y=2,
                cup=dict(w=2*v['SCOOP_HW - SCOOP_WALL'], y_front=v['BODY_Y_FRONT'] + 5, y_rear=v['SCOOP_Y_TAPER'], in_h=30, bot_z=v['SCOOP_Z0'] + zoff,
                         floor_t=v['SCOOP_WALL'], travel=v['SCOOP_Y_REAR - BODY_Y_FRONT + 20']), parts=parts)
    return meshes, meta

def write(key, meshes, meta):
    os.makedirs(OUT, exist_ok=True)
    sc = trimesh.Scene()
    for n, m in meshes.items(): sc.add_geometry(m, node_name=n, geom_name=n)
    # glTF as one JSON file with the buffers embedded (plain .json is served everywhere, binary .glb is not)
    import base64
    files = sc.export(file_type='gltf')
    g = json.loads(files['model.gltf'])
    for b in g.get('buffers', []):
        b['uri'] = 'data:application/octet-stream;base64,' + base64.b64encode(files[b['uri']]).decode()
    path = os.path.join(OUT, key + '.gltf.json'); json.dump(g, open(path, 'w'), separators=(',', ':'))
    meta['key'] = key
    json.dump(meta, open(os.path.join(OUT, key + '.json'), 'w'), indent=1)
    print(key, f'{os.path.getsize(path)/1e6:.1f} MB', len(meshes), 'meshes')

if __name__ == '__main__':
    ms, meta = head('std'); write('std', ms, meta)
    mp, metap = head('pro', name='PROTEIN'); write('pro', mp, metap)
    pitch = meta['row_pitch']; rm, rp = {}, {}
    for i, dx in enumerate([-pitch, 0, pitch]):
        for n, m in ms.items():
            c = m.copy(); c.apply_translation([dx, 0, 0]); rm[f'{n}_{i}'] = c; rp[f'{n}_{i}'] = dict(meta['parts'][n], head=[dx, 0])
    write('row', rm, dict(meta, parts=rp))
