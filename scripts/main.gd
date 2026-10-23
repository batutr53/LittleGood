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
var has_player_world = false
var loading = false
var suspended = false
var ui_pointer_blocked = false
var save_pending = -1.0
var onboarding_live = false
var diagnostics = preload("res://scripts/local_diagnostics.gd").new()
var pipeline: Dictionary = {}
var save_path = Persistence.PATH
var showcases = preload("res://scripts/planet_showcase.gd").new()
var visiting = false
var visited_id = ""
var visit_origin: Dictionary = {}
var input_feedback_ms = -1.0
var online
var decorator
var realm_ui
var hero_ui
var military_ui
var trade_ui
var army_scene
var adventure_scene

func enter_adventure() -> bool:
	if is_instance_valid(adventure_scene) or visiting:return false
	if not preload("res://scripts/adventure.gd").enter(world,paused):return false
	ui.close();adventure_scene=load("res://scenes/adventure.tscn").instantiate();adventure_scene.game=self;add_child(adventure_scene);checkpoint("adventure-entry");return true

func enter_army(mission: String="") -> bool:
	if is_instance_valid(army_scene) or is_instance_valid(adventure_scene) or visiting:return false
	var M=preload("res://scripts/military.gd")
	if not M.enabled(world):return false
	if not world.kingdom.military.battle.get("active",false):
		if not M.deploy(world,mission,M.available(world).map(func(u):return int(u.id))):return false
	ui.close();army_scene=load("res://scenes/army_battle.tscn").instantiate();army_scene.game=self;add_child(army_scene);checkpoint("company-entry");return true

func measure_input_feedback(started: int) -> void:
	await RenderingServer.frame_post_draw
	input_feedback_ms = (Time.get_ticks_usec()-started)/1000.0

func _exit_tree() -> void:
	GameArt.foliage_material = null
	GameArt.silver_material = null

func _ready() -> void:
	var ready_start = Time.get_ticks_usec()
	# Automated harnesses must not be recorded as human launches or sessions.
	is_test_session = is_test_session or (OS.is_debug_build() and ("--benchmark" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_user_args() or FileAccess.file_exists("user://phase2_benchmark.json") or FileAccess.file_exists("user://phase4_qa.json")))
	get_window().min_size = Vector2i(360, 640)
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	get_window().go_back_requested.connect(navigate_back)
	$Atmosphere.size = get_viewport_rect().size
	audio = Soundscape.new()
	add_child(audio)
	online = preload("res://scripts/online_client.gd").new()
	add_child(online)
	ui.game = self
	decorator=preload("res://scripts/customization_interface.gd").new(ui,self)
	realm_ui=preload("res://scripts/kingdom_interface.gd").new(self,ui)
	military_ui=preload("res://scripts/military_interface.gd").new(self,ui)
	trade_ui=preload("res://scripts/trade_interface.gd").new(self,ui)
	hero_ui=preload("res://scripts/hero_interface.gd").new(self,ui)
	view.set_quality(false)
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		ui.language = config.get_value("user", "language", "en")
		audio.set_enabled(config.get_value("user", "sound", true))
		haptics = config.get_value("user", "haptics", true)
		diagnostics.enabled = config.get_value("user", "diagnostics", true)
		view.set_quality(config.get_value("user", "economy", false))
	diagnostics.configure()
	if not is_test_session:
		diagnostics.begin()
		diagnostics.record("first_launch",0,true)
	show_world(false)
	ui.build()
	ui.main_menu()
	pipeline.scene_ready_ms = (Time.get_ticks_usec() - ready_start) / 1000.0
	last_clock_ms = Time.get_ticks_msec()
	if "--capture" in OS.get_cmdline_user_args():
		new_planet(2026, "Lumi", false)
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
		if options.get("kingdom_fixture",false):
			var fixture=Persistence.load_world("user://phase085_profile_world.json")
			if fixture.is_empty() or not fixture.has("kingdom"):push_error("Missing validated kingdom benchmark fixture");get_tree().quit(1);return
			pipeline.industry_fixture=fixture.kingdom.has("industry")
			world=fixture
			if options.get("hide_kingdom",false):world.erase("kingdom")
			view.world=world;rng.state=int(world.rng_state);world.weather=1;paused=false;view.invalidate()
			pipeline.kingdom_fixture=true;pipeline.hide_kingdom=options.get("hide_kingdom",false)
			has_player_world=true;ui.refresh()
		if options.get("cosmetics",false):
			preload("res://scripts/cosmetic_qa.gd").decorate(world,32)
			preload("res://scripts/cosmetics.gd").equip(world,options.get("cosmetic_theme","crystal"))
			view.invalidate()
		if options.get("stress", false):
			while world.creatures.size() < 70:
				var cr = world.creatures[world.creatures.size() % 18].duplicate(true)
				cr.erase("identity")
				world.creatures.append(cr)
			LivingStories.ensure(world)
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
		if not OS.has_feature("mobile"): probe.destination = "res://builds/phase8/desktop-" + ("economy" if view.low_quality else "smooth") + ".json"
		add_child(probe)
	set_process_input(true)
	if OS.is_debug_build() and FileAccess.file_exists("user://phase4_qa.json"):
		var qa_options = JSON.parse_string(FileAccess.get_file_as_string("user://phase4_qa.json"))
		if qa_options is Dictionary:
			var qa = load("res://scripts/beta_qa.gd").new()
			qa.options = qa_options
			add_child(qa)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("user", "language", ui.language)
	config.set_value("user", "sound", audio.enabled)
	config.set_value("user", "haptics", haptics)
	config.set_value("user", "economy", view.low_quality)
	config.set_value("user", "diagnostics", diagnostics.enabled)
	config.save("user://settings.cfg")

func new_planet(seed_value: int, planet_name: String, persist: bool = true) -> void:
	if visiting: return
	var start = Time.get_ticks_usec()
	world = WorldGen.generate(seed_value, planet_name)
	preload("res://scripts/cosmetics.gd").ensure(world)
	pipeline.world_generation_ms = (Time.get_ticks_usec() - start) / 1000.0
	has_player_world = persist
	onboarding_live = persist
	show_world(true)
	rng.state = int(world.rng_state)
	view.world = world
	view.selected = -1
	view.selected_creature = -1
	view.selected_identity = -1
	view.creature_positions.clear()
	view.inhabitants.position_memory.clear()
	view.invalidate()
	view.pan = Vector2.ZERO
	view.zoom = 0.88
	view.display_zoom = .88
	view.display_pan = Vector2.ZERO
	accumulator = 0
	last_clock_ms = Time.get_ticks_msec()
	power = -1
	paused = false
	save_pending = -1
	ui.refresh()
	if persist:
		note("planet_created", 0, true)
		checkpoint("creation")

func restore() -> void:
	if loading or visiting: return
	loading = true
	ui.loading_screen()
	await get_tree().process_frame
	var start = Time.get_ticks_usec()
	var restored = Persistence.load_world(save_path)
	pipeline.restore_parse_ms = (Time.get_ticks_usec() - start) / 1000.0
	if restored.is_empty():
		loading = false
		ui.main_menu()
		ui.toast(ui.t("load_failed"))
		if not is_test_session: diagnostics.record("handled_error", 2)
		return
	var recovery = Persistence.last_recovery
	var report = await replay_offline(restored, Time.get_unix_time_from_system())
	world = restored
	has_player_world = true
	onboarding_live = false
	paused = bool(world.get("user_paused", false))
	show_world(true)
	rng.state = int(world.rng_state)
	view.world = world
	view.selected = -1
	view.selected_creature = -1
	view.selected_identity = -1
	view.creature_positions.clear()
	view.invalidate()
	ui.close()
	view.inhabitants.position_memory.clear()
	ui.refresh()
	loading = false
	last_clock_ms = Time.get_ticks_msec()
	accumulator = 0
	note("world_restored", 1 if recovery != "none" else 0)
	checkpoint("restore")
	if world.get("kingdom",{}).get("military",{}).get("battle",{}).get("active",false):enter_army();return
	if world.get("kingdom",{}).get("adventure",{}).get("run",{}).get("active",false):enter_adventure();return
	if report.minutes >= 1: in_menu = true; ui.away(report)
	elif recovery != "none": ui.toast(ui.t("recovered"))

func manual_save() -> void:
	ui.close()
	ui.toast(ui.t("saved") if checkpoint("manual") else ui.t("save_failed"))

func show_world(value: bool) -> void:
	view.visible = value
	view.set_process(value)
	$WorldForeground.visible = value
	$WorldForeground.set_process(value)

func note(key: String, value: int = 0, once: bool = false) -> void:
	if is_test_session or not has_player_world or visiting: return
	diagnostics.begin()
	diagnostics.record(key, value, once)

func schedule_save() -> void:
	if has_player_world and not is_test_session and not visiting: save_pending = 1.0

func checkpoint(_reason: String = "automatic") -> bool:
	if world.is_empty() or is_test_session or not has_player_world or visiting: return true
	world.rng_state = str(rng.state)
	world.user_paused = paused
	var start = Time.get_ticks_usec()
	var ok = Persistence.save_world(world, save_path)
	pipeline.save_ms = (Time.get_ticks_usec() - start) / 1000.0
	save_pending = -1
	note("save_completed" if ok else "handled_error", 0 if ok else 1)
	if not ok: ui.toast(ui.t("save_failed"))
	return ok

func replay_offline(target: Dictionary, now: float) -> Dictionary:
	if target.get("_read_only",false): return {}
	var start = Time.get_ticks_usec()
	var job = Persistence.offline_begin(target, now)
	var peak = 0.0
	while job.done < job.count:
		var slice_start = Time.get_ticks_usec()
		while job.done < job.count and Time.get_ticks_usec() - slice_start < 4000:
			Persistence.offline_step(job, 1)
		peak = maxf(peak, (Time.get_ticks_usec() - slice_start) / 1000.0)
		ui.loading_progress(float(job.done) / maxf(1, job.count))
		await get_tree().process_frame
	pipeline.offline_wall_ms = (Time.get_ticks_usec() - start) / 1000.0
	pipeline.offline_peak_slice_ms = peak
	return Persistence.offline_finish(job)

func suspend_session() -> void:
	if suspended: return
	checkpoint("background")
	suspended = true
	diagnostics.finish()
	reset_gesture()

func resume_session(now: float = -1) -> void:
	if not suspended: return
	suspended = false
	last_clock_ms = Time.get_ticks_msec()
	if visiting: return
	if world.is_empty() or loading: return
	if has_player_world and not is_test_session: diagnostics.begin()
	var resume_time = Time.get_unix_time_from_system() if now < 0 else now
	if paused or resume_time - float(world.saved_at) < 60:
		checkpoint("resume")
		return
	loading = true
	ui.loading_screen()
	var report = await replay_offline(world, resume_time)
	rng.state = int(world.rng_state)
	loading = false
	last_clock_ms = Time.get_ticks_msec()
	accumulator = 0
	ui.close()
	checkpoint("resume")
	if report.minutes >= 1: in_menu = true; ui.away(report)

func reset_gesture() -> void:
	dragging = false
	drag_distance = 0
	touch_points.clear()
	pinch_cancelled = true
	ui_pointer_blocked = true

func navigate_back() -> void:
	if is_instance_valid(army_scene):army_scene.toggle_pause();return
	if is_instance_valid(adventure_scene):adventure_scene.toggle_pause();return
	if loading: return
	if realm_ui!=null and realm_ui.active:realm_ui.finish();return
	if decorator!=null and decorator.active:decorator.finish();return
	reset_gesture()
	if visiting:
		if in_menu and ui.page == "visit_menu": stop_visit()
		elif in_menu and ui.page == "profile": ui.visit_menu()
		elif in_menu: ui.visit_menu()
		else: ui.visit_menu()
		return
	if ui.page == "online": ui.menu() if not world.is_empty() else ui.main_menu()
	elif ui.page == "beta": ui.settings()
	elif in_menu and ui.page in ["settings", "journal", "history", "neighbors", "achievements", "pulse", "detail", "favorites", "postcard", "universe", "profile", "wonders","customization","kingdom"]: ui.menu() if not world.is_empty() else ui.main_menu()
	elif in_menu and has_player_world: ui.close()
	elif has_player_world: ui.menu()
	else: ui.main_menu()

func advance_tick() -> void:
	if visiting or world.is_empty(): return
	var start = Time.get_ticks_usec()
	var before = world.discoveries.size()
	var chapters_before = world.living.findings.size()
	Ecosystem.tick(world, rng)
	Civilization.tick(world)
	preload("res://scripts/cosmetics.gd").reconcile(world)
	world.rng_state = str(rng.state)
	if world.discoveries.size() > before:
		audio.chime(6)
		var found = int(world.discoveries.back())
		ui.toast(ui.t("discovery") % ui.species(found))
		for cr in world.creatures:
			if int(cr.species) == found:
				view.effects.append({"cell": int(cr.cell), "age": 0.0, "power": 3})
				break
	if world.living.findings.size() > chapters_before:
		for e in world.events:
			if int(e.tick) == int(world.tick) and e.key in LivingStories.FINDINGS:
				ui.toast(ui.event_text(e))
				view.effects.append({"cell": int(e.cell), "age": 0.0, "power": 1})
				audio.chime(6)
	# A full Chronicle rotates episodes, so its size cannot detect a new story.
	var new_memories = world.living.memories.filter(func(e): return int(e.tick) == int(world.tick))
	if not new_memories.is_empty():
		note("memory_found", new_memories.size())
		var memory = new_memories.back()
		if not memory.key in LivingStories.FINDINGS:
			ui.toast(ui.event_text(memory))
			view.effects.append({"cell": int(memory.cell), "age": 0.0, "power": 5})
			audio.chime(6)
	ui.refresh()
	if onboarding_live and world.living.findings.has("friendship") and not world.living.observed.is_empty():
		note("onboarding_completed", 0, true)
		onboarding_live = false
	$Atmosphere.material.set_shader_parameter("night", maxf(0, -sin(float(world.tick) / 30.0)))
	var cost = (Time.get_ticks_usec() - start) / 1000.0
	simulation_total_ms += cost
	simulation_peak_ms = maxf(simulation_peak_ms, cost)
	simulation_samples += 1

func _process(delta: float) -> void:
	var clock_ms = Time.get_ticks_msec()
	var simulation_delta = clampf((clock_ms - last_clock_ms) / 1000.0, 0, 1)
	last_clock_ms = clock_ms
	diagnostics.advance(simulation_delta if not suspended else 0)
	if is_instance_valid(adventure_scene) or is_instance_valid(army_scene):return
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
	if suspended or loading: return
	if save_pending >= 0:
		save_pending -= simulation_delta
		if save_pending <= 0: checkpoint("interaction")
	if visiting or ((paused or in_menu) and not (trade_ui!=null and trade_ui.watching)): return
	accumulator += simulation_delta * speed
	autosave_time += simulation_delta
	while accumulator >= 2:
		accumulator -= 2
		advance_tick()
		ui.refresh()
	audio.weather(int(world.weather) == 1)
	if autosave_time >= 30 and not is_test_session:
		autosave_time = 0
		checkpoint("autosave")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if checkpoint("quit"):
			diagnostics.finish()
			get_tree().quit()
	if what == NOTIFICATION_APPLICATION_PAUSED: suspend_session()
	if what == NOTIFICATION_APPLICATION_RESUMED: resume_session()

func _input(event: InputEvent) -> void:
	if is_instance_valid(adventure_scene) or is_instance_valid(army_scene):return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		navigate_back()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			ui_pointer_blocked = ui.blocks_world(event.position)
			if not ui_pointer_blocked and touch_points.size() < 2: pinch_cancelled = false
		elif ui_pointer_blocked or ui.blocks_world(event.position):
			dragging = false
			pinch_cancelled = true
	if in_menu or loading or suspended:
		touch_points.clear()
		return
	# Pinch uses independent fingers; single-finger input is emulated as mouse.
	if event is InputEventScreenTouch:
		if event.pressed:
			if ui.blocks_world(event.position): return
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
	if is_instance_valid(adventure_scene) or is_instance_valid(army_scene):return
	if in_menu or loading or suspended: return
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT and ui_pointer_blocked) or ui.blocks_world(event.position): return
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
		if ui_pointer_blocked: return
		drag_distance += event.relative.length()
		view.pan += event.relative
		view.pan = view.pan.clamp(Vector2(-450, -400), Vector2(450, 400))
	if event is InputEventMagnifyGesture: view.zoom = clampf(view.zoom * event.factor, 0.5, 2)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE: ui.menu()
		if event.keycode == KEY_SPACE: paused = not paused; ui.refresh()

func touch_world(pos: Vector2) -> void:
	if realm_ui!=null and realm_ui.active:realm_ui.pick(pos);return
	if decorator!=null and decorator.active:decorator.pick(pos);return
	var input_started = Time.get_ticks_usec()
	if visiting: power = -1
	if power < 0:
		for home in world.settlements:
			if pos.distance_to(view.screen_point(world.cells[int(home.cell)])) < 13 * view.display_zoom:
				view.selected = int(home.cell)
				view.selected_creature = -1
				view.selected_identity = -1
				ui.inspect_settlement(home)
				return
		var creature = view.inhabitants.closest_creature(pos)
		if world.has("kingdom") and not visiting:
			for b in world.kingdom.buildings:
				var center=view.screen_point(world.cells[int(b.cell)])-Vector2(0,20)*view.display_zoom
				if center.distance_to(pos)<25*view.display_zoom:realm_ui.inspect_building(int(b.id));return
		if creature >= 0:
			view.focus_creature(creature)
			var cr = world.creatures[creature]
			view.selected = int(cr.cell)
			LivingStories.observe(world, cr)
			ui.show_creature(cr)
			ui.refresh()
			audio.button_sound()
			return
	var cell = view.pick(pos)
	if cell < 0: return
	view.selected = cell
	if power >= 0:
		if Powers.apply(world, power, cell):
			note("first_power", power, true)
			note("power_used", power)
			schedule_save()
			view.effects.append({"cell": cell, "age": 0.0, "power": power})
			view.invalidate()
			if OS.has_feature("mobile") and haptics: Input.vibrate_handheld(22, .25)
			audio.chime(power)
			power = -1
			ui.choose_power(-1)
			ui.refresh()
			if DisplayServer.get_name() != "headless": measure_input_feedback(input_started)
		else: ui.toast(ui.t("habitat_full") if power == 3 and world.creatures.size() >= 70 else ui.t("failed"))
	else:
		ui.inspect(cell)
		if world.has("kingdom") and not visiting:
			for b in world.kingdom.buildings:
				if int(b.cell)==cell:realm_ui.inspect_building(int(b.id));break

func visit_planet(data: Dictionary, id: String = "") -> bool:
	var imported = showcases.world_from(data)
	if imported.is_empty() or visiting: return false
	if not checkpoint("before_visit"): return false
	visit_origin = {"world":world,"paused":paused,"power":power,"pan":view.pan,"zoom":view.zoom,"owned":has_player_world,"rng":rng.state,"onboarding":onboarding_live}
	visiting = true
	visited_id = id
	world = imported
	paused = true
	power = -1
	save_pending = -1
	onboarding_live = false
	show_world(true)
	reset_visit_camera()
	ui.close()
	return true

func reset_visit_camera() -> void:
	view.world = world
	view.selected = -1
	view.selected_creature = -1
	view.selected_identity = -1
	view.inhabitants.position_memory.clear()
	view.pan = Vector2.ZERO
	view.display_pan = Vector2.ZERO
	view.zoom = .88
	view.display_zoom = .88
	view.invalidate()
	reset_gesture()
	accumulator = 0
	last_clock_ms = Time.get_ticks_msec()

func stop_visit() -> void:
	if not visiting: return
	var previous = visit_origin
	visiting = false
	visited_id = ""
	world = previous.world
	paused = previous.paused
	power = previous.power
	has_player_world = previous.owned
	onboarding_live = previous.onboarding
	rng.state = previous.rng
	reset_visit_camera()
	view.pan = previous.pan
	view.zoom = previous.zoom
	visit_origin = {}
	show_world(not world.is_empty())
	if world.is_empty(): ui.main_menu()
	else:
		ui.close()
		checkpoint("after_visit")
