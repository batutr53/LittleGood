extends SceneTree
const E=preload("res://scripts/estate.gd")
var game
var checks={}
func _initialize():call_deferred("run")
func settle():
	for i in range(6):await process_frame
	await RenderingServer.frame_post_draw
func shot(name):
	await settle();checks["capture_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/estate/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/estate")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://estate-visual.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");E.start(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();game.view.invalidate()
	var b=w.kingdom.buildings.filter(func(item):return item.kind=="lumber")[0];w.kingdom.stock.wood=0;E.deposit(w,b,"wood",6000)
	for extent in [Vector2i(1280,720),Vector2i(960,540),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();game.ui.build();game.ui.close();game.view.zoom=.95;game.view.display_zoom=.95;game.view.pan=-game.view.project(w.cells[int(b.cell)])*.95;game.view.display_pan=game.view.pan
		await shot("village-"+str(extent.x));game.ui.premium.route("estate");await shot("expand-"+str(extent.x));checks[str(extent.x)+"_panel_bounds"]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.get_global_rect());game.ui.close()
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720);game.ui.build();game.ui.close();game.view.estate_layer.land_mode=false;await settle()
	var before=int(w.kingdom.stock.wood);var point=game.view.estate_layer.bubble(b);game.touch_world(point);checks.real_icon_click=int(w.kingdom.stock.wood)==before+6000;await shot("harvest-feedback")
	var p=E.candidates(w)[0];checks.expand=E.expand(w,p);game.view.invalidate();game.view.estate_layer.land_mode=true;game.view.zoom=.3;game.view.display_zoom=.3;game.view.pan=Vector2.ZERO;game.view.display_pan=Vector2.ZERO;await shot("expanded-world")
	game.view.set_quality(false);await settle()
	var frames=[];var costs=[];var started=Time.get_ticks_usec();var previous=started
	while Time.get_ticks_usec()-started<3000000:
		await process_frame;var now=Time.get_ticks_usec();frames.append((now-previous)/1000.0);previous=now;costs.append(game.view.frame_cpu_ms)
	frames.sort();costs.sort();var result={"checks":checks,"all_passed":not checks.values().has(false),"fps":frames.size()*1000000.0/(Time.get_ticks_usec()-started),"p95_frame_ms":frames[int(frames.size()*.95)],"world_cpu_p95_ms":costs[int(costs.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_memory_mb":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0,"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"cells":w.cells.size()}
	var f=FileAccess.open("res://builds/estate/visual.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("ESTATE_VISUAL "+JSON.stringify(result));quit(0 if result.all_passed else 1)
