extends Node2D

@onready var view = $LivingWorld
@onready var ui = $Interface
var audio: Soundscape
var world: Dictionary = {}
var rng = RandomNumberGenerator.new()
var accumulator = 0.0
var autosave_time = 0.0
var speed = 1
var paused = false
var in_menu = true
var power = -1
var dragging = false
var drag_distance = 0.0
var touch_points: Dictionary = {}
var capture_frames = 0
var diagnostic_time = 0.0
var haptics = true
var is_test_session = false
var simulation_total_ms = 0.0
var simulation_peak_ms = 0.0
var simulation_samples = 0
var pinch_cancelled = false
var last_clock_ms = 0
var benchmark_control = false

func _exit_tree() -> void:
	GameArt.foliage_material = null

func _ready() -> void:
	get_window().min_size = Vector2i(360, 640)
	$Atmosphere.size = get_viewport_rect().size
	audio = Soundscape.new()
	add_child(audio)
	ui.game = self
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		ui.language = config.get_value("user", "language", "en")
		audio.set_enabled(config.get_value("user", "sound", true))
		haptics = config.get_value("user", "haptics", true)
		view.set_quality(config.get_value("user", "economy", false))
	world = WorldGen.generate(2026, "Lumi")
	view.world = world
	rng.state = int(world.rng_state)
	ui.build()
	ui.main_menu()
	last_clock_ms = Time.get_ticks_msec()
	if "--capture" in OS.get_cmdline_user_args():
		in_menu = false
		ui.close()
		for i in range(12): advance_tick()
	if OS.is_debug_build() and ("--benchmark" in OS.get_cmdline_user_args() or FileAccess.file_exists("user://phase2_benchmark.json")):
		var options = {}
		if FileAccess.file_exists("user://phase2_benchmark.json"):
			var parser = JSON.new()
			if parser.parse(FileAccess.get_file_as_string("user://phase2_benchmark.json")) == OK and parser.data is Dictionary: options = parser.data
			DirAccess.remove_absolute("user://phase2_benchmark.json")
		is_test_session = true
		new_planet(2026, "Lumi", false)
		ui.close()
		view.set_quality(options.get("economy", "--economy" in OS.get_cmdline_user_args()))
		world.weather = 1
		if options.get("stress", false):
			while world.creatures.size() < 70: world.creatures.append(world.creatures[world.creatures.size() % 18].duplicate(true))
		benchmark_control = options.get("control", false)
		if benchmark_control:
			view.hide()
			view.set_process(false)
			$WorldForeground.hide()
			$WorldForeground.set_process(false)
			$Atmosphere.hide()
			ui.root.hide()
			in_menu = true
		var probe = PerformanceProbe.new()
		probe.duration = options.get("duration", 15)
		if not OS.has_feature("mobile"): probe.destination = "res://builds/phase2/profile-" + ("economy" if view.low_quality else "smooth") + ".json"
		add_child(probe)
	set_process_input(true)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("user", "language", ui.language)
	config.set_value("user", "sound", audio.enabled)
	config.set_value("user", "haptics", haptics)
	config.set_value("user", "economy", view.low_quality)
	config.save("user://settings.cfg")

func new_planet(seed_value: int, planet_name: String, persist: bool = true) -> void:
	world = WorldGen.generate(seed_value, planet_name)
	rng.state = int(world.rng_state)
	view.world = world
	view.selected = -1
	view.creature_positions.clear()
	view.invalidate()
	view.pan = Vector2.ZERO
	view.zoom = 0.88
	view.display_zoom = .88
	view.display_pan = Vector2.ZERO
	accumulator = 0
	last_clock_ms = Time.get_ticks_msec()
	power = -1
	paused = false
	ui.refresh()
	if persist: Persistence.save_world(world)

func restore() -> void:
	var restored = Persistence.load_world()
	if restored.is_empty(): ui.toast(ui.t("load_failed")); return
	world = restored
	var report = Persistence.offline(world, Time.get_unix_time_from_system())
	rng.state = int(world.rng_state)
	view.world = world
	view.selected = -1
	view.creature_positions.clear()
	view.invalidate()
	ui.close()
	ui.refresh()
	if report.minutes >= 1: in_menu = true; ui.away(report)

func manual_save() -> void:
	world.rng_state = str(rng.state)
	ui.close()
	ui.toast(ui.t("saved") if Persistence.save_world(world) else ui.t("save_failed"))

func advance_tick() -> void:
	var start = Time.get_ticks_usec()
	var before = world.discoveries.size()
	Ecosystem.tick(world, rng)
	Civilization.tick(world)
	world.rng_state = str(rng.state)
	if world.discoveries.size() > before:
		audio.chime(6)
		var found = int(world.discoveries.back())
		ui.toast(ui.t("discovery") % ui.species(found))
		for cr in world.creatures:
			if int(cr.species) == found:
				view.effects.append({"cell": int(cr.cell), "age": 0.0, "power": 3})
				break
	$Atmosphere.material.set_shader_parameter("night", maxf(0, -sin(float(world.tick) / 30.0)))
	var cost = (Time.get_ticks_usec() - start) / 1000.0
	simulation_total_ms += cost
	simulation_peak_ms = maxf(simulation_peak_ms, cost)
	simulation_samples += 1

func _process(delta: float) -> void:
	var clock_ms = Time.get_ticks_msec()
	var simulation_delta = clampf((clock_ms - last_clock_ms) / 1000.0, 0, 1)
	last_clock_ms = clock_ms
	diagnostic_time += delta
	if OS.is_debug_build() and diagnostic_time >= 10:
		diagnostic_time = 0
		print("LittleGod runtime: tick=", world.get("tick", -1), " paused=", paused, " menu=", in_menu, " fps=", Engine.get_frames_per_second())
	if "--capture" in OS.get_cmdline_user_args():
		capture_frames += 1
		if capture_frames == 120:
			get_viewport().get_texture().get_image().save_png("res://builds/gameplay.png")
			print("CAPTURE_SAVED")
			print("PROFILE fps=", Engine.get_frames_per_second(), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " process_ms=", Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
			get_tree().quit()
	if paused or in_menu: return
	accumulator += simulation_delta * speed
	autosave_time += simulation_delta
	while accumulator >= 2:
		accumulator -= 2
		advance_tick()
		ui.refresh()
	audio.weather(int(world.weather) == 1)
	if autosave_time >= 30 and not is_test_session:
		autosave_time = 0
		Persistence.save_world(world)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		if not world.is_empty() and not in_menu and not is_test_session: Persistence.save_world(world)
	if what == NOTIFICATION_APPLICATION_RESUMED and not world.is_empty() and not in_menu:
		last_clock_ms = Time.get_ticks_msec()
		var report = Persistence.offline(world, Time.get_unix_time_from_system())
		rng.state = int(world.rng_state)
		if report.minutes >= 1: in_menu = true; ui.away(report)

func _input(event: InputEvent) -> void:
	if in_menu:
		touch_points.clear()
		return
	# Pinch uses independent fingers; single-finger input is emulated as mouse.
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_points.is_empty(): pinch_cancelled = false
			touch_points[event.index] = event.position
			if touch_points.size() >= 2: pinch_cancelled = true
		else: touch_points.erase(event.index)
	if event is InputEventScreenDrag and touch_points.has(event.index):
		if touch_points.size() == 2:
			var keys = touch_points.keys()
			var before = touch_points[keys[0]].distance_to(touch_points[keys[1]])
			var centre_before = (touch_points[keys[0]] + touch_points[keys[1]]) * .5
			touch_points[event.index] = event.position
			var after = touch_points[keys[0]].distance_to(touch_points[keys[1]])
			view.pan += (touch_points[keys[0]] + touch_points[keys[1]]) * .5 - centre_before
			if before > 1: view.zoom_at((touch_points[keys[0]] + touch_points[keys[1]]) * .5, after / before)
			drag_distance = 100
		else: touch_points[event.index] = event.position

func _unhandled_input(event: InputEvent) -> void:
	if in_menu: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: view.zoom_at(event.position, 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: view.zoom_at(event.position, .9)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_distance = 0
			else:
				dragging = false
				if drag_distance < 12 and touch_points.size() < 2 and not pinch_cancelled: touch_world(event.position)
	if event is InputEventMouseMotion and dragging and touch_points.size() < 2:
		drag_distance += event.relative.length()
		view.pan += event.relative
		view.pan = view.pan.clamp(Vector2(-450, -400), Vector2(450, 400))
	if event is InputEventMagnifyGesture: view.zoom = clampf(view.zoom * event.factor, 0.5, 2)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE: ui.menu()
		if event.keycode == KEY_SPACE: paused = not paused; ui.refresh()

func touch_world(pos: Vector2) -> void:
	if power < 0:
		var creature = view.inhabitants.closest_creature(pos)
		if creature >= 0:
			view.selected_creature = creature
			var cr = world.creatures[creature]
			view.selected = int(cr.cell)
			ui.hint.text = ui.t("creature_info") % [ui.species(int(cr.species)), int(cr.hunger * 100), Biomes.title(int(cr.species), ui.language)]
			audio.button_sound()
			return
	var cell = view.pick(pos)
	if cell < 0: return
	view.selected = cell
	if power >= 0:
		if Powers.apply(world, power, cell):
			view.effects.append({"cell": cell, "age": 0.0, "power": power})
			view.invalidate()
			if OS.has_feature("mobile") and haptics: Input.vibrate_handheld(22, .25)
			audio.chime(power)
			ui.refresh()
		else: ui.toast(ui.t("failed"))
	else: ui.inspect(cell)
