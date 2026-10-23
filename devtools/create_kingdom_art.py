from pathlib import Path
root=Path(__file__).resolve().parents[1];out=root/'assets/kingdom'
head='<svg xmlns="http://www.w3.org/2000/svg" width="192" height="192" viewBox="0 0 192 192">'
base='<ellipse cx="96" cy="148" rx="76" ry="27" fill="#153d3c" opacity=".32"/><path d="m20 131 76-37 76 37-76 39Z" fill="#819e77" stroke="#c5cb99" stroke-width="2"/>'
wall='<path d="m47 89 49-24 49 24v51l-49 23-49-23Z" fill="#b9b38c"/><path d="m96 112 49-23v51l-49 23Z" fill="#7b9686"/><path d="m87 162 0-32 17-8v32Z" fill="#426965"/><path d="m57 108 19 9v17l-19-9Z" fill="#e1d79b"/>'
roof='<path d="m30 91 64-54 67 54-65 32Z" fill="#719b85" stroke="#d0d4a2" stroke-width="3"/><path d="m96 123-2-86 67 54Z" fill="#3f7871"/><path d="m45 91 50-40 51 40" fill="none" stroke="#b8c799" stroke-width="3"/>'
art={}
art['house']=base+wall+roof+'<path d="m121 58 0-24 12-4v39" fill="#93a28c"/><path d="M126 27q-15-18 3-24" fill="none" stroke="#d7e0c0" opacity=".4" stroke-width="7"/>'
art['lumber']=base+'<path d="M39 148V92m112 52V88M44 96l52-29 56 25" stroke="#b4a27c" stroke-width="9"/>'+roof+'<path d="m41 132 46-22 58 25-46 22Z" fill="#af956c"/>'+''.join(f'<path d="m{x} {y} 39-18" stroke="#c3ac7e" stroke-width="12"/><ellipse cx="{x}" cy="{y}" rx="6" ry="7" fill="#e0ca97" stroke="#a28d68" stroke-width="2"/>' for x,y in [(54,137),(70,145),(86,152)])
art['farm']=base+'<path d="m30 132 55-27 70 29-59 29Z" fill="#7d7753"/>'+''.join(f'<path d="m{36+i*13} {135+i*5} 56-25" stroke="#b7ad73" stroke-width="4"/>' for i in range(4))+''.join(f'<path d="M{x} {y}v-20m0 11-8-8m8 4 7-11" fill="none" stroke="#d6cf7e" stroke-width="3"/>' for x,y in [(61,133),(81,123),(102,113),(89,146),(110,136),(130,127)])+'<path d="m29 110 14-7v27l-14 7Z" fill="#88b2ab"/>'
art['storage']=base+wall+roof+'<path d="m39 132 19-10 21 10v22l-19 10-21-10Z" fill="#c6a777" stroke="#7c8062" stroke-width="2"/><path d="m128 131 15-8 17 8v20l-17 8-15-8Z" fill="#baa77a" stroke="#7c8062" stroke-width="2"/>'
art['townhall']=base+wall+roof+'<path d="m81 67 0-40 16-11 17 11v40l-17 9Z" fill="#d1c39b"/><path d="m72 28 25-26 28 26-28 13Z" fill="#538b7c" stroke="#c6d19e" stroke-width="2"/><path d="M97 3V-8m0 0h26l-6 10-20 0" fill="#e2cb8c" stroke="#c2bc8e" stroke-width="3"/><path d="M140 86v43m-3-36 19-8v25l-19 8Z" fill="#d0b477"/>'
art['scaffold']=base+'<path d="M37 155V69m34 100V90m50 68V81m34 59V67M37 86l118-16M37 122l118-18M37 151l118-20m-84 38 50-88m-84 74 34-65" fill="none" stroke="#b5a27a" stroke-width="5"/><path d="m27 124 51-23 93 30-57 27Z" fill="#b6c7ac" opacity=".28"/>'
for key,body in art.items():(out/(key+'.svg')).write_text(head+body+'</svg>',encoding='utf-8')
parts=[f'<g transform="translate({i%3*192} {i//3*192})">{body}</g>' for i,body in enumerate([art[key] for key in ['lumber','farm','house','storage','townhall','scaffold']])]
(out/'buildings-atlas.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="576" height="384" viewBox="0 0 576 384">'+''.join(parts)+'</svg>',encoding='utf-8')
print('Six original reusable kingdom sprites, shared 576x384 atlas.')
