extends "res://scripts/rpg_android_qa.gd"
func run():
	game.is_test_session=true;game.save_path="user://reforge-android-private.json"
	if host.options.get("restore_only",false):
		var saved=Persistence.load_world(game.save_path);host.checks.restore_valid=not saved.is_empty()
		host.checks.same_saved_bytes=FileAccess.get_file_as_string(game.save_path).sha256_text()==str(host.options.get("expected_sha256",""))
		if not saved.is_empty():
			game.world=saved;game.view.world=saved;game.has_player_world=true;game.paused=true;game.ui.build();game.ui.close();game.show_world(true);game.view.invalidate();await settle()
			host.checks.jobs_restored=saved.has("colony") and not saved.colony.jobs.is_empty()
		host.publish("reforge_restore_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false)})
		return
	var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("reforge_failed");return
	var K=load("res://scripts/kingdom.gd");var C=load("res://scripts/colony.gd");load("res://scripts/estate.gd").start(w);C.ensure(w);var worker=0
	for c in w.kingdom.workers:
		if load("res://scripts/military.gd").worker_reserved(w,int(c.id)) or load("res://scripts/trade.gd").worker_reserved(w,int(c.id)):continue
		K.assign(w,int(c.id),0)
		if worker==0:worker=int(c.id)
	host.checks.job_started=C.start(w,worker,"gold");w.kingdom.stock.gold=0
	game.world=w;game.view.world=w;game.has_player_world=true;game.paused=false;game.ui.language="tr";game.ui.build();game.ui.close();game.show_world(true);game.view.invalidate()
	game.ui.premium.route("journey");await settle();var tick=int(w.tick);var job=w.colony.jobs[str(worker)];var angle=game.view.kingdom_layer.workers[0].rotation
	await get_tree().create_timer(2.3).timeout
	host.checks.live_clock=w.tick>tick and game.npc_dialogue_open and game.in_menu and not get_tree().paused
	host.checks.worker_visual=game.view.kingdom_layer.workers[0].rotation!=angle;await shot("reforge-android-dialogue")
	var deadline=Time.get_ticks_msec()+30000
	while job.buffer==0 and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	host.checks.real_production=job.buffer==C.trip_yield(w,worker,"gold");var cargo=int(job.buffer);var gold=int(w.kingdom.stock.gold)
	host.checks.collect_exact=C.collect(w,worker)==cargo and w.kingdom.stock.gold==gold+cargo;host.checks.no_double_collect=C.collect(w,worker)==0
	host.checks.save=Persistence.save_world(w,game.save_path);var restored=Persistence.load_world(game.save_path);host.checks.restore=not restored.is_empty() and restored.colony==w.colony
	game.ui.premium.route("settings");tick=int(w.tick);await get_tree().create_timer(2.2).timeout;host.checks.settings_pauses=w.tick==tick and not game.npc_dialogue_open
	game.ui.premium.route("journey");await settle();var button=game.ui.modal.find_child("SurfaceBack",true,false);var at=button.get_global_rect().get_center()
	host.publish("reforge_close_ready",{"run_id":host.options.get("run_id",""),"close_point":[at.x,at.y]})
	deadline=Time.get_ticks_msec()+15000
	while game.in_menu and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	host.checks.native_close=not game.in_menu and not game.npc_dialogue_open;await shot("reforge-android-world")
	host.checks.valid=Persistence.validate(w);game.paused=true;host.checks.lifecycle_checkpoint=Persistence.save_world(w,game.save_path)
	var profiles=[await profile(60),await profile(30)];game.view.set_quality(false)
	host.publish("reforge_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"save_sha256":FileAccess.get_file_as_string(game.save_path).sha256_text(),"source":"Real Android wall-clock production and native ADB X tap; private fixture; not a full onboarding or portrait HUD test"})
