extends SceneTree
const A=preload("res://scripts/adventure.gd")
const MAP=preload("res://scripts/wildwood_map.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var p=preload("res://scripts/adventure_progression_probe.gd").new();var checks={"legal14":p.equipped_upgrade(2031)};var w=p.world;A.enter(w);var r=w.kingdom.adventure.run;var boss=r.enemies[3]
	for target in MAP.path(Vector2(r.x,r.y),MAP.BOSS,false):
		for i in range(90):
			if Vector2(r.x,r.y).distance_to(target)<12:break
			A.step(w,p.command(target,false))
	var patterns=[];var saw_fast=false;var moved=false;var saved=false
	for i in range(2000):
		var attacking=patterns.has(0) and patterns.has(1) and boss.hp>110
		var input=p.command(Vector2(boss.x,boss.y),attacking)
		if Vector2(r.x,r.y).distance_to(Vector2(boss.x,boss.y))<60 and not input.get("dodge",false):input.move=Vector2.ZERO
		if boss.state=="windup":
			if not patterns.has(int(boss.pattern)):patterns.append(int(boss.pattern))
			if boss.hp<=110 and boss.pattern==1 and boss.timer>500 and boss.timer<=700:saw_fast=true
			if boss.pattern==1 and not saved:
				saved=Persistence.save_world(w,"user://boss-warning.json") and Persistence.load_world("user://boss-warning.json").kingdom==w.kingdom
				input.move=Vector2.LEFT;moved=true
		A.step(w,input)
		if patterns.has(2) and saw_fast:break
		if w.kingdom.adventure.hero.defeated:break
	checks.frontal=patterns.has(0);checks.root=patterns.has(1);checks.shockwave=patterns.has(2);checks.faster_phase2=saw_fast;checks.saved_locked_warning=saved and moved;checks.survived=not w.kingdom.adventure.hero.defeated
	print("C6_BOSS_PATTERNS ",checks);quit(1 if checks.values().has(false) else 0)
