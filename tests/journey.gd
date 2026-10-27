extends SceneTree
const J=preload("res://scripts/journey.gd")
const D=preload("res://scripts/drop_guide.gd")
const K=preload("res://scripts/kingdom.gd")
var game
var checks={}
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame
func button(prefix):
	for b in game.ui.modal.find_children("*","Button",true,false):
		if b.text.begins_with(prefix):return b
	return null
func shot(name):
	await settle();await RenderingServer.frame_post_draw;checks["image_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/journey/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/journey");DirAccess.make_dir_recursive_absolute("res://docs/benchmarks/journey")
	for stage in [["a","industry"],["b","hero"],["c","army"],["d","trade"]]:
		var w=Persistence.load_world("res://tests/fixtures/planet-v085"+stage[0]+".json");var before=w.duplicate(true);var key=stage[1];checks[key+"_offered"]=J.transition(w)==key;checks[key+"_advice_readonly"]=J.report(w).has("route") and w==before
		var ro=w.duplicate(true);ro._read_only=true;checks[key+"_readonly"]=not J.advance(ro,key);checks[key+"_wrong"]=not J.advance(w,"wrong") and w==before;checks[key+"_advance"]=J.advance(w,key);checks[key+"_no_replay"]=not J.advance(w,key);checks[key+"_identity"]=w.kingdom.workers==before.kingdom.workers and w.kingdom.claimed==before.kingdom.claimed;checks[key+"_valid"]=Persistence.validate(w)
	var rows=D.catalogue();checks.all_monsters=rows.size()==12;checks.all_regions=load("res://scripts/regions.gd").IDS.all(func(region):return rows.any(func(row):return row.region==region));checks.source_unchanged=JSON.stringify(D.catalogue())==JSON.stringify(rows);checks.gold_search=not D.search("altın").is_empty();checks.localized_search=not D.search("kurt").is_empty();checks.region_filter=D.search("","sanctuary").all(func(row):return row.region=="sanctuary");checks.class_item_search=D.search("legend_mage_weapon","all","mage").size()==3;checks.no_fake_items=D.search("does-not-exist").is_empty()
	for row in rows:
		var def=load("res://scripts/adventure.gd").enemies()[row.kind];checks[row.kind+"_real_xp"]=row.xp==def.xp;checks[row.kind+"_real_chances"]=row.rewards.all(func(reward):return reward.chance_bp>0 and reward.chance_bp<=10000)
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://journey-ui-only.json";root.add_child(game);current_scene=game
	game.new_planet(42,"First loop",false);var first=game.world;var C0=load("res://scripts/colony.gd");checks.founding=K.enable(first);C0.ensure(first);var worker_id=int(first.kingdom.workers[0].id);checks.first_gather=C0.start(first,worker_id,"wood");K.observe_settlers(first,int(K.home(first).cell))
	for i in range(30):first.tick+=1;K.tick(first)
	checks.first_cargo=C0.collect(first,worker_id)==6000;checks.first_quest=K.claim(first,"main_01");checks.first_reward_once=not K.claim(first,"main_01");checks.leave_gather=C0.release(first,worker_id);var site=-1
	for i in range(first.cells.size()):
		if K.valid_site(first,"lumber",i) and first.cells[i].plants>=.6 and first.cells[i].resources>=6:site=i;break
	var building_id=K.begin_build(first,"lumber",site);checks.first_build=building_id>0
	for i in range(10):first.tick+=1;K.tick(first)
	checks.first_build_complete=K.count(first,"lumber")==1;checks.first_collect_construction=load("res://scripts/estate.gd").collect(first,building_id).has("built");checks.first_production_worker=K.assign(first,worker_id,building_id)
	checks.second_lumberjack=K.assign(first,int(K.assigned(first,0)[0].id),building_id)
	for i in range(10):first.tick+=1;K.tick(first)
	checks.first_production=load("res://scripts/estate.gd").collect(first,building_id).get("wood",0)>=4000;checks.second_quest=K.claim(first,"main_02");checks.first_loop_valid=Persistence.validate(first)
	var w=Persistence.load_world("res://tests/fixtures/planet-v085b.json");checks.open_hero_chapter=J.advance(w,"hero");load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.has_player_world=true;game.paused=true;game.show_world(true);game.ui.language="tr";game.ui.build();game.ui.close();game.ui.premium.route("hero");await settle();checks.recruitment_reachable=button("Şampiyonu çağır")!=null;await shot("recruitment");var gold=w.kingdom.stock.gold;var food=K.home(w).food;button("Şampiyonu çağır").pressed.emit();await settle();checks.recruit_once=not w.kingdom.adventure.hero.is_empty() and w.kingdom.stock.gold==gold-3000 and K.home(w).food==food-5;checks.roster_created=w.has("rpg") and w.rpg.roster.size()==4;checks.recruit_valid=Persistence.validate(w)
	w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");w.kingdom.adventure.run.active=false;load("res://scripts/estate.gd").start(w);game.world=w;game.view.world=w;game.paused=true;game.ui.build();game.ui.close();var p=game.ui.premium;var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];var free=K.assigned(w,0)[0]
	p.route("staffing",int(farm.id));await settle();var assign=button("Ata: "+free.name);checks.direct_staffing=assign!=null
	if assign:assign.pressed.emit();await settle()
	checks.actual_staffing=int(free.building)==int(farm.id);checks.staffing_valid=Persistence.validate(w);var snap=w.duplicate(true)
	for extent in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle()
		for locale in ["tr","en"]:
			game.ui.language=locale;game.ui.build();p=game.ui.premium
			p.current_recipe="iron_sword"
			for route in ["journey","staffing","bestiary","contracts","forge","forge_queue","recipe","material"]:
				p.route(route,int(farm.id) if route=="staffing" else 0);await settle();var key=route+str(extent.x)+locale;checks[key+"_no_scroll"]=game.ui.modal.find_child("SurfaceContent",true,false).size.y<=p.scroll.size.y+1;checks[key+"_fits"]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.get_global_rect())
				if locale=="tr":await shot(route+"-"+str(extent.x))
	checks.navigation_no_grants=w==snap;game.ui.language="tr";p.route("journey");await settle();button("Dünyayı sürdür").pressed.emit();await settle();checks.resume_explicit=not game.paused and not game.in_menu;game.paused=true;checks.save=Persistence.save_world(w,game.save_path) and not Persistence.load_world(game.save_path).is_empty()
	var L=load("res://scripts/settlement_layout.gd");checks.locked_market_protected=L.propose(w).is_empty();var T=load("res://scripts/trade.gd");K.spend(w,{"wood":60})
	for i in range(60):
		w.tick+=1;T.tick(w)
		for caravan in w.kingdom.trade.caravans:
			if caravan.state=="blocked":T.resolve(w,int(caravan.id),false)
			if caravan.state=="ready":T.collect(w,int(caravan.id))
	var before_layout=w.duplicate(true);var layout=L.propose(w);checks.layout_preview_readonly=w==before_layout;checks.complete_plan=layout.size()==w.kingdom.buildings.size();checks.layout_moves=layout.any(func(entry):return entry.from!=entry.to);checks.layout_apply=L.apply(w,layout);checks.layout_valid=Persistence.validate(w);checks.layout_spacious=w.kingdom.buildings.all(func(b):return L.clear(w,int(b.cell),int(b.id)));checks.layout_ids=w.kingdom.buildings.map(func(b):return b.id)==before_layout.kingdom.buildings.map(func(b):return b.id);checks.layout_workers=w.kingdom.workers==before_layout.kingdom.workers and w.estate==before_layout.estate;checks.layout_stale_rejected=not L.apply(w,layout);p.route("layout");await shot("layout-review");game.ui.close();game.view.pan=Vector2.ZERO;game.view.invalidate();await shot("spacious-village")
	var I=load("res://scripts/industry.gd");var C=load("res://scripts/colony.gd");var axe_id=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":axe_id,"recipe":"forest_axe"});I.equip(w,int(free.id),axe_id);checks.real_tool_yield=C.trip_yield(w,int(free.id),"wood")==3000;checks.no_fishing_axe_bonus=C.trip_yield(w,int(free.id),"fish")==2000
	var report={"count":checks.size(),"checks":checks,"all_passed":not checks.values().has(false)};var f=FileAccess.open("res://docs/benchmarks/journey/verification.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));print("JOURNEY ",checks.size()," passed=",report.all_passed," failures=",checks.keys().filter(func(k):return not checks[k]));quit(0 if report.all_passed else 1)
