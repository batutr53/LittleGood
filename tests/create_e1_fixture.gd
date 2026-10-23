extends SceneTree
func _initialize() -> void:
 var output=[]
 OS.execute('git',['rev-parse','HEAD'],output)
 if output.is_empty() or str(output[0]).strip_edges()!='914728f5872595d46046fcb32098a696a183d43b' or FileAccess.file_exists('res://scripts/regions.gd'):quit(2);return
 var p=preload('res://scripts/trade_progression_probe.gd').new()
 if not p.complete(42):print(p.error);quit(1);return
 var id=preload('res://scripts/trade.gd').dispatch(p.world,'hills',p.merchant,[],{'wood':2})
 if id<0 or not Persistence.save_world(p.world,'res://tests/fixtures/planet-v085e1.json'):quit(1);return
 print('AUTHENTIC_E1_PENDING ',Persistence.validate(p.world));quit(0)
