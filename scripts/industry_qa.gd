extends Node
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
var game
var directory="res://builds/phase09"
var checks: Dictionary={}
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().create_timer(.7).timeout;await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(name+".png"))
func button(node: Node,prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):return node
	for child in node.get_children():
		var found=button(child,prefix)
		if found:return found
	return null
func run() -> Dictionary:
	var probe=preload("res://scripts/industry_progression_probe.gd").new();checks.legal_forge_progression=probe.forge_stage()
	game.world=probe.world;game.has_player_world=true;game.in_menu=false;game.paused=true;game.is_test_session=false;game.rng.state=int(game.world.rng_state);game.view.world=game.world;game.view.invalidate();game.ui.language="en";game.ui.build();game.ui.close()
	game.show_world(true)
	game.diagnostics.configure("user://industry-qa-diagnostics.json","simulated")
	game.view.pan=Vector2.ZERO;game.view.zoom=.88
	await capture("iron-village");checks.actual_eight_buildings=game.view.kingdom_layer.structures.size()==8
	game.realm_ui.workshop();await capture("workshop")
	var axe=button(game.ui.modal,"Forester’s Axe");checks.recipe_button=axe!=null
	if axe:axe.pressed.emit()
	var pick=button(game.ui.modal,"Iron Pick");checks.pick_button=pick!=null
	if pick:pick.pressed.emit()
	checks.real_queue=game.world.kingdom.industry.queue.size()==2 and game.world.kingdom.industry.items.is_empty()
	await capture("craft-queue");game.ui.close()
	var forge=game.world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0];game.view.zoom=1.4;game.realm_ui.focus(int(forge.cell));await capture("working-forge");game.view.zoom=.88;game.view.pan=Vector2.ZERO
	for i in range(12):game.advance_tick()
	checks.real_crafted_items=game.world.kingdom.industry.items.size()==2 and game.world.kingdom.industry.queue.is_empty()
	game.realm_ui.claim_reward("main_09");checks.realm_ten=K.level(game.world)==10
	game.realm_ui.inventory();await capture("inventory")
	var worker=int(game.world.kingdom.workers[0].id);game.realm_ui.choose_tool(worker);await capture("compare-tool")
	axe=button(game.ui.modal,"Forester’s Axe #");checks.equip_button=axe!=null
	if axe:axe.pressed.emit()
	checks.actual_axe_equipped=not I.tool(game.world,worker).is_empty()
	var miner=int(game.world.kingdom.workers[2].id);game.realm_ui.choose_tool(miner);pick=button(game.ui.modal,"Iron Pick #")
	if pick:pick.pressed.emit()
	var mine=game.world.kingdom.buildings.filter(func(b):return b.kind=="mine")[0];K.assign(game.world,miner,int(mine.id));game.ui.close()
	for i in range(8):game.advance_tick()
	checks.real_tool_work=K.complete(game.world,K.current(game.world));game.realm_ui.claim_reward("main_10")
	checks.ten_real_quests=game.world.kingdom.claimed.size()==10
	game.ui.close();await capture("equipped-village");game.realm_ui.open();await capture("iron-chapter-complete")
	game.ui.language="tr";game.realm_ui.workshop();await capture("workshop-tr");game.realm_ui.inventory();await capture("inventory-tr");game.ui.language="en"
	checks.saved=game.checkpoint("industry-qa");checks.exact_restore=Persistence.load_world(game.save_path).get("kingdom",{})==game.world.kingdom
	return {"source":"actual_rendered_industry_ui_and_legal_actions","checks":checks,"all_passed":not checks.values().has(false),"realm":K.level(game.world),"quests":game.world.kingdom.claimed.size(),"items":game.world.kingdom.industry.items.size(),"legal_simulation_ticks":probe.driver.ticks}
