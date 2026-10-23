"""Original chapter-II gameplay data; no placeholder later-campaign quests."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1];out=root/'assets/kingdom'
def write(name,data):(out/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
buildings=json.loads((out/'buildings.json').read_text(encoding='utf-8'))[:5]
rows=[('quarry',['Sunstone Quarry','Güneştaşı Ocağı'],['Stonecutters gather real rock for your village.','Taşçılar köyün için gerçek kaya kaynaklarını toplar.'],6,{'wood':12,'stone':4},'stone','rock',['Stonecutter','Taşçı']),('mine',['Ironvein Mine','Demirdamar Madeni'],['Miners extract ore. Move a worker here after building.','Madenciler cevher çıkarır. İnşa bitince bir işçi ata.'],7,{'wood':14,'stone':8},'ore','rock',['Miner','Madenci']),('furnace',['Ember Furnace','Kor Fırını'],['Smelters consume two ore and one timber per iron.','Dökümcüler her demir için iki cevher ve bir odun tüketir.'],8,{'wood':14,'stone':10},'iron','land',['Smelter','Dökümcü']),('forge',['Hearthforge','Ocak Demircisi'],['Assign a smith and queue tools in the workshop.','Bir demirci ata ve atölyede aletleri sıraya koy.'],9,{'wood':18,'stone':8,'iron':2},'','land',['Smith','Demirci'])]
for key,name,description,level,cost,output,site,role in rows:
 b={'id':key,'name':name,'description':description,'level':level,'cost':cost,'ticks':6,'slots':2,'output':output,'role':role,'site':site,'limit':2}
 if key=='furnace':b['inputs']={'ore':2,'wood':1}
 buildings.append(b)
write('buildings.json',buildings)
recipes=[]
for key,name,cost,effects,description in [
 ('forest_axe',['Forester’s Axe','Ormancı Baltası'],{'iron':2,'wood':2},{'lumber':1500},['Timber output +50% for its equipped citizen.','Kuşanan sakinin odun üretimi +%50.']),
 ('iron_pick',['Iron Pick','Demir Kazma'],{'iron':2,'wood':1},{'mine':1500,'quarry':1350},['Ore +50%, stone +35% for its equipped citizen.','Kuşanan sakinin cevheri +%50, taşı +%35.']),
 ('field_sickle',['Rainseed Sickle','Yağmur Tohumu Orağı'],{'iron':1,'wood':1},{'farm':1350},['Food output +35% for its equipped farmer.','Kuşanan çiftçinin besin üretimi +%35.']),
 ('mason_hammer',['Mason’s Hammer','Taşçı Çekici'],{'iron':1,'wood':2},{'quarry':1250,'builder':1250},['Stone and idle construction labor +25%.','Taş üretimi ve boştaki inşaat emeği +%25.'])]:
 recipes.append({'id':key,'name':name,'description':description,'cost':cost,'effects':effects,'level':9,'ticks':4,'building':'forge'})
write('recipes.json',recipes)
quests=json.loads((out/'quests.json').read_text(encoding='utf-8'))[:5]
quests[4]['next']='main_06'
def obj(kind,key,target,en,tr,navigate):return {'kind':kind,'key':key,'target':target,'text':[en,tr],'navigate':navigate}
rows=[
 (6,['Stone for Tomorrow','Yarın İçin Taş'],['Raise a quarry on rocky land and give a citizen a stonecutting job.','Kayalık arazide ocak kur; bir sakine taşçılık işi ver.'],[obj('building','quarry',1,'Finish a quarry','Taş ocağını tamamla','build_quarry'),obj('event','produce_stone',6,'Produce stone with a stonecutter','Taşçıyla taş üret','workers')]),
 (7,['Beneath the Mountain','Dağın Altında'],['Your miners find iron ore in the mountain. Save it for smelting.','Madencilerin dağda demir cevheri bulur. Döküm için biriktir.'],[obj('building','mine',1,'Finish an iron mine','Demir madenini tamamla','build_mine'),obj('event','produce_ore',12,'Extract ore','Cevher çıkar','workers')]),
 (8,['The First Ember','İlk Kor'],['Wood fuels the furnace; ore becomes iron. Every bar has real inputs.','Odun fırını besler; cevher demire dönüşür. Her külçe gerçek malzeme tüketir.'],[obj('building','furnace',1,'Finish a furnace','Fırını tamamla','build_furnace'),obj('event','produce_iron',6,'Smelt iron','Demir dök','workers')]),
 (9,['Hands of the Smith','Demircinin Elleri'],['Build a forge. Give a smith a job, then craft an axe and a pick.','Demirci kur. Bir demirci ata; sonra balta ve kazma üret.'],[obj('building','forge',1,'Finish a forge','Demirciyi tamamla','build_forge'),obj('event','craft_forest_axe',1,'Craft a Forester’s Axe','Ormancı Baltası üret','workshop'),obj('event','craft_iron_pick',1,'Craft an Iron Pick','Demir Kazma üret','workshop')]),
 (10,['Tools of a New Age','Yeni Çağın Aletleri'],['Equip your citizens. Watch their real work benefit from the tools you made.','Sakinlerine alet kuşandır. Ürettiklerinin gerçek işleri hızlandırmasını izle.'],[obj('equipment','tools',2,'Equip two citizens','İki sakine alet kuşandır','inventory'),obj('event','tool_work',6,'Work productively with equipped tools','Kuşanılmış aletlerle verimli çalış','workers')])]
for level,title,description,objectives in rows:
 quests.append({'id':f'main_{level:02}','level':level,'chapter':2,'title':title,'description':description,'tracking':'realm_lifetime','prerequisites':[f'main_{level-1:02}'],'objectives':objectives,'rewards':{'xp':40*level,'wood':12,'stone':8,'gold':3},'next':f'main_{level+1:02}' if level<10 else ''})
write('quests.json',quests)
print('Nine functional building types, four working tool recipes, ten main quests.')
