extends SceneTree
const E=preload("res://scripts/estate.gd")
const K=preload("res://scripts/kingdom.gd")
const S=preload("res://scripts/planet_showcase.gd")
var checks={}
func _initialize():call_deferred("run")
func run():
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");var old=w.duplicate(true);var rng=w.rng_state
	E.start(w)
	checks.large_start=w.cells.size()==1024
	checks.append_only_migration=w.cells.slice(0,old.cells.size())==old.cells
	checks.original_buildings=w.kingdom.buildings==old.kingdom.buildings
	checks.rng_preserved=w.rng_state==rng
	checks.initial_valid=Persistence.validate(w)
	var before=JSON.stringify(w);E.start(w);checks.idempotent=before==JSON.stringify(w)
	var stock=w.kingdom.stock.duplicate();var p=E.candidates(w)[0]
	checks.first_free=E.cost(w).is_empty() and E.expand(w,p) and stock==w.kingdom.stock and w.cells.size()==1088
	checks.no_duplicate=not E.expand(w,p)
	checks.no_remote=not E.expand(w,Vector2i(80,80))
	checks.expanded_valid=Persistence.validate(w)
	var price=E.cost(w);var next=E.candidates(w)[0]
	for key in price:w.kingdom.stock[key]=int(price[key])*1000
	checks.paid_expansion=E.expand(w,next) and w.kingdom.stock.wood==0 and w.kingdom.stock.stone==0 and w.kingdom.stock.gold==0
	var unchanged=JSON.stringify(w);checks.insufficient_atomic=not E.expand(w,E.candidates(w)[0]) and unchanged==JSON.stringify(w)
	var b=w.kingdom.buildings.filter(func(item):return item.kind=="lumber")[0];var id=int(b.id)
	w.kingdom.stock.wood=0
	E.deposit(w,b,"wood",7000)
	checks.harvest_ready=E.status(w,b)=="harvest" and w.kingdom.stock.wood==0
	checks.buffer_room=is_equal_approx(E.room(w,b),20.0*int(b.level)-7)
	checks.buffer_valid=Persistence.validate(w)
	var gained=E.collect(w,id)
	checks.real_transfer=gained.wood==7000 and w.kingdom.stock.wood==7000
	checks.exactly_once=E.collect(w,id).is_empty() and w.kingdom.stock.wood==7000
	w.kingdom.stock.wood=roundi(K.storage(w)*1000)-1000;E.deposit(w,b,"wood",7000);gained=E.collect(w,id)
	checks.partial_capacity=gained.wood==1000 and int(w.estate.pending[str(id)].wood)==6000
	checks.full_warehouse_keeps_output=E.collect(w,id).is_empty() and int(w.estate.pending[str(id)].wood)==6000
	w.estate.completed.erase(str(id));checks.construction_bubble=E.status(w,b)=="harvest"
	w.kingdom.stock.wood=0;gained=E.collect(w,id);checks.construction_ack=gained.get("built")==1 and E.status(w,b)==""
	checks.save=Persistence.save_world(w,"user://estate-tests.json")
	var loaded=Persistence.load_world("user://estate-tests.json");checks.load=not loaded.is_empty() and loaded.estate==w.estate and loaded.cells.size()==w.cells.size()
	var public=S.project(w);checks.public_v3=int(public.version)==3 and S.validate(public) and not S.encode(w).is_empty()
	var downgraded=public.duplicate(true);downgraded.version=2;checks.old_public_cap_retained=not S.validate(downgraded)
	downgraded.erase("appearance");downgraded.version=1;checks.oldest_public_cap_retained=not S.validate(downgraded)
	var visit=S.world_from(public);checks.public_readonly=visit.get("_read_only",false) and visit.cells.size()==w.cells.size() and not E.expand(visit,Vector2i.ZERO) and E.collect(visit,id).is_empty()
	var bad=w.duplicate(true);bad.cells[0].x=100;checks.reject_coordinate=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.estate.pending={"999":{"wood":1000}};checks.reject_orphan=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.estate.pending={str(id):{"gold":1000}};checks.reject_wrong_resource=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.estate.pending={str(id):{"wood":999999}};checks.reject_overflow=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.estate.plots.append(bad.estate.plots[0]);checks.reject_duplicate_plot=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.estate.craft_ready=[99999];checks.reject_missing_craft=not Persistence.validate(bad)
	var full=WorldGen.generate(42,"Full realm");E.start(full);K.enable(full)
	while not E.candidates(full).is_empty():
		for resource in ["wood","stone","gold"]:full.kingdom.stock[resource]=100000
		E.expand(full,E.candidates(full)[0])
	checks.bounded_complete_world=full.cells.size()==2304 and full.estate.plots.size()==36 and Persistence.validate(full)
	checks.full_public=not S.encode(full).is_empty() and S.parse(S.encode(full)).cells.size()==2304
	var simulation=w.duplicate(true);var random=RandomNumberGenerator.new();random.state=int(simulation.rng_state);var started=Time.get_ticks_usec()
	for i in range(720):Ecosystem.tick(simulation,random);Civilization.tick(simulation)
	simulation.rng_state=str(random.state)
	var simulation_ms=(Time.get_ticks_usec()-started)/1000.0
	checks.extended_simulation=Persistence.validate(simulation)
	var offline=w.duplicate(true);offline.user_paused=false;offline.estate.pending.clear();offline.kingdom.stock.wood=0
	offline.kingdom.workers[0].building=id
	var report=Persistence.offline(offline,float(offline.saved_at)+28800)
	checks.offline_replay=report.ticks==480 and Persistence.validate(offline)
	checks.offline_buffered=not offline.estate.pending.get(str(id),{}).is_empty() and offline.kingdom.stock.wood==0
	var ready=offline.estate.pending.duplicate(true);Persistence.offline(offline,float(offline.saved_at));checks.offline_no_duplicate=ready==offline.estate.pending
	var craft=w.duplicate(true);var I=load("res://scripts/industry.gd");var forge=craft.kingdom.buildings.filter(func(item):return item.kind=="forge")[0]
	craft.kingdom.industry.queue.clear()
	for resource in craft.kingdom.stock:craft.kingdom.stock[resource]=50000
	checks.queue_craft=I.queue(craft,"forest_axe",int(forge.id))
	var job=craft.kingdom.industry.queue.back();var count=craft.kingdom.industry.items.size();var reserved=int(job.id);craft.kingdom.workers[0].building=int(forge.id);job.progress=int(I.recipes()[job.recipe].ticks)*1000-1;craft.tick+=1;I.tick(craft)
	checks.craft_waits_for_collection=craft.estate.craft_ready.has(reserved) and craft.kingdom.industry.items.size()==count and Persistence.validate(craft)
	checks.craft_icon=E.status(craft,forge)=="crafted"
	checks.craft_claim=E.collect(craft,int(forge.id)).get("crafted",0)==1 and not I.item(craft,reserved).is_empty() and craft.estate.craft_ready.is_empty()
	checks.craft_exactly_once=not E.collect(craft,int(forge.id)).has("crafted") and craft.kingdom.industry.items.size()==count+1 and Persistence.validate(craft)
	var stats={"checks":checks,"count":checks.size(),"all_passed":not checks.values().has(false),"simulation_720_ticks_ms":simulation_ms,"cells":w.cells.size()}
	DirAccess.make_dir_recursive_absolute("res://builds/estate");var file=FileAccess.open("res://builds/estate/tests.json",FileAccess.WRITE);file.store_string(JSON.stringify(stats,"  "));print("ESTATE_CHECKS "+JSON.stringify(stats));quit(0 if stats.all_passed else 1)
