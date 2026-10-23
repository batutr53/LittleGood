extends SceneTree
const MAP=preload("res://scripts/iron_hills_map.gd")
var game
var scene
var checks={}
var samples=[]
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085e2/"+name+".png")
func travel(target: Vector2,attack: bool=true) -> bool:
	var r=game.world.kingdom.adventure.run
	for point in MAP.path(Vector2(r.x,r.y),target):
		for i in range(80):
			if Vector2(r.x,r.y).distance_to(point)<13:break
			scene.movement=(point-Vector2(r.x,r.y)).normalized();scene.actions.attack=attack;scene.actions.skill=attack;scene.actions.heal=true
			for e in r.enemies:
				if attack and e.hp>0 and e.state=="windup" and e.timer<250:scene.actions.dodge=true
			await physics_frame
			if game.world.kingdom.adventure.hero.defeated:return false
	scene.movement=Vector2.ZERO
	return Vector2(r.x,r.y).distance_to(target)<80
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/phase085e2")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://regions-rendered-private.json";root.add_child(game);current_scene=game
	game.world=Persistence.load_world("res://tests/fixtures/planet-v085e1.json");game.view.world=game.world;game.paused=true;game.has_player_world=true;game.ui.language="en"
	game.hero_ui.world_map();await create_timer(.5).timeout;await shot("world-map")
	checks.enter=game.enter_adventure("iron_hills");scene=game.adventure_scene;scene.controlled=true
	await create_timer(.5).timeout;await shot("iron-entry")
	checks.walk_to_stone=await travel(MAP.NODES.stone.point,false);scene.interact()
	checks.gather_stone=game.world.kingdom.adventure.run.nodes.stone
	await create_timer(.5).timeout;await shot("iron-gather")
	var r=game.world.kingdom.adventure.run;var enemy=r.enemies[0]
	checks.walk_to_enemy=await travel(Vector2(enemy.x,enemy.y),false);var hp=game.world.kingdom.adventure.hero.hp;var warned=false
	for i in range(360):
		if enemy.state=="windup":warned=true;await shot("iron-combat-warning");break
		scene.movement=(Vector2(enemy.x,enemy.y)-Vector2(r.x,r.y)).normalized() if Vector2(r.x,r.y).distance_to(Vector2(enemy.x,enemy.y))>65 else Vector2.ZERO;await physics_frame
	scene.movement=Vector2.ZERO
	scene.actions.clear()
	for i in range(400):
		if game.world.kingdom.adventure.hero.hp<hp:break
		await physics_frame
	checks.warning=warned;checks.enemy_damage=game.world.kingdom.adventure.hero.hp<hp
	for e in r.enemies:
		if e.hp<=0:continue
		await travel(Vector2(e.x,e.y))
		for i in range(1200):
			if e.hp<=0 or game.world.kingdom.adventure.hero.defeated:break
			var p=Vector2(r.x,r.y);var ep=Vector2(e.x,e.y)
			scene.movement=(ep-p).normalized() if p.distance_to(ep)>60 else Vector2.ZERO;scene.actions.attack=true;scene.actions.skill=true;scene.actions.heal=true
			if e.state=="windup" and e.timer<=250:scene.actions.dodge=true;scene.movement=(p-ep).normalized()
			await physics_frame
	scene.movement=Vector2.ZERO;checks.real_kills=r.enemies.all(func(e):return e.hp<=0)
	checks.walk_to_ore=await travel(MAP.NODES.ore.point);scene.interact();checks.gather_ore=r.nodes.ore
	checks.mine_path=await travel(MAP.LANDMARK);scene.interact();checks.mine=r.landmark
	game.ui.language="tr";scene.refresh_hud();await create_timer(.6).timeout;await shot("forgotten-mine-tr")
	var previous=Time.get_ticks_usec()
	for i in range(180):
		await process_frame;var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
	var total=0.0
	for ms in samples:total+=ms
	samples.sort();var profile={"fps":samples.size()*1000.0/total,"p95_ms":samples[int(samples.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_bytes":OS.get_static_memory_usage(),"setup_ms":scene.startup_ms,"step_us":scene.combat_cpu_us/maxi(1,scene.physics_steps)}
	checks.save=Persistence.save_world(game.world,game.save_path) and Persistence.load_world(game.save_path).kingdom==game.world.kingdom;scene.go_home();await process_frame
	checks.home=not is_instance_valid(game.adventure_scene) and game.view.visible and game.paused and Persistence.validate(game.world)
	var report={"checks":checks,"all_passed":not checks.values().has(false),"profile":profile}
	FileAccess.open("res://builds/phase085e2/rendered.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("E2B_RENDERED ",report)
	quit(0 if report.all_passed else 1)
