extends SceneTree
const A=preload("res://scripts/adventure.gd")
const S=preload("res://scripts/sanctuary.gd")
const MAP=preload("res://scripts/sanctuary_map.gd")
func fixture() -> Dictionary:return Persistence.load_world("res://tests/fixtures/planet-v085e2.json")
func active() -> Dictionary:
	var w=fixture();A.enter(w,true,"sanctuary");return w
func _initialize() -> void:
	var checks={};var w=fixture();var previous=w.duplicate(true)
	checks.authentic_e2=not w.is_empty() and Persistence.validate(w) and not S.enabled(w)
	checks.entry=A.enter(w,true,"sanctuary") and S.enabled(w)
	checks.preserved=w.kingdom.industry==previous.kingdom.industry and w.kingdom.trade==previous.kingdom.trade and w.kingdom.claimed==previous.kingdom.claimed
	checks.entry_valid=Persistence.validate(w)
	checks.no_free_claim=not preload("res://scripts/kingdom.gd").claim(w,"main_23") and not S.research(w)
	checks.recipe_ui_schema=S.GEAR.all(func(id):
		var data=preload("res://scripts/industry.gd").recipes()[id]
		return data.name is Array and data.name.size()==2 and data.get("description") is Array and data.description.size()==2 and data.get("building")=="forge")
	var r=w.kingdom.adventure.run
	checks.locked_stone=MAP.path(MAP.START,MAP.SWITCHES[0],r).is_empty()
	checks.locked_relic=MAP.path(MAP.START,MAP.RELIC,r).is_empty()
	checks.plate_route=not MAP.path(MAP.START,MAP.PLATES[0],r).is_empty()
	r.x=roundi(MAP.PLATES[1].x);r.y=roundi(MAP.PLATES[1].y);S.tick(w)
	checks.wrong_plate=r.mechanisms.plates==0
	for p in MAP.PLATES:r.x=roundi(p.x);r.y=roundi(p.y);S.tick(w)
	checks.plates_open=r.mechanisms.plates==2 and not "stone" in MAP.doors(r)
	checks.guardian_route=not MAP.path(Vector2(r.x,r.y),MAP.SWITCHES[0],r).is_empty()
	r.x=820;r.y=560;checks.wrong_switch=S.interact(w)=="wrong_switch" and r.mechanisms.switches==0
	for p in MAP.SWITCHES:r.x=roundi(p.x);r.y=roundi(p.y);S.interact(w)
	checks.runes_open=r.mechanisms.switches==3 and not "runes" in MAP.doors(r)
	checks.puzzles_save=Persistence.save_world(w,"user://sanctuary-test-private.json") and Persistence.load_world("user://sanctuary-test-private.json").kingdom==w.kingdom
	var snap=w.duplicate(true);Persistence.offline(w,w.saved_at+86400);checks.offline_pauses=w.kingdom==snap.kingdom and w.tick==snap.tick
	var ro=w.duplicate(true);ro._read_only=true;snap=ro.duplicate(true);S.tick(ro);S.interact(ro);S.research(ro);A.step(ro,{"attack":true});checks.readonly=ro==snap
	var p=preload("res://scripts/sanctuary_progression_probe.gd").new();p.world=fixture()
	checks.saved_campaign_exploration=p.explore()
	print("SANCTUARY_JOURNEY ",p.error)
	checks.completed_state_valid=Persistence.validate(p.world)
	if checks.saved_campaign_exploration:
		checks.relic_once=S.progress(p.world,"relic")==1 and S.progress(p.world,"returned")==1 and not S.research(p.world)
		checks.final_save=Persistence.save_world(p.world,"user://sanctuary-complete-private.json") and Persistence.load_world("user://sanctuary-complete-private.json").kingdom==p.world.kingdom
	var journeys=[]
	for seed in [7,42,2026]:
		var legal=preload("res://scripts/sanctuary_progression_probe.gd").new();var ok=legal.complete(seed)
		journeys.append({"seed":seed,"complete":ok,"valid":Persistence.validate(legal.world),"error":legal.error})
		if ok:
			checks["material_conservation_"+str(seed)]=legal.world.kingdom.stock.ancient_alloy==1000 and legal.world.kingdom.stock.sentinel_core==0 and legal.world.kingdom.stock.sunstone_fragment==2000
			checks["quest_once_"+str(seed)]=not preload("res://scripts/kingdom.gd").claim(legal.world,"main_23")
			checks["armor_resistance_"+str(seed)]=preload("res://scripts/hero.gd").stats(legal.world).hazard_resist==6
			checks["legal_save_"+str(seed)]=Persistence.save_world(legal.world,"user://sanctuary-legal-private.json") and Persistence.load_world("user://sanctuary-legal-private.json").kingdom==legal.world.kingdom
	checks.legal_campaigns=journeys.all(func(j):return j.complete and j.valid)
	# Synthetic boundary cases below isolate trap timing, interruption and corrupt
	# saves; these are separate from the three unmodified legal campaign journeys.
	w=active();r=w.kingdom.adventure.run;r.x=700;r.y=1070;r.clock=1750
	var hp=w.kingdom.adventure.hero.hp;checks.trap_warning=S.phase(r,"spikes")=="warning";A.step(w,{})
	checks.trap_damage=hp-w.kingdom.adventure.hero.hp==maxi(1,16-int(preload("res://scripts/hero.gd").stats(w).defense)) and S.phase(r,"spikes")=="active"
	hp=w.kingdom.adventure.hero.hp;S.tick(w);S.tick(w);checks.trap_once_per_cycle=w.kingdom.adventure.hero.hp==hp
	checks.trap_damage_save=Persistence.save_world(w,"user://sanctuary-trap-private.json") and Persistence.load_world("user://sanctuary-trap-private.json").kingdom==w.kingdom
	w=active();r=w.kingdom.adventure.run;r.x=700;r.y=1070;r.clock=1750;hp=w.kingdom.adventure.hero.hp;A.step(w,{"dodge":true,"move":Vector2.RIGHT})
	checks.trap_dodge=w.kingdom.adventure.hero.hp==hp
	var snapshot=w.duplicate(true);Persistence.offline(w,w.saved_at+604800);checks.trap_no_offline_damage=w.kingdom==snapshot.kingdom and w.tick==snapshot.tick
	var bad=w.duplicate(true);bad.kingdom.adventure.run.traps.spikes=9000;checks.reject_future_trap=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.adventure.run.mechanisms.switches=3;checks.reject_switch_without_plates=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.adventure.run.chest=true;checks.reject_forged_treasure=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.adventure.regions.ancients.returned=true;checks.reject_return_without_relic=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.adventure.regions.ancients.researched=true;checks.reject_forged_research=not Persistence.validate(bad)
	w=active();r=w.kingdom.adventure.run;var e=r.enemies[0];r.x=740;r.y=900;r.mechanisms.plates=2;hp=w.kingdom.adventure.hero.hp;A.step(w,{})
	checks.sentinel_warning=e.state=="windup" and e.timer==950 and hp==w.kingdom.adventure.hero.hp
	for i in range(19):A.step(w,{})
	checks.sentinel_strike=e.state=="recover" and w.kingdom.adventure.hero.hp<hp and e.pattern==1
	checks.sentinel_opening=S.armor(e,7)==0
	e.state="chase";S.struck(w,e);checks.sentinel_counter=e.state=="windup" and e.timer==500
	w=active();r=w.kingdom.adventure.run;e=r.enemies[1];r.mechanisms.plates=2;r.x=740;r.y=740;hp=w.kingdom.adventure.hero.hp;A.step(w,{})
	checks.shade_warning=e.state=="windup" and hp==w.kingdom.adventure.hero.hp
	for i in range(17):A.step(w,{})
	checks.shade_ray=e.state=="recover" and w.kingdom.adventure.hero.hp<hp
	var pos=Vector2(e.x,e.y);A.step(w,{});checks.shade_relocates=Vector2(e.x,e.y)!=pos
	e=r.enemies[2];checks.warden_shield=S.armor(e,18)==18;e.state="recover";checks.warden_opening=S.armor(e,18)==0
	checks.closed_door_blocks_line=not S.line_clear(Vector2(735,950),Vector2(735,1000),active().kingdom.adventure.run)
	checks.open_door_allows_line=S.line_clear(Vector2(735,950),Vector2(735,1000),r)
	ro=w.duplicate(true);ro._read_only=true;snap=ro.duplicate(true);S.returning(ro);S.picked(ro,{"recipe":"sun_relic"});S.struck(ro,ro.kingdom.adventure.run.enemies[0]);S.enemy_step(ro,ro.kingdom.adventure.run.enemies[1],Callable());checks.direct_readonly=ro==snap
	w=p.world;var saved_run=S.run_of(w).duplicate(true)
	checks.research_cannot_repeat=not S.research(w)
	for id in ["wildwood","iron_hills","ashen_desert","sanctuary"]:
		checks["restore_"+id]=A.enter(w,true,id) and Persistence.validate(w);A.exit(w)
	checks.sanctuary_identity=S.run_of(w)==saved_run
	# Fill the inventory synthetically to verify the real unique-pickup retry.
	w=active();r=w.kingdom.adventure.run;e=r.enemies[2];e.hp=0;A.defeat_enemy(w,e);r.x=210;r.y=185
	var I=preload("res://scripts/industry.gd")
	while w.kingdom.industry.items.size()+w.kingdom.industry.queue.size()<I.MAX_ITEMS:
		w.kingdom.industry.items.append({"id":int(w.kingdom.industry.next_item),"recipe":"iron_sword"});w.kingdom.industry.next_item+=1
	checks.full_relic_stays=S.interact(w)=="full" and S.progress(w,"relic")==0
	S.interact(w);checks.full_relic_no_duplicates=r.loot.filter(func(l):return l.recipe=="sun_relic").size()==1
	checks.full_relic_save=Persistence.save_world(w,"user://sanctuary-full-private.json") and Persistence.load_world("user://sanctuary-full-private.json").kingdom==w.kingdom
	A.exit(w);var spare=int(w.kingdom.industry.items[-1].id);checks.free_capacity=preload("res://scripts/trade.gd").salvage(w,spare)
	A.enter(w,true,"sanctuary");r.x=210;r.y=185;checks.retry_relic=A.interact(w)=="loot" and S.progress(w,"relic")==1
	var relic_id=int(w.kingdom.adventure.regions.ancients.relic_item);checks.protected_relic=not preload("res://scripts/trade.gd").salvage(w,relic_id)
	var count=w.kingdom.industry.items.size();A.interact(w);checks.unique_relic_once=w.kingdom.industry.items.size()==count and w.kingdom.industry.items.filter(func(item):return item.recipe=="sun_relic").size()==1
	checks.relic_not_craftable=not I.queue(w,"sun_relic",int(w.kingdom.buildings.filter(func(b):return b.kind=="forge")[0].id))
	checks.capacity_final_valid=Persistence.validate(w)
	for legacy in ["planet-v085c.json","planet-v085d.json","planet-v085e1.json","planet-v085e2b.json","planet-v085e2.json"]:
		var older=Persistence.load_world("res://tests/fixtures/"+legacy);checks["legacy_"+legacy]=not older.is_empty() and Persistence.save_world(older,"user://sanctuary-legacy-private.json") and Persistence.load_world("user://sanctuary-legacy-private.json").kingdom==older.kingdom
	print("SANCTUARY_LEGAL_JOURNEYS ",journeys)
	print("SANCTUARY_CHECKS ",checks);quit(1 if checks.values().has(false) else 0)
