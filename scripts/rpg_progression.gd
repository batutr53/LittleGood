extends RefCounted
# Additive versioned extension. The active hero remains adventure.hero for existing campaigns.
const ATTRIBUTES=["strength","dexterity","intelligence","magic","vitality"]
const CLASSES=["warrior","priest","mage","rogue"]
const EXTRA_SLOTS=["head","legs","hands","feet","neck","belt","ring_left","ring_right","ear_left","ear_right"]
const NAMES={"warrior":"Warrior","priest":"Priest","mage":"Mage","rogue":"Rogue"}
const SKILL_NAMES={
	"warrior":[["Cleave","Yarma"],["Iron Guard","Demir Muhafız"],["Charge","Hücum"],["Battle Cry","Savaş Çığlığı"],["Whirlwind","Kasırga"],["Last Stand","Son Direniş"]],
	"priest":[["Sacred Bolt","Kutsal Darbe"],["Blessing","Kutsama"],["Sanctuary","Sığınak"],["Judgment","Hüküm"],["Purify","Arındırma"],["Dawn","Şafak"]],
	"mage":[["Flame Bolt","Alev Oku"],["Frost Ring","Buz Halkası"],["Spark","Kıvılcım"],["Meteor","Göktaşı"],["Arcane Ward","Büyü Kalkanı"],["Storm","Fırtına"]],
	"rogue":[["Precision","İsabet"],["Retreat","Geri Çekilme"],["Twin Strike","Çifte Darbe"],["Shadowstep","Gölge Adımı"],["Piercing Strike","Delici Darbe"],["Ambush","Pusu"]]}
static func skill_name(key: String,index: int,turkish: bool=false) -> String:return SKILL_NAMES[key][index][1 if turkish else 0]
static func available(w: Dictionary) -> bool:
	var kingdom=w.get("kingdom",{})
	if not kingdom is Dictionary:return false
	var adventure=kingdom.get("adventure",{})
	if not adventure is Dictionary:return false
	var hero=adventure.get("hero",{})
	return hero is Dictionary and not hero.is_empty()
static func home(w: Dictionary) -> bool:
	return available(w) and not w.get("_read_only",false) and not w.kingdom.adventure.get("run",{}).get("active",false) and not w.kingdom.get("military",{}).get("battle",{}).get("active",false)
static func ensure(w: Dictionary) -> void:
	if not available(w) or w.get("_read_only",false):return
	var a=w.kingdom.adventure
	if not w.has("rpg"):
		var active=a.hero.get("class","warrior")
		w.rpg={"version":1,"active":active,"roster":{},"progression":{},"loadouts":{},"locked":[],"starter_grants":["warrior"]}
		for key in CLASSES:
			var hero=a.hero if key==active else {"id":1,"name":{"warrior":"Arden","priest":"Elara","mage":"Vaelis","rogue":"Nyra"}[key],"class":key,"xp":0,"hp":100,"equipment":{"weapon":0,"shield":0,"armor":0,"artifact":0},"cooldowns":{"attack":0,"skill":0,"dodge":0,"heal":0},"defeated":false}
			w.rpg.roster[key]=hero
			var attrs={}
			for attr in ATTRIBUTES:attrs[attr]=0
			w.rpg.progression[key]={"attributes":attrs,"skills":[0,0,0,0,0,0],"bar":[0,1,2],"specialization":"archer" if key=="rogue" else key,"mana":100}
			var gear={}
			for slot in EXTRA_SLOTS:gear[slot]=0
			w.rpg.loadouts[key]=gear
	w.rpg.roster[w.rpg.active]=a.hero
static func selected(w: Dictionary) -> Dictionary:
	ensure(w)
	return w.rpg.progression[w.rpg.active] if w.has("rpg") else {}
static func switch(w: Dictionary,key: String) -> bool:
	if not home(w) or not key in CLASSES:return false
	ensure(w);w.rpg.roster[w.rpg.active]=w.kingdom.adventure.hero;w.rpg.active=key;w.kingdom.adventure.hero=w.rpg.roster[key]
	if not w.rpg.has("starter_grants"):w.rpg.starter_grants=["warrior"]
	if not key in w.rpg.starter_grants and w.kingdom.adventure.hero.equipment.weapon==0:
		var I=load("res://scripts/industry.gd");var recipe="rpg_"+key+"_weapon"
		var existing=w.kingdom.industry.items.filter(func(item):return item.recipe==recipe)
		if existing.is_empty() and w.kingdom.industry.items.size()+w.kingdom.industry.queue.size()<I.MAX_ITEMS:
			var item={"id":int(w.kingdom.industry.next_item),"recipe":recipe};w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append(item);existing=[item]
		if not existing.is_empty():w.kingdom.adventure.hero.equipment.weapon=int(existing[0].id);w.rpg.starter_grants.append(key)
	return true
static func points(w: Dictionary,skills=false) -> int:
	var p=selected(w)
	if p.is_empty():return 0
	var level=load("res://scripts/hero.gd").level(w.kingdom.adventure.hero)
	var spent=0
	for value in (p.skills if skills else p.attributes.values()):spent+=int(value)
	return maxi(0,(level-1)*(1 if skills else 5)-spent)
static func allocate(w: Dictionary,draft: Dictionary) -> bool:
	if not home(w) or draft.size()!=ATTRIBUTES.size():return false
	var p=selected(w);var total=0
	for key in ATTRIBUTES:
		if not draft.has(key) or not draft[key] is int or draft[key]<int(p.attributes[key]) or draft[key]>70:return false
		total+=draft[key]-int(p.attributes[key])
	if total>points(w):return false
	p.attributes=draft.duplicate();return true
static func train(w: Dictionary,index: int) -> bool:
	if not home(w) or index<0 or index>=6 or points(w,true)<=0:return false
	var p=selected(w);var level=load("res://scripts/hero.gd").level(w.kingdom.adventure.hero)
	if level<1+index*2 or p.skills[index]>=3:return false
	p.skills[index]+=1;return true
static func reset(w: Dictionary) -> bool:
	if not home(w):return false
	var p=selected(w)
	for key in ATTRIBUTES:p.attributes[key]=0
	p.skills=[0,0,0,0,0,0];w.kingdom.adventure.hero.hp=mini(int(w.kingdom.adventure.hero.hp),int(load("res://scripts/hero.gd").stats(w).health));p.mana=minf(float(p.mana),float(modifiers(w).mana));return true
static func specialize(w: Dictionary,key: String) -> bool:
	if not home(w) or w.kingdom.adventure.hero.get("class")!="rogue" or not key in ["archer","assassin"]:return false
	selected(w).specialization=key;return true
static func modifiers(w: Dictionary) -> Dictionary:
	var result={"health":0,"attack":0,"defense":0,"speed":0,"crit":0,"mana":100}
	if not w.has("rpg") or not available(w):return result
	var key=w.kingdom.adventure.hero.get("class","warrior");var p=w.rpg.progression[key];var a=p.attributes
	result.health=int(a.vitality)*3;result.defense=int(a.vitality)/3;result.speed=int(a.dexterity);result.crit=int(a.dexterity)*2;result.mana=100+int(a.intelligence)*4
	result.attack=int(a.strength) if key=="warrior" else int(a.dexterity) if key=="rogue" else int(a.magic)+int(a.intelligence)/2
	if float(p.get("guard_ms",0))>0:result.defense+=8
	var I=load("res://scripts/industry.gd")
	for id in w.rpg.loadouts[key].values():
		var item=I.item(w,int(id))
		if not item.is_empty():
			var bonuses=I.effects(w,item)
			for stat in bonuses:
				if result.has(stat):result[stat]+=int(bonuses[stat])
	var set_bonuses=load("res://scripts/equipment_sets.gd").bonuses(w)
	for stat in set_bonuses:
		if result.has(stat):result[stat]+=int(set_bonuses[stat])
	return result
static func combat_tick(w: Dictionary):
	if not w.has("rpg"):return
	var p=selected(w);p.mana=minf(float(modifiers(w).mana),float(p.mana)+.3);p.guard_ms=maxf(0,float(p.get("guard_ms",0))-50)
	if not p.has("cooldowns"):p.cooldowns=[0,0,0,0,0,0]
	for i in range(6):p.cooldowns[i]=maxi(0,int(p.cooldowns[i])-50)
static func skill_ready(w: Dictionary,input: Dictionary) -> bool:
	if not w.has("rpg"):return true
	var p=selected(w);var index=int(p.bar[clampi(int(input.get("skill_slot",0)),0,2)])
	if int(p.skills[index])==0:return index==0 and int(p.get("cooldowns",[0,0,0,0,0,0])[0])==0 and float(p.mana)>=8
	return int(p.get("cooldowns",[0,0,0,0,0,0])[index])==0 and (int(p.skills[index])==0 or float(p.mana)>=int(skill_definition(w.kingdom.adventure.hero.get("class","warrior"),index).mana))
static func basic_range(w: Dictionary) -> int:
	var key=w.kingdom.adventure.hero.get("class","warrior")
	if key=="rogue" and w.has("rpg") and selected(w).specialization=="assassin":return 78
	return 300 if key=="mage" else 190 if key=="priest" else 340 if key=="rogue" else 78
static var skill_behaviors={}
static func skill_definition(key: String,index: int) -> Dictionary:
	if skill_behaviors.is_empty():skill_behaviors=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rpg/skill-behaviors.json"))
	return skill_behaviors[key][index]
static func attack_context(w: Dictionary,input: Dictionary) -> Dictionary:
	var key=w.kingdom.adventure.hero.get("class","warrior")
	var result={"range":basic_range(w),"multiplier":1.0,"area":false,"cast":false}
	if not w.has("rpg") or not input.get("skill",false):return result
	if not skill_ready(w,input):return {"range":0,"multiplier":0.0,"area":false,"cast":false}
	var p=selected(w);var index=int(p.bar[clampi(int(input.get("skill_slot",0)),0,2)]);var rank=int(p.skills[index])
	if rank<=0:
		p.mana-=8;result.cast=true;result.multiplier=1.6;p.cooldowns[0]=4000;return result
	var d=skill_definition(key,index)
	p.mana-=int(d.mana);p.cooldowns[index]=int(d.cooldown_ms)
	result.cast=true;result.multiplier=1.4+rank*.2+index*.1+float(d.damage_bonus);result.area=d.area
	if int(d.range)>0:result.range=int(d.range)
	if d.pierce:result.pierce=true
	if d.guard:p.guard_ms=3000+rank*500
	var hero=w.kingdom.adventure.hero;var run=w.kingdom.adventure.run
	if d.dash:run.dash=250;run.invulnerable=300
	if int(d.heal_base)>0:hero.hp=mini(load("res://scripts/hero.gd").stats(w).health,int(hero.hp)+int(d.heal_base)+rank*int(d.heal_per_rank))
	if d.cleanse and run.get("region","")=="ashen_desert":run.poison_until=0;run.poison_next=0
	return result
static func clear_shot(w: Dictionary,from: Vector2,to: Vector2) -> bool:
	var map=load("res://scripts/regions.gd").map(load("res://scripts/regions.gd").current(w))
	for rect in map.solids(w.kingdom.claimed.size()<14):
		var a=rect.position;var b=Vector2(rect.end.x,rect.position.y);var c=rect.end;var d=Vector2(rect.position.x,rect.end.y)
		for edge in [[a,b],[b,c],[c,d],[d,a]]:
			if Geometry2D.segment_intersects_segment(from,to,edge[0],edge[1])!=null:return false
	return true
static func extra_equip(w: Dictionary,slot: String,id: int) -> bool:
	if not home(w) or not slot in EXTRA_SLOTS:return false
	ensure(w)
	if id==0:w.rpg.loadouts[w.rpg.active][slot]=0;clamp_equipment_health(w);return true
	var I=load("res://scripts/industry.gd");var item=I.item(w,id)
	if item.is_empty():return false
	var d=I.recipes()[item.recipe];var category=slot.replace("_right","_left")
	if d.get("category")!=category or not w.rpg.active in d.get("classes",CLASSES):return false
	for key in CLASSES:
		if key!=w.rpg.active and (w.rpg.loadouts[key].values().has(id) or w.rpg.roster[key].equipment.values().has(id)):return false
	for key in EXTRA_SLOTS:
		if int(w.rpg.loadouts[w.rpg.active][key])==id:w.rpg.loadouts[w.rpg.active][key]=0
	w.rpg.loadouts[w.rpg.active][slot]=id;clamp_equipment_health(w);return true
static func clamp_equipment_health(w: Dictionary):
	w.kingdom.adventure.hero.hp=mini(int(w.kingdom.adventure.hero.hp),int(load("res://scripts/hero.gd").stats(w).health))
	selected(w).mana=minf(float(selected(w).mana),float(modifiers(w).mana))
static func normalize(w: Dictionary) -> void:
	if not w.has("rpg") or not available(w):return
	for cls in CLASSES:
		var p=w.rpg.progression[cls]
		for attr in ATTRIBUTES:p.attributes[attr]=int(p.attributes[attr])
		for i in range(6):p.skills[i]=int(p.skills[i])
		for i in range(3):p.bar[i]=int(p.bar[i])
		for slot in EXTRA_SLOTS:w.rpg.loadouts[cls][slot]=int(w.rpg.loadouts[cls][slot])
		var hero=w.rpg.roster[cls]
		for field in ["id","xp","hp"]:hero[field]=int(hero[field])
		for field in hero.equipment:hero.equipment[field]=int(hero.equipment[field])
		for field in hero.cooldowns:hero.cooldowns[field]=int(hero.cooldowns[field])
	for i in range(w.rpg.locked.size()):w.rpg.locked[i]=int(w.rpg.locked[i])
	w.rpg.roster[w.rpg.active]=w.kingdom.adventure.hero
static func reserved(w: Dictionary,id: int) -> bool:
	if not w.has("rpg"):return false
	ensure(w)
	for key in CLASSES:
		if w.rpg.roster[key].equipment.values().any(func(value):return int(value)==id):return true
		if w.rpg.loadouts[key].values().any(func(value):return int(value)==id):return true
	return false
static func lock_item(w: Dictionary,id: int) -> bool:
	if not home(w) or load("res://scripts/industry.gd").item(w,id).is_empty():return false
	ensure(w)
	if id in w.rpg.locked:w.rpg.locked.erase(id)
	else:w.rpg.locked.append(id)
	return true
static func discard(w: Dictionary,id: int) -> bool:
	if not home(w):return false
	ensure(w);var I=load("res://scripts/industry.gd");var owned=I.item(w,id)
	if owned.is_empty() or id in w.rpg.locked or reserved(w,id) or load("res://scripts/military.gd").item_reserved(w,id):return false
	if I.recipes()[owned.recipe].get("category")=="artifact" or w.kingdom.industry.equipped.any(func(s):return int(s.item)==id):return false
	w.kingdom.industry.items.erase(owned);load("res://scripts/armory.gd").remove(w,id);return true
static func validate(w: Dictionary) -> bool:
	if not w.has("rpg"):return true
	if not available(w):return false
	var C=load("res://scripts/cosmetics.gd");var I=load("res://scripts/industry.gd")
	var r=w.rpg
	if not r is Dictionary or r.get("version")!=1 or not r.get("active") in CLASSES:return false
	for field in ["roster","progression","loadouts"]:
		if not r.get(field) is Dictionary or r[field].size()!=4:return false
	if not r.get("locked") is Array or r.locked.size()>32:return false
	if not r.get("starter_grants",[]) is Array or r.get("starter_grants",[]).size()>4:return false
	var grants=[]
	for key in r.get("starter_grants",[]):
		if not key in CLASSES or key in grants:return false
		grants.append(key)
	var locks=[]
	for id in r.locked:
		if not C.number(id,1,100000,true) or int(id) in locks or I.item(w,int(id)).is_empty():return false
		locks.append(int(id))
	var used=[]
	for key in CLASSES:
		if not r.roster.has(key) or not r.progression.has(key) or not r.loadouts.has(key):return false
		var h=w.kingdom.adventure.hero if r.active==key else r.roster[key];var p=r.progression[key]
		if not h is Dictionary or h.get("class")!=key or not h.get("equipment") is Dictionary or not h.get("xp") is float and not h.get("xp") is int:return false
		if not C.shape(h,["id","name","class","xp","hp","equipment","cooldowns","defeated"]) or h.id!=1 or not load("res://scripts/hero.gd").valid_name(h.name) or not C.number(h.xp,0,1000000,true) or not h.defeated is bool:return false
		if not C.shape(h.equipment,["weapon","shield","armor","artifact"]) or not C.shape(h.cooldowns,["attack","skill","dodge","heal"]):return false
		for cd in h.cooldowns.values():
			if not C.number(cd,0,10000,true):return false
		if not C.shape(r.loadouts[key],EXTRA_SLOTS):return false
		if not p is Dictionary or not p.get("attributes") is Dictionary or not p.get("skills") is Array or p.skills.size()!=6 or not p.get("bar") is Array or p.bar.size()!=3:return false
		if not C.shape(p.attributes,ATTRIBUTES) or not C.number(p.get("mana"),0,388,false) or not C.number(p.get("guard_ms",0),0,4500,false):return false
		var spent=0
		for attr in ATTRIBUTES:
			var n=p.attributes.get(attr,-1)
			if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>70 or n!=int(n):return false
			spent+=int(n)
		var level=load("res://scripts/hero.gd").level(h)
		if spent>(level-1)*5:return false
		spent=0
		for n in p.skills:
			if not (n is int or n is float) or n<0 or n>3 or n!=int(n):return false
			spent+=int(n)
		for index in range(6):
			if int(p.skills[index])>0 and level<1+index*2:return false
		if spent>level-1:return false
		if p.has("cooldowns"):
			if not p.cooldowns is Array or p.cooldowns.size()!=6:return false
			for cd in p.cooldowns:
				if not C.number(cd,0,6500,true):return false
		for n in p.bar:
			if not (n is int or n is float) or n<0 or n>5 or n!=int(n):return false
		if not p.get("specialization") in (["archer","assassin"] if key=="rogue" else [key]):return false
		for id in h.equipment.values()+r.loadouts[key].values():
			if not C.number(id,0,100000,true):return false
			if int(id)==0:continue
			if int(id) in used or load("res://scripts/industry.gd").item(w,int(id)).is_empty():return false
			used.append(int(id))
		for slot in r.loadouts[key]:
			var id=int(r.loadouts[key][slot])
			if id==0:continue
			var d=I.recipes()[I.item(w,id).recipe]
			if d.get("category")!=slot.replace("_right","_left") or not key in d.get("classes",CLASSES):return false
		for slot in h.equipment:
			var id=int(h.equipment[slot])
			if id==0:continue
			var d=I.recipes()[I.item(w,id).recipe]
			if d.get("category")!=slot or not key in d.get("classes",["warrior"] if slot!="artifact" else CLASSES):return false
		if not C.number(h.hp,0,1000,true) or h.defeated!=(h.hp==0):return false
	return true
