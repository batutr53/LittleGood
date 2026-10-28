extends SceneTree
const K=preload("res://scripts/kingdom.gd")
const C=preload("res://scripts/colony.gd")
var game
var checks={}
func _initialize():call_deferred("run")
func settle():
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
func tick_once():
	for i in range(2):game.last_clock_ms=Time.get_ticks_msec()-2000;game._process(1)
func shot(name):
	await settle();checks["capture_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/reforge/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/reforge");DirAccess.make_dir_recursive_absolute("res://builds/reforge")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://reforge-continuity-private.json";root.add_child(game);current_scene=game;game.set_process(false)
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");load("res://scripts/estate.gd").start(w);C.ensure(w)
	w.kingdom.stock.gold=0;game.world=w;game.view.world=w;game.has_player_world=true;game.paused=false;game.ui.language="tr";game.ui.build();game.ui.close();game.show_world(true);game.view.invalidate()
	var worker=0
	for citizen in w.kingdom.workers:
		if load("res://scripts/military.gd").worker_reserved(w,int(citizen.id)) or load("res://scripts/trade.gd").worker_reserved(w,int(citizen.id)):continue
		K.assign(w,int(citizen.id),0)
		if worker==0:worker=int(citizen.id)
	checks.job_started=C.start(w,worker,"gold");var job=w.colony.jobs[str(worker)];var initial_tick=int(w.tick);game.accumulator=0;game.ui.premium.route("journey");await settle()
	checks.dialogue_context=game.in_menu and game.npc_dialogue_open and game.home_clock_running() and not paused
	checks.original_identity=game.ui.modal.get_meta("npc_id")=="arin";checks.advisor_visible=game.view.advisor_layer.visible
	var nodes=game.view.world_root.get_child_count()
	for i in range(10):tick_once()
	checks.production_while_dialogue=int(w.tick)==initial_tick+10 and int(job.buffer)==C.trip_yield(w,worker,"gold") and job.progress==0
	checks.save_during_dialogue=Persistence.save_world(w,game.save_path);var restored=Persistence.load_world(game.save_path);checks.dialogue_roundtrip=not restored.is_empty() and restored.colony==w.colony and restored.kingdom.industry==w.kingdom.industry
	for i in range(12):game.ui.close();game.ui.premium.route("journey");await process_frame
	await settle();checks.single_window=game.ui.root.find_children("AdvisorDialogue","PanelContainer",true,false).size()==1 and game.view.world_root.get_child_count()==nodes
	checks.reopen_no_production=int(job.buffer)==C.trip_yield(w,worker,"gold") and int(w.tick)==initial_tick+10
	var construction=w.kingdom.buildings[0];construction.progress=maxi(0,int(construction.required)-1000);tick_once();checks.construction_finishes=K.ready(construction)
	var sprite=game.view.kingdom_layer.workers[0];var angle=sprite.rotation;await create_timer(.2).timeout;checks.worker_visual_active=sprite.rotation!=angle
	game.paused=true;var before=int(w.tick);tick_once();checks.explicit_pause_respected=w.tick==before and not game.home_clock_running();game.paused=false
	game.suspended=true;tick_once();checks.suspend_gate=w.tick==before;game.suspended=false
	game.visiting=true;tick_once();checks.visit_gate=w.tick==before;game.visiting=false
	game.ui.premium.route("settings");tick_once();checks.settings_pauses=not game.npc_dialogue_open and w.tick==before
	game.ui.close();var gold=int(w.kingdom.stock.gold);var cargo=int(job.buffer);checks.collect_exact=C.collect(w,worker)>0 and int(w.kingdom.stock.gold)==gold+cargo;checks.collect_no_replay=C.collect(w,worker)==0
	for language in ["tr","en"]:
		game.ui.language=language
		for extent in [Vector2i(320,568),Vector2i(360,800),Vector2i(393,852),Vector2i(412,915),Vector2i(800,1280),Vector2i(1280,720)]:
			root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;game.ui.build();game.ui.premium.route("journey");await settle()
			var key=language+str(extent.x);checks["bounds_"+key]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.get_global_rect());checks["close_"+key]=game.ui.modal.find_child("SurfaceBack",true,false).get_global_rect().size.y>=48
			checks["action_"+key]=game.ui.modal.find_child("AdvisorNextStep",true,false).get_global_rect().size.y>=48
			await shot("r2-dialogue-"+key)
	game.ui.close();checks.clock_released=not game.npc_dialogue_open and game.home_clock_running()
	checks.final_valid=Persistence.validate(w)
	# Legitimate first-chapter actions, then the actual NPC reward callback twice.
	game.new_planet(42,"Reforge reward",false);var first=game.world;checks.found_first=K.enable(first);C.ensure(first);var first_worker=int(first.kingdom.workers[0].id);C.start(first,first_worker,"wood");K.observe_settlers(first,int(K.home(first).cell))
	for i in range(30):first.tick+=1;K.tick(first)
	C.collect(first,first_worker);game.ui.premium.route("journey");await settle();var claim=game.ui.modal.find_child("AdvisorClaimReward",true,false);checks.npc_reward_offered=claim!=null
	if claim:
		var callback=claim.pressed.get_connections()[0].callable;callback.call();await settle();checks.npc_reward_advances=first.kingdom.claimed.has("main_01");var claimed=first.kingdom.duplicate(true);callback.call();checks.npc_reward_no_replay=first.kingdom==claimed
	checks.npc_reward_save=Persistence.save_world(first,"user://reforge-first-reward-private.json") and not Persistence.load_world("user://reforge-first-reward-private.json").is_empty()
	var result={"all_passed":not checks.values().has(false),"count":checks.size(),"checks":checks,"source":"Private fixture; authoritative simulation through actual main clock gate; rendered NPC dialogue at real viewports, not a full onboarding journey"};var file=FileAccess.open("res://builds/reforge/continuity.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));print("REFORGE_CONTINUITY "+JSON.stringify(result));quit(0 if result.all_passed else 1)
