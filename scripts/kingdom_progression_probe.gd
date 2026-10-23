extends RefCounted
const K=preload("res://scripts/kingdom.gd")
var world: Dictionary
var rng=RandomNumberGenerator.new()
var ticks=0
var actions: Array=[]
func start(seed: int) -> void:
	ticks=0;actions=[]
	world=WorldGen.generate(seed,"First Kingdom verification");preload("res://scripts/cosmetics.gd").ensure(world);K.enable(world);rng.state=int(world.rng_state)
func step() -> void:
	Ecosystem.tick(world,rng);Civilization.tick(world);world.rng_state=str(rng.state);ticks+=1
func site(kind: String) -> int:
	for i in range(world.cells.size()):
		if K.valid_site(world,kind,i):return i
	return -1
func gather(resource: String,quantity: float) -> bool:
	var before=float(world.kingdom.events.get("gather_"+resource,0))/K.SCALE
	for attempt in range(100):
		for i in range(world.cells.size()):
			if K.gather(world,resource,i)>0:actions.append("gather_"+resource);break
		if float(world.kingdom.events.get("gather_"+resource,0))/K.SCALE-before>=quantity:return true
		step()
	return false
func build(kind: String) -> int:
	var id=K.begin_build(world,kind,site(kind))
	if id<0:return id
	actions.append("build_"+kind)
	for i in range(100):
		var b=world.kingdom.buildings.filter(func(b):return int(b.id)==id)[0]
		if K.ready(b):return id
		step()
	return -1
func finish_current() -> bool:
	var q=K.current(world)
	for i in range(600):
		if K.complete(world,q):
			var ok=K.claim(world,q.id)
			if ok:actions.append("claim_"+q.id)
			return ok
		step()
	return false
func through_first_flame() -> bool:
	if not K.observe_settlers(world,int(K.home(world).cell)) or not gather("wood",6) or not finish_current():return false
	var camp=build("lumber")
	if camp<0 or not K.assign(world,int(world.kingdom.workers[0].id),camp) or not finish_current():return false
	var farm=build("farm")
	if farm<0 or not K.assign(world,int(world.kingdom.workers[1].id),farm) or not finish_current():return false
	if build("house")<0 or not K.recruit(world) or not finish_current():return false
	if build("townhall")<0 or not finish_current():return false
	return K.current(world).is_empty() and K.level(world)==5 and K.tier(world)==2
