extends Node

# Debug-only, private-file-triggered harness. All writes use QA slots, even in the main APK.
var game: Node
var options: Dictionary
var checks: Dictionary = {}

func _ready() -> void:
	run.call_deferred()

func publish(stage: String, extra: Dictionary = {}) -> void:
	var report = {"stage": stage, "source": "simulated_android_qa", "checks": checks, "viewport": [game.get_viewport_rect().size.x, game.get_viewport_rect().size.y]}
	report.merge(extra,true)
	var f = FileAccess.open("user://phase4_qa_status.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report))
	f.close()

func find_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found = find_text(child, text)
		if found: return found
	return null

func point(control: Control) -> Array:
	var p = control.get_global_rect().get_center()
	return [p.x, p.y]

func point_at(pos: Vector2) -> Array:return [pos.x,pos.y]

func run() -> void:
	game = get_parent()
	game.save_path = "user://beta-qa-world.json"
	game.diagnostics.configure("user://beta-qa-diagnostics.json", "simulated")
	game.is_test_session = false
	game.ui.language = "en"
	game.ui.build()
	game.ui.main_menu()
	await get_tree().process_frame
	if options.get("phase", "new")=="rpg":
		var qa=preload("res://scripts/rpg_android_qa.gd").new();qa.game=game;qa.host=self;add_child(qa);await qa.run();return
	if options.get("phase", "new") in ["warrior_v4","warrior_v4_reopen","warrior_v4_profile"]:
		var qa=preload("res://scripts/warrior_qa.gd").new();qa.game=game;qa.host=self;add_child(qa);await qa.run();return
	if options.get("phase", "new") in ["sanctuary","sanctuary_reopen"]:
		var qa=preload("res://scripts/sanctuary_qa.gd").new();qa.game=game;qa.host=self;add_child(qa)
		game.view.set_quality(int(options.get("fps",60))==30);await qa.run();return
	if options.get("phase", "new") in ["desert","desert_reopen"]:
		var qa=preload("res://scripts/desert_qa.gd").new();qa.game=game;qa.host=self;add_child(qa)
		game.view.set_quality(int(options.get("fps",60))==30);await qa.run();return
	if options.get("phase", "new") in ["regions","regions_reopen"]:
		var qa=preload("res://scripts/regions_qa.gd").new();qa.game=game;qa.host=self;add_child(qa)
		game.view.set_quality(int(options.get("fps",60))==30);await qa.run();return
	if options.get("phase", "new") in ["trade","trade_reopen","trade_profile"]:
		var qa=preload("res://scripts/trade_qa.gd").new();qa.game=game;qa.host=self;add_child(qa)
		game.view.set_quality(int(options.get("fps",60))==30);await qa.run();return
	if options.get("phase", "new") in ["army","army_reopen"]:
		var qa=preload("res://scripts/military_qa.gd").new();qa.game=game;qa.host=self;add_child(qa)
		Engine.max_fps=int(options.get("fps",60));await qa.run();return
	if options.get("phase", "new")=="adventure_reopen":
		var expected=Persistence.load_world(game.save_path);await game.restore()
		checks.real_scene_restored=is_instance_valid(game.adventure_scene) and game.world.kingdom.adventure.run.active
		if is_instance_valid(game.adventure_scene):game.adventure_scene.frozen=true
		checks.exact_adventure_restored=game.world.kingdom==expected.kingdom
		checks.home_preserved=game.world.cells==expected.cells and game.world.tick==expected.tick
		await get_tree().create_timer(.4).timeout;await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://android-adventure-resumed.png")
		publish("adventure_reopened",{"all_passed":not checks.values().has(false),"source":"external_process_restart_real_restore"});return
	if options.get("phase", "new") in ["adventure","adventure_profile"]:
		var qa=preload("res://scripts/adventure_qa.gd").new();qa.game=game;qa.host=self;add_child(qa);await qa.run();return
	if options.get("phase", "new")=="industry":
		var qa=preload("res://scripts/industry_qa.gd").new();add_child(qa);qa.game=game;qa.directory="user://"
		var result=await qa.run();checks=result.checks
		var I=preload("res://scripts/industry.gd");var worker=int(game.world.kingdom.workers[0].id)
		game.realm_ui.choose_tool(worker);await get_tree().create_timer(.4).timeout
		publish("industry_touch_ready",{"unequip":point(find_text(game.ui.modal,"Unequip · return to inventory"))})
		while not FileAccess.file_exists("user://industry_unequipped"):await get_tree().process_frame
		checks.adb_unequipped=I.tool(game.world,worker).is_empty()
		game.realm_ui.choose_tool(worker);await get_tree().create_timer(.4).timeout
		publish("industry_equip_ready",{"equip":point(qa.button(game.ui.modal,"Forester’s Axe #"))})
		while not FileAccess.file_exists("user://industry_equipped"):await get_tree().process_frame
		checks.adb_equipped=not I.tool(game.world,worker).is_empty();game.checkpoint("industry-qa")
		checks.adb_equipment_persisted=Persistence.load_world(game.save_path).kingdom.industry.equipped==game.world.kingdom.industry.equipped
		result.checks=checks;result.all_passed=not checks.values().has(false);publish("industry_complete",result)
		return
	if options.get("phase", "new")=="kingdom":
		var qa=preload("res://scripts/kingdom_qa.gd").new();add_child(qa);qa.game=game;qa.directory="user://"
		var result=await qa.run();checks=result.checks
		game.ui.close();game.realm_ui.begin("build","house")
		await get_tree().create_timer(.7).timeout
		var before=game.world.kingdom.buildings.size();var room=preload("res://scripts/kingdom.gd").capacity(game.world)
		publish("kingdom_touch_ready",{"target":point_at(game.view.screen_point(game.world.cells[game.realm_ui.cell])),"confirm":point(find_text(game.realm_ui.panel,"Confirm"))})
		while not FileAccess.file_exists("user://phase085_touch_continue"):await get_tree().process_frame
		checks.adb_construction_started=game.world.kingdom.buildings.size()==before+1
		game.realm_ui.finish()
		for i in range(5):game.advance_tick()
		checks.adb_house_changes_capacity=preload("res://scripts/kingdom.gd").capacity(game.world)==room+3
		game.checkpoint("qa");checks.adb_house_persisted=Persistence.load_world(game.save_path).kingdom.buildings.size()==before+1
		result.checks=checks;result.all_passed=not checks.values().has(false);publish("kingdom_complete",result)
		return
	if options.get("phase", "new") == "customization":
		var custom_qa=preload("res://scripts/cosmetic_qa.gd").new();add_child(custom_qa);custom_qa.game=game;custom_qa.image_dir="user://"
		var result=await custom_qa.run();checks=result.checks
		game.decorator.begin("flowers")
		var tile=-1
		for i in range(game.world.cells.size()):
			var pos=game.view.screen_point(game.world.cells[i])
			if preload("res://scripts/cosmetics.gd").valid_place(game.world,"flowers",i) and pos.x>100 and pos.x<620 and pos.y>420 and pos.y<900:tile=i;break
		await get_tree().process_frame
		var before=game.world.wardrobe.placements.size()
		publish("customization_touch_ready",{"tile":point_at(game.view.screen_point(game.world.cells[tile])),"place":point(find_text(game.decorator.panel,"Place")),"fixture":result})
		while not FileAccess.file_exists("user://phase8_touch_continue"):await get_tree().process_frame
		checks.adb_decoration_placed=game.world.wardrobe.placements.size()==before+1
		game.decorator.finish()
		checks.adb_decoration_persisted=Persistence.load_world(game.save_path).wardrobe.placements.size()==before+1
		result.checks=checks;result.all_passed=not checks.values().has(false)
		publish("customization_complete",result)
		return
	if options.get("phase", "new") == "offline_shutdown":
		game.is_test_session=false
		game.new_planet(2026,"Offline after shutdown",false)
		game.has_player_world=true
		game.online.endpoint="http://10.0.2.2:5087"
		var r=await game.online.call_api(HTTPClient.METHOD_GET,"/me")
		checks.server_actually_unreachable=not r.ok and r.status==0
		var tick=game.world.tick
		for i in range(12):game.advance_tick()
		checks.offline_simulation=game.world.tick>tick
		var target=game.world.creatures[0].cell
		checks.offline_power=Powers.apply(game.world,0,target)
		checks.offline_save=game.checkpoint()
		checks.offline_load=Persistence.load_world(game.save_path).get("name","")=="Offline after shutdown"
		game.ui.close()
		publish("offline_complete",{"source":"real_backend_stopped_android_qa"})
		return
	if options.get("phase", "new") == "online":
		game.is_test_session=true
		var online_qa=preload("res://scripts/online_qa.gd").new()
		add_child(online_qa)
		online_qa.game=game
		online_qa.endpoint="http://10.0.2.2:5087"
		online_qa.image_dir="user://"
		var result=await online_qa.run()
		checks=result.checks
		publish("online_complete",result)
		return
	if options.get("phase", "new") == "social_dialogs":
		game.new_planet(42,"PickerQA",true)
		game.showcases.directory = "user://beta-picker-showcases"
		var filename = "LittleGod-QA-"+str(Time.get_ticks_usec())+".lgplanet"
		game.ui.export_planet_dialog(game.showcases.project(game.world),filename)
		publish("json_dialog_ready",{"filename":filename})
		while not FileAccess.file_exists("user://phase6_qa_import"):
			await get_tree().process_frame
		game.ui.import_planet_dialog()
		publish("import_dialog_ready")
		while game.showcases.entries().is_empty():
			await get_tree().process_frame
		checks.native_json_import = game.showcases.get_planet(game.showcases.entries()[0]).planet.name == "PickerQA"
		publish("social_dialogs_complete")
		return
	if options.get("phase", "new") == "reopen":
		await game.restore()
		checks.reopened_saved_world = game.world.get("name") == "BetaQA" and game.has_player_world
		checks.power_survived = int(game.world.living.gifts) >= 1
		checks.diagnostics_simulated = game.diagnostics.feedback().events.all(func(e): return e.source == "simulated")
		game.ui.close()
		game.view.set_quality(false)
		checks.normal_mode = Engine.max_fps == 60
		game.view.set_quality(true)
		checks.battery_saver = Engine.max_fps == 30
		game.view.set_quality(false)
		game.ui.menu()
		checks.menu_checkpoint = Persistence.load_world(game.save_path).tick == game.world.tick
		publish("complete", {"tick": game.world.tick, "energy": game.world.energy})
		while not FileAccess.file_exists("user://phase5_qa_back"):
			await get_tree().process_frame
		checks.adb_back = not game.in_menu
		# Synthetic engine events on Android validate the gesture handler; they
		# are explicitly separate from the external ADB touch checks above.
		var zoom = game.view.zoom
		for i in range(2):
			var touch = InputEventScreenTouch.new()
			touch.index = i; touch.pressed = true
			touch.position = Vector2(280 + i * 160, 590)
			game._input(touch)
		var drag = InputEventScreenDrag.new()
		drag.index = 1; drag.position = Vector2(500, 590); drag.relative = Vector2(60,0)
		game._input(drag)
		checks.android_engine_pinch = game.view.zoom > zoom
		game.reset_gesture()
		for i in range(120): game.advance_tick()
		game.ui.refresh()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var hud = game.get_viewport().get_texture().get_image()
		var ratio = Vector2(hud.get_size())/game.get_viewport_rect().size
		var icons_present = 0
		for control in game.ui.root.get_children():
			if not control is TextureRect: continue
			var area = control.get_global_rect()
			var bright = 0
			for y in range(int(area.position.y*ratio.y),int(area.end.y*ratio.y)):
				for x in range(int(area.position.x*ratio.x),int(area.end.x*ratio.x)):
					var pixel = hud.get_pixel(x,y)
					if pixel.r>.6 and pixel.g>.6: bright += 1
			if bright>4: icons_present += 1
		checks.android_power_icons_after_updates = icons_present == 6
		await game.ui.capture_postcard()
		checks.android_postcard = game.ui.save_postcard("user://beta-postcard.png")
		var shared = preload("res://scripts/planet_showcase.gd")
		var encoded = shared.encode(game.world)
		game.showcases.directory = "user://beta-qa-showcases"
		var id = game.ui.import_planet_text(encoded)
		checks.android_showcase_roundtrip = not id.is_empty() and game.showcases.get_planet(id).planet.name == "BetaQA"
		checks.android_visit = game.visit_planet(game.showcases.get_planet(id),id)
		# Entering a visit deliberately checkpoints the player's current world.
		# Freeze the bytes AFTER that checkpoint, before exercising visit guards.
		var saved = FileAccess.get_file_as_bytes(game.save_path)
		var imported_bytes = FileAccess.get_file_as_bytes(game.showcases.directory.path_join(id+".lgplanet"))
		var frozen = game.world.duplicate(true)
		game.advance_tick();game.schedule_save();game.checkpoint()
		game.suspend_session();await game.resume_session(Time.get_unix_time_from_system()+86400)
		checks.android_visit_readonly = game.world == frozen and FileAccess.get_file_as_bytes(game.save_path)==saved
		checks.android_import_unchanged = FileAccess.get_file_as_bytes(game.showcases.directory.path_join(id+".lgplanet"))==imported_bytes
		game.ui.visit_menu();game.navigate_back()
		checks.android_visit_return = not game.visiting and game.world.name=="BetaQA" and not game.world.get("_read_only",false)
		checks.android_reaction = game.showcases.react(id,1) and game.showcases.reaction(id)==1
		var cr = game.world.creatures[0]
		checks.android_favorite = preload("res://scripts/world_connections.gd").favorite_creature(game.world,cr)
		game.ui.neighbors();game.ui.wonders();game.ui.planet_profile()
		publish("back_complete")
		if options.get("export", false):
			while not FileAccess.file_exists("user://phase5_qa_export"):
				await get_tree().process_frame
			game.ui.export_postcard()
		return
	checks.fresh_slot = not Persistence.has_save(game.save_path)
	find_text(game.ui.root, game.ui.t("new")).pressed.emit()
	game.ui.modal.find_child("PlanetName", true, false).text = "BetaQA"
	game.ui.modal.find_child("WorldSeed", true, false).text = "2026"
	find_text(game.ui.root, game.ui.t("create")).pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	checks.created_from_form = game.world.name == "BetaQA" and game.world.seed == 2026
	checks.initial_save = not Persistence.load_world(game.save_path).is_empty()
	var zoom_before = game.view.zoom
	var pan_before = game.view.pan
	publish("touch_ready", {"plus": point(game.ui.root.get_node("Plus")), "rain": point(game.ui.power_buttons[4]), "world": [360, game.view.origin.y], "drag": [[300, game.view.origin.y], [350, game.view.origin.y + 20]]})
	var until = Time.get_ticks_msec() + 30000
	while not FileAccess.file_exists("user://phase4_qa_continue") and Time.get_ticks_msec() < until:
		await get_tree().process_frame
	checks.adb_zoom = game.view.zoom > zoom_before
	checks.adb_pan = game.view.pan.distance_to(pan_before) > 10
	checks.adb_power = int(game.world.living.gifts) >= 1 and int(game.world.weather) == 1
	checks.adb_feedback_sample = game.input_feedback_ms >= 0
	game.ui.menu()
	checks.saved_from_menu = Persistence.load_world(game.save_path).living.gifts == game.world.living.gifts
	game.suspend_session()
	checks.background_checkpoint = not game.diagnostics.running and not Persistence.load_world(game.save_path).is_empty()
	publish("ready_to_restart", {"tick": game.world.tick, "gifts": game.world.living.gifts, "handler_to_frame_ms":game.input_feedback_ms})
