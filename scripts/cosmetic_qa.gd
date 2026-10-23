extends Node
const C=preload("res://scripts/cosmetics.gd")
var game
var image_dir="res://builds/phase8"
var checks: Dictionary={}
static func decorate(w: Dictionary,count: int=16) -> void:
	# Controlled historical milestone fixture, never presented as human progress.
	var fixture=w.duplicate(true);C.ensure(fixture)
	fixture.discoveries=[0,1,2,3,4,5];fixture.living.findings=LivingStories.FINDINGS.duplicate();fixture.living.secrets=LivingStories.SECRETS.duplicate();fixture.living.gifts=2
	fixture.settlements[0].stage=2;fixture.settlements[0].landmark=true
	for i in range(3):fixture.cells[i].plants=.9;fixture.cells[i].moisture=.9
	C.reconcile(fixture)
	for id in C.items():
		if not C.items()[id].premium and not C.owned(fixture,id):C.buy(fixture,id)
	w.wardrobe=fixture.wardrobe.duplicate(true);w.wardrobe.placements=[];w.wardrobe.coats=[]
	var decor=["willow","prisms","glowfern","flowers","stones","ruins","fireflies","obelisk"]
	var total=0
	for j in range(w.cells.size()):
		var i=(j*73)%w.cells.size()
		if int(w.cells[i].biome) in [0,2] and w.cells[i].detail<.8 and C.valid_place(w,decor[total%decor.size()],i):
			C.place(w,decor[total%decor.size()],i,total%4);total+=1
		if total>=count-1:break
	C.place(w,"banner",int(w.settlements[0].cell))
	C.equip(w,"starband",int(w.creatures[0].identity));C.equip(w,"mint",int(w.creatures[1].identity));C.equip(w,"dreamer",int(w.creatures[2].identity))
	C.equip(w,"aurora");C.equip(w,"orbit")
func capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await get_tree().create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(image_dir.path_join(name+".png"))
func run() -> Dictionary:
	game.new_planet(2026,"Atelier QA",false);game.has_player_world=true;game.is_test_session=false;game.paused=true
	decorate(game.world)
	checks.full_catalog_affordable=game.world.wardrobe.owned.size()==23 and game.world.wardrobe.dust==75
	checks.valid_ledger=C.validate(game.world)
	game.ui.close()
	await get_tree().create_timer(.6).timeout
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
	var terrain_builds=game.view.terrain.rebuilds
	var original_sprites=game.view.cosmetic_layer.sprites.duplicate()
	var switch_times: Array=[]
	for theme in ["enchanted","crystal","celestial","ancient"]:
		var started=Time.get_ticks_usec();C.equip(game.world,theme);game.view.invalidate_cosmetics()
		await get_tree().process_frame
		if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
		switch_times.append((Time.get_ticks_usec()-started)/1000.0)
		await capture("theme-"+theme)
		checks["render_"+theme]=game.view.cosmetic_layer.theme==theme
	checks.theme_reuses_terrain=game.view.terrain.rebuilds==terrain_builds
	checks.theme_reuses_decor_nodes=game.view.cosmetic_layer.sprites==original_sprites
	var ui_started=Time.get_ticks_usec()
	game.decorator.collection(true)
	var shop_cpu_ms=(Time.get_ticks_usec()-ui_started)/1000.0
	await capture("shop");checks.shop_navigation=game.ui.page=="customization"
	game.decorator.detail("prisms");await capture("item")
	game.decorator.creature_looks(int(game.world.creatures[0].identity));await capture("creature-wardrobe")
	game.decorator.begin("flowers")
	for i in range(game.world.cells.size()):
		if C.valid_place(game.world,"flowers",i):game.decorator.pick(game.view.screen_point(game.world.cells[i]));break
	await capture("editor")
	var before=game.world.wardrobe.placements.size()
	game.decorator.commit();checks.editor_placed=game.world.wardrobe.placements.size()==before+1
	game.decorator.history(false);checks.editor_undo=game.world.wardrobe.placements.size()==before
	game.decorator.history(true);checks.editor_redo=game.world.wardrobe.placements.size()==before+1
	game.decorator.finish();checks.editor_pause_restored=game.paused
	var save_started=Time.get_ticks_usec()
	checks.saved=game.checkpoint("qa")
	var save_ms=(Time.get_ticks_usec()-save_started)/1000.0
	var load_started=Time.get_ticks_usec()
	var restored=Persistence.load_world(game.save_path)
	var load_ms=(Time.get_ticks_usec()-load_started)/1000.0
	checks.restored=not restored.is_empty() and restored.wardrobe==game.world.wardrobe
	var public=game.showcases.project(game.world)
	checks.showcase_v2=public.version==2 and game.showcases.validate(public)
	var f=FileAccess.open(image_dir.path_join("customized.lgplanet"),FileAccess.WRITE);f.store_string(JSON.stringify(public));f.close()
	checks.visit=game.visit_planet(public,"qa-cosmetics");await capture("visit")
	var frozen=game.visit_origin.world.duplicate(true)
	checks.visit_appearance=game.world.wardrobe.theme==public.appearance.theme
	var ro=game.world.duplicate(true);C.reconcile(game.world);C.buy(game.world,"enchanted");checks.visit_immutable=game.world==ro
	game.stop_visit()
	var returned=game.world.duplicate(true)
	# Visit exit deliberately checkpoints again; only the save timestamp may change.
	frozen.erase("saved_at");returned.erase("saved_at")
	checks.home_restored=returned==frozen
	game.ui.language="tr";game.decorator.collection();await capture("collection-tr");game.ui.language="en"
	return {"checks":checks,"all_passed":not checks.values().has(false),"source":"controlled_cosmetic_fixture_real_render","theme_switch_frame_ms":switch_times,"shop_cpu_ms":shop_cpu_ms,"save_ms":save_ms,"load_ms":load_ms,"catalog_count":24,"owned":game.world.wardrobe.owned.size(),"placements":game.world.wardrobe.placements.size()}
