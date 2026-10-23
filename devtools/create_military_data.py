"""Add the optional Chapter IV without rewriting prior campaign records."""
import json
from pathlib import Path
r=Path(__file__).resolve().parents[1]
def edit(path,change):
 p=r/path;s=p.read_text(encoding='utf-8');p.write_text(change(s),encoding='utf-8')
def data(path,entries):
 p=r/path;a=json.loads(p.read_text(encoding='utf-8'));ids={x['id'] for x in a};a.extend(x for x in entries if x['id'] not in ids);p.write_text(json.dumps(a,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
build=[]
for key,names,desc,level,cost,slots in [
 ('barracks',['Border Barracks','Sınır Kışlası'],['An assigned instructor trains citizens using real equipment.','Atanmış eğitmen gerçek donanımla sakinleri eğitir.'],16,dict(wood=12,stone=8,gold=2),1),
 ('watchtower',['Beacon Watchtower','İşaret Gözetleme Kulesi'],['Adds 2 attack to defenders during a raid.','Baskında savunanlara 2 saldırı ekler.'],18,dict(wood=10,stone=8),0),
 ('wall',['Palisade Gate','Çit Kapısı'],['Adds 3 defense to soldiers defending the village.','Köyü savunan askerlere 3 savunma ekler.'],18,dict(wood=6,stone=12),0)]:
 build.append(dict(id=key,name=names,description=desc,level=level,cost=cost,ticks=6,slots=slots,output='',role=['Instructor','Eğitmen'],site='land',limit=1))
data('assets/kingdom/buildings.json',build)
recipes=[]
for kind,names,atk,defense,reach,speed in [('militia',['Militia kit','Milis takımı'],11,3,48,100),('spearman',['Spearman kit','Mızrakçı takımı'],14,2,78,90),('archer',['Archer kit','Okçu takımı'],10,1,190,85)]:
 recipes.append(dict(id=kind+'_kit',name=names,description=[f'{atk} attack · {defense} armor · range {reach}',f'{atk} saldırı · {defense} zırh · menzil {reach}'],cost=dict(iron=1,wood=2),effects=dict(attack=atk,defense=defense,range=reach,speed=speed),category='military',level=17,ticks=4,building='forge'))
data('assets/kingdom/recipes.json',recipes)
quests=[]
for level,title,desc,objectives in [
 (16,['A Beacon at the Border','Sınırda Bir İşaret'],['Build a barracks and appoint an instructor.','Kışla kur ve bir eğitmen ata.'],[('building','barracks',1,['Build a barracks','Kışla inşa et'],'build_barracks'),('military','instructor',1,['Assign an instructor','Eğitmen ata'],'workers')]),
 (17,['The First Company','İlk Birlik'],['Forge three kits, recruit free citizens and train your company.','Üç takım döv, boşta sakinler al ve birliğini eğit.'],[('military','trained',3,['Train three soldiers','Üç asker eğit'],'army')]),
 (18,['Walls and Resolve','Duvarlar ve Kararlılık'],['Prepare the village and choose a formation.','Köyü hazırla ve bir düzen seç.'],[('building','watchtower',1,['Build a watchtower','Gözetleme kulesi kur'],'build_watchtower'),('building','wall',1,['Build a palisade gate','Çit kapısı kur'],'build_wall'),('military','formation',1,['Choose a formation','Savaş düzeni seç'],'army')]),
 (19,['Hold the Hearth','Ocağı Savun'],['Repel the raiders. Your defenses protect the company. Return to report.','Baskıncıları püskürt. Savunmaların birliği korur. Rapor vermek için dön.'],[('military','raid',1,['Win the village defense','Köy savunmasını kazan'],'army'),('military','raid_returned',1,['Return from the defense','Savunmadan dön'],'army')]),
 (20,['The Border Captain','Sınır Komutanı'],['Lead your company around the camp barricade and defeat its captain.','Birliğini kamp barikatından geçir ve komutanı yen.'],[('military','camp',1,['Defeat the camp captain','Kamp komutanını yen'],'army'),('military','camp_returned',1,['Bring the company home','Birliği eve getir'],'army')])]:
 quests.append(dict(id=f'main_{level}',level=level,chapter=4,title=title,description=desc,tracking='realm_lifetime',prerequisites=[f'main_{level-1}'],objectives=[dict(kind=k,key=key,target=n,text=t,navigate=nav) for k,key,n,t,nav in objectives],rewards=dict(xp=40*level,wood=8,stone=4,gold=4),next=f'main_{level+1}' if level<20 else ''))
data('assets/kingdom/quests.json',quests)
