extends SceneTree
const K=preload("res://scripts/kingdom.gd")
const C=preload("res://scripts/colony.gd")
const O=preload("res://scripts/selection_outline.gd")
var game
var checks={}
var capture_dir=OS.get_environment("LITTLEGOD_SELECTION_CAPTURES") if not OS.get_environment("LITTLEGOD_SELECTION_CAPTURES").is_empty() else "res://docs/screenshots/selection"
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame
func find(prefix):
	for button in game.ui.modal.find_children("*","Button",true,false):
		if button.text.begins_with(prefix):return button
	return null
func click(button):
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=button.get_global_rect().get_center();e.pressed=true;Input.parse_input_event(e);await settle();e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await settle()
func shot(name):
	await settle();await RenderingServer.frame_post_draw;checks["image_"+name]=root.get_texture().get_image().save_png(capture_dir+"/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute(capture_dir);DirAccess.make_dir_recursive_absolute("res://docs/benchmarks/selection")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://object-selection-private.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");w.kingdom.adventure.run.active=false;load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await settle();game.view.zoom=1.2;game.view.display_zoom=1.2
	var p=game.ui.premium;var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];p.route("building",int(farm.id));await settle();game.ui.close();game.view.display_pan=game.view.pan;game.view.kingdom_layer.animate(0);var sprite=game.view.kingdom_layer.structures[int(farm.id)].sprite;checks.building_outline=sprite.material is ShaderMaterial and sprite.material.shader==O.SHADER;checks.atlas_boundaries=sprite.material.get_shader_parameter("uv_bounds")!=Vector4(0,0,1,1);await shot("building-outline")
	var hit=false;var missed=false
	for y in range(0,512,16):
		for x in range(0,512,16):
			var local=Vector2(x,y)+sprite.offset;var screen=sprite.get_global_transform_with_canvas()*local
			if sprite.is_pixel_opaque(local):hit=hit or O.hit(sprite,screen)
			else:missed=missed or not O.hit(sprite,screen)
	checks.opaque_hit=hit;checks.transparent_miss=missed;var oldmaterial=sprite.get_meta("selection_original_material").material;game.view.select_cell(-1);game.view.kingdom_layer.animate(0);checks.outline_restored=sprite.material==oldmaterial and not sprite.has_meta("selection_original_material")
	var worker=K.assigned(w,0)[0];p.route("worker",int(worker.id));await settle();game.view.kingdom_layer.animate(0);var index=w.kingdom.workers.find(worker);checks.worker_selected=game.view.selected_worker_id==int(worker.id) and game.view.selected==-1;checks.worker_outline=game.view.kingdom_layer.workers[index].material is ShaderMaterial;game.ui.close();var context=game.ui.root.find_child("WorldSelection",true,false);context.refresh();checks.worker_context=context.selection.kind=="worker" and context.selection.id==int(worker.id);await shot("worker-outline")
	var cell=C.source(w,"wood");p.route("terrain",cell);await settle();checks.terrain_action=find("Toplamaya ata:")!=null;find("Toplamaya ata:").pressed.emit();await settle();checks.exact_node=w.colony.jobs[str(int(worker.id))].cell==cell;checks.cannot_double_assign=not C.start(w,int(worker.id),"fish",cell);checks.worker_detail=p.current=="worker";C.release(w,int(worker.id))
	var before=w.duplicate(true)
	checks.invalid_node_rejected=not C.start(w,int(worker.id),"wood",C.source(w,"water")) and not C.start(w,int(worker.id),"wood",w.cells.size())
	for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle()
		for locale in ["tr","en"]:
			game.ui.language=locale;game.ui.build();p=game.ui.premium
			for route in ["building","building_upgrade","terrain","settlement"]:
				p.route(route,cell if route=="terrain" else int(K.home(w).cell) if route=="settlement" else int(farm.id));await settle();var key=route+str(extent.x)+locale;checks[key+"_no_scroll"]=game.ui.modal.find_child("SurfaceContent",true,false).size.y<=p.scroll.size.y+1;checks[key+"_fits"]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.get_global_rect())
				if locale=="tr":await shot(route+"-"+str(extent.x))
	checks.preview_no_mutation=w==before;game.ui.language="tr";game.ui.build();p=game.ui.premium;p.route("building_upgrade",int(farm.id));await settle();var oldlevel=int(farm.level);var gold=int(w.kingdom.stock.gold);var cost=K.upgrade_cost(farm);var stock=w.kingdom.stock.duplicate();await click(find("Geliştirmeyi onayla"));checks.native_upgrade=int(farm.level)==oldlevel+1;checks.exact_payment=cost.keys().all(func(key):return w.kingdom.stock[key]==stock[key]-int(cost[key])*1000);checks.no_unrelated_gold=w.kingdom.stock.gold==gold-int(cost.get("gold",0))*1000;checks.upgrade_construction=not K.ready(farm)
	p.route("building_upgrade",int(farm.id));await settle();checks.ongoing_upgrade_blocked=find("Geliştirmeyi onayla").disabled
	var oldcell=int(farm.cell);var unchanged=w.duplicate(true);game.realm_ui.begin("build",farm.kind,int(farm.id));checks.move_starts_at_original=game.realm_ui.cell==oldcell;var target=-1
	for i in range(w.cells.size()):
		if i!=oldcell and K.valid_site(w,farm.kind,i,int(farm.id)):target=i;break
	game.realm_ui.cell=target;game.realm_ui.refresh_placement();checks.move_preview_no_mutation=w==unchanged;game.realm_ui.finish();checks.move_cancel_preserves=int(farm.cell)==oldcell
	game.realm_ui.begin("build",farm.kind,int(farm.id));game.realm_ui.cell=target;game.realm_ui.refresh_placement();var oldstock=w.kingdom.stock.duplicate();game.realm_ui.commit();await settle();checks.move_commit=int(farm.cell)==target and game.view.selected==target;checks.move_free=w.kingdom.stock==oldstock;checks.move_returns_correct_panel=p.current=="building" and p.argument==int(farm.id);await shot("moved-building")
	checks.valid=Persistence.validate(w);checks.save=Persistence.save_world(w,game.save_path) and not Persistence.load_world(game.save_path).is_empty()
	game.ui.close();checks.enter_battle=game.enter_adventure("wildwood");await settle();var a=game.adventure_scene;a.frozen=true;a.controlled=true;var enemy=w.kingdom.adventure.run.enemies[0];enemy.hp=32;enemy.state="idle";a.targeting.choose(int(enemy.id));a.targeting.refresh();checks.enemy_outline=a.bodies[int(enemy.id)].get_node("Art").material is ShaderMaterial;a.camera.position=Vector2(enemy.x,enemy.y);await shot("enemy-outline");await click(a.targeting.inspect_button);checks.enemy_context=game.ui.premium.current=="enemy_info" and game.ui.premium.argument==int(enemy.id) and a.frozen;await shot("enemy-context");game.ui.close();await settle();checks.context_restores_pause=a.frozen and not a.rpg_overlay;a.targeting.clear();checks.enemy_clear=a.bodies[int(enemy.id)].get_node("Art").material==null;a.go_home();await settle()
	var result={"count":checks.size(),"checks":checks,"all_passed":not checks.values().has(false)};var f=FileAccess.open("res://docs/benchmarks/selection/verification.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("OBJECT_SELECTION ",checks.size()," passed=",result.all_passed," failures=",checks.keys().filter(func(k):return not checks[k]));quit(0 if result.all_passed else 1)
