extends SceneTree
const A=preload("res://scripts/adventure.gd")
const H=preload("res://scripts/hero.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var p=preload("res://scripts/adventure_progression_probe.gd").new();var checks={"legal14":p.equipped_upgrade(42)};var w=p.world;A.enter(w);var r=w.kingdom.adventure.run
	checks.active_save=Persistence.save_world(w,"user://c6-active.json") and Persistence.load_world("user://c6-active.json").kingdom==w.kingdom
	var old=w.duplicate(true);Persistence.offline(w,w.saved_at+86400);checks.offline_safe=w.kingdom==old.kingdom and w.tick==old.tick
	var ro=w.duplicate(true);ro._read_only=true;var before=ro.duplicate(true);A.step(ro,{"attack":true,"move":Vector2.ONE});A.hurt(ro,20);A.heal(ro);A.defeat_enemy(ro,r.enemies[0]);checks.readonly=not A.exit(ro) and not A.enter(ro) and ro==before
	var hp_before=w.kingdom.adventure.hero.hp;checks.cooldown=A.hurt(w,20) and not A.hurt(w,20) and w.kingdom.adventure.hero.hp==hp_before-20+H.stats(w).defense
	for i in range(6):A.step(w,{})
	checks.defeat=A.hurt(w,999) and w.kingdom.adventure.hero.defeated
	var pos=Vector2(r.x,r.y);A.step(w,{"move":Vector2.ONE,"attack":true,"heal":true});checks.defeated_no_actions=Vector2(r.x,r.y)==pos and not A.heal(w)
	checks.defeated_save=Persistence.save_world(w,"user://c6-defeat.json") and Persistence.load_world("user://c6-defeat.json").kingdom==w.kingdom
	checks.recovery=A.exit(w) and not w.kingdom.adventure.hero.defeated and w.kingdom.adventure.hero.hp==H.stats(w).health
	checks.no_equipment_loss=w.kingdom.industry==old.kingdom.industry
	var invalid=w.duplicate(true);invalid.kingdom.adventure.run.enemies[3].pattern=9;checks.bad_pattern=not Persistence.validate(invalid)
	invalid=w.duplicate(true);invalid.kingdom.adventure.run.enemies[3].id=2;checks.duplicate_actor=not Persistence.validate(invalid)
	checks.potion_crafted=p.craft("healing_potion");A.enter(w);A.hurt(w,30);var count=w.kingdom.industry.items.size();checks.potion_consumed=A.heal(w) and w.kingdom.industry.items.size()==count-1
	checks.chest_route=p.travel(MAP_CHEST()) and A.interact(w)=="chest"
	var full=w.duplicate(true);var inventory=full.kingdom.industry
	# Synthetic boundary case only; the legal campaign above uses actual forge labor.
	while inventory.items.size()<32:inventory.items.append({"id":int(inventory.next_item),"recipe":"forest_axe"});inventory.next_item+=1
	var gear=full.kingdom.adventure.run.loot.filter(func(l):return l.recipe=="reinforced_shield")[0]
	checks.capacity=not A.pickup(full,gear) and not gear.taken and inventory.items.size()==32
	inventory.items.pop_back();checks.retry_pickup=A.pickup(full,gear) and inventory.items.size()==32 and gear.taken
	checks.no_duplicate_pickup=not A.pickup(full,gear.duplicate(true)) and inventory.items.size()==32
	checks.no_civilian_sword=not preload("res://scripts/industry.gd").equip(w,int(w.kingdom.workers[0].id),int(w.kingdom.adventure.hero.equipment.weapon))
	print("C6_INVARIANTS ",checks);quit(1 if checks.values().has(false) else 0)
func MAP_CHEST() -> Vector2:return preload("res://scripts/wildwood_map.gd").CHEST
