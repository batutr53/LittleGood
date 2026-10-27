extends "res://scripts/rpg_android_qa.gd"
func shot(name):
	await settle();host.checks["image_"+name]=get_viewport().get_texture().get_image().save_png("user://"+name+".png")==OK
func active_profile(a,target_fps):
	game.view.set_quality(target_fps==30);a.frozen=false;a.set_physics_process(true);a.controlled=true;a.clear_combat_input();await get_tree().create_timer(2).timeout
	var samples=[];var process_samples=[];var start=Time.get_ticks_usec();var previous=start;var hp_before=int(game.world.kingdom.adventure.hero.hp);var steps=a.physics_steps;var cpu=a.combat_cpu_us
	while Time.get_ticks_usec()-start<4000000:
		await get_tree().process_frame;var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now;process_samples.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	samples.sort();process_samples.sort();a.frozen=true
	return {"scene":"active_melee_enemy_counterattacks","target":target_fps,"fps":samples.size()*1000000.0/(Time.get_ticks_usec()-start),"p95_ms":samples[int(samples.size()*.95)],"process_cpu_p95_ms":process_samples[int(process_samples.size()*.95)],"simulation_ms_per_tick":float(a.combat_cpu_us-cpu)/maxi(1,a.physics_steps-steps)/1000.0,"hero_hp_before":hp_before,"hero_hp_after":game.world.kingdom.adventure.hero.hp,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_memory_mb":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0}
func run():
	var A=load("res://scripts/adventure.gd");var H=load("res://scripts/hero.gd");var R=load("res://scripts/rpg_progression.gd");game.is_test_session=true;game.save_path="user://battle-android-private.json"
	var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("battle_failed");return
	R.ensure(w);load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();host.checks.enter=game.enter_adventure("wildwood");await settle()
	var a=game.adventure_scene;a.controlled=true;a.set_physics_process(false);var run=w.kingdom.adventure.run;var hero=w.kingdom.adventure.hero;var p=R.selected(w);run.enemies=A.new_enemies();run.loot=[];run.cargo.herb=1;run.x=550;run.y=1120;run.invulnerable=0;hero.xp=350;hero.hp=100;hero.defeated=false
	var enemy=run.enemies[0];enemy.x=605;enemy.y=1120;enemy.hp=1;enemy.state="windup";enemy.timer=50;enemy.aimx=run.x;enemy.aimy=run.y;a.camera.position=Vector2(590,1100);a.targeting.choose(1);a._physics_process(.05);a.frozen=true;a.refresh_hud();host.checks.counterattack=hero.hp<100 and a.battle_feedback.hurt_flash>0;await shot("battle-android-counterattack")
	hero.cooldowns.attack=0;hero.cooldowns.skill=0;p.mana=70;p.skills[0]=0;p.bar[0]=0;p.cooldowns=[0,0,0,0,0,0];a.actions.skill=true;a.frozen=false;a._physics_process(.05);a.frozen=true;a.refresh_hud()
	host.checks.kill=enemy.hp==0;host.checks.mana=p.mana<63 and p.mana>62;host.checks.experience=hero.xp==374;host.checks.level=H.level(hero)==4;host.checks.xp_hud=a.rpg_experience_bar.value==14;host.checks.drops=not run.loot.is_empty();host.checks.effects=a.battle_feedback.events.any(func(e):return e.kind=="experience") and a.battle_feedback.events.any(func(e):return e.kind=="mana_spent");await shot("battle-android-kill")
	var loot=run.loot[0];var touch=InputEventScreenTouch.new();touch.index=1;touch.pressed=true;touch.position=a.get_canvas_transform()*a.battle_feedback.loot_point(loot);a.frozen=false;a._input(touch);a.frozen=true;host.checks.touch_pickup=loot.taken;var taken=int(run.picked);host.checks.no_duplicate=not A.pickup(w,loot) and run.picked==taken;await shot("battle-android-pickup")
	hero.hp=H.stats(w).health-35;hero.cooldowns.heal=0;a.actions.heal=true;a.frozen=false;a._physics_process(.05);a.frozen=true;host.checks.heal=hero.hp>H.stats(w).health-35;await shot("battle-android-healing")
	host.checks.valid=Persistence.validate(w);host.checks.save=Persistence.save_world(w,game.save_path);var loaded=Persistence.load_world(game.save_path);host.checks.restore=not loaded.is_empty() and loaded.kingdom.adventure.hero.xp==hero.xp and loaded.kingdom.adventure.run.loot==run.loot
	a.frozen=false;a.open_rpg_panel("inventory");await settle();host.checks.bag_opens=game.ui.premium.current=="inventory" and game.ui.modal!=null
	a.open_rpg_panel("skills");await settle();host.checks.correct_skill_window=game.ui.premium.current=="skills" and game.ui.modal!=null;game.ui.close();a._physics_process(0);await settle();host.checks.window_switch_resumes=not a.rpg_overlay and not a.frozen
	a.open_rpg_panel("hunts");await shot("battle-android-hunts");host.checks.boss_hub=game.ui.premium.current=="hunts";game.ui.close();a._physics_process(0);await settle()
	enemy.hp=32;enemy.state="idle";enemy.x=605;enemy.y=1120;hero.hp=H.stats(w).health;run.invulnerable=0;a.targeting.choose(1)
	var profiles=[await active_profile(a,60),await active_profile(a,30)];host.checks.live_counterattacks=profiles[0].hero_hp_after<profiles[0].hero_hp_before
	host.publish("battle_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"source":"actual emulator rendering, live simulation and programmatic screen-touch pickup; controlled wounded enemy fixture"})
