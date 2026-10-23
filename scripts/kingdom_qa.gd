extends Node
const K=preload("res://scripts/kingdom.gd")
var game
var directory="res://builds/phase085"
var checks: Dictionary={}
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().create_timer(.7).timeout;await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
func find_button(node: Node,text: String) -> Button:
	if node is Button and node.text==text:return node
	for child in node.get_children():
		var result=find_button(child,text)
		if result:return result
	return null
func step(count: int) -> void:
	for i in range(count):game.advance_tick()
func run() -> Dictionary:
	game.new_planet(2026,"First Flame",false);game.has_player_world=true;game.paused=true;game.is_test_session=false
	game.diagnostics.configure("user://phase085-qa-diagnostics.json","simulated")
	game.ui.language="en";game.ui.build();game.ui.close();game.realm_ui.open()
	await capture("advisor-intro")
	var start=find_button(game.ui.modal,"Awaken the First Kingdom");checks.real_intro_button=start!=null
	if start:start.pressed.emit()
	await capture("quest-01");checks.intro_enabled=game.world.has("kingdom")
	game.realm_ui.navigate("settlers");await get_tree().create_timer(.7).timeout
	game.touch_world(game.view.screen_point(game.world.cells[int(K.home(game.world).cell)]))
	checks.met_settlers=K.progress(game.world,{"kind":"event","key":"observe_settlement"})>=1
	game.realm_ui.begin("gather","wood");await capture("gather-preview");game.realm_ui.commit();step(4)
	game.realm_ui.begin("gather","wood");game.realm_ui.commit()
	checks.actual_gather=K.progress(game.world,{"kind":"event","key":"gather_wood"})==6
	game.realm_ui.claim_reward("main_01");checks.realm_two=K.level(game.world)==2
	game.realm_ui.begin("build","lumber");await capture("building-preview");game.realm_ui.commit()
	checks.real_construction=game.world.kingdom.buildings.size()==1 and not K.ready(game.world.kingdom.buildings[0])
	await capture("construction");step(4)
	var camp=int(game.world.kingdom.buildings[0].id)
	game.realm_ui.assignments(int(game.world.kingdom.workers[0].id));await get_tree().process_frame
	var assign=find_button(game.ui.modal,"Lumber Camp · 0 / 2");checks.assignment_button=assign!=null
	if assign:assign.pressed.emit()
	step(20);await capture("working-camp")
	checks.real_worker_output=K.progress(game.world,{"kind":"event","key":"produce_wood"})>0
	game.realm_ui.workers();await capture("workers")
	game.ui.close()
	var driver=preload("res://scripts/kingdom_progression_probe.gd").new();driver.start(2026)
	checks.full_progression=driver.through_first_flame()
	game.world=driver.world;game.view.world=game.world;game.rng.state=int(game.world.rng_state);game.view.invalidate();game.view.pan=Vector2.ZERO;game.view.zoom=.88;game.paused=true
	game.ui.close();await capture("first-village");game.realm_ui.open();await capture("chapter-complete")
	game.realm_ui.construction();await capture("buildings");game.ui.language="tr";game.realm_ui.open();await capture("kingdom-tr");game.ui.language="en"
	checks.real_save=game.checkpoint("qa");checks.exact_restore=Persistence.load_world(game.save_path).get("kingdom",{})==game.world.kingdom
	checks.full_village_rendered=game.view.kingdom_layer.structures.size()==4
	return {"checks":checks,"all_passed":not checks.values().has(false),"source":"real_rendered_scene_and_ui_actions","milestone":"A","level":K.level(game.world),"rendered_buildings":game.view.kingdom_layer.structures.size(),"simulation_ticks":driver.ticks}
