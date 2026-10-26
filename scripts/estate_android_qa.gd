extends "res://scripts/rpg_android_qa.gd"
func run():
	var E=load("res://scripts/estate.gd");game.is_test_session=true;game.save_path="user://estate-android-qa.json"
	var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("estate_failed");return
	E.start(w);game.world=w;game.view.world=w;game.paused=true;game.has_player_world=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();game.view.invalidate()
	var b=w.kingdom.buildings.filter(func(item):return item.kind=="lumber")[0];w.kingdom.stock.wood=0;E.deposit(w,b,"wood",6000);game.ui.refresh();game.view.zoom=.95;game.view.pan=-game.view.project(w.cells[int(b.cell)])*.95
	await get_tree().create_timer(1).timeout;await shot("estate-android-village")
	host.checks.large_world=w.cells.size()==1024
	game.touch_world(game.view.estate_layer.bubble(b));host.checks.harvest=w.kingdom.stock.wood==6000;await shot("estate-android-harvest")
	game.ui.premium.route("estate");await shot("estate-android-panel");game.ui.close()
	host.checks.expansion=E.expand(w,E.candidates(w)[0]) and w.cells.size()==1088;game.view.invalidate();game.view.zoom=.3;game.view.pan=Vector2.ZERO;game.view.estate_layer.land_mode=true
	await get_tree().create_timer(1).timeout;await shot("estate-android-world")
	host.checks.save=Persistence.save_world(w,game.save_path);var loaded=Persistence.load_world(game.save_path);host.checks.restore=not loaded.is_empty() and loaded.estate==w.estate and loaded.cells.size()==1088
	var profiles=[await profile(60),await profile(30)];game.view.set_quality(false)
	host.publish("estate_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"source":"actual_android_emulator_render_with_programmatic_model_actions_no_native_input_claim"})
