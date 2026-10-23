extends SceneTree
const A=preload("res://scripts/adventure.gd")
const MAP=preload("res://scripts/wildwood_map.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var p=preload("res://scripts/hero_progression_probe.gd").new();var checks={"legal_hero":p.armed()};var w=p.world;var old=w.duplicate(true)
	checks.entry=A.enter(w);var r=w.kingdom.adventure.run
	checks.collisions=MAP.move(Vector2(330,650),Vector2(-100,0)).x>=314
	var path=MAP.path(Vector2(r.x,r.y),MAP.LANDMARK,true)
	checks.path=path.size()>0
	for target in path:
		for i in range(100):
			var here=Vector2(r.x,r.y)
			if here.distance_to(target)<9:break
			A.step(w,{"move":(target-here).normalized()})
	checks.landmark=A.interact(w)=="landmark" and A.interact(w)!="landmark"
	checks.save=Persistence.save_world(w,"user://exploration.json") and Persistence.load_world("user://exploration.json").kingdom==w.kingdom
	var tick=w.tick;Persistence.offline(w,w.saved_at+28800);checks.offline_pause=w.tick==tick
	checks.return=A.exit(w) and not A.exit(w) and w.cells==old.cells
	checks.quest=preload("res://scripts/kingdom.gd").claim(w,"main_12")
	print("C2_EXPLORATION ",checks);quit(1 if checks.values().has(false) else 0)
