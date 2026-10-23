extends SceneTree
const H=preload("res://scripts/hero.gd")
const A=preload("res://scripts/adventure.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var p=preload("res://scripts/adventure_progression_probe.gd").new();var ok=p.equipped_upgrade();var w=p.world;print("C4_LEGAL ",ok," ",p.error)
	var checks={"legal_14":ok,"real_attack":H.stats(w).attack>=28,"real_defense":H.stats(w).defense>=6,"loot_consumed":w.kingdom.stock.thornhide==0,"saved":Persistence.save_world(w,"user://combat-crafted.json") and Persistence.load_world("user://combat-crafted.json").kingdom==w.kingdom}
	var before=w.kingdom.industry.items.size();var active=A.revisit(w) and A.enter(w);checks.legal_revisit=active and w.kingdom.adventure.run.id==2 and w.kingdom.industry.items.size()==before
	print("C4_CRAFTING ",checks);quit(1 if checks.values().has(false) else 0)
