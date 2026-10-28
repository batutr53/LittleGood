extends SceneTree
const K=preload("res://scripts/kingdom.gd")
const E=preload("res://scripts/estate.gd")
const S=preload("res://scripts/selection_outline.gd")
var game
var checks={}
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
func click(at):
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=at;e.pressed=true;Input.parse_input_event(e);await process_frame;e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await settle()
func find(name):return game.ui.modal.find_child(name,true,false)
func point(id):
	var v=game.view;var ordered=game.world.kingdom.buildings.duplicate();ordered.sort_custom(func(a,b):return v.project(game.world.cells[int(a.cell)]).y>v.project(game.world.cells[int(b.cell)]).y)
	var sprite=v.kingdom_layer.structures[id].sprite;var transform=sprite.get_global_transform_with_canvas();var rect=sprite.get_rect();var first=transform*rect.position;var last=transform*rect.end;var extent=Rect2(first,last-first).abs().intersection(Rect2(Vector2(10,75),root.size-Vector2i(20,160)))
	for y in range(int(extent.position.y),int(extent.end.y),7):
		for x in range(int(extent.position.x),int(extent.end.x),7):
			var at=Vector2(x,y)
			if game.ui.blocks_world(at) or not S.hit(sprite,at):continue
			var npc=v.advisor_layer
			if npc.visible and (npc.get_global_transform_with_canvas()*Vector2(0,-30)).distance_to(at)<=maxf(28,38*v.display_zoom):continue
			if ordered.any(func(b):return E.status(game.world,b)!="" and v.estate_layer.bubble(b).distance_to(at)<=28):continue
			if v.kingdom_layer.workers.any(func(worker):return S.hit(worker,at)):continue
			var top=0
			for b in ordered:
				if S.hit(v.kingdom_layer.structures[int(b.id)].sprite,at):top=int(b.id);break
			if top!=id:continue
			var stable=true
			for shift in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
				var hit=0
				for b in ordered:
					if S.hit(v.kingdom_layer.structures[int(b.id)].sprite,at+shift):hit=int(b.id);break
				if hit!=id:stable=false;break
			if stable:return at
	return Vector2(-1,-1)
func shot(name):
	await settle();checks["image_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/hotfix/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/hotfix");DirAccess.make_dir_recursive_absolute("res://builds/hotfix")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://hotfix-input-private.json";root.add_child(game);current_scene=game;game.set_process(false)
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");E.start(w);load("res://scripts/colony.gd").ensure(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=false;game.ui.language="tr";game.ui.build();game.ui.close();game.show_world(true);game.view.invalidate();var p=game.ui.premium
	# This old fixture stacks the forge behind other roofs. Use the real free move
	# command in the private fixture to expose it, preserving IDs/jobs/materials.
	var forge=w.kingdom.buildings.filter(func(b):return b.kind=="forge")[0];var sites=[];var near=game.view.project(w.cells[int(forge.cell)])
	for cell in range(w.cells.size()):
		if K.valid_site(w,"forge",cell,int(forge.id)):sites.append(cell)
	sites.sort_custom(func(a,b):return game.view.project(w.cells[a]).distance_squared_to(near)<game.view.project(w.cells[b]).distance_squared_to(near))
	checks.legal_fixture_move=not sites.is_empty() and K.move(w,int(forge.id),sites[0]);game.view.invalidate()
	for i in range(8):game.advance_tick()
	p.route("building",6);await settle();checks.nonmodal_clock=game.world_inspector_open and game.home_clock_running();var tick=int(w.tick);game.accumulator=0
	for i in range(2):game.last_clock_ms=Time.get_ticks_msec()-2000;game._process(1)
	checks.inspect_clock_advances=w.tick==tick+1;checks.live_status=find("InspectorProducts")!=null
	for id in [2,8,9,12,6,2]:
		# Native mouse events on a real opaque visible part, outside all UI/bubbles.
		game.view.display_pan=game.view.pan;game.view.display_zoom=game.view.zoom;game.view._process(.05);await settle();var at=point(id);checks["exposed_"+str(id)]=at.x>=0
		if at.x<0:continue
		await click(at);checks["switch_"+str(id)]=p.current=="building" and p.argument==id and game.view.selected==w.kingdom.buildings.filter(func(b):return int(b.id)==id)[0].cell
		checks["one_panel_"+str(id)]=game.ui.root.find_children("GameSurface","PanelContainer",true,false).size()==1
	await shot("c-mouse-farm")
	var collect=find("CollectBuildingOutput");var before_food=K.home(w).food;var before_pending=int(w.estate.pending.get("2",{}).get("food",0));var before_cell=game.view.selected;await click(collect.get_global_rect().get_center())
	var transferred=before_pending-int(w.estate.pending.get("2",{}).get("food",0));checks.native_collection=transferred>0 and is_equal_approx(K.home(w).food,before_food+transferred/1000.0);checks.inside_no_clickthrough=p.current=="building" and p.argument==2 and game.view.selected==before_cell;checks.feedback_visible=game.ui.action_notice.is_visible_in_tree();var exact=w.duplicate(true);await click(find("CollectBuildingOutput").get_global_rect().get_center());checks.native_double_collect=w==exact
	p.route("staffing",6);await settle();var free=K.assigned(w,0)[0];var worker=int(free.id);await click(find("AssignWorker"+str(worker)).get_global_rect().get_center());checks.native_assign=int(free.building)==6 and p.current=="staffing";checks.assign_feedback=game.ui.action_notice_text.text.contains(free.name);await shot("b-native-assigned")
	var remove=find("RemoveWorker"+str(worker));await click(remove.get_global_rect().get_center());checks.native_remove=int(free.building)==0
	p.route("building_upgrade",2);await settle();var original=p.argument;var at=game.view.screen_point(w.cells[int(w.kingdom.buildings[5].cell)])-Vector2(0,50);checks.modal_blocks=game.ui.blocks_world(at) and not game.world_input_available();await click(at);checks.modal_retains=p.current=="building_upgrade" and p.argument==original
	p.route("building",2);await settle();await click(Vector2(320,465));checks.empty_dismisses=not game.in_menu and not game.world_inspector_open
	for locale in ["tr","en"]:
		game.ui.language=locale
		for extent in [Vector2i(320,568),Vector2i(360,800),Vector2i(393,852),Vector2i(1280,720)]:
			root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;game.ui.build();p=game.ui.premium;p.route("building",2);await settle();var key=locale+str(extent.x);checks["bounds_"+key]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.get_global_rect());checks["buttons_"+key]=find("CollectBuildingOutput")!=null and find("SurfaceBack")!=null;checks["outside_"+key]=not game.ui.blocks_world(Vector2(extent.x*.5,extent.y*.3));await shot("c-inspector-"+key)
	checks.save=Persistence.save_world(w,game.save_path);var restored=Persistence.load_world(game.save_path);checks.restore=not restored.is_empty() and restored.estate==w.estate and restored.kingdom.workers==w.kingdom.workers
	var result={"checks":checks,"all_passed":not checks.values().has(false),"count":checks.size(),"method":"Real Godot viewport mouse events, existing fixture and authoritative ticks; no arbitrary output/balance injection"};var file=FileAccess.open("res://builds/hotfix/input.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));print("HOTFIX_INPUT "+JSON.stringify(result));quit(0 if result.all_passed else 1)
