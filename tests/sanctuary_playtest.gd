extends SceneTree
const A=preload("res://scripts/adventure.gd")
const MAP=preload("res://scripts/sanctuary_map.gd")
var game
var scene
var checks={}
var probe=preload("res://scripts/sanctuary_progression_probe.gd").new()
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/phase085e3/"+name+".png")
func travel(target: Vector2) -> bool:
	var r=game.world.kingdom.adventure.run
	var route=MAP.path(Vector2(r.x,r.y),target,r)
	if route.is_empty():return false
	for point in route:
		for i in range(120):
			if Vector2(r.x,r.y).distance_to(point)<13:break
			scene.movement=(point-Vector2(r.x,r.y)).normalized();scene.actions=probe.driver.command(point)
			await physics_frame
			if game.world.kingdom.adventure.hero.defeated:return false
	scene.movement=Vector2.ZERO;scene.actions.clear()
	return Vector2(r.x,r.y).distance_to(target)<70
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/phase085e3")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://sanctuary-rendered-private.json";root.add_child(game);current_scene=game
	game.world=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.has_player_world=true;game.view.world=game.world;game.paused=true;game.ui.language="tr"
	probe.world=game.world;probe.driver.world=game.world
	checks.entry=game.enter_adventure("sanctuary");scene=game.adventure_scene;scene.controlled=true
	var clock=game.world.kingdom.adventure.run.clock;scene.toggle_pack();await create_timer(.15).timeout
	checks.pack_pauses=scene.frozen and game.world.kingdom.adventure.run.clock==clock
	scene.actions.attack=true;scene.toggle_pack();checks.pack_clears_input=not scene.frozen and scene.actions.is_empty() and not scene.attack_held
	scene.toggle_pack();scene.toggle_pause();checks.pause_closes_pack=not is_instance_valid(scene.pack_panel) and scene.frozen
	scene.toggle_pause();checks.resume=not scene.frozen
	await create_timer(.5).timeout;await shot("sanctuary-entry-tr")
	var r=game.world.kingdom.adventure.run
	checks.inscription_route=await travel(MAP.INSCRIPTION);scene.interact();checks.inscription=r.landmark
	await shot("inscription-tr")
	for i in range(2):checks["plate_route_"+str(i)]=await travel(MAP.PLATES[i])
	checks.plates=r.mechanisms.plates==2;await shot("stone-trial-tr")
	for i in range(3):
		checks["switch_route_"+str(i)]=await travel(MAP.SWITCHES[i]);scene.interact()
	checks.runes=r.mechanisms.switches==3;await shot("guardian-hall-tr")
	for e in r.enemies:
		if e.hp<=0:continue
		checks["enemy_route_"+str(e.id)]=await travel(Vector2(e.x,e.y))
		for i in range(2000):
			if e.hp<=0 or game.world.kingdom.adventure.hero.defeated:break
			var pos=Vector2(r.x,r.y);var ep=Vector2(e.x,e.y);var input=probe.driver.command(ep)
			scene.movement=input.move if pos.distance_to(ep)>59 or input.get("dodge",false) else Vector2.ZERO;scene.actions=input
			if e.state=="windup" and e.timer<=100:await shot("enemy-"+str(e.id)+"-warning-tr")
			await physics_frame
	scene.movement=Vector2.ZERO;scene.actions.clear();checks.kills=r.enemies.all(func(e):return e.hp==0)
	checks.relic_route=await travel(MAP.RELIC);scene.interact();checks.relic=preload("res://scripts/sanctuary.gd").progress(game.world,"relic")==1
	await shot("sun-relic-tr")
	checks.secret_route=await travel(MAP.SECRET);scene.interact()
	checks.lore_route=await travel(MAP.LORE);scene.interact()
	checks.treasure_route=await travel(MAP.TREASURE);scene.interact();checks.treasury=r.chest
	await shot("hidden-treasury-tr")
	for loot in r.loot:
		if not loot.taken:await travel(Vector2(loot.x,loot.y));scene.interact()
	checks.active_save=Persistence.save_world(game.world,game.save_path) and Persistence.load_world(game.save_path).kingdom==game.world.kingdom
	var samples=[];var previous=Time.get_ticks_usec();var cpu=scene.combat_cpu_us;var steps=scene.physics_steps
	for i in range(180):
		await process_frame;var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
	var total=0.0
	for ms in samples:total+=ms
	samples.sort()
	var profile={"fps":samples.size()*1000.0/total,"p95_ms":samples[int(samples.size()*.95)],"simulation_step_us":(scene.combat_cpu_us-cpu)/maxi(1,scene.physics_steps-steps),"setup_ms":scene.startup_ms,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_bytes":OS.get_static_memory_usage()}
	scene.go_home();await process_frame
	checks.returned=preload("res://scripts/sanctuary.gd").progress(game.world,"returned")==1
	checks.research=preload("res://scripts/sanctuary.gd").research(game.world)
	game.realm_ui.ancients();await create_timer(.4).timeout;await shot("relic-research-tr")
	# Continue through the real staffed forge; reconnect only the existing
	# progression driver's references to this private world after scene return.
	var crafter=preload("res://scripts/adventure_progression_probe.gd").new();crafter.world=game.world;crafter.foundation.world=game.world;crafter.foundation.base.world=game.world;crafter.foundation.base.driver.world=game.world;crafter.foundation.base.driver.rng.state=int(game.world.rng_state)
	for recipe in preload("res://scripts/sanctuary.gd").GEAR:
		checks["forge_"+recipe]=crafter.craft(recipe)
		var items=game.world.kingdom.industry.items.filter(func(item):return item.recipe==recipe)
		checks["equip_"+recipe]=not items.is_empty() and preload("res://scripts/hero.gd").equip(game.world,preload("res://scripts/industry.gd").recipes()[recipe].category,int(items[0].id))
	game.realm_ui.workshop();await create_timer(.4).timeout;await shot("ancient-forging-tr")
	checks.quest23=preload("res://scripts/kingdom.gd").claim(game.world,"main_23")
	game.realm_ui.open();await create_timer(.4).timeout;await shot("quest23-complete-tr")
	checks.final_save=Persistence.save_world(game.world,game.save_path) and Persistence.load_world(game.save_path).kingdom==game.world.kingdom
	checks.home_valid=Persistence.validate(game.world)
	var report={"checks":checks,"all_passed":not checks.values().has(false),"profile":profile}
	FileAccess.open("res://builds/phase085e3/rendered.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("SANCTUARY_RENDERED ",report);quit(0 if report.all_passed else 1)
