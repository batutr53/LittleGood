extends SceneTree
const A=preload("res://scripts/adventure.gd")
const H=preload("res://scripts/hero.gd")
const R=preload("res://scripts/rpg_progression.gd")
const I=preload("res://scripts/industry.gd")
var game
var checks={}
var trace=[]
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame
func capture(name):
	await settle();await RenderingServer.frame_post_draw
	checks["image_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/battle/"+name+".png")==OK
func supplies(w):
	return w.kingdom.industry.items.filter(func(item):return item.recipe=="healing_potion").size()+int(w.kingdom.adventure.run.cargo.get("herb",0))+int(w.kingdom.stock.herb)/1000
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/battle");DirAccess.make_dir_recursive_absolute("res://docs/benchmarks/battle")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://battle-loop-private.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");w.erase("rpg");game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close()
	checks.enter=game.enter_adventure("wildwood");checks.entry_initializes_mana=w.has("rpg");await settle();var a=game.adventure_scene;a.set_physics_process(false);a.controlled=true;a.frozen=false
	var run=w.kingdom.adventure.run;var hero=w.kingdom.adventure.hero;var p=R.selected(w);run.enemies=A.new_enemies();run.loot=[];run.x=550;run.y=1120;run.invulnerable=0;run.cargo.herb=1;hero.xp=350;hero.hp=100;hero.defeated=false
	var enemy=run.enemies[0];enemy.x=605;enemy.y=1120;enemy.hp=1;enemy.state="windup";enemy.timer=50;enemy.aimx=run.x;enemy.aimy=run.y
	a.camera.position=Vector2(590,1100);a.targeting.choose(1);var hp_before=int(hero.hp);a._physics_process(.05);a.frozen=true
	checks.counterattack_hp=hero.hp<hp_before;checks.hurt_visual=a.battle_feedback.events.any(func(e):return e.kind=="hurt") and a.battle_feedback.hurt_flash>0;checks.hero_damage_number=a.floats.any(func(f):return f.text.contains("HP") and f.color.r>f.color.g)
	checks.enemy_strike_recoil=a.bodies[1].get_node("Art").position!=Vector2(a.bodies[1].get_meta("art_rest"))
	a.refresh_hud();checks.hp_bar_real=a.rpg_health_bar.value==hero.hp;checks.overlay_fits=a.battle_feedback.overlay.size==game.get_viewport_rect().size;trace.append({"phase":"enemy_counterattack","hp_before":hp_before,"hp_after":hero.hp});await capture("counterattack")
	var rng=RandomNumberGenerator.new()
	for seed in range(1000):
		rng.seed=seed;var state=rng.state
		if rng.randi_range(0,999)<int(H.stats(w).crit):run.rng=str(state);break
	hero.cooldowns.attack=0;hero.cooldowns.skill=0;p.mana=70;p.skills[0]=0;p.bar[0]=0;p.cooldowns=[0,0,0,0,0,0];var xp_before=int(hero.xp);var mana_before=float(p.mana)
	a.actions.skill=true;a.actions.skill_slot=0;a.frozen=false;a._physics_process(.05);a.frozen=true;a.refresh_hud()
	checks.kill_real=enemy.hp==0 and enemy.state=="dead";checks.xp_real=hero.xp==xp_before+int(A.enemies().wolf.xp);checks.starter_mana=mana_before-p.mana>=7.6 and mana_before-p.mana<=8;checks.mana_visual=a.battle_feedback.events.any(func(e):return e.kind=="mana_spent");checks.experience_visual=a.battle_feedback.events.any(func(e):return e.kind=="experience");checks.critical_visual=a.battle_feedback.events.any(func(e):return e.kind=="critical");checks.level_real=H.level(hero)==4;checks.level_banner=a.battle_feedback.banner.contains("SEVİYE");checks.xp_bar_live=a.rpg_experience_bar.value==hero.xp-40*9;checks.mp_label_live=a.mana_label.text.contains(str(int(p.mana)))
	checks.hero_faces_attack=a.bodies[0].get_node("Art").flip_h
	checks.loot_real=not run.loot.is_empty() and run.loot.all(func(loot):return not loot.taken);trace.append({"phase":"skill_kill","xp_before":xp_before,"xp_after":hero.xp,"mp_before":mana_before,"mp_after":p.mana,"drops":run.loot.size(),"level":H.level(hero)});await capture("kill-exp-mana")
	var xp_after=int(hero.xp);var loot_after=run.loot.size();A.defeat_enemy(w,enemy);checks.kill_once=hero.xp==xp_after and run.loot.size()==loot_after
	var first=run.loot[0];a.frozen=false;var at=a.get_canvas_transform()*a.battle_feedback.loot_point(first);checks.tap_loot=a.battle_feedback.pick_at(at);a.frozen=true;checks.pickup_model=first.taken;checks.pickup_visual=a.battle_feedback.events.any(func(e):return e.kind=="pickup");var picked=int(run.picked);checks.no_duplicate_pickup=not A.pickup(w,first) and run.picked==picked;await capture("loot-collected")
	hero.hp=H.stats(w).health-35;hero.cooldowns.heal=0;var supply_before=supplies(w);a.actions.heal=true;a.frozen=false;a._physics_process(.05);a.frozen=true;checks.heal_real=hero.hp>H.stats(w).health-35;checks.heal_consumes=supplies(w)==supply_before-1;checks.heal_visual=a.battle_feedback.events.any(func(e):return e.kind=="heal");await capture("healing")
	hero.cooldowns.attack=0;hero.cooldowns.skill=0;p.mana=0;var count=a.battle_feedback.events.filter(func(e):return e.kind=="mana_spent").size();a.actions.skill=true;a.frozen=false;a._physics_process(.05);a.frozen=true;checks.empty_mana_blocks=not R.skill_ready(w,{"skill_slot":0}) and a.battle_feedback.events.filter(func(e):return e.kind=="mana_spent").size()==count and p.mana>=0
	A.drop(run,6000,Vector2(900,500),"gold",1);var far=run.loot[-1];var far_cargo=run.cargo.duplicate();checks.far_loot_guard=A.interact(w,int(far.id))=="far" and not far.taken and run.cargo==far_cargo
	var items=w.kingdom.industry.items.duplicate(true)
	while w.kingdom.industry.items.size()+w.kingdom.industry.queue.size()<I.MAX_ITEMS:
		w.kingdom.industry.items.append({"id":int(w.kingdom.industry.next_item),"recipe":"field_sickle"});w.kingdom.industry.next_item+=1
	A.drop(run,6001,Vector2(run.x+20,run.y),"",1,"iron_sword");var full=run.loot[-1];checks.full_bag_guard=A.interact(w,int(full.id))=="full" and not full.taken;w.kingdom.industry.items=items
	checks.feedback_does_not_award=true;var unchanged=w.duplicate(true);a.battle_feedback.resolve(a.battle_feedback.snapshot());checks.feedback_does_not_award=w==unchanged
	checks.events_bounded=a.battle_feedback.events.size()<=40 and a.floats.size()<=40;checks.save_valid=Persistence.validate(w);checks.save=Persistence.save_world(w,game.save_path);var loaded=Persistence.load_world(game.save_path);checks.restore=not loaded.is_empty() and loaded.kingdom.adventure.hero.xp==hero.xp and loaded.kingdom.adventure.run.loot==run.loot
	for extent in [Vector2i(960,540),Vector2i(1600,720)]:
		a.go_home();await settle();root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();game.ui.build();game.ui.close();checks["reenter_"+str(extent.x)]=game.enter_adventure("wildwood");await settle();a=game.adventure_scene;a.frozen=true;a.battle_feedback.announce("+24 EXP · SAVAŞ GERİ BİLDİRİMİ");a.battle_feedback.hurt_flash=.25;a.battle_feedback.overlay.queue_redraw();checks["overlay_"+str(extent.x)]=a.battle_feedback.overlay.size==Vector2(extent);await capture("feedback-"+str(extent.x))
	var result={"all_passed":not checks.values().has(false),"checks":checks,"count":checks.size(),"trace":trace,"source":"real simulation and presentation in controlled QA fixture; deterministic critical RNG and injured enemy"};var f=FileAccess.open("res://docs/benchmarks/battle/verification.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("BATTLE_LOOP ",checks.size()," passed=",result.all_passed," failures=",checks.keys().filter(func(key):return not checks[key]));quit(0 if result.all_passed else 1)
