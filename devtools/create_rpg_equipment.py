"""Generate original LittleGod starter definitions and native vector equipment icons."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
rows=[]
themes={'warrior':('#9a3538','Emberguard','Köz Muhafızı'),'priest':('#d4bd79','Dawnkeeper','Şafak Bekçisi'),'mage':('#688db5','Starweave','Yıldız Örgüsü'),'rogue':('#587963','Nightleaf','Gece Yaprağı')}
shapes={
'weapon':'<path d="M35 105 96 29 103 22 106 33 49 113Z" fill="url(#metal)"/><path d="m39 98 19 16-5 8-22-16Z" fill="#c5a46b"/><path d="m31 110-11 15 7 7 13-17" fill="#6b422b"/>',
'armor':'<path d="m38 25 21-8h18l20 8 23 25-19 16-10-12 5 66H37l5-66-11 12-19-16Z" fill="url(#metal)"/><path d="M58 19v26h20V19M44 78l45 22M88 76 43 98" stroke="#d1b77c" stroke-width="5" fill="none"/>',
'head':'<path d="M29 97V54Q30 18 67 18t36 36v43L81 111l-8-37H59l-8 37Z" fill="url(#metal)"/><path d="m40 62 18 6m20 0 14-6M65 26v33" stroke="#e4ce96" stroke-width="6"/>',
'legs':'<path d="M32 26h69l-4 40 9 53H77L65 75l-10 44H27l8-54Z" fill="url(#metal)"/><path d="M34 37h64M35 65l20 8m21 0 21-8" stroke="#dbc18c" stroke-width="5"/>',
'hands':'<path d="M34 25h54l8 43 12 25-14 24-49-3-14-30Z" fill="url(#metal)"/><path d="m40 59 45 1M43 76l40 2M46 94l37 2" stroke="#d1b77c" stroke-width="5"/>',
'feet':'<path d="M45 20h46l-2 58 26 22-1 19H27l-1-22 19-14Z" fill="url(#metal)"/><path d="M46 37h42M46 55h42M47 75h41" stroke="#c5a46b" stroke-width="5"/>',
'neck':'<path d="M24 28q3 62 43 66 37-8 43-66" stroke="url(#metal)" stroke-width="7" fill="none"/><path d="m65 79 18 20-18 27-17-27Z" fill="#76c4cd" stroke="#d2b574" stroke-width="5"/>',
'belt':'<path d="M16 47h101v43H16Z" fill="#664932" stroke="#d2b574" stroke-width="4"/><rect x="48" y="43" width="35" height="51" rx="5" fill="url(#metal)"/><path d="M55 68h25" stroke="#1b1b1b" stroke-width="7"/>',
'ring_left':'<ellipse cx="66" cy="80" rx="31" ry="37" fill="none" stroke="url(#metal)" stroke-width="12"/><path d="m65 18 21 24-21 24-21-24Z" fill="#76c4cd" stroke="#d2b574" stroke-width="5"/>',
'ear_left':'<path d="M47 31a20 20 0 1 1 39 0" fill="none" stroke="url(#metal)" stroke-width="8"/><path d="m66 39 19 33-19 42-19-42Z" fill="#76c4cd" stroke="#d2b574" stroke-width="5"/>'}
for cls,(color,en,tr) in themes.items():
    for slot,english,turkish in [('armor','Cuirass','Göğüslük'),('head','Helm','Başlık'),('legs','Legguards','Bacaklık'),('hands','Gauntlets','Eldiven'),('feet','Boots','Çizme')]:
        rows.append(dict(id=f'rpg_{cls}_{slot}',name=[f'{en} {english}',f'{tr} {turkish}'],description=['Original class equipment.','Sınıfa özel özgün donanım.'],category=slot,classes=[cls],cost={'iron':1,'gold':1},effects={'defense':1},level=11,ticks=3,slot=slot,color=color))
    rows.append(dict(id=f'rpg_{cls}_weapon',name=[f'{en} '+{'warrior':'Blade','priest':'Mace','mage':'Staff','rogue':'Bow'}[cls],f'{tr} '+{'warrior':'Kılıcı','priest':'Topuzu','mage':'Asası','rogue':'Yayı'}[cls]],description=['A balanced class starter weapon.','Sınıf için dengeli başlangıç silahı.'],category='weapon',classes=[cls],cost={'iron':1,'wood':1},effects={'attack':5},level=11,ticks=3,slot='weapon',color=color))
for slot,en,tr in [('neck','Wayfarer Pendant','Gezgin Kolyesi'),('belt','Wayfarer Belt','Gezgin Kemeri'),('ring_left','Wayfarer Ring','Gezgin Yüzüğü'),('ear_left','Wayfarer Earring','Gezgin Küpesi')]:
    rows.append(dict(id=f'rpg_{slot}',name=[en,tr],description=['A simple protective accessory.','Basit bir koruyucu takı.'],category=slot,classes=list(themes),cost={'iron':1,'gold':1},effects={'health':3},level=11,ticks=3,slot=slot,color='#72999b'))
for row in rows:
    color=row.pop('color');shape=shapes.get(row['slot'],shapes['weapon'])
    if row['id']=='rpg_mage_weapon':shape='<path d="M62 30h9v93h-9Z" fill="#8b633a"/><path d="m65 9 22 25-22 29-22-29Z" fill="#84d7ee" stroke="#dbc28c" stroke-width="5"/>'
    if row['id']=='rpg_priest_weapon':shape='<path d="M60 47h12v76H60Z" fill="#8b633a"/><path d="m42 17 49 3 10 35-33 19-32-20Z" fill="url(#metal)"/><path d="M67 22v41M44 42h44" stroke="#e6d39c" stroke-width="5"/>'
    if row['id']=='rpg_rogue_weapon':shape='<path d="M42 13q85 51 0 108" fill="none" stroke="#bb975a" stroke-width="9"/><path d="M42 13v108" stroke="#e3d9ac" stroke-width="2"/><path d="M18 65h93l-13-8m13 8-13 8" fill="none" stroke="#a3b0b4" stroke-width="4"/>'
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="132" height="132" viewBox="0 0 132 132"><defs><linearGradient id="metal" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#efe4bd"/><stop offset=".45" stop-color="{color}"/><stop offset=".7" stop-color="#4b4d48"/><stop offset="1" stop-color="#b5ab90"/></linearGradient></defs><rect x="3" y="3" width="126" height="126" rx="8" fill="#131510" stroke="#a78d57" stroke-width="3"/>{shape}</svg>'
    (root/'assets/kingdom'/f'{row["id"]}.svg').write_text(svg,encoding='utf8')
(root/'assets/rpg/equipment.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
print(f'Generated {len(rows)} original equipment definitions/icons')
