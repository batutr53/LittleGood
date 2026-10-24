extends "res://scripts/regions_qa.gd"
const SMAP=preload("res://scripts/sanctuary_map.gd")
const S=preload("res://scripts/sanctuary.gd")
func travel(target: Vector2,attack: bool=true) -> bool:
	scene.frozen=false;var r=game.world.kingdom.adventure.run
	var route=SMAP.path(Vector2(r.x,r.y),target,r)
	if route.is_empty():return false
	for dest in route:
		for i in range(140):
			if Vector2(r.x,r.y).distance_to(dest)<13:break
			var cmd=probe.command(dest) if attack else {"move":(dest-Vector2(r.x,r.y)).normalized()}
			scene.movement=cmd.move;scene.actions=cmd;await get_tree().physics_frame
			if game.world.kingdom.adventure.hero.defeated:return false
	scene.movement=Vector2.ZERO;scene.actions.clear();scene.frozen=true
	return Vector2(r.x,r.y).distance_to(target)<70
func touch(stage: String,id: String) -> void:
	host.publish(stage,{"touch":point(id)});await wait_marker(stage)
func run() -> void:
	if host.options.phase=="sanctuary":
		var campaign=preload("res://scripts/desert_progression_probe.gd").new()
		host.checks.legal22=campaign.complete(42);game.world=campaign.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.in_menu=false
		game.hero_ui.destination("sanctuary");await get_tree().create_timer(.4).timeout
		host.publish("sanctuary_entry",{"touch":host.point(prefix(game.ui.modal,"Enter Sunken Sanctuary"))});await wait_marker("sanctuary_entry")
		scene=game.adventure_scene;host.checks.native_entry=is_instance_valid(scene) and scene.region=="sanctuary";scene.controlled=true
		var r=game.world.kingdom.adventure.run;probe.world=game.world;var x=r.x
		host.publish("sanctuary_move",{"stick":[scene.stick.position.x,scene.stick.position.y]});await wait_marker("sanctuary_move")
		host.checks.native_move=r.x>x+15 and scene.action_counts.get("drag",0)>0
		await touch("sanctuary_pack","pack");host.checks.native_pack=scene.frozen and is_instance_valid(scene.pack_panel)
		await touch("sanctuary_pack_pause","pause");host.checks.native_pack_pause=scene.frozen and not is_instance_valid(scene.pack_panel)
		await touch("sanctuary_pack_resume","pause");host.checks.native_pack_resume=not scene.frozen and scene.actions.is_empty()
		host.checks.inscription_path=await travel(SMAP.INSCRIPTION);await touch("sanctuary_inscription","interact");host.checks.native_inscription=r.landmark
		for i in range(2):host.checks["plate_path_"+str(i)]=await travel(SMAP.PLATES[i])
		host.checks.plates=r.mechanisms.plates==2
		for i in range(3):
			host.checks["switch_path_"+str(i)]=await travel(SMAP.SWITCHES[i]);await touch("sanctuary_switch_"+str(i),"interact")
		host.checks.native_switches=r.mechanisms.switches==3
		await shot("android-sanctuary-puzzles");host.checks.checkpoint=game.checkpoint("sanctuary-native-restart")
		host.publish("sanctuary_saved",{"all_passed":not host.checks.values().has(false)});return
	var expected=Persistence.load_world(game.save_path);await game.restore();scene=game.adventure_scene;scene.frozen=true;scene.controlled=true;probe.world=game.world
	host.checks.exact_restore=game.world.kingdom==expected.kingdom and game.world.tick==expected.tick
	host.checks.puzzles_restored=scene.region=="sanctuary" and game.world.kingdom.adventure.run.mechanisms.switches==3
	await shot("android-sanctuary-restored")
	await touch("sanctuary_resume","pause");await touch("sanctuary_attack","attack");await touch("sanctuary_dodge","dodge")
	host.checks.native_attack=scene.action_counts.get("attack",0)>0;host.checks.native_dodge=scene.action_counts.get("dodge",0)>0
	var r=game.world.kingdom.adventure.run;var tick=game.world.tick;var trade=game.world.kingdom.trade.duplicate(true)
	combat_samples=[];previous_frame=Time.get_ticks_usec();measuring=true;var cpu=scene.combat_cpu_us;var steps=scene.physics_steps
	for e in r.enemies:
		if e.hp<=0:continue
		# Developer-only AStar route construction is not used by touch movement.
		# Keep the original inclusive run, then measure sustained combat separately.
		measuring=false
		host.checks["enemy_path_"+str(e.id)]=await travel(Vector2(e.x,e.y),false);scene.frozen=false
		previous_frame=Time.get_ticks_usec();measuring=true
		for i in range(1800):
			if e.hp<=0 or game.world.kingdom.adventure.hero.defeated:break
			var p=Vector2(r.x,r.y);var ep=Vector2(e.x,e.y);var cmd=probe.command(ep)
			scene.movement=cmd.move if p.distance_to(ep)>59 or cmd.get("dodge",false) else Vector2.ZERO;scene.actions=cmd;await get_tree().physics_frame
		scene.movement=Vector2.ZERO;scene.actions.clear();scene.frozen=true
	measuring=false;combat_samples.sort();var total=0.0
	FileAccess.open("user://sanctuary-combat-frames.json",FileAccess.WRITE).store_string(JSON.stringify(combat_samples))
	for ms in combat_samples:total+=ms
	var profile={"scene":"sanctuary_sustained_combat_excluding_test_bot_path_construction","fps":combat_samples.size()*1000.0/maxf(.001,total),"p95_ms":combat_samples[int(combat_samples.size()*.95)] if not combat_samples.is_empty() else 0,"frames":combat_samples.size(),"step_us":(scene.combat_cpu_us-cpu)/maxi(1,scene.physics_steps-steps),"physics_callback_us":scene.presentation_cpu_us/maxi(1,scene.presentation_steps),"effect_draw_us":scene.effect_draw_cpu_us/maxi(1,scene.effect_draws),"setup_ms":scene.startup_ms,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_bytes":OS.get_static_memory_usage(),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"cap":Engine.max_fps}
	host.checks.kills=r.enemies.all(func(e):return e.hp==0)
	for loot in r.loot:
		if not loot.taken:await travel(Vector2(loot.x,loot.y));scene.interact()
	host.checks.relic_path=await travel(SMAP.RELIC);await touch("sanctuary_relic","interact");host.checks.native_relic=S.progress(game.world,"relic")==1
	await shot("android-sun-relic")
	scene.frozen=false;combat_samples=[];previous_frame=Time.get_ticks_usec();measuring=true
	await get_tree().create_timer(8).timeout;measuring=false;scene.frozen=true;combat_samples.sort();var steady_total=0.0
	for ms in combat_samples:steady_total+=ms
	var steady={"scene":"sanctuary_relic_chamber","fps":combat_samples.size()*1000.0/maxf(.001,steady_total),"p95_ms":combat_samples[int(combat_samples.size()*.95)],"frames":combat_samples.size(),"cap":Engine.max_fps}
	host.checks.secret_path=await travel(SMAP.SECRET);scene.interact();host.checks.treasure_path=await travel(SMAP.TREASURE);scene.interact();host.checks.treasure=r.chest
	for loot in r.loot:
		if not loot.taken:await travel(Vector2(loot.x,loot.y));scene.interact()
	host.checks.clocks_paused=game.world.tick==tick and game.world.kingdom.trade==trade
	await touch("sanctuary_home","return");host.checks.home=game.paused and game.view.visible and S.progress(game.world,"returned")==1
	game.realm_ui.ancients();await get_tree().create_timer(.4).timeout
	host.publish("sanctuary_research",{"touch":host.point(prefix(game.ui.modal,"Inspect recovered Sun Relic"))});await wait_marker("sanctuary_research")
	host.checks.native_research=S.progress(game.world,"researched")==1
	await shot("android-sun-research")
	var crafter=preload("res://scripts/adventure_progression_probe.gd").new();crafter.world=game.world;crafter.foundation.world=game.world;crafter.foundation.base.world=game.world;crafter.foundation.base.driver.world=game.world;crafter.foundation.base.driver.rng.state=int(game.world.rng_state)
	for recipe in S.GEAR:
		host.checks["forge_"+recipe]=crafter.craft(recipe)
		var items=game.world.kingdom.industry.items.filter(func(item):return item.recipe==recipe)
		host.checks["equip_"+recipe]=not items.is_empty() and preload("res://scripts/hero.gd").equip(game.world,preload("res://scripts/industry.gd").recipes()[recipe].category,int(items[0].id))
	game.realm_ui.open();await get_tree().create_timer(.4).timeout
	var claim=prefix(game.ui.modal,"Claim verified reward");var scroll=claim.get_parent()
	while scroll and not scroll is ScrollContainer:scroll=scroll.get_parent()
	if scroll:scroll.ensure_control_visible(claim)
	await get_tree().create_timer(.3).timeout;host.publish("sanctuary_claim",{"touch":host.point(claim)});await wait_marker("sanctuary_claim")
	host.checks.native_quest23=game.world.kingdom.claimed.has("main_23") and not preload("res://scripts/kingdom.gd").claim(game.world,"main_23")
	game.ui.language="tr";game.realm_ui.open();await get_tree().create_timer(.7).timeout;await shot("android-quest23-complete-tr")
	host.checks.saved_home=game.checkpoint("sanctuary-qa-end") and Persistence.load_world(game.save_path).kingdom==game.world.kingdom and Persistence.validate(game.world)
	host.publish("sanctuary_complete",{"all_passed":not host.checks.values().has(false),"profile":profile,"steady_profile":steady,"source":"rendered_bot_routes_and_forge_with_external_adb_controls_and_restart"})
