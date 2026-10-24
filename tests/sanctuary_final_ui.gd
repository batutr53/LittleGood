extends SceneTree
var game
func _initialize() -> void:call_deferred("run")
func prefix(node: Node,text: String) -> Button:
	if node is Button and node.text.begins_with(text):return node
	for child in node.get_children():
		var found=prefix(child,text)
		if found:return found
	return null
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://sanctuary-ui-private.json";root.add_child(game);current_scene=game
	game.world=Persistence.load_world("user://sanctuary-rendered-private.json");game.has_player_world=true;game.view.world=game.world;game.paused=true;game.ui.language="tr"
	game.realm_ui.workshop();await create_timer(.3).timeout
	var button=prefix(game.ui.modal,"Kadim Demir Kılıç");var scroll=button.get_parent()
	while scroll and not scroll is ScrollContainer:scroll=scroll.get_parent()
	if scroll:scroll.ensure_control_visible(button)
	await create_timer(.3).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085e3/ancient-forging-tr.png")
	game.hero_ui.profile();await create_timer(.3).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085e3/ancient-equipment-tr.png")
	print("SANCTUARY_FINAL_UI ",Persistence.validate(game.world) and game.world.kingdom.claimed.has("main_23"));quit()
