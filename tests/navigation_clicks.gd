extends SceneTree
var game
var checks={}
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame
func click(control):
	var point=control.get_global_rect().get_center();var motion=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion);await process_frame
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=point;Input.parse_input_event(event);await process_frame;event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await settle()
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/benchmarks/battle");game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://nav-clicks-private.json";root.add_child(game);current_scene=game
	game.new_planet(42,"Nav QA",false);game.ui.language="tr";game.ui.build();game.ui.close()
	for route in ["inventory","hero","skills","attributes"]:
		await click(game.ui.root.find_child("Nav"+route.capitalize(),true,false));checks["locked_"+route]=game.ui.modal!=null and game.ui.premium.current_title=="Özellik henüz açılmadı";game.ui.close();await settle()
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.world=w;game.view.world=w;game.paused=true;game.has_player_world=true;game.show_world(true);game.ui.build();game.ui.close()
	for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();game.ui.build();game.ui.close()
		for route in ["hero","inventory","skills","attributes","quest","map","construction","workers"]:
			await click(game.ui.root.find_child("Nav"+route.capitalize(),true,false));checks["home_"+route+str(extent.x)]=game.ui.modal!=null and game.ui.premium.current==route;game.ui.close();await settle()
		await click(game.ui.root.find_child("OpenHunts",true,false));checks["hunts_"+str(extent.x)]=game.ui.premium.current=="hunts" and game.ui.modal!=null;game.ui.close()
		checks["entry_"+str(extent.x)]=game.enter_adventure("wildwood");await settle();var a=game.adventure_scene;a.controlled=true
		for route in ["inventory","skills","attributes","quest","hero","chat","menu"]:
			await click(a.hud.find_child("CombatNav"+route.capitalize(),true,false));checks["combat_"+route+str(extent.x)]=game.ui.modal!=null and game.ui.premium.current==route and a.rpg_overlay and a.frozen
		game.ui.close();await settle();checks["resume_after_switches_"+str(extent.x)]=not a.frozen and not a.rpg_overlay
		await click(a.buttons.hunts);checks["boss_button_"+str(extent.x)]=game.ui.modal!=null and game.ui.premium.current=="hunts";game.ui.close();await settle();a.go_home();await settle()
	var result={"checks":checks,"count":checks.size(),"all_passed":not checks.values().has(false),"input":"Input.parse_input_event mouse press/release through actual viewport hit testing"};var f=FileAccess.open("res://docs/benchmarks/battle/navigation.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("NAV_CLICKS ",checks.size()," passed=",result.all_passed," failures=",checks.keys().filter(func(k):return not checks[k]));quit(0 if result.all_passed else 1)
