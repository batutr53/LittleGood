class_name LivingStories
extends RefCounted

# Optional version-one save extension. No wall-clock rewards or absence penalties.
const NAMES = ["Pip", "Clover", "Juniper", "Miso", "Fern", "Wisp", "Pebble", "Tansy", "Nori", "Bramble", "Luma", "Sorrel"]
const TRAITS = ["gardener", "friendly", "explorer", "patient"]
const HOMES = ["Willow", "Sunstone", "Moonreed", "Clover", "Amber", "Mist"]
const FINDINGS = ["rain_bloom", "friendship", "lantern_grove", "first_village"]

static func ensure(w: Dictionary) -> void:
	if not w.has("living"):
		w.living = {"next_id": 0, "observed": [], "findings": [], "gifts": 0, "bloom_after": 0}
	if not w.living.has("records"): w.living.records = {}
	for cr in w.creatures:
		if cr.has("identity"): continue
		var id = int(w.living.next_id)
		w.living.next_id = id + 1
		cr.identity = id
		cr.given_name = NAMES[posmod(int(w.seed) + id * 7, NAMES.size())] + " " + str(id / 12 + 1)
		cr.trait = TRAITS[posmod(int(w.seed) + id, TRAITS.size())]
		cr.visits = 0
	for i in range(w.settlements.size()):
		var s = w.settlements[i]
		if not s.has("given_name"):
			s.given_name = HOMES[posmod(int(w.seed) + i * 5, HOMES.size())] + " Haven"
			s.visitors = 0
		if not s.has("custom"):
			s.custom = ["orchard", "riverfolk", "stargazers"][posmod(int(w.seed) + i, 3)]
	ensure_memories(w)

static func discover(w: Dictionary, key: String, cell: int, subject: String = "") -> void:
	if w.living.findings.has(key): return
	w.living.findings.append(key)
	w.xp += 12
	w.energy = minf(100, w.energy + 8)
	Ecosystem.event(w, key)
	w.events.back().cell = cell
	w.events.back().subject = subject
	w.living.records[key] = w.events.back().duplicate(true)
	remember(w, key, key, cell, subject)

static func observe(w: Dictionary, cr: Dictionary) -> bool:
	ensure(w)
	if w.living.observed.has(int(cr.identity)): return false
	w.living.observed.append(int(cr.identity))
	w.xp += 2
	if not w.discoveries.has(int(cr.species)):
		w.discoveries.append(int(cr.species))
		w.xp += 8
		Ecosystem.event(w, "discovery", int(cr.species))
	return true

static func tick(w: Dictionary) -> void:
	ensure(w)
	# A wet, established patch of desert becomes a permanent meadow after rain.
	if w.weather == 1 and int(w.tick) >= int(w.living.bloom_after):
		for i in range(w.cells.size()):
			var c = w.cells[i]
			if c.biome == 2 and c.moisture >= .55 and c.plants >= .45:
				c.biome = 0
				c.plants = 1.0
				c.bloom_until = int(w.tick) + 40
				c.meadow = true
				w.living.bloom_after = int(w.tick) + 90
				discover(w, "rain_bloom", i)
				break
	for cr in w.creatures:
		var c = w.cells[int(cr.cell)]
		if cr.trait == "gardener" and c.biome != 6: c.plants = minf(1, c.plants + .012)
		if cr.trait == "patient": cr.hunger = maxf(0, cr.hunger - .009)
		if cr.trait == "friendly":
			for s in w.settlements:
				var home = w.cells[int(s.cell)]
				if absf(home.x - c.x) + absf(home.y - c.y) <= 2:
					cr.visits = int(cr.visits) + 1
					s.food = minf(100, s.food + .18)
					s.visitors = int(s.visitors) + 1
					if cr.visits >= 4:
						s.friend_id = int(cr.identity)
						discover(w, "friendship", int(s.cell), cr.given_name + " · " + s.given_name)
		# A well-fed fox and lush forest make a rare, living lantern grove.
		if cr.species == 1 and c.biome == 1 and c.plants > .85 and cr.hunger < .25 and int(w.tick) % 90 == 45:
			c.grove_until = int(w.tick) + 35
			c.resources = minf(100, c.resources + 12)
			discover(w, "lantern_grove", int(cr.cell), cr.given_name)
	for s in w.settlements:
		var home = w.cells[int(s.cell)]
		match s.custom:
			"orchard": home.plants = minf(1, home.plants + .006)
			"riverfolk":
				if w.weather == 1: s.food = minf(100, s.food + .12)
			"stargazers":
				if w.weather == 0: s.tech += .003
		if s.stage >= 1: discover(w, "first_village", int(s.cell), s.given_name)
	living_tick(w)

static func objective(w: Dictionary) -> String:
	ensure(w)
	if int(w.living.gifts) == 0: return "guide_rain"
	if w.living.observed.is_empty(): return "guide_creature"
	if not w.living.findings.has("rain_bloom"): return "guide_bloom"
	if not w.living.findings.has("friendship"): return "guide_friend"
	if not w.living.findings.has("first_village"): return "guide_village"
	if not w.living.findings.has("lantern_grove"): return "guide_grove"
	return "guide_world"

# Small, bounded extensions of the existing version-one world. Historical dates on
# migrated creatures mean "first recorded", never an invented birth date.
const SECRETS = ["mountain_spring", "silver_fox", "rainbow_choir"]
const MEMORY_KEYS = ["rain_bloom", "friendship", "lantern_grove", "first_village", "first_birth", "companions", "rivalry", "explored", "landmark", "alliance", "mountain_spring", "silver_fox", "rainbow_choir", "elder", "rescue"]

static func ensure_memories(w: Dictionary) -> void:
	for entry in [["memories", []], ["remembered", []], ["secrets", []], ["favorites", []]]:
		if not w.living.has(entry[0]): w.living[entry[0]] = entry[1].duplicate(true)
	for cr in w.creatures:
		if cr.has("recorded_at"): continue
		cr.recorded_at = int(w.tick)
		cr.preferred = int(cr.species)
		cr.trail = [int(cr.cell)]
		cr.habitat_ticks = 0
		cr.companion = -1
		cr.rival = -1
		cr.bond_ticks = 0
		if cr.get("born_here", false):
			remember(w, "first_birth", "first_birth", int(cr.cell), cr.given_name, int(cr.identity), int(cr.species))
	for s in w.settlements:
		if not s.has("recorded_at"):
			s.recorded_at = int(w.tick)
			s.allies = []
			s.landmark = false
			s.dry_ticks = 0
			s.helped = false
	# Backfill only documented original discoveries, retaining their original tick.
	for key in w.living.records:
		if w.living.remembered.has(key): continue
		var e = w.living.records[key]
		remember(w, key, key, int(e.get("cell", 0)), str(e.get("subject", "")))
		w.living.memories.back().tick = int(e.get("tick", w.tick))

static func remember(w: Dictionary, id: String, key: String, cell: int, subject: String = "", identity: int = -1, species: int = -1) -> bool:
	if w.living.remembered.has(id): return false
	if w.living.remembered.size() >= 128:
		# Keep permanent firsts; rotate older individual episodes, bounded in size.
		for old in w.living.remembered:
			if str(old).contains(":"):
				w.living.remembered.erase(old)
				break
		if w.living.remembered.size() >= 128: return false
	w.living.remembered.append(id)
	var c = w.cells[cell]
	w.living.memories.append({"id": id, "key": key, "tick": int(w.tick), "cell": cell, "subject": subject, "identity": identity, "species": species, "biome": int(c.biome), "plants": snappedf(c.plants, .01)})
	if w.living.memories.size() > 64:
		var oldest_episode = 0
		for i in range(w.living.memories.size()):
			if w.living.memories[i].key in ["explored", "elder", "companions", "rivalry"]:
				oldest_episode = i
				break
		w.living.memories.remove_at(oldest_episode)
	# Existing chapters already emit their own real-state event.
	if not FINDINGS.has(key):
		Ecosystem.event(w, key)
		w.events.back().cell = cell
		w.events.back().subject = subject
	return true

static func secret(w: Dictionary, key: String, cell: int, subject: String = "") -> void:
	if w.living.secrets.has(key): return
	w.living.secrets.append(key)
	remember(w, key, key, cell, subject)

static func living_tick(w: Dictionary) -> void:
	var occupants: Dictionary = {}
	for cr in w.creatures:
		var c = w.cells[int(cr.cell)]
		if not cr.trail.has(int(cr.cell)) and cr.trail.size() < 32: cr.trail.append(int(cr.cell))
		if cr.trail.size() >= 8 and not cr.get("trail_recorded", false):
			cr.trail_recorded = true
			remember(w, "explored:" + str(cr.identity), "explored", int(cr.cell), cr.given_name, int(cr.identity), int(cr.species))
		if int(w.tick) - int(cr.recorded_at) >= 450 and not cr.get("elder_recorded", false):
			cr.elder_recorded = true
			remember(w, "elder:" + str(cr.identity), "elder", int(cr.cell), cr.given_name, int(cr.identity), int(cr.species))
		if c.biome == cr.preferred and cr.hunger < .25: cr.habitat_ticks = int(cr.habitat_ticks) + 1
		if cr.species == 1 and cr.trait == "patient" and int(cr.habitat_ticks) >= 360 and c.get("grove_until", 0) > int(w.tick):
			cr.silver = true
			c.plants = minf(1, c.plants + .015)
			secret(w, "silver_fox", int(cr.cell), cr.given_name)
		var other: Dictionary = occupants.get(int(cr.cell), {})
		if not other.is_empty():
			if cr.species == other.species and cr.hunger < .6 and other.hunger < .6:
				# Consecutive meetings with the same neighbor, not unrelated crowd visits.
				if int(cr.get("meeting_id", -1)) != int(other.identity): cr.bond_ticks = 0
				cr.meeting_id = int(other.identity)
				cr.bond_ticks = int(cr.bond_ticks) + 1
				if cr.bond_ticks >= 6:
					var new_bond = int(cr.companion) != int(other.identity)
					cr.companion = int(other.identity)
					other.companion = int(cr.identity)
					cr.hunger = maxf(0, cr.hunger - .015)
					other.hunger = maxf(0, other.hunger - .015)
					if new_bond: remember(w, "companions:%d:%d" % [mini(cr.identity,other.identity), maxi(cr.identity,other.identity)], "companions", int(cr.cell), cr.given_name + " · " + other.given_name, int(cr.identity), int(cr.species))
			elif (cr.species == 1 and other.species == 0) or (cr.species == 0 and other.species == 1):
				var prey = cr if cr.species == 0 else other
				var fox = other if cr.species == 0 else cr
				if prey.hunger > .7:
					var new_rival = int(prey.rival) != int(fox.identity)
					prey.rival = int(fox.identity)
					if new_rival: remember(w, "rivalry:%d:%d" % [int(prey.identity),int(fox.identity)], "rivalry", int(prey.cell), prey.given_name + " · " + fox.given_name, int(prey.identity), 0)
		else: cr.bond_ticks = 0
		occupants[int(cr.cell)] = cr
	# A raised mountain beside a forest catches water: a permanent spring that
	# moistens only adjacent land. Spatial indexing keeps this linear in map size.
	var positions: Dictionary = {}
	for i in range(w.cells.size()):
		var c = w.cells[i]
		if c.biome != 3 or c.get("last_gift", -1) != 2: continue
		# Untouched worlds need no extra spatial dictionary at all.
		if positions.is_empty():
			for j in range(w.cells.size()): positions[Vector2i(w.cells[j].x, w.cells[j].y)] = j
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var near = int(positions.get(Vector2i(c.x, c.y) + direction, -1))
			if near < 0: continue
			var forest = w.cells[near]
			if forest.biome == 1 and forest.moisture >= .6 and forest.plants >= .7:
				c.spring = true
				forest.moisture = minf(1, forest.moisture + .015)
				secret(w, "mountain_spring", i)
	var previous_weather = int(w.living.get("previous_weather", w.weather))
	if previous_weather == 1 and w.weather == 0:
		for cr in w.creatures:
			if cr.species == 5 and w.cells[int(cr.cell)].moisture > .8 and int(w.tick) >= 60:
				w.cells[int(cr.cell)].plants = minf(1, w.cells[int(cr.cell)].plants + .12)
				w.living.choir_until = int(w.tick) + 12
				secret(w, "rainbow_choir", int(cr.cell), cr.given_name)
				break
	w.living.previous_weather = int(w.weather)
	for s in w.settlements:
		var c = w.cells[int(s.cell)]
		if c.moisture < .2: s.dry_ticks = int(s.dry_ticks) + 1
		if int(s.dry_ticks) >= 12 and c.moisture > .6 and not s.helped:
			s.helped = true
			s.food = minf(100, s.food + 8)
			remember(w, "rescue:" + str(s.cell), "rescue", int(s.cell), s.given_name)
		if s.stage >= 1 and s.food >= 30 and s.tech >= 1 and not s.landmark:
			s.landmark = true
			remember(w, "landmark:" + str(s.cell), "landmark", int(s.cell), s.given_name)
		if s.landmark and int(w.tick) % 30 == 0:
			if s.custom == "orchard": s.food = minf(100, s.food + 2)
			elif s.custom == "riverfolk": c.moisture = minf(1, c.moisture + .03)
			else: s.tech = minf(100, s.tech + .05)
		for other in w.settlements:
			if int(other.cell) <= int(s.cell) or s.allies.has(int(other.cell)): continue
			var b = w.cells[int(other.cell)]
			if absf(c.x - b.x) + absf(c.y - b.y) <= 9 and s.food > 25 and other.food > 25 and s.stage >= 1 and other.stage >= 1:
				s.allies.append(int(other.cell))
				other.allies.append(int(s.cell))
				remember(w, "alliance:" + str(s.cell) + ":" + str(other.cell), "alliance", int(s.cell), s.given_name + " · " + other.given_name)
		if not s.allies.is_empty(): s.tech = minf(100, s.tech + .002)

static func rename_subject(subject: Dictionary, value: String) -> bool:
	var clean = value.strip_edges().replace("\n", " ").replace("\r", " ").replace("\t", " ")
	if clean.is_empty() or clean.length() > 24: return false
	subject.given_name = clean
	return true

static func favorite(w: Dictionary, cell: int) -> bool:
	if cell < 0 or cell >= w.cells.size(): return false
	if w.living.favorites.has(cell): w.living.favorites.erase(cell); return true
	if w.living.favorites.size() >= 5: return false
	w.living.favorites.append(cell)
	return true
