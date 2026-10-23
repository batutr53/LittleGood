class_name Persistence
extends RefCounted

const PATH = "user://planet.json"
const MAX_OFFLINE_SECONDS = 28800
static var last_recovery = "none"

static func has_save(path: String = PATH) -> bool:
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak") or FileAccess.file_exists(path + ".tmp")

static func save_world(w: Dictionary, path: String = PATH) -> bool:
	if w.get("_read_only",false): return false
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
		for field in ["memories", "remembered", "secrets", "favorites"]:
			if w.living.has(field) and not w.living[field] is Array: return false
		if w.living.get("memories", []).size() > 64 or w.living.get("remembered", []).size() > 128 or w.living.get("secrets", []).size() > 3 or w.living.get("favorites", []).size() > 5: return false
		for key in w.living.get("secrets", []):
			if not key is String or not LivingStories.SECRETS.has(key): return false
		for key in w.living.get("remembered", []):
			if not key is String or key.length() > 80: return false
		for cell in w.living.get("favorites", []):
			if not cell is float and not cell is int: return false
			if not is_finite(float(cell)) or cell < 0 or cell >= w.cells.size(): return false
		for memory in w.living.get("memories", []):
			if not memory is Dictionary: return false
			if not memory.get("id") is String or not memory.get("subject") is String or not LivingStories.MEMORY_KEYS.has(memory.get("key")): return false
			for field in ["tick", "cell", "identity", "species", "biome", "plants"]:
				if not (memory.get(field) is int or memory.get(field) is float) or not is_finite(float(memory[field])): return false
			if memory.cell < 0 or memory.cell >= w.cells.size() or memory.tick < 0 or memory.species < -1 or memory.species > 5 or memory.biome < 0 or memory.biome > 6: return false
		if not preload("res://scripts/world_connections.gd").validate(w): return false
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
		if cr.has("recorded_at"):
			for field in ["recorded_at", "preferred", "habitat_ticks", "companion", "rival", "bond_ticks"]:
				if not (cr.get(field) is int or cr.get(field) is float) or not is_finite(float(cr[field])): return false
			if cr.preferred < 0 or cr.preferred > 5 or not cr.get("trail") is Array or cr.trail.size() > 32: return false
			for cell in cr.trail:
				if not (cell is float or cell is int) or not is_finite(float(cell)) or cell < 0 or cell >= w.cells.size(): return false
		for field in ["lineage","origin_cell"]:
			if cr.has(field) and (not (cr[field] is int or cr[field] is float) or not is_finite(float(cr[field])) or cr[field]<0): return false
		if cr.has("origin_cell") and cr.origin_cell >= w.cells.size(): return false
		if cr.has("parent_name") and (not cr.parent_name is String or cr.parent_name.length()>48): return false
	for s in w.settlements:
		if not s is Dictionary: return false
		for key in ["cell", "population", "food", "stage", "tech", "blessing"]:
			if not s.has(key) or not (s[key] is float or s[key] is int) or not is_finite(float(s[key])): return false
		if s.cell < 0 or s.cell >= w.cells.size() or s.stage < 0 or s.stage > 2: return false
		if s.has("given_name") and (not s.given_name is String or not s.get("custom") in ["orchard", "riverfolk", "stargazers"] or not (s.get("visitors") is int or s.get("visitors") is float)): return false
		if s.has("recorded_at"):
			if not s.get("allies") is Array or s.allies.size() > 10 or not s.get("landmark") is bool or not s.get("helped") is bool: return false
			for field in ["recorded_at", "dry_ticks"]:
				if not (s.get(field) is int or s.get(field) is float) or not is_finite(float(s[field])): return false
			for cell in s.allies:
				if not (cell is int or cell is float) or not is_finite(float(cell)) or cell < 0 or cell >= w.cells.size(): return false
		for field in ["rival_cell","trade_until"]:
			if s.has(field) and (not (s[field] is int or s[field] is float) or not is_finite(float(s[field]))): return false
		if s.has("rival_cell") and (s.rival_cell < -1 or s.rival_cell >= w.cells.size()): return false
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
	for i in range(w.living.favorites.size()): w.living.favorites[i] = int(w.living.favorites[i])
	for cr in w.creatures:
		for key in ["recorded_at", "preferred", "habitat_ticks", "companion", "rival", "bond_ticks", "meeting_id", "parent_id", "lineage", "origin_cell"]:
			if cr.has(key): cr[key] = int(cr[key])
		for i in range(cr.trail.size()): cr.trail[i] = int(cr.trail[i])
	for s in w.settlements:
		for key in ["recorded_at", "dry_ticks", "rival_cell", "trade_until"]: s[key] = int(s[key])
		for i in range(s.allies.size()): s.allies[i] = int(s.allies[i])
	for memory in w.living.memories:
		for key in ["tick", "cell", "identity", "species", "biome"]: memory[key] = int(memory[key])
		memory.plants = snappedf(memory.plants, .01)
	w.living.next_migration = int(w.living.next_migration)
	for record in w.living.favorite_creatures:
		for key in ["id","species","recorded_at"]: record[key] = int(record[key])
	for record in w.living.places:
		for key in ["cell","tick"]: record[key] = int(record[key])
	for record in w.living.trades:
		for key in ["a","b","tick"]: record[key] = int(record[key])
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
	var actual_elapsed = 0.0 if w.get("user_paused", false) else maxf(0, now - float(w.saved_at))
	var elapsed = minf(actual_elapsed, MAX_OFFLINE_SECONDS)
	var count = mini(480, int(elapsed / 60))
	var previous = w.events.duplicate(true)
	var rng = RandomNumberGenerator.new()
	rng.state = int(w.rng_state)
	return {"world": w, "now": now, "count": count, "done": 0, "elapsed": elapsed, "actual_elapsed": actual_elapsed, "previous": previous, "rng": rng, "chapters_before": chapters_before, "creatures_before": creatures_before, "homes_before": homes_before, "people_before": people_before, "memories_before": w.living.remembered.duplicate()}

static func offline_step(job: Dictionary, budget: int = 12) -> bool:
	for i in range(mini(maxi(0, budget), int(job.count) - int(job.done))):
		Ecosystem.tick(job.world, job.rng)
		Civilization.tick(job.world)
		job.done += 1
	return job.done == job.count

static func offline_finish(job: Dictionary) -> Dictionary:
	assert(job.done == job.count, "Offline replay must finish before committing")
	var w: Dictionary = job.world
	if w.get("_read_only",false): return {"minutes":0,"ticks":0,"events":[],"memories":[]}
	w.rng_state = str(job.rng.state)
	w.saved_at = job.now
	var changes: Array = []
	for e in w.events:
		if not job.previous.has(e): changes.append(e)
	var people_after = 0.0
	for s in w.settlements: people_after += s.population
	var memories = w.living.memories.filter(func(e): return not job.memories_before.has(e.id))
	return {"minutes": int(job.actual_elapsed / 60), "ticks": job.count, "events": changes, "memories": memories, "new_chapters": w.living.findings.size() - job.chapters_before, "creature_change": w.creatures.size() - job.creatures_before, "people_change": int(people_after) - int(job.people_before), "new_settlements": w.settlements.size() - job.homes_before}
