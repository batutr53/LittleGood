class_name PerformanceProbe
extends Node

var duration = 15.0
var destination = "user://phase2_profile.json"
var started = 0
var previous = 0
var frame_times: Array = []
var peak_process = 0.0
var peak_draws = 0.0
var done = false
var first_frame_ms = 0
var world_cpu_total = 0.0
var foreground_cpu_total = 0.0
var animation_cpu_total = 0.0
var cosmetic_cpu_total = 0.0

func _ready() -> void:
	started = Time.get_ticks_usec()
	previous = started
	get_parent().is_test_session = true

func _process(_delta: float) -> void:
	var now = Time.get_ticks_usec()
	if first_frame_ms == 0: first_frame_ms = Time.get_ticks_msec()
	frame_times.append((now - previous) / 1000.0)
	world_cpu_total += get_parent().view.frame_cpu_ms
	foreground_cpu_total += get_parent().view.foreground_cpu_ms
	animation_cpu_total += get_parent().view.inhabitants.animate_ms
	cosmetic_cpu_total += get_parent().view.cosmetic_layer.draw_ms
	previous = now
	peak_process = maxf(peak_process, Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
	peak_draws = maxf(peak_draws, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if not done and (now - started) / 1000000.0 >= duration:
		done = true
		finish.call_deferred()

func finish() -> void:
	var game = get_parent()
	game.in_menu = true
	frame_times.sort()
	var elapsed = (Time.get_ticks_usec() - started) / 1000000.0
	var report = {"platform": OS.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "quality": "economy" if game.view.low_quality else "smooth", "wall_seconds": elapsed, "frames": frame_times.size(), "average_fps": frame_times.size() / elapsed, "frame_p50_ms": frame_times[int(frame_times.size() * .5)], "frame_p95_ms": frame_times[mini(frame_times.size() - 1, int(frame_times.size() * .95))], "peak_process_ms": peak_process, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "peak_draw_calls": peak_draws, "static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, "video_memory_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "creatures": game.world.creatures.size(), "simulation_ticks": game.world.tick, "simulation_average_ms": game.simulation_total_ms / maxf(1, game.simulation_samples), "simulation_peak_ms": game.simulation_peak_ms, "terrain_last_build_ms": game.view.terrain.build_ms, "terrain_rebuilds": game.view.terrain.rebuilds, "first_frame_ms": first_frame_ms, "atlas_size": [1024,1024], "effects": game.view.effects.size()}
	var f = FileAccess.open(destination, FileAccess.WRITE)
	report["control_scene"] = game.benchmark_control
	report["pipeline"] = game.pipeline
	report["props_sync_ms"] = game.view.inhabitants.sync_ms
	report["props_created_total"] = game.view.inhabitants.props_created
	report["content_scale_mode"] = game.get_window().content_scale_mode
	report["render_size"] = [game.get_viewport().get_texture().get_width(), game.get_viewport().get_texture().get_height()]
	report["world_cpu_average_ms"] = world_cpu_total/maxi(1,frame_times.size())
	report["foreground_cpu_average_ms"] = foreground_cpu_total/maxi(1,frame_times.size())
	report["creature_animation_average_ms"] = animation_cpu_total/maxi(1,frame_times.size())
	report["cosmetic_draw_average_ms"]=cosmetic_cpu_total/maxi(1,frame_times.size())
	report["cosmetic_count"]=game.world.get("wardrobe",{}).get("placements",[]).size()
	report["kingdom_buildings"]=game.world.get("kingdom",{}).get("buildings",[]).size()
	report["kingdom_workers"]=game.world.get("kingdom",{}).get("workers",[]).size()
	report["cosmetic_sync_ms"]=game.view.cosmetic_layer.sync_ms
	report["cosmetic_theme"]=game.world.get("wardrobe",{}).get("theme","enchanted")
	f.store_string(JSON.stringify(report, "\t"))
	f.close()
	print("PHASE2_PROFILE ", JSON.stringify(report))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png(destination.replace(".json", ".png"))
	get_tree().quit()
