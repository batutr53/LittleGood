extends SceneTree
const K=preload("res://scripts/kingdom.gd")
var passed=0
var failed=0
func check(ok: bool,message: String) -> void:
	if ok:passed+=1;print("PASS ",message)
	else:failed+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var before=FileAccess.get_file_as_bytes(Persistence.PATH)
	var w=WorldGen.generate(42,"First Flame");var legacy=w.duplicate(true)
	check(not w.has("kingdom") and K.validate(w),"Existing worlds stay unchanged until opt-in")
	check(K.enable(w) and not K.enable(w),"Founding stores/citizens granted exactly once")
	check(w.cells==legacy.cells and w.settlements==legacy.settlements and w.rng_state==legacy.rng_state,"Enable preserves real people, food, habitat and RNG")
	check(K.validate(w) and K.level(w)==1 and K.current(w).id=="main_01","Fresh campaign starts on its first real mission")
	check(not K.claim(w,"main_01") and not K.claim(w,"main_05"),"No reward before objectives/prerequisites")
	check(not K.observe_settlers(w,-1) and K.observe_settlers(w,int(w.settlements[0].cell)),"Only an actual settlers camp satisfies observation")
	check(K.begin_build(w,"farm",0)==-1 and not K.recruit(w),"Levels gate construction and specialist recruitment")
	var driver=preload("res://scripts/kingdom_progression_probe.gd").new();driver.start(2026)
	check(driver.gather("wood",6),"Gathering consumes real forest resources")
	var cell=-1
	for i in range(w.cells.size()):
		if int(w.cells[i].biome)==1:cell=i;break
	var raw=w.cells[cell].resources;var quantity=K.gather(w,"wood",cell)
	check(quantity>0 and w.cells[cell].resources==raw-quantity,"Gathering conserves harvested units")
	check(K.gather(w,"wood",cell)==0,"Gathering cooldown prevents click farming")
	check(K.gather(w,"gold",cell)==0 and K.gather(w,"stone",-1)==0,"Unsupported or invalid gathering rejects safely")
	driver.start(2026);check(driver.through_first_flame(),"Fresh world completes all five primary missions through real actions")
	w=driver.world
	check(w.kingdom.claimed.size()==5 and w.kingdom.xp==600 and K.level(w)==5,"Exact XP curve and ordered rewards reach realm five")
	check(K.progress(w,{"kind":"event","key":"produce_food"})>=6 and K.progress(w,{"kind":"event","key":"produce_wood"})>=4,"Real assigned work satisfies production objectives")
	check(K.tier(w)==2 and K.home(w).population>=6 and K.capacity(w)>=8,"Village tier derives from people, housing, food and actual buildings")
	var paid=w.kingdom.duplicate(true)
	check(not K.claim(w,"main_05") and w.kingdom==paid,"Repeated claim cannot duplicate currency or XP")
	var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0]
	check(not K.assign(w,999,int(farm.id)) and not K.assign(w,1,999),"Invalid citizen and workplace references rejected")
	check(K.assign(w,int(w.kingdom.workers[2].id),int(farm.id)) and not K.assign(w,int(w.kingdom.workers[3].id),int(farm.id)),"Worker slots enforce real capacity")
	check(K.assign(w,int(w.kingdom.workers[2].id),0),"Workers can return to building duties")
	var frozen=w.kingdom.duplicate(true);K.tick(w)
	check(w.kingdom==frozen,"Same simulation tick cannot produce or charge wages twice")
	var bad=w.duplicate(true);bad.kingdom.stock.wood=-1;check(not Persistence.validate(bad),"Negative resources reject")
	bad=w.duplicate(true);bad.kingdom.xp+=1;check(not Persistence.validate(bad),"XP must agree with uniquely claimed quest rewards")
	bad=w.duplicate(true);bad.kingdom.claimed.append("main_05");check(not Persistence.validate(bad),"Duplicate claimed quest rejects")
	bad=w.duplicate(true);bad.kingdom.workers[0].building=999;check(not Persistence.validate(bad),"Dangling worker assignment rejects")
	bad=w.duplicate(true);bad.kingdom.buildings[0].cell=999;check(not Persistence.validate(bad),"Out-of-map building rejects")
	check(Persistence.save_world(w,"user://phase085-test.json"),"Kingdom persists with original atomic save envelope")
	var restored=Persistence.load_world("user://phase085-test.json")
	check(not restored.is_empty() and restored.kingdom==w.kingdom,"Resources, workers, buildings and quests round-trip")
	var public=preload("res://scripts/planet_showcase.gd").project(w)
	check(not public.has("kingdom") and not public.has("stock"),"Private campaign and work data never upload as a showcase")
	var ro=w.duplicate(true);ro._read_only=true;frozen=ro.duplicate(true)
	K.tick(ro);K.claim(ro,"main_05");K.recruit(ro);K.assign(ro,1,0);K.gather(ro,"wood",cell);K.begin_build(ro,"house",0)
	check(ro==frozen,"All public-visit mutation boundaries remain intact")
	var occupied_cell=int(w.kingdom.buildings[0].cell)
	check(not preload("res://scripts/cosmetics.gd").valid_place(w,"flowers",occupied_cell),"Cosmetics cannot overlap functional kingdom buildings")
	check(not K.valid_site(w,"house",occupied_cell),"Functional structures cannot overlap each other")
	var house=w.kingdom.buildings.filter(func(b):return b.kind=="house")[0]
	var capacity_before=K.capacity(w);var housing_cost=K.upgrade_cost(house);var timber_before=int(w.kingdom.stock.wood)
	check(K.upgrade(w,int(house.id)) and w.kingdom.stock.wood==timber_before-int(housing_cost.wood)*K.SCALE,"Core building upgrades charge exact material costs")
	check(K.capacity(w)==capacity_before and K.count(w,"house")==1,"Housing upgrade retains previous rooms and village status")
	for i in range(20):driver.step()
	check(K.ready(house) and K.capacity(w)==capacity_before+3,"Completed housing upgrade adds real population capacity")
	var frozen_stock=w.kingdom.stock.duplicate(true)
	for c in w.kingdom.workers:K.assign(w,int(c.id),0)
	driver.step()
	check(w.kingdom.stock==frozen_stock,"Unassigned production buildings cannot create materials")
	var gather_before=w.kingdom.stock.wood;w.kingdom.stock.wood=int(K.storage(w))*K.SCALE;w.kingdom.gather_at=int(w.tick)-4
	check(K.gather(w,"wood",occupied_cell)==0,"Full material storage stops gathering")
	w.kingdom.stock.wood=gather_before
	var claimed=w.kingdom.claimed.duplicate();var now=w.saved_at+3600
	Persistence.offline(w,now)
	check(Persistence.validate(w) and w.kingdom.last_tick==w.tick and w.kingdom.claimed==claimed,"Bounded offline replay advances work without silently claiming quests")
	var after_offline=w.kingdom.duplicate(true);Persistence.offline(w,now)
	check(w.kingdom==after_offline,"Repeated offline report cannot duplicate production")
	var crowded=WorldGen.generate(42,"Legacy citizens");crowded.settlements[0].population=40.5
	K.enable(crowded)
	check(K.capacity(crowded)>=41 and crowded.settlements[0].population==40.5,"Existing high-population settlements keep their residents when opting in")
	var old=Persistence.load_world("res://tests/fixtures/planet-v07.json")
	check(not old.is_empty() and not old.has("kingdom") and K.enable(old) and Persistence.validate(old),"Actual 0.7 save gains optional kingdom without rebuilding its world")
	var old08=Persistence.load_world("res://tests/fixtures/planet-v08.json")
	var outfit=old08.get("wardrobe",{}).duplicate(true);var habitat=old08.get("cells",[]).duplicate(true)
	check(not old08.is_empty() and K.enable(old08) and Persistence.validate(old08) and old08.wardrobe==outfit and old08.cells==habitat,"Actual tagged 0.8 save preserves equipped cosmetics and habitat on opt-in")
	var recovery="user://phase085-recovery.json"
	Persistence.save_world(w,recovery);Persistence.save_world(w,recovery)
	var corrupt=FileAccess.open(recovery,FileAccess.WRITE);corrupt.store_string("interrupted");corrupt.close()
	check(Persistence.load_world(recovery).get("kingdom",{})==w.kingdom and Persistence.last_recovery=="backup","Corrupt campaign primary recovers exact kingdom from healthy backup")
	var unfinished=w.duplicate(true);var build=unfinished.kingdom.buildings[0].duplicate(true)
	for i in range(3):
		build=build.duplicate(true);build.id=unfinished.kingdom.next_building;unfinished.kingdom.next_building+=1;build.cell=i;unfinished.kingdom.buildings.append(build)
	check(not K.validate(unfinished),"Per-kind structure limits reject unbounded duplicate saves")
	var waiting=w.duplicate(true);var pending=waiting.kingdom.buildings.filter(func(b):return b.kind=="house")[0];pending.progress=0
	var lumber=waiting.kingdom.buildings.filter(func(b):return b.kind=="lumber")[0]
	for i in range(waiting.kingdom.workers.size()):waiting.kingdom.workers[i].building=int(farm.id if i<2 else lumber.id)
	var progress_before=pending.progress;waiting.tick+=1;K.tick(waiting)
	check(pending.progress==progress_before,"Construction needs an available citizen rather than free automatic work")
	var hungry=w.duplicate(true);K.home(hungry).population=hungry.kingdom.workers.size();K.home(hungry).food=2.5;hungry.cells[int(K.home(hungry).cell)].resources=0
	hungry.tick+=1;Civilization.tick(hungry)
	check(K.home(hungry).population>=hungry.kingdom.workers.size() and Persistence.validate(hungry),"Low food cannot remove residents while leaving their paid worker records")
	var loops: Array=[]
	for seed in [42,7,301,99991]:
		driver.start(seed);var ok=driver.through_first_flame();check(ok and Persistence.validate(driver.world),"First-Flame reachability seed "+str(seed));loops.append({"seed":seed,"ticks":driver.ticks,"actions":driver.actions,"passed":ok})
	check(FileAccess.get_file_as_bytes(Persistence.PATH)==before,"All expansion checks preserve the real player save")
	var f=FileAccess.open("res://builds/phase085/tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"failed":failed,"source":"real_model_actions_no_forced_levels_or_resources","milestone":"A","reachability":loops}));f.close()
	print("PHASE085 ",passed," passed, ",failed," failed");quit(0 if failed==0 else 1)
