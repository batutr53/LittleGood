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

func _ready() -> void:
	get_window().min_size = Vector2i(360, 640)
	audio = Soundscape.new()
	add_child(audio)
	ui.game = self
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		ui.language = config.get_value("user", "language", "en")
		audio.set_enabled(config.get_value("user", "sound", true))
	world = WorldGen.generate(2026, "Lumi")
	view.world = world
	rng.state = int(world.rng_state)
	ui.build()
	ui.main_menu()
	if "--capture" in OS.get_cmdline_user_args():
		in_menu = false
		ui.close()
		for i in range(12): advance_tick()
	set_process_input(true)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("user", "language", ui.language)
	config.set_value("user", "sound", audio.enabled)
	config.save("user://settings.cfg")

func new_planet(seed_value: int, planet_name: String) -> void:
	world = WorldGen.generate(seed_value, planet_name)
	rng.state = int(world.rng_state)
	view.world = world
	view.selected = -1
	view.creature_positions.clear()
	view.pan = Vector2.ZERO
	view.zoom = 0.88
	power = -1
	paused = false
	ui.refresh()
	Persistence.save_world(world)

func restore() -> void:
	var restored = Persistence.load_world()
	if restored.is_empty(): ui.toast(ui.t("load_failed")); return
	world = restored
	var report = Persistence.offline(world, Time.get_unix_time_from_system())
	rng.state = int(world.rng_state)
	view.world = world
	view.selected = -1
	view.creature_positions.clear()
	ui.close()
	ui.refresh()
	if report.minutes >= 1: in_menu = true; ui.away(report)

func manual_save() -> void:
	world.rng_state = str(rng.state)
	ui.close()
	ui.toast(ui.t("saved") if Persistence.save_world(world) else ui.t("save_failed"))

func advance_tick() -> void:
	var before = world.discoveries.size()
	Ecosystem.tick(world, rng)
	Civilization.tick(world)
	world.rng_state = str(rng.state)
	if world.discoveries.size() > before: audio.chime(6)
	$Atmosphere.material.set_shader_parameter("night", maxf(0, -sin(float(world.tick) / 30.0)))

func _process(delta: float) -> void:
	if "--capture" in OS.get_cmdline_user_args():
		capture_frames += 1
		if capture_frames == 120:
			get_viewport().get_texture().get_image().save_png("res://builds/gameplay.png")
			print("CAPTURE_SAVED")
			print("PROFILE fps=", Engine.get_frames_per_second(), " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " process_ms=", Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
			get_tree().quit()
	if paused or in_menu: return
	accumulator += delta * speed
	autosave_time += delta
	if accumulator >= 2:
		accumulator -= 2
		advance_tick()
		ui.refresh()
	if autosave_time >= 30:
		autosave_time = 0
		Persistence.save_world(world)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		if not world.is_empty() and not in_menu: Persistence.save_world(world)
	if what == NOTIFICATION_APPLICATION_RESUMED and not world.is_empty() and not in_menu:
		var report = Persistence.offline(world, Time.get_unix_time_from_system())
		rng.state = int(world.rng_state)
		if report.minutes >= 1: in_menu = true; ui.away(report)

func _input(event: InputEvent) -> void:
	# Pinch uses independent fingers; single-finger input is emulated as mouse.
	if event is InputEventScreenTouch:
		if event.pressed: touch_points[event.index] = event.position
		else: touch_points.erase(event.index)
	if event is InputEventScreenDrag and touch_points.has(event.index):
		if touch_points.size() == 2:
			var keys = touch_points.keys()
			var before = touch_points[keys[0]].distance_to(touch_points[keys[1]])
			touch_points[event.index] = event.position
			var after = touch_points[keys[0]].distance_to(touch_points[keys[1]])
			if before > 1: view.zoom = clampf(view.zoom * after / before, 0.5, 2)
			drag_distance = 100
		else: touch_points[event.index] = event.position

func _unhandled_input(event: InputEvent) -> void:
	if in_menu: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: view.zoom = clampf(view.zoom + 0.1, 0.5, 2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: view.zoom = clampf(view.zoom - 0.1, 0.5, 2)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				drag_distance = 0
			else:
				dragging = false
				if drag_distance < 12 and touch_points.size() < 2: touch_world(event.position)
	if event is InputEventMouseMotion and dragging and touch_points.size() < 2:
		drag_distance += event.relative.length()
		view.pan += event.relative
		view.pan = view.pan.clamp(Vector2(-450, -400), Vector2(450, 400))
	if event is InputEventMagnifyGesture: view.zoom = clampf(view.zoom * event.factor, 0.5, 2)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE: ui.menu()
		if event.keycode == KEY_SPACE: paused = not paused

func touch_world(pos: Vector2) -> void:
	var cell = view.pick(pos)
	if cell < 0: return
	view.selected = cell
	if power >= 0:
		if Powers.apply(world, power, cell):
			view.effects.append({"cell": cell, "age": 0.0})
			audio.chime(power)
			ui.refresh()
		else: ui.toast(ui.t("failed"))
	else: ui.inspect(cell)
