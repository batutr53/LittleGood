extends SceneTree
var game
var checks={}
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame
func shot(name):
	await settle();await RenderingServer.frame_post_draw;checks["capture_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/alignment/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/alignment");DirAccess.make_dir_recursive_absolute("res://builds/alignment")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://alignment-private.json";root.add_child(game);current_scene=game;await settle()
	game.world=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.view.world=game.world;game.has_player_world=true;game.paused=true;game.show_world(true)
	for extent in [Vector2i(960,540),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;game.ui.language="tr";await settle();game.ui.build();game.ui.close();game.show_world(true);await settle()
		for b in game.ui.root.find_children("*","Button",true,false):
			var layout=b.get_node_or_null("IconCaption")
			if not layout:continue
			var icon=layout.find_child("NavIcon",true,false);var caption=layout.find_child("Caption",true,false);var middle=b.get_global_rect().get_center().x
			checks["icon_center_"+str(extent.x)+str(b.name)]=absf(icon.get_global_rect().get_center().x-middle)<1
			checks["caption_center_"+str(extent.x)+str(b.name)]=absf(caption.get_global_rect().get_center().x-middle)<1
			checks["separate_"+str(extent.x)+str(b.name)]=icon.get_global_rect().end.y<=caption.get_global_rect().position.y
			checks["inside_"+str(extent.x)+str(b.name)]=b.get_global_rect().grow(1).encloses(caption.get_global_rect()) and b.get_global_rect().grow(1).encloses(icon.get_global_rect())
		var chat=game.ui.root.find_child("ChatPanel",true,false);var tabs=chat.find_child("ChatPreviewTabs",true,false);checks["chat_padding_"+str(extent.x)]=chat.get_global_rect().grow(-game.ui.premium.px(8)).encloses(tabs.get_global_rect())
		game.speed=3;game.ui.refresh();checks["dynamic_caption_"+str(extent.x)]=game.ui.speed_button.text.is_empty() and game.ui.speed_button.find_child("Caption",true,false).text=="3×";game.speed=1;game.ui.refresh()
		await shot("hud-"+str(extent.x))
		for route in ["inventory","skills","attributes","quest","map","settings","chat"]:
			game.ui.premium.route(route);await settle();var title=game.ui.modal.find_child("SurfaceTitle",true,false)
			checks["title_center_"+str(extent.x)+route]=absf(title.get_global_rect().get_center().x-game.ui.modal.get_global_rect().get_center().x)<1.1
			if route=="inventory":
				checks["equipment_icons_"+str(extent.x)]=game.ui.modal.find_children("*","Button",true,false).all(func(b):return not b.has_meta("equipment_slot") or b.icon_alignment==HORIZONTAL_ALIGNMENT_CENTER)
			await shot(route+"-"+str(extent.x));game.ui.close();await settle()
		game.ui.entry_ui.open();await settle();checks["login_center_"+str(extent.x)]=game.ui.entry_ui.account.alignment==HORIZONTAL_ALIGNMENT_CENTER;await shot("login-"+str(extent.x));game.ui.entry_ui.create_page();await settle();await shot("create-"+str(extent.x))
	var report={"all_passed":not checks.values().has(false),"count":checks.size(),"checks":checks};var f=FileAccess.open("res://builds/alignment/result.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));print("ALIGNMENT "+JSON.stringify(report));quit(0 if report.all_passed else 1)
