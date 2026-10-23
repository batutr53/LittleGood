"""Original vector terrain: a cached texture replaces hundreds of frame draw commands."""
from pathlib import Path
import random
root=Path(__file__).resolve().parents[1]
rng=random.Random(19)
p=['<svg xmlns="http://www.w3.org/2000/svg" width="960" height="1440">','<rect width="960" height="1440" fill="#355c51"/>']
for _ in range(430):
 x,y=rng.randrange(18,942),rng.randrange(18,1422)
 p.append(f'<ellipse cx="{x}" cy="{y}" rx="{rng.randrange(3,20)}" ry="{rng.randrange(3,14)}" fill="#90b57b" opacity="{rng.uniform(.05,.17):.2f}"/>')
path='M240 1440 L240 1060 Q270 1000 480 920 L480 650 Q530 570 720 510 L720 150'
p += [f'<path d="{path}" fill="none" stroke="#668e73" stroke-width="122" stroke-linejoin="round"/>',f'<path d="{path}" fill="none" stroke="#9caf88" stroke-width="70" stroke-linejoin="round"/>','<rect x="20" y="500" width="280" height="300" rx="18" fill="#80b7ab"/>','<rect x="29" y="509" width="262" height="282" rx="16" fill="#3a8286"/>']
for i in range(13):
 y=526+i*20
 p.append(f'<path d="M45 {y} Q100 {y-8} 155 {y} T275 {y}" fill="none" stroke="#a3d4bd" opacity=".27" stroke-width="2"/>')
for x,y,w,h in [(590,980,140,120),(90,880,80,100),(360,300,140,220)]:
 p += [f'<path d="M{x+12} {y+5} L{x+w-20} {y} L{x+w} {y+28} L{x+w-4} {y+h-18} L{x+w-28} {y+h} L{x+10} {y+h-8} L{x} {y+28} Z" fill="#73988a" stroke="#afc0a1" stroke-width="3"/>',f'<path d="M{x+12} {y+5} L{x+28} {y+32} L{x+w-30} {y+42} L{x+w-20} {y} M{x+28} {y+32} L{x+10} {y+h-8}" fill="none" stroke="#9fb59a" stroke-width="4"/>']
for x,y,r in [(240,1260,68),(480,840,68),(720,230,160)]:
 p.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#668b73" stroke="#acb88e" stroke-width="3"/>')
for _ in range(140):
 x,y=rng.randrange(30,930),rng.randrange(30,1410)
 p.append(f'<path d="M{x-3} {y+3} l3 -9 l2 7 l4 -5" fill="none" stroke="#a6bb81" opacity=".28" stroke-width="2"/>')
p += ['<circle cx="240" cy="1260" r="36" fill="none" stroke="#e6d49b" stroke-width="4"/>','<rect x="458" y="775" width="44" height="72" rx="9" fill="#9cbbaa" stroke="#d8d8ae" stroke-width="4"/>','<circle cx="480" cy="795" r="18" fill="none" stroke="#ead797" stroke-width="4"/>','</svg>']
(root/'assets/adventure/wildwood-ground.svg').write_text('\n'.join(p),encoding='utf-8')
