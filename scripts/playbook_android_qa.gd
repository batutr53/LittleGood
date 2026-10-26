extends "res://scripts/rpg_android_qa.gd"
func run():
	var K=load("res://scripts/kingdom.gd");game.is_test_session=true;game.save_path="user://playbook-android-qa.json"
	var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("playbook_failed");return
	load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.paused=true;game.has_player_world=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();game.view.invalidate()
	var p=game.ui.premium;var before=w.duplicate(true)
	for locale in ["tr","en"]:
		game.ui.language=locale
		for route in ["quest","guide","workers","construction","army","map","menu","army_roster"]:
			p.route(route);await settle();var content=game.ui.modal.find_child("SurfaceContent",true,false)
			host.checks[route+locale+"_no_scroll"]=content.size.y<=p.scroll.size.y+1
			host.checks[route+locale+"_fits"]=get_viewport().get_visible_rect().encloses(game.ui.modal.get_global_rect())
			if locale=="tr":await shot("playbook-android-"+route)
	host.checks.navigation_read_only=w==before
	game.ui.language="tr";var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];var worker=K.assigned(w,int(farm.id))[0];var id=int(worker.id);var old=int(worker.building)
	p.route("worker",id);await settle()
	for b in game.ui.modal.find_children("*","Button",true,false):
		if b.text.begins_with("İnşaatçı"):b.pressed.emit();break
	host.checks.builder_command=int(worker.building)==0
	p.playbook().assign(id,old);host.checks.worker_restored=int(worker.building)==old
	game.ui.close();game.realm_ui.begin("build","house");await shot("playbook-android-placement");host.checks.compact_placement=game.realm_ui.panel.size.y<=game.ui.premium.px(140);game.realm_ui.finish()
	host.checks.valid=Persistence.validate(w);host.checks.save=Persistence.save_world(w,game.save_path);host.checks.restore=not Persistence.load_world(game.save_path).is_empty()
	game.ui.close();var profiles=[await profile(60),await profile(30)];game.view.set_quality(false)
	host.publish("playbook_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"source":"actual_android_emulator_render_with_programmatic_ui_actions_no_native_input_claim"})
