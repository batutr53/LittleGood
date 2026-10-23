extends Node
const A=preload("res://scripts/adventure.gd")
const MAP=preload("res://scripts/iron_hills_map.gd")
var game
var host
var scene
var probe=preload("res://scripts/regional_progression_probe.gd").new()
var measuring=false
var combat_samples=[]
var previous_frame=0
func _process(_delta: float) -> void:
	if measuring:
		var now=Time.get_ticks_usec();combat_samples.append((now-previous_frame)/1000.0);previous_frame=now
func wait_marker(name: String) -> void:
	while not FileAccess.file_exists("user://"+name):await get_tree().process_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://"+name+".png")
func point(id: String) -> Array:return host.point(scene.buttons[id])
func prefix(node: Node,text: String) -> Button:
	if node is Button and node.text.begins_with(text):return node
	for c in node.get_children():
		var found=prefix(c,text)
		if found:return found
	return null
func travel(target: Vector2,attack: bool=true) -> bool:
	scene.frozen=false;var r=game.world.kingdom.adventure.run
	for dest in MAP.path(Vector2(r.x,r.y),target):
		for i in range(140):
			if Vector2(r.x,r.y).distance_to(dest)<13:break
			var cmd=probe.command(dest) if attack else {"move":(dest-Vector2(r.x,r.y)).normalized()}
			scene.movement=cmd.move;scene.actions=cmd;await get_tree().physics_frame
			if game.world.kingdom.adventure.hero.defeated:return false
	scene.movement=Vector2.ZERO;scene.actions.clear();scene.frozen=true
	return Vector2(r.x,r.y).distance_to(target)<80
func run() -> void:
	if host.options.get("phase")=="regions_reopen":
		var expected=Persistence.load_world(game.save_path);await game.restore();scene=game.adventure_scene;scene.frozen=true
		host.checks.exact_restore=game.world.kingdom==expected.kingdom and game.world.tick==expected.tick
		host.checks.region_restore=scene.region=="iron_hills" and game.world.kingdom.adventure.run.nodes.ore and game.world.kingdom.adventure.run.nodes.stone and game.world.kingdom.adventure.run.landmark
		await get_tree().create_timer(.5).timeout;await shot("android-iron-restored")
		host.publish("regions_home_touch",{"home":point("return")});await wait_marker("regions_home")
		host.checks.home=not is_instance_valid(game.adventure_scene) and game.view.visible and game.paused and Persistence.validate(game.world)
		host.checks.material_banked=game.world.kingdom.stock.ore>=expected.kingdom.stock.ore+6000 and game.world.kingdom.stock.stone>=expected.kingdom.stock.stone+5000
		host.checks.trade_preserved=game.world.kingdom.trade==expected.kingdom.trade
		host.checks.saved_home=Persistence.load_world(game.save_path).kingdom==game.world.kingdom
		host.publish("regions_reopened",{"all_passed":not host.checks.values().has(false),"source":"external_adb_process_restart"});return
	host.checks.legal21=probe.base.complete(42);game.world=probe.base.world;probe.world=game.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.in_menu=false
	# A real additional pending route must survive the whole expedition.
	var T=preload("res://scripts/trade.gd");var id=T.dispatch(game.world,"hills",probe.base.merchant,[],{"wood":1});host.checks.pending_route=id>0
	game.hero_ui.world_map();await get_tree().create_timer(.5).timeout;await shot("android-regions-map")
	var card=prefix(game.ui.modal,"Iron Hills ·");var parent=card.get_parent()
	while parent and not parent is ScrollContainer:parent=parent.get_parent()
	if parent:parent.ensure_control_visible(card)
	await get_tree().create_timer(.4).timeout
	host.publish("regions_card_touch",{"card":host.point(card)});await wait_marker("regions_card")
	host.checks.native_card=prefix(game.ui.modal,"Enter Iron Hills")!=null
	host.publish("regions_entry_touch",{"entry":host.point(prefix(game.ui.modal,"Enter Iron Hills"))});await wait_marker("regions_entry")
	scene=game.adventure_scene;host.checks.native_entry=is_instance_valid(scene)
	if not scene:host.publish("regions_failed");return
	scene.controlled=true;var r=game.world.kingdom.adventure.run;var x=r.x;var tick=game.world.tick;var trade=game.world.kingdom.trade.duplicate(true)
	await get_tree().create_timer(.5).timeout;await shot("android-iron-entry")
	host.publish("regions_move_touch",{"stick":[scene.stick.position.x,scene.stick.position.y]});await wait_marker("regions_move")
	host.checks.native_move=r.x>x+15 and scene.action_counts.get("drag",0)>0
	host.checks.movement_no_attack=scene.action_counts.get("attack",0)==0
	host.checks.stone_path=await travel(MAP.NODES.stone.point,false)
	host.publish("regions_stone_touch",{"inspect":point("interact")});await wait_marker("regions_stone")
	host.checks.native_stone=r.nodes.stone and r.cargo.stone==5
	var e=r.enemies[0];host.checks.encounter_path=await travel(Vector2(e.x,e.y),false);scene.frozen=false;scene.actions.clear();var hp=game.world.kingdom.adventure.hero.hp;var warned=false
	for i in range(500):
		if e.state=="windup" and not warned:warned=true;await shot("android-iron-warning")
		if game.world.kingdom.adventure.hero.hp<hp:break
		await get_tree().physics_frame
	host.checks.telegraph=warned;host.checks.enemy_damage=game.world.kingdom.adventure.hero.hp<hp
	scene.frozen=true;host.publish("regions_combat_touch",{"resume":point("pause"),"attack":point("attack"),"dodge":point("dodge"),"heal":point("heal")});await wait_marker("regions_combat")
	host.checks.native_attack=scene.action_counts.get("attack",0)>0;host.checks.native_dodge=scene.action_counts.get("dodge",0)>0
	combat_samples=[];previous_frame=Time.get_ticks_usec();var combat_cpu=scene.combat_cpu_us;var combat_steps=scene.physics_steps;measuring=true
	for enemy in r.enemies:
		if enemy.hp<=0:continue
		await travel(Vector2(enemy.x,enemy.y));scene.frozen=false
		for i in range(1800):
			if enemy.hp<=0 or game.world.kingdom.adventure.hero.defeated:break
			var p=Vector2(r.x,r.y);var ep=Vector2(enemy.x,enemy.y);var cmd=probe.command(ep)
			scene.movement=cmd.move if p.distance_to(ep)>60 or cmd.get("dodge",false) else Vector2.ZERO;scene.actions=cmd;await get_tree().physics_frame
		scene.movement=Vector2.ZERO;scene.frozen=true
	measuring=false;combat_samples.sort();var combat_total=0.0
	for ms in combat_samples:combat_total+=ms
	var live_profile={"scene":"iron_hills_active_encounters","fps":combat_samples.size()*1000.0/maxf(.001,combat_total),"p95_ms":combat_samples[int(combat_samples.size()*.95)] if not combat_samples.is_empty() else 0,"step_us":(scene.combat_cpu_us-combat_cpu)/maxi(1,scene.physics_steps-combat_steps),"cap":Engine.max_fps,"frames":combat_samples.size()}
	host.checks.real_kills=r.enemies.all(func(enemy):return enemy.hp==0)
	host.checks.ore_path=await travel(MAP.NODES.ore.point)
	host.publish("regions_ore_touch",{"inspect":point("interact")});await wait_marker("regions_ore")
	host.checks.native_ore=r.nodes.ore and r.cargo.ore>=6
	host.checks.mine_path=await travel(MAP.LANDMARK)
	host.publish("regions_mine_touch",{"inspect":point("interact")});await wait_marker("regions_mine")
	host.checks.native_mine=r.landmark;game.ui.language="tr";scene.refresh_hud();await shot("android-forgotten-mine-tr")
	scene.frozen=false;var samples=[];var previous=Time.get_ticks_usec();var started=previous;var cpu=scene.combat_cpu_us;var steps=scene.physics_steps
	while Time.get_ticks_usec()-started<8000000:
		await get_tree().process_frame;var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
	samples.sort();var total=0.0
	for ms in samples:total+=ms
	var profile={"scene":"iron_hills_cleared_mine","fps":samples.size()*1000.0/total,"p95_ms":samples[int(samples.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_bytes":OS.get_static_memory_usage(),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"setup_ms":scene.startup_ms,"step_us":(scene.combat_cpu_us-cpu)/maxi(1,scene.physics_steps-steps),"cap":Engine.max_fps}
	scene.frozen=true;host.checks.home_clock_paused=game.world.tick==tick and game.world.kingdom.trade==trade
	host.checks.saved=game.checkpoint("regions-external-restart") and Persistence.load_world(game.save_path).kingdom==game.world.kingdom
	host.publish("regions_complete",{"all_passed":not host.checks.values().has(false),"profile":profile,"combat_profile":live_profile,"source":"rendered_bot_navigation_with_external_adb_controls"})
