"""Create original, explicit LittleGod equipment and source-audit data. No remote images."""
from pathlib import Path
import json
r=Path(__file__).resolve().parents[1]
def write(path,value):
 p=r/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
rows=[]
names={'warrior':('Dawnsteel','Şafak Çeliği'),'priest':('Hallowlight','Kutsal Işık'),'mage':('Winterglass','Kış Camı'),'rogue':('Verdant Whisper','Yeşil Fısıltı')}
for cls,(en,tr) in names.items():
 for tier in ['high','legend']:
  rows.append({'id':tier+'_'+cls+'_weapon','name':[en+(' Relic' if tier=='legend' else ' Weapon'),tr+(' Yadigârı' if tier=='legend' else ' Silahı')],'description':['Original class weapon. Its grade, enhancement and element are separate properties.','Sınıfa özel özgün silah. Derece, yükseltme ve element ayrı özelliklerdir.'],'category':'weapon','classes':[cls],'cost':{'iron':4 if tier=='high' else 8,'gold':4 if tier=='high' else 8},'effects':{'attack':10 if tier=='high' else 15},'level':14 if tier=='high' else 15,'ticks':5 if tier=='high' else 8,'source':'LittleGod original balance; not a copied KO item'})
write('assets/rpg/armory-equipment.json',rows)
for row in rows:
 cls=row['classes'][0]
 (r/'assets/kingdom'/f"{row['id']}.svg").write_bytes((r/'assets/kingdom'/f'rpg_{cls}_weapon.svg').read_bytes())
sources=[
 {'url':'https://kobugda.com/drops','status':'Public page readable; live monster rows absent in returned HTML; direct HTTP403; browser disabled','verified':['Zone filters and separate item/monster searches'],'missing':['Complete live monster-item rows','Monster drop percentages','Item stat tables']},
 {'url':'https://old.kobugda.com/Drops','status':'Readable static reference; explicitly player-observed','verified':['Dragon Tooth: hammer family','Harpy Queen: class earrings','Shaula: bow/shield families','Bosses grouped by region'],'missing':['Authoritative drop rates']},
 {'url':'https://kobugda.com/blog/knight-online-anvil-simulator-guide','status':'Conflicts with other guides','verified':['Simulator keeps items on failure','Published standard row chances:98,80,57,35,20,6,1 percent'],'conflict':'Article example says6% at+7 while table says1%; not authoritative server rates'},
 {'url':'https://kobugda.com/blog/knight-online-rebirth-upgrade-system-guide','status':'Reference mechanics, approximate odds','verified':['High/unique equipment +7 or higher may reverse; accessories excluded','Normal7/8/9/10 maps to rebirth1/5/11/21','Conversion100%; strengthened rebirth described as approximately25%','Four glow bands'],'conflict':'Destruction described here; simulator guide retains items'},
 {'url':'https://kobugda.com/rebirth','status':'Character progression, separate from item rebirth','verified':['Character level83 requirement','2 bonus stat points per character rebirth','Quest-reset behavior'],'adaptation':'Character rebirth not implemented; existing campaign never reset'},
 {'url':'https://kobugda.com/quests/skill','status':'Readable','verified':['Accessory disassembly supplies skill powders','Requirements scale with ability level'],'adaptation':'Class skill trees retained; powder unlocks pending'},
 {'url':'https://kobugda.com/quests/keyholder','status':'Readable','verified':['Seven NPCs with sequential questions and level requirement'],'adaptation':'LittleGod contract board implemented; seven-NPC quest/map not yet implemented'},
 {'url':'https://kobugda.com/quests/daily','status':'Readable','verified':['NPC kill objectives and explicit rewards'],'adaptation':'One-time hunt/craft/guardian/refinement contracts, no daily absence penalty'},
 {'url':'https://kobugda.com/skill-calculator','status':'App shell only','missing':['Complete class skill numbers and animations']},
 {'url':'https://kobugda.com/calculator/advanced','status':'App shell only','missing':['AP formula and full item stats']},
 {'url':'https://kobugda.com/sets','status':'App shell only','verified':['Class filters and piece-count bonuses'],'missing':['Complete bonus values']},
 {'url':'https://kobugda.com/probabilities','status':'App shell only, data loading message','missing':['Loaded probability tables']},
 {'url':'https://kobugda.com/anvil','status':'Readable controls and image references','verified':['Separate upgrade, reverse and rebirth-strengthening scroll roles']}
]
write('docs/research/kobugda-audit.json',{'date':'2026-10-26','complete':False,'art_permission':'No redistribution license found; all-rights-reserved footer. No third-party image copied into assets.','sources':sources,'balance':'See assets/rpg/forge-rules.json; explicit LittleGod adaptation, not verified KO server odds'})
all_rows=json.loads((r/'assets/kingdom/recipes.json').read_text(encoding='utf8'))+json.loads((r/'assets/rpg/equipment.json').read_text(encoding='utf8'))+rows
write('docs/research/littlegod-armory-catalogue.json',[{'id':x['id'],'name':x['name'],'category':x.get('category','tool'),'classes':x.get('classes',['warrior'] if x.get('category') in ['weapon','shield','armor'] else []),'effects':x['effects'],'source':'LittleGod existing definition' if x not in rows else 'LittleGod original adaptation','reference_stats_copied':False} for x in all_rows])
