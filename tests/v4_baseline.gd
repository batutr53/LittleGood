extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://v4-private.json";root.add_child(game);current_scene=game
 var p=preload("res://scripts/hero_progression_probe.gd").new();var ok=p.armed();game.world=p.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="tr";game.enter_adventure()
 var s=game.adventure_scene;s.controlled=true;s.frozen=true
 await create_timer(.3).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/visual-v4/before-idle.png")
 print("V4_BASELINE_RENDERED ",ok);quit(0 if ok else 1)
