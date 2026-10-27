extends "res://scripts/rpg_android_qa.gd"
func run():
	game.is_test_session=true;game.save_path="user://targeting-android-qa.json";var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("targeting_failed");return
	load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.paused=true;game.has_player_world=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();game.view.invalidate()
	var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];game.ui.premium.route("building",int(farm.id));game.ui.close();var selection=game.ui.root.find_child("WorldSelection",true,false);selection.refresh()
	host.checks.world_context=selection.visible and selection.selection.kind=="building";host.checks.context_fits=get_viewport().get_visible_rect().encloses(selection.get_global_rect());await shot("targeting-android-building")
	game.ui.premium.route("inventory");await settle();var p=game.ui.premium;var item=w.kingdom.industry.items[0];p.rpg.selected_item=int(item.id);p.rpg.show_item(int(item.id));host.checks.item_mark=game.ui.modal.find_children("SelectedMark","Label",true,false).any(func(mark):return mark.visible);await shot("targeting-android-item")
	game.ui.close();var original=w.duplicate(true);host.checks.adventure=game.enter_adventure("wildwood")
	if host.checks.adventure:
		await settle();var a=game.adventure_scene;a.frozen=true;a.controlled=true;var run=w.kingdom.adventure.run;run.enemies[0].hp=32;run.enemies[0].state="idle";run.enemies[0].x=730;run.enemies[0].y=1120;run.x=550;run.y=1120;a.bodies[0].position=Vector2(run.x,run.y);a.bodies[1].position=Vector2(730,1120);a.bodies[1].get_node("Art").modulate.a=1;a.camera.position=Vector2(650,1100)
		var touch=InputEventScreenTouch.new();touch.index=1;touch.pressed=true;touch.position=a.get_canvas_transform()*Vector2(730,1085);a.frozen=false;a._input(touch);a.frozen=true
		host.checks.touch_target=a.targeting.selected_id==1;host.checks.tap_no_auto_attack=not a.actions.get("attack",false);host.checks.target_card=a.targeting.card.visible and get_viewport().get_visible_rect().encloses(a.targeting.card.get_global_rect());host.checks.range_truth=not a.targeting.in_range();await shot("targeting-android-enemy")
		run.enemies[0].state="windup";a.frozen=false;a.targeting.refresh();a.frozen=true;host.checks.warning=a.targeting.warning.text.contains("KAÇIN");await shot("targeting-android-warning")
		run.enemies[0].hp=0;a.targeting.refresh();host.checks.dead_cleared=a.targeting.selected_id==0 and not a.targeting.card.visible;a.go_home();await settle()
	host.checks.save=Persistence.save_world(original,game.save_path);host.checks.restore=not Persistence.load_world(game.save_path).is_empty()
	game.world=original;game.view.world=original;game.ui.build();game.ui.close();game.view.invalidate();var profiles=[await profile(60),await profile(30)];game.view.set_quality(false)
	host.publish("targeting_complete",{"run_id":host.options.get("run_id",""),"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"profiles":profiles,"source":"actual_android_emulator_render_with_programmatic_touch_events_no_physical_input_claim"})
