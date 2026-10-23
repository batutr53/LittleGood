extends RefCounted
const I=preload("res://scripts/industry.gd")
const REALM_CAP=11
const MATERIALS=["leather","thornhide","herb","heart"]
const SLOTS=["weapon","shield","armor","artifact"]
static func enabled(w: Dictionary) -> bool:return w.has("kingdom") and int(w.kingdom.get("version",1))==3
static func writable(w: Dictionary) -> bool:return enabled(w) and not w.get("_read_only",false)
static func enable(w: Dictionary) -> bool:
	if w.get("_read_only",false) or not I.enabled(w) or enabled(w) or w.kingdom.claimed.size()!=10:return false
	w.kingdom.version=3
	for key in MATERIALS:w.kingdom.stock[key]=0
	w.kingdom.adventure={"version":1,"hero":{},"events":{},"run":{},"boss_rewarded":false,"next_run":1,"tutorial":false}
	return true
static func valid_name(value: Variant) -> bool:
	if not value is String or value.strip_edges()!=value or value.is_empty() or value.length()>24:return false
	for c in value:
		if c.unicode_at(0)<32 or c in ["<",">","[","]","/","\\"]:return false
	return true
static func recruit(w: Dictionary,name: String) -> bool:
	if not writable(w) or not valid_name(name) or not w.kingdom.adventure.hero.is_empty() or w.settlements[0].food<5 or w.kingdom.stock.gold<3000:return false
	w.settlements[0].food-=5;w.kingdom.stock.gold-=3000
	w.kingdom.adventure.hero={"id":1,"name":name,"class":"warrior","xp":0,"hp":100,"equipment":{"weapon":0,"shield":0,"armor":0,"artifact":0},"cooldowns":{"attack":0,"skill":0,"dodge":0,"heal":0},"defeated":false}
	return true
static func level(h: Dictionary) -> int:return mini(15,1+floori(sqrt(float(h.xp)/40.0)))
static func stats(w: Dictionary) -> Dictionary:
	var h=w.kingdom.adventure.hero;var n=level(h)-1
	var result={"health":100+6*n,"attack":10+2*n,"defense":2+n,"speed":180,"crit":100}
	for slot in SLOTS:
		var owned=I.item(w,int(h.equipment[slot]))
		if not owned.is_empty():
			for key in I.recipes()[owned.recipe].effects:
				if result.has(key):result[key]+=int(I.recipes()[owned.recipe].effects[key])
	return result
static func equip(w: Dictionary,slot: String,id: int) -> bool:
	if not writable(w) or w.kingdom.adventure.hero.is_empty() or not slot in SLOTS:return false
	var a=w.kingdom.adventure
	if not a.run.is_empty() and a.run.get("active",false):return false
	if id!=0:
		var owned=I.item(w,id)
		if owned.is_empty() or I.recipes()[owned.recipe].get("category","tool")!=slot:return false
	a.hero.equipment[slot]=id;a.hero.hp=mini(int(a.hero.hp),int(stats(w).health));return true
static func progress(w: Dictionary,key: String) -> float:
	if not enabled(w):return 0
	var a=w.kingdom.adventure
	if key=="hero_armed":return 1 if not a.hero.is_empty() and int(a.hero.equipment.weapon)>0 else 0
	if key=="combat_upgrade":
		if a.hero.is_empty():return 0
		var owned=I.item(w,int(a.hero.equipment.weapon))
		return 1 if not owned.is_empty() and owned.recipe=="thornblade" else 0
	return float(a.events.get(key,0))
static func event(w: Dictionary,key: String,amount: int=1) -> void:
	var events=w.kingdom.adventure.events;events[key]=mini(1000000,int(events.get(key,0))+amount)
static func normalize(w: Dictionary) -> void:
	if not enabled(w):return
	var a=w.kingdom.adventure;a.version=int(a.version);a.next_run=int(a.next_run)
	for key in a.events:a.events[key]=int(a.events[key])
	if not a.hero.is_empty():
		for key in ["id","xp","hp"]:a.hero[key]=int(a.hero[key])
		for key in SLOTS:a.hero.equipment[key]=int(a.hero.equipment[key])
		for key in a.hero.cooldowns:a.hero.cooldowns[key]=int(a.hero.cooldowns[key])
static func validate(w: Dictionary) -> bool:
	if not enabled(w):return true
	var C=preload("res://scripts/cosmetics.gd");var a=w.kingdom.get("adventure")
	if not C.shape(a,["version","hero","events","run","boss_rewarded","next_run","tutorial"]) or not C.number(a.version,1,1,true) or not C.number(a.next_run,1,1000000,true) or not a.boss_rewarded is bool or not a.tutorial is bool or not a.run is Dictionary:return false
	if not a.events is Dictionary or a.events.size()>16:return false
	for key in a.events:
		if not key in ["landmark","returned","kills","picked","banked","healed","boss","chest","harvest","dodged"] or not C.number(a.events[key],0,1000000,true):return false
	if not a.hero is Dictionary:return false
	if a.hero.is_empty():return a.run.is_empty()
	var h=a.hero
	if not C.shape(h,["id","name","class","xp","hp","equipment","cooldowns","defeated"]) or not C.number(h.id,1,1,true) or not valid_name(h.name) or h.get("class")!="warrior" or not C.number(h.xp,0,1000000,true) or not h.defeated is bool:return false
	if not C.shape(h.equipment,SLOTS) or not C.shape(h.cooldowns,["attack","skill","dodge","heal"]):return false
	var used=[]
	for slot in SLOTS:
		var id=h.equipment[slot]
		if not C.number(id,0,w.kingdom.industry.next_item-1,true):return false
		if id>0:
			var owned=I.item(w,int(id))
			if owned.is_empty() or used.has(int(id)) or I.recipes()[owned.recipe].get("category","tool")!=slot:return false
			used.append(int(id))
	for key in h.cooldowns:
		if not C.number(h.cooldowns[key],0,10000,true):return false
	if not C.number(h.hp,0,stats(w).health,true) or h.defeated!=(h.hp==0):return false
	return a.run.is_empty()
