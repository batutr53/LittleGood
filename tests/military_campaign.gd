extends SceneTree
func _initialize() -> void:
	var results=[]
	for seed in [1,2,3,7,17,42,99,123,555,2026,9001,31415]:
		var p=preload("res://scripts/military_progression_probe.gd").new();var ok=p.complete(seed) and Persistence.validate(p.world)
		results.append({"seed":seed,"legal_1_20":ok,"error":p.error})
	print("MILITARY_CAMPAIGN ",results)
	quit(0 if results.all(func(r):return r.legal_1_20) else 1)
