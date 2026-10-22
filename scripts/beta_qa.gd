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
	game.ui.menu()
	checks.saved_from_menu = Persistence.load_world(game.save_path).living.gifts == game.world.living.gifts
	game.suspend_session()
	checks.background_checkpoint = not game.diagnostics.running and not Persistence.load_world(game.save_path).is_empty()
	publish("ready_to_restart", {"tick": game.world.tick, "gifts": game.world.living.gifts})
