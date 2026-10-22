class_name Persistence
extends RefCounted

const PATH = "user://planet.json"
const MAX_OFFLINE_SECONDS = 28800
static var last_recovery = "none"

static func has_save(path: String = PATH) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak") or FileAccess.file_exists(path + ".tmp")

static func save_world(w: Dictionary, path: String = PATH) -> bool:
	var candidate = w.duplicate()
	candidate.saved_at = Time.get_unix_time_from_system()
	if not validate(candidate): return false
	var payload = JSON.stringify(candidate)
	var envelope = JSON.stringify({"checksum": payload.sha256_text(), "payload": payload})
	var f = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null: return false
	f.store_string(envelope)
	f.flush()
	var write_error = f.get_error()
	f.close()
	if write_error != OK or read_checked(path + ".tmp").is_empty(): return false
	# Never replace the healthy recovery copy with a corrupt primary.
	if not read_checked(path).is_empty():
		if DirAccess.copy_absolute(path, path + ".bak") != OK: return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return false
	w.saved_at = candidate.saved_at
	return true

static func validate(w: Variant) -> bool:
	if not w is Dictionary: return false
	for key in ["version", "seed", "name", "tick", "cells", "creatures", "settlements", "events", "discoveries", "achievements", "energy", "xp", "weather", "rng_state", "saved_at", "theme"]:
		if not w.has(key): return false
	if w.version != 1 or not w.cells is Array or w.cells.is_empty() or w.cells.size() > 400: return false
	if w.has("user_paused") and not w.user_paused is bool: return false
	if not w.name is String or w.name.length() > 32 or not w.rng_state is String or not w.rng_state.is_valid_int(): return false
	for key in ["seed", "tick", "energy", "xp", "weather", "saved_at", "theme"]:
		if not (w[key] is float or w[key] is int) or not is_finite(float(w[key])): return false
	if w.tick < 0 or w.energy < 0 or w.energy > 100 or w.weather < 0 or w.weather > 3: return false
	for key in ["events", "discoveries", "achievements"]:
		if not w[key] is Array: return false
	if w.events.size() > 160: return false
	if w.has("living"):
		if not w.living is Dictionary: return false
		for key in ["next_id", "gifts", "bloom_after"]:
			if not (w.living.get(key) is int or w.living.get(key) is float) or not is_finite(float(w.living[key])) or w.living[key] < 0: return false
		for key in ["observed", "findings"]:
			if not w.living.get(key) is Array: return false
		if w.living.observed.size() > 10000 or w.living.findings.size() > 4: return false
		for key in w.living.findings:
			if not key is String or not LivingStories.FINDINGS.has(key): return false
		for id in w.living.observed:
			if not (id is int or id is float) or not is_finite(float(id)) or id < 0: return false
		if w.living.has("records") and not w.living.records is Dictionary: return false
		if w.living.has("records"):
			if w.living.records.size() > 4: return false
			for key in w.living.records:
				var record = w.living.records[key]
				if not LivingStories.FINDINGS.has(key) or not record is Dictionary or record.get("key") != key or not record.get("subject") is String: return false
	for e in w.events:
		if not e is Dictionary or not e.get("key") is String or not (e.get("tick") is int or e.get("tick") is float): return false
	for s in w.discoveries:
		if not (s is float or s is int) or s < 0 or s > 5: return false
	if not w.creatures is Array or w.creatures.size() > 100 or not w.settlements is Array or w.settlements.size() > 10: return false
	for c in w.cells:
		if not c is Dictionary: return false
		for key in ["x", "y", "biome", "height", "moisture", "plants", "resources", "temperature", "detail"]:
			if not c.has(key) or not (c[key] is float or c[key] is int) or not is_finite(float(c[key])): return false
		if c.biome < 0 or c.biome > 6: return false
	for cr in w.creatures:
		if not cr is Dictionary: return false
		for key in ["cell", "species", "hunger", "phase"]:
			if not cr.has(key) or not (cr[key] is float or cr[key] is int) or not is_finite(float(cr[key])): return false
		if cr.cell < 0 or cr.cell >= w.cells.size() or cr.species < 0 or cr.species > 5: return false
		if cr.has("identity"):
			if not (cr.identity is int or cr.identity is float) or not is_finite(float(cr.identity)): return false
			if not cr.get("given_name") is String or not LivingStories.TRAITS.has(cr.get("trait")): return false
			if not (cr.get("visits") is int or cr.get("visits") is float): return false
	for s in w.settlements:
		if not s is Dictionary: return false
		for key in ["cell", "population", "food", "stage", "tech", "blessing"]:
			if not s.has(key) or not (s[key] is float or s[key] is int) or not is_finite(float(s[key])): return false
		if s.cell < 0 or s.cell >= w.cells.size() or s.stage < 0 or s.stage > 2: return false
		if s.has("given_name") and (not s.given_name is String or not s.get("custom") in ["orchard", "riverfolk", "stargazers"] or not (s.get("visitors") is int or s.get("visitors") is float)): return false
	return true

static func normalize_integer_fields(w: Dictionary) -> Dictionary:
	for key in ["version", "seed", "tick", "xp", "weather", "theme"]: w[key] = int(w[key])
	for cr in w.creatures:
		cr.cell = int(cr.cell)
		cr.species = int(cr.species)
		for key in ["identity", "visits"]:
			if cr.has(key): cr[key] = int(cr[key])
	for s in w.settlements:
		for key in ["cell", "stage", "blessing"]: s[key] = int(s[key])
		for key in ["visitors", "friend_id"]:
			if s.has(key): s[key] = int(s[key])
	for i in range(w.discoveries.size()): w.discoveries[i] = int(w.discoveries[i])
	for e in w.events:
		e.tick = int(e.tick)
		e.amount = int(e.get("amount", 0))
	LivingStories.ensure(w)
	for key in ["next_id", "gifts", "bloom_after"]: w.living[key] = int(w.living[key])
	for i in range(w.living.observed.size()): w.living.observed[i] = int(w.living.observed[i])
	return w

static func read_checked(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var parser = JSON.new()
		var parse_error = parser.parse(FileAccess.get_file_as_string(path))
		var envelope = parser.data if parse_error == OK else null
		if envelope is Dictionary and envelope.get("payload") is String and envelope.get("checksum") == envelope.payload.sha256_text():
			if parser.parse(envelope.payload) == OK and validate(parser.data): return parser.data
	return {}

static func load_world(path: String = PATH, backup: bool = true) -> Dictionary:
	last_recovery = "none"
	var primary = read_checked(path)
	if not primary.is_empty(): return normalize_integer_fields(primary)
	if not backup: return {}
	var recovered: Dictionary = {}
	for suffix in [".bak", ".tmp"]:
		var candidate = read_checked(path + suffix)
		if not candidate.is_empty() and (recovered.is_empty() or candidate.saved_at > recovered.saved_at):
			recovered = candidate
			last_recovery = "backup" if suffix == ".bak" else "interrupted_write"
	return normalize_integer_fields(recovered) if not recovered.is_empty() else {}

static func offline(w: Dictionary, now: float) -> Dictionary:
	var job = offline_begin(w, now)
	offline_step(job, 480)
	return offline_finish(job)

static func offline_begin(w: Dictionary, now: float) -> Dictionary:
	LivingStories.ensure(w)
	var chapters_before = w.living.findings.size()
	var creatures_before = w.creatures.size()
	var homes_before = w.settlements.size()
	var people_before = 0.0
	for s in w.settlements: people_before += s.population
	var elapsed = 0.0 if w.get("user_paused", false) else clampf(now - float(w.saved_at), 0, MAX_OFFLINE_SECONDS)
	var count = mini(480, int(elapsed / 60))
	var previous = w.events.duplicate(true)
	var rng = RandomNumberGenerator.new()
	rng.state = int(w.rng_state)
	return {"world": w, "now": now, "count": count, "done": 0, "elapsed": elapsed, "previous": previous, "rng": rng, "chapters_before": chapters_before, "creatures_before": creatures_before, "homes_before": homes_before, "people_before": people_before}

static func offline_step(job: Dictionary, budget: int = 12) -> bool:
	for i in range(mini(maxi(0, budget), int(job.count) - int(job.done))):
		Ecosystem.tick(job.world, job.rng)
		Civilization.tick(job.world)
		job.done += 1
	return job.done == job.count

static func offline_finish(job: Dictionary) -> Dictionary:
	assert(job.done == job.count, "Offline replay must finish before committing")
	var w: Dictionary = job.world
	w.rng_state = str(job.rng.state)
	w.saved_at = job.now
	var changes: Array = []
	for e in w.events:
		if not job.previous.has(e): changes.append(e)
	var people_after = 0.0
	for s in w.settlements: people_after += s.population
	return {"minutes": int(job.elapsed / 60), "ticks": job.count, "events": changes, "new_chapters": w.living.findings.size() - job.chapters_before, "creature_change": w.creatures.size() - job.creatures_before, "people_change": int(people_after) - int(job.people_before), "new_settlements": w.settlements.size() - job.homes_before}
