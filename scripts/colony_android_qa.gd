extends "res://scripts/rpg_android_qa.gd"
const C=preload("res://scripts/colony.gd")
const K=preload("res://scripts/kingdom.gd")
func shot(name):
	await settle();host.checks["image_"+name]=get_viewport().get_texture().get_image().save_png("user://"+name+".png")==OK
func run():
	game.is_test_session=true;game.save_path="user://colony-android-private.json";var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("colony_failed");return
	w.kingdom.adventure.run.active=false;load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await settle()
	var p=game.ui.premium;host.checks.additive_migration=C.enabled(w);var worker=K.assigned(w,0)[0];var id=int(worker.id);host.checks.assign=C.start(w,id,"water")
	for i in range(10):w.tick+=1;C.tick(w)
	host.checks.real_output=w.colony.jobs[str(id)].buffer==2000;host.checks.exclusive=not C.start(w,id,"fish") and not K.assigned(w,0).has(worker)
	for route in ["colony","workers","resources","defense"]:
		p.route(route);await settle();host.checks[route+"_no_scroll"]=game.ui.modal.find_child("SurfaceContent",true,false).size.y<=p.scroll.size.y+1;await shot("colony-android-"+route)
	p.route("worker",id);await shot("colony-android-cargo");var point=game.ui.modal.find_child("SurfaceBack",true,false).get_global_rect().get_center()
	host.publish("colony_close_ready",{"run_id":host.options.get("run_id",""),"close_point":[point.x,point.y]})
	var deadline=Time.get_ticks_msec()+20000
	while game.in_menu and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	host.checks.native_x_closes=not game.in_menu and not is_instance_valid(game.ui.modal)
	game.realm_ui.focus(int(w.colony.jobs[str(id)].cell));await settle();game.ui.close();await shot("colony-android-world");var index=w.kingdom.workers.find(worker);var at=game.view.estate_layer.worker_bubble(index);host.checks.world_collect=game.view.estate_layer.pick(at) and w.colony.stock.water==2000;host.checks.no_repeat=C.collect(w,id)==0;host.checks.release=C.release(w,id);host.checks.available=K.assigned(w,0).has(worker)
	host.checks.save=Persistence.save_world(w,game.save_path);var loaded=Persistence.load_world(game.save_path);host.checks.restore=not loaded.is_empty() and loaded.colony==w.colony;host.checks.valid=Persistence.validate(w)
	var profiles=[await profile(60),await profile(30)]
	host.publish("colony_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"source":"actual emulator renders with programmatic model actions, native ADB close tap and world collection hit test; private fixture"})
