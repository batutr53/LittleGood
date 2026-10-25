extends SceneTree
const R=preload("res://scripts/rpg_progression.gd")
const A=preload("res://scripts/adventure.gd")
var checks={}
var game
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame
func run():
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://rpg-interaction-private.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await settle()
	var ui=game.ui;var p=ui.premium;var r=p.rpg
	ui.root.find_child("CollapseChat",true,false).pressed.emit()
	checks.chat_minimizes=not r.chat_box.visible and ui.root.find_child("ReopenChat",true,false).visible
	p.route("inventory");ui.close();await settle()
	checks.chat_state_survives_modal=not r.chat_box.visible and ui.root.find_child("ReopenChat",true,false).visible
	ui.root.find_child("ReopenChat",true,false).pressed.emit()
	checks.chat_reopens=r.chat_box.visible and not ui.root.find_child("ReopenChat",true,false).visible
	p.route("inventory");ui.close();await settle()
	checks.open_chat_survives_modal=r.chat_box.visible and not ui.root.find_child("ReopenChat",true,false).visible
	checks.class_switch=R.switch(w,"mage");ui.refresh()
	checks.portrait_matches_active=r.hud_portrait.texture.resource_path=="res://assets/rpg/mage.png"
	p.route("inventory");ui.root.find_child("SelectClasswarrior",true,false).pressed.emit();await settle()
	checks.class_button_switches=w.rpg.active=="warrior" and not p.nested
	game.navigate_back();await settle();checks.class_refresh_back_closes=not is_instance_valid(ui.modal)
	checks.adventure=game.enter_adventure("wildwood");await settle()
	var scene=game.adventure_scene;var run=w.kingdom.adventure.run;var enemy=run.enemies[0]
	checks.travel_allowed_at_safe_spawn=A.can_travel(w)
	var pos=Vector2(enemy.x,enemy.y);var hp=enemy.hp;var state=enemy.state;enemy.x=run.x;enemy.y=run.y-100;enemy.hp=20;enemy.state="chase"
	scene.open_rpg_panel("map");checks.combat_blocks_travel=is_instance_valid(game.adventure_scene) and run.active
	enemy.x=pos.x;enemy.y=pos.y;enemy.hp=hp;enemy.state=state
	var stock=int(w.kingdom.stock.leather);run.cargo={"leather":2};run.picked=2
	scene.open_rpg_panel("map");await settle()
	checks.safe_travel_banks_cargo=int(w.kingdom.stock.leather)==stock+2000 and run.cargo.is_empty()
	checks.safe_travel_opens_map=not is_instance_valid(game.adventure_scene) and p.current=="map" and ui.layer==1
	checks.travel_save_valid=Persistence.validate(w)
	print("RPG_UI_INTERACTIONS ",JSON.stringify(checks));quit(1 if checks.values().has(false) else 0)
