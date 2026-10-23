extends SceneTree
func _initialize() -> void:
	var results=[]
	for seed in [1,7,42,99,123,2026,9001,31415]:
		var p=preload("res://scripts/trade_progression_probe.gd").new();var ok=p.complete(seed) and Persistence.validate(p.world)
		results.append({"seed":seed,"legal_1_21":ok,"error":p.error})
	print("E1_LEGAL_CAMPAIGNS ",results);quit(0 if results.all(func(r):return r.legal_1_21) else 1)
