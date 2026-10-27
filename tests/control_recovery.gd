extends SceneTree
var game
var checks={}
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame
func mouse(point,pressed):
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=pressed;Input.parse_input_event(event);await settle()
func run():
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://control-recovery-private.json";root.add_child(game);current_scene=game
	game.world=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.view.world=game.world;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();checks.entry=game.enter_adventure("wildwood");await settle();var a=game.adventure_scene;var run=game.world.kingdom.adventure.run
	var x=int(run.x);await mouse(a.stick.position,true);var motion=InputEventMouseMotion.new();motion.position=a.stick.position+Vector2(45,0);Input.parse_input_event(motion);await create_timer(.45).timeout;checks.real_mouse_moves=run.x>x+20;await mouse(motion.position,false);var stop=int(run.x);await create_timer(.2).timeout;checks.release_stops=not a.mouse_stick and a.movement==Vector2.ZERO and absf(run.x-stop)<=2
	var mana=float(game.world.rpg.progression.warrior.mana);await mouse(a.buttons.skill.get_global_rect().get_center(),true);await mouse(a.buttons.skill.get_global_rect().get_center(),false);await create_timer(.15).timeout;checks.real_skill_works=game.world.rpg.progression.warrior.mana<mana-5
	a.toggle_pause();a.targeting.refresh();checks.pause_explained=a.targeting.warning.text.contains("DURAKLATILDI") and a.targeting.resume_button.visible;var clock=int(run.clock);await create_timer(.15).timeout;checks.pause_stops_clock=run.clock==clock
	a.controlled=true;a.set_physics_process(false);await mouse(a.targeting.resume_button.get_global_rect().get_center(),true);await mouse(a.targeting.resume_button.get_global_rect().get_center(),false);checks.resume_restores_processing=not a.frozen and a.is_physics_processing() and not a.controlled;await create_timer(.15).timeout;checks.resume_clock_advances=run.clock>clock
	a.open_rpg_panel("inventory");await settle();checks.modal_freezes=a.frozen and a.rpg_overlay;a.open_rpg_panel("skills");game.ui.close();await settle();checks.modal_close_recovers=not a.frozen and not a.rpg_overlay
	var touch=InputEventScreenTouch.new();touch.index=2;touch.pressed=true;touch.position=a.stick.position;a._input(touch);var drag=InputEventScreenDrag.new();drag.index=2;drag.position=a.stick.position+Vector2(0,-40);a._input(drag);var y=int(run.y);await create_timer(.2).timeout;checks.touch_moves=run.y<y;touch.pressed=false;a._input(touch);checks.touch_release=a.stick_index==-1 and a.movement==Vector2.ZERO
	a.clear_combat_input();checks.no_stuck_input=not a.mouse_stick and not a.attack_held and a.actions.is_empty();checks.valid_save=Persistence.validate(game.world)
	DirAccess.make_dir_recursive_absolute("res://docs/benchmarks/controls");var result={"count":checks.size(),"checks":checks,"all_passed":not checks.values().has(false)};var f=FileAccess.open("res://docs/benchmarks/controls/verification.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("CONTROL_RECOVERY ",checks.size()," passed=",result.all_passed," failures=",checks.keys().filter(func(k):return not checks[k]));quit(0 if result.all_passed else 1)
