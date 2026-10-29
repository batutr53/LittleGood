extends SceneTree
var game
var checks={}
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame
func click(b):
	var e=InputEventMouseButton.new();e.position=b.get_global_rect().get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;Input.parse_input_event(e);await process_frame;e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await settle()
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/simple-ui");DirAccess.make_dir_recursive_absolute("res://builds/simple-ui")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://simple-army-private.json";root.add_child(game);current_scene=game;await settle()
	for extent in [Vector2i(960,540),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;game.world=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.view.world=game.world;game.has_player_world=true;game.ui.language="tr";game.ui.build();game.ui.close();await settle()
		checks["entry_"+str(extent.x)]=game.enter_army("raid");await settle();var a=game.army_scene
		if not is_instance_valid(a):quit(1);return
		for key in a.buttons:checks["button_fits_"+str(extent.x)+key]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(a.buttons[key].get_global_rect())
		await click(a.buttons.hold);checks["native_order_"+str(extent.x)]=game.world.kingdom.military.battle.order=="hold"
		await click(a.buttons.defensive);checks["native_formation_"+str(extent.x)]=game.world.kingdom.military.formation=="defensive" and a.buttons.defensive.button_pressed
		await click(a.buttons.pause);checks["native_pause_"+str(extent.x)]=a.frozen;await RenderingServer.frame_post_draw;checks["capture_"+str(extent.x)]=root.get_texture().get_image().save_png("res://docs/screenshots/simple-ui/army-"+str(extent.x)+".png")==OK
		checks["save_valid_"+str(extent.x)]=Persistence.validate(game.world);a.queue_free();game.army_scene=null;await settle()
	var result={"all_passed":not checks.values().has(false),"count":checks.size(),"checks":checks};var f=FileAccess.open("res://builds/simple-ui/army.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("SIMPLE_ARMY "+JSON.stringify(result));quit(0 if result.all_passed else 1)
