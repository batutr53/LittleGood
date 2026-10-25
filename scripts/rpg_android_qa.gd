extends Node
var game
var host
func settle():
	await get_tree().process_frame;await get_tree().process_frame;await RenderingServer.frame_post_draw
func shot(name):
	await settle();get_viewport().get_texture().get_image().save_png("user://"+name+".png")
func profile(fps: int) -> Dictionary:
	game.view.set_quality(fps==30);await get_tree().create_timer(5 if fps==60 else 2).timeout
	var samples=[];var process_samples=[];var world_samples=[];var started=Time.get_ticks_usec();var previous=started
	while Time.get_ticks_usec()-started<5000000:
		await get_tree().process_frame;var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now;process_samples.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000);world_samples.append(game.view.frame_cpu_ms)
	samples.sort();process_samples.sort();world_samples.sort()
	return {"scene":"paused_home_with_ambient_animation","target":fps,"fps":samples.size()*1000000.0/(Time.get_ticks_usec()-started),"p95_ms":samples[int(samples.size()*.95)],"process_cpu_p95_ms":process_samples[int(process_samples.size()*.95)],"world_update_cpu_p95_ms":world_samples[int(world_samples.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_memory_mb":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0,"memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0}
func run():
	game.is_test_session=true;game.save_path="user://rpg-qa-only.json";var w=Persistence.load_world("user://rpg-fixture.json")
	host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("rpg_failed");return
	game.world=w;game.view.world=w;game.paused=true;game.has_player_world=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await shot("rpg-android-home")
	host.checks.landscape=game.get_viewport_rect().size.x>game.get_viewport_rect().size.y
	var profiles=[await profile(60),await profile(30)];game.view.set_quality(false)
	game.ui.premium.route("inventory");await shot("rpg-android-inventory")
	host.checks.inventory_visible=is_instance_valid(game.ui.modal)
	preload("res://scripts/rpg_progression.gd").switch(w,"mage");game.ui.premium.route("inventory");await shot("rpg-android-mage")
	host.checks.class_switch=w.kingdom.adventure.hero.get("class")=="mage"
	host.checks.save=Persistence.save_world(w,game.save_path)
	var loaded=Persistence.load_world(game.save_path);host.checks.restore=not loaded.is_empty() and loaded.rpg.active=="mage"
	game.ui.close()
	host.checks.adventure_entry=game.enter_adventure("wildwood")
	if host.checks.adventure_entry:await shot("rpg-android-adventure");game.adventure_scene.go_home()
	host.publish("rpg_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"source":"actual_android_emulator_render_with_programmatic_model_actions_no_native_input_claim"})
