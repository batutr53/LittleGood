extends SceneTree
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085d/"+name+".png")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://military-rendered-private.json";root.add_child(game);current_scene=game
	var p=preload("res://scripts/military_progression_probe.gd").new();var ok=p.defended();game.world=p.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="en";game.ui.build();game.show_world(true);game.view.invalidate();game.military_ui.open()
	await create_timer(.4).timeout;await shot("company-hall")
	game.enter_army("raid");var scene=game.army_scene
	await create_timer(2).timeout;await shot("village-defense")
	var frames=[];var last=Time.get_ticks_usec()
	while game.world.kingdom.military.battle.result.is_empty() and frames.size()<3000:
		await process_frame;var now=Time.get_ticks_usec();frames.append((now-last)/1000.0);last=now
	ok=ok and game.world.kingdom.military.battle.result=="won";await shot("defense-victory")
	var total=0.0
	for ms in frames:total+=ms
	frames.sort();var report={"source":"desktop_rendered_live_army","fps":frames.size()*1000/total,"p95_ms":frames[int(frames.size()*.95)],"startup_ms":scene.startup_ms,"step_us":scene.cpu_us/maxi(1,scene.steps),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory_bytes":OS.get_static_memory_usage(),"frames":frames.size(),"victory":ok}
	var f=FileAccess.open("res://builds/phase085d/desktop-army-performance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("MILITARY_RENDERED ",report)
	scene.go_home();preload("res://scripts/kingdom.gd").claim(game.world,"main_19");game.enter_army("camp")
	await create_timer(5).timeout;await shot("border-camp")
	preload("res://scripts/military.gd").order(game.world,"retreat");game.army_scene.go_home();game.queue_free();await process_frame;quit(0 if ok else 1)
