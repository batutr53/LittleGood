extends SceneTree
const A=preload("res://scripts/adventure.gd")
const H=preload("res://scripts/hero.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var p=preload("res://scripts/adventure_progression_probe.gd").new();var checks={};checks.legal_hunt=p.hunt();print("PROBE_ERROR ",p.error)
	if p.world.is_empty():quit(1);return
	var w=p.world;var r=w.kingdom.adventure.run;checks.kills=H.progress(w,"kills")==3 and r.enemies.all(func(e):return e.state=="dead")
	checks.materials=w.kingdom.stock.leather>=2000 and w.kingdom.stock.thornhide>=2000 and H.progress(w,"healed")>=1
	checks.exact_save=Persistence.save_world(w,"user://combat-test.json") and Persistence.load_world("user://combat-test.json").kingdom==w.kingdom
	A.enter(w);var before=w.kingdom.duplicate(true)
	for e in r.enemies:A.defeat_enemy(w,e)
	checks.no_death_replay=w.kingdom==before
	var ro=w.duplicate(true);ro._read_only=true;var frozen=ro.duplicate(true);A.hurt(ro,20);A.heal(ro);A.step(ro,{"attack":true});A.exit(ro);checks.readonly=ro==frozen
	print("COMBAT_C3 ",checks);quit(1 if checks.values().has(false) else 0)
