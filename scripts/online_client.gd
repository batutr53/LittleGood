extends Node

# Optional transport. No requests at startup, no stored password/token, no background polling.
const Showcase = preload("res://scripts/planet_showcase.gd")
var endpoint = ""
var access = ""
var renewal = ""
var profile: Dictionary = {}
var busy = false
var connected = false
var cache: Dictionary = {}
var last_latency_ms = 0.0
var last_bytes = 0
var session_epoch = 0

func _ready() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://online.cfg") == OK: endpoint = str(cfg.get_value("online","endpoint",""))

func configure(value: String) -> bool:
	value = value.strip_edges().trim_suffix("/")
	# Cleartext allowed only for explicit local debug development, including emulator host alias.
	var local = value in ["http://127.0.0.1:5087","http://localhost:5087","http://10.0.2.2:5087"]
	if not value.is_empty() and not (value.begins_with("https://") or (OS.is_debug_build() and local)): return false
	if "@" in value or "?" in value or "#" in value or value.length()>256: return false
	forget()
	endpoint = value
	var cfg = ConfigFile.new()
	cfg.set_value("online","endpoint",endpoint)
	cfg.save("user://online.cfg")
	return true

func forget() -> void:
	session_epoch+=1
	access = ""
	renewal = ""
	profile = {}
	cache.clear()
	connected = false

func raw(method: int, path: String, body: Dictionary = {}, authenticated: bool = true) -> Dictionary:
	if endpoint.is_empty(): return {"ok":false,"status":0}
	var request_node = HTTPRequest.new()
	request_node.use_threads = true
	request_node.timeout = 6.0
	request_node.body_size_limit = 2200000
	add_child(request_node)
	var headers = PackedStringArray(["Content-Type: application/json","Accept: application/json"])
	if authenticated and not access.is_empty(): headers.append("Authorization: Bearer " + access)
	var started = Time.get_ticks_usec()
	var error = request_node.request(endpoint + "/api/v1" + path,headers,method,JSON.stringify(body) if method in [HTTPClient.METHOD_POST,HTTPClient.METHOD_PUT] else "")
	if error != OK:
		request_node.queue_free()
		connected = false
		return {"ok":false,"status":0}
	var response = await request_node.request_completed
	request_node.queue_free()
	last_latency_ms = (Time.get_ticks_usec()-started)/1000.0
	last_bytes = response[3].size()
	var code = int(response[1])
	connected = response[0] == HTTPRequest.RESULT_SUCCESS and code>0
	var parsed = JSON.parse_string(response[3].get_string_from_utf8()) if response[3].size()>0 else {}
	return {"ok":connected and code>=200 and code<300,"status":code,"data":parsed if parsed is Dictionary else {}}

func call_api(method: int,path: String,body: Dictionary = {}) -> Dictionary:
	if busy: return {"ok":false,"status":-1}
	busy = true
	var epoch = session_epoch
	var result = await raw(method,path,body)
	if epoch!=session_epoch:
		busy=false
		return {"ok":false,"status":401}
	if result.status == 401 and not renewal.is_empty():
		var renew = await raw(HTTPClient.METHOD_POST,"/auth/refresh",{"refreshToken":renewal},false)
		if epoch!=session_epoch:
			busy=false
			return {"ok":false,"status":401}
		if renew.ok and set_tokens(renew.data): result = await raw(method,path,body)
		else: forget()
	busy = false
	return result

func set_tokens(data: Dictionary) -> bool:
	if not data.get("accessToken",null) is String or not data.get("refreshToken",null) is String: return false
	for value in [data.accessToken,data.refreshToken]:
		if value.is_empty() or value.length()>8192:return false
		for ch in value:
			if ch.unicode_at(0)<33 or ch.unicode_at(0)>126:return false
	access = data.accessToken
	renewal = data.refreshToken
	return true

func login(account: String,password: String) -> Dictionary:
	if busy:return {"ok":false,"status":-1}
	forget()
	var r = await call_api(HTTPClient.METHOD_POST,"/auth/login",{"account":account,"password":password})
	if r.ok:
		if not set_tokens(r.data):return {"ok":false,"status":422}
		var me = await call_api(HTTPClient.METHOD_GET,"/me")
		if me.ok: profile = me.data
		else: forget(); return me
	return r

func fetch_snapshot(code: String) -> Dictionary:
	if not valid_code(code): return {"ok":false,"status":404}
	# Reauthorize every online visit. Memory cache is private to this login, never a local save.
	var r = await call_api(HTTPClient.METHOD_GET,"/planets/"+code+"/showcase")
	if r.ok:
		if r.data.get("version",0)!=1 or not Showcase.validate(r.data.get("snapshot",{})): return {"ok":false,"status":422}
		if cache.size()>=8: cache.erase(cache.keys()[0])
		cache[code] = r.data.snapshot.duplicate(true)
	elif r.status in [401,403,404]: cache.erase(code)
	return r

static func valid_code(code: String) -> bool:
	if code.length()!=32: return false
	for c in code:
		if not c in "0123456789abcdef": return false
	return true
