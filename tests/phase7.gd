extends SceneTree
var checks=0
var failures=0
func check(value: bool, label: String) -> void:
	checks+=1
	if not value: failures+=1;push_error(label)
	print(("PASS " if value else "FAIL ")+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var net=preload("res://scripts/online_client.gd").new()
	root.add_child(net)
	await process_frame
	check(net.access.is_empty() and net.renewal.is_empty(),"No startup credentials")
	check(not net.set_tokens({"accessToken":"bad\nheader","refreshToken":"x"}),"Token header injection refused")
	check(not net.set_tokens({"accessToken":"","refreshToken":"x"}),"Empty tokens refused")
	check(net.valid_code("0123456789abcdef0123456789abcdef"),"Valid opaque code")
	check(not net.valid_code("../another-player"),"Code traversal refused")
	check(not net.valid_code("0123456789abcdef0123456789abcdeg"),"Nonhex code refused")
	check(not net.configure("http://example.com:5087"),"Public cleartext refused")
	check(not net.configure("https://user:password@example.com"),"URL credentials refused")
	check(not net.configure("https://example.com?token=secret"),"Query secrets refused")
	# Tests use a separate config path sandbox and restore settings below.
	var cfg_path="user://online.cfg"
	var original=FileAccess.get_file_as_bytes(cfg_path) if FileAccess.file_exists(cfg_path) else PackedByteArray()
	var existed=FileAccess.file_exists(cfg_path)
	check(net.configure("http://127.0.0.1:5087"),"Debug loopback allowed")
	net.access="private-access";net.renewal="private-refresh";net.profile={"name":"guardian"};net.cache={"x":{}}
	var disk=FileAccess.get_file_as_string(cfg_path)
	check(not "private-access" in disk and not "private-refresh" in disk,"Tokens absent from configuration")
	net.forget()
	check(net.access.is_empty() and net.renewal.is_empty() and net.cache.is_empty() and net.profile.is_empty(),"Logout clears private memory")
	var invalid=await net.fetch_snapshot("bad")
	check(invalid.status==404 and not invalid.ok,"Invalid identifier rejected before transport")
	net.endpoint=""
	var offline=await net.call_api(HTTPClient.METHOD_GET,"/me")
	check(not offline.ok and offline.status==0 and not net.busy,"Unconfigured online service returns without blocking local play")
	var w=WorldGen.generate(2026,"Kept offline")
	var before=w.tick
	var rng=RandomNumberGenerator.new();rng.seed=2026
	Ecosystem.tick(w,rng)
	check(w.tick>before,"Local simulation independent of API")
	if existed:
		var f=FileAccess.open(cfg_path,FileAccess.WRITE);f.store_buffer(original);f.close()
	else:DirAccess.remove_absolute(cfg_path)
	net.queue_free()
	print("PHASE7 ",checks-failures,"/",checks)
	quit(1 if failures else 0)
