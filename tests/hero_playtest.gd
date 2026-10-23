extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;root.add_child(game);current_scene=game
	var probe=preload("res://scripts/hero_progression_probe.gd").new();var ok=probe.armed();game.world=probe.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="en";game.show_world(true);game.ui.close();game.hero_ui.profile()
	await create_timer(.8).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085c/hero-profile.png")
	print("HERO_PROFILE_REAL ",ok);quit(0 if ok else 1)
