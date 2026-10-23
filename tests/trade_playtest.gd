extends SceneTree
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://builds/phase085e1/"+name+".png")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://trade-rendered-private.json";root.add_child(game);current_scene=game
	var p=preload("res://scripts/trade_progression_probe.gd").new();var ok=p.marketplace();game.world=p.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="en";game.ui.build();game.show_world(true);game.view.invalidate();game.trade_ui.prices()
	game.rng.state=int(game.world.rng_state)
	await create_timer(.5).timeout;await shot("market-prices")
	game.trade_ui.merchant=p.merchant;game.trade_ui.guards=preload("res://scripts/military.gd").available(game.world).slice(0,2).map(func(u):return int(u.id));game.trade_ui.draft()
	await create_timer(.5).timeout;await shot("caravan-draft")
	var T=preload("res://scripts/trade.gd");var id=T.dispatch(game.world,"river",p.merchant,game.trade_ui.guards,{"wood":4});game.trade_ui.watch(id)
	ok=ok and not game.view.visible and not game.view.is_processing() and game.trade_ui.watching
	await create_timer(8).timeout;await shot("caravan-road")
	var frames=[];var previous=Time.get_ticks_usec();var started=previous
	while Time.get_ticks_usec()-started<6000000:
		await process_frame;var now=Time.get_ticks_usec();frames.append((now-previous)/1000.0);previous=now
	var total=0.0
	for ms in frames:total+=ms
	frames.sort();var report={"source":"desktop_live_strategic_caravan","fps":frames.size()*1000.0/total,"p95_ms":frames[int(frames.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory_bytes":OS.get_static_memory_usage(),"actual_progress":T.caravan(game.world,id).progress,"world_tick":game.world.tick}
	var f=FileAccess.open("res://builds/phase085e1/desktop-trade-performance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("E1_RENDERED ",report)
	# Complete the real remaining simulation ticks; no delivery flag injection.
	p.base.driver.rng.state=int(game.world.rng_state)
	for i in range(30):p.base.driver.step()
	await shot("caravan-returned");ok=ok and T.collect(game.world,id) and preload("res://scripts/kingdom.gd").claim(game.world,"main_21")
	game.ui.language="tr";game.trade_ui.open();await create_timer(.3).timeout;await shot("trade-complete-tr")
	ok=ok and game.view.visible and game.view.is_processing() and not game.trade_ui.watching and game.paused
	report.all_passed=ok
	f=FileAccess.open("res://builds/phase085e1/desktop-trade-performance.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("E1_RENDERED_CHECKS ",ok)
	game.queue_free();await process_frame;quit(0 if ok else 1)
