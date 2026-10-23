extends SceneTree
const A=preload("res://scripts/adventure.gd")
const R=preload("res://scripts/regions.gd")
const MAP=preload("res://scripts/iron_hills_map.gd")
func _initialize() -> void:
	var checks={}
	var e1=Persistence.load_world("res://tests/fixtures/planet-v085e1.json")
	checks.authentic_e1=not e1.is_empty() and Persistence.validate(e1)
	if e1.is_empty():print(checks);quit(1);return
	checks.no_automatic_migration=not e1.kingdom.adventure.has("regions")
	var locked=Persistence.load_world("res://tests/fixtures/planet-v085d.json");var copy=locked.duplicate(true)
	checks.locked_no_mutation=not A.enter(locked,false,"iron_hills") and locked==copy
	var before=e1.duplicate(true)
	checks.desert_not_fake=not A.enter(e1,false,"ashen_desert") and e1==before
	checks.invalid_region=not A.enter(e1,false,"downloaded_script") and e1==before
	checks.mountain_entry=A.enter(e1,true,"iron_hills") and R.current(e1)=="iron_hills"
	checks.e1_preserved=e1.kingdom.trade==before.kingdom.trade and e1.kingdom.military==before.kingdom.military and e1.kingdom.industry==before.kingdom.industry and e1.kingdom.claimed==before.kingdom.claimed and e1.kingdom.xp==before.kingdom.xp and e1.kingdom.workers==before.kingdom.workers
	checks.wildwood_parked=e1.kingdom.adventure.regions.stored.wildwood==before.kingdom.adventure.run
	checks.valid_entry=Persistence.validate(e1)
	checks.pending_route_preserved=e1.kingdom.trade.caravans[-1]==before.kingdom.trade.caravans[-1]
	var r=e1.kingdom.adventure.run;var p=Vector2(r.x,r.y)
	A.step(e1,{"move":Vector2.UP});checks.movement=Vector2(r.x,r.y)!=p
	checks.collision=MAP.move(Vector2(350,850),Vector2(250,0)).x<357 and MAP.move(Vector2(30,1100),Vector2(-300,0)).x>=30
	checks.paths=not MAP.path(MAP.START,MAP.LANDMARK).is_empty() and not MAP.path(MAP.START,MAP.NODES.ore.point).is_empty()
	checks.no_remote_gather=A.interact(e1)==""
	# Synthetic position/full-storage boundaries; legal journeys below use movement commands.
	r.x=roundi(MAP.NODES.ore.point.x);r.y=roundi(MAP.NODES.ore.point.y)
	var ore=e1.kingdom.stock.ore
	checks.real_gather=A.interact(e1)=="mineral" and r.nodes.ore and r.cargo.ore==6 and e1.kingdom.stock.ore==ore
	checks.no_duplicate_gather=A.interact(e1)=="" and r.cargo.ore==6
	checks.cargo_valid=Persistence.validate(e1)
	var saved=e1.duplicate(true)
	checks.active_roundtrip=Persistence.save_world(e1,"user://e2-test-active.json") and Persistence.load_world("user://e2-test-active.json").kingdom==e1.kingdom
	Persistence.offline(e1,e1.saved_at+86400);checks.home_and_caravan_pause=e1.kingdom==saved.kingdom and e1.tick==saved.tick
	checks.return_material=A.exit(e1) and e1.kingdom.stock.ore==ore+6000 and r.cargo.is_empty()
	checks.no_duplicate_return=not A.exit(e1)
	checks.finite_nodes=not A.revisit(e1) and A.enter(e1,true,"iron_hills") and r.nodes.ore
	r.x=roundi(MAP.NODES.ore.point.x);r.y=roundi(MAP.NODES.ore.point.y);checks.no_reload_farm=A.interact(e1)==""
	A.exit(e1)
	checks.restore_wildwood=A.enter(e1,false,"wildwood") and R.current(e1)=="wildwood" and e1.kingdom.adventure.run.enemies==before.kingdom.adventure.run.enemies and e1.kingdom.adventure.run.loot==before.kingdom.adventure.run.loot
	checks.parked_valid=Persistence.validate(e1)
	A.exit(e1);A.enter(e1,true,"iron_hills");r=e1.kingdom.adventure.run
	r.x=roundi(MAP.NODES.stone.point.x);r.y=roundi(MAP.NODES.stone.point.y)
	var old_stone=e1.kingdom.stock.stone;e1.kingdom.stock.stone=R.capacity(e1)-4000
	checks.capacity_atomic=A.interact(e1)=="full" and not r.nodes.stone and not r.cargo.has("stone")
	e1.kingdom.stock.stone=old_stone;checks.capacity_retry=A.interact(e1)=="mineral" and r.nodes.stone and r.cargo.stone==5
	r.x=roundi(MAP.LANDMARK.x);r.y=roundi(MAP.LANDMARK.y)
	checks.discovery=A.interact(e1)=="mine" and r.landmark and e1.kingdom.history[-1].subject=="forgotten_mine"
	var n=e1.kingdom.history.size();checks.discovery_once=A.interact(e1)=="" and e1.kingdom.history.size()==n
	checks.discovery_saved=Persistence.save_world(e1,"user://e2-mine.json") and Persistence.load_world("user://e2-mine.json").kingdom==e1.kingdom
	var ro=e1.duplicate(true);ro._read_only=true;var original=ro.duplicate(true);A.step(ro,{"attack":true,"move":Vector2.ONE});A.interact(ro)
	checks.readonly=not A.enter(ro,false,"wildwood") and not A.exit(ro) and ro==original
	var bad=e1.duplicate(true);bad.kingdom.adventure.run.region="ashen_desert";checks.unknown_map_rejected=not Persistence.validate(bad)
	bad=e1.duplicate(true);bad.kingdom.adventure.run.nodes.ore=12;checks.bad_nodes_rejected=not Persistence.validate(bad)
	bad=e1.duplicate(true);bad.kingdom.adventure.regions.stored.iron_hills=bad.kingdom.adventure.run.duplicate(true);checks.duplicate_region_rejected=not Persistence.validate(bad)
	bad=e1.duplicate(true);bad.kingdom.adventure.run.enemies[0].kind="thornheart";checks.cross_region_enemy_rejected=not Persistence.validate(bad)
	A.exit(e1);checks.final_save=Persistence.validate(e1)
	for path in ["planet-v085c.json","planet-v085d.json","planet-v085e1.json"]:
		var w=Persistence.load_world("res://tests/fixtures/"+path)
		checks["legacy_"+path]=not w.is_empty() and Persistence.validate(w) and Persistence.save_world(w,"user://e2-legacy.json") and Persistence.load_world("user://e2-legacy.json").kingdom==w.kingdom
	var legal=[]
	for seed in [7,42,2026]:
		var probe=preload("res://scripts/regional_progression_probe.gd").new();var ok=probe.explore(seed)
		legal.append({"seed":seed,"legal_1_21_plus_iron":ok and Persistence.validate(probe.world),"error":probe.error,"steps":probe.steps})
	checks.legal_journeys=legal.all(func(row):return row.legal_1_21_plus_iron)
	print("E2B_LEGAL_JOURNEYS ",legal);print("E2B_CHECKS ",checks);quit(1 if checks.values().has(false) else 0)
