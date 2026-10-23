extends SceneTree
const A=preload("res://scripts/adventure.gd")
const H=preload("res://scripts/hero.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var checks={}
	for seed in [2026,77,138]:
		var p=preload("res://scripts/adventure_progression_probe.gd").new();var ok=p.complete(seed);var w=p.world
		print("C5_ROUTE ",seed," ",ok," ",p.error)
		checks["legal15_"+str(seed)]=ok
		if not ok:continue
		checks["heart_"+str(seed)]=w.kingdom.stock.heart==1000 and H.progress(w,"boss")==1
		checks["save_"+str(seed)]=Persistence.save_world(w,"user://c5-boss.json") and Persistence.load_world("user://c5-boss.json").kingdom==w.kingdom
		var xp=w.kingdom.adventure.hero.xp;var loot=w.kingdom.adventure.run.loot.size();var e=w.kingdom.adventure.run.enemies[3]
		A.enter(w);A.defeat_enemy(w,e);checks["unique_"+str(seed)]=w.kingdom.adventure.hero.xp==xp and w.kingdom.adventure.run.loot.size()==loot
		A.exit(w);checks["artifact_"+str(seed)]=p.craft("heartward")
		var owned=w.kingdom.industry.items.filter(func(i):return i.recipe=="heartward")
		checks["effect_"+str(seed)]=not owned.is_empty() and H.equip(w,"artifact",int(owned[0].id)) and H.stats(w).health>=126 and w.kingdom.stock.heart==0
	print("C5_BOSS ",checks);quit(1 if checks.values().has(false) else 0)
