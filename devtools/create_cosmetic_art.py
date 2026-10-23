"""Original reusable vector game assets; no external art or raster concept previews."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1];out=root/'assets/cosmetics';out.mkdir(exist_ok=True)
head='<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><defs><radialGradient id="glow"><stop stop-color="#deedc0" stop-opacity=".7"/><stop offset="1" stop-color="#99c2ac" stop-opacity="0"/></radialGradient><linearGradient id="gem" x2="1" y2="1"><stop stop-color="#d6eff3"/><stop offset=".5" stop-color="#a6abd9"/><stop offset="1" stop-color="#657aa6"/></linearGradient></defs>'
shadow='<ellipse cx="64" cy="104" rx="36" ry="12" fill="#112d36" opacity=".3"/>'
art={
'willow':'<path d="M59 106 61 48 68 48 73 105Z" fill="#a98e6a"/><path d="M64 23C19 23 10 54 24 82L36 57 39 93 53 51 61 84 71 49 85 90 87 55 104 78C115 45 91 23 64 23Z" fill="#6aab90" stroke="#b6d8a1" stroke-width="2"/><path d="M39 45Q63 32 88 45M33 57 28 72M47 55 42 79M83 54 89 75" fill="none" stroke="#d3e7ad" stroke-width="3"/><circle cx="61" cy="60" r="4" fill="#efdfaa"/>',
'flowers':''.join(f'<path d="M{x} 103Q{x-8} 83 {x} {y}" fill="none" stroke="#7faa7b" stroke-width="3"/><circle cx="{x}" cy="{y}" r="10" fill="#ead5b4"/><circle cx="{x}" cy="{y}" r="4" fill="#c8a26c"/>' for x,y in [(32,80),(57,67),(78,85),(98,64)]),
'prisms':'<path d="m39 105-9-41 13-23 14 31-7 35m5-4-6-65 18-25 16 38-7 55m3 0 5-37 17-18 11 35-14 24" fill="url(#gem)" stroke="#d3eff1" stroke-width="2"/><path d="m67 15-2 81M43 44l-2 53M97 55l-9 45" stroke="#f1e6f7" fill="none" opacity=".7"/>',
'stones':'<path d="M19 97q6-19 27-17l8 19q-14 13-35-2M51 102q-4-26 24-34 24 6 24 29-13 17-48 5" fill="#9cafa4" stroke="#d0d6bd" stroke-width="2"/><path d="M73 91q-15 0-10-10 9-9 16 3 2 8-6 11" fill="none" stroke="#e6d4a3" stroke-width="3"/>',
'falls':'<path d="m29 54 17-8 57 9-5 15H29Z" fill="#829f9f"/><path d="M40 58Q35 84 43 125H83Q90 85 85 58Z" fill="#6bb8c9" opacity=".8"/><path d="M49 61q-4 28 5 61m10-61q7 26 1 61m11-60q-1 25 0 61" fill="none" stroke="#c4f3ee" stroke-width="4"/><ellipse cx="64" cy="120" rx="30" ry="6" fill="#b2e4db" opacity=".6"/>',
'fireflies':'<circle cx="64" cy="64" r="49" fill="url(#glow)"/><path d="M48 103 53 67 75 67 80 103Z" fill="#687e63"/><path d="m49 66 15-17 16 17Z" fill="#829567"/><path d="M57 73h14v18H57Z" fill="#f1d893"/>'+''.join(f'<circle cx="{x}" cy="{y}" r="3" fill="#f4e7a1"/>' for x,y in [(24,67),(40,36),(83,38),(99,73)]),
'glowfern':'<circle cx="64" cy="73" r="44" fill="url(#glow)"/><path d="M64 107Q22 83 27 55q28 4 37 52M64 107Q101 77 101 50q-30 14-37 57M64 107Q47 62 62 34q20 33 2 73" fill="#7eb9a0" stroke="#d2e8b5" stroke-width="2"/>',
'ruins':'<path d="M25 106V57Q24 27 64 24q40 3 40 33v49H85V59Q82 45 64 45T44 60v46Z" fill="#b9bba2" stroke="#e1d8b4" stroke-width="2"/><path d="m29 80 13-3m-14-17 14 2m46 16 13 3M58 25l2 18m13-16-4 17" stroke="#8e9d8e" stroke-width="3"/><path d="M22 101q18-24 8-45m2 22q-19-6-10-15m10 15q20-10 9-18" fill="none" stroke="#77a183" stroke-width="5"/>',
'obelisk':'<path d="M42 104 47 41 64 21 81 41 86 104Z" fill="#a3b6b0" stroke="#d8e2bb" stroke-width="2"/><path d="m64 21 0 78 22 5-5-63Z" fill="#718f91"/><path d="m64 45 4 10 11 1-9 6 3 11-9-7-9 7 3-11-9-6 11-1Z" fill="#eddb9f"/><path d="M34 104h60v8H34Z" fill="#c6cbb0"/>',
'banner':'<path d="M47 111V28" stroke="#bdb998" stroke-width="5"/><path d="M50 30q22-9 45 1v39q-22-10-45 0Z" fill="#7cae95" stroke="#d6dcb0" stroke-width="2"/><path d="m71 37 4 9 10 1-8 6 3 10-9-6-9 6 3-10-8-6 10-1Z" fill="#f0d999"/>',
'lanterns':'<path d="M64 112V29m-28 9h56" stroke="#9ba58c" stroke-width="4"/>'+''.join(f'<path d="M{x-8} 43h16v23h-16Z" fill="#e9cc91" stroke="#93ac90" stroke-width="2"/><path d="M{x} 67v8" stroke="#c9b87d" stroke-width="2"/>' for x in [39,64,89]),
'statue':'<path d="M38 105h52v9H38Zm7-6 5-30h28l6 30Z" fill="#a4b9ae"/><circle cx="64" cy="51" r="21" fill="#bdcebc"/><path d="m47 39-3-21 15 14m10 0 15-14-4 22" fill="#bdcebc"/><circle cx="57" cy="50" r="3" fill="#486b68"/><circle cx="72" cy="50" r="3" fill="#486b68"/><path d="m61 58 6 0-3 5Z" fill="#799c8e"/>'}
for key,body in art.items():(out/(key+'.svg')).write_text(head+shadow+body+'</svg>',encoding='utf-8')
for theme,a,b in [('enchanted','#264e48','#b4d49b'),('crystal','#3d446c','#b2e0e1'),('celestial','#202d57','#ced1ee'),('ancient','#59433c','#e9c78e')]:
    body=f'<circle cx="64" cy="62" r="50" fill="{a}"/><ellipse cx="64" cy="65" rx="58" ry="17" transform="rotate(-22 64 65)" fill="none" stroke="{b}" stroke-width="3"/><circle cx="82" cy="41" r="12" fill="{b}"/><path d="m24 72 39-18 40 18-40 23Z" fill="{b}" opacity=".85"/><path d="m25 74 38 22 39-21-3 15-36 21-34-20Z" fill="{b}" opacity=".45"/>'
    (out/(theme+'.svg')).write_text(head+body+'</svg>',encoding='utf-8')
for key,color in [('aurora','#a9d5c1'),('comets','#e9d9b0'),('orbit','#d5c08d'),('mint','#b6dfcd'),('sunset','#e9bba7'),('starband','#ecd392'),('dreamer','#c9bfdf'),('royal_pack','#bfb9d9')]:
    (out/(key+'.svg')).write_text(head+f'<circle cx="64" cy="64" r="39" fill="none" stroke="{color}" stroke-width="3"/><path d="m64 25 10 25 27 3-22 17 7 27-22-16-22 16 7-27-22-17 27-3Z" fill="{color}"/>'+'</svg>',encoding='utf-8')
print('Created',len([p for p in out.glob('*.svg') if p.stem!='atlas']),'original reusable cosmetic SVGs.')

# One shared GPU texture for depth-sorted world props; individual files remain UI assets.
items=json.loads((out/'catalog.json').read_text(encoding='utf-8'))
parts=[]
for i,item in enumerate(items):
    key=item['id'];svg=(out/(key+'.svg')).read_text(encoding='utf-8')
    body=svg[svg.index('>')+1:svg.rindex('</svg>')]
    for gradient in ['glow','gem']:
        body=body.replace('id="'+gradient+'"','id="'+key+'_'+gradient+'"').replace('url(#'+gradient+')','url(#'+key+'_'+gradient+')')
    parts.append(f'<g transform="translate({i%6*128} {i//6*128})">{body}</g>')
(out/'atlas.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="768" height="512" viewBox="0 0 768 512">'+''.join(parts)+'</svg>',encoding='utf-8')
print('Shared cosmetic atlas: 768x512, 24 cells.')
