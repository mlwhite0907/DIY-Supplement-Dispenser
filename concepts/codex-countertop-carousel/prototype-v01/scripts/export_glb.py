"""Assemble the checked appearance meshes into a colored, portable 3D scene.

Matches appearance.scad defaults, without the small text labels. No working
kinematics are implied. Run after build.py. Uses no external asset downloads.
"""
from pathlib import Path
import math, sys
import numpy as np
import trimesh

ROOT=Path(sys.argv[1]) if len(sys.argv)>1 else Path(__file__).resolve().parents[1]
OUT=ROOT/'exports'
colors={'black':[19,21,24,255],'silver':[194,184,161,255],'window':[110,130,133,255]}
scene=trimesh.Scene()
def matrix(a,xyz):
    rot=trimesh.transformations.rotation_matrix(math.radians(a),[0,0,1])
    tr=trimesh.transformations.translation_matrix(xyz)
    return rot@tr
def put(part,name,color,a=0,xyz=(0,0,0)):
    mesh=trimesh.load_mesh(OUT/f'{part}.stl')
    mesh.visual.face_colors=colors[color]
    scene.add_geometry(mesh,node_name=name,geom_name=name,transform=matrix(a,xyz))

for j in range(4):put('base_sector',f'base-section-{j+1}','black',a=j*90)
base_center=trimesh.creation.cylinder(radius=42.5,height=14,sections=96)
base_center.apply_translation([0,0,7]);base_center.visual.face_colors=colors['black']
scene.add_geometry(base_center,node_name='base-center')
for k in range(2):
    z=14+k*158
    put('hub',f'tier-{k+1}-hub','black',xyz=(0,0,z))
    for j in range(6):
        a=j*60
        stem=f'tier-{k+1}-cartridge-{j+1}'
        put('tray_sector',stem+'-cradle-envelope','black',a,(0,0,z))
        for part,color,offset in [('body','silver',0),('liner','window',2),('lid','black',118),('foot','black',-6)]:
            put(part,stem+'-'+part,color,a,(0,0,z+13+offset))
        put('wheel',stem+'-thumbwheel','black',a,(0,-132,z+28))
    for name,r,h,center in [('support',12.5,158,z+79),('upper-collar',38.5,6,z+142)]:
        mesh=trimesh.creation.cylinder(radius=r,height=h,sections=96)
        mesh.apply_translation([0,0,center]);mesh.visual.face_colors=colors['black']
        scene.add_geometry(mesh,node_name=f'tier-{k+1}-{name}')
put('handle','top-handle-envelope','silver',xyz=(0,0,322))
# glTF uses Y up; SCAD/STL use Z up. Rotate the scene, not its part meshes.
scene.apply_transform(trimesh.transformations.rotation_matrix(-math.pi/2,[1,0,0]))
dst=OUT/'carousel-12.glb'
dst.write_bytes(scene.export(file_type='glb'))
readback=trimesh.load(dst)
assert len(readback.geometry)==len(scene.geometry)
assert np.allclose(readback.bounds,scene.bounds,atol=0.01)
print(f'GLB round-trip PASS: {len(readback.geometry)} named objects; bounds {readback.bounds.tolist()}')
