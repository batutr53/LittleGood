extends RefCounted

# Optional private-save extension. The existing civilization remains the food/population authority.
const PLAYABLE_LEVEL_CAP=5
const SCALE=1000
const MAX_BUILDINGS=16
const MAX_WORKERS=12
const RESOURCES=["wood","stone","gold"]
static var building_data: Dictionary={}
static var quest_data: Array=[]
static func buildings() -> Dictionary:
	if building_data.is_empty():
		for b in JSON.parse_string(FileAccess.get_file_as_string("res://assets/kingdom/buildings.json")):building_data[b.id]=b
	return building_data
static func quests() -> Array:
	if quest_data.is_empty():quest_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/kingdom/quests.json"))
	return quest_data
static func writable(w: Dictionary) -> bool:return w.has("kingdom") and not w.get("_read_only",false)
static func normalize(w: Dictionary) -> void:
	if not w.has("kingdom"):return
	for key in ["version","xp","next_worker","next_building","last_tick","gather_at","legacy_capacity","stability"]:w.kingdom[key]=int(w.kingdom[key])
	for worker in w.kingdom.workers:
		worker.id=int(worker.id);worker.building=int(worker.building);worker.skill=int(worker.skill)
	for b in w.kingdom.buildings:
		for key in ["id","cell","level","progress","required"]:b[key]=int(b[key])
	for h in w.kingdom.history:h.tick=int(h.tick)
	for key in w.kingdom.stock:w.kingdom.stock[key]=int(w.kingdom.stock[key])
	for key in w.kingdom.events:w.kingdom.events[key]=int(w.kingdom.events[key])
static func home(w: Dictionary) -> Dictionary:return w.settlements[0]
static func enable(w: Dictionary) -> bool:
	if w.get("_read_only",false) or w.has("kingdom") or w.settlements.is_empty():return false
	w.kingdom={"version":1,"xp":0,"stock":{"wood":0,"stone":12000,"gold":8000},"workers":[],"buildings":[],"claimed":[],"events":{},"history":[],"next_worker":1,"next_building":1,"last_tick":int(w.tick),"gather_at":int(w.tick)-4,"stability":900,"legacy_capacity":maxi(5,ceili(home(w).population)),"advisor":true}
	for i in range(mini(3,floori(home(w).population))):add_worker(w)
	record(w,"founding","Arin")
	return true
static func add_worker(w: Dictionary) -> void:
	var k=w.kingdom;var id=int(k.next_worker);k.next_worker=id+1
	var names=["Nara","Ivo","Tala","Mira","Arda","Sera","Oren","Lale","Eren","Dara","Nuri","Ayla"]
	k.workers.append({"id":id,"name":names[(id-1+absi(int(w.seed)))%names.size()],"building":0,"skill":1000})
static func level(w: Dictionary) -> int:
	if not w.has("kingdom"):return 1
	var n=1
	while n<PLAYABLE_LEVEL_CAP and int(w.kingdom.xp)>=20*n*(n+1):n+=1
	return n
static func ready(b: Dictionary) -> bool:return float(b.progress)>=float(b.required)
static func count(w: Dictionary,kind: String) -> int:
	return w.kingdom.buildings.filter(func(b):return b.kind==kind and (ready(b) or int(b.level)>1)).size() if w.has("kingdom") else 0
static func capacity(w: Dictionary) -> int:
	var total=int(w.kingdom.legacy_capacity)
	for b in w.kingdom.buildings:
		if b.kind=="house":total+=3*(int(b.level) if ready(b) else maxi(0,int(b.level)-1))
	return mini(80,total)
static func storage(w: Dictionary) -> float:
	var total=60.0
	for b in w.kingdom.buildings:
		if b.kind=="storage":total+=80*(int(b.level) if ready(b) else maxi(0,int(b.level)-1))
	return total
static func assigned(w: Dictionary,id: int) -> Array:return w.kingdom.workers.filter(func(c):return int(c.building)==id)
static func tier(w: Dictionary) -> int:
	if not w.has("kingdom"):return 1
	return 2 if count(w,"townhall")>0 and count(w,"house")>0 and count(w,"farm")>0 and count(w,"lumber")>0 and w.kingdom.workers.size()>=4 and home(w).population>=6 and home(w).food>=8 and w.kingdom.stability>=600 else 1
static func event(w: Dictionary,key: String,amount: float=1) -> void:
	if not writable(w):return
	w.kingdom.events[key]=mini(1000000000,int(w.kingdom.events.get(key,0))+maxi(0,roundi(amount*SCALE)))
static func observe_settlers(w: Dictionary,cell: int) -> bool:
	if not writable(w) or int(home(w).cell)!=cell:return false
	event(w,"observe_settlement");return true
static func record(w: Dictionary,key: String,subject: String) -> void:
	w.kingdom.history.append({"tick":int(w.tick),"key":key,"subject":subject})
	if w.kingdom.history.size()>30:w.kingdom.history.pop_front()
static func afford(w: Dictionary,cost: Dictionary) -> bool:
	for key in cost:
		if int(w.kingdom.stock.get(key,0))<roundi(float(cost[key])*SCALE):return false
	return true
static func spend(w: Dictionary,cost: Dictionary) -> void:
	for key in cost:w.kingdom.stock[key]=int(w.kingdom.stock[key])-roundi(float(cost[key])*SCALE)
static func valid_site(w: Dictionary,kind: String,cell: int,ignore: int=0) -> bool:
	if not writable(w) or not buildings().has(kind) or cell<0 or cell>=w.cells.size():return false
	if w.settlements.any(func(s):return int(s.cell)==cell):return false
	for p in w.get("wardrobe",{}).get("placements",[]):
		if int(p.cell)==cell:return false
	for b in w.kingdom.buildings:
		if int(b.cell)==cell and int(b.id)!=ignore:return false
	var c=w.cells[cell];var site=buildings()[kind].site
	var capital=w.cells[int(home(w).cell)]
	if Vector2(c.x-capital.x,c.y-capital.y).length()>5.5:return false
	return int(c.biome)==1 if site=="forest" else int(c.biome) in [0,1,5] if site=="fertile" else int(c.biome) in [0,1,2,5]
static func begin_build(w: Dictionary,kind: String,cell: int) -> int:
	if not writable(w) or not buildings().has(kind):return -1
	var data=buildings()[kind]
	if level(w)<int(data.level) or w.kingdom.buildings.size()>=MAX_BUILDINGS or w.kingdom.buildings.filter(func(b):return b.kind==kind).size()>=int(data.limit) or not valid_site(w,kind,cell) or not afford(w,data.cost):return -1
	spend(w,data.cost)
	var id=int(w.kingdom.next_building);w.kingdom.next_building=id+1
	w.kingdom.buildings.append({"id":id,"kind":kind,"cell":cell,"level":1,"progress":0,"required":int(data.ticks)*SCALE})
	record(w,"construction",kind)
	return id
static func upgrade_cost(b: Dictionary) -> Dictionary:
	var result=buildings()[b.kind].cost.duplicate()
	for key in result:result[key]*=int(b.level)+1
	return result
static func upgrade(w: Dictionary,id: int) -> bool:
	if not writable(w):return false
	for b in w.kingdom.buildings:
		if int(b.id)==id and ready(b) and int(b.level)<3 and afford(w,upgrade_cost(b)):
			spend(w,upgrade_cost(b));b.level=int(b.level)+1;b.progress=0;b.required=int(buildings()[b.kind].ticks)*int(b.level)*SCALE;record(w,"upgrade",b.kind);return true
	return false
static func move(w: Dictionary,id: int,cell: int) -> bool:
	if not writable(w):return false
	for b in w.kingdom.buildings:
		if int(b.id)==id and valid_site(w,b.kind,cell,id):b.cell=cell;return true
	return false
static func assign(w: Dictionary,worker: int,building: int) -> bool:
	if not writable(w):return false
	if building!=0:
		var match_build=w.kingdom.buildings.filter(func(b):return int(b.id)==building and ready(b))
		if match_build.is_empty() or assigned(w,building).size()>=int(buildings()[match_build[0].kind].slots):return false
	for c in w.kingdom.workers:
		if int(c.id)==worker:c.building=building;return true
	return false
static func recruit(w: Dictionary) -> bool:
	if not writable(w) or level(w)<4 or w.kingdom.workers.size()>=MAX_WORKERS or home(w).food<4 or w.kingdom.stability<600 or not afford(w,{"gold":1}):return false
	var needs_room=w.kingdom.workers.size()>=floori(home(w).population)
	if needs_room and home(w).population+1>capacity(w):return false
	if needs_room:home(w).population+=1
	home(w).food-=2;spend(w,{"gold":1});add_worker(w);event(w,"recruit");record(w,"recruit",w.kingdom.workers[-1].name)
	return true
static func gather(w: Dictionary,resource: String,cell: int) -> float:
	if not writable(w) or not resource in ["wood","stone"] or cell<0 or cell>=w.cells.size() or int(w.tick)<int(w.kingdom.gather_at)+4:return 0
	var c=w.cells[cell]
	if (resource=="wood" and int(c.biome)!=1) or (resource=="stone" and not int(c.biome) in [3,4]):return 0
	var amount=minf(3,minf(float(c.resources),maxf(0,storage(w)-w.kingdom.stock[resource]/float(SCALE))))
	amount=floori(amount*SCALE)/float(SCALE)
	if amount<=0:return 0
	c.resources-=amount;w.kingdom.stock[resource]+=roundi(amount*SCALE);w.kingdom.gather_at=int(w.tick);event(w,"gather_"+resource,amount)
	return amount
static func productivity(w: Dictionary,b: Dictionary) -> float:
	if not ready(b):return 0
	var data=buildings()[b.kind]
	if data.output.is_empty():return 0
	var c=w.cells[int(b.cell)];var environment=0.0
	if b.kind=="lumber" and int(c.biome)==1:environment=maxf(.2,c.plants)
	elif b.kind=="farm" and int(c.biome) in [0,1,5]:environment=c.moisture*(.65 if int(c.biome)==1 else 1.0)
	var skill=0.0
	for worker in assigned(w,int(b.id)):skill+=float(worker.skill)/SCALE
	return .45*int(b.level)*skill*float(w.kingdom.stability)/SCALE*environment
static func tick(w: Dictionary) -> void:
	if not writable(w) or int(w.kingdom.last_tick)>=int(w.tick):return
	var k=w.kingdom;k.last_tick=int(w.tick)
	k.stability=clampi(int(k.stability)+(2 if home(w).food>5 else -5),550,1000)
	home(w).food=maxf(0,home(w).food-k.workers.size()*.025)
	var labor=assigned(w,0).size()*int(k.stability)
	for b in k.buildings:
		if not ready(b):
			var used=mini(labor,int(b.required)-int(b.progress));b.progress+=used;labor-=used
			if ready(b):event(w,"build_"+b.kind);record(w,"built",b.kind)
			continue
		var data=buildings()[b.kind];var c=w.cells[int(b.cell)];var amount=productivity(w,b)
		var space=maxf(0,100-home(w).food) if data.output=="food" else maxf(0,storage(w)-float(k.stock.get(data.output,0))/SCALE)
		amount=floori(minf(amount,minf(c.resources,space))*SCALE)/float(SCALE)
		if amount<=0:continue
		c.resources-=amount
		if data.output=="food":home(w).food+=amount
		else:k.stock[data.output]+=roundi(amount*SCALE)
		event(w,"produce_"+data.output,amount)
		for worker in assigned(w,int(b.id)):worker.skill=mini(1500,int(worker.skill)+1)
static func current(w: Dictionary) -> Dictionary:
	if not w.has("kingdom"):return {}
	for q in quests():
		if not w.kingdom.claimed.has(q.id):return q
	return {}
static func progress(w: Dictionary,o: Dictionary) -> float:
	match o.kind:
		"event":return float(w.kingdom.events.get(o.key,0))/SCALE
		"building":return count(w,o.key)
		"tier":return tier(w)
	return 0
static func complete(w: Dictionary,q: Dictionary) -> bool:
	for prerequisite in q.prerequisites:
		if not w.kingdom.claimed.has(prerequisite):return false
	return q.objectives.all(func(o):return progress(w,o)>=float(o.target))
static func claim(w: Dictionary,id: String) -> bool:
	if not writable(w):return false
	var q=current(w)
	if q.is_empty() or q.id!=id or level(w)<int(q.level) or not complete(w,q):return false
	w.kingdom.claimed.append(id);w.kingdom.xp+=int(q.rewards.xp)
	for key in RESOURCES:w.kingdom.stock[key]+=roundi(float(q.rewards.get(key,0))*SCALE)
	record(w,"quest",id)
	return true
static func validate(w: Dictionary) -> bool:
	if not w.has("kingdom"):return true
	var k=w.kingdom;var fields=["version","xp","stock","workers","buildings","claimed","events","history","next_worker","next_building","last_tick","gather_at","stability","legacy_capacity","advisor"]
	var C=preload("res://scripts/cosmetics.gd")
	if not C.shape(k,fields) or not C.number(k.version,1,1,true) or not C.number(k.xp,0,100000,true) or not C.number(k.stability,550,1000,true) or not k.advisor is bool:return false
	if not C.shape(k.stock,RESOURCES):return false
	for key in RESOURCES:
		if not C.number(k.stock[key],0,10000000,true):return false
	for key in ["next_worker","next_building"]:
		if not C.number(k[key],1,1000000,true):return false
	if not C.number(k.legacy_capacity,5,80,true) or not C.number(k.last_tick,0,w.tick,true) or not C.number(k.gather_at,-4,w.tick,true):return false
	if not k.workers is Array or k.workers.size()>MAX_WORKERS or not k.buildings is Array or k.buildings.size()>MAX_BUILDINGS or not k.claimed is Array or k.claimed.size()>quests().size():return false
	if w.settlements.is_empty() or k.workers.size()>floori(home(w).population):return false
	var ids: Dictionary={};var cells: Dictionary={}
	for b in k.buildings:
		if not C.shape(b,["id","kind","cell","level","progress","required"]) or not C.number(b.id,1,k.next_building-1,true) or ids.has(int(b.id)) or not b.kind is String or not buildings().has(b.kind) or not C.number(b.cell,0,w.cells.size()-1,true) or cells.has(int(b.cell)) or not C.number(b.level,1,3,true):return false
		if not C.number(b.required,1,100000,true) or not C.number(b.progress,0,b.required,true):return false
		ids[int(b.id)]=b;cells[int(b.cell)]=true
	for kind in buildings():
		if k.buildings.filter(func(b):return b.kind==kind).size()>int(buildings()[kind].limit):return false
	var workers: Dictionary={};var occupied: Dictionary={}
	for c in k.workers:
		if not C.shape(c,["id","name","building","skill"]) or not C.number(c.id,1,k.next_worker-1,true) or workers.has(int(c.id)) or not c.name is String or c.name.length()>24 or not C.number(c.skill,1000,1500,true) or not C.number(c.building,0,k.next_building-1,true):return false
		if c.building!=0:
			if not ids.has(int(c.building)):return false
			occupied[int(c.building)]=occupied.get(int(c.building),0)+1
			if occupied[int(c.building)]>int(buildings()[ids[int(c.building)].kind].slots):return false
		workers[int(c.id)]=true
	var xp=0
	for i in range(k.claimed.size()):
		if not k.claimed[i] is String or k.claimed[i]!=quests()[i].id:return false
		xp+=int(quests()[i].rewards.xp)
	if k.xp!=xp or not k.events is Dictionary or k.events.size()>24:return false
	var event_keys=["observe_settlement","gather_wood","gather_stone","recruit","produce_wood","produce_food"]
	for key in buildings():event_keys.append("build_"+key)
	for key in k.events:
		if not event_keys.has(key) or not C.number(k.events[key],0,1000000000,true):return false
	if not k.history is Array or k.history.size()>30:return false
	for h in k.history:
		if not C.shape(h,["tick","key","subject"]) or not C.number(h.tick,0,w.tick,true) or not h.key in ["founding","construction","built","upgrade","recruit","quest"] or not h.subject is String or h.subject.length()>32:return false
	return true
