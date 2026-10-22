extends SceneTree

var passed = 0
var failed = 0
const SLOT = "user://phase4-world.json"
const DIAG = "user://phase4-diagnostics.json"

func verify(value: bool, message: String) -> void:
	if value: passed += 1; print("PASS: ", message)
	else: failed += 1; printerr("FAIL: ", message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var original_save = FileAccess.get_file_as_string(Persistence.PATH) if FileAccess.file_exists(Persistence.PATH) else ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SLOT + suffix): DirAccess.remove_absolute(SLOT + suffix)
	var w = WorldGen.generate(2026, "Private test name")
	verify(Persistence.save_world(w, SLOT), "New beta save commits a verified file")
	var first = Persistence.load_world(SLOT)
	w.tick = 10
	Persistence.save_world(w, SLOT)
	verify(Persistence.read_checked(SLOT + ".bak").tick == first.tick, "Backup retains previous committed generation")
	var f = FileAccess.open(SLOT, FileAccess.WRITE)
	f.store_string("interrupted primary")
	f.close()
	var recovered = Persistence.load_world(SLOT)
	verify(recovered.tick == first.tick and Persistence.last_recovery == "backup", "Corrupt primary recovers healthy backup")
	w.tick = 20
	Persistence.save_world(w, SLOT)
	verify(Persistence.read_checked(SLOT + ".bak").tick == first.tick, "Saving over corruption never destroys healthy backup")
	Persistence.save_world(w, SLOT + ".tmp")
	DirAccess.remove_absolute(SLOT)
	DirAccess.remove_absolute(SLOT + ".bak")
	verify(Persistence.has_save(SLOT) and Persistence.load_world(SLOT).tick == 20 and Persistence.last_recovery == "interrupted_write", "Complete interrupted temporary write can restore a missing primary")
	verify(Persistence.load_world(SLOT, false).is_empty(), "Explicit primary-only read never silently uses recovery")
	for version in ["02", "03"]:
		var legacy = Persistence.load_world("res://tests/fixtures/planet-v" + version + ".json", false)
		verify(not legacy.is_empty() and legacy.version == 1 and legacy.creatures[0].has("identity"), "Actual 0." + version.right(1) + " fixture migrates without losing its world")
	var invalid = w.duplicate(true)
	invalid.creatures[0].hunger = INF
	verify(not Persistence.validate(invalid), "Non-finite creature state cannot be committed")
	invalid = w.duplicate(true)
	invalid.user_paused = "false"
	verify(not Persistence.validate(invalid), "Malformed pause metadata is rejected")
	var a = WorldGen.generate(188, "Replay")
	a.saved_at = 1000
	var b = a.duplicate(true)
	var direct = Persistence.offline(a, 1000 + 86400)
	var job = Persistence.offline_begin(b, 1000 + 86400)
	while not Persistence.offline_step(job, 7): pass
	var sliced = Persistence.offline_finish(job)
	verify(a == b and direct == sliced, "Sliced replay exactly matches all 480 synchronous ticks and RNG")
	var frozen = WorldGen.generate(2026, "Paused")
	frozen.user_paused = true
	frozen.saved_at = 1000
	verify(Persistence.offline(frozen, 99999).ticks == 0 and frozen.tick == 0, "Explicit world pause persists across offline restoration")
	var d = LocalDiagnostics.new()
	d.configure(DIAG, "simulated")
	d.clear()
	d.begin()
	d.advance(1)
	d.record("first_power", 4, true)
	d.record("first_power", 4, true)
	verify(d.data.events.filter(func(e): return e.event == "first_power").size() == 1, "Diagnostics records first actions once")
	d.record("Private test name")
	d.data.events[0].planet_name = "DO_NOT_EXPORT"
	var export_text = d.export_feedback()
	verify(not export_text.contains("DO_NOT_EXPORT") and not export_text.contains("Private test name") and not export_text.contains("planet_name"), "Export whitelist excludes personal names and injected fields")
	verify(d.feedback().events.all(func(e): return e.source == "simulated"), "Simulated diagnostics are explicitly distinguished from players")
	for i in range(240): d.record("save_completed")
	verify(d.data.events.size() == 200, "Local diagnostics remain bounded")
	d.finish()
	verify(not FileAccess.file_exists(DIAG + ".open") and d.data.events.back().event == "session_ended", "Clean session records duration and removes open marker")
	d.begin()
	var after_kill = LocalDiagnostics.new()
	after_kill.configure(DIAG, "simulated")
	after_kill.begin()
	verify(after_kill.data.events.any(func(e): return e.event == "unclean_previous_session"), "Unexpected termination is recorded as unclean, without inventing a crash cause")
	after_kill.clear()
	verify(not FileAccess.file_exists(DIAG) and not FileAccess.file_exists(DIAG + ".feedback.json") and after_kill.data.events.is_empty(), "Clear removes diagnostic events, marker and export only")
	after_kill.enabled = false
	after_kill.record("first_power")
	verify(after_kill.data.events.is_empty(), "Disabled diagnostics records nothing")
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test_session = true
	root.add_child(game)
	current_scene = game
	verify(game.world.is_empty() and not game.view.is_processing() and game.view.terrain.rebuilds == 0, "Start screen performs no unused planet generation or mesh rebuild")
	game.save_path = SLOT
	game.diagnostics.configure(DIAG, "simulated")
	game.diagnostics.clear()
	game.new_planet(2026, "Never exported name", false)
	game.ui.close()
	await process_frame
	await process_frame
	verify(not game.world.is_empty() and game.view.visible and game.view.terrain.rebuilds == 1, "A named world initializes once and activates the real renderer")
	var props = game.view.inhabitants.props.get_children()
	var count_before = game.view.inhabitants.props_created
	game.world.tick += 1
	game.view.inhabitants.sync(game.world)
	verify(game.view.inhabitants.props_created == count_before and game.view.inhabitants.props.get_children() == props, "Unchanged habitats retain existing scene objects")
	var menu_point = game.ui.root.get_node("Menu").get_global_rect().get_center()
	var start_pan = game.view.pan
	var touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = menu_point
	touch.pressed = true
	game._input(touch)
	verify(game.touch_points.is_empty(), "Touch beginning on UI never joins the world pinch gesture")
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = menu_point
	press.pressed = true
	game._input(press)
	game._unhandled_input(press)
	var motion = InputEventMouseMotion.new()
	motion.relative = Vector2(100, 60)
	game._unhandled_input(motion)
	verify(game.view.pan == start_pan and not game.dragging, "Dragging out of a UI control cannot pan the world")
	press.position = Vector2(330, 550)
	game._input(press)
	game._unhandled_input(press)
	game._unhandled_input(motion)
	verify(game.view.pan != start_pan, "A fresh world drag still pans after UI interaction")
	game.ui.menu()
	game.ui.settings()
	game.navigate_back()
	verify(game.ui.page == "menu", "Device back returns from settings to planet menu")
	game.has_player_world = true
	game.navigate_back()
	verify(not game.in_menu and game.touch_points.is_empty() and not game.dragging, "Back closes menu and clears stale gestures")
	game.ui.follow_chapter()
	game.touch_world(game.view.screen_point(game.world.cells[game.view.selected]))
	game.advance_tick()
	game.ui.follow_chapter()
	game.ui.follow_chapter()
	game.touch_world(game.view.screen_point(game.world.cells[game.view.selected]))
	for i in range(4): game.advance_tick()
	verify(game.world.living.gifts >= 2 and game.world.living.findings.has("friendship") and game.world.living.observed.size() > 0, "Opening interactions still produce real rain, discovery and friendship")
	game.ui.world_pulse()
	verify(game.ui.page == "pulse" and game.in_menu, "Longer-session choices describe current world state")
	game.ui.close()
	game.is_test_session = false
	game.diagnostics.enabled = true
	game.onboarding_live = true
	game.advance_tick()
	verify(game.diagnostics.data.events.any(func(e): return e.event == "onboarding_completed"), "Actual scene actions can record onboarding completion")
	game.ui.menu()
	var latest = Persistence.load_world(SLOT)
	verify(latest.tick == game.world.tick and latest.living.findings == game.world.living.findings, "Opening a menu checkpoints recent world changes")
	game.world.energy = 53
	game._notification(NOTIFICATION_APPLICATION_PAUSED)
	verify(game.suspended and Persistence.load_world(SLOT).energy == 53 and not game.diagnostics.running, "Backgrounding from a menu saves world state and ends the foreground session")
	await game.resume_session()
	verify(not game.suspended and game.in_menu and game.ui.page == "menu", "Brief resume preserves open UI without replaying active time")
	game.ui.close()
	game.paused = true
	game.suspend_session()
	var paused_tick = int(game.world.tick)
	await game.resume_session(float(game.world.saved_at) + 7200)
	verify(game.paused and game.world.tick == paused_tick, "Background/resume respects explicit pause")
	game.paused = false
	game.world.user_paused = false
	game.world.saved_at = 1000
	game.suspended = true
	await game.resume_session(1180)
	verify(game.world.tick == paused_tick + 3 and not game.loading, "Longer resume uses real sliced offline ticks once")
	game.ui.close()
	game.world.saved_at = 1000
	Persistence.save_world(game.world, SLOT)
	var saved = Persistence.load_world(SLOT)
	game.world.name = "Unsaved replacement"
	await game.restore()
	verify(game.world.name == saved.name and not game.loading and not game.in_menu, "Save/load restores the committed planet through staged initialization")
	verify(game.pipeline.has("offline_peak_slice_ms") and game.pipeline.restore_parse_ms >= 0, "Initialization and replay timings are measured")
	game.ui.beta_tools()
	game.ui.feedback_preview()
	verify(game.ui.page == "beta" and game.in_menu, "Feedback preview is available without sending anything")
	game.is_test_session = true
	game.diagnostics.finish()
	game.in_menu = true
	var player_after = FileAccess.get_file_as_string(Persistence.PATH) if FileAccess.file_exists(Persistence.PATH) else ""
	verify(player_after == original_save, "Entire beta integration run preserves the real player save bytes")
	print("PHASE4_RESULT: ", passed, " passed, ", failed, " failed")
	quit(0 if failed == 0 else 1)
