from pathlib import Path
import json
root=Path(__file__).resolve().parents[1];out=root/'assets/kingdom'
def write(name,data):(out/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
recipes=json.loads((out/'recipes.json').read_text(encoding='utf-8'))[:4]
for key,name,category,level,cost,effects in [
 ('iron_sword',['Iron Sword','Demir Kılıç'],'weapon',11,{'iron':2,'wood':1},{'attack':8}),
 ('reinforced_shield',['Reinforced Shield','Güçlendirilmiş Kalkan'],'shield',11,{'iron':2,'wood':2},{'defense':3}),
 ('leather_armor',['Trailguard Armor','Patika Muhafızı Zırhı'],'armor',13,{'leather':2,'iron':1},{'defense':4}),
 ('healing_potion',['Herbal Draught','Şifalı Bitki İksiri'],'consumable',13,{'herb':1,'wood':1},{'heal':35}),
 ('thornblade',['Thornhide Blade','Dikenderi Kılıcı'],'weapon',14,{'thornhide':2,'iron':2,'leather':1},{'attack':16}),
 ('heartward',['Heart of Wildwood','Yabanorman Kalbi'],'artifact',15,{'heart':1,'iron':1},{'health':20,'attack':2})]:
 description={'iron_sword':['+8 attack. A real forged weapon.','+8 saldırı. Gerçek dövülmüş silah.'],'reinforced_shield':['+3 defense against incoming hits.','Gelen darbelere karşı +3 savunma.'],'leather_armor':['+4 defense. Made from recovered leather.','+4 savunma. Getirilen deriden üretilir.'],'healing_potion':['Restore 35 health. Consumed once.','35 can yeniler. Bir kez tüketilir.'],'thornblade':['+16 attack. Thornhide makes a sharper edge.','+16 saldırı. Dikenderi keskinliği artırır.'],'heartward':['+20 maximum health and +2 attack.','+20 azami can ve +2 saldırı.']}[key]
 recipes.append({'id':key,'name':name,'description':description,'cost':cost,'effects':effects,'category':category,'level':level,'ticks':4,'building':'forge'})
write('recipes.json',recipes)
quests=json.loads((out/'quests.json').read_text(encoding='utf-8'))[:10];quests[-1]['next']='main_11'
def objective(key,target,text,navigate):return {'kind':'adventure','key':key,'target':target,'text':text,'navigate':navigate}
rows=[
 (11,['The Chosen Champion','Seçilmiş Şampiyon'],['Arin asks a brave citizen to follow the forest trail. Name your Warrior and forge a sword.','Arin, cesur bir yurttaştan orman izini takip etmesini ister. Savaşçını adlandır ve bir kılıç döv.'],[objective('hero_armed',1,['Recruit and arm your Warrior','Savaşçını çağır ve silah kuşandır'],'hero')]),
 (12,['Beyond the Border','Sınırın Ötesinde'],['Wildwood remembers an older kingdom. Find the Sunstone landmark and return to tell Arin.','Yabanorman eski bir krallığı hatırlar. Güneştaşı anıtını bul ve Arin’e anlatmak için dön.'],[objective('landmark',1,['Discover the Sunstone','Güneştaşını keşfet'],'wildwood'),objective('returned',1,['Return to your kingdom','Krallığına dön'],'wildwood')]),
 (13,['The First Hunt','İlk Av'],['The forest is hurting. Defeat its hostile beasts, bring back their materials, and learn to heal.','Orman acı çekiyor. Düşman yaratıkları yen, malzemelerini geri getir ve iyileşmeyi öğren.'],[objective('kills',3,['Defeat three hostile creatures','Üç düşman yaratığı yen'],'wildwood'),objective('banked',3,['Bring three loot pickups home','Üç ganimet alımını eve getir'],'wildwood'),objective('healed',1,['Use a healing herb or potion','Şifalı bitki veya iksir kullan'],'wildwood')]),
 (14,['The Blacksmith’s Secret','Demircinin Sırrı'],['Thornhide can bind a sharper iron edge. Craft and equip the Thornhide Blade before facing its source.','Dikenderi demirin keskinliğini bağlar. Kaynağıyla yüzleşmeden Dikenderi Kılıcı üret ve kuşan.'],[objective('combat_upgrade',1,['Craft and equip a Thornhide Blade','Dikenderi Kılıcı üret ve kuşan'],'hero')]),
 (15,['Guardian of the Forest','Ormanın Muhafızı'],['Thornheart guards the broken grove. Read its warnings, dodge its roots, and bring peace to Wildwood.','Dikenyürek kırık koruluğu korur. Uyarıları oku, köklerinden kaç ve Yabanorman’a huzur getir.'],[objective('boss',1,['Defeat Thornheart','Dikenyürek’i yen'],'wildwood'),objective('banked',4,['Return with the guardian’s reward','Muhafızın ödülüyle dön'],'wildwood')])]
for level,title,description,objectives in rows:
 quests.append({'id':f'main_{level:02}','level':level,'chapter':3,'title':title,'description':description,'tracking':'realm_lifetime','prerequisites':[f'main_{level-1:02}'],'objectives':objectives,'rewards':{'xp':40*level,'wood':8,'stone':4,'gold':4},'next':f'main_{level+1:02}' if level<15 else ''})
write('quests.json',quests)
