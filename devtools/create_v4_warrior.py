"""Original articulated SVG key-pose atlas; no image-generation or external assets.
128px cells, foot pivot (64,112), four cardinal views. Weapon sockets in JSON.
"""
from pathlib import Path
import math,json
R=Path(__file__).resolve().parents[1];out=R/'assets/visual_v4';out.mkdir(exist_ok=True)
STATES={'idle':8,'walk':8,'attack':5,'dodge':6,'hit':3,'defeat':6}
# Explicit authored sword/torso poses, rather than rotating a full actor image.
attack=[(-13,-9,-125,0),(-4,-5,-65,-3),(18,3,15,-6),(12,9,55,-2),(1,0,70,0)]
def line(a,b,width,color):return f'<path d="M{a[0]:.2f},{a[1]:.2f} L{b[0]:.2f},{b[1]:.2f}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round"/>'
def ellipse(x,y,rx,ry,color):return f'<ellipse cx="{x:.2f}" cy="{y:.2f}" rx="{rx}" ry="{ry}" fill="{color}"/>'
def pose(state,i,n,d):
 phase=i/n*math.tau;stride=math.sin(phase) if state=='walk' else 0
 breath=math.sin(phase)*.65 if state=='idle' else 0
 crouch=[3,9,15,12,5,0][i] if state=='dodge' else [1,4,7,13,23,30][i] if state=='defeat' else [3,1,0][i] if state=='hit' else 0
 tx,ty,angle,lean=attack[i] if state=='attack' else (0,0,65,0)
 if state=='dodge':lean=[-3,-9,-13,-9,-4,0][i];angle=100
 if state=='hit':lean=[-7,-4,0][i]
 if state=='defeat':lean=[0,-2,-5,-8,-12,-15][i];angle=[65,70,80,40,10,0][i]
 cx=64+lean;hip=86+crouch;top=53+crouch+breath;head=top-14
 side=d in (1,3);back=d==2;sign=-1 if d==3 else 1
 shapes=[]
 # Cape behind articulated limbs; hem changes with gait.
 shapes.append(f'<path d="M{cx-14},{top+1} Q{cx-26},{top+23} {cx-22-stride*3},{hip+10} Q{cx},{hip+20} {cx+22},{hip+10} L{cx+13},{top}Z" fill="#175159" stroke="#122e38" stroke-width="2"/>')
 for j,s in enumerate([-1,1]):
  footx=64+s*(7 if side else 10)+s*stride*10
  footy=111-max(0,s*stride)*5 if not state=='defeat' else 112
  knee=(cx+s*8+s*stride*4,100+crouch*.25-max(0,s*stride)*4)
  shapes.append(line((cx+s*7,hip),knee,10,'#263d49'));shapes.append(line(knee,(footx,footy-3),8,'#9caeab'))
  shapes.append(ellipse(footx+2,footy,7,3.5,'#172d37'))
 # Cloth folds and armor facets keep the compact silhouette readable.
 shapes.append(line((cx-13,top+11),(cx-17-stride*2,hip+8),2,'#377b7d'))
 shapes.append(line((cx+12,top+15),(cx+17,hip+7),2,'#103e49'))
 # Breastplate, segmented fauld and shoulder caps.
 shapes.append(f'<path d="M{cx-14},{top} Q{cx},{top-4} {cx+14},{top} L{cx+12},{hip-2} Q{cx},{hip+4} {cx-12},{hip-2}Z" fill="{"#476c71" if back else "#8fa6a2"}" stroke="#18323f" stroke-width="2"/>')
 shapes.append(f'<path d="M{cx-10},{top+5} L{cx},{top+1} L{cx+10},{top+5} L{cx+6},{top+22} L{cx},{top+26} L{cx-6},{top+22}Z" fill="{"#24545c" if back else "#d2d6be"}"/>')
 shapes.append(f'<path d="M{cx},{top+2} L{cx+10},{top+6} L{cx+6},{top+21} L{cx},{top+25}Z" fill="#718f91"/>')
 shapes.append(line((cx-9,top+7),(cx-7,top+19),2,'#e8e6cb'))
 for t in [-1,1]:
  shapes.append(f'<path d="M{cx+t*2},{hip-2} L{cx+t*12},{hip-2} L{cx+t*14},{hip+9} L{cx+t*4},{hip+7}Z" fill="#829e9a" stroke="#294b54" stroke-width="1.5"/>')
 shapes.append(line((cx-11,hip-3),(cx+11,hip-3),4,'#bd995d'))
 shapes.append(ellipse(cx,hip-3,3,3,'#e2cf91'))
 for s in [-1,1]:
  shoulder=(cx+s*17,top+4);hand=(cx+s*21+(tx if s==1 else 0),top+23+(ty if s==1 else 0)+(-stride*5*s if state=='walk' else 0))
  elbow=((shoulder[0]+hand[0])*.5+s*2,(shoulder[1]+hand[1])*.5)
  shapes.extend([line(shoulder,elbow,10,'#718d8c'),line(elbow,hand,8,'#aab8ac'),ellipse(*shoulder,9,6,'#c4b378'),ellipse(*hand,4,4,'#cfab7e')])
 shapes.append(ellipse(cx,head,11,14,'#d7b88a'))
 # Helmet and directional visor. No tiny generated face details.
 shapes.append(f'<path d="M{cx-12},{head+1} L{cx-11},{head-11} Q{cx},{head-23} {cx+11},{head-11} L{cx+12},{head+2} L{cx+6},{head-3} L{cx-6},{head-3}Z" fill="#8fa6a2" stroke="#173440" stroke-width="2"/>')
 shapes.append(line((cx,head-17),(cx,head-4),3,'#d9c583'))
 if not back:
  eye_x=cx+(4*sign if side else 0);shapes.append(line((eye_x-5,head+1),(eye_x+5,head+1),3,'#213d46'))
 if back:shapes.append(f'<path d="M{cx-8},{head+10} L{cx-10},{hip-4} L{cx+10},{hip-4} L{cx+8},{head+10}Z" fill="#20616a"/>')
 if side and d==3:shapes=['<g transform="translate(128 0) scale(-1 1)">']+shapes+['</g>']
 socket=[cx+21+tx,top+23+ty-stride*5 if state=='walk' else top+23+ty]
 shield=[cx-21,top+23+stride*5 if state=='walk' else top+23]
 if d==3:socket[0]=128-socket[0];shield[0]=128-shield[0];angle=180-angle
 if d==2:angle=-75
 return ''.join(shapes),{'sword':socket,'shield':shield,'angle':angle,'feet':[[64-10-stride*10,111],[64+10+stride*10,111]],'lean':lean}
meta={'cell':128,'pivot':[64,112],'directions':['south','east','north','west'],'states':{}}
for state,n in STATES.items():
 parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="512" viewBox="0 0 1024 512">'];rows=[]
 for d in range(4):
  frames=[]
  for i in range(n):
   art,sockets=pose(state,i,n,d);parts.append(f'<g transform="translate({i*128} {d*128})">{art}</g>');frames.append(sockets)
  rows.append(frames)
 parts.append('</svg>');(out/f'warrior-{state}.svg').write_text(''.join(parts),encoding='utf-8');meta['states'][state]={'frames':n,'sockets':rows}
(out/'warrior-poses.json').write_text(json.dumps(meta,separators=(',',':')),encoding='utf-8')
print('Original warrior atlas:',sum(STATES.values())*4,'poses; 6 atlases; RGBA upper bound 12 MiB')
