extends SceneTree
const MAP=preload("res://scripts/ashen_desert_map.gd")
var game
var scene
var probe=preload("res://scripts/desert_progression_probe.gd").new()
var checks={}
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085e2full/"+name+".png")
func travel(target: Vector2,attack: bool=true) -> bool:
	var r=game.world.kingdom.adventure.run
	for p in MAP.path(Vector2(r.x,r.y),target):
		for i in range(120):
			if Vector2(r.x,r.y).distance_to(p)<13:break
			scene.movement=(p-Vector2(r.x,r.y)).normalized();scene.actions.attack=attack;scene.actions.skill=attack;scene.actions.heal=attack
			for e in r.enemies:
				if attack and e.hp>0 and e.state=="windup" and e.timer<250:scene.actions.dodge=true
			await physics_frame
			if game.world.kingdom.adventure.hero.defeated:return false
	scene.movement=Vector2.ZERO;scene.actions.clear();return Vector2(r.x,r.y).distance_to(target)<80
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/phase085e2full")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://desert-rendered-private.json";root.add_child(game);current_scene=game
	game.world=Persistence.load_world("res://tests/fixtures/planet-v085e2b.json");game.has_player_world=true;game.view.world=game.world;game.paused=true;game.ui.language="tr"
	probe.world=game.world;probe.driver.world=game.world
	game.hero_ui.destination("ashen_desert");await create_timer(.5).timeout;await shot("desert-card-tr")
	checks.entry=game.enter_adventure("ashen_desert");scene=game.adventure_scene;scene.controlled=true;await create_timer(.5).timeout;await shot("desert-entry-tr")
	var r=game.world.kingdom.adventure.run
	checks.oasis_path=await travel(MAP.LANDMARK);scene.interact();checks.oasis=r.landmark;await create_timer(.3).timeout;await shot("oasis-discovery-tr")
	var scorpion=r.enemies[1];checks.scorpion_path=await travel(Vector2(scorpion.x,scorpion.y),false);var hp=game.world.kingdom.adventure.hero.hp;var warning=false
	for i in range(400):
		if scorpion.state=="windup" and not warning:warning=true;await shot("scorpion-warning-tr")
		if r.poison_next>0:break
		scene.movement=(Vector2(scorpion.x,scorpion.y)-Vector2(r.x,r.y)).normalized() if Vector2(r.x,r.y).distance_to(Vector2(scorpion.x,scorpion.y))>65 else Vector2.ZERO;await physics_frame
	scene.movement=Vector2.ZERO;checks.sting=game.world.kingdom.adventure.hero.hp<hp and r.poison_next>0;checks.warning=warning
	scene.refresh_hud();await shot("poison-status-tr")
	for e in r.enemies:
		if e.hp<=0:continue
		await travel(Vector2(e.x,e.y))
		for i in range(1600):
			if e.hp<=0 or game.world.kingdom.adventure.hero.defeated:break
			var p=Vector2(r.x,r.y);var ep=Vector2(e.x,e.y);var input=probe.driver.command(ep)
			scene.movement=input.move if p.distance_to(ep)>60 or input.get("dodge",false) else Vector2.ZERO;scene.actions=input;await physics_frame
	scene.movement=Vector2.ZERO;checks.real_kills=r.enemies.all(func(e):return e.hp==0)
	for loot in r.loot:
		if not loot.taken:await travel(Vector2(loot.x,loot.y));scene.interact()
	checks.crystal_path=await travel(MAP.CRYSTAL);scene.interact();checks.crystal=r.nodes.crystal;await shot("crystal-pickup-tr")
	checks.road_path=await travel(MAP.ROAD);scene.interact();checks.road=r.road;await shot("ancient-road-tr")
	var samples=[];var previous=Time.get_ticks_usec();var cpu=scene.combat_cpu_us;var steps=scene.physics_steps
	for i in range(240):await process_frame;var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
	var total=0.0
	for ms in samples:total+=ms
	samples.sort();var profile={"scene":"ashen_desert_cleared_road","fps":samples.size()*1000.0/total,"p95_ms":samples[int(samples.size()*.95)],"step_us":(scene.combat_cpu_us-cpu)/maxi(1,scene.physics_steps-steps),"setup_ms":scene.startup_ms,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_bytes":OS.get_static_memory_usage()}
	checks.active_save=Persistence.save_world(game.world,game.save_path) and Persistence.load_world(game.save_path).kingdom==game.world.kingdom
	scene.go_home();await process_frame;checks.register=preload("res://scripts/ashen_desert.gd").register(game.world);checks.quest22=preload("res://scripts/kingdom.gd").claim(game.world,"main_22")
	game.realm_ui.open();await create_timer(.5).timeout;await shot("quest22-complete-tr")
	checks.home=game.paused and game.view.visible and Persistence.validate(game.world)
	var report={"checks":checks,"all_passed":not checks.values().has(false),"profile":profile};FileAccess.open("res://builds/phase085e2full/rendered.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("DESERT_RENDERED ",report);quit(0 if report.all_passed else 1)
