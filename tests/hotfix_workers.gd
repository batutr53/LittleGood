extends SceneTree
const K=preload("res://scripts/kingdom.gd")
const E=preload("res://scripts/estate.gd")
const C=preload("res://scripts/colony.gd")
var checks={}
func _initialize():call_deferred("run")
func ticks(w,count):
	for i in range(count):w.tick+=1;K.tick(w)
func run():
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");E.start(w);C.ensure(w)
	var ids=w.kingdom.workers.map(func(c):return int(c.id));var mine=w.kingdom.buildings.filter(func(b):return b.kind=="mine")[0];var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];var free=K.assigned(w,0)[0];var id=int(free.id)
	checks.eligible=K.assignment_reason(w,id,int(mine.id)).is_empty();var old_count=K.occupied(w,int(mine.id));var old_rate=K.activity_rate(w,mine);checks.assign=K.assign(w,id,int(mine.id)) and K.occupied(w,int(mine.id))==old_count+1 and K.activity_rate(w,mine)>old_rate
	checks.same_assignment_explained=K.assignment_reason(w,id,int(mine.id))=="already";checks.busy_explained=K.assignment_reason(w,id,int(farm.id)) in ["busy","full"];var before=w.duplicate(true);checks.no_incompatible_assign=not K.assign(w,id,int(farm.id)) and w==before
	var prior=int(w.estate.pending.get(str(int(mine.id)),{}).get("ore",0));ticks(w,3);checks.real_output=int(w.estate.pending.get(str(int(mine.id)),{}).get("ore",0))>prior
	checks.release=K.assign(w,id,0) and K.occupied(w,int(mine.id))==old_count and K.activity_rate(w,mine)<=old_rate
	checks.transfer_after_release=K.assignment_reason(w,id,int(farm.id)).is_empty() and K.assign(w,id,int(farm.id));K.assign(w,id,0)
	for citizen in w.kingdom.workers:
		if int(citizen.building)==int(mine.id):K.assign(w,int(citizen.id),0)
	prior=int(w.estate.pending.get(str(int(mine.id)),{}).get("ore",0));ticks(w,3);checks.removal_stops_output=int(w.estate.pending.get(str(int(mine.id)),{}).get("ore",0))==prior
	checks.invalid_worker=K.assignment_reason(w,999999,int(mine.id))=="worker" and not K.assign(w,999999,int(mine.id));checks.invalid_building=K.assignment_reason(w,id,999999)=="building" and not K.assign(w,id,999999)
	var passive=w.kingdom.buildings.filter(func(b):return b.kind=="house")[0];checks.passive=K.assignment_reason(w,id,int(passive.id))=="passive";var held=mine.progress;mine.progress=0;checks.unfinished=K.assignment_reason(w,id,int(mine.id))=="construction" and not K.assign(w,id,int(mine.id));mine.progress=held
	checks.gathering_started=C.start(w,id,"gold");checks.gathering_reserved=K.assignment_reason(w,id,int(mine.id))=="gathering" and not K.assign(w,id,int(mine.id));checks.release_gathering=C.release(w,id)
	for unit in w.kingdom.military.units:checks["military_"+str(unit.id)]=K.assignment_reason(w,int(unit.worker),int(mine.id))=="military" and not K.assign(w,int(unit.worker),int(mine.id))
	for unit in w.kingdom.military.units.duplicate():load("res://scripts/military.gd").retire(w,int(unit.id))
	for citizen in w.kingdom.workers:
		if not load("res://scripts/military.gd").worker_reserved(w,int(citizen.id)) and not load("res://scripts/trade.gd").worker_reserved(w,int(citizen.id)):K.assign(w,int(citizen.id),0)
	for citizen in K.assigned(w,0).duplicate():
		if K.occupied(w,int(mine.id))>=int(K.buildings()[mine.kind].slots):break
		K.assign(w,int(citizen.id),int(mine.id))
	var candidates=K.assigned(w,0)
	if candidates.is_empty():
		var busy=w.kingdom.workers.filter(func(c):return c.building!=mine.id and not load("res://scripts/military.gd").worker_reserved(w,int(c.id)) and not load("res://scripts/trade.gd").worker_reserved(w,int(c.id)))
		if not busy.is_empty():K.assign(w,int(busy[0].id),0);candidates=K.assigned(w,0)
	checks.capacity=K.occupied(w,int(mine.id))==int(K.buildings()[mine.kind].slots) and not candidates.is_empty() and K.assignment_reason(w,int(candidates[0].id),int(mine.id))=="full"
	checks.population_conserved=w.kingdom.workers.map(func(c):return int(c.id))==ids;checks.valid=Persistence.validate(w);checks.save=Persistence.save_world(w,"user://hotfix-workers-private.json");var restored=Persistence.load_world("user://hotfix-workers-private.json");checks.restore=not restored.is_empty() and restored.kingdom.workers==w.kingdom.workers and restored.estate==w.estate
	DirAccess.make_dir_recursive_absolute("res://builds/hotfix");var result={"checks":checks,"count":checks.size(),"all_passed":not checks.values().has(false)};var file=FileAccess.open("res://builds/hotfix/workers.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));print("HOTFIX_WORKERS "+JSON.stringify(result));quit(0 if result.all_passed else 1)
