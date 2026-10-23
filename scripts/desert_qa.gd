extends "res://scripts/regions_qa.gd"
const DMAP=preload("res://scripts/ashen_desert_map.gd")
const D=preload("res://scripts/ashen_desert.gd")
func travel(target: Vector2,attack: bool=true) -> bool:
	scene.frozen=false;var r=game.world.kingdom.adventure.run
	for dest in DMAP.path(Vector2(r.x,r.y),target):
		for i in range(140):
			if Vector2(r.x,r.y).distance_to(dest)<13:break
			var input=probe.command(dest) if attack else {"move":(dest-Vector2(r.x,r.y)).normalized()}
			scene.movement=input.move;scene.actions=input;await get_tree().physics_frame
			if game.world.kingdom.adventure.hero.defeated:return false
	scene.movement=Vector2.ZERO;scene.actions.clear();scene.frozen=true;return Vector2(r.x,r.y).distance_to(target)<80
func run() -> void:
	if host.options.get("phase")=="desert":
		host.checks.legal21_and_hills=probe.explore(42);game.world=probe.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.in_menu=false
		var T=preload("res://scripts/trade.gd");host.checks.pending_route=T.dispatch(game.world,"hills",probe.base.merchant,[],{"wood":1})>0
		game.hero_ui.world_map();await get_tree().create_timer(.5).timeout
		var card=prefix(game.ui.modal,"Ashen Desert ·");var p=card.get_parent()
		while p and not p is ScrollContainer:p=p.get_parent()
		if p:p.ensure_control_visible(card)
		await get_tree().create_timer(.4).timeout;await shot("android-desert-map")
		host.publish("desert_card_touch",{"card":host.point(card)});await wait_marker("desert_card")
		host.publish("desert_entry_touch",{"entry":host.point(prefix(game.ui.modal,"Enter Ashen Desert"))});await wait_marker("desert_entry")
		scene=game.adventure_scene;host.checks.native_entry=is_instance_valid(scene) and scene.region=="ashen_desert";scene.controlled=true
		var r=game.world.kingdom.adventure.run;var x=r.x;await get_tree().create_timer(.5).timeout;await shot("android-desert-entry")
		host.publish("desert_move_touch",{"stick":[scene.stick.position.x,scene.stick.position.y]});await wait_marker("desert_move")
		host.checks.native_move=r.x>x+15 and scene.action_counts.get("drag",0)>0 and scene.action_counts.get("attack",0)==0
		host.checks.oasis_path=await travel(DMAP.LANDMARK)
		host.publish("desert_oasis_touch",{"inspect":point("interact")});await wait_marker("desert_oasis")
		host.checks.native_oasis=r.landmark and D.progress(game.world,"oasis")==1;await shot("android-oasis-discovery")
		var e=r.enemies[1];await travel(Vector2(e.x,e.y),false);scene.frozen=false;var warned=false
		for i in range(500):
			if e.state=="windup" and not warned:warned=true;await shot("android-scorpion-warning")
			if D.poisoned(r):break
			scene.movement=(Vector2(e.x,e.y)-Vector2(r.x,r.y)).normalized() if Vector2(r.x,r.y).distance_to(Vector2(e.x,e.y))>65 else Vector2.ZERO;await get_tree().physics_frame
		scene.movement=Vector2.ZERO;scene.frozen=true;scene.refresh_hud();host.checks.warning=warned;host.checks.actual_poison=D.poisoned(r)
		await shot("android-desert-poison");host.checks.poison_checkpoint=game.checkpoint("native-poison-restart")
		host.publish("desert_poison_saved",{"all_passed":not host.checks.values().has(false)});return
	var expected=Persistence.load_world(game.save_path);await game.restore();scene=game.adventure_scene;scene.frozen=true;scene.controlled=true;probe.world=game.world
	host.checks.exact_poison_restore=game.world.kingdom==expected.kingdom and game.world.tick==expected.tick
	host.checks.status_restore=D.poisoned(game.world.kingdom.adventure.run) and scene.region=="ashen_desert"
	await get_tree().create_timer(.4).timeout;await shot("android-desert-restored")
	host.publish("desert_combat_touch",{"resume":point("pause"),"attack":point("attack"),"dodge":point("dodge"),"heal":point("heal")});await wait_marker("desert_combat")
	host.checks.native_attack=scene.action_counts.get("attack",0)>0;host.checks.native_dodge=scene.action_counts.get("dodge",0)>0
	var r=game.world.kingdom.adventure.run;combat_samples=[];previous_frame=Time.get_ticks_usec();var cpu=scene.combat_cpu_us;var steps=scene.physics_steps;measuring=true
	for e in r.enemies:
		if e.hp<=0:continue
		await travel(Vector2(e.x,e.y));scene.frozen=false
		for i in range(1800):
			if e.hp<=0 or game.world.kingdom.adventure.hero.defeated:break
			var pos=Vector2(r.x,r.y);var ep=Vector2(e.x,e.y);var command=probe.command(ep)
			scene.movement=command.move if pos.distance_to(ep)>60 or command.get("dodge",false) else Vector2.ZERO;scene.actions=command;await get_tree().physics_frame
		scene.movement=Vector2.ZERO;scene.frozen=true
	measuring=false;combat_samples.sort();var total=0.0
	for ms in combat_samples:total+=ms
	var battle={"scene":"ashen_desert_encounters","fps":combat_samples.size()*1000.0/maxf(.001,total),"p95_ms":combat_samples[int(combat_samples.size()*.95)] if not combat_samples.is_empty() else 0,"step_us":(scene.combat_cpu_us-cpu)/maxi(1,scene.physics_steps-steps),"frames":combat_samples.size(),"cap":Engine.max_fps}
	host.checks.real_kills=r.enemies.all(func(e):return e.hp==0)
	for loot in r.loot:
		if not loot.taken:await travel(Vector2(loot.x,loot.y));scene.interact()
	host.checks.crystal_path=await travel(DMAP.CRYSTAL)
	host.publish("desert_crystal_touch",{"inspect":point("interact")});await wait_marker("desert_crystal")
	host.checks.native_crystal=r.nodes.crystal;await shot("android-desert-crystal")
	await travel(DMAP.ROAD);scene.interact();host.checks.road=r.road;scene.frozen=false;combat_samples=[];previous_frame=Time.get_ticks_usec();measuring=true
	await get_tree().create_timer(8).timeout;measuring=false;combat_samples.sort();total=0.0
	for ms in combat_samples:total+=ms
	var profile={"scene":"ashen_desert_cleared_road","fps":combat_samples.size()*1000.0/total,"p95_ms":combat_samples[int(combat_samples.size()*.95)],"setup_ms":scene.startup_ms,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_bytes":OS.get_static_memory_usage(),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"cap":Engine.max_fps}
	scene.frozen=true;host.checks.clock_and_trade=game.world.tick==expected.tick and game.world.kingdom.trade==expected.kingdom.trade
	host.publish("desert_home_touch",{"home":point("return")});await wait_marker("desert_home")
	game.realm_ui.desert_report();await get_tree().create_timer(.4).timeout
	host.publish("desert_register_touch",{"register":host.point(prefix(game.ui.modal,"Register 1 crystal"))});await wait_marker("desert_register")
	host.checks.native_registered=D.progress(game.world,"registered")==1
	game.realm_ui.open();await get_tree().create_timer(.4).timeout
	var claim=prefix(game.ui.modal,"Claim verified reward");var parent=claim.get_parent()
	while parent and not parent is ScrollContainer:parent=parent.get_parent()
	if parent:parent.ensure_control_visible(claim)
	await get_tree().create_timer(.3).timeout;host.publish("desert_claim_touch",{"claim":host.point(claim)});await wait_marker("desert_claim")
	host.checks.native_quest22=game.world.kingdom.claimed.has("main_22") and not preload("res://scripts/kingdom.gd").claim(game.world,"main_22")
	game.ui.language="tr";game.realm_ui.open();await shot("android-quest22-complete-tr")
	host.checks.saved_home=game.checkpoint("desert-complete") and Persistence.load_world(game.save_path).kingdom==game.world.kingdom and Persistence.validate(game.world)
	host.publish("desert_complete",{"all_passed":not host.checks.values().has(false),"combat_profile":battle,"profile":profile,"source":"external_adb_controls_and_process_restart_with_bot_navigation"})
