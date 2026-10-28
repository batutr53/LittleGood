extends "res://scripts/rpg_android_qa.gd"
var sequence=0
func native(action: String,control: Control,condition: Callable):
	sequence+=1;var at=control.get_global_rect().get_center()
	host.publish("parallel_tap",{"run_id":host.options.run_id,"sequence":sequence,"action":action,"tap_point":[at.x,at.y]})
	var deadline=Time.get_ticks_msec()+15000
	while not condition.call() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	host.checks["native_"+action]=condition.call();await settle()
func run():
	game.is_test_session=true;game.save_path="user://parallel-android-private.json"
	if host.options.get("restore_only",false):
		var restored=Persistence.load_world(game.save_path);host.checks.restore_valid=not restored.is_empty();host.checks.save_bytes=FileAccess.get_file_as_string(game.save_path).sha256_text()==host.options.expected_sha256
		if not restored.is_empty():host.checks.hero_and_city=restored.parallel_play.version==1 and restored.kingdom.adventure.hero.id==1 and not restored.colony.jobs.is_empty()
		host.publish("parallel_restore_complete",{"run_id":host.options.run_id,"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false)});return
	game.new_planet(42,"İlk Gün · Özgür Macera",true);game.ui.language="tr";game.ui.build();game.ui.close();await settle();var w=game.world
	host.checks.city_one=load("res://scripts/kingdom.gd").level(w)==1 and w.kingdom.claimed.is_empty();host.checks.four_heroes=w.rpg.roster.size()==4
	await native("inventory",game.ui.root.find_child("NavInventory",true,false),func():return game.ui.modal!=null and game.ui.premium.current=="inventory");await shot("parallel-android-inventory");game.ui.close();await settle()
	load("res://scripts/colony.gd").ensure(w);var worker=int(w.kingdom.workers[0].id);host.checks.worker=load("res://scripts/colony.gd").start(w,worker,"wood")
	await native("hunts",game.ui.root.find_child("OpenHunts",true,false),func():return game.ui.modal!=null and game.ui.premium.current=="hunts");await shot("parallel-android-hunts")
	await native("destination",host.find_text(game.ui.modal,"Bölgeyi incele / gir"),func():return game.ui.premium.current=="destination")
	await native("enter",host.find_text(game.ui.modal,"Gir: Yabanorman"),func():return is_instance_valid(game.adventure_scene))
	if not is_instance_valid(game.adventure_scene):host.publish("parallel_failed");return
	var a=game.adventure_scene;game.paused=false;var tick=w.tick;var progress=w.colony.jobs[str(worker)].progress
	await get_tree().create_timer(2.3).timeout;host.checks.city_works_in_battle=w.tick>tick and w.colony.jobs[str(worker)].progress>progress
	var mana=load("res://scripts/rpg_progression.gd").selected(w).mana
	await native("skill",a.buttons.skill,func():return load("res://scripts/rpg_progression.gd").selected(w).mana<mana);await shot("parallel-android-battle")
	host.checks.valid_active=Persistence.validate(w);host.checks.save_active=Persistence.save_world(w,game.save_path);var copy=Persistence.load_world(game.save_path);host.checks.restore_active=not copy.is_empty() and copy.kingdom.adventure.run==w.kingdom.adventure.run
	await native("return",a.buttons["return"],func():return not is_instance_valid(game.adventure_scene));await shot("parallel-android-home")
	host.checks.no_story_grants=w.kingdom.claimed.is_empty();host.checks.valid_home=Persistence.validate(w);host.checks.save_home=Persistence.save_world(w,game.save_path)
	host.publish("parallel_complete",{"run_id":host.options.run_id,"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"save_sha256":FileAccess.get_file_as_string(game.save_path).sha256_text(),"source":"actual_android_emulator_first_day_world_with_external_adb_taps"})
