extends SceneTree
var game
var checks={}
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame
func click(c):
	var point=c.get_global_rect().get_center();var e=InputEventMouseMotion.new();e.position=point;Input.parse_input_event(e);await process_frame
	var b=InputEventMouseButton.new();b.button_index=MOUSE_BUTTON_LEFT;b.position=point;b.pressed=true;Input.parse_input_event(b);await process_frame;b=b.duplicate();b.pressed=false;Input.parse_input_event(b);await settle()
func fits(c):return Rect2(Vector2.ZERO,Vector2(root.size)).grow(1).encloses(c.get_global_rect())
func shot(name):
	await settle();await RenderingServer.frame_post_draw;checks["capture_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/kingdom-panels/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/kingdom-panels");DirAccess.make_dir_recursive_absolute("res://builds/kingdom-ui")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://kingdom-ui-private.json";root.add_child(game);current_scene=game;await settle()
	game.world=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="tr";game.show_world(true)
	for extent in [Vector2i(960,540),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();game.ui.build();game.ui.close();await settle();await shot("city-"+str(extent.x))
		for route in ["inventory","skills","attributes","quest","map","settings"]:
			game.ui.premium.route(route);await settle();checks[route+"_fits_"+str(extent.x)]=fits(game.ui.modal)
			if route=="inventory":
				checks["comparison_inside_"+str(extent.x)]=game.ui.modal.get_global_rect().encloses(game.ui.premium.rpg.details_window.get_global_rect())
				checks["grid_visible_"+str(extent.x)]=game.ui.premium.scroll.get_global_rect().encloses(game.ui.modal.find_child("InventoryGrid",true,false).get_global_rect())
			if route=="settings":
				var before=game.haptics;await click(game.ui.modal.find_child("Option_haptics",true,false));checks["settings_draft_"+str(extent.x)]=game.haptics==before
			await shot(route+"-"+str(extent.x));await click(game.ui.modal.find_child("SurfaceBack",true,false));checks[route+"_native_close_"+str(extent.x)]=not is_instance_valid(game.ui.modal)
	checks.valid=Persistence.validate(game.world)
	var report={"all_passed":not checks.values().has(false),"count":checks.size(),"checks":checks,"source":"actual rendered Godot at 960x540 and 1600x720; native mouse close and settings draft"};var f=FileAccess.open("res://builds/kingdom-ui/panels.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));print("KINGDOM_UI "+JSON.stringify(report));quit(0 if report.all_passed else 1)
