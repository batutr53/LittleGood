extends "res://scripts/rpg_android_qa.gd"
func shot(name):
	await settle();host.checks["image_"+name]=get_viewport().get_texture().get_image().save_png("user://"+name+".png")==OK
func run():
	game.is_test_session=true;game.save_path="user://selection-android-private.json";var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("selection_failed");return
	w.kingdom.adventure.run.active=false;load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await settle();var p=game.ui.premium;var K=load("res://scripts/kingdom.gd");var C=load("res://scripts/colony.gd");var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];game.view.zoom=1.2
	p.route("building",int(farm.id));await settle();game.ui.close();game.view.display_pan=game.view.pan;game.view.kingdom_layer.animate(0);host.checks.building_outline=game.view.kingdom_layer.structures[int(farm.id)].sprite.material is ShaderMaterial;await shot("selection-android-building")
	var snapshot=w.duplicate(true)
	for route in ["building_upgrade","terrain","settlement"]:
		p.route(route,C.source(w,"wood") if route=="terrain" else int(K.home(w).cell) if route=="settlement" else int(farm.id));await settle();host.checks[route+"_no_scroll"]=game.ui.modal.find_child("SurfaceContent",true,false).size.y<=p.scroll.size.y+1;await shot("selection-android-"+route)
	host.checks.preview_readonly=w==snapshot;p.route("building_upgrade",int(farm.id));await settle();var button=game.ui.modal.find_children("*","Button",true,false).filter(func(b):return b.text=="Geliştirmeyi onayla")[0];var point=button.get_global_rect().get_center();var level=int(farm.level);var wood=int(w.kingdom.stock.wood);var required=int(K.upgrade_cost(farm).wood)*1000
	host.publish("selection_upgrade_ready",{"run_id":host.options.get("run_id",""),"close_point":[point.x,point.y]});var deadline=Time.get_ticks_msec()+20000
	while int(farm.level)==level and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	host.checks.native_upgrade=int(farm.level)==level+1;host.checks.exact_upgrade_cost=w.kingdom.stock.wood==wood-required
	var original=int(farm.cell);var supplies=w.kingdom.stock.duplicate();game.realm_ui.begin("build",farm.kind,int(farm.id));host.checks.move_origin=game.realm_ui.cell==original
	for i in range(w.cells.size()):
		if i!=original and K.valid_site(w,farm.kind,i,int(farm.id)):game.realm_ui.cell=i;break
	var target=game.realm_ui.cell;game.realm_ui.refresh_placement();await shot("selection-android-moving");host.checks.preview_original=int(farm.cell)==original;game.realm_ui.commit();host.checks.move_exact=int(farm.cell)==target and game.view.selected==target;host.checks.move_free=w.kingdom.stock==supplies
	game.ui.close();host.checks.enter=game.enter_adventure("wildwood");await settle();var a=game.adventure_scene;a.frozen=true;var enemy=w.kingdom.adventure.run.enemies[0];enemy.hp=32;enemy.state="idle";a.targeting.choose(int(enemy.id));a.targeting.refresh();host.checks.enemy_outline=a.bodies[int(enemy.id)].get_node("Art").material is ShaderMaterial;a.camera.position=Vector2(enemy.x,enemy.y);await shot("selection-android-enemy");a.targeting.clear();host.checks.clear_enemy=a.bodies[int(enemy.id)].get_node("Art").material==null;a.go_home();await settle();host.checks.valid=Persistence.validate(w);host.checks.save=Persistence.save_world(w,game.save_path);host.checks.restore=not Persistence.load_world(game.save_path).is_empty()
	host.publish("selection_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"source":"real emulator renders; native ADB upgrade confirmation; programmatic move and target actions; private fixture"})
