extends SceneTree

var passed = 0
var failed = 0

func verify(value: bool, message: String) -> void:
	if value: passed += 1; print("PASS: ", message)
	else: failed += 1; printerr("FAIL: ", message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.is_test_session = true
	game.new_planet(2026, "Phase2 Test", false)
	game.ui.close()
	await process_frame
	await process_frame
	verify(game.view.terrain.land.mesh.get_surface_count() == 1 and game.view.terrain.water.mesh.get_surface_count() == 1, "Land and water meshes compile and contain geometry")
	verify(game.view.inhabitants.animals.size() == 18, "All six species retain three rendered individuals")
	var selected_cell = 60
	var screen_point = game.view.screen_point(game.world.cells[selected_cell])
	verify(game.view.pick(screen_point) == selected_cell, "World projection and picking agree after terrain rewrite")
	var anchor = Vector2(280, 500)
	var before = (anchor - game.view.origin - game.view.pan) / game.view.zoom
	game.view.zoom_at(anchor, 1.3)
	var after = (anchor - game.view.origin - game.view.pan) / game.view.zoom
	verify(before.distance_to(after) < .001, "Pinch/scroll zoom keeps the chosen world anchor stable")
	var old_zoom = game.view.display_zoom
	game.view._process(1.0 / 60)
	verify(game.view.display_zoom > old_zoom and game.view.display_zoom < game.view.zoom, "Camera zoom interpolates rather than snapping")
	game.power = 0
	var energy = game.world.energy
	for finger in range(2):
		var touch = InputEventScreenTouch.new()
		touch.index = finger
		touch.position = Vector2(300 + finger * 70, 500)
		touch.pressed = true
		game._input(touch)
	var drag = InputEventScreenDrag.new()
	drag.index = 1
	drag.position = Vector2(400, 500)
	game._input(drag)
	for finger in range(2):
		var release = InputEventScreenTouch.new()
		release.index = finger
		release.pressed = false
		game._input(release)
	var mouse_release = InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_LEFT
	mouse_release.position = game.view.screen_point(game.world.cells[selected_cell])
	mouse_release.pressed = false
	game._unhandled_input(mouse_release)
	verify(game.world.energy == energy and game.view.effects.is_empty(), "Finishing a two-finger gesture cannot accidentally cast a power")
	game.touch_world(game.view.screen_point(game.world.cells[selected_cell]))
	verify(game.world.energy == energy - 12 and game.world.cells[selected_cell].biome == 6, "Intentional tap still changes saved terrain and charges spirit")
	game.view.set_quality(true)
	verify(Engine.max_fps == 30, "Battery saver selects the 30 FPS budget")
	game.view.set_quality(false)
	verify(Engine.max_fps == 60, "Smooth mode restores the 60 FPS budget")
	var previous_tick = int(game.world.tick)
	game.last_clock_ms = Time.get_ticks_msec() - 700
	game.accumulator = 1.4
	game._process(.01)
	verify(game.world.tick == previous_tick + 1, "Live clock advances from elapsed monotonic time even on slow frames")
	var loaded = Persistence.load_world("res://tests/fixtures/planet-v1.json", false)
	verify(not loaded.is_empty() and loaded.version == 1, "Phase-one version-one save fixture still loads unchanged")
	if not loaded.is_empty():
		verify(typeof(loaded.tick) == TYPE_INT and typeof(loaded.creatures[0].cell) == TYPE_INT, "JSON integer fields are normalized before resuming simulation")
		var old_population = loaded.settlements[0].population
		var rng = RandomNumberGenerator.new()
		rng.state = int(loaded.rng_state)
		for i in range(100): Ecosystem.tick(loaded, rng); Civilization.tick(loaded)
		verify(Persistence.validate(loaded) and loaded.settlements[0].population > old_population and loaded.discoveries.size() > 0, "Legacy planet actually grows and discovers species after load")
	var w = WorldGen.generate(32458, "Extended simulation")
	var rng = RandomNumberGenerator.new()
	rng.state = int(w.rng_state)
	var start = Time.get_ticks_msec()
	for i in range(10000): Ecosystem.tick(w, rng); Civilization.tick(w)
	verify(Persistence.validate(w) and w.tick == 10000, "Ten-thousand-tick world remains valid")
	verify(w.creatures.size() >= 6 and w.creatures.size() <= 70 and w.events.size() <= 160, "Extended populations and event history stay bounded")
	print("EXTENDED_SIM_MS: ", Time.get_ticks_msec() - start)
	game.in_menu = true
	print("PHASE2_RESULT: ", passed, " passed, ", failed, " failed")
	quit(0 if failed == 0 else 1)
