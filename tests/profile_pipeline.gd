extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var result: Dictionary = {"platform": OS.get_name(), "headless": DisplayServer.get_name() == "headless", "assets": {}, "static_before_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0}
	var retained: Array = []
	for path in ["res://assets/phase2/world-atlas.png", "res://assets/phase2/nunito.ttf", "res://assets/phase2/lora.ttf", "res://assets/phase2/rain-loop.wav"]:
		var cached = ResourceLoader.has_cached(path)
		var start = Time.get_ticks_usec()
		retained.append(load(path))
		result.assets[path.get_file()] = {"ms": (Time.get_ticks_usec() - start) / 1000.0, "already_cached": cached}
	var start = Time.get_ticks_usec()
	var packed = load("res://scenes/main.tscn")
	result.scene_load_ms = (Time.get_ticks_usec() - start) / 1000.0
	start = Time.get_ticks_usec()
	var game = packed.instantiate()
	game.is_test_session = true
	result.instantiate_ms = (Time.get_ticks_usec() - start) / 1000.0
	start = Time.get_ticks_usec()
	root.add_child(game)
	current_scene = game
	result.ready_ms = (Time.get_ticks_usec() - start) / 1000.0
	start = Time.get_ticks_usec()
	var w = WorldGen.generate(2026, "Pipeline test")
	result.world_generation_ms = (Time.get_ticks_usec() - start) / 1000.0
	game.new_planet(2026, "Pipeline test", false)
	game.ui.close()
	await process_frame
	var samples: Array = []
	for i in range(12):
		start = Time.get_ticks_usec()
		game.view.terrain.rebuild(w)
		samples.append((Time.get_ticks_usec() - start) / 1000.0)
	result.terrain_ms = samples
	start = Time.get_ticks_usec()
	Persistence.save_world(w, "user://pipeline-test.json")
	result.save_ms = (Time.get_ticks_usec() - start) / 1000.0
	start = Time.get_ticks_usec()
	var loaded = Persistence.load_world("user://pipeline-test.json", false)
	result.restore_parse_ms = (Time.get_ticks_usec() - start) / 1000.0
	loaded.saved_at = 1000
	start = Time.get_ticks_usec()
	var report = Persistence.offline(loaded, 1000 + 86400)
	result.offline_480_ms = (Time.get_ticks_usec() - start) / 1000.0
	result.offline_ticks = report.ticks
	game.ui.loading_screen()
	var staged = WorldGen.generate(2026, "Staged replay")
	staged.saved_at = 1000
	await game.replay_offline(staged, 1000 + 86400)
	result.staged_offline = game.pipeline.duplicate(true)
	result.static_after_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	game.in_menu = true
	var dest = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "res://builds/phase4/pipeline.json"
	var f = FileAccess.open(dest, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "\t"))
	f.close()
	print(JSON.stringify(result))
	quit()
