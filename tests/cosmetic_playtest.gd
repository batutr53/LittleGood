extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://phase8-visual.json";root.add_child(game);current_scene=game;game.ui.language="en";game.ui.build()
	game.diagnostics.configure("user://phase8-visual-diagnostics.json","simulated")
	var qa=preload("res://scripts/cosmetic_qa.gd").new();game.add_child(qa);qa.game=game
	var result=await qa.run()
	var f=FileAccess.open("res://builds/phase8/visual.json",FileAccess.WRITE);f.store_string(JSON.stringify(result));f.close();print("COSMETIC_QA ",result)
	quit(0 if result.all_passed else 1)
