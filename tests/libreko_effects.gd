extends SceneTree
const F=preload("res://scripts/armory.gd")
const R=preload("res://scripts/rpg_progression.gd")
const A=preload("res://scripts/adventure.gd")
var checks={}
var game
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/libreko")
	DirAccess.make_dir_recursive_absolute("res://builds/libreko")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://libreko-effects-private.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");load("res://scripts/estate.gd").start(w);R.ensure(w);F.ensure(w)
	var id=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":id,"recipe":"legend_warrior_weapon"});w.kingdom.adventure.hero.equipment.weapon=id
	for level in range(11):
		w.armory.items[str(id)]={"normal":level,"rebirth":0,"element":"none"};checks["normal_tier_"+str(level)]=F.glow(w,id).level==clampi(level-6,0,4)
	for pair in [[1,1],[5,2],[11,3],[21,4]]:
		w.armory.items[str(id)]={"normal":8,"rebirth":pair[0],"element":"fire"};checks["reverse_tier_"+str(pair[0])]=F.glow(w,id).level==pair[1]
	game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close()
	checks.enter=game.enter_adventure("wildwood");await settle();var a=game.adventure_scene;a.set_physics_process(false);a.frozen=false;a.controlled=true
	var run=w.kingdom.adventure.run;run.enemies=A.new_enemies();run.x=550;run.y=1120;run.facing=[1,0];run.enemies[0].x=605;run.enemies[0].y=1120
	var hero=w.kingdom.adventure.hero;hero.cooldowns.attack=0;a.actions.attack=true;a._physics_process(.05);a.frozen=true
	checks.accepted_swing=not a.spell_fx.weapon_trails.is_empty();var before=a.spell_fx.weapon_trails.size();a.frozen=false;a.actions.attack=true;a._physics_process(.05);a.frozen=true
	checks.cooldown_no_false_trail=a.spell_fx.weapon_trails.size()==before
	a.frozen=false;a.camera.position=Vector2(run.x,run.y);a.refresh_hud()
	a.spell_fx.set_process(false)
	for element in ["none","fire","frost","lightning","poison"]:
		w.armory.items[str(id)].element=element;a.spell_fx.weapon_trails.clear();a.spell_fx.aura=F.glow(w,id);a.spell_fx.weapon_swing(Vector2(run.x,run.y),Vector2.RIGHT,F.glow(w,id));a.spell_fx.weapon_trails[0].age=.16;a.spell_fx.queue_redraw()
		checks["element_profile_"+element]=a.spell_fx.weapon_trails[0].profile.element==element
		await settle();checks["image_"+element]=root.get_texture().get_image().save_png("res://docs/screenshots/libreko/trail-"+element+".png")==OK
	var snapshot=JSON.stringify(w)
	a.spell_fx.low_quality=true
	for i in range(30):a.spell_fx.weapon_swing(Vector2.ZERO,Vector2.RIGHT,F.glow(w,id))
	checks.low_quality_cap=a.spell_fx.weapon_trails.size()==2;a.spell_fx.reduce_motion=true;a.spell_fx._process(.5);checks.trails_expire=a.spell_fx.weapon_trails.is_empty()
	checks.presentation_pure=JSON.stringify(w)==snapshot
	checks.save_valid=Persistence.validate(w);checks.save=Persistence.save_world(w,"user://libreko-effects-roundtrip.json");var restored=Persistence.load_world("user://libreko-effects-roundtrip.json");checks.load=not restored.is_empty() and restored.armory.items[str(id)]==w.armory.items[str(id)]
	var T=load("res://scripts/premium_theme.gd")
	for key in ["hero","bag","quest","hammer","workers","menu","map","shield"]:checks["icon_"+key]=T.icon(key)!=null and T.icon(key).resource_path.begins_with("res://assets/third_party/libreko/")
	for language in ["tr","en"]:
		game.ui.language=language
		for kind in A.enemies():checks["name_"+language+"_"+kind]=not game.realm_ui.localized(A.enemies()[kind].name).is_empty()
	game.ui.language="tr";var first=run.enemies[0];var old_kind=first.kind;var old_hp=first.hp;var old_state=first.state;first.kind="thornheart";first.hp=220;first.state="idle";a.targeting.choose(int(first.id));a.targeting.refresh()
	checks.boss_target_name=a.targeting.title.text.contains("Dikenyürek");first.kind=old_kind;first.hp=old_hp;first.state=old_state
	a.go_home();await settle();game.ui.premium.route("inventory");await settle();checks.inventory_image=root.get_texture().get_image().save_png("res://docs/screenshots/libreko/inventory.png")==OK
	var result={"count":checks.size(),"checks":checks,"all_passed":not checks.values().has(false)};var f=FileAccess.open("res://builds/libreko/effects.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("LIBREKO_EFFECTS "+JSON.stringify(result));quit(0 if result.all_passed else 1)
