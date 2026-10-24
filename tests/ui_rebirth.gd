extends SceneTree
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
const H=preload("res://scripts/hero.gd")
var game
var checks={}
var screens=[]
func _initialize():call_deferred("run")
func button(node: Node,prefix: String) -> Button:
 if node is Button and node.text.begins_with(prefix):return node
 for c in node.get_children():
  var found=button(c,prefix)
  if found:return found
 return null
func settle():
 await process_frame;await process_frame
func capture(name):
 await settle();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/ui-rebirth/"+name+".png")
func fits(control: Control) -> bool:
 var rect=control.get_global_rect();var viewport=game.get_viewport_rect();return rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=viewport.size.x+1 and rect.end.y<=viewport.size.y+1
func visible_in_surface(control: Control) -> bool:
 return game.ui.modal.get_global_rect().encloses(control.get_global_rect())
func run():
 game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://ui-rebirth-private.json";root.add_child(game);current_scene=game
 var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");checks.authentic_fixture=not w.is_empty();checks.enable_actual_chapter23=preload("res://scripts/sanctuary.gd").enable(w)
 game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();await settle()
 var ui=game.ui;var p=ui.premium;checks.production_default=ui.rebirth_enabled and p!=null;checks.calm_hud=not p.tray.visible
 var blocked=0
 for x in range(10):
  for y in range(20):
   if ui.blocks_world(Vector2((x+.5)*72,(y+.5)*64)):blocked+=1
 checks.world_visible_at_least_75_percent=blocked<=50
 var before=w.kingdom.duplicate(true)
 for route in ["quest","inventory","hero","map","forge","army","trade","workers","construction","settings","menu"]:
  p.route(route);await settle();checks["open_"+route]=is_instance_valid(ui.modal) and fits(ui.modal)
 checks.navigation_does_not_change_simulation=w.kingdom==before
 p.route("inventory");await settle();var sword=w.kingdom.industry.items.filter(func(item):return item.recipe=="iron_sword")[0];p.route("item",int(sword.id));await settle();game.navigate_back();await settle();checks.android_back_to_inventory=p.current=="inventory";game.navigate_back();checks.back_history_persists=p.current!="item"
 p.route("quest");await settle();var go=button(ui.modal,"Hedefe git");checks.real_objective_button=go!=null
 if go:go.pressed.emit();await settle()
 checks.objective_routes_to_real_sanctuary=ui.modal!=null and button(ui.modal,"Gir: Batık Tapınak")!=null
 game.navigate_back();await settle();checks.detail_back_to_quest=p.current=="quest"
 var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];ui.close();game.view.display_pan=game.view.pan;game.view.display_zoom=game.view.zoom
 game.touch_world(game.view.screen_point(w.cells[int(farm.cell)])-Vector2(0,20)*game.view.display_zoom);await settle();checks.actual_world_building_select=p.current=="building" and p.argument==int(farm.id)
 var worker_button=button(ui.modal,"İşçiler");checks.context_action=worker_button!=null
 if worker_button:worker_button.pressed.emit();await settle()
 checks.context_workers_route=p.current=="workers"
 p.route("forge");p.current_recipe="field_sickle";p.route("recipe");await settle();var craft=button(ui.modal,"Dövümü başlat");var queue_before=w.kingdom.industry.queue.size();var iron=w.kingdom.stock.iron;var wood=w.kingdom.stock.wood
 checks.legitimate_craft_available=craft!=null and not craft.disabled
 if craft:
  craft.pressed.emit();craft.pressed.emit();await settle()
 checks.one_submission_one_job=w.kingdom.industry.queue.size()==queue_before+1
 checks.actual_material_cost=w.kingdom.stock.iron==iron-1000 and w.kingdom.stock.wood==wood-1000
 # Equipped/military/artifact ownership remains model-owned; no UI clones.
 p.route("item",int(sword.id));await settle();var equip=button(ui.modal,"Bu eşyayı kuşan")
 if equip:equip.pressed.emit();await settle()
 checks.equip_real_id=int(w.kingdom.adventure.hero.equipment.weapon)==int(sword.id)
 p.route("forge");p.current_recipe="iron_sword";p.route("recipe");await settle();var unavailable=button(ui.modal,"Dövümü başlat");checks.missing_material_disabled=unavailable!=null and unavailable.disabled
 var no_spend=w.kingdom.duplicate(true)
 if unavailable:unavailable.pressed.emit()
 checks.disabled_action_cannot_spend=w.kingdom==no_spend
 # Real placement UI remains accessible and cancellation cannot spend.
 ui.close();game.realm_ui.begin("build","house");await settle();checks.placement_responsive=fits(game.realm_ui.panel)
 var build_before=w.kingdom.duplicate(true);game.navigate_back();checks.placement_cancel_preserves_state=not game.realm_ui.active and w.kingdom==build_before
 # Layout/scroll evidence at the requested portrait sizes and one tablet.
 for viewport in [Vector2i(320,568),Vector2i(360,800),Vector2i(393,852),Vector2i(412,915),Vector2i(720,1280),Vector2i(720,1600),Vector2i(768,1024)]:
  root.min_size=Vector2i(1,1);root.size=viewport;root.content_scale_size=viewport;await settle();game.view.origin=Vector2(viewport.x*.5,viewport.y*.47);game.view.zoom=.88*viewport.x/720.0;game.view.display_zoom=game.view.zoom
  for locale in ["tr","en"]:
   ui.language=locale;ui.build();ui.close();await settle();await capture("home-"+str(viewport.x)+"-"+locale)
   for destination in ["quest","inventory","hero","map","forge","army","trade","construction","workers"]:
    p.route(destination);await settle();var key=destination+"-"+str(viewport.x)+"x"+str(viewport.y)+"-"+locale
    var close=ui.modal.find_child("SurfaceBack",true,false);var content=ui.modal.find_child("SurfaceContent",true,false)
    checks[key+"-bounds"]=fits(ui.modal) and close!=null and fits(close) and content.size.x<=p.scroll.size.x+1
    if destination=="quest":
     var claim=button(ui.modal,"Doğrulanan ödülü al" if locale=="tr" else "Claim verified reward")
     if claim:p.scroll.ensure_control_visible(claim);await settle()
     checks[key+"-reward-reachable"]=claim!=null and visible_in_surface(claim)
     p.scroll.scroll_vertical=0;await settle()
    if viewport.x in [320,393,720] or destination=="quest":await capture(key)
    screens.append({"screen":destination,"viewport":[viewport.x,viewport.y],"locale":locale,"bounds_passed":checks[key+"-bounds"]})
   p.route("building",int(farm.id));await settle();checks["building-"+str(viewport.x)+"-"+locale]=fits(ui.modal);await capture("building-"+str(viewport.x)+"-"+locale)
   ui.close();game.realm_ui.begin("build","house");await settle();checks["placement-"+str(viewport.x)+"-"+locale]=fits(game.realm_ui.panel);game.realm_ui.finish()
 ui.close();checks.save_compatible=Persistence.save_world(w,game.save_path) and Persistence.load_world(game.save_path).kingdom==w.kingdom;checks.final_state_valid=Persistence.validate(w)
 var result={"all_passed":not checks.values().has(false),"checks":checks,"screens":screens,"source":"actual Godot render + real state adapters; synthetic viewport sizes; UI signals separately from Android native input"};var file=FileAccess.open("res://builds/ui-rebirth/rendered.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close();print("UI_REBIRTH ",result.all_passed," ",checks.size()," checks; failures ",checks.keys().filter(func(key):return not checks[key]));quit(0 if result.all_passed else 1)
