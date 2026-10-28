extends "res://scripts/rpg_android_qa.gd"
var sequence=0
func native(action:String,control:Control,condition:Callable):
	sequence+=1;var point=control.get_global_rect().get_center();host.publish("entry_tap",{"run_id":host.options.run_id,"sequence":sequence,"action":action,"tap_point":[point.x,point.y]})
	var until=Time.get_ticks_msec()+15000
	while not condition.call() and Time.get_ticks_msec()<until:await get_tree().process_frame
	host.checks["native_"+action]=condition.call();await settle()
func run():
	game.is_test_session=true;game.save_path="user://entry-android-private.json";game.ui.language="tr"
	if host.options.get("restore_only",false):
		var w=Persistence.load_world(game.save_path);host.checks.restore_valid=not w.is_empty();host.checks.save_bytes=FileAccess.get_file_as_string(game.save_path).sha256_text()==host.options.expected_sha256;host.checks.account_city_bound=not w.is_empty() and w.has("realm_entry")
		host.publish("entry_restore_complete",{"run_id":host.options.run_id,"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"source":"actual_android_emulator_private_save_restore"});return
	game.online.endpoint=str(host.options.get("endpoint","http://127.0.0.1:5087"));game.ui.main_menu();var entry=game.ui.entry_ui;await shot("entry-android-login")
	var account="qa_"+Crypto.new().generate_random_bytes(8).hex_encode();var password=Crypto.new().generate_random_bytes(24).hex_encode();var r=await game.online.call_api(HTTPClient.METHOD_POST,"/auth/register",{"account":account,"password":password});host.checks.register=r.ok;entry.account.text=account;entry.password.text=password
	await native("login",game.ui.modal.find_child("EntryLogin",true,false),func():return game.ui.modal.find_child("Realm_hearth",true,false)!=null)
	await native("realm",game.ui.modal.find_child("Realm_hearth",true,false),func():return entry.stage=="create")
	await native("mage",game.ui.modal.find_child("FirstClass_mage",true,false),func():return entry.selected_class=="mage");entry.hero_name.text="QA "+Crypto.new().generate_random_bytes(5).hex_encode();await shot("entry-android-create")
	await native("create",game.ui.modal.find_child("CreateRealmHero",true,false),func():return game.ui.modal.find_child("JoinSharedHunt",true,false)!=null);host.checks.only_mage=entry.character.unlocked==["mage"];host.checks.priest_locked=game.ui.modal.find_child("Company_priest",true,false).disabled
	await native("join",game.ui.modal.find_child("JoinSharedHunt",true,false),func():return is_instance_valid(game.shared_hunt_scene) and game.shared_hunt_scene.received)
	if not is_instance_valid(game.shared_hunt_scene):host.publish("entry_failed");return
	var hunt=game.shared_hunt_scene;var until=Time.get_ticks_msec()+12000;var in_range=false
	while Time.get_ticks_msec()<until:
		var me=hunt.snapshot.players.filter(func(p):return p.id==entry.character.id)[0];var targets=hunt.snapshot.enemies.filter(func(e):return e.hp>0)
		if targets.is_empty():await get_tree().process_frame;continue
		var target=targets[0];hunt.selected=int(target.id);var delta=Vector2(target.x-me.x,target.y-me.y)
		if delta.length()<225:in_range=true;break
		hunt.direction=delta.normalized();await get_tree().process_frame
	hunt.direction=Vector2.ZERO;host.checks.server_movement=in_range;var me=hunt.snapshot.players.filter(func(p):return p.id==entry.character.id)[0];var mana=int(me.mp)
	await native("skill",hunt.skill_button,func():return hunt.snapshot.players.any(func(p):return p.id==entry.character.id and p.mp<mana));await shot("entry-android-shared")
	host.checks.valid_city=Persistence.validate(game.world);host.checks.class_bound=game.world.realm_entry.classes==["mage"];host.checks.private_save=Persistence.save_world(game.world,"user://entry-android-private.json")
	await native("return",hunt.exit_button,func():return not is_instance_valid(game.shared_hunt_scene) and not game.online.busy and game.ui.modal.find_child("JoinSharedHunt",true,false)!=null);await shot("entry-android-home");await game.online.call_api(HTTPClient.METHOD_DELETE,"/me")
	host.publish("entry_complete",{"run_id":host.options.run_id,"pid":OS.get_process_id(),"all_passed":not host.checks.values().has(false),"save_sha256":FileAccess.get_file_as_string("user://entry-android-private.json").sha256_text(),"source":"actual_android_emulator_real_account_and_websocket_with_external_adb_taps; server movement intent for skill range"})
