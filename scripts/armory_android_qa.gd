extends "res://scripts/rpg_android_qa.gd"
func run():
	var F=load("res://scripts/armory.gd");var R=load("res://scripts/rpg_progression.gd");game.is_test_session=true;game.save_path="user://armory-android-qa.json"
	var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("armory_failed");return
	load("res://scripts/estate.gd").start(w);R.ensure(w);F.ensure(w)
	w.kingdom.stock.iron=20000;w.kingdom.stock.gold=20000
	for mode in ["normal","reverse","rebirth","element"]:
		var sid=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":sid,"recipe":F.scroll_recipe(mode)})
	var spare=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":spare,"recipe":F.scroll_recipe("normal")})
	game.world=w;game.view.world=w;game.paused=true;game.has_player_world=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();game.view.invalidate()
	var weapon=w.kingdom.industry.items.filter(func(item):return item.recipe=="iron_sword")[0];var id=int(weapon.id)
	game.ui.premium.route("inventory");game.ui.premium.rpg.show_item(id);await shot("armory-android-inventory")
	game.ui.premium.route("enhance",id);await shot("armory-android-anvil")
	var q=F.quote(w,id,"normal");var result=F.attempt(w,id,"normal",int(q.serial));host.checks.upgrade=result.success and F.state(w,id).normal==1
	host.checks.scroll_consumed=load("res://scripts/industry.gd").item(w,int(q.scroll_id)).is_empty()
	host.checks.replay_blocked=F.attempt(w,id,"normal",int(q.serial)).is_empty()
	host.checks.real_stats=load("res://scripts/industry.gd").effects(w,weapon).attack==9
	game.ui.premium.route("bestiary");await shot("armory-android-bestiary")
	game.ui.premium.route("contracts");host.checks.contract=F.claim(w,"refine") and not F.claim(w,"refine");await shot("armory-android-contracts")
	for recipe in ["rpg_warrior_head","rpg_warrior_armor"]:
		var sid=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":sid,"recipe":recipe})
		if recipe.ends_with("head"):R.extra_equip(w,"head",sid)
		else:load("res://scripts/hero.gd").equip(w,"armor",sid)
	host.checks.set_bonus=load("res://scripts/equipment_sets.gd").count(w)==2 and load("res://scripts/equipment_sets.gd").bonuses(w).get("defense")==1
	game.ui.premium.route("sets");await shot("armory-android-sets")
	host.checks.save=Persistence.save_world(w,game.save_path);var loaded=Persistence.load_world(game.save_path);host.checks.restore=not loaded.is_empty() and loaded.armory==w.armory
	game.ui.close();host.checks.adventure=game.enter_adventure("wildwood")
	if host.checks.adventure:
		await settle()
		var hero=w.kingdom.adventure.hero;hero.cooldowns.skill=0;w.rpg.progression.warrior.skills[0]=1;w.rpg.progression.warrior.bar[0]=0;w.rpg.progression.warrior.cooldowns=[0,0,0,0,0,0];w.rpg.progression.warrior.mana=100;game.adventure_scene.actions.skill=true
		var deadline=Time.get_ticks_msec()+1000
		while game.adventure_scene.spell_fx.spells.is_empty() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
		host.checks.spell=not game.adventure_scene.spell_fx.spells.is_empty();await shot("armory-android-spell");game.adventure_scene.go_home();await settle()
	host.checks.valid=Persistence.validate(w)
	var profiles=[await profile(60),await profile(30)];game.view.set_quality(false)
	host.publish("armory_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"source":"actual_android_emulator_render_with_programmatic_model_actions_no_native_input_claim"})
