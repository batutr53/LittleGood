extends RefCounted
# Private, versioned land ownership. Cell indices are append-only, including migration.
const CHUNK=8
const MAX_CELLS=2304
static func enabled(w: Dictionary) -> bool:return w.has("estate") and not w.get("_read_only",false)
static func initial_plots() -> Array:
	var plots=[]
	for y in range(-1,3):
		for x in range(-1,3):plots.append([x,y])
	return plots
static func start(w: Dictionary) -> void:
	if w.has("estate") or w.get("_read_only",false):return
	w.estate={"version":1,"plots":initial_plots(),"pending":{},"completed":{},"craft_ready":[]}
	for b in w.get("kingdom",{}).get("buildings",[]):
		if int(b.progress)>=int(b.required):w.estate.completed[str(int(b.id))]=int(b.level)
	for plot in w.estate.plots:append_plot(w,Vector2i(plot[0],plot[1]))
static func append_plot(w: Dictionary,plot: Vector2i) -> void:
	var occupied={}
	for c in w.cells:occupied[Vector2i(c.x,c.y)]=true
	var noise=FastNoiseLite.new();noise.seed=int(w.seed);noise.frequency=.075
	for y in range(plot.y*CHUNK,(plot.y+1)*CHUNK):
		for x in range(plot.x*CHUNK,(plot.x+1)*CHUNK):
			if occupied.has(Vector2i(x,y)):continue
			var moisture=clampf(.55+noise.get_noise_2d(x+70,y+50),.1,.95)
			var detail=absf(sin(x*127.1+y*311.7+int(w.seed)*.001))
			var biome=1 if moisture>.6 else 0
			if x<0:biome=2
			elif y<0:biome=4 if x>8 else 3
			elif y>19:biome=5
			if absf(x-8.0-sin(y*.6)*1.8)<.8:biome=6
			w.cells.append({"x":x,"y":y,"biome":biome,"height":clampf(.2+noise.get_noise_2d(x,y)*.25,.02,.5),"moisture":moisture,"plants":.45+detail*.45,"resources":15.0,"temperature":clampf(25-y*1.2,-25,35),"detail":detail})
static func candidates(w: Dictionary) -> Array:
	if not enabled(w):return []
	var owned={};var result={}
	for p in w.estate.plots:owned[Vector2i(p[0],p[1])]=true
	for p in owned:
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var q=p+d
			if q.x>=-2 and q.x<=3 and q.y>=-2 and q.y<=3 and not owned.has(q):result[q]=true
	return result.keys()
static func cost(w: Dictionary) -> Dictionary:
	var n=w.estate.plots.size()-16
	return {} if n==0 else {"wood":4+n*2,"stone":2+n,"gold":2+n}
static func expand(w: Dictionary,plot: Vector2i) -> bool:
	if not enabled(w) or not w.has("kingdom") or not candidates(w).has(plot):return false
	if w.kingdom.get("adventure",{}).get("run",{}).get("active",false) or w.kingdom.get("military",{}).get("battle",{}).get("active",false):return false
	var k=load("res://scripts/kingdom.gd");var price=cost(w)
	if not k.afford(w,price):return false
	k.spend(w,price);w.estate.plots.append([plot.x,plot.y]);append_plot(w,plot)
	return true
static func room(w: Dictionary,b: Dictionary) -> float:
	var pending=w.estate.pending.get(str(int(b.id)),{})
	var amount=0
	for value in pending.values():amount+=int(value)
	return maxf(0,20.0*int(b.level)-amount/1000.0)
static func deposit(w: Dictionary,b: Dictionary,key: String,amount: int) -> void:
	var id=str(int(b.id))
	if not w.estate.pending.has(id):w.estate.pending[id]={}
	w.estate.pending[id][key]=int(w.estate.pending[id].get(key,0))+amount
static func status(w: Dictionary,b: Dictionary) -> String:
	if not enabled(w):return ""
	if w.get("kingdom",{}).has("industry"):
		for job in w.kingdom.industry.queue:
			if int(job.building)==int(b.id) and w.estate.craft_ready.has(int(job.id)):return "crafted"
	if not w.estate.pending.get(str(int(b.id)),{}).is_empty():return "harvest"
	if int(b.progress)>=int(b.required) and int(w.estate.completed.get(str(int(b.id)),0))<int(b.level):return "built"
	return ""
static func collect(w: Dictionary,id: int) -> Dictionary:
	if not enabled(w) or not w.has("kingdom"):return {}
	if w.kingdom.get("adventure",{}).get("run",{}).get("active",false) or w.kingdom.get("military",{}).get("battle",{}).get("active",false):return {}
	var k=load("res://scripts/kingdom.gd");var found=w.kingdom.buildings.filter(func(b):return int(b.id)==id)
	if found.is_empty():return {}
	var b=found[0];var key=str(id);var result={};var pending=w.estate.pending.get(key,{})
	if w.kingdom.has("industry"):
		for job in w.kingdom.industry.queue.duplicate():
			if int(job.building)!=id or not w.estate.craft_ready.has(int(job.id)):continue
			# Queued items reserve capacity, but never append over an occupied/invalid slot.
			if w.kingdom.industry.items.size()>=load("res://scripts/industry.gd").MAX_ITEMS or w.kingdom.industry.items.any(func(item):return int(item.id)==int(job.id)):continue
			w.kingdom.industry.items.append({"id":int(job.id),"recipe":job.recipe});w.kingdom.industry.queue.erase(job);w.estate.craft_ready.erase(int(job.id))
			k.event(w,"craft_"+job.recipe);k.record(w,"craft",job.recipe);result["crafted"]=int(result.get("crafted",0))+1
	for resource in pending.keys():
		if resource!="food" and not w.kingdom.stock.has(resource):continue
		var space=maxf(0,100-k.home(w).food) if resource=="food" else maxf(0,k.storage(w)-int(w.kingdom.stock.get(resource,0))/1000.0)
		var amount=mini(int(pending[resource]),floori(space*1000))
		if amount<=0:continue
		if resource=="food":k.home(w).food+=amount/1000.0
		else:w.kingdom.stock[resource]=int(w.kingdom.stock.get(resource,0))+amount
		pending[resource]=int(pending[resource])-amount;result[resource]=amount
		k.event(w,"produce_"+resource,amount/1000.0)
		if int(pending[resource])==0:pending.erase(resource)
	if pending.is_empty():w.estate.pending.erase(key)
	if int(b.progress)>=int(b.required) and int(w.estate.completed.get(key,0))<int(b.level):
		w.estate.completed[key]=int(b.level);result["built"]=1
	return result
static func collection_state(w: Dictionary,id: int) -> Dictionary:
	var report={"code":"unavailable","pending":{},"space":{},"items":0,"built":false}
	if not enabled(w) or not w.has("kingdom"):return report
	if w.kingdom.get("adventure",{}).get("run",{}).get("active",false) or w.kingdom.get("military",{}).get("battle",{}).get("active",false):report.code="expedition";return report
	var found=w.kingdom.buildings.filter(func(b):return int(b.id)==id)
	if found.is_empty():return report
	var b=found[0];var K=load("res://scripts/kingdom.gd");report.pending=w.estate.pending.get(str(id),{}).duplicate();var possible=false
	for key in report.pending:
		var room=maxf(0,100-K.home(w).food) if key=="food" else maxf(0,K.storage(w)-int(w.kingdom.stock.get(key,0))/1000.0)
		report.space[key]=floori(room*1000)
		if mini(int(report.pending[key]),int(report.space[key]))>0:possible=true
	if w.kingdom.has("industry"):
		for job in w.kingdom.industry.queue:
			if int(job.building)==id and w.estate.craft_ready.has(int(job.id)):report.items+=1
	if report.items>0 and w.kingdom.industry.items.size()<load("res://scripts/industry.gd").MAX_ITEMS:possible=true
	report.built=K.ready(b) and int(w.estate.completed.get(str(id),0))<int(b.level)
	if report.built:possible=true
	report.code="ready" if possible else "full" if not report.pending.is_empty() or report.items>0 else "running" if not K.ready(b) or K.activity_rate(w,b)>0 else "empty"
	return report
static func validate(w: Dictionary) -> bool:
	if not w.has("estate"):return true
	var c=load("res://scripts/planet_showcase.gd");var e=w.estate
	if not c.shape(e,["version","plots","pending","completed","craft_ready"]) or e.version!=1 or not e.plots is Array or e.plots.size()<16 or e.plots.size()>36:return false
	if not e.craft_ready is Array or e.craft_ready.size()>4:return false
	var seen_jobs={}
	for id in e.craft_ready:
		if not c.number(id,1,100000,true) or seen_jobs.has(int(id)):return false
		seen_jobs[int(id)]=true
		var jobs=w.get("kingdom",{}).get("industry",{}).get("queue",[]).filter(func(job):return int(job.id)==int(id))
		if jobs.is_empty() or int(jobs[0].progress)!=int(load("res://scripts/industry.gd").recipes()[jobs[0].recipe].ticks)*1000-1:return false
	if not e.pending is Dictionary or not e.completed is Dictionary or e.pending.size()>25 or e.completed.size()>25:return false
	var owned={}
	var index=0
	for p in e.plots:
		if not p is Array or p.size()!=2 or not c.number(p[0],-2,3,true) or not c.number(p[1],-2,3,true):return false
		var q=Vector2i(p[0],p[1])
		if owned.has(q):return false
		if index<16:
			var original=initial_plots()[index]
			if q!=Vector2i(original[0],original[1]):return false
		if owned.size()>=16 and not [q+Vector2i.LEFT,q+Vector2i.RIGHT,q+Vector2i.UP,q+Vector2i.DOWN].any(func(n):return owned.has(n)):return false
		owned[q]=true
		index+=1
	for p in initial_plots():
		if not owned.has(Vector2i(p[0],p[1])):return false
	if w.cells.size()!=owned.size()*64:return false
	var positions={}
	for cell in w.cells:
		if not c.number(cell.x,-16,31,true) or not c.number(cell.y,-16,31,true):return false
		var q=Vector2i(cell.x,cell.y)
		if positions.has(q) or not owned.has(Vector2i(floori(cell.x/8.0),floori(cell.y/8.0))):return false
		positions[q]=true
	var buildings={}
	for b in w.get("kingdom",{}).get("buildings",[]):buildings[str(int(b.id))]=b
	for key in e.pending:
		if not buildings.has(key) or not e.pending[key] is Dictionary or e.pending[key].is_empty():return false
		var total=0;var output=load("res://scripts/kingdom.gd").buildings()[buildings[key].kind].output
		for resource in e.pending[key]:
			if resource!=output or not c.number(e.pending[key][resource],1,20000*int(buildings[key].level),true):return false
			total+=int(e.pending[key][resource])
		if total>20000*int(buildings[key].level):return false
	for key in e.completed:
		if not buildings.has(key) or not c.number(e.completed[key],1,int(buildings[key].level),true):return false
	return true
static func normalize(w: Dictionary) -> void:
	if not w.has("estate"):return
	w.estate.version=int(w.estate.version)
	for i in range(w.estate.craft_ready.size()):w.estate.craft_ready[i]=int(w.estate.craft_ready[i])
	for plot in w.estate.plots:plot[0]=int(plot[0]);plot[1]=int(plot[1])
	for key in w.estate.completed:w.estate.completed[key]=int(w.estate.completed[key])
	for id in w.estate.pending:
		for resource in w.estate.pending[id]:w.estate.pending[id][resource]=int(w.estate.pending[id][resource])
