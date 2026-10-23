extends Node
# Runs against the real local API + PostgreSQL, with two disposable accounts.
var game
var endpoint = "http://127.0.0.1:5087"
var destination = "user://phase7-result.json"
var image_dir = ""
var results: Dictionary = {}
var checks: Dictionary = {}
func verify(name: String,ok: bool) -> bool:
	checks[name]=ok
	print("ONLINE ",name,": ",ok)
	return ok
func capture(name: String) -> void:
	if image_dir.is_empty() or DisplayServer.get_name()=="headless":return
	await get_tree().create_timer(.35).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(image_dir.path_join(name+".png"))
func run() -> Dictionary:
	var a=game.online
	var b=preload("res://scripts/online_client.gd").new();add_child(b)
	await get_tree().process_frame
	a.forget();a.endpoint=endpoint;b.endpoint=endpoint
	var nonce=Crypto.new().generate_random_bytes(12).hex_encode()
	var password=Crypto.new().generate_random_bytes(24).hex_encode()
	for entry in [[a,"qa_a_"+nonce],[b,"qa_b_"+nonce]]:
		var r=await entry[0].call_api(HTTPClient.METHOD_POST,"/auth/register",{"account":entry[1],"password":password})
		if not verify("register_"+entry[1].left(4),r.ok):return await finish(a,b)
		r=await entry[0].login(entry[1],password)
		if not verify("login_"+entry[1].left(4),r.ok):return await finish(a,b)
	var ac=str(a.profile.code);var bc=str(b.profile.code)
	for entry in [[a,"QA guardian A"],[b,"QA guardian B"]]:
		var r=await entry[0].call_api(HTTPClient.METHOD_PUT,"/me/profile",{"name":entry[1],"avatar":1,"visibility":"friends"})
		verify("profile_"+entry[1].right(1),r.ok)
		if r.ok:entry[0].profile=r.data
	game.new_planet(2026,"QA home A",false)
	game.has_player_world=true
	game.is_test_session=false
	game.diagnostics.configure("user://phase7-qa-diagnostics.json","simulated")
	game.paused=true
	var own=game.world
	var other=WorldGen.generate(42,"QA published B")
	var rng=RandomNumberGenerator.new();rng.state=int(other.rng_state)
	for i in range(120):Ecosystem.tick(other,rng);Civilization.tick(other)
	var data=game.showcases.project(other)
	var r=await b.call_api(HTTPClient.METHOD_PUT,"/planets/showcase",{"snapshot":data,"visibility":"friends"})
	verify("explicit_publish",r.ok)
	r=await a.fetch_snapshot(bc);verify("not_friends_denied",not r.ok and r.status==404)
	r=await a.call_api(HTTPClient.METHOD_POST,"/friends/"+bc);verify("friend_request",r.ok)
	r=await b.call_api(HTTPClient.METHOD_GET,"/friends");verify("other_account_request",r.ok and r.data.get("items",[]).size()==1)
	r=await b.call_api(HTTPClient.METHOD_PUT,"/friends/"+ac+"/accept");verify("friend_accept",r.ok)
	game.ui.online_screen()
	await game.ui.online_ui.friends()
	await capture("friends")
	game.ui.online_ui.player(bc)
	game.ui.menu()
	while a.busy:await get_tree().process_frame
	await get_tree().process_frame
	verify("cancelled_online_navigation_stays_home",game.ui.page=="menu")
	game.ui.online_screen()
	r=await a.fetch_snapshot(bc)
	if not verify("download_actual_snapshot",r.ok and r.data.get("snapshot",{}).get("planet",{}).get("name","")=="QA published B"):return await finish(a,b)
	results.snapshot_bytes=a.last_bytes;results.snapshot_latency_ms=a.last_latency_ms
	await game.ui.online_ui.snapshot_profile(bc)
	await capture("profile")
	verify("visit_real_snapshot",game.visit_planet(r.data.snapshot,"online:"+bc))
	var saved=FileAccess.get_file_as_bytes(game.save_path)
	var frozen=game.world.duplicate(true)
	game.advance_tick();game.checkpoint();game.schedule_save()
	verify("visit_read_only",game.visiting and game.world==frozen and own==game.visit_origin.world)
	verify("visit_save_unchanged",saved==FileAccess.get_file_as_bytes(game.save_path))
	await capture("visit")
	game.ui.show_creature(game.world.creatures[0])
	verify("creature_inspection",game.ui.hint.text.begins_with(game.world.creatures[0].given_name))
	game.view.selected=game.world.creatures[0].cell
	game.view.selected_creature=0
	game.ui.inspect_selected()
	verify("creature_biography",game.ui.page=="detail")
	await capture("creature")
	if not game.world.settlements.is_empty():
		game.ui.inspect_settlement(game.world.settlements[0]);verify("settlement_inspection",game.ui.hint.text.begins_with(game.world.settlements[0].given_name))
	game.stop_visit()
	verify("return_exact_own_world",game.world==own and game.world.name=="QA home A" and not game.visiting)
	verify("save_compatibility",Persistence.load_world(game.save_path).get("name","")=="QA home A")
	r=await a.call_api(HTTPClient.METHOD_PUT,"/reactions/"+bc,{"kind":2});verify("real_reaction",r.ok)
	r=await b.call_api(HTTPClient.METHOD_GET,"/notifications")
	verify("real_reaction_inbox",r.ok and r.data.get("items",[]).any(func(x):return x.kind=="planet_reaction"))
	# A receives the real acceptance event.
	await game.ui.online_ui.inbox()
	await capture("inbox")
	r=await b.call_api(HTTPClient.METHOD_PUT,"/me/profile",{"name":"QA guardian B","avatar":1,"visibility":"public"});verify("opt_in_profile",r.ok)
	r=await b.call_api(HTTPClient.METHOD_PUT,"/planets/showcase",{"snapshot":data,"visibility":"public"});verify("opt_in_showcase",r.ok)
	await game.ui.online_ui.discovery()
	await capture("discovery")
	game.ui.language="tr";game.ui.online_ui.home()
	await capture("home-tr")
	game.ui.language="en"
	r=await b.call_api(HTTPClient.METHOD_PUT,"/blocks/"+ac);verify("block",r.ok)
	r=await a.fetch_snapshot(bc);verify("blocked_visit_denied_cache_purged",not r.ok and not a.cache.has(bc))
	r=await b.call_api(HTTPClient.METHOD_DELETE,"/planets/showcase");verify("unpublish",r.ok)
	var old_endpoint=a.endpoint;a.endpoint="http://127.0.0.1:5099"
	r=await a.call_api(HTTPClient.METHOD_GET,"/me");verify("network_failure_handled",not r.ok and not a.busy)
	game.paused=false;var tick=game.world.tick;game.advance_tick()
	verify("offline_simulation_after_network_failure",game.world.tick>tick)
	game.power=0;game.touch_world(Vector2(360,620))
	verify("offline_save_after_network_failure",game.checkpoint() and Persistence.load_world(game.save_path).get("name","")=="QA home A")
	game.view.set_quality(true);verify("battery_saver_preserved",Engine.max_fps==30);game.view.set_quality(false)
	a.endpoint=old_endpoint
	return await finish(a,b)
func finish(a,b) -> Dictionary:
	for client in [a,b]:
		if not client.access.is_empty():
			var r=await client.call_api(HTTPClient.METHOD_DELETE,"/me")
			results["delete_status_"+("a" if client==a else "b")]=r.status
			verify("delete_"+("a" if client==a else "b"),r.ok)
		client.forget()
	b.queue_free()
	results.checks=checks;results.source="real_godot_http_postgresql";results.all_passed=not checks.values().has(false)
	results.automated_test=true
	var f=FileAccess.open(destination,FileAccess.WRITE);f.store_string(JSON.stringify(results));f.close()
	return results
