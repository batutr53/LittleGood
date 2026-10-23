extends SceneTree
const MAP=preload("res://scripts/wildwood_map.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;root.add_child(game);current_scene=game
	var probe=preload("res://scripts/hero_progression_probe.gd").new();var ok=probe.armed();game.world=probe.world;game.view.world=game.world;game.paused=true;game.has_player_world=true;game.ui.language="en"
	ok=game.enter_adventure() and ok;var scene=game.adventure_scene;scene.controlled=true
	await create_timer(.8).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085c/wildwood-entry.png")
	var r=game.world.kingdom.adventure.run;var path=MAP.path(Vector2(r.x,r.y),MAP.LANDMARK,true)
	for target in path:
		for i in range(60):
			var point=Vector2(r.x,r.y)
			if point.distance_to(target)<10:break
			scene.movement=(target-point).normalized();await physics_frame
	scene.movement=Vector2.ZERO;scene.interact();await create_timer(.7).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/phase085c/wildwood-landmark.png");ok=ok and r.landmark;scene.go_home()
	print("C2_RENDERED_PHYSICS ",ok);quit(0 if ok else 1)
