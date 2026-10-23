extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://industry-visual.json";root.add_child(game);current_scene=game
	var qa=preload("res://scripts/industry_qa.gd").new();qa.game=game;game.add_child(qa)
	var report=await qa.run();var f=FileAccess.open("res://builds/phase09/visual.json",FileAccess.WRITE);f.store_string(JSON.stringify(report));f.close()
	print("INDUSTRY_VISUAL ",report);quit(0 if report.all_passed else 1)
