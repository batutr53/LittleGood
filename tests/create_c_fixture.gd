extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if FileAccess.file_exists("res://scripts/military.gd"):quit(1);return
	var output=[];OS.execute("git",["rev-parse","HEAD"],output)
	if output.is_empty() or output[0].strip_edges()!="f1684d969f934f2ebef6e10d1c07d47dfde0b54f":quit(1);return
	var p=preload("res://scripts/adventure_progression_probe.gd").new();var ok=p.complete(2026)
	var forge=p.world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	ok=ok and preload("res://scripts/industry.gd").queue(p.world,"healing_potion",int(forge.id))
	ok=ok and Persistence.save_world(p.world,"res://tests/fixtures/planet-v085c.json")
	print("ACTUAL_TAG_C_FIXTURE ",ok);quit(0 if ok else 1)
