extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.new_planet(12345, "RuntimeTest", false)
	scene.ui.close()
	await create_timer(3.2).timeout
	print("RUNTIME tick=", scene.world.tick, " paused=", scene.paused, " menu=", scene.in_menu, " processing=", scene.is_processing(), " accumulator=", scene.accumulator)
	var passed = scene.world.tick >= 1
	scene.in_menu = true
	print("RUNTIME_RESULT: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)
