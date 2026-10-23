extends Node
const A=preload("res://scripts/adventure.gd")
const K=preload("res://scripts/kingdom.gd")
const MAP=preload("res://scripts/wildwood_map.gd")
var game
var host
var checks={}
var probe
var scene
var samples=[]
var measuring=false
var previous=0
var peak_process=0.0
var peak_physics=0.0
var measure_seconds=15.0
func _process(_delta: float) -> void:
	if measuring:
		var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
		peak_process=maxf(peak_process,Performance.get_monitor(Performance.TIME_PROCESS)*1000);peak_physics=maxf(peak_physics,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
func point(id: String) -> Array:
	var p=scene.buttons[id].get_global_rect().get_center();return [p.x,p.y]
func wait_for(name: String) -> void:
	while not FileAccess.file_exists("user://"+name):await get_tree().process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://"+name+".png")
func travel(target: Vector2) -> bool:
	var r=game.world.kingdom.adventure.run
	for dest in MAP.path(Vector2(r.x,r.y),target,false):
		for i in range(160):
			if Vector2(r.x,r.y).distance_to(dest)<12:break
			var command=probe.command(dest);scene.movement=command.move;scene.actions=command;await get_tree().physics_frame
			if game.world.kingdom.adventure.hero.defeated:return false
	scene.movement=Vector2.ZERO;return Vector2(r.x,r.y).distance_to(target)<90
func measure(economy: bool) -> Dictionary:
	game.view.set_quality(economy);Engine.max_fps=30 if economy else 60
	await get_tree().create_timer(1).timeout;samples=[];peak_process=0;peak_physics=0;previous=Time.get_ticks_usec();var started=previous;var cpu=scene.combat_cpu_us;var steps=scene.physics_steps;measuring=true
	await get_tree().create_timer(measure_seconds).timeout;measuring=false;samples.sort()
	return {"quality":"battery" if economy else "smooth","seconds":(Time.get_ticks_usec()-started)/1000000.0,"fps":samples.size()*1000000.0/(Time.get_ticks_usec()-started),"p95_ms":samples[int(samples.size()*.95)],"combat_step_us":(scene.combat_cpu_us-cpu)/maxi(1,scene.physics_steps-steps),"peak_process_ms":peak_process,"peak_physics_ms":peak_physics,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"video_memory_mb":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,"scene_build_ms":scene.startup_ms}
func run() -> void:
	probe=preload("res://scripts/adventure_progression_probe.gd").new();checks.legal14=probe.equipped_upgrade(2026)
	game.world=probe.world;game.has_player_world=true;game.in_menu=false;game.paused=true;game.view.world=game.world;game.view.invalidate();game.ui.close();game.enter_adventure();scene=game.adventure_scene;scene.controlled=true
	if host.options.get("phase")=="adventure_profile":await isolate();return
	var r=game.world.kingdom.adventure.run;var x=r.x
	await RenderingServer.frame_post_draw;await get_tree().create_timer(1).timeout
	host.publish("adventure_move_ready",{"stick":[scene.stick.position.x,scene.stick.position.y]})
	await wait_for("adventure_moved");checks.adb_joystick=r.x>x+15
	checks.adb_joystick_no_attack=scene.action_counts.get("attack",0)==0
	var movement_evidence={"before_x":x,"after_x":r.x,"touch_events":scene.action_counts.get("touch",0),"drag_events":scene.action_counts.get("drag",0)}
	scene.frozen=true;checks.route=await route_to_boss()
	await capture("android-thornheart-ready")
	scene.action_counts={};scene.frozen=true
	host.publish("adventure_combat_ready",{"resume":point("pause"),"attack":point("attack"),"skill":point("skill"),"dodge":point("dodge"),"heal":point("heal"),"interact":point("interact")})
	await wait_for("adventure_attacked")
	for key in ["attack","skill","dodge","heal","interact"]:checks["adb_"+key]=scene.action_counts.get(key,0)>0
	var boss=r.enemies[3];var phase2=false;var warned=false
	samples=[];previous=Time.get_ticks_usec();var battle_start=previous;var battle_cpu=scene.combat_cpu_us;var battle_steps=scene.physics_steps;measuring=true
	for i in range(3000):
		if boss.hp<=0 or game.world.kingdom.adventure.hero.defeated:break
		var command=probe.command(Vector2(boss.x,boss.y));scene.movement=command.move if Vector2(r.x,r.y).distance_to(Vector2(boss.x,boss.y))>58 or command.get("dodge",false) else Vector2.ZERO;scene.actions=command
		if boss.state=="windup" and not warned:await capture("android-thornheart-warning");warned=true
		if boss.hp<=110 and not phase2:await capture("android-thornheart-phase2");phase2=true
		await get_tree().physics_frame
	measuring=false;samples.sort();var battle_elapsed=(Time.get_ticks_usec()-battle_start)/1000000.0
	var battle={"quality":"instrumented_guardian_fight","seconds":battle_elapsed,"fps":samples.size()/maxf(.001,battle_elapsed),"p95_ms":samples[int(samples.size()*.95)] if not samples.is_empty() else 0,"combat_step_us":(scene.combat_cpu_us-battle_cpu)/maxi(1,scene.physics_steps-battle_steps),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	scene.movement=Vector2.ZERO;checks.boss=boss.hp==0;checks.phase2=phase2;checks.warning=warned
	for l in r.loot:
		if not l.taken:await travel(Vector2(l.x,l.y));scene.interact()
	await capture("android-thornheart-victory")
	var profiles=[battle,await measure(false),await measure(true)]
	scene.hide();scene.hud.hide();scene.stick.hide();var control=await measure(false);control.quality="same_simulation_hidden_render_control";profiles.append(control);scene.show();scene.hud.show();scene.stick.show();Engine.max_fps=60
	scene.go_home();checks.realm15=K.claim(game.world,"main_15");game.checkpoint("adventure-qa")
	checks.persisted=Persistence.load_world(game.save_path).kingdom==game.world.kingdom
	game.hero_ui.profile();await get_tree().create_timer(.4).timeout;await capture("android-hero-profile");game.ui.language="tr";game.realm_ui.open();await get_tree().create_timer(.4).timeout;await capture("android-chapter3-tr")
	host.checks=checks;host.publish("adventure_complete",{"all_passed":not checks.values().has(false),"source":"real_android_runtime_bot_with_external_adb_controls","profiles":profiles,"movement_evidence":movement_evidence})
func route_to_boss() -> bool:
	scene.frozen=false
	var ok=await travel(MAP.BOSS);scene.frozen=true;return ok
func isolate() -> void:
	measure_seconds=6;var profiles=[]
	var normal=await measure(false);normal.quality="camp_all";profiles.append(normal)
	for child in scene.actors.get_children():
		if child is Sprite2D:child.material=null
	var plain=await measure(false);plain.quality="no_foliage_shader";profiles.append(plain)
	scene.actors.hide();var actors=await measure(false);actors.quality="actors_hidden";profiles.append(actors)
	scene.get_child(0).hide();var ground=await measure(false);ground.quality="ground_and_actors_hidden";profiles.append(ground)
	scene.effects.hide();scene.props.hide();var effects=await measure(false);effects.quality="hud_only";profiles.append(effects)
	scene.hud.hide();scene.stick.hide();var empty=await measure(false);empty.quality="all_canvas_hidden";profiles.append(empty)
	host.publish("adventure_profile_complete",{"profiles":profiles})
