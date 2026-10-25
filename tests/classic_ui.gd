extends SceneTree
var game
var checks={}
var measures=[]
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame
func shot(name):
	await settle();await RenderingServer.frame_post_draw
	checks["capture_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/classic-ui/"+name+".png")==OK
func fits(c: Control) -> bool:return Rect2(Vector2.ZERO,Vector2(root.size)).grow(1).encloses(c.get_global_rect())
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/classic-ui")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://classic-ui-private.json";root.add_child(game);current_scene=game
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr"
	for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,720),Vector2i(1920,1080)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();game.ui.build();game.ui.close();await settle()
		var ui=game.ui;var p=ui.premium;var r=p.rpg;var suffix=str(extent.x)+"x"+str(extent.y)
		checks[suffix+"_status_compact"]=ui.header.get_parent()==ui.root and ui.header.position.y<extent.y*.05 and r.classic.hp.size.x<extent.x*.2
		checks[suffix+"_chat_reference_proportion"]=r.chat_box.size.x<=extent.x*.36 and r.chat_box.size.y<=extent.y*.27
		var bag=ui.root.find_child("NavInventory",true,false);checks[suffix+"_nav_compact"]=bag.size.y<=extent.y*.07 and bag.get_theme_constant("icon_max_width")<=extent.y*.04
		await shot("home-"+suffix)
		p.route("inventory");await settle();var rect=ui.modal.get_global_rect();checks[suffix+"_inventory_proportion"]=rect.size.x<=extent.x*.34 and rect.size.y<=extent.y*.84 and fits(ui.modal)
		checks[suffix+"_inventory_seven_columns"]=ui.modal.find_child("InventoryGrid",true,false).columns==7
		checks[suffix+"_world_remains_visible"]=ui.header.is_visible_in_tree() and ui.veil.color.a==0
		await shot("inventory-"+suffix)
		var item=w.kingdom.industry.items.filter(func(i):return i.recipe=="iron_sword")[0];r.show_item(int(item.id));await settle()
		checks[suffix+"_comparison_bounds"]=r.details_window.visible and fits(r.details_window) and r.details_window.get_global_rect().end.x<rect.position.x
		await shot("item-detail-"+suffix)
		measures.append({"viewport":[extent.x,extent.y],"inventory":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"navigation_height":bag.size.y,"chat":[r.chat_box.size.x,r.chat_box.size.y]})
		for route in ["attributes","skills","quest","map","menu"]:
			p.route(route);await settle();checks[suffix+"_"+route+"_window"]=fits(ui.modal) and ui.modal.size.x<extent.x*.45
			if extent.x==1280:await shot(route+"-"+suffix)
		ui.close();checks[suffix+"_adventure_entry"]=game.enter_adventure("wildwood");await settle();var scene=game.adventure_scene
		checks[suffix+"_circular_attack"]=scene.buttons.attack.size.x==scene.buttons.attack.size.y and scene.buttons.attack.size.x<=extent.y*.15
		var touch=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=scene.stick.position;scene._input(touch);checks[suffix+"_stick_accepts_touch"]=scene.stick_index==0;touch.pressed=false;scene._input(touch)
		touch.pressed=true;touch.position=Vector2(20,extent.y-175*p.scale_ui());scene._input(touch);checks[suffix+"_chat_does_not_move"]=scene.stick_index==-1 and scene.movement==Vector2.ZERO
		await shot("combat-"+suffix)
		scene.open_rpg_panel("inventory");await settle();checks[suffix+"_combat_modal_single_hud"]=not ui.header.is_visible_in_tree() and scene.health.is_visible_in_tree() and scene.frozen
		await shot("combat-inventory-"+suffix);ui.close();await settle();checks[suffix+"_combat_modal_resumes"]=not scene.rpg_overlay and not scene.frozen
		scene.go_home();await settle()
	checks.save_compatible=Persistence.save_world(w,game.save_path) and not Persistence.load_world(game.save_path).is_empty()
	var result={"all_passed":not checks.values().has(false),"checks":checks,"measurements":measures,"source":"actual Godot rendering; scripted UI and touch events, not physical-device certification"}
	var file=FileAccess.open("res://docs/benchmarks/classic-ui/verification.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close();print("CLASSIC_UI ",checks.size()," checks; passed=",result.all_passed," failures=",checks.keys().filter(func(k):return not checks[k]));quit(0 if result.all_passed else 1)
