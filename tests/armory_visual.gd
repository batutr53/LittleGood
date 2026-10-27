extends SceneTree
const F=preload("res://scripts/armory.gd")
const R=preload("res://scripts/rpg_progression.gd")
const I=preload("res://scripts/industry.gd")
var game
var checks={}
var capture_dir=OS.get_environment("LITTLEGOD_ARMORY_CAPTURES") if not OS.get_environment("LITTLEGOD_ARMORY_CAPTURES").is_empty() else "res://docs/screenshots/armory"
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
func shot(name):
	await settle();checks["capture_"+name]=root.get_texture().get_image().save_png(capture_dir+"/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute(capture_dir)
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/armory")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://armory-visual.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");preload("res://scripts/estate.gd").start(w);R.ensure(w);F.ensure(w)
	var id=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":id,"recipe":"legend_warrior_weapon"});w.armory.items[str(id)]={"normal":8,"rebirth":5,"element":"fire"}
	w.kingdom.stock.iron=20000;w.kingdom.stock.gold=20000
	for mode in ["normal","reverse","rebirth","element"]:
		var sid=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":sid,"recipe":F.scroll_recipe(mode)})
	game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();game.view.invalidate();game.view.zoom=.7;game.view.pan=Vector2.ZERO
	for extent in [Vector2i(1280,720),Vector2i(960,540),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();game.ui.build();game.ui.close();game.ui.premium.route("inventory");game.ui.premium.rpg.selected_item=id;game.ui.premium.rpg.show_item(id);await shot("inventory-"+str(extent.x))
		for route in ["enhance","bestiary","contracts","sets"]:
			game.ui.premium.route(route,id);await settle();checks[route+str(extent.x)]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.get_global_rect());await shot(route+"-"+str(extent.x))
	root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720);game.ui.build();game.ui.close()
	var rune=F.quote(w,id,"rebirth");checks.confirmation_visible=not rune.is_empty();game.ui.premium.rpg.confirm_upgrade(rune);await shot("upgrade-confirmation")
	checks.confirmation_button=game.ui.modal.find_child("ConfirmEnhancement",true,false)!=null
	game.ui.close()
	for recipe in load("res://scripts/equipment_sets.gd").definitions().warrior.pieces:
		var sid=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":sid,"recipe":recipe});var category=I.recipes()[recipe].category
		if category=="armor":load("res://scripts/hero.gd").equip(w,"armor",sid)
		else:R.extra_equip(w,category,sid)
	game.ui.premium.route("sets");checks.full_set_active=load("res://scripts/equipment_sets.gd").count(w)==5;await shot("full-set");game.ui.close()
	game.ui.premium.craft_filter="scroll";game.ui.premium.route("forge");await shot("scroll-crafting");game.ui.close()
	for cls in R.CLASSES:
		game.ui.close();R.switch(w,cls);var hero=w.kingdom.adventure.hero;hero.xp=maxi(int(hero.xp),400);hero.hp=100;hero.cooldowns.skill=0;w.rpg.progression[cls].cooldowns=[0,0,0,0,0,0];w.rpg.progression[cls].mana=100;w.rpg.progression[cls].skills[0]=1;w.rpg.progression[cls].bar[0]=0
		checks[cls+"_entry"]=game.enter_adventure("wildwood")
		var scene=game.adventure_scene;await settle();scene.actions.skill=true
		var deadline=Time.get_ticks_msec()+750
		while scene.spell_fx.spells.is_empty() and Time.get_ticks_msec()<deadline:await process_frame
		checks[cls+"_cast"]=not scene.spell_fx.spells.is_empty();scene.frozen=true;await shot("spell-"+cls);scene.go_home();await settle()
	checks.state_valid=Persistence.validate(w)
	DirAccess.make_dir_recursive_absolute("res://builds/armory");var result={"checks":checks,"count":checks.size(),"all_passed":not checks.values().has(false),"source":"Actual Godot screenshots; fixtures and synthetic viewport changes, real adventure skill inputs"};var f=FileAccess.open("res://builds/armory/visual.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("ARMORY_VISUAL "+JSON.stringify(result));quit(0 if result.all_passed else 1)
