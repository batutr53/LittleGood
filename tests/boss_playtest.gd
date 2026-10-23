extends SceneTree
const MAP=preload("res://scripts/wildwood_map.gd")
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085c/"+name+".png")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;root.add_child(game);current_scene=game
	var p=preload("res://scripts/adventure_progression_probe.gd").new();var ok=p.equipped_upgrade();game.world=p.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="en";game.enter_adventure()
	var scene=game.adventure_scene;scene.controlled=true;var r=game.world.kingdom.adventure.run;var boss=r.enemies[3];var path=MAP.path(Vector2(r.x,r.y),Vector2(boss.x,boss.y),false);var warned=false;var phase2=false;var dodge_before=game.world.kingdom.adventure.events.get("dodged",0)
	for target in path:
		for i in range(90):
			if Vector2(r.x,r.y).distance_to(target)<12:break
			var command=p.command(target);scene.movement=command.move;scene.actions=command;await physics_frame
	for i in range(2400):
		var command=p.command(Vector2(boss.x,boss.y));scene.movement=command.move if Vector2(r.x,r.y).distance_to(Vector2(boss.x,boss.y))>58 or command.get("dodge",false) else Vector2.ZERO;scene.actions=command
		if boss.state=="windup" and not warned:await shot("thornheart-warning");warned=true
		if boss.hp<=110 and boss.hp>0 and not phase2:await shot("thornheart-phase2");phase2=true
		if boss.hp<=0 or game.world.kingdom.adventure.hero.defeated:break
		await physics_frame
	scene.movement=Vector2.ZERO;await shot("thornheart-victory")
	var intervals=[];var previous=Time.get_ticks_usec();var start=previous
	while Time.get_ticks_usec()-start<10000000:
		await process_frame;var now=Time.get_ticks_usec();intervals.append((now-previous)/1000.0);previous=now
	intervals.sort();var total=0.0
	for ms in intervals:total+=ms
	var report={"source":"desktop_real_rendered_adventure","fps":intervals.size()*1000.0/total,"frame_ms_p95":intervals[int(intervals.size()*.95)],"startup_ms":scene.startup_ms,"combat_step_us":scene.combat_cpu_us/maxi(1,scene.physics_steps),"memory_bytes":OS.get_static_memory_usage(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"physics_steps":scene.physics_steps,"boss_dead":boss.hp==0,"warning":warned,"phase2":phase2,"dodges":game.world.kingdom.adventure.events.get("dodged",0)-dodge_before}
	var f=FileAccess.open("res://builds/phase085c/desktop-adventure-performance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("C5_RENDERED ",report)
	ok=ok and boss.hp==0 and warned and phase2 and report.dodges>0;scene.go_home();quit(0 if ok else 1)
