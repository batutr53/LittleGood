extends Node
const T=preload("res://scripts/trade.gd")
const M=preload("res://scripts/military.gd")
var game
var host
func wait_marker(name: String) -> void:
	while not FileAccess.file_exists("user://"+name):await get_tree().process_frame
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://"+name+".png")
func prefix(node: Node,text: String) -> Button:
	if node is Button and node.text.begins_with(text):return node
	for c in node.get_children():
		var result=prefix(c,text)
		if result:return result
	return null
func buttons(node: Node,text: String) -> Array:
	var result=[]
	if node is Button and node.text==text:result.append(node)
	for c in node.get_children():result.append_array(buttons(c,text))
	return result
func run() -> void:
	if host.options.get("phase")=="trade_profile":
		var probe=preload("res://scripts/trade_progression_probe.gd").new();var ok=probe.marketplace();game.world=probe.world;game.view.world=game.world;game.has_player_world=true;game.paused=true
		var id=T.dispatch(game.world,"river",probe.merchant,M.available(game.world).slice(0,2).map(func(u):return int(u.id)),{"wood":4});game.trade_ui.watch(id)
		var render_planet=bool(host.options.get("render_planet",false));game.show_world(render_planet)
		await get_tree().create_timer(2).timeout;var samples=[];var previous=Time.get_ticks_usec();var started=previous
		while Time.get_ticks_usec()-started<12000000:
			await get_tree().process_frame;var now=Time.get_ticks_usec();samples.append((now-previous)/1000.0);previous=now
		var total=0.0
		for ms in samples:total+=ms
		samples.sort();host.publish("trade_profile_complete",{"valid":ok and Persistence.validate(game.world),"planet_rendering":render_planet,"fps":samples.size()*1000.0/total,"p95_ms":samples[int(samples.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"memory_bytes":OS.get_static_memory_usage(),"cap":Engine.max_fps});return
	if host.options.get("phase")=="trade_reopen":
		var expected=Persistence.load_world(game.save_path);await game.restore()
		host.checks.exact_pending=game.world.kingdom==expected.kingdom and game.world.tick==expected.tick
		var c=game.world.kingdom.trade.caravans[-1];host.checks.merchant_reserved=T.worker_reserved(game.world,int(c.merchant))
		game.trade_ui.watch(int(c.id));await get_tree().create_timer(.4).timeout
		host.publish("trade_reopen_touch",{"detour":host.point(prefix(game.ui.modal,"Hazard: safe detour")),"collect":host.point(prefix(game.ui.modal,"Collect returned"))})
		await wait_marker("trade_detour")
		host.checks.native_detour=c.outcome=="detour"
		while not c.state in ["ready","collected"]:await get_tree().process_frame
		host.publish("trade_reopen_collect",{"collect":host.point(prefix(game.ui.modal,"Collect returned"))});await wait_marker("trade_collected")
		host.checks.native_collect=c.state=="collected" and c.sold
		host.checks.menu_pause_restored=not game.trade_ui.watching and game.view.visible and game.paused
		host.checks.no_replay=not T.collect(game.world,int(c.id)) and Persistence.validate(game.world)
		host.publish("trade_reopened",{"all_passed":not host.checks.values().has(false)});return
	var p=preload("res://scripts/trade_progression_probe.gd").new();host.checks.legal_market=p.marketplace();game.world=p.world;game.view.world=game.world;game.has_player_world=true;game.paused=true;game.show_world(true);game.view.invalidate()
	game.trade_ui.merchant=p.merchant;game.trade_ui.guards=M.available(game.world).slice(0,2).map(func(u):return int(u.id));game.trade_ui.draft()
	await get_tree().create_timer(.5).timeout;await shot("android-trade-draft")
	var wood=int(game.world.kingdom.stock.wood)
	var plus=buttons(game.ui.modal,"+")[0]
	# Native + rebuilds the panel; the footer confirm retains the same layout rectangle.
	host.publish("trade_draft_touch",{"plus":host.point(plus),"confirm":host.point(prefix(game.ui.modal,"Confirm departure"))});await wait_marker("trade_dispatched")
	var caravans=game.world.kingdom.trade.caravans
	host.checks.native_dispatch=caravans.size()==1
	if caravans.is_empty():host.publish("trade_failed");return
	var c=caravans[0];host.checks.native_cargo=c.cargo.wood==5 and game.world.kingdom.stock.wood<=wood-5000
	var intervals=[];var previous=Time.get_ticks_usec();var started=previous
	while c.state!="ready" and Time.get_ticks_usec()-started<120000000:
		await get_tree().process_frame;var now=Time.get_ticks_usec();intervals.append((now-previous)/1000.0);previous=now
	intervals.sort();var total=0.0
	for ms in intervals:total+=ms
	var profile={"fps":intervals.size()*1000.0/total,"p95_ms":intervals[int(intervals.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"memory_bytes":OS.get_static_memory_usage(),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"frames":intervals.size(),"cap":Engine.max_fps,"simulation_peak_ms":game.simulation_peak_ms,"simulation_average_ms":game.simulation_total_ms/maxi(1,game.simulation_samples)}
	host.checks.actual_ready=c.state=="ready" and c.sold;await shot("android-trade-returned")
	host.publish("trade_collect_touch",{"collect":host.point(prefix(game.ui.modal,"Collect returned"))});await wait_marker("trade_first_collected")
	host.checks.native_collect=c.state=="collected" and game.world.kingdom.trade.delivered==1
	host.checks.menu_pause_restored=not game.trade_ui.watching and game.view.visible and game.paused
	host.checks.quest21=preload("res://scripts/kingdom.gd").claim(game.world,"main_21")
	# A second real unescorted route saves at a hazard for genuine process restart.
	var id=T.dispatch(game.world,"river",p.merchant,[],{"stone":1})
	game.trade_ui.watch(id)
	while T.caravan(game.world,id).state!="blocked":await get_tree().process_frame
	game.ui.close();game.paused=true;host.checks.pending_checkpoint=game.checkpoint("trade-restart")
	game.ui.language="tr";game.trade_ui.open();await shot("android-trade-complete-tr")
	host.publish("trade_complete",{"all_passed":not host.checks.values().has(false),"profile":profile})
