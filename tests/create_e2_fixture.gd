extends SceneTree
func _initialize() -> void:
	var output=[];OS.execute("git",["rev-parse","HEAD"],output)
	if output.is_empty() or output[0].strip_edges()!="57ca7fa467e811e9e5829f95f2dac77539ab95c1" or FileAccess.file_exists("res://scripts/sanctuary.gd"):quit(2);return
	var p=preload("res://scripts/desert_progression_probe.gd").new();var ok=p.complete(42)
	var T=preload("res://scripts/trade.gd");var I=preload("res://scripts/industry.gd");var forge=p.world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	ok=ok and T.dispatch(p.world,"hills",p.base.base.merchant,[],{"wood":1})>0 and I.queue(p.world,"healing_potion",int(forge.id)) and Persistence.save_world(p.world,"res://tests/fixtures/planet-v085e2.json")
	print("AUTHENTIC_E2 ",ok);quit(0 if ok else 1)
