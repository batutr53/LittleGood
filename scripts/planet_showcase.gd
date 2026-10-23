extends RefCounted

# Public, inert data only. Never deserialize a save or a Godot resource from a visit.
const FORMAT = "littlegod.showcase"
const MAX_BYTES = 524288
const MAX_VISITS = 8
const CELL_FIELDS = ["x", "y", "biome", "height", "moisture", "plants", "resources", "temperature", "detail", "meadow", "spring", "grove_until", "last_gift", "canopy_arch", "reed_shelter"]
const CREATURE_FIELDS = ["id", "name", "species", "cell", "trait", "hunger", "phase", "recorded_at", "preferred", "trail", "companion", "rival", "silver", "parent", "parent_name", "lineage", "origin_cell", "migrant"]
const HOME_FIELDS = ["cell", "name", "custom", "population", "food", "stage", "tech", "landmark", "allies", "rival_cell", "trade_until"]
const MEMORY_FIELDS = ["key", "tick", "cell", "subject", "species", "biome", "plants", "identity"]
var directory = "user://showcases"

static func shape(value: Variant, keys: Array) -> bool:
	if not value is Dictionary or value.size() != keys.size(): return false
	for key in keys:
		if not value.has(key): return false
	return true

static func number(value: Variant, low: float, high: float, integer: bool = false) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high and (not integer or float(value) == floorf(value))

static func safe_text(value: Variant, limit: int) -> bool:
	if not value is String or value.length() > limit: return false
	# No paths, URLs, control characters, markup or script-bearing resource references.
	for i in range(value.length()):
		var ch = value.unicode_at(i)
		if ch < 32 or (ch >= 127 and ch <= 159) or value[i] in ["/", "\\", ":", "<", ">", "[", "]", "{", "}"]: return false
	return true

static func public_text(value: String, limit: int, fallback: String) -> String:
	return value if safe_text(value, limit) and not value.strip_edges().is_empty() else fallback

static func index_list(value: Variant, limit: int, highest: int) -> bool:
	if not value is Array or value.size() > limit: return false
	var seen: Dictionary = {}
	for item in value:
		if not number(item, 0, highest, true) or seen.has(int(item)): return false
		seen[int(item)] = true
	return true

static func validate(data: Variant) -> bool:
	if data is Dictionary and number(data.get("version"),2,2,true):
		if not shape(data,["format","version","planet","cells","creatures","settlements","memories","discoveries","secrets","findings","appearance"]):return false
		var legacy=data.duplicate();legacy.erase("appearance");legacy.version=1
		if not validate(legacy):return false
		return preload("res://scripts/cosmetics.gd").public_valid(data.appearance,data.cells.size(),data.creatures.size())
	if not shape(data, ["format", "version", "planet", "cells", "creatures", "settlements", "memories", "discoveries", "secrets", "findings"]): return false
	if data.format != FORMAT or not number(data.version, 1, 1, true): return false
	var p = data.planet
	if not shape(p, ["name", "tick", "weather", "theme", "xp"]) or not safe_text(p.name, 32) or p.name.strip_edges().is_empty(): return false
	if not number(p.tick, 0, 1000000000, true) or not number(p.weather, 0, 3, true) or not number(p.theme, 0, 1, true) or not number(p.xp, 0, 1000000000, true): return false
	if not data.cells is Array or data.cells.is_empty() or data.cells.size() > 400: return false
	var positions: Dictionary = {}
	var place_counts = {"canopy_arch":0, "reed_shelter":0}
	for c in data.cells:
		if not shape(c, CELL_FIELDS): return false
		if not number(c.x,-32,32,true) or not number(c.y,-32,32,true) or not number(c.biome,0,6,true): return false
		var pos = Vector2i(c.x,c.y)
		if positions.has(pos): return false
		positions[pos] = true
		if not number(c.height,-1,2) or not number(c.moisture,0,1) or not number(c.plants,0,1) or not number(c.resources,0,100) or not number(c.temperature,-100,100) or not number(c.detail,0,1): return false
		if not c.meadow is bool or not c.spring is bool or not number(c.grove_until,0,p.tick+120,true) or not number(c.last_gift,-1,2,true): return false
		if not c.canopy_arch is bool or not c.reed_shelter is bool: return false
		for kind in place_counts:
			if c[kind]: place_counts[kind] += 1
			if place_counts[kind] > 1: return false
	var last = data.cells.size()-1
	if not data.creatures is Array or data.creatures.size() > 100: return false
	for i in range(data.creatures.size()):
		var cr = data.creatures[i]
		if not shape(cr, CREATURE_FIELDS) or not number(cr.id,i,i,true) or not safe_text(cr.name,24) or cr.name.strip_edges().is_empty(): return false
		if not number(cr.species,0,5,true) or not number(cr.cell,0,last,true) or not cr.trait in LivingStories.TRAITS: return false
		if not number(cr.hunger,0,1) or not number(cr.phase,0,TAU+.001) or not number(cr.recorded_at,0,p.tick,true) or not number(cr.preferred,0,5,true): return false
		if not index_list(cr.trail,32,last) or not cr.silver is bool: return false
		if not safe_text(cr.parent_name,24) or not number(cr.lineage,0,99,true) or not number(cr.origin_cell,0,last,true) or not cr.migrant is bool: return false
		for key in ["companion", "rival", "parent"]:
			if not number(cr[key],-1,data.creatures.size()-1,true) or int(cr[key]) == i: return false
	if not data.settlements is Array or data.settlements.size() > 10: return false
	var homes: Dictionary = {}
	for s in data.settlements:
		if not shape(s, HOME_FIELDS) or not number(s.cell,0,last,true) or homes.has(int(s.cell)): return false
		homes[int(s.cell)] = true
		if not safe_text(s.name,24) or s.name.strip_edges().is_empty() or not s.custom in ["orchard", "riverfolk", "stargazers"]: return false
		if not number(s.population,0,80) or not number(s.food,0,100) or not number(s.stage,0,2,true) or not number(s.tech,0,1000000000) or not s.landmark is bool: return false
		if not index_list(s.allies,10,last): return false
		if not number(s.rival_cell,-1,last,true) or not number(s.trade_until,0,p.tick+30,true): return false
	for s in data.settlements:
		for ally in s.allies:
			if not homes.has(int(ally)) or int(ally) == int(s.cell): return false
		if int(s.rival_cell)>=0 and (not homes.has(int(s.rival_cell)) or int(s.rival_cell)==int(s.cell)): return false
	if not data.memories is Array or data.memories.size() > 64: return false
	for m in data.memories:
		if not shape(m, MEMORY_FIELDS) or not m.key in LivingStories.MEMORY_KEYS or not safe_text(m.subject,192): return false
		if not number(m.tick,0,p.tick,true) or not number(m.cell,0,last,true) or not number(m.species,-1,5,true) or not number(m.biome,0,6,true) or not number(m.plants,0,1) or not number(m.identity,-1,data.creatures.size()-1,true): return false
	if not index_list(data.discoveries,6,5): return false
	for entry in [["secrets", LivingStories.SECRETS], ["findings", LivingStories.FINDINGS]]:
		var list = data[entry[0]]
		if not list is Array or list.size() > entry[1].size(): return false
		var seen: Dictionary = {}
		for key in list:
			if not key is String or not entry[1].has(key) or seen.has(key): return false
			seen[key] = true
	return true

static func parse(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES: return {}
	# Bound nesting BEFORE asking the JSON parser to allocate recursive structures.
	var depth = 0
	var quoted = false
	var escaped = false
	for i in range(text.length()):
		var ch = text[i]
		if quoted:
			if escaped: escaped = false
			elif ch == "\\": escaped = true
			elif ch == '"': quoted = false
		elif ch == '"': quoted = true
		elif ch in ["[", "{"]:
			depth += 1
			if depth > 12: return {}
		elif ch in ["]", "}"]:
			depth -= 1
			if depth < 0: return {}
	if quoted or depth != 0: return {}
	var parser = JSON.new()
	if parser.parse(text) != OK or not validate(parser.data): return {}
	return parser.data

static func read_file(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null or f.get_length() > MAX_BYTES: return {}
	var bytes = f.get_buffer(MAX_BYTES+1)
	if bytes.size()>MAX_BYTES: return {}
	return parse(bytes.get_string_from_utf8())

static func project(w: Dictionary) -> Dictionary:
	var data = {"format":FORMAT, "version":1, "planet":{"name":public_text(w.name,32,"Little planet"), "tick":int(w.tick), "weather":int(w.weather), "theme":int(w.theme), "xp":int(w.xp)}, "cells":[], "creatures":[], "settlements":[], "memories":[], "discoveries":w.discoveries.duplicate(), "secrets":w.living.secrets.duplicate(), "findings":w.living.findings.duplicate()}
	var ids: Dictionary = {}
	var families: Dictionary = {}
	for i in range(w.creatures.size()): ids[int(w.creatures[i].identity)] = i
	for c in w.cells:
		var tile: Dictionary = {}
		for key in CELL_FIELDS: tile[key] = c.get(key, false if key in ["meadow","spring","canopy_arch","reed_shelter"] else -1 if key == "last_gift" else 0)
		data.cells.append(tile)
	for i in range(w.creatures.size()):
		var cr = w.creatures[i]
		var family = int(cr.lineage)
		if not families.has(family): families[family] = families.size()
		data.creatures.append({"id":i, "name":public_text(cr.given_name,24,"Neighbor"), "species":int(cr.species), "cell":int(cr.cell), "trait":cr.trait, "hunger":cr.hunger, "phase":cr.phase, "recorded_at":int(cr.recorded_at), "preferred":int(cr.preferred), "trail":cr.trail.duplicate(), "companion":ids.get(int(cr.companion),-1), "rival":ids.get(int(cr.rival),-1), "silver":cr.get("silver",false), "parent":ids.get(int(cr.get("parent_id",-1)),-1), "parent_name":public_text(cr.parent_name,24,""),"origin_cell":int(cr.origin_cell),"lineage":families[family],"migrant":cr.get("migrant",false)})
	for s in w.settlements:
		data.settlements.append({"cell":int(s.cell), "name":public_text(s.given_name,24,"Community"), "custom":s.custom, "population":s.population, "food":s.food, "stage":int(s.stage), "tech":s.tech, "landmark":s.landmark, "allies":s.allies.duplicate(), "rival_cell":int(s.rival_cell),"trade_until":int(s.trade_until)})
	for m in w.living.memories:
		var memory: Dictionary = {}
		for key in MEMORY_FIELDS: memory[key] = m[key]
		memory.identity = ids.get(int(m.identity),-1)
		memory.subject = public_text(m.subject,192,"")
		data.memories.append(memory)
	if w.has("wardrobe"):
		var appearance=preload("res://scripts/cosmetics.gd").appearance(w,ids)
		if appearance.theme!="enchanted" or appearance.sky!="" or appearance.frame!="" or not appearance.placements.is_empty() or not appearance.coats.is_empty():data.version=2;data.appearance=appearance
	return data

static func encode(w: Dictionary) -> String:
	var data = project(w)
	return JSON.stringify(data) if validate(data) else ""

static func world_from(data: Dictionary) -> Dictionary:
	if not validate(data): return {}
	var p = data.planet
	var w = {"version":1, "name":p.name, "seed":0, "tick":int(p.tick), "weather":int(p.weather), "theme":int(p.theme), "xp":int(p.xp), "energy":0.0, "rng_state":"1", "saved_at":0.0, "cells":data.cells.duplicate(true), "creatures":[], "settlements":[], "events":[], "discoveries":data.discoveries.duplicate(), "achievements":[]}
	for cr in data.creatures:
		w.creatures.append({"identity":int(cr.id), "given_name":cr.name, "species":int(cr.species), "cell":int(cr.cell), "trait":cr.trait, "hunger":cr.hunger, "phase":cr.phase, "visits":0})
	for s in data.settlements:
		w.settlements.append({"cell":int(s.cell), "given_name":s.name, "custom":s.custom, "population":s.population, "food":s.food, "stage":int(s.stage), "tech":s.tech, "blessing":0, "visitors":0})
	LivingStories.ensure(w)
	w.living.findings = data.findings.duplicate()
	w.living.secrets = data.secrets.duplicate()
	w.living.next_id = w.creatures.size()
	# ensure() seeds legacy milestones; the public record is authoritative here.
	w.living.memories.clear()
	w.living.remembered.clear()
	w.living.records.clear()
	for i in range(data.creatures.size()):
		var source = data.creatures[i]
		var cr = w.creatures[i]
		for key in ["recorded_at", "preferred", "trail", "companion", "rival", "silver", "parent_name", "origin_cell", "lineage", "migrant"]: cr[key] = source[key].duplicate() if source[key] is Array else source[key]
		cr.parent_id = int(source.parent)
	for i in range(data.settlements.size()):
		w.settlements[i].landmark = data.settlements[i].landmark
		w.settlements[i].allies = data.settlements[i].allies.duplicate()
		w.settlements[i].rival_cell = int(data.settlements[i].rival_cell)
		w.settlements[i].trade_until = int(data.settlements[i].trade_until)
	for i in range(data.memories.size()):
		var m = data.memories[i].duplicate(true)
		m.id = "showcase:" + str(i)
		w.living.memories.append(m)
		w.living.remembered.append(m.id)
		if m.key in LivingStories.FINDINGS:
			w.living.records[m.key] = m.duplicate(true)
			w.living.remembered.append(m.key)
	w = Persistence.normalize_integer_fields(w)
	if data.get("version")==2:w.wardrobe=preload("res://scripts/cosmetics.gd").from_appearance(data.appearance)
	for i in range(w.cells.size()):
		for kind in ["canopy_arch","reed_shelter"]:
			if w.cells[i][kind]:
				var records = w.living.memories.filter(func(m): return m.key==kind and int(m.cell)==i)
				w.living.places.append({"kind":kind,"cell":i,"tick":int(records[0].tick) if not records.is_empty() else 0})
	w._read_only = true
	for cr in w.creatures: cr._read_only = true
	for s in w.settlements: s._read_only = true
	return w

func import_text(text: String) -> String:
	var data = parse(text)
	if data.is_empty(): return ""
	var canonical = JSON.stringify(data)
	var id = canonical.sha256_text()
	var existing = entries()
	if existing.size() >= MAX_VISITS and not existing.has(id): return ""
	DirAccess.make_dir_recursive_absolute(directory)
	var path = directory.path_join(id + ".lgplanet")
	var f = FileAccess.open(path+".tmp", FileAccess.WRITE)
	if f == null: return ""
	f.store_string(canonical)
	f.flush()
	var error = f.get_error()
	f.close()
	if error != OK or read_file(path+".tmp").is_empty() or DirAccess.rename_absolute(path+".tmp",path)!=OK: return ""
	return id

func entries() -> Array:
	var result: Array = []
	var dir = DirAccess.open(directory)
	if dir == null: return result
	for file in dir.get_files():
		var id = file.get_basename()
		if file.ends_with(".lgplanet") and valid_id(id) and result.size() < MAX_VISITS and not read_file(directory.path_join(file)).is_empty(): result.append(id)
	result.sort()
	return result

static func valid_id(id: String) -> bool:
	if id.length() != 64: return false
	for ch in id:
		if not ch in "0123456789abcdef": return false
	return true

func get_planet(id: String) -> Dictionary:
	return read_file(directory.path_join(id + ".lgplanet")) if valid_id(id) else {}

func remove(id: String) -> bool:
	if not valid_id(id): return false
	var path = directory.path_join(id + ".lgplanet")
	if not FileAccess.file_exists(path) or DirAccess.remove_absolute(path) != OK: return false
	if FileAccess.file_exists(directory.path_join(id+".reaction")): DirAccess.remove_absolute(directory.path_join(id+".reaction"))
	return true

func react(id: String, value: int) -> bool:
	if not valid_id(id) or value < 0 or value > 3 or get_planet(id).is_empty(): return false
	var f = FileAccess.open(directory.path_join(id + ".reaction"), FileAccess.WRITE)
	if f == null: return false
	f.store_string(str(value))
	return true

func reaction(id: String) -> int:
	if not valid_id(id): return 0
	var path = directory.path_join(id + ".reaction")
	var f = FileAccess.open(path,FileAccess.READ)
	return clampi(int(f.get_as_text()),0,3) if f != null and f.get_length() <= 2 else 0
