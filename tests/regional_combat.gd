extends SceneTree
const A=preload("res://scripts/adventure.gd")
func world() -> Dictionary:
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e1.json");A.enter(w,true,"iron_hills");return w
func _initialize() -> void:
	var checks={};var w=world();var r=w.kingdom.adventure.run;var e=r.enemies[0]
	# Synthetic positioning isolates attack rules; legal campaigns exercise full navigation.
	r.x=600;r.y=1000;var hp=w.kingdom.adventure.hero.hp
	A.step(w,{})
	checks.crawler_warning=e.state=="windup" and e.timer==1050 and w.kingdom.adventure.hero.hp==hp
	for i in range(20):A.step(w,{})
	checks.no_early_heavy_hit=w.kingdom.adventure.hero.hp==hp
	A.step(w,{});checks.heavy_hit=e.state=="recover" and w.kingdom.adventure.hero.hp<hp
	checks.heavy_recovery=e.timer==1550
	w=world();r=w.kingdom.adventure.run;e=r.enemies[0];r.x=600;r.y=1000;hp=w.kingdom.adventure.hero.hp;A.step(w,{})
	for i in range(21):A.step(w,{"move":Vector2.DOWN})
	checks.missed_heavy=w.kingdom.adventure.hero.hp==hp and e.state=="recover"
	w=world();r=w.kingdom.adventure.run;e=r.enemies[1];r.x=540;r.y=545;hp=w.kingdom.adventure.hero.hp;A.step(w,{})
	checks.stalker_quick_warning=e.state=="windup" and e.timer==420
	var start=Vector2(e.x,e.y)
	for i in range(9):A.step(w,{})
	checks.stalker_lunge=Vector2(e.x,e.y).distance_to(start)>25 and w.kingdom.adventure.hero.hp<hp
	start=Vector2(e.x,e.y);A.step(w,{})
	checks.stalker_repositions=e.state=="recover" and Vector2(e.x,e.y).distance_to(start)>3
	checks.no_bonus_damage_during_recovery=w.kingdom.adventure.hero.hp<hp and e.timer>0
	var counts=[]
	for seed in [99,123,31415]:
		var probe=preload("res://scripts/regional_progression_probe.gd").new();var ok=probe.explore(seed)
		counts.append({"seed":seed,"legal":ok and Persistence.validate(probe.world),"error":probe.error})
	checks.more_legal_campaigns=counts.all(func(row):return row.legal)
	print("E2B_COMBAT_SEEDS ",counts);print("E2B_COMBAT ",checks);quit(1 if checks.values().has(false) else 0)
