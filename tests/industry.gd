extends SceneTree
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
var passed=0
var failed=0
func check(value: bool,message: String) -> void:
	if value:passed+=1;print("PASS ",message)
	else:failed+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var primary=FileAccess.get_file_as_bytes(Persistence.PATH)
	var old=Persistence.load_world("res://tests/fixtures/planet-v085a.json");var original=old.duplicate(true)
	check(not old.is_empty() and old.kingdom.version==1 and K.level(old)==5,"Actual tagged milestone-A save remains a playable realm-five chapter")
	check(I.enable(old) and not I.enable(old) and K.level(old)==6,"Explicit chapter transition unlocks realm six exactly once")
	check(old.cells==original.cells and old.kingdom.workers==original.kingdom.workers and old.kingdom.claimed==original.kingdom.claimed and old.kingdom.xp==original.kingdom.xp and old.wardrobe==original.wardrobe,"Transition preserves habitat, citizens, claims, XP and wardrobe")
	check(old.kingdom.stock.wood==original.kingdom.stock.wood and old.kingdom.stock.ore==0 and old.kingdom.stock.iron==0,"Chapter transition preserves balances without awarding imaginary ore or iron")
	check(Persistence.validate(old) and K.current(old).id=="main_06","Validated migrated state points to the real quarry quest")
	var fresh=WorldGen.generate(42,"Early");K.enable(fresh)
	check(not I.enable(fresh) and not I.queue(fresh,"forest_axe",1),"New chapter and crafting cannot bypass first-five prerequisites")
	var journey=preload("res://scripts/industry_progression_probe.gd").new()
	check(journey.forge_stage(),"Gathered stone and ore become smelted iron through legal assigned jobs: "+journey.error)
	var w=journey.world
	if w.is_empty():quit(1);return
	check(K.level(w)==9 and K.progress(w,{"kind":"event","key":"produce_ore"})>=12 and K.progress(w,{"kind":"event","key":"produce_iron"})>=6,"Real mineral production completes realm-six to realm-eight goals")
	var forge=w.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	var before=w.kingdom.stock.duplicate(true)
	check(I.queue(w,"forest_axe",int(forge.id)) and w.kingdom.stock.iron==before.iron-2000 and w.kingdom.stock.wood==before.wood-2000,"Craft queues reserve exact material costs before work")
	check(w.kingdom.industry.items.is_empty(),"Queuing an item does not instantly create it")
	var smith=w.kingdom.workers[2];K.assign(w,int(smith.id),0);var frozen=w.kingdom.industry.duplicate(true)
	journey.driver.step();check(w.kingdom.industry.queue==frozen.queue and w.kingdom.industry.items==frozen.items,"A forge with no smith makes no crafting progress")
	K.assign(w,int(smith.id),int(forge.id))
	for i in range(8):journey.driver.step()
	check(w.kingdom.industry.items.size()==1 and w.kingdom.industry.queue.is_empty(),"Assigned smith completes one persisted item instance")
	frozen=w.kingdom.duplicate(true);K.tick(w);I.tick(w)
	check(w.kingdom==frozen,"Repeated same-clock kingdom and forge ticks cannot duplicate work or items")
	var axe=w.kingdom.industry.items[0];var lumber=w.kingdom.buildings.filter(func(b):return b.kind=="lumber")[0];var worker=int(w.kingdom.workers[0].id)
	var base=K.productivity(w,lumber)
	check(I.equip(w,worker,int(axe.id)) and is_equal_approx(K.productivity(w,lumber),base*1.5),"Equipped axe increases the actual lumber production formula by fifty percent")
	check(I.equip(w,int(smith.id),int(axe.id)) and I.tool(w,worker).is_empty() and w.kingdom.industry.equipped.size()==1,"Moving a tool atomically removes its previous owner rather than duplicating it")
	check(not I.equip(w,999,int(axe.id)) and not I.equip(w,worker,999),"Invalid citizens and item instances cannot equip")
	check(I.equip(w,int(smith.id),0) and w.kingdom.industry.items.size()==1,"Unequipping returns an existing item without destroying or copying it")
	var saved="user://industry-test.json"
	check(Persistence.save_world(w,saved) and Persistence.load_world(saved).kingdom==w.kingdom,"Inventory, recipe events and jobs round-trip exactly")
	var bad=w.duplicate(true);bad.kingdom.industry.items.append(axe.duplicate(true));check(not Persistence.validate(bad),"Duplicate item instance IDs reject")
	bad=w.duplicate(true);bad.kingdom.industry.equipped=[{"worker":worker,"item":999}];check(not Persistence.validate(bad),"Dangling equipment rejects")
	bad=w.duplicate(true);bad.kingdom.stock.ore=-1;check(not Persistence.validate(bad),"Negative refined-economy balances reject")
	bad=w.duplicate(true);bad.kingdom.industry.queue=[{"id":999,"recipe":"free_sword","building":int(forge.id),"progress":0}];check(not Persistence.validate(bad),"Unknown recipes and unallocated IDs reject")
	var ro=w.duplicate(true);ro._read_only=true;frozen=ro.duplicate(true)
	I.enable(ro);I.queue(ro,"forest_axe",int(forge.id));I.equip(ro,worker,int(axe.id));I.tick(ro)
	check(ro==frozen,"All industry mutations honor read-only visits")
	check(not preload("res://scripts/planet_showcase.gd").project(w).has("kingdom"),"Public snapshots never expose inventory or private mineral balances")
	var smelting=w.duplicate(true);var furnace=smelting.kingdom.buildings.filter(func(b):return b.kind=="furnace")[0]
	for citizen in smelting.kingdom.workers:citizen.building=0
	K.assign(smelting,int(smelting.kingdom.workers[0].id),int(furnace.id));smelting.kingdom.stock.ore=1000;smelting.kingdom.stock.wood=10000;smelting.kingdom.stock.iron=0
	var ground=smelting.cells[int(furnace.cell)].resources;smelting.tick+=1;K.tick(smelting);var iron=int(smelting.kingdom.stock.iron)
	check(iron>0 and smelting.kingdom.stock.ore==1000-2*iron and smelting.kingdom.stock.wood==10000-iron,"Actual smelting conserves two ore and one timber per refined iron")
	check(smelting.cells[int(furnace.cell)].resources==ground,"Furnace consumes stored ingredients rather than inventing bars from its ground tile")
	smelting.kingdom.stock.iron=int(K.storage(smelting))*K.SCALE;before=smelting.kingdom.stock.duplicate(true);smelting.tick+=1;K.tick(smelting)
	check(smelting.kingdom.stock==before,"Full iron storage stops the furnace without consuming ingredients")
	smelting.kingdom.stock.iron=0;smelting.kingdom.stock.ore=0;before=smelting.kingdom.stock.duplicate(true);smelting.tick+=1;K.tick(smelting)
	check(smelting.kingdom.stock==before,"A furnace with no ore cannot produce iron")
	check(K.activity_rate(smelting,furnace)==0,"Unfueled furnace cannot display a false productive work animation")
	var boosted=w.duplicate(true);var plain=w.duplicate(true)
	for candidate in [boosted,plain]:
		for citizen in candidate.kingdom.workers:citizen.building=0
		K.assign(candidate,worker,int(lumber.id));candidate.kingdom.stock.wood=0;candidate.cells[int(lumber.cell)].resources=20
	I.equip(boosted,worker,int(axe.id));I.equip(plain,worker,0)
	boosted.tick+=1;plain.tick+=1;K.tick(boosted);K.tick(plain)
	check(absi(int(boosted.kingdom.stock.wood)-roundi(int(plain.kingdom.stock.wood)*1.5))<=1 and boosted.kingdom.stock.wood>plain.kingdom.stock.wood,"Equipped tool yields more real harvested stock in a matched simulation tick")
	var queued=w.duplicate(true);queued.kingdom.stock.iron=20000;queued.kingdom.stock.wood=20000
	var accepted=true
	for i in range(4):accepted=I.queue(queued,"field_sickle",int(forge.id)) and accepted
	before=queued.kingdom.stock.duplicate(true)
	check(accepted and not I.queue(queued,"field_sickle",int(forge.id)) and queued.kingdom.stock==before,"Full crafting queue rejects atomically without charging a fifth recipe")
	check(Persistence.save_world(queued,"user://industry-pending.json") and Persistence.load_world("user://industry-pending.json").kingdom==queued.kingdom,"Reserved costs and unfinished forge queue restore exactly")
	queued.kingdom.stock.iron=0;queued.kingdom.stock.wood=0;var ids_before=queued.kingdom.industry.next_item
	check(not I.queue(queued,"iron_pick",int(forge.id)) and queued.kingdom.industry.next_item==ids_before,"Failed crafting does not allocate phantom item IDs")
	var old_again=Persistence.load_world("res://tests/fixtures/planet-v085a.json");check(not old_again.kingdom.has("industry") and old_again.kingdom==original.kingdom,"Reading an old campaign does not silently opt it into a new economy")
	w.kingdom.stock.iron=20000;w.kingdom.stock.wood=20000
	var paid_tools=I.queue(w,"iron_pick",int(forge.id)) and I.queue(w,"field_sickle",int(forge.id)) and I.queue(w,"mason_hammer",int(forge.id))
	for i in range(16):journey.driver.step()
	check(paid_tools and w.kingdom.industry.items.size()==4,"All four tool recipes create real distinct items through paid smith work")
	var pick=w.kingdom.industry.items.filter(func(owned):return owned.recipe=="iron_pick")[0]
	var sickle=w.kingdom.industry.items.filter(func(owned):return owned.recipe=="field_sickle")[0]
	var hammer=w.kingdom.industry.items.filter(func(owned):return owned.recipe=="mason_hammer")[0]
	var mine=w.kingdom.buildings.filter(func(b):return b.kind=="mine")[0]
	boosted=w.duplicate(true);plain=w.duplicate(true)
	for candidate in [boosted,plain]:
		for citizen in candidate.kingdom.workers:citizen.building=0
		K.assign(candidate,worker,int(mine.id));candidate.kingdom.stock.ore=0;candidate.cells[int(mine.cell)].resources=20
	I.equip(boosted,worker,int(pick.id));I.equip(plain,worker,0);boosted.tick+=1;plain.tick+=1;K.tick(boosted);K.tick(plain)
	check(boosted.kingdom.stock.ore>plain.kingdom.stock.ore,"Iron pick increases actually harvested ore in matched world ticks")
	var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0]
	boosted=w.duplicate(true);plain=w.duplicate(true)
	for candidate in [boosted,plain]:
		for citizen in candidate.kingdom.workers:citizen.building=0
		K.assign(candidate,worker,int(farm.id));K.home(candidate).food=20;candidate.cells[int(farm.cell)].resources=20;candidate.cells[int(farm.cell)].moisture=1
	I.equip(boosted,worker,int(sickle.id));I.equip(plain,worker,0);boosted.tick+=1;plain.tick+=1;K.tick(boosted);K.tick(plain)
	check(K.home(boosted).food>K.home(plain).food,"Sickle increases actual settlement food after equal citizen upkeep")
	boosted=w.duplicate(true);plain=w.duplicate(true);var housing_id=int(w.kingdom.buildings.filter(func(b):return b.kind=="house")[0].id)
	var paid_upgrade=true
	for candidate in [boosted,plain]:
		candidate.kingdom.workers[0].building=0;candidate.kingdom.workers[1].building=int(farm.id);candidate.kingdom.workers[2].building=int(lumber.id);candidate.kingdom.workers[3].building=int(lumber.id)
		paid_upgrade=K.upgrade(candidate,housing_id) and paid_upgrade
	I.equip(boosted,worker,int(hammer.id));I.equip(plain,worker,0);boosted.tick+=1;plain.tick+=1;K.tick(boosted);K.tick(plain)
	var fast_house=boosted.kingdom.buildings.filter(func(b):return int(b.id)==housing_id)[0];var slow_house=plain.kingdom.buildings.filter(func(b):return int(b.id)==housing_id)[0]
	check(paid_upgrade and fast_house.progress>slow_house.progress,"Mason hammer increases actual paid construction labor for its idle citizen")
	var journeys=[]
	for seed in [2026,1,3,7,42,301,99991]:
		var probe=preload("res://scripts/industry_progression_probe.gd").new();var ok=probe.through_iron_age(seed)
		check(ok and Persistence.validate(probe.world),"Ten-quest legal progression seed "+str(seed)+" "+probe.error)
		if ok:
			var claimed=probe.world.kingdom.claimed.duplicate();var now=probe.world.saved_at+28800;Persistence.offline(probe.world,now);frozen=probe.world.kingdom.duplicate(true);Persistence.offline(probe.world,now)
			check(probe.world.kingdom==frozen and Persistence.validate(probe.world) and probe.world.kingdom.claimed==claimed,"Eight-hour offline industry replay is consistent and idempotent seed "+str(seed))
		journeys.append({"seed":seed,"passed":ok,"ticks":probe.driver.ticks,"error":probe.error})
	check(FileAccess.get_file_as_bytes(Persistence.PATH)==primary,"Industry tests preserve the primary player save")
	var f=FileAccess.open("res://builds/phase09/industry-tests.json",FileAccess.WRITE);f.store_string(JSON.stringify({"passed":passed,"failed":failed,"journeys":journeys}));f.close()
	print("INDUSTRY ",passed," passed, ",failed," failed");quit(0 if failed==0 else 1)
