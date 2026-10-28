extends "res://scripts/rpg_android_qa.gd"
const K=preload("res://scripts/kingdom.gd")
const E=preload("res://scripts/estate.gd")
const S=preload("res://scripts/selection_outline.gd")
var sequence=0
func native(action: String,at: Vector2,condition: Callable,count=1):
	sequence+=1
	print("HOTFIX_NATIVE_REQUEST action=",action," point=",at," pan=",game.view.pan," display_pan=",game.view.display_pan)
	host.publish("hotfix_tap",{"run_id":host.options.run_id,"sequence":sequence,"action":action,"tap_point":[at.x,at.y],"tap_count":count})
	var deadline=Time.get_ticks_msec()+15000
	while not condition.call() and Time.get_ticks_msec()<deadline:await get_tree().process_frame
	host.checks["native_"+action]=condition.call()
	if not host.checks["native_"+action]:print("HOTFIX_NATIVE_FAILED action=",action," point=",at," page=",game.ui.premium.current," argument=",game.ui.premium.argument," selected=",game.view.selected);await shot("hotfix-failed-"+action)
	await settle()
func button(name):return game.ui.modal.find_child(name,true,false)
func point(id):
	var v=game.view;var ordered=game.world.kingdom.buildings.duplicate();ordered.sort_custom(func(a,b):return v.project(game.world.cells[int(a.cell)]).y>v.project(game.world.cells[int(b.cell)]).y)
	var sprite=v.kingdom_layer.structures[id].sprite;var transform=sprite.get_global_transform_with_canvas();var rect=sprite.get_rect();var first=transform*rect.position;var last=transform*rect.end;var extent=Rect2(first,last-first).abs().intersection(Rect2(Vector2(10,75),game.get_viewport_rect().size-Vector2(20,160)))
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
func expose(id):
	game.view.display_pan=game.view.pan;game.view.display_zoom=game.view.zoom;game.view._process(.05);await settle();return point(id)
func run():
	game.is_test_session=true;game.save_path="user://hotfix-android-private.json"
	if host.options.get("restore_only",false):
		var restored=Persistence.load_world(game.save_path);host.checks.restore_valid=not restored.is_empty();host.checks.save_bytes=FileAccess.get_file_as_string(game.save_path).sha256_text()==host.options.expected_sha256
		if not restored.is_empty():host.checks.economy_present=restored.has("estate") and not restored.kingdom.workers.is_empty()
		host.publish("hotfix_restore_complete",{"run_id":host.options.run_id,"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false)});return
	var w=Persistence.load_world("user://rpg-fixture.json");host.checks.fixture=not w.is_empty()
	if w.is_empty():host.publish("hotfix_failed");return
	E.start(w);load("res://scripts/colony.gd").ensure(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.ui.language="tr";game.ui.build();game.ui.close();game.show_world(true);game.view.invalidate()
	# Use accepted relocation in this private old dense-layout fixture to expose the forge.
	var forge=w.kingdom.buildings.filter(func(b):return b.kind=="forge")[0];var sites=[];var near=game.view.project(w.cells[int(forge.cell)])
	for cell in range(w.cells.size()):
		if K.valid_site(w,"forge",cell,int(forge.id)):sites.append(cell)
	sites.sort_custom(func(a,b):return game.view.project(w.cells[a]).distance_squared_to(near)<game.view.project(w.cells[b]).distance_squared_to(near));host.checks.legal_forge_move=not sites.is_empty() and K.move(w,int(forge.id),sites[0]);game.view.invalidate()
	for i in range(8):game.advance_tick()
	var p=game.ui.premium;p.route("building",2);await settle();var food=K.home(w).food;var pending=int(w.estate.pending["2"].food)
	await native("collect",button("CollectBuildingOutput").get_global_rect().get_center(),func():return int(w.estate.pending.get("2",{}).get("food",0))<pending)
	var amount=pending-int(w.estate.pending.get("2",{}).get("food",0));host.checks.collect_exact=is_equal_approx(K.home(w).food,food+amount/1000.0);host.checks.feedback_visible=game.ui.action_notice.is_visible_in_tree();await shot("hotfix-android-collect")
	var snapshot=w.duplicate(true);game.ui.toast("WAITING_DOUBLE")
	await native("double_collect",button("CollectBuildingOutput").get_global_rect().get_center(),func():return game.ui.action_notice_text.text!="WAITING_DOUBLE",2);host.checks.no_duplicate=w==snapshot
	var at=await expose(6);host.checks.mine_exposed=at.x>=0
	if at.x>=0:await native("switch_mine",at,func():return p.current=="building" and p.argument==6)
	var staff=game.ui.modal.find_children("*","Button",true,false).filter(func(b):return b.text=="Bu binanın personeli")[0]
	await native("open_workers",staff.get_global_rect().get_center(),func():return p.current=="staffing")
	var free=K.assigned(w,0)[0];var worker=int(free.id);await native("assign",button("AssignWorker"+str(worker)).get_global_rect().get_center(),func():return int(free.building)==6);host.checks.assigned_count=K.assigned(w,6).has(free);await shot("hotfix-android-worker")
	var mine=w.kingdom.buildings.filter(func(b):return int(b.id)==6)[0];var before=K.activity_rate(w,mine);var output=int(w.estate.pending.get("6",{}).get("ore",0));game.paused=false;var tick=int(w.tick);await get_tree().create_timer(2.5).timeout;game.paused=true;host.checks.live_inspector=w.tick>tick and int(w.estate.pending.get("6",{}).get("ore",0))>output
	await native("remove",button("RemoveWorker"+str(worker)).get_global_rect().get_center(),func():return int(free.building)==0);host.checks.production_rate_removed=K.activity_rate(w,mine)<before
	p.route("building",6);await settle();at=await expose(2)
	if at.x>=0:await native("switch_farm",at,func():return p.current=="building" and p.argument==2)
	at=await expose(8);host.checks.forge_exposed=at.x>=0
	if at.x>=0:await native("switch_forge",at,func():return p.current=="building" and p.argument==8)
	at=await expose(9);host.checks.barracks_exposed=at.x>=0
	if at.x>=0:await native("switch_barracks",at,func():return p.current=="building" and p.argument==9)
	await shot("hotfix-android-switch")
	# A tap on a real panel button may change its route, never select world below.
	p.route("building_upgrade",2);await settle();var selected=int(game.view.selected);at=Vector2(320,400)
	host.checks.modal_blocks=game.ui.blocks_world(at) and not game.world_input_available();sequence+=1;host.publish("hotfix_tap",{"run_id":host.options.run_id,"sequence":sequence,"action":"modal_outside","tap_point":[at.x,at.y],"tap_count":1});await get_tree().create_timer(2).timeout;host.checks.modal_retained=p.current=="building_upgrade" and game.view.selected==selected
	p.route("building",2);await settle();await native("outside_empty",Vector2(320,465),func():return not game.in_menu);host.checks.selection_cleared=not game.world_inspector_open
	game.ui.language="en";p.route("building",2);await settle();var button_at=button("CollectBuildingOutput").get_global_rect().get_center();game.ui.toast("WAITING_ENGLISH")
	await native("english_collect",button_at,func():return game.ui.action_notice_text.text!="WAITING_ENGLISH");host.checks.english_label=button("CollectBuildingOutput").text=="Collect ready output";await shot("hotfix-android-english")
	# Disposable portrait override exercises actual ADB taps at compact logical size.
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT);get_tree().root.content_scale_size=Vector2i(360,800)
	var portrait_deadline=Time.get_ticks_msec()+8000
	while game.get_viewport_rect().size.x>=game.get_viewport_rect().size.y and Time.get_ticks_msec()<portrait_deadline:await get_tree().process_frame
	game.ui.language="tr";game.ui.build();p=game.ui.premium;p.route("building",2);await settle();host.checks.portrait=game.get_viewport_rect().size.y>game.get_viewport_rect().size.x;host.checks.portrait_panel_bounds=game.get_viewport_rect().encloses(game.ui.modal.get_global_rect());game.ui.toast("WAITING_PORTRAIT")
	await native("portrait_collect",button("CollectBuildingOutput").get_global_rect().get_center(),func():return game.ui.action_notice_text.text!="WAITING_PORTRAIT");await shot("hotfix-android-portrait")
	await native("portrait_close",button("SurfaceBack").get_global_rect().get_center(),func():return not game.in_menu)
	host.checks.save=Persistence.save_world(w,game.save_path);var restored=Persistence.load_world(game.save_path);host.checks.restore=not restored.is_empty() and restored.estate==w.estate and restored.kingdom.workers==w.kingdom.workers;host.checks.valid=Persistence.validate(w)
	host.publish("hotfix_complete",{"run_id":host.options.run_id,"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"save_sha256":FileAccess.get_file_as_string(game.save_path).sha256_text(),"source":"Actual external ADB taps on real building sprites and UI; private fixture, legal model ticks/relocation, no arbitrary balance injection"})
