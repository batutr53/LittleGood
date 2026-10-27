extends SceneTree
const C=preload("res://scripts/colony.gd")
const K=preload("res://scripts/kingdom.gd")
var game
var checks={}
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame
func shot(name):
	await settle();await RenderingServer.frame_post_draw;checks["image_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/colony/"+name+".png")==OK
func click(control):
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=control.get_global_rect().get_center();e.pressed=true;Input.parse_input_event(e);await settle();e= e.duplicate();e.pressed=false;Input.parse_input_event(e);await settle()
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/colony")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://colony-ui-private.json";root.add_child(game);current_scene=game
	game.world=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.world.kingdom.adventure.run.active=false;load("res://scripts/estate.gd").start(game.world);game.view.world=game.world;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await settle()
	var w=game.world;var p=game.ui.premium;var free=K.assigned(w,0)[0];var id=int(free.id);checks.additive_migration=C.enabled(w);checks.gather=C.start(w,id,"water")
	for i in range(10):w.tick+=1;C.tick(w)
	var snapshot=w.duplicate(true)
	for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle()
		for locale in ["tr","en"]:
			game.ui.language=locale;game.ui.build();p=game.ui.premium
			for route in ["colony","resources","gathering","defense","workers","worker"]:
				p.route(route,id if route=="worker" else 6 if route=="gathering" else 0);await settle();var key=route+"_"+str(extent.x)+"_"+locale;var content=game.ui.modal.find_child("SurfaceContent",true,false)
				checks[key+"_no_scroll"]=content.size.y<=p.scroll.size.y+1;checks[key+"_fits"]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.get_global_rect())
				if locale=="tr" and route in ["colony","workers","gathering","defense"]:await shot(route+"-"+str(extent.x))
	checks.read_only_navigation=w==snapshot
	root.size=Vector2i(1280,720);root.content_scale_size=root.size;game.ui.language="tr";game.ui.build();p=game.ui.premium;p.route("colony");p.route("resources");p.route("gathering",6);await settle();await click(game.ui.modal.find_child("SurfaceBack",true,false));checks.real_x_closes=not game.in_menu and not is_instance_valid(game.ui.modal)
	await settle();checks.no_pets=game.view.inhabitants.animals.all(func(animal):return not animal.visible);var index=w.kingdom.workers.find(free);checks.original_worker_art=game.view.kingdom_layer.workers[index].texture.resource_path.ends_with("hearthkin.svg")
	var job=w.colony.jobs[str(id)];job.progress=4;game.view.kingdom_layer.animate(0);var dest=game.view.project(w.cells[int(job.cell)]);checks.at_real_source=game.view.kingdom_layer.workers[index].position.distance_to(dest)<12
	game.realm_ui.focus(int(job.cell));await settle();game.ui.close();await shot("gathering-world")
	var amount=int(w.colony.stock.water);var overlay=game.view.estate_layer;overlay.collect_worker(id,overlay.worker_bubble(index));checks.collect_feedback=w.colony.stock.water==amount+2000 and not overlay.rewards.is_empty();checks.collect_no_replay=C.collect(w,id)==0
	checks.no_double_job=not C.start(w,id,"fish") and not K.assigned(w,0).has(free);checks.release=C.release(w,id);checks.release_available=K.assigned(w,0).has(free)
	var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];var busy=K.assigned(w,int(farm.id))[0];p.route("worker",int(busy.id));await settle();checks.busy_explained=game.ui.modal.find_children("*","Label",true,false).any(func(label):return label.text.contains("GÖREVDE"));checks.no_hidden_reassignment=not game.ui.modal.find_children("*","Button",true,false).any(func(button):return button.text.begins_with("Ata:"))
	checks.save=Persistence.save_world(w,game.save_path) and not Persistence.load_world(game.save_path).is_empty()
	var report={"count":checks.size(),"checks":checks,"all_passed":not checks.values().has(false)};var f=FileAccess.open("res://docs/benchmarks/colony/ui.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));print("COLONY_UI ",checks.size()," passed=",report.all_passed," failures=",checks.keys().filter(func(k):return not checks[k]));quit(0 if report.all_passed else 1)
