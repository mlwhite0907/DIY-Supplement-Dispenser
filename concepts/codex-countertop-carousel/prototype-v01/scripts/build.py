"""Export the appearance model and validate actual exported meshes. No hardware actions."""
from pathlib import Path
import json, subprocess, hashlib
import trimesh

ROOT=Path(__file__).resolve().parents[1]
CAD=ROOT/'cad'/'appearance.scad'
OUT=ROOT/'exports'
IMG=ROOT/'images'
REPORT=ROOT/'validation'
for p in (OUT,IMG,REPORT): p.mkdir(exist_ok=True)
parts=['body','liner','lid','wheel','foot','tray_sector','hub','base_sector','handle']
records=[]
for part in parts:
    dst=OUT/f'{part}.stl'
    run=subprocess.run(['openscad','-o',str(dst),'-D',f'part="{part}"',str(CAD)],capture_output=True,text=True,timeout=180)
    (REPORT/f'{part}.txt').write_text(run.stdout+run.stderr)
    if run.returncode or 'ERROR:' in run.stderr: raise RuntimeError(run.stderr)
    mesh=trimesh.load_mesh(dst)
    rec={'part':part,'watertight':bool(mesh.is_watertight),'winding_consistent':bool(mesh.is_winding_consistent),'components':len(mesh.split()),'bounds_mm':mesh.bounds.tolist(),'extents_mm':mesh.extents.tolist(),'volume_mm3':float(mesh.volume),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest()}
    records.append(rec)
    if not mesh.is_watertight or not mesh.is_winding_consistent or rec['components']!=1 or mesh.volume<=0: raise RuntimeError(f'Invalid mesh {rec}')
    if max(mesh.extents)>256: raise RuntimeError(f'Part exceeds 256 mm envelope: {rec}')

scenes=[('assembled','assembly',[]),('single-tier','single',[]),('separated-tiers','separated',[]),('cartridge','cartridge',[]),('removed-cartridge','assembly',['-D','removed=true']),('exploded-cartridge','cartridge',['-D','exploded=true'])]
for name,scene,extra in scenes:
    cmd=['xvfb-run','-a','openscad','-o',str(IMG/f'{name}.png'),'--imgsize=1600,1400','--projection=o','--viewall','--autocenter','--camera=0,0,0,72,0,18,1000','--colorscheme=Tomorrow','-D',f'part="{scene}"',*extra,str(CAD)]
    run=subprocess.run(cmd,capture_output=True,text=True,timeout=180)
    (REPORT/f'render-{name}.txt').write_text(run.stdout+run.stderr)
    if run.returncode or 'ERROR:' in run.stderr: raise RuntimeError(run.stderr)
summary={'model':'appearance-v01','stations_per_tier':6,'tiers':2,'total_cartridges':12,'checks':'Exported individual meshes only; not assembly collision, fit, force, flow, stability, food-contact or physical tests.','parts':records,'renders':[x[0] for x in scenes],'source_sha256':hashlib.sha256(CAD.read_bytes()).hexdigest()}
(REPORT/'mesh-report.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({'result':'PASS','parts':len(records),'renders':len(scenes),'source_sha256':summary['source_sha256']}))
