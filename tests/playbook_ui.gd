extends SceneTree
const K=preload("res://scripts/kingdom.gd")
var game
var checks={}
var capture_dir=OS.get_environment("LITTLEGOD_PLAYBOOK_CAPTURES") if not OS.get_environment("LITTLEGOD_PLAYBOOK_CAPTURES").is_empty() else "res://docs/screenshots/playbook"
func _initialize():call_deferred("run")
func settle():
 await process_frame;await process_frame
func find_button(prefix):
 for b in game.ui.modal.find_children("*","Button",true,false):
  if b.text.begins_with(prefix):return b
 return null
func shot(name):
 await settle();await RenderingServer.frame_post_draw
 checks["screenshot_"+name]=root.get_texture().get_image().save_png(capture_dir+"/"+name+".png")==OK
func run():
 DirAccess.make_dir_recursive_absolute(capture_dir);DirAccess.make_dir_recursive_absolute("res://docs/benchmarks/playbook")
 game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://playbook-ui-only.json";root.add_child(game);current_scene=game
 game.new_planet(42,"Playbook QA",false);game.ui.language="tr";game.ui.build();game.ui.close();game.realm_ui.intro();await settle()
 checks.compact_intro=game.ui.modal.size.y<=440 and find_button("Köyümü kurmaya başla")!=null
 await shot("first-village")
 for route in ["workers","construction"]:
  game.ui.premium.route(route);await settle();checks["before_founding_"+route]=not game.world.has("kingdom") and find_button("Köyümü kurmaya başla")!=null
 find_button("Köyümü kurmaya başla").pressed.emit();await settle()
 var p=game.ui.premium;var w=game.world;checks.real_founding=w.has("kingdom") and w.kingdom.workers.size()==3
 checks.first_quest_no_scroll=game.ui.modal.find_child("SurfaceContent",true,false).size.y<=p.scroll.size.y+1
 await shot("first-quest")
 var before=w.kingdom.duplicate(true);p.route("guide");await settle();checks.navigation_read_only=w.kingdom==before
 p.route("quest");await settle();find_button("Hedefe git").pressed.emit();await settle()
 checks.objective_closes_menu=not game.in_menu
 checks.objective_selects_camp=game.view.selected==int(K.home(w).cell)
 game.ui.inspect_settlement(K.home(w));checks.observe_real_settlers=K.progress(w,K.current(w).objectives[0])>=1
 var loaded=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");preload("res://scripts/estate.gd").start(loaded);game.world=loaded;game.view.world=loaded;game.paused=true;game.ui.build();game.ui.close();w=loaded;p=game.ui.premium
 var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];var worker=K.assigned(w,int(farm.id))[0];var original_job=int(worker.building)
 p.route("worker",int(worker.id));await settle();find_button("İnşaatçı").pressed.emit();await settle();checks.explicit_builder_assignment=int(worker.building)==0 and K.assigned(w,0).has(worker)
 p.playbook().assign(int(worker.id),original_job);checks.production_reassignment=int(worker.building)==original_job
 var reserved=preload("res://scripts/military.gd").worker_reserved(w,int(worker.id));checks.civilian_not_reserved=not reserved
 var snapshot=w.duplicate(true)
 for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,720)]:
  root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle()
  for locale in ["tr","en"]:
   game.ui.language=locale;game.ui.build();p=game.ui.premium
   for route in ["quest","workers","construction","guide","army","map","menu","army_roster"]:
    p.route(route);await settle();var content=game.ui.modal.find_child("SurfaceContent",true,false);var key=route+"_"+str(extent.x)+"_"+locale
    checks[key+"_no_scroll"]=content.size.y<=p.scroll.size.y+1
    checks[key+"_fits"]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.get_global_rect())
   p.route("building",int(farm.id));await settle();checks["building_"+str(extent.x)+locale+"_no_scroll"]=game.ui.modal.find_child("SurfaceContent",true,false).size.y<=p.scroll.size.y+1
   if locale=="tr":
    for route in ["guide","workers","construction","army","quest"]:
     p.route(route);await shot(route+"-"+str(extent.x))
 checks.navigation_preserves_world=w==snapshot
 root.size=Vector2i(1280,720);root.content_scale_size=root.size;game.ui.language="tr";game.ui.build();p=game.ui.premium
 game.ui.close();game.realm_ui.begin("build","house");await settle();checks.placement_small=game.realm_ui.panel.size.y<=140;await shot("placement");game.realm_ui.finish()
 game.realm_ui.begin("build","house");var valid_cell=game.realm_ui.cell;game.realm_ui.cell=-1;game.realm_ui.refresh_placement();checks.invalid_placement_disabled=game.realm_ui.confirm_button.disabled
 game.realm_ui.cell=valid_cell;game.realm_ui.refresh_placement();checks.valid_placement_enabled=not game.realm_ui.confirm_button.disabled;game.realm_ui.finish()
 var site=w.kingdom.buildings[0];var saved=site.duplicate(true);site.progress=0;site.required=9000
 for c in w.kingdom.workers:
  if not preload("res://scripts/military.gd").worker_reserved(w,int(c.id)) and not preload("res://scripts/trade.gd").worker_reserved(w,int(c.id)):c.building=int(farm.id)
 checks.blocked_construction_explained=p.playbook().work_status(w,site).contains("İnşaatçı yok")
 var free=w.kingdom.workers.filter(func(c):return not preload("res://scripts/military.gd").worker_reserved(w,int(c.id)) and not preload("res://scripts/trade.gd").worker_reserved(w,int(c.id)))[0]
 K.assign(w,int(free.id),0);checks.named_builder=p.playbook().work_status(w,site).contains(free.name)
 var progress=int(site.progress);w.tick+=1;K.tick(w);checks.actual_builder_advances=int(site.progress)>progress
 var building_count=w.kingdom.buildings.size();p.playbook().go_objective("build_"+site.kind);checks.queued_objective_locates_existing=p.current=="building" and p.argument==int(site.id) and w.kingdom.buildings.size()==building_count
 p.route("building",int(site.id));await shot("construction-status")
 checks.save_compatible=Persistence.save_world(snapshot,game.save_path) and not Persistence.load_world(game.save_path).is_empty()
 var result={"all_passed":not checks.values().has(false),"checks":checks,"count":checks.size(),"physical_device":false}
 var f=FileAccess.open("res://docs/benchmarks/playbook/verification.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();print("PLAYBOOK_UI ",checks.size()," passed=",result.all_passed," failures=",checks.keys().filter(func(k):return not checks[k]));quit(0 if result.all_passed else 1)
