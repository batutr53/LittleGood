extends SceneTree
var game
func _initialize():call_deferred("run")
func shot(name):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/rpg/"+name+".png")
func run():
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://rpg-render-private.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await shot("home")
	for page in ["inventory","attributes","skills","chat"]:
		game.ui.premium.route(page);await shot(page)
	for key in ["priest","mage","rogue"]:
		preload("res://scripts/rpg_progression.gd").switch(w,key);game.ui.premium.route("inventory");await shot("inventory-"+key)
	game.ui.close();preload("res://scripts/rpg_progression.gd").switch(w,"mage")
	if game.enter_adventure("wildwood"):await shot("adventure-mage");game.adventure_scene.go_home()
	print("RPG_RENDER_COMPLETE");quit()
