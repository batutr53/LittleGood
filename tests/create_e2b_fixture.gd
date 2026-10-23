extends SceneTree
func _initialize() -> void:
	var output=[];OS.execute("git",["rev-parse","HEAD"],output)
	if output.is_empty() or output[0].strip_edges()!="45cc684b0d1c5f07912dbad0d0cf72ef856b182f" or FileAccess.file_exists("res://scripts/ashen_desert.gd"):quit(2);return
	var p=preload("res://scripts/regional_progression_probe.gd").new();var ok=p.explore(42)
	var T=preload("res://scripts/trade.gd");var I=preload("res://scripts/industry.gd")
	var id=T.dispatch(p.world,"hills",p.base.merchant,[],{"wood":1})
	var forge=p.world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	ok=ok and id>0 and I.queue(p.world,"healing_potion",int(forge.id)) and Persistence.save_world(p.world,"res://tests/fixtures/planet-v085e2b.json")
	print("AUTHENTIC_E2B ",ok);quit(0 if ok else 1)
