"""Original static vector terrain. Positions match wildwood_map.gd collision/landmarks."""
from pathlib import Path
import random, math
r=random.Random(48512)
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="960" height="1440" viewBox="0 0 960 1440">',
'''<defs><radialGradient id="land"><stop stop-color="#72864a"/><stop offset=".6" stop-color="#405b39"/><stop offset="1" stop-color="#233e32"/></radialGradient><radialGradient id="moss"><stop stop-color="#899b53" stop-opacity=".38"/><stop offset="1" stop-color="#344a30" stop-opacity="0"/></radialGradient><linearGradient id="water" x2="1" y2="1"><stop stop-color="#153e43"/><stop offset=".5" stop-color="#36756c"/><stop offset="1" stop-color="#77a995"/></linearGradient><linearGradient id="stone" x2="1" y2="1"><stop stop-color="#a5aa8b"/><stop offset=".3" stop-color="#737e6e"/><stop offset="1" stop-color="#344b44"/></linearGradient></defs>''',
'<rect width="960" height="1440" fill="url(#land)"/>']
for i in range(110):
 x,y=r.randrange(960),r.randrange(1440);rx=r.randrange(30,170)
 svg.append(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{rx*.6:.1f}" fill="url(#moss)"/>')
for i in range(2600):
 x,y=r.randrange(960),r.randrange(1440);c=r.choice(['#809658','#a1aa64','#1d3d2d','#506d3c']);n=r.randrange(2,7)
 svg.append(f'<path d="M{x} {y}l-2 -{n}m2 {n}l3 -{n+2}" fill="none" stroke="{c}" opacity=".35" stroke-width="1.2"/>')
path='M240 1440 L240 1060 Q270 1000 480 920 L480 650 Q530 570 720 510 L720 150'
for width,color in [(120,'#2d4230'),(101,'#4c5535'),(80,'#776748'),(65,'#91805a'),(28,'#a18e65')]:
 svg.append(f'<path d="{path}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linejoin="round" opacity=".85"/>')
for i in range(1250):
 x,y=r.randrange(960),r.randrange(1440);n=r.randrange(1,4)
 svg.append(f'<ellipse cx="{x}" cy="{y}" rx="{n}" ry="{n*.55}" fill="{r.choice(["#c0b38b","#283d2e","#9aa377"])}" opacity=".28"/>')
svg += ['<path d="M30 530Q130 490 275 536L280 758Q180 804 35 770Z" fill="#1d332d" stroke="#839579" stroke-width="18"/>','<path d="M30 530Q130 490 275 536L280 758Q180 804 35 770Z" fill="url(#water)" stroke="#b4b58a" stroke-width="3"/>']
for i in range(30):
 x,y=r.randrange(42,220),r.randrange(545,754)
 svg.append(f'<path d="M{x} {y}q12 -3 24 0" stroke="#b2d0bb" opacity=".25" fill="none"/>')
for x,y,w,h in [(360,300,140,220),(590,980,140,120),(90,880,80,100)]:
 svg.append(f'<ellipse cx="{x+w*.55}" cy="{y+h*.72}" rx="{w*.7}" ry="{h*.5}" fill="#122c27" opacity=".5"/>')
 svg.append(f'<path d="M{x} {y+h*.2}l{w*.28} -{h*.22} {w*.62} {h*.1} {w*.12} {h*.62} -{w*.2} {h*.29} -{w*.76} -{h*.04}Z" fill="url(#stone)" stroke="#43584c" stroke-width="3"/>')
 for j in range(7):
  yy=y+20+j*h/8
  svg.append(f'<path d="M{x+7} {yy:.1f}l{w-13} 4" stroke="#304a3e" opacity=".65" stroke-width="2"/>')
svg += ['<ellipse cx="480" cy="840" rx="66" ry="32" fill="#243b32" stroke="#b3aa77" stroke-width="3"/>','<path d="M456 837l4 -71 38 -10 11 70 -22 24Z" fill="url(#stone)" stroke="#b8b997" stroke-width="2"/>','<path d="M478 778v36m-10 -18h22" stroke="#cbe4ad" stroke-width="3"/>','<ellipse cx="240" cy="1260" rx="57" ry="30" fill="#485f46" stroke="#c5b57c" stroke-width="3"/>']
for angle in range(0,360,30):
 a=math.radians(angle);x=240+math.cos(a)*57;y=1260+math.sin(a)*30
 svg.append(f'<path d="M{x-5:.1f} {y-4:.1f}l10 1 -1 7 -10 -1Z" fill="#9ba588" stroke="#465b49"/>')
svg.append('</svg>')
Path(__file__).resolve().parents[1].joinpath('assets/adventure/wildwood-ground-premium.svg').write_text('\n'.join(svg),encoding='utf8')
