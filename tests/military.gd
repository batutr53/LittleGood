extends SceneTree
const K=preload("res://scripts/kingdom.gd")
const M=preload("res://scripts/military.gd")
const I=preload("res://scripts/industry.gd")
func _initialize() -> void:
	var p=preload("res://scripts/military_progression_probe.gd").new()
	var checks={"legal_1_18":p.defended()};var w=p.world
	if not checks.legal_1_18:print(p.error);quit(1);return
	checks.valid=Persistence.validate(w)
	var soldier=M.available(w)[0];var citizen=int(soldier.worker);var gear=int(soldier.gear)
	checks.no_double_work=not K.assign(w,citizen,0) and not K.assigned(w,0).any(func(c):return c.id==citizen)
	checks.no_soldier_tool=not I.equip(w,citizen,0)
	checks.gear_reserved=M.item_reserved(w,gear)
	checks.no_early_camp=not M.deploy(w,"camp",[int(soldier.id)])
	checks.no_duplicate_units=not M.deploy(w,"raid",[int(soldier.id),int(soldier.id)])
	checks.no_foreign_units=not M.deploy(w,"raid",[999])
	var before=w.kingdom.duplicate(true);var ro=w.duplicate(true);ro._read_only=true
	checks.readonly=not M.enable(ro) and not M.train(ro,citizen,"militia",gear,int(soldier.barracks)) and not M.retire(ro,int(soldier.id)) and not M.recover(ro,int(soldier.id)) and not M.formation(ro,"assault") and not M.deploy(ro,"raid",[int(soldier.id)]) and M.step(ro).is_empty() and not M.return_home(ro) and ro.kingdom==before
	checks.raid=p.battle("raid");checks.real_damage=M.available(w).any(func(u):return u.hp<100)
	checks.claim19=K.claim(w,"main_19");checks.no_reclaim=not K.claim(w,"main_19")
	checks.camp=p.battle("camp");checks.claim20=K.claim(w,"main_20")
	checks.level20=K.level(w)==20 and K.current(w).is_empty() and w.kingdom.claimed.size()==20
	checks.experience=w.kingdom.military.units.all(func(u):return u.xp==40)
	checks.exact_save=Persistence.save_world(w,"user://military-test.json") and Persistence.load_world("user://military-test.json").kingdom==w.kingdom
	var bad=w.duplicate(true);bad.kingdom.military.units[1].worker=citizen;checks.duplicate_citizen=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.military.units[1].gear=gear;checks.duplicate_gear=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.military.units[0].gear=999;checks.missing_gear=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.military.units[0].hp=101;checks.hp_bound=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.military.units[0].status="dead";checks.status_bound=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.military.formation="win";checks.formation_bound=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.military.battle.enemies[0].x=-1;checks.position_bound=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.military.battle.friends[1].id=bad.kingdom.military.battle.friends[0].id;checks.actor_duplicate=not Persistence.validate(bad)
	var sum_before=w.kingdom.industry.items.duplicate(true);checks.retire=M.retire(w,int(soldier.id)) and not M.worker_reserved(w,citizen) and not M.item_reserved(w,gear) and w.kingdom.industry.items==sum_before and Persistence.validate(w)
	# Frozen battle checkpoint: offline time must not resolve combat or consume home stores.
	checks.redeploy=M.deploy(w,"raid",M.available(w).map(func(u):return int(u.id)))
	for i in range(25):M.step(w)
	checks.active_save=Persistence.save_world(w,"user://military-active.json") and Persistence.load_world("user://military-active.json").kingdom==w.kingdom
	before=w.kingdom.duplicate(true);var tick=w.tick;Persistence.offline(w,w.saved_at+86400)
	checks.offline_battle_frozen=w.kingdom==before and w.tick==tick
	checks.adventure_exclusion=not preload("res://scripts/adventure.gd").enter(w)
	checks.no_early_return=not M.return_home(w)
	checks.retreat=M.order(w,"retreat") and M.return_home(w) and not w.kingdom.military.battle.rewarded
	checks.valid_retreat=Persistence.validate(w)
	# Real C fixture was generated at f1684d9 before adding military code.
	var c=Persistence.load_world("res://tests/fixtures/planet-v085c.json")
	checks.actual_c_fixture=Persistence.validate(c)
	K.normalize(c);var old=c.kingdom.duplicate(true);checks.c_optin=M.enable(c)
	checks.c_conservation=c.kingdom.industry==old.industry and c.kingdom.adventure==old.adventure and c.kingdom.stock==old.stock and c.kingdom.claimed==old.claimed
	checks.c_pending_queue=not c.kingdom.industry.queue.is_empty()
	checks.c_once=not M.enable(c) and Persistence.validate(c)
	# Training and recovery use real instructor work and are idempotent per world tick.
	var b=p.world.kingdom.buildings.filter(func(x):return x.kind=="barracks")[0]
	checks.train_again=M.train(w,citizen,"militia",gear,int(b.id))
	var trainee=w.kingdom.military.units[-1];before=trainee.duplicate(true);M.tick(w);checks.same_tick=trainee==before
	K.assign(w,int(K.assigned(w,int(b.id))[0].id),0)
	for i in range(12):p.driver.step()
	checks.instructor_required=trainee.progress==0
	K.assign(w,int(w.kingdom.workers[4].id),int(b.id))
	for i in range(12):p.driver.step()
	checks.training_completes=trainee.status=="ready" and trainee.hp==100
	# Compare identical legal companies under different formations in a real battle.
	var totals=[]
	for f in ["defensive","assault"]:
		var model=w.duplicate(true);M.formation(model,f);M.deploy(model,"raid",M.available(model).map(func(u):return int(u.id)))
		for i in range(3000):
			M.step(model)
			if not model.kingdom.military.battle.result.is_empty():break
		var hp=0
		for u in model.kingdom.military.units:hp+=u.hp
		totals.append([model.kingdom.military.battle.clock,hp])
	checks.tactical_consequence=totals[0]!=totals[1]
	print("MILITARY_CHECKS ",checks," formation_outcomes=",totals)
	quit(1 if checks.values().has(false) else 0)
