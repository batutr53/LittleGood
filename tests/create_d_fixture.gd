extends SceneTree
func _initialize() -> void:
	var output=[];OS.execute("git",["rev-parse","HEAD"],output)
	if output.is_empty() or output[0].strip_edges()!="38c7f0dcf6d13a079df281d7f5ce3fc7aba5d34a" or FileAccess.file_exists("res://scripts/trade.gd"):quit(1);return
	var p=preload("res://scripts/military_progression_probe.gd").new();var ok=p.complete()
	var forge=p.world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	ok=ok and preload("res://scripts/industry.gd").queue(p.world,"healing_potion",int(forge.id))
	ok=ok and Persistence.save_world(p.world,"res://tests/fixtures/planet-v085d.json")
	print("ACTUAL_TAG_D_FIXTURE ",ok);quit(0 if ok else 1)
