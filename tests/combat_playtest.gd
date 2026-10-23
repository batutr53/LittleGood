extends SceneTree
const MAP=preload("res://scripts/wildwood_map.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;root.add_child(game);current_scene=game
	var p=preload("res://scripts/hero_progression_probe.gd").new();var ok=p.armed();game.world=p.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="en";game.enter_adventure()
	var scene=game.adventure_scene;scene.controlled=true;var r=game.world.kingdom.adventure.run;var e=r.enemies[0];var path=MAP.path(Vector2(r.x,r.y),Vector2(e.x,e.y),true);var warned=false
	for target in path:
		for i in range(70):
			var pos=Vector2(r.x,r.y)
			if pos.distance_to(target)<12:break
			scene.movement=(target-pos).normalized();await physics_frame
	for i in range(1800):
		var pos=Vector2(r.x,r.y);var target=Vector2(e.x,e.y);scene.movement=(target-pos).normalized() if pos.distance_to(target)>60 else Vector2.ZERO
		if game.world.kingdom.adventure.hero.hp<100 and warned:scene.actions={"attack":true,"skill":true}
		if e.state=="windup" and not warned:
			await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085c/wolf-warning.png");warned=true
		if e.hp==0:break
		await physics_frame
	scene.movement=Vector2.ZERO;scene.interact();await create_timer(.2).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085c/wolf-defeated.png")
	ok=ok and e.hp==0 and warned and game.world.kingdom.adventure.hero.hp<100;print("C3_REAL_PHYSICS_COMBAT ",ok);scene.go_home();quit(0 if ok else 1)
