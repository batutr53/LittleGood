extends SceneTree
const P=preload("res://scripts/parallel_play.gd")
const K=preload("res://scripts/kingdom.gd")
const R=preload("res://scripts/rpg_progression.gd")
const A=preload("res://scripts/adventure.gd")
const G=preload("res://scripts/regions.gd")
var checks={}
func walk(w,point):
	var map=load("res://scripts/wildwood_map.gd");var run=w.kingdom.adventure.run
	for waypoint in map.path(Vector2(run.x,run.y),point,false):
		for i in range(30):
			var direction=waypoint-Vector2(run.x,run.y)
			if direction.length()<12:break
			A.step(w,{"move":direction.normalized()})
func _initialize():call_deferred("run")
func run():
	var w=WorldGen.generate(42,"Parallel first day");load("res://scripts/estate.gd").start(w);checks.first_day=P.ensure(w);checks.no_quest_granted=w.kingdom.claimed.is_empty() and w.kingdom.xp==0;checks.city_level_one=K.level(w)==1
	checks.hero_available=R.available(w) and w.rpg.roster.size()==4;checks.armed=load("res://scripts/hero.gd").progress(w,"hero_armed")==1;checks.no_cost=w.kingdom.stock.gold==8000 and K.home(w).food==20
	checks.new_valid=Persistence.validate(w);var snap=w.duplicate(true);P.ensure(w);checks.idempotent=w==snap
	for region in G.IDS:
		checks[region+"_no_city_gate"]=G.unlocked(w,region);checks[region+"_enter"]=A.enter(w,false,region);checks[region+"_save"]=Persistence.save_world(w,"user://parallel-"+region+".json");checks[region+"_valid"]=Persistence.validate(w)
		var copy=Persistence.load_world("user://parallel-"+region+".json");checks[region+"_restore"]=not copy.is_empty() and copy.kingdom.adventure.run==w.kingdom.adventure.run
		checks[region+"_return"]=A.exit(w)
	checks.boss_not_city_locked=not P.boss_locked(w)
	for cls in R.CLASSES:checks[cls+"_available"]=R.switch(w,cls) and G.unlocked(w,"wildwood")
	R.switch(w,"warrior");A.enter(w,false,"wildwood");var run=w.kingdom.adventure.run;var clock=run.duplicate(true);var id=int(w.kingdom.workers[0].id);load("res://scripts/colony.gd").ensure(w);checks.gathering=load("res://scripts/colony.gd").start(w,id,"wood")
	var rng=RandomNumberGenerator.new();rng.state=int(w.rng_state)
	for i in range(10):Ecosystem.tick(w,rng);Civilization.tick(w)
	w.rng_state=str(rng.state);checks.city_gathering_during_adventure=w.colony.jobs[str(id)].buffer==2000;checks.no_auto_combat=run==clock;checks.concurrent_valid=Persistence.validate(w)
	var tick=w.tick;w.saved_at=100000;w.user_paused=false;clock=run.duplicate(true);Persistence.offline(w,100600);checks.offline_city_progress=w.tick>tick;checks.offline_no_combat=run==clock;checks.offline_buffer_bounded=w.colony.jobs[str(id)].buffer<=6000;checks.offline_valid=Persistence.validate(w)
	A.exit(w);checks.normal_return_valid=Persistence.validate(w)
	var old=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");var hero=old.kingdom.adventure.hero.duplicate(true);var workers=old.kingdom.workers.duplicate(true);var claimed=old.kingdom.claimed.duplicate();var industry=old.kingdom.industry.duplicate(true);var stock=old.kingdom.stock.duplicate();checks.old_migrate=P.ensure(old);checks.identity_kept=old.kingdom.adventure.hero==hero and old.kingdom.workers==workers;checks.history_kept=old.kingdom.claimed==claimed;checks.items_queue_kept=old.kingdom.industry==industry;checks.stock_kept=old.kingdom.stock==stock;checks.migrated_valid=Persistence.validate(old)
	var ro=old.duplicate(true);ro.erase("parallel_play");ro._read_only=true;snap=ro.duplicate(true);checks.readonly_no_migration=not P.ensure(ro) and ro==snap
	var bad=old.duplicate(true);bad.parallel_play.version=9;checks.reject_version=not Persistence.validate(bad)
	# First-day combat uses actual path movement, enemy AI and damage/drop rules.
	var first=WorldGen.generate(42,"First hunt");load("res://scripts/estate.gd").start(first);P.ensure(first);A.enter(first,false,"wildwood")
	var hunt=first.kingdom.adventure.run;var wolf=hunt.enemies[0];walk(first,Vector2(660,1160))
	for i in range(300):
		if wolf.hp<=0 or first.kingdom.adventure.hero.defeated:break
		var toward=Vector2(wolf.x,wolf.y)-Vector2(hunt.x,hunt.y)
		A.step(first,{"move":toward.normalized() if toward.length()>65 else Vector2.ZERO,"attack":true,"skill":true,"target_id":1})
	checks.first_day_wolf_defeated=wolf.hp==0 and not first.kingdom.adventure.hero.defeated;checks.first_day_xp=first.kingdom.adventure.hero.xp>0;checks.first_day_real_drop=not hunt.loot.is_empty()
	for drop in hunt.loot:
		walk(first,Vector2(drop.x,drop.y));A.pickup(first,drop)
	checks.first_day_pickup=not hunt.loot.is_empty() and hunt.loot.all(func(drop):return drop.taken)
	var cargo=hunt.cargo.duplicate();var before=first.kingdom.stock.duplicate();checks.first_day_return=A.exit(first);checks.first_day_cargo_delivered=not cargo.is_empty() and cargo.keys().all(func(key):return first.kingdom.stock[key]==before[key]+int(cargo[key])*1000)
	var banked=first.kingdom.stock.duplicate();checks.return_once=not A.exit(first) and first.kingdom.stock==banked;checks.first_day_hunt_valid=Persistence.validate(first)
	# Existing buildings and forge queues also advance through the real city tick.
	var city=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");load("res://scripts/estate.gd").start(city);P.ensure(city);A.enter(city,false,"wildwood");var farm=city.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];var forge=city.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	checks.forge_worker=K.assign(city,int(city.kingdom.workers.filter(func(worker):return int(worker.building)==0)[0].id),int(forge.id))
	var queue_id=int(city.kingdom.industry.queue[0].id);var combat=city.kingdom.adventure.run.duplicate(true)
	for i in range(60):city.tick+=1;K.tick(city)
	checks.farm_products_during_hunt=city.estate.pending.get(str(int(farm.id)),{}).get("food",0)>0;checks.forge_finishes_during_hunt=queue_id in city.estate.craft_ready;checks.production_does_not_simulate_combat=city.kingdom.adventure.run==combat;checks.production_valid=Persistence.validate(city)
	DirAccess.make_dir_recursive_absolute("res://builds/parallel");var result={"count":checks.size(),"checks":checks,"all_passed":not checks.values().has(false)};var file=FileAccess.open("res://builds/parallel/model.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));print("PARALLEL_PLAY "+JSON.stringify(result));quit(0 if result.all_passed else 1)
