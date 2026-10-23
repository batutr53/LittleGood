extends Node
const M=preload("res://scripts/military.gd")
const K=preload("res://scripts/kingdom.gd")
var game
var host
func wait_marker(name: String) -> void:
	while not FileAccess.file_exists("user://"+name):await get_tree().process_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://"+name+".png")
func controls() -> Dictionary:
	var points={}
	for key in game.army_scene.buttons:points[key]=host.point(game.army_scene.buttons[key])
	return points
func run() -> void:
	if host.options.get("phase")=="army_reopen":
		var expected=Persistence.load_world(game.save_path);await game.restore()
		host.checks.actual_scene_restored=is_instance_valid(game.army_scene)
		if not is_instance_valid(game.army_scene):host.publish("army_failed");return
		game.army_scene.frozen=true;host.checks.exact_restored=game.world.kingdom==expected.kingdom and game.world.tick==expected.tick
		await get_tree().create_timer(.5).timeout;await shot("android-army-restored")
		host.publish("army_reopen_touch",{"controls":controls()});await wait_marker("army_returned")
		host.checks.native_retreat=not game.world.kingdom.military.battle.active and game.world.kingdom.military.battle.result=="retreat"
		host.checks.no_quest20=game.world.kingdom.claimed.size()==19 and not game.world.kingdom.military.victories.camp
		host.checks.final_valid=Persistence.validate(game.world)
		host.publish("army_reopened",{"all_passed":not host.checks.values().has(false)});return
	var p=preload("res://scripts/military_progression_probe.gd").new();host.checks.legal18=p.defended();game.world=p.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.close();game.show_world(true);game.view.invalidate()
	host.checks.entry=game.enter_army("raid");game.army_scene.frozen=true
	await get_tree().create_timer(.5).timeout;await shot("android-army-defense")
	host.publish("army_touch_ready",{"controls":controls()});await wait_marker("army_orders")
	host.checks.native_hold=game.world.kingdom.military.battle.order=="hold"
	host.checks.native_formation=game.world.kingdom.military.formation=="assault"
	host.publish("army_resume_ready",{"controls":controls()});await wait_marker("army_started")
	host.checks.native_resume=not game.army_scene.frozen
	host.checks.native_advance=game.world.kingdom.military.battle.order=="advance"
	var intervals=[];var previous=Time.get_ticks_usec();var start=previous
	while game.world.kingdom.military.battle.result.is_empty() and Time.get_ticks_usec()-start<90000000:
		await get_tree().process_frame;var now=Time.get_ticks_usec();intervals.append((now-previous)/1000.0);previous=now
	intervals.sort();var total=0.0
	for ms in intervals:total+=ms
	var scene=game.army_scene
	var profile={"fps":intervals.size()*1000.0/maxf(1,total),"p95_ms":intervals[int(intervals.size()*.95)],"step_us":scene.cpu_us/maxi(1,scene.steps),"startup_ms":scene.startup_ms,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"memory_bytes":OS.get_static_memory_usage(),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"frames":intervals.size(),"cap":Engine.max_fps}
	host.checks.visible_victory=game.world.kingdom.military.battle.result=="won";await shot("android-army-victory")
	scene.go_home();host.checks.claim19=K.claim(game.world,"main_19");host.checks.camp_entry=game.enter_army("camp");game.army_scene.frozen=true
	game.checkpoint("army-qa-reopen");host.checks.active_save=Persistence.load_world(game.save_path).kingdom==game.world.kingdom
	await shot("android-army-camp");host.publish("army_complete",{"all_passed":not host.checks.values().has(false),"profile":profile})
