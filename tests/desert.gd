extends SceneTree
const A=preload("res://scripts/adventure.gd")
const D=preload("res://scripts/ashen_desert.gd")
const R=preload("res://scripts/regions.gd")
const MAP=preload("res://scripts/ashen_desert_map.gd")
const K=preload("res://scripts/kingdom.gd")
func fixture() -> Dictionary:return Persistence.load_world("res://tests/fixtures/planet-v085e2b.json")
func active() -> Dictionary:
	var w=fixture();A.enter(w,true,"ashen_desert");return w
func _initialize() -> void:
	var checks={};var w=fixture();var old=w.duplicate(true)
	checks.authentic_e2b=not w.is_empty() and Persistence.validate(w) and not D.enabled(w) and not w.kingdom.stock.has("desert_crystal")
	checks.quest22_optin=K.current(w).is_empty() and K.level(w)==21
	checks.entry=A.enter(w,true,"ashen_desert") and R.current(w)=="ashen_desert" and D.enabled(w)
	checks.previous_preserved=w.kingdom.trade==old.kingdom.trade and w.kingdom.industry==old.kingdom.industry and w.kingdom.military==old.kingdom.military and w.kingdom.workers==old.kingdom.workers and w.kingdom.claimed==old.kingdom.claimed
	checks.legal_cap=K.level(w)==22 and K.current(w).id=="main_22"
	checks.no_free_quest=not K.claim(w,"main_22") and not D.register(w)
	checks.entry_valid=Persistence.validate(w)
	checks.exact_active_save=Persistence.save_world(w,"user://desert-active.json") and Persistence.load_world("user://desert-active.json").kingdom==w.kingdom
	var frozen=w.duplicate(true);Persistence.offline(w,w.saved_at+172800);checks.offline_pauses=w.tick==frozen.tick and w.kingdom==frozen.kingdom
	var r=w.kingdom.adventure.run;var pos=Vector2(r.x,r.y);A.step(w,{"move":Vector2.RIGHT});checks.movement=Vector2(r.x,r.y)!=pos
	checks.collision=MAP.move(Vector2(315,1050),Vector2(220,0)).x<=326
	checks.paths=not MAP.path(MAP.START,MAP.LANDMARK).is_empty() and not MAP.path(MAP.START,MAP.CRYSTAL).is_empty()
	# Synthetic coordinate/HP/capacity boundaries isolate interaction rules.
	r.x=640;r.y=900;checks.oasis=A.interact(w)=="oasis" and r.landmark and D.progress(w,"oasis")==1
	var history=w.kingdom.history.duplicate(true);checks.discovery_once=A.interact(w)=="" and w.kingdom.history==history
	w.kingdom.adventure.hero.hp-=40;checks.oasis_recovery=A.interact(w)=="oasis_heal" and r.recovered
	w.kingdom.adventure.hero.hp-=10;var hp=w.kingdom.adventure.hero.hp;checks.no_repeat_recovery=A.interact(w)=="" and w.kingdom.adventure.hero.hp==hp
	r.x=780;r.y=530;w.kingdom.stock.desert_crystal=R.capacity(w)-5000
	checks.capacity_atomic=A.interact(w)=="full" and not r.nodes.crystal and not r.cargo.has("desert_crystal")
	w.kingdom.stock.desert_crystal=0;checks.gather=A.interact(w)=="crystal" and r.nodes.crystal and r.cargo.desert_crystal==6 and D.progress(w,"picked")==1
	checks.no_refill=A.interact(w)=="" and not A.revisit(w)
	checks.no_kill_forgery=not K.claim(w,"main_22") and not D.register(w)
	checks.depletion_save=Persistence.save_world(w,"user://desert-node.json") and Persistence.load_world("user://desert-node.json").kingdom==w.kingdom
	A.exit(w);checks.return_without_kill=not D.register(w) and D.progress(w,"returned")==0
	checks.ordinary_bank=w.kingdom.stock.desert_crystal==6000
	checks.no_unrelated_material=not K.claim(w,"main_22")
	checks.recipe_needs_proof=not preload("res://scripts/industry.gd").queue(old,"crystal_tonic",int(old.kingdom.buildings.filter(func(b):return b.kind=="forge")[0].id))
	w=active();r=w.kingdom.adventure.run;var e=r.enemies[1];r.x=760;r.y=700;hp=w.kingdom.adventure.hero.hp
	A.step(w,{});checks.scorpion_warning=e.state=="windup" and e.timer==1050 and w.kingdom.adventure.hero.hp==hp
	for i in range(21):A.step(w,{})
	checks.sting=e.state=="recover" and w.kingdom.adventure.hero.hp<hp and D.poisoned(r)
	hp=w.kingdom.adventure.hero.hp;checks.status_before_tick=not D.status_step(w) and w.kingdom.adventure.hero.hp==hp
	for i in range(20):A.step(w,{})
	checks.poison_tick=w.kingdom.adventure.hero.hp==hp-2
	hp=w.kingdom.adventure.hero.hp;D.status_step(w);D.status_step(w);checks.poison_idempotent=w.kingdom.adventure.hero.hp==hp
	checks.poison_roundtrip=Persistence.save_world(w,"user://desert-poison.json") and Persistence.load_world("user://desert-poison.json").kingdom==w.kingdom
	A.exit(w);checks.exit_clears_poison=r.poison_next==0 and r.poison_until==0 and not w.kingdom.adventure.hero.defeated
	w=active();r=w.kingdom.adventure.run;e=r.enemies[2];r.x=650;r.y=540;hp=w.kingdom.adventure.hero.hp
	A.step(w,{});checks.sentinel_target=e.state=="windup" and e.timer==900 and e.aimy==540
	for i in range(18):A.step(w,{"move":Vector2.DOWN})
	checks.sentinel_dodge=w.kingdom.adventure.hero.hp==hp
	r.x=240;r.y=1260;e.state="idle";e.timer=0;A.step(w,{});checks.sentinel_leash=e.state=="guard"
	var bad=w.duplicate(true);bad.kingdom.adventure.run.poison_next=-1;checks.bad_poison=not Persistence.validate(bad)
	var ro=w.duplicate(true);ro._read_only=true;var copy=ro.duplicate(true);A.step(ro,{"move":Vector2.ONE,"attack":true});A.interact(ro)
	checks.readonly=not A.exit(ro) and not D.register(ro) and ro==copy
	D.poison(ro);D.interact(ro);D.status_step(ro);checks.direct_readonly=ro==copy
	bad=w.duplicate(true);bad.kingdom.adventure.regions.quest.kill=true;checks.forged_hunt=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.adventure.regions.quest.picked=true;checks.forged_pickup=not Persistence.validate(bad)
	var exp=active();var run=exp.kingdom.adventure.run;run.x=845;run.y=640;var initial_hp=exp.kingdom.adventure.hero.hp
	A.step(exp,{})
	for i in range(21):A.step(exp,{"move":Vector2.RIGHT,"dodge":true})
	checks.sting_dodge=exp.kingdom.adventure.hero.hp==initial_hp and not D.poisoned(run)
	D.poison(exp);run.x=240;run.y=1260;initial_hp=exp.kingdom.adventure.hero.hp
	for i in range(100):A.step(exp,{})
	checks.poison_bounded=initial_hp-exp.kingdom.adventure.hero.hp==8 and not D.poisoned(run)
	var stock_before=w.kingdom.stock.ore;var bank=w.kingdom.adventure.regions.quest.banked
	A.exit(w);A.enter(w,true,"iron_hills");checks.three_region_switch=Persistence.validate(w) and w.kingdom.adventure.run.nodes.ore and w.kingdom.stock.ore==stock_before and w.kingdom.adventure.regions.quest.banked==bank
	A.exit(w);A.enter(w,true,"wildwood");checks.wildwood_identity=Persistence.validate(w) and w.kingdom.adventure.boss_rewarded
	for path in ["planet-v085c.json","planet-v085d.json","planet-v085e1.json","planet-v085e2b.json"]:
		var legacy=Persistence.load_world("res://tests/fixtures/"+path);checks["legacy_"+path]=not legacy.is_empty() and Persistence.save_world(legacy,"user://desert-legacy.json") and Persistence.load_world("user://desert-legacy.json").kingdom==legacy.kingdom
	var journeys=[]
	for seed in [7,42,2026]:
		var p=preload("res://scripts/desert_progression_probe.gd").new();var ok=p.complete(seed)
		journeys.append({"seed":seed,"legal_1_22":ok and Persistence.validate(p.world),"error":p.error})
		if ok and seed==42:
			var xp=p.world.kingdom.xp;checks.once_quest=not K.claim(p.world,"main_22") and p.world.kingdom.xp==xp and not D.register(p.world)
			var stock=p.world.kingdom.stock.desert_crystal;checks.bank_conservation=stock==9000
			var guarded=p.world.duplicate(true);guarded.kingdom.adventure.regions.quest.registered=false;guarded.kingdom.stock.desert_crystal=2000
			var owned=guarded.duplicate(true);var guarded_forge=guarded.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
			checks.quest_crystal_protected=not preload("res://scripts/industry.gd").queue(guarded,"crystal_tonic",int(guarded_forge.id)) and guarded==owned
			var I=preload("res://scripts/industry.gd");var forge=p.world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
			checks.tonic_queue=I.queue(p.world,"crystal_tonic",int(forge.id))
			for i in range(20):p.base.base.base.driver.step()
			checks.tonic_work=p.world.kingdom.industry.items.any(func(item):return item.recipe=="crystal_tonic") and p.world.kingdom.stock.desert_crystal==stock-2000
			A.enter(p.world,true,"ashen_desert");D.poison(p.world);var count=p.world.kingdom.industry.items.size()
			checks.tonic_cure=A.heal(p.world) and not D.poisoned(p.world.kingdom.adventure.run) and p.world.kingdom.industry.items.size()==count-1
			checks.final_save=Persistence.save_world(p.world,"user://desert-complete.json") and Persistence.load_world("user://desert-complete.json").kingdom==p.world.kingdom
	checks.legal_journeys=journeys.all(func(j):return j.legal_1_22)
	print("DESERT_JOURNEYS ",journeys);print("DESERT_CHECKS ",checks);quit(1 if checks.values().has(false) else 0)
