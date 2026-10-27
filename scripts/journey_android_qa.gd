extends "res://scripts/rpg_android_qa.gd"
func shot(name):
	await settle();host.checks["image_"+name]=get_viewport().get_texture().get_image().save_png("user://"+name+".png")==OK
func run():
	game.is_test_session=true;game.save_path="user://journey-android-private.json";var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("journey_failed");return
	w.kingdom.adventure.run.active=false;load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await settle();var p=game.ui.premium;var K=load("res://scripts/kingdom.gd");var I=load("res://scripts/industry.gd");var farm=w.kingdom.buildings.filter(func(b):return b.kind=="furnace")[0];var free=K.assigned(w,0)[0]
	p.route("staffing",int(farm.id));await settle();var assign=game.ui.modal.find_children("*","Button",true,false).filter(func(b):return b.text.begins_with("Ata: "+free.name));host.checks.staffing_action=not assign.is_empty()
	if not assign.is_empty():assign[0].pressed.emit()
	host.checks.actual_worker_assignment=int(free.building)==int(farm.id)
	p.current_recipe="iron_sword"
	for route in ["journey","staffing","bestiary","contracts","forge","recipe","material"]:
		p.route(route,int(farm.id) if route=="staffing" else 0);await settle();host.checks[route+"_no_scroll"]=game.ui.modal.find_child("SurfaceContent",true,false).size.y<=p.scroll.size.y+1;await shot("journey-android-"+route)
	var rows=load("res://scripts/drop_guide.gd").search("legend_mage_weapon","all","mage");host.checks.search_real_sources=rows.size()==3
	p.route("recipe");await settle();var craft=game.ui.modal.find_children("*","Button",true,false).filter(func(b):return b.text=="Dövümü başlat")[0];host.checks.missing_material_blocks=craft.disabled
	for i in range(12):w.tick+=1;K.tick(w)
	var furnace=w.kingdom.buildings.filter(func(b):return b.kind=="furnace")[0];host.checks.real_iron_production=load("res://scripts/estate.gd").collect(w,int(furnace.id)).get("iron",0)>0
	p.route("recipe");await settle();craft=game.ui.modal.find_children("*","Button",true,false).filter(func(b):return b.text=="Dövümü başlat")[0];host.checks.can_craft=not craft.disabled;var iron=int(w.kingdom.stock.iron);var wood=int(w.kingdom.stock.wood);var order_id=int(w.kingdom.industry.next_item)
	craft.pressed.emit();await settle();host.checks.real_order=w.kingdom.industry.queue.any(func(job):return job.recipe=="iron_sword" and int(job.id)==order_id);host.checks.exact_cost=w.kingdom.stock.iron==iron-2000 and w.kingdom.stock.wood==wood-1000
	for i in range(20):w.tick+=1;K.tick(w)
	var forge=w.kingdom.buildings.filter(func(b):return b.kind=="forge")[0];host.checks.completed_order=w.estate.craft_ready.has(order_id);var items=w.kingdom.industry.items.size();host.checks.collect_order=load("res://scripts/estate.gd").collect(w,int(forge.id)).get("crafted",0)>0 and w.kingdom.industry.items.size()>items and not I.item(w,order_id).is_empty();host.checks.collect_once=not load("res://scripts/estate.gd").collect(w,int(forge.id)).has("crafted")
	p.route("journey");await settle();var point=game.ui.modal.find_child("SurfaceBack",true,false).get_global_rect().get_center();host.publish("journey_close_ready",{"run_id":host.options.get("run_id",""),"close_point":[point.x,point.y]});var deadline=Time.get_ticks_msec()+20000
	while game.in_menu and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	host.checks.native_x_closes=not game.in_menu;host.checks.valid=Persistence.validate(w);host.checks.save=Persistence.save_world(w,game.save_path);host.checks.restore=not Persistence.load_world(game.save_path).is_empty();var profiles=[await profile(60),await profile(30)]
	host.publish("journey_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"source":"actual emulator render, programmatic staffing/crafting/collection and native ADB close tap; isolated fixture"})
