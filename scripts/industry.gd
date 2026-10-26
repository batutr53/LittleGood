extends RefCounted

# Optional, private chapter-II extension. Kingdom owns common resources and the simulation clock.
const SCALE=1000
const EXTRA_RESOURCES=["ore","iron"]
const MAX_ITEMS=32
const MAX_QUEUE=4
static var recipe_data: Dictionary={}
static func recipes() -> Dictionary:
	if recipe_data.is_empty():
		for data in JSON.parse_string(FileAccess.get_file_as_string("res://assets/kingdom/recipes.json")):recipe_data[data.id]=data
		if FileAccess.file_exists("res://assets/rpg/equipment.json"):
			for data in JSON.parse_string(FileAccess.get_file_as_string("res://assets/rpg/equipment.json")):recipe_data[data.id]=data
		for data in JSON.parse_string(FileAccess.get_file_as_string("res://assets/rpg/armory-equipment.json")):recipe_data[data.id]=data
	return recipe_data
static func effects(w: Dictionary,owned: Dictionary) -> Dictionary:return load("res://scripts/armory.gd").effects(w,owned)
static func enabled(w: Dictionary) -> bool:return w.has("kingdom") and int(w.kingdom.get("version",1)) in [2,3]
static func writable(w: Dictionary) -> bool:return enabled(w) and not w.get("_read_only",false)
static func enable(w: Dictionary) -> bool:
	if w.get("_read_only",false) or not w.has("kingdom") or enabled(w) or w.kingdom.claimed.size()<5:return false
	w.kingdom.version=2
	for key in EXTRA_RESOURCES:w.kingdom.stock[key]=0
	w.kingdom.industry={"version":1,"next_item":1,"last_tick":int(w.tick),"items":[],"queue":[],"equipped":[]}
	return true
static func normalize(w: Dictionary) -> void:
	if not enabled(w):return
	var state=w.kingdom.industry;state.version=int(state.version);state.next_item=int(state.next_item)
	state.last_tick=int(state.last_tick)
	for item in state.items:item.id=int(item.id)
	for job in state.queue:
		for key in ["id","building","progress"]:job[key]=int(job[key])
	for slot in state.equipped:slot.worker=int(slot.worker);slot.item=int(slot.item)
static func item(w: Dictionary,id: int) -> Dictionary:
	if not enabled(w):return {}
	for owned in w.kingdom.industry.items:
		if int(owned.id)==id:return owned
	return {}
static func tool(w: Dictionary,worker: int) -> Dictionary:
	if not enabled(w):return {}
	for slot in w.kingdom.industry.equipped:
		if int(slot.worker)==worker:return item(w,int(slot.item))
	return {}
static func multiplier(w: Dictionary,worker: int,role: String) -> int:
	var owned=tool(w,worker)
	return int(recipes()[owned.recipe].effects.get(role,SCALE)) if not owned.is_empty() else SCALE
static func equip(w: Dictionary,worker: int,id: int) -> bool:
	if not writable(w) or load("res://scripts/military.gd").worker_reserved(w,worker) or not w.kingdom.workers.any(func(c):return int(c.id)==worker):return false
	if id!=0 and item(w,id).is_empty():return false
	if id!=0 and recipes()[item(w,id).recipe].get("category","tool")!="tool":return false
	var state=w.kingdom.industry
	# Moving a tool is explicit and atomic; no item can equip to two citizens.
	state.equipped=state.equipped.filter(func(slot):return int(slot.worker)!=worker and int(slot.item)!=id)
	if id>0:state.equipped.append({"worker":worker,"item":id});event(w,"equip_tool")
	return true
static func event(w: Dictionary,key: String,amount: int=1) -> void:
	w.kingdom.events[key]=mini(1000000000,int(w.kingdom.events.get(key,0))+amount*SCALE)
static func queue(w: Dictionary,recipe: String,building: int) -> bool:
	if not writable(w) or not recipes().has(recipe):return false
	var data=recipes()[recipe];var state=w.kingdom.industry
	if recipe=="sun_relic":return false
	if recipe in load("res://scripts/sanctuary.gd").GEAR and (not load("res://scripts/sanctuary.gd").enabled(w) or not w.kingdom.adventure.regions.ancients.researched):return false
	if recipe=="crystal_tonic" and not load("res://scripts/ashen_desert.gd").can_spend(w,2000):return false
	if data.get("category","tool")!="tool" and int(w.kingdom.version)!=3:return false
	if data.get("category")=="military" and not load("res://scripts/military.gd").enabled(w):return false
	if state.items.size()+state.queue.size()>=MAX_ITEMS or state.queue.size()>=MAX_QUEUE or w.kingdom.claimed.size()+1<int(data.level):return false
	if not w.kingdom.buildings.any(func(b):return int(b.id)==building and b.kind=="forge" and int(b.progress)>=int(b.required)):return false
	for key in data.cost:
		if int(w.kingdom.stock[key])<int(data.cost[key])*SCALE:return false
	for key in data.cost:w.kingdom.stock[key]-=int(data.cost[key])*SCALE
	state.queue.append({"id":int(state.next_item),"recipe":recipe,"building":building,"progress":0});state.next_item+=1
	return true
static func work_rate(w: Dictionary,b: Dictionary) -> int:
	if not enabled(w) or b.kind!="forge" or int(b.progress)<int(b.required) or not w.kingdom.industry.queue.any(func(job):return int(job.building)==int(b.id) and not w.get("estate",{}).get("craft_ready",[]).has(int(job.id))):return 0
	var rate=0
	for c in w.kingdom.workers:
		if int(c.building)==int(b.id):rate+=int(c.skill)
	return int(rate*int(w.kingdom.stability)/float(SCALE))
static func tick(w: Dictionary) -> void:
	if not writable(w):return
	var state=w.kingdom.industry
	if int(state.last_tick)>=int(w.tick):return
	state.last_tick=int(w.tick)
	for b in w.kingdom.buildings:
		var work=work_rate(w,b)
		if work<=0:continue
		for job in state.queue.duplicate():
			if int(job.building)!=int(b.id):continue
			if w.get("estate",{}).get("craft_ready",[]).has(int(job.id)):continue
			var required=int(recipes()[job.recipe].ticks)*SCALE;var used=mini(work,required-int(job.progress));job.progress+=used;work-=used
			if int(job.progress)>=required:
				if w.has("estate"):
					job.progress=required-1;w.estate.craft_ready.append(int(job.id));continue
				state.items.append({"id":int(job.id),"recipe":job.recipe});state.queue.erase(job);event(w,"craft_"+job.recipe)
				w.kingdom.history.append({"tick":int(w.tick),"key":"craft","subject":job.recipe})
				if w.kingdom.history.size()>30:w.kingdom.history.pop_front()
			if work<=0:break
static func validate(w: Dictionary) -> bool:
	if not enabled(w):return true
	var C=preload("res://scripts/cosmetics.gd");var state=w.kingdom.get("industry")
	if not C.shape(state,["version","next_item","last_tick","items","queue","equipped"]) or not C.number(state.version,1,1,true) or not C.number(state.next_item,1,100000,true) or not C.number(state.last_tick,0,w.tick,true):return false
	if not state.items is Array or not state.queue is Array or not state.equipped is Array or state.items.size()+state.queue.size()>MAX_ITEMS or state.queue.size()>MAX_QUEUE or state.equipped.size()>w.kingdom.workers.size():return false
	var owned: Dictionary={};var ids: Dictionary={};var workers: Dictionary={};var equipped: Dictionary={}
	for entry in state.items+state.queue:
		if not entry is Dictionary or not C.number(entry.get("id"),1,state.next_item-1,true) or ids.has(int(entry.id)) or not entry.get("recipe") is String or not recipes().has(entry.recipe):return false
		if recipes()[entry.recipe].get("category")=="military" and (not load("res://scripts/military.gd").enabled(w) or w.kingdom.claimed.size()<16):return false
		if entry.recipe=="crystal_tonic" and not load("res://scripts/ashen_desert.gd").enabled(w):return false
		if (entry.recipe=="sun_relic" or entry.recipe in load("res://scripts/sanctuary.gd").GEAR) and not load("res://scripts/sanctuary.gd").enabled(w):return false
		if entry.recipe in load("res://scripts/sanctuary.gd").GEAR and not w.kingdom.adventure.regions.ancients.researched:return false
		ids[int(entry.id)]=true
	for entry in state.items:
		if not C.shape(entry,["id","recipe"]):return false
		owned[int(entry.id)]=true
	for job in state.queue:
		if job.recipe=="sun_relic":return false
		if not C.shape(job,["id","recipe","building","progress"]) or not C.number(job.building,1,w.kingdom.next_building-1,true) or not C.number(job.progress,0,int(recipes()[job.recipe].ticks)*SCALE-1,true):return false
		if not w.kingdom.buildings.any(func(b):return int(b.id)==int(job.building) and b.kind=="forge"):return false
	for slot in state.equipped:
		if not C.shape(slot,["worker","item"]) or not C.number(slot.worker,1,w.kingdom.next_worker-1,true) or not C.number(slot.item,1,state.next_item-1,true):return false
		if workers.has(int(slot.worker)) or equipped.has(int(slot.item)) or not owned.has(int(slot.item)) or not w.kingdom.workers.any(func(c):return int(c.id)==int(slot.worker)):return false
		if recipes()[item(w,int(slot.item)).recipe].get("category","tool")!="tool":return false
		workers[int(slot.worker)]=true;equipped[int(slot.item)]=true
	return true
