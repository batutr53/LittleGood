extends SceneTree
const C=preload("res://scripts/colony.gd")
const K=preload("res://scripts/kingdom.gd")
const M=preload("res://scripts/military.gd")
var checks={}
func _initialize():call_deferred("run")
func ticks(w,n):
	for i in range(n):w.tick+=1;C.tick(w)
func run():
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");w.kingdom.adventure.run.active=false;var creatures=w.creatures.duplicate(true);var old=w.kingdom.duplicate(true);C.ensure(w);checks.additive=w.kingdom==old and w.creatures==creatures;var colony=w.colony.duplicate(true);C.ensure(w);checks.idempotent=w.colony==colony;checks.initial_valid=Persistence.validate(w)
	var free=K.assigned(w,0)[0];var id=int(free.id);var target=w.kingdom.buildings.filter(func(b):return K.ready(b) and int(K.buildings()[b.kind].slots)>0 and K.occupied(w,int(b.id))<int(K.buildings()[b.kind].slots))[0]
	checks.assign=K.assign(w,id,int(target.id));var other=w.kingdom.buildings.filter(func(b):return int(b.id)!=int(target.id) and K.ready(b) and int(K.buildings()[b.kind].slots)>0 and K.occupied(w,int(b.id))<int(K.buildings()[b.kind].slots))[0];checks.cannot_silently_reassign=not K.assign(w,id,int(other.id)) and int(free.building)==int(target.id);checks.busy_not_gather=not C.start(w,id,"wood");checks.explicit_release=K.assign(w,id,0)
	for key in C.RESOURCES:
		if key in ["wood","stone","gold"]:w.kingdom.stock[key]=0
		checks[key+"_real_source"]=C.source(w,key)>=0;checks[key+"_start"]=C.start(w,id,key);var job=w.colony.jobs[str(id)];checks[key+"_one_job"]=not C.start(w,id,"fish") and not K.assign(w,id,int(target.id)) and not K.assigned(w,0).has(free)
		var time=int(w.tick);C.tick(w);checks[key+"_tick_once"]=w.tick==time and job.progress==0;ticks(w,10);checks[key+"_output"]=job.buffer==2000
		var prior=int(w.kingdom.stock[key]) if key in ["wood","stone","gold"] else int(w.colony.stock[key]);checks[key+"_collect"]=C.collect(w,id)==2000 and (int(w.kingdom.stock[key]) if key in ["wood","stone","gold"] else int(w.colony.stock[key]))==prior+2000;checks[key+"_no_replay"]=C.collect(w,id)==0;checks[key+"_release"]=C.release(w,id)
	checks.worker_advances_quest=w.kingdom.events.gather_wood>=old.events.gather_wood+2000
	C.start(w,id,"fish");ticks(w,40);checks.buffer_cap=w.colony.jobs[str(id)].buffer==6000;checks.collect_before_release=not C.release(w,id);w.colony.stock.fish=59000;checks.partial_collect=C.collect(w,id)==1000 and w.colony.jobs[str(id)].buffer==5000;checks.full_no_loss=C.collect(w,id)==0 and w.colony.jobs[str(id)].buffer==5000
	ticks(w,10);checks.partial_refill_bounded=w.colony.jobs[str(id)].buffer==6000 and Persistence.validate(w)
	w.colony.stock.fish=0;C.collect(w,id);C.release(w,id);w.colony.stock.fish=2000;w.colony.stock.water=1000;K.home(w).food=30;checks.meal=C.meal(w) and K.home(w).food==34 and w.colony.stock.fish==0 and w.colony.stock.water==0;checks.no_free_meal=not C.meal(w)
	var unit=w.kingdom.military.units[0];checks.military_protected=not C.start(w,int(unit.worker),"wood")
	var before=M.stats(w,unit,true);w.colony.stock.copper=20000;w.colony.stock.clay=20000;w.colony.stock.silver=10000;w.kingdom.stock.stone=30000;var existing_defense=K.count(w,"watchtower")>0 and K.count(w,"wall")>0
	checks.actual_defense_requirements=C.reinforce(w)==existing_defense
	if existing_defense:checks.actual_defense_bonus=M.stats(w,unit,true).defense==before.defense+2 and M.stats(w,unit,false).defense==before.defense-K.count(w,"wall")*3
	C.start(w,id,"water");ticks(w,3);var online=w.duplicate(true);var now=float(w.saved_at)+3600;Persistence.offline(w,now);checks.offline_buffer=w.colony.jobs[str(id)].buffer==6000;var replay=w.colony.duplicate(true);Persistence.offline(w,now);checks.offline_once=w.colony==replay
	var paused=online.duplicate(true);paused.kingdom.adventure.run.active=true;var progress=paused.colony.jobs[str(id)].progress;ticks(paused,3);checks.no_expedition_work=paused.colony.jobs[str(id)].progress==progress
	var ro=w.duplicate(true);ro._read_only=true;var snapshot=ro.duplicate(true);C.tick(ro);C.collect(ro,id);C.release(ro,id);C.start(ro,id,"gold");C.meal(ro);C.reinforce(ro);checks.readonly=ro==snapshot
	var invalid=w.duplicate(true);invalid.colony.jobs[str(id)].buffer=7000;checks.reject_overflow=not Persistence.validate(invalid);invalid=w.duplicate(true);invalid.colony.jobs["99999"]=invalid.colony.jobs[str(id)].duplicate();checks.reject_orphan=not Persistence.validate(invalid);invalid=w.duplicate(true);invalid.colony.jobs[str(id)].cell=-1;checks.reject_source=not Persistence.validate(invalid)
	checks.final_valid=Persistence.validate(w);checks.save=Persistence.save_world(w,"user://colony-model-only.json");var loaded=Persistence.load_world("user://colony-model-only.json");checks.roundtrip=not loaded.is_empty() and loaded.colony==w.colony;checks.legacy_roundtrip=not loaded.is_empty() and JSON.stringify(loaded.creatures)==JSON.stringify(Persistence.normalize_integer_fields(w.duplicate(true)).creatures)
	DirAccess.make_dir_recursive_absolute("res://docs/benchmarks/colony");var report={"checks":checks,"count":checks.size(),"all_passed":not checks.values().has(false)};var f=FileAccess.open("res://docs/benchmarks/colony/model.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));print("COLONY_MODEL ",checks.size()," passed=",report.all_passed," failures=",checks.keys().filter(func(k):return not checks[k]));quit(0 if report.all_passed else 1)
