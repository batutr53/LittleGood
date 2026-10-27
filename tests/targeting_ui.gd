extends SceneTree
const A=preload("res://scripts/adventure.gd")
const R=preload("res://scripts/rpg_progression.gd")
const K=preload("res://scripts/kingdom.gd")
var game
var checks={}
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame
func shot(name):
	await settle();await RenderingServer.frame_post_draw
	checks["image_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/targeting/"+name+".png")==OK
func fits(c):return Rect2(Vector2.ZERO,Vector2(root.size)).grow(1).encloses(c.get_global_rect())
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/targeting");DirAccess.make_dir_recursive_absolute("res://docs/benchmarks/targeting")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://targeting-private.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();R.ensure(w)
	var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];game.view.selected_creature=0;game.view.selected_identity=int(w.creatures[0].identity);game.ui.premium.route("building",int(farm.id));await settle();checks.building_clears_stale_creature=game.view.selected_creature==-1 and game.view.selected==int(farm.cell)
	game.ui.close();var selection=game.ui.root.find_child("WorldSelection",true,false);selection.refresh();checks.building_context_visible=selection.visible and selection.selection.kind=="building" and selection.command.text=="Yönet"
	await shot("building-selected");selection.activate();await settle();checks.manage_real_building=game.ui.premium.current=="building" and game.ui.premium.argument==int(farm.id)
	game.ui.premium.route("inventory");await settle();var p=game.ui.premium;var item=w.kingdom.industry.items[0];p.rpg.selected_item=int(item.id);p.rpg.show_item(int(item.id));await settle()
	var marks=game.ui.modal.find_children("SelectedMark","Label",true,false);checks.item_selection_marker=marks.any(func(mark):return mark.visible)
	checks.navigation_selection=game.ui.root.find_child("NavInventory",true,false).button_pressed;await shot("item-selected")
	var empty_slots=game.ui.modal.find_children("*","Button",true,false).filter(func(b):return b.has_meta("equipment_slot") and int(b.get_meta("item_id"))==0)
	checks.empty_slot_available=not empty_slots.is_empty()
	if not empty_slots.is_empty():
		empty_slots[0].pressed.emit();checks.empty_slot_clears_stale_details=p.rpg.selected_item==0 and not p.rpg.details_window.visible and p.rpg.target_slot==str(empty_slots[0].get_meta("equipment_slot"))
	game.ui.close();checks.navigation_clears=not game.ui.root.find_child("NavInventory",true,false).button_pressed
	var free_cells=range(w.cells.size()).filter(func(index):return not w.kingdom.buildings.any(func(b):return int(b.cell)==index) and not w.settlements.any(func(home):return int(home.cell)==index))
	game.view.selected_creature=0;game.view.selected_identity=int(w.creatures[0].identity);game.view.select_cell(free_cells[0]);selection.refresh();checks.terrain_no_stale_creature=selection.selection.kind=="terrain" and game.view.selected_identity==-1
	selection.clear();checks.clear_world_selection=game.view.selected==-1 and not selection.visible
	var saved=w.duplicate(true)
	for kind in ["wolf","thorn","spider"]:
		var texture=load("res://assets/adventure/"+kind+"-painted-v2.png");checks[kind+"_mobile_texture"]=texture.get_width()<=512;checks[kind+"_transparent"]=texture.get_image().get_pixel(0,0).a<.05
	for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();game.ui.build();game.ui.close()
		checks["enter_"+str(extent.x)]=game.enter_adventure("wildwood");await settle();var a=game.adventure_scene;a.frozen=true;a.controlled=true;var run=w.kingdom.adventure.run
		run.enemies[0].hp=32;run.enemies[0].state="idle";run.enemies[0].x=730;run.enemies[0].y=1120;run.x=550;run.y=1120;a.bodies[0].position=Vector2(run.x,run.y);a.bodies[1].position=Vector2(730,1120);a.bodies[1].get_node("Art").modulate.a=1;a.camera.position=Vector2(650,1100)
		var point=a.get_canvas_transform()*Vector2(730,1085);var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=point
		a.frozen=false;a._unhandled_input(event);a.frozen=true;checks["click_selects_"+str(extent.x)]=a.targeting.selected_id==1 and a.targeting.card.visible;checks["first_click_no_attack_"+str(extent.x)]=not a.actions.get("attack",false)
		a.frozen=false;a._unhandled_input(event);a.frozen=true;checks["second_click_attack_"+str(extent.x)]=a.actions.get("attack",false);a.actions.clear()
		checks["range_truth_"+str(extent.x)]=not a.targeting.in_range();checks["target_card_fits_"+str(extent.x)]=fits(a.targeting.card);checks["target_button_fits_"+str(extent.x)]=fits(a.buttons.target)
		var before=w.duplicate(true);a.targeting.refresh();a.targeting.queue_redraw();checks["presentation_read_only_"+str(extent.x)]=w==before
		await shot("enemy-selected-"+str(extent.x))
		run.enemies[0].state="windup";a.frozen=false;a.targeting.refresh();a.frozen=true;checks["warning_outside_chat_"+str(extent.x)]=a.targeting.warning.text.contains("KAÇIN") and not a.message.get_global_rect().intersects(a.targeting.warning.get_global_rect())
		run.enemies[0].hp=0;a.targeting.refresh();checks["death_clears_"+str(extent.x)]=a.targeting.selected_id==0 and not a.targeting.card.visible
		run.enemies[0].hp=32;run.enemies[0].state="idle";a.frozen=false;a.targeting.cycle();a.frozen=true;checks["cycle_visible_"+str(extent.x)]=a.targeting.selected_id>0
		run.enemies[1].hp=42;run.enemies[1].x=680;run.enemies[1].y=1180;a.targeting.choose(1);a.frozen=false;a.targeting.cycle();a.frozen=true;checks["cycle_changes_target_"+str(extent.x)]=a.targeting.selected_id==2
		var touch=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=Vector2(20,extent.y-175*game.ui.premium.scale_ui());var chosen=a.targeting.selected_id;a._input(touch);checks["chat_touch_safe_"+str(extent.x)]=a.targeting.selected_id==chosen and a.stick_index==-1
		a.go_home();await settle();w=game.world
	# Model contract: selected ranged enemy has priority over array order.
	var combat=saved.duplicate(true);combat.kingdom.adventure.run.active=false;R.switch(combat,"mage");checks.target_model_region=A.enter(combat,false,"wildwood") and load("res://scripts/regions.gd").current(combat)=="wildwood"
	var run=combat.kingdom.adventure.run;run.x=550;run.y=1120;run.enemies=A.new_enemies();run.enemies[0].x=650;run.enemies[0].y=1120;run.enemies[1].x=720;run.enemies[1].y=1120
	var hp0=int(run.enemies[0].hp);var hp1=int(run.enemies[1].hp);combat.kingdom.adventure.hero.cooldowns.attack=0
	A.step(combat,{"attack":true,"target_id":2});checks.selected_ranged_damage=run.enemies[1].hp<hp1 and run.enemies[0].hp==hp0
	checks.basic_range_preserved=R.basic_range(combat)==300;run.enemies[1].x=930;combat.kingdom.adventure.hero.cooldowns.attack=0;var remote=int(run.enemies[1].hp);A.step(combat,{"attack":true,"target_id":2});checks.no_range_bypass=run.enemies[1].hp==remote
	run.enemies[1].x=650;run.enemies[1].y=1000;combat.kingdom.adventure.hero.cooldowns.attack=0;var behind_wall=int(run.enemies[1].hp);A.step(combat,{"attack":true,"target_id":2});checks.no_obstacle_bypass=run.enemies[1].hp==behind_wall
	checks.save_compatible=Persistence.save_world(saved,game.save_path) and not Persistence.load_world(game.save_path).is_empty()
	var result={"checks":checks,"count":checks.size(),"all_passed":not checks.values().has(false),"physical_device":false};var file=FileAccess.open("res://docs/benchmarks/targeting/verification.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));print("TARGETING_UI ",checks.size()," passed=",result.all_passed," failures=",checks.keys().filter(func(key):return not checks[key]));quit(0 if result.all_passed else 1)
