extends RefCounted
# Original game balance; reference facts and conflicting claims live in docs/research.
static var rules_cache={}
static func rules() -> Dictionary:
	if rules_cache.is_empty():rules_cache=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rpg/forge-rules.json"))
	return rules_cache
static func ensure(w: Dictionary) -> void:
	if w.has("armory") or not load("res://scripts/rpg_progression.gd").home(w):return
	var rng=RandomNumberGenerator.new();rng.seed=int(w.seed)^79193071
	w.armory={"version":1,"items":{},"rng":str(rng.state),"serial":0,"history":[],"kills":{},"claims":[]}
	# Credit existing, verifiable victories once without rerolling old loot.
	var adventure=w.kingdom.adventure;var runs=[adventure.get("run",{})]
	runs.append_array(adventure.get("regions",{}).get("stored",{}).values())
	for run in runs:
		for enemy in run.get("enemies",[]):
			if enemy.get("state","")=="dead" and int(enemy.get("hp",1))==0:w.armory.kills[enemy.kind]=int(w.armory.kills.get(enemy.kind,0))+1
static func grade(recipe: String) -> String:
	if recipe.begins_with("legend_"):return "unique"
	var d=load("res://scripts/industry.gd").recipes().get(recipe,{})
	if d.get("category","")=="artifact":return "unique"
	if recipe in ["thornblade","ancient_blade","ruinwalker_armor","sunguard_shield"] or recipe.begins_with("high_"):return "high"
	return "middle" if recipe.begins_with("rpg_") or int(d.get("level",0))>=11 else "low"
static func color(recipe: String) -> Color:return Color(rules().grade_colors[grade(recipe)])
static func icon(recipe: String) -> Texture2D:
	var slot=-1;var cls=0
	if recipe.begins_with("armory_") and recipe.ends_with("scroll"):slot=15
	for key in ["warrior","priest","mage","rogue"]:
		if recipe.contains(key):
			if recipe.ends_with("weapon"):slot=cls
			elif recipe.ends_with("head"):slot=4+cls
			elif recipe.ends_with("armor"):slot=8+cls
		cls+=1
	if recipe in ["iron_sword","thornblade","ancient_blade"]:slot=0
	if recipe in ["leather_armor","ruinwalker_armor"]:slot=8
	if recipe=="rpg_ring_left":slot=12
	if recipe in ["rpg_neck","rpg_ear_left"]:slot=13
	if recipe in ["reinforced_shield","sunguard_shield"]:slot=14
	if slot<0:return load("res://assets/kingdom/"+recipe+".svg")
	var atlas=load("res://assets/rpg/equipment-atlas-v2.png");var extent=atlas.get_width()/4.0
	var texture=AtlasTexture.new();texture.atlas=atlas;texture.region=Rect2((slot%4)*extent,(slot/4)*extent,extent,extent);texture.filter_clip=true;return texture
static func eligible(w: Dictionary,id: int) -> bool:
	var I=load("res://scripts/industry.gd");var item=I.item(w,id)
	if item.is_empty():return false
	return I.recipes()[item.recipe].get("category","") in ["weapon","shield","armor","head","legs","hands","feet","neck","belt","ring_left","ear_left"]
static func state(w: Dictionary,id: int) -> Dictionary:
	var fallback={"normal":0,"rebirth":0,"element":"none"};var a=w.get("armory",{})
	if not a is Dictionary or not a.get("items",{}) is Dictionary:return fallback
	var s=a.get("items",{}).get(str(id),fallback);var C=load("res://scripts/planet_showcase.gd")
	if not C.shape(s,["normal","rebirth","element"]) or not C.number(s.normal,0,10,true) or not C.number(s.rebirth,0,21,true) or not s.element in rules().elements:return fallback
	return s
static func effects(w: Dictionary,item: Dictionary) -> Dictionary:
	var result=load("res://scripts/industry.gd").recipes()[item.recipe].effects.duplicate()
	if not eligible(w,int(item.id)):return result
	var s=state(w,int(item.id));var bonus=int(rules().rebirth_attack_bonus[int(s.rebirth)]) if int(s.rebirth)>0 else int(rules().normal_attack_bonus[int(s.normal)])
	if result.has("attack"):result.attack+=bonus+(2 if s.element!="none" else 0)
	elif result.has("defense"):result.defense+=ceili(bonus/2.0)
	elif result.has("health"):result.health+=bonus*2
	return result
static func label(w: Dictionary,item: Dictionary,turkish=false) -> String:
	var d=load("res://scripts/industry.gd").recipes()[item.recipe];var s=state(w,int(item.id));var name=d.name[1 if turkish else 0]
	return name+(" · REB +"+str(int(s.rebirth)) if int(s.rebirth)>0 else " (+"+str(int(s.normal))+")") if eligible(w,int(item.id)) else name
static func quote(w: Dictionary,id: int,mode: String,element: String="none") -> Dictionary:
	var R=load("res://scripts/rpg_progression.gd");var I=load("res://scripts/industry.gd")
	if not R.home(w) or not eligible(w,id):return {}
	if w.get("rpg",{}).get("locked",[]).has(id) or load("res://scripts/military.gd").item_reserved(w,id) or w.kingdom.industry.equipped.any(func(slot):return int(slot.item)==id):return {}
	if w.has("rpg"):
		for key in R.CLASSES:
			if key!=w.rpg.active and (w.rpg.roster[key].equipment.values().has(id) or w.rpg.loadouts[key].values().has(id)):return {}
	var s=state(w,id);var item=I.item(w,id);var category=I.recipes()[item.recipe].category;var q={"id":id,"mode":mode,"element":element,"serial":int(w.get("armory",{}).get("serial",0)),"chance_bp":10000,"cost":{},"before":s.duplicate(),"after":s.duplicate()}
	match mode:
		"normal":
			if int(s.rebirth)>0 or int(s.normal)>=10:return {}
			q.chance_bp=int(rules().normal_chance_bp[int(s.normal)]);q.cost={"iron":1+int(s.normal)/3,"gold":1+int(s.normal)};q.after.normal=int(s.normal)+1
		"reverse":
			if not grade(item.recipe) in ["high","unique"] or not category in ["weapon","shield","armor","head","legs","hands","feet"] or int(s.normal)<7 or int(s.rebirth)>0:return {}
			q.cost={"iron":4,"gold":8};q.after.rebirth=int(rules().reverse_map[str(int(s.normal))])
		"rebirth":
			if int(s.rebirth)<=0 or int(s.rebirth)>=21:return {}
			q.chance_bp=int(rules().rebirth_chance_bp);q.cost={"iron":2,"gold":2+int(s.rebirth)/5};q.after.rebirth=int(s.rebirth)+1
		"element":
			if category!="weapon" or not element in rules().elements or element=="none" or s.element==element:return {}
			q.cost={"iron":2,"gold":3};q.after.element=element
		_:return {}
	q.scroll_recipe=scroll_recipe(mode);q.scroll_id=scroll_item(w,mode)
	return q
static func scroll_recipe(mode: String) -> String:return {"normal":"armory_refine_scroll","reverse":"armory_reverse_scroll","rebirth":"armory_rebirth_scroll","element":"armory_element_scroll"}.get(mode,"")
static func scroll_item(w: Dictionary,mode: String) -> int:
	var recipe=scroll_recipe(mode);var locked=w.get("rpg",{}).get("locked",[])
	for item in w.get("kingdom",{}).get("industry",{}).get("items",[]):
		if item.recipe==recipe and not int(item.id) in locked:return int(item.id)
	return 0
static func attempt(w: Dictionary,id: int,mode: String,serial: int,element: String="none") -> Dictionary:
	ensure(w)
	if not w.has("armory") or serial!=int(w.armory.serial):return {}
	var q=quote(w,id,mode,element);var K=load("res://scripts/kingdom.gd")
	if q.is_empty() or int(q.scroll_id)==0 or not K.afford(w,q.cost) or K.count(w,"forge")==0:return {}
	var industry=load("res://scripts/industry.gd");var scroll=industry.item(w,int(q.scroll_id))
	var rng=RandomNumberGenerator.new();rng.state=int(w.armory.rng);var roll=rng.randi_range(1,10000)
	K.spend(w,q.cost);w.armory.rng=str(rng.state);w.armory.serial+=1
	w.kingdom.industry.items.erase(scroll)
	var success=roll<=int(q.chance_bp)
	if success:w.armory.items[str(id)]=q.after
	var result={"serial":int(w.armory.serial),"item":id,"mode":mode,"success":success,"chance_bp":int(q.chance_bp),"roll":roll}
	w.armory.history.append(result)
	if w.armory.history.size()>24:w.armory.history.pop_front()
	return result
static func remove(w: Dictionary,id: int) -> void:
	if w.has("armory"):w.armory.items.erase(str(id))
static func defeated(w: Dictionary,e: Dictionary) -> void:
	if not w.has("armory") or w.get("_read_only",false):return
	w.armory.kills[e.kind]=mini(100000,int(w.armory.kills.get(e.kind,0))+1)
	var r=w.kingdom.adventure.run;var rng=RandomNumberGenerator.new();rng.state=int(w.armory.rng)
	var boss=e.kind in ["thornheart","ruin_sentinel","sunward_warden"]
	var chance=10000 if boss else 2500
	var roll=rng.randi_range(1,10000);w.armory.rng=str(rng.state)
	if roll>chance or r.loot.size()>=19:return
	var cls=w.kingdom.adventure.hero.get("class","warrior");var recipe=("legend_" if boss else "high_")+cls+"_weapon"
	load("res://scripts/adventure.gd").drop(r,50000+int(e.id),Vector2(clampf(e.x-22,0,960),clampf(e.y,0,1440)),"",1,recipe)
static func contracts() -> Dictionary:
	return {"hunt":{"title":["Forest Patrol","Orman Devriyesi"],"target":2,"rewards":{"gold":3,"iron":2}},"guardian":{"title":["A Guardian's Legacy","Muhafızın Mirası"],"target":1,"rewards":{"gold":6,"iron":4}},"craft":{"title":["The Smith's Apprentice","Demircinin Çırağı"],"target":1,"rewards":{"gold":3,"iron":3}},"refine":{"title":["The First Spark","İlk Kıvılcım"],"target":1,"rewards":{"gold":2,"iron":2}}}
static func progress(w: Dictionary,key: String) -> int:
	if not w.has("armory"):return 0
	match key:
		"hunt":return int(w.armory.kills.get("wolf",0))+int(w.armory.kills.get("thorn",0))
		"guardian":return int(w.armory.kills.get("thornheart",0))+int(w.armory.kills.get("ruin_sentinel",0))+int(w.armory.kills.get("sunward_warden",0))
		"craft":return mini(1,int(w.get("kingdom",{}).get("events",{}).get("craft_iron_sword",0))/1000)
		"refine":return 1 if not w.armory.items.is_empty() else 0
	return 0
static func claim(w: Dictionary,key: String) -> bool:
	var R=load("res://scripts/rpg_progression.gd")
	if not R.home(w) or not w.has("armory") or not contracts().has(key) or key in w.armory.claims or progress(w,key)<int(contracts()[key].target):return false
	var rewards=contracts()[key].rewards;var K=load("res://scripts/kingdom.gd")
	for resource in rewards:
		if int(w.kingdom.stock[resource])+int(rewards[resource])*1000>roundi(K.storage(w)*1000):return false
	for resource in rewards:w.kingdom.stock[resource]+=int(rewards[resource])*1000
	w.armory.claims.append(key);return true
static func glow(w: Dictionary,id: int) -> Dictionary:
	var s=state(w,id);var n=int(s.rebirth)
	var level=4 if n>=21 else 3 if n>=11 else 2 if n>=5 else 1 if n>0 else clampi(int(s.normal)-6,0,4)
	var strength=[0.0,.3,.55,.8,1.0][level] if n>0 else [0.0,.16,.36,.65,1.0][level]
	var colors={"none":Color("f5d088"),"fire":Color("ff9251"),"frost":Color("88ddff"),"lightning":Color("d9a0ff"),"poison":Color("8ae99e")}
	return {"strength":strength,"color":colors[s.element],"level":level,"element":s.element}
static func validate(w: Dictionary) -> bool:
	if not w.has("armory"):return true
	var C=load("res://scripts/planet_showcase.gd");var a=w.armory
	if not C.shape(a,["version","items","rng","serial","history","kills","claims"]) or a.version!=1 or not a.rng is String or not a.rng.is_valid_int() or not C.number(a.serial,0,1000000,true):return false
	if not a.items is Dictionary or a.items.size()>32 or not a.history is Array or a.history.size()>24 or not a.kills is Dictionary or a.kills.size()>16 or not a.claims is Array or a.claims.size()>4:return false
	for key in a.items:
		if not key is String or not key.is_valid_int() or not eligible(w,int(key)):return false
		var s=a.items[key]
		if not C.shape(s,["normal","rebirth","element"]) or not C.number(s.normal,0,10,true) or not C.number(s.rebirth,0,21,true) or not s.element in rules().elements:return false
		if s.element!="none":
			var item=load("res://scripts/industry.gd").item(w,int(key))
			if load("res://scripts/industry.gd").recipes()[item.recipe].category!="weapon":return false
		if s.rebirth>0:
			var item=load("res://scripts/industry.gd").item(w,int(key));var category=load("res://scripts/industry.gd").recipes()[item.recipe].category
			if not grade(item.recipe) in ["high","unique"] or not category in ["weapon","shield","armor","head","legs","hands","feet"] or s.normal<7 or s.rebirth<int(rules().reverse_map[str(int(s.normal))]):return false
	for h in a.history:
		if not C.shape(h,["serial","item","mode","success","chance_bp","roll"]) or not C.number(h.serial,1,a.serial,true) or not C.number(h.item,1,100000,true) or not h.mode in ["normal","reverse","rebirth","element"] or not h.success is bool or not C.number(h.chance_bp,1,10000,true) or not C.number(h.roll,1,10000,true) or h.success!=(h.roll<=h.chance_bp):return false
	for key in a.kills:
		if not load("res://scripts/adventure.gd").enemies().has(key) or not C.number(a.kills[key],0,100000,true):return false
	var seen=[]
	for key in a.claims:
		if not key in ["hunt","guardian","craft","refine"] or key in seen:return false
		seen.append(key)
	return true
static func normalize(w: Dictionary):
	if not w.has("armory"):return
	w.armory.version=int(w.armory.version);w.armory.serial=int(w.armory.serial)
	for key in w.armory.items:
		for field in ["normal","rebirth"]:w.armory.items[key][field]=int(w.armory.items[key][field])
	for h in w.armory.history:
		for key in ["serial","item","chance_bp","roll"]:h[key]=int(h[key])
	for key in w.armory.kills:w.armory.kills[key]=int(w.armory.kills[key])
