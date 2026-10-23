extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	game.is_test_session=true;game.save_path="user://phase7-qa-world.json"
	root.add_child(game);current_scene=game
	var qa=preload("res://scripts/online_qa.gd").new();game.add_child(qa)
	qa.game=game;qa.destination="res://builds/phase7/godot-integration.json"
	qa.image_dir="res://builds/phase7"
	var result=await qa.run()
	print("ONLINE_RESULT ",result)
	quit(0 if result.all_passed else 1)
