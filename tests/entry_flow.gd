extends SceneTree
var game
var checks={}
var observer=WebSocketPeer.new()
var other
var other_id=""
var credentials=[]
func _initialize():call_deferred("run")
func settle():await process_frame;await process_frame
func wait_for(predicate,seconds=15.0):
	var until=Time.get_ticks_msec()+int(seconds*1000)
	while not predicate.call() and Time.get_ticks_msec()<until:observer.poll();await process_frame
	return predicate.call()
func click(control):
	if control==null:return
	var point=control.get_global_rect().get_center();var motion=InputEventMouseMotion.new();motion.position=point;Input.parse_input_event(motion);await process_frame
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.position=point;e.pressed=true;Input.parse_input_event(e);await process_frame;e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await settle()
func shot(name):
	await settle();await RenderingServer.frame_post_draw;checks["capture_"+name]=root.get_texture().get_image().save_png("res://docs/screenshots/lobby/"+name+".png")==OK
func run():
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots/lobby");DirAccess.make_dir_recursive_absolute("res://builds/lobby")
	game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://entry-test-private.json";root.add_child(game);current_scene=game;await settle();game.online.endpoint=OS.get_environment("LITTLEGOD_TEST_ORIGIN") if not OS.get_environment("LITTLEGOD_TEST_ORIGIN").is_empty() else "http://127.0.0.1:5087";game.ui.language="tr";game.ui.main_menu();var entry=game.ui.entry_ui
	for extent in [Vector2i(960,540),Vector2i(1600,720)]:
		root.min_size=Vector2i.ONE;root.size=extent;root.content_scale_size=extent;await settle();entry.open();await settle();var panel=game.ui.modal.find_child("EntryForm",true,false)
		checks["fullscreen_"+str(extent.x)]=game.ui.modal.position==Vector2.ZERO and game.ui.modal.size==Vector2(extent);checks["login_fits_"+str(extent.x)]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(panel.get_global_rect());await shot("login-"+str(extent.x))
	var account="qa_"+Crypto.new().generate_random_bytes(8).hex_encode();var password=Crypto.new().generate_random_bytes(24).hex_encode();var registered=await game.online.call_api(HTTPClient.METHOD_POST,"/auth/register",{"account":account,"password":password});checks.registration=registered.ok
	entry.account.text=account;entry.password.text=password;await click(game.ui.modal.find_child("EntryLogin",true,false));checks.native_login=await wait_for(func():return game.ui.modal.find_child("Realm_hearth",true,false)!=null);checks.password_cleared=not is_instance_valid(entry.password) or entry.password.text.is_empty();await shot("realms")
	await click(game.ui.modal.find_child("Realm_hearth",true,false));checks.native_realm=await wait_for(func():return entry.stage=="create")
	for extent in [Vector2i(960,540),Vector2i(1600,720)]:
		root.size=extent;root.content_scale_size=extent;await settle();entry.create_page();await settle();var mage=game.ui.modal.find_child("FirstClass_mage",true,false);checks["class_button_width_"+str(extent.x)]=mage.size.x>85
		await click(mage);checks["native_mage_"+str(extent.x)]=entry.selected_class=="mage";await settle();checks["create_fits_"+str(extent.x)]=Rect2(Vector2.ZERO,Vector2(extent)).encloses(game.ui.modal.find_child("CreateRealmHero",true,false).get_global_rect());await shot("create-mage-"+str(extent.x))
	entry.hero_name.text="QA "+Crypto.new().generate_random_bytes(5).hex_encode();await shot("create-mage")
	await click(game.ui.modal.find_child("CreateRealmHero",true,false));checks.native_create=await wait_for(func():return game.ui.modal.find_child("JoinSharedHunt",true,false)!=null)
	if not checks.native_create:
		print("ENTRY_FLOW failed before character creation: "+JSON.stringify(checks)+" status="+entry.message);quit(1);return
	checks.initial_one_class=entry.character.unlocked==["mage"];checks.priest_locked=game.ui.modal.find_child("Company_priest",true,false).disabled;await shot("first-company")
	# A second real authenticated Godot transport joins the same server instance.
	other=load("res://scripts/online_client.gd").new();root.add_child(other);other.endpoint=game.online.endpoint;var other_account="qa_"+Crypto.new().generate_random_bytes(8).hex_encode();var other_password=Crypto.new().generate_random_bytes(24).hex_encode();await other.call_api(HTTPClient.METHOD_POST,"/auth/register",{"account":other_account,"password":other_password});checks.second_login=(await other.login(other_account,other_password)).ok
	var c=await other.call_api(HTTPClient.METHOD_POST,"/realms/hearth/characters",{"name":"QA "+Crypto.new().generate_random_bytes(5).hex_encode(),"class":"priest"});other_id=c.data.id;var ticket=await other.call_api(HTTPClient.METHOD_POST,"/realms/hearth/characters/"+other_id+"/enter");observer.connect_to_url(game.online.endpoint.replace("https://","wss://").replace("http://","ws://")+"/play");await wait_for(func():return observer.get_ready_state()==WebSocketPeer.STATE_OPEN);observer.send_text(JSON.stringify({"ticket":ticket.data.ticket}))
	await click(game.ui.modal.find_child("JoinSharedHunt",true,false));checks.native_join=await wait_for(func():return is_instance_valid(game.shared_hunt_scene) and game.shared_hunt_scene.received);var hunt=game.shared_hunt_scene
	checks.two_godot_peers=await wait_for(func():return hunt.snapshot.players.size()==2);checks.city_bound=game.world.realm_entry.character==entry.character.id and game.world.realm_entry.classes==["mage"];checks.local_class_lock=not load("res://scripts/rpg_progression.gd").switch(game.world,"warrior");checks.city_valid=Persistence.validate(game.world);await shot("two-clients-shared-hunt")
	var deadline=Time.get_ticks_msec()+60000;var earned=false
	while Time.get_ticks_msec()<deadline:
		observer.poll();var me=hunt.snapshot.players.filter(func(p):return p.id==entry.character.id)[0]
		if int(me.hunts)>=3:earned=true;break
		var enemies=hunt.snapshot.enemies.filter(func(e):return e.hp>0)
		if not enemies.is_empty():
			var target=enemies[0];hunt.selected=int(target.id);var toward=Vector2(target.x-me.x,target.y-me.y);hunt.direction=toward.normalized() if toward.length()>190 else -toward.normalized() if toward.length()<100 else Vector2.ZERO;hunt.attack_held=true
		await process_frame
	checks.actual_three_hunts=earned;hunt.direction=Vector2.ZERO;hunt.attack_held=false;await shot("earned-essence")
	await click(hunt.exit_button);checks.native_leave=await wait_for(func():return not is_instance_valid(game.shared_hunt_scene) and game.ui.modal.find_child("Company_priest",true,false)!=null and not game.online.busy)
	checks.recruit_ready=not game.ui.modal.find_child("Company_priest",true,false).disabled;await click(game.ui.modal.find_child("Company_priest",true,false));checks.native_recruit=await wait_for(func():return "priest" in entry.character.unlocked);await shot("recruited-company")
	await click(game.ui.modal.find_child("JoinSharedHunt",true,false));checks.party_join=await wait_for(func():return is_instance_valid(game.shared_hunt_scene) and game.shared_hunt_scene.received);hunt=game.shared_hunt_scene;checks.party_companion=await wait_for(func():return hunt.snapshot.get("companions",[]).any(func(a):return a.owner==entry.character.id and a.job=="priest"));await shot("priest-companion")
	hunt.leave();await wait_for(func():return not game.online.busy);observer.close();await game.online.call_api(HTTPClient.METHOD_DELETE,"/me");await other.call_api(HTTPClient.METHOD_DELETE,"/me")
	var report={"all_passed":not checks.values().has(false),"count":checks.size(),"checks":checks,"source":"rendered Godot native mouse UI, actual HTTP accounts, two authenticated Godot WebSocket peers and unmodified server combat; movement/attack intent bot for three earned hunts"};var f=FileAccess.open("res://builds/lobby/entry-ui.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));print("ENTRY_FLOW "+JSON.stringify(report));quit(0 if report.all_passed else 1)
