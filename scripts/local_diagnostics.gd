class_name LocalDiagnostics
extends RefCounted

# Private app storage only. Never store planet/creature names, seed, paths or identifiers.
const ALLOWED = ["session_started", "session_ended", "unclean_previous_session", "planet_created", "first_power", "first_creature", "first_settlement", "onboarding_completed", "save_completed", "world_restored", "handled_error", "power_used", "memory_found", "return_day", "first_launch"]
var path = "user://diagnostics.json"
var enabled = true
var source = "player"
var active_seconds = 0.0
var running = false
var data: Dictionary = {"schema": 1, "events": [], "once": {}}

func configure(destination: String = "user://diagnostics.json", kind: String = "player") -> void:
	path = destination
	source = kind
	data = {"schema": 1, "events": [], "once": {}}
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and parsed.get("events") is Array and parsed.get("once") is Dictionary:
			data = parsed
			if data.has("first_day") and not (data.first_day is int or data.first_day is float): data.erase("first_day")
			if data.has("visit_days") and not data.visit_days is Array: data.erase("visit_days")

func begin() -> void:
	if not enabled or running: return
	if FileAccess.file_exists(path + ".open"): record("unclean_previous_session")
	running = true
	active_seconds = 0
	var marker = FileAccess.open(path + ".open", FileAccess.WRITE)
	if marker: marker.store_string(source)
	record("session_started")
	var day = int(Time.get_unix_time_from_system() / 86400)
	if not data.has("first_day"): data.first_day = day
	var relative = maxi(0, day - int(data.first_day))
	if not data.has("visit_days"): data.visit_days = []
	if not data.visit_days.has(relative):
		data.visit_days.append(relative)
		if data.visit_days.size() > 32: data.visit_days.pop_front()
		record("return_day", relative)

func advance(seconds: float) -> void:
	if running and enabled: active_seconds += clampf(seconds, 0, 1)

func record(key: String, value: int = 0, only_once: bool = false) -> void:
	if not enabled or not ALLOWED.has(key): return
	if only_once and data.once.has(key): return
	if only_once: data.once[key] = true
	data.events.append({"event": key, "seconds": int(active_seconds), "value": clampi(value, 0, 1000000), "source": source})
	while data.events.size() > 200: data.events.pop_front()
	flush()

func flush() -> void:
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data))

func finish() -> void:
	if running: record("session_ended", int(active_seconds))
	running = false
	if FileAccess.file_exists(path + ".open"): DirAccess.remove_absolute(path + ".open")

func clear() -> void:
	data = {"schema": 1, "events": [], "once": {}}
	running = false
	active_seconds = 0
	for suffix in ["", ".open", ".feedback.json"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)

func feedback() -> Dictionary:
	# Rebuild every field from a whitelist, even if a local file was manually edited.
	var events: Array = []
	for e in data.events:
		if not e is Dictionary or not ALLOWED.has(e.get("event")): continue
		events.append({"event": e.event, "seconds": maxi(0, int(e.get("seconds", 0))), "value": maxi(0, int(e.get("value", 0))), "source": "simulated" if e.get("source") == "simulated" else "player"})
	return {"schema": 1, "game_version": ProjectSettings.get_setting("application/config/version"), "platform": OS.get_name(), "scope": "local_optional_feedback", "events": events.slice(maxi(0, events.size() - 200))}

func export_feedback() -> String:
	var text = JSON.stringify(feedback(), "\t")
	var f = FileAccess.open(path + ".feedback.json", FileAccess.WRITE)
	if f: f.store_string(text)
	return text
