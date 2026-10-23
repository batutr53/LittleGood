extends Node

# Debug-only, private-file-triggered harness. All writes use QA slots, even in the main APK.
var game: Node
var options: Dictionary
var checks: Dictionary = {}

func _ready() -> void:
	run.call_deferred()

func publish(stage: String, extra: Dictionary = {}) -> void:
	var report = {"stage": stage, "source": "simulated_android_qa", "checks": checks, "viewport": [game.get_viewport_rect().size.x, game.get_viewport_rect().size.y]}
	report.merge(extra)
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

func run() -> void:
	game = get_parent()
	game.save_path = "user://beta-qa-world.json"
	game.diagnostics.configure("user://beta-qa-diagnostics.json", "simulated")
	game.is_test_session = false
	game.ui.language = "en"
	game.ui.build()
	game.ui.main_menu()
	await get_tree().process_frame
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
