extends SceneTree
var game
var checks={}
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame
func click(control):
	var point=control.get_global_rect().get_center();var motion=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion);await process_frame
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.pressed=true;Input.parse_input_event(event);await process_frame;event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await settle()
func capture(id):
	await settle();await RenderingServer.frame_post_draw
	checks["capture_"+id]=root.get_texture().get_image().save_png("res://docs/screenshots/parallel/"+id+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/parallel");DirAccess.make_dir_recursive_absolute("res://builds/parallel")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://parallel-ui-private.json";root.add_child(game);current_scene=game
	# Use the actual player new-world path; no chapter, XP or resource injection.
	game.new_planet(42,"İlk Gün · Özgür Macera",true);game.ui.language="tr";game.ui.build();game.ui.close();await settle()
	var w=game.world;checks.real_new_world=w.has("parallel_play") and w.kingdom.claimed.is_empty() and load("res://scripts/kingdom.gd").level(w)==1
	for route in ["hero","inventory","skills","attributes"]:
		await click(game.ui.root.find_child("Nav"+route.capitalize(),true,false));checks["first_day_"+route]=game.ui.modal!=null and game.ui.premium.current==route
		if route=="inventory":await capture("first-day-inventory")
		game.ui.close();await settle()
	load("res://scripts/colony.gd").ensure(w);var id=int(w.kingdom.workers[0].id);checks.worker_assigned=load("res://scripts/colony.gd").start(w,id,"wood")
	await click(game.ui.root.find_child("OpenHunts",true,false));checks.hunts_open=game.ui.premium.current=="hunts";await capture("first-day-hunts")
	game.hero_ui.destination("wildwood");await settle()
	var enter:Button
	for node in game.ui.modal.find_children("*","Button",true,false):
		if node.text.begins_with("Gir: "):enter=node;break
	checks.entry_button=enter!=null
	if enter!=null:await click(enter)
	checks.native_entry=is_instance_valid(game.adventure_scene)
	if not checks.native_entry:print("PARALLEL_UI entry failed");quit(1);return
	var a=game.adventure_scene;var before=w.tick;var progress=w.colony.jobs[str(id)].progress;game.paused=false
	await create_timer(2.3).timeout
	checks.live_city_clock=w.tick>before and w.colony.jobs[str(id)].progress>progress
	a.toggle_pause();before=w.tick;await create_timer(2.3).timeout;checks.battle_pause_stops_city=w.tick==before;a.toggle_pause();checks.battle_resume=not a.frozen
	var mana=load("res://scripts/rpg_progression.gd").selected(w).mana;await click(a.buttons.skill);await create_timer(.15).timeout
	checks.native_skill=load("res://scripts/rpg_progression.gd").selected(w).mana<mana
	var pos=Vector2(w.kingdom.adventure.run.x,w.kingdom.adventure.run.y)
	# Real viewport joystick drag, not direct movement/state injection.
	var center=a.stick.position;var press=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.position=center;press.pressed=true;Input.parse_input_event(press);await process_frame
	var move=InputEventMouseMotion.new();move.position=center+Vector2(35,0);move.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(move);await create_timer(.4).timeout
	press=press.duplicate();press.position=move.position;press.pressed=false;Input.parse_input_event(press);await settle()
	checks.native_movement=pos.distance_to(Vector2(w.kingdom.adventure.run.x,w.kingdom.adventure.run.y))>1
	for extent in [Vector2i(960,540),Vector2i(1600,720)]:
		a.go_home();await settle();root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();game.ui.build();game.ui.close()
		checks["reenter_"+str(extent.x)]=game.enter_adventure("wildwood");await settle();a=game.adventure_scene
		checks["controls_fit_"+str(extent.x)]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(a.buttons.attack.get_global_rect()) and Rect2(Vector2.ZERO,Vector2(extent)).encloses(a.buttons["return"].get_global_rect())
		await capture("first-day-adventure-"+str(extent.x))
	checks.save=Persistence.save_world(w,game.save_path);var copy=Persistence.load_world(game.save_path);checks.restore=not copy.is_empty() and copy.kingdom.adventure.run==w.kingdom.adventure.run and copy.colony==w.colony
	a.go_home();await settle();checks.return_home=not is_instance_valid(game.adventure_scene) and not w.kingdom.adventure.run.active;checks.valid_after_return=Persistence.validate(w);checks.no_chapters_injected=w.kingdom.claimed.is_empty()
	var report={"all_passed":not checks.values().has(false),"count":checks.size(),"checks":checks,"source":"real first-day world; native viewport mouse buttons and joystick; rendered Godot"};var f=FileAccess.open("res://builds/parallel/ui.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));print("PARALLEL_UI "+JSON.stringify(report));quit(0 if report.all_passed else 1)
