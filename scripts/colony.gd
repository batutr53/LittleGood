extends RefCounted
# Optional private-save extension. Existing citizens remain authoritative worker IDs.
const RESOURCES=["wood","stone","gold","copper","silver","clay","water","fish"]
const LOCAL=["copper","silver","clay","water","fish"]
const NAMES={"wood":["Wood","Odun"],"stone":["Stone","Taş"],"gold":["Gold","Altın"],"copper":["Copper","Bakır"],"silver":["Silver","Gümüş"],"clay":["Clay","Kil"],"water":["Water","Su"],"fish":["Fish","Balık"]}
const CYCLE=10
static func K():return load("res://scripts/kingdom.gd")
static func enabled(w):return w.has("colony") and w.has("kingdom")
static func writable(w):return enabled(w) and not w.get("_read_only",false)
static func reserved(w,id):return enabled(w) and w.colony.jobs.has(str(id))
static func ensure(w):
	if w.has("colony") or not w.has("kingdom") or w.get("_read_only",false):return
	var stock={}
	for key in LOCAL:stock[key]=0
	w.colony={"version":1,"last_tick":int(w.tick),"stock":stock,"jobs":{},"spent":{},"fortification":0,"meals":0}
static func source(w,resource):
	var home=w.cells[int(K().home(w).cell)];var nearest=INF;var found=-1
	for i in range(w.cells.size()):
		var c=w.cells[i];var biome=int(c.biome);var fits=biome==1 if resource=="wood" else biome in [3,4] if resource in ["stone","gold","copper","silver"] else biome in [0,5] if resource=="clay" else biome==6
		if not fits or resource in ["wood","stone"] and float(c.resources)<1:continue
		if resource in ["gold","copper","silver","clay"] and int(w.get("colony",{}).get("spent",{}).get(resource+":"+str(i),0))>=12000:continue
		var distance=Vector2(c.x-home.x,c.y-home.y).length()
		if distance<nearest:nearest=distance;found=i
	return found
static func start(w,worker_id,resource):
	if not writable(w) or not resource in RESOURCES or reserved(w,worker_id):return false
	if not K().assigned(w,0).any(func(c):return int(c.id)==worker_id):return false
	var cell=source(w,resource)
	if cell<0:return false
	w.colony.jobs[str(worker_id)]={"resource":resource,"cell":cell,"progress":0,"buffer":0};return true
static func release(w,worker_id):
	if not writable(w) or not reserved(w,worker_id):return false
	if int(w.colony.jobs[str(worker_id)].buffer)>0:return false
	w.colony.jobs.erase(str(worker_id));return true
static func trip_yield(w,id,resource):
	var role={"wood":"lumber","stone":"quarry","gold":"mine","copper":"mine","silver":"mine","clay":"quarry"}.get(resource,"")
	return 2000 if role.is_empty() else roundi(2000*load("res://scripts/industry.gd").multiplier(w,id,role)/1000.0)
static func tick(w):
	if not writable(w) or int(w.colony.last_tick)>=int(w.tick):return
	w.colony.last_tick=int(w.tick)
	if w.kingdom.get("adventure",{}).get("run",{}).get("active",false) or w.kingdom.get("military",{}).get("battle",{}).get("active",false):return
	for id in w.colony.jobs:
		var job=w.colony.jobs[id]
		if int(job.buffer)>=6000:continue
		job.progress+=1
		if job.progress<CYCLE:continue
		job.progress=0;var c=w.cells[int(job.cell)];var resource=str(job.resource);var amount=mini(trip_yield(w,int(id),resource),6000-int(job.buffer))
		if resource in ["wood","stone"]:amount=mini(amount,floori(float(c.resources)*1000));c.resources=maxf(0,float(c.resources)-amount/1000.0)
		elif resource in ["gold","copper","silver","clay"]:
			var key=resource+":"+str(int(job.cell));amount=mini(amount,12000-int(w.colony.spent.get(key,0)));w.colony.spent[key]=int(w.colony.spent.get(key,0))+amount
		if amount<=0:
			var next=source(w,resource)
			if next>=0:job.cell=next
			continue
		job.buffer+=amount
static func collect(w,id):
	if not writable(w) or not reserved(w,id):return 0
	var job=w.colony.jobs[str(id)];var resource=str(job.resource);var amount=int(job.buffer)
	if resource in ["wood","stone","gold"]:
		amount=mini(amount,maxi(0,roundi(K().storage(w)*1000)-int(w.kingdom.stock[resource])));w.kingdom.stock[resource]+=amount
	else:
		amount=mini(amount,maxi(0,60000-int(w.colony.stock[resource])));w.colony.stock[resource]+=amount
	if amount>0 and resource in ["wood","stone"]:K().event(w,"gather_"+resource,amount/1000.0)
	job.buffer-=amount;return amount
static func meal(w):
	if not writable(w) or w.colony.stock.fish<2000 or w.colony.stock.water<1000 or K().home(w).food>96:return false
	w.colony.stock.fish-=2000;w.colony.stock.water-=1000;K().home(w).food+=4;w.colony.meals+=1;return true
static func reinforce(w):
	if not writable(w) or int(w.colony.fortification)>=3 or K().count(w,"watchtower")==0 or K().count(w,"wall")==0:return false
	var n=int(w.colony.fortification)+1
	if w.colony.stock.copper<2000*n or w.colony.stock.clay<2000*n or w.colony.stock.silver<1000*n or not K().afford(w,{"stone":3*n}):return false
	w.colony.stock.copper-=2000*n;w.colony.stock.clay-=2000*n;w.colony.stock.silver-=1000*n;K().spend(w,{"stone":3*n});w.colony.fortification=n;return true
static func task_status(w,job,turkish=true):
	if job.buffer>=6000:return "Yük dolu · topla" if turkish else "Cargo full · collect"
	var n=int(job.progress)
	return ("Kaynağa gidiyor" if n<2 else "Topluyor" if n<8 else "Yükle dönüyor") if turkish else ("Travelling" if n<2 else "Gathering" if n<8 else "Returning with cargo")
static func validate(w):
	if not w.has("colony"):return true
	var C=load("res://scripts/cosmetics.gd");var c=w.colony
	if not w.has("kingdom") or not c is Dictionary or not C.shape(c,["version","last_tick","stock","jobs","spent","fortification","meals"]) or c.version!=1:return false
	if not C.number(c.last_tick,0,w.tick,true) or not C.number(c.fortification,0,3,true) or not C.number(c.meals,0,1000000000,true):return false
	if not c.stock is Dictionary or not C.shape(c.stock,LOCAL) or not c.jobs is Dictionary or c.jobs.size()>12 or not c.spent is Dictionary or c.spent.size()>w.cells.size()*4:return false
	for key in LOCAL:
		if not C.number(c.stock[key],0,60000,true):return false
	for key in c.spent:
		var parts=str(key).split(":")
		if parts.size()!=2 or not parts[0] in ["gold","copper","silver","clay"] or not parts[1].is_valid_int() or int(parts[1])<0 or int(parts[1])>=w.cells.size() or not C.number(c.spent[key],0,12000,true):return false
		if parts[1]!=str(int(parts[1])):return false
		var biome=int(w.cells[int(parts[1])].biome)
		if parts[0]=="clay" and not biome in [0,5] or parts[0]!="clay" and not biome in [3,4]:return false
	for id in c.jobs:
		if not id is String or not id.is_valid_int() or id!=str(int(id)):return false
		var workers=w.kingdom.workers.filter(func(worker):return int(worker.id)==int(id));var job=c.jobs[id]
		if workers.size()!=1 or int(workers[0].building)!=0 or load("res://scripts/military.gd").worker_reserved(w,int(id)) or load("res://scripts/trade.gd").worker_reserved(w,int(id)):return false
		if not job is Dictionary or not C.shape(job,["resource","cell","progress","buffer"]) or not job.resource in RESOURCES or not C.number(job.cell,0,w.cells.size()-1,true) or not C.number(job.progress,0,CYCLE-1,true) or not C.number(job.buffer,0,6000,true):return false
		var biome=int(w.cells[int(job.cell)].biome)
		if job.resource=="wood" and biome!=1 or job.resource in ["stone","gold","copper","silver"] and not biome in [3,4] or job.resource=="clay" and not biome in [0,5] or job.resource in ["water","fish"] and biome!=6:return false
	return true
static func normalize(w):
	if not enabled(w):return
	var c=w.colony
	for key in ["version","last_tick","fortification","meals"]:c[key]=int(c[key])
	for key in c.stock:c.stock[key]=int(c.stock[key])
	for key in c.spent:c.spent[key]=int(c.spent[key])
	for job in c.jobs.values():
		for key in ["cell","progress","buffer"]:job[key]=int(job[key])
