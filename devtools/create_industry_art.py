"""Original isometric workshop art and readable tool icons, extending the established SVG palette."""
from pathlib import Path
root=Path(__file__).resolve().parents[1];out=root/'assets/kingdom'
header='<svg xmlns="http://www.w3.org/2000/svg" width="192" height="192" viewBox="0 0 192 192">'
base='<ellipse cx="96" cy="153" rx="77" ry="25" fill="#133b39" opacity=".36"/><path d="m18 137 78-36 78 36-78 38Z" fill="#8c9b7b" stroke="#d2ca9b" stroke-width="2"/>'
rock='<path d="m35 131 8-39 34-24 20 10 31-24 29 40 7 38-65 31Z" fill="#98a49a" stroke="#d5d4b6" stroke-width="2"/><path d="m97 78 3 85 64-31-7-38-29-40Z" fill="#618a81"/><path d="m43 92 34-24 20 10-18 26Z" fill="#d1ceb1"/>'
wood='<path d="M34 145V65m124 79V65M32 67l63-30 65 29" fill="none" stroke="#c6ac7c" stroke-width="8"/>'
art={
 'quarry':base+rock+'<path d="m37 138 26-12 23 12v23l-24 11-25-11Z" fill="#c6cbb6"/><path d="M122 48v82m0-73 39 20m-3-1v57" stroke="#bda579" stroke-width="6"/><path d="m149 128 18-8v22l-18 9Z" fill="#c5b887"/><path d="m78 83 31 15-12 8-28-16Z" fill="#e6ddae"/>' ,
 'mine':base+rock+'<path d="M66 151v-44q30-47 60-8v27Z" fill="#214b49" stroke="#b7ab87" stroke-width="8"/><path d="m76 145 11-37 25-12 4 34" fill="#122f31"/><path d="m76 149 24-13 24 11m-12-7 32 12" stroke="#a5b8ab" stroke-width="4"/><path d="m133 106 10-6v14l-10 6Z" fill="#f8ce7e"/><path d="m42 103 11-8 7 14-13 8Z" fill="#d6ac6e"/>',
 'furnace':base+'<path d="m53 134 0-58 42-20 40 20v58l-40 22Z" fill="#bdba9b" stroke="#dfcfa6" stroke-width="3"/><path d="m95 96 40-20v58l-40 22Z" fill="#66897b"/><path d="M77 74V24l25-11 26 12v49" fill="#a7ac94" stroke="#cfcbab" stroke-width="4"/><path d="m87 137 0-30 19-10v31Z" fill="#e3a362"/><path d="m91 133 7-20 6 13Z" fill="#ffe0a0"/><path d="m41 142 18-8 19 8-18 10Z" fill="#d9bf88"/><path d="M104 14q-20-22 0-29" fill="none" stroke="#bccbb0" stroke-width="9" opacity=".4"/>',
 'forge':base+wood+'<path d="m22 68 72-49 77 47-76 36Z" fill="#537f78" stroke="#d7c59d" stroke-width="3"/><path d="m95 102-1-83 77 47Z" fill="#376763"/><path d="m49 137 34-16 48 19-32 18Z" fill="#9daea3"/><path d="m72 129 16-24 48 10-7 16-34 5v16l-18-8v-10Z" fill="#4f7773" stroke="#c1c9ab" stroke-width="3"/><path d="M139 104v32m-11-17 25-11" stroke="#d1af78" stroke-width="6"/><path d="m39 115 10-5v22l-10 4Z" fill="#ffc879"/>'}
for key,body in art.items():(out/(key+'.svg')).write_text(header+body+'</svg>',encoding='utf-8')
(out/'industry-atlas.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="768" height="192" viewBox="0 0 768 192">'+''.join(f'<g transform="translate({i*192} 0)">{body}</g>' for i,body in enumerate(art.values()))+'</svg>',encoding='utf-8')
tools={
 'forest_axe':'<path d="m56 155 62-98" stroke="#bd9b6b" stroke-width="16"/><path d="m93 38 54 20-26 43-38-31Z" fill="#c5d7c0" stroke="#76978a" stroke-width="4"/>',
 'iron_pick':'<path d="m67 160 36-115" stroke="#bd9b6b" stroke-width="15"/><path d="M42 69q55-70 116 3l-24-10-34-10-33 8Z" fill="#c5d7c0" stroke="#76978a" stroke-width="4"/>',
 'field_sickle':'<path d="m69 155 34-65" stroke="#bd9b6b" stroke-width="16"/><path d="M99 92q69-62 3-63-43 1-45 41 24-35 51-19 22 14-12 32Z" fill="#d7d8b8" stroke="#76978a" stroke-width="3"/>',
 'mason_hammer':'<path d="m74 154 32-94" stroke="#bd9b6b" stroke-width="17"/><path d="m73 42 31-13 42 18-9 39-34 10-40-22Z" fill="#a7bca9" stroke="#678d81" stroke-width="4"/>'}
for key,body in tools.items():(out/(key+'.svg')).write_text(header+'<ellipse cx="96" cy="151" rx="53" ry="15" fill="#123c3a" opacity=".3"/>'+body+'</svg>',encoding='utf-8')
print('Four isometric production buildings, shared atlas and four original tool icons.')
