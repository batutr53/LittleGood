extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://phase085-visual.json";root.add_child(game);current_scene=game
	var qa=preload("res://scripts/kingdom_qa.gd").new();game.add_child(qa);qa.game=game
	var report=await qa.run()
	var f=FileAccess.open("res://builds/phase085/visual.json",FileAccess.WRITE);f.store_string(JSON.stringify(report));f.close();print("KINGDOM_VISUAL ",report);quit(0 if report.all_passed else 1)
