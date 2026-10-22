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

static func discover(w: Dictionary, key: String, cell: int, subject: String = "") -> void:
	if w.living.findings.has(key): return
	w.living.findings.append(key)
	w.xp += 12
	w.energy = minf(100, w.energy + 8)
	Ecosystem.event(w, key)
	w.events.back().cell = cell
	w.events.back().subject = subject
	w.living.records[key] = w.events.back().duplicate(true)

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

static func objective(w: Dictionary) -> String:
	ensure(w)
	if int(w.living.gifts) == 0: return "guide_rain"
	if w.living.observed.is_empty(): return "guide_creature"
	if not w.living.findings.has("rain_bloom"): return "guide_bloom"
	if not w.living.findings.has("friendship"): return "guide_friend"
	if not w.living.findings.has("first_village"): return "guide_village"
	if not w.living.findings.has("lantern_grove"): return "guide_grove"
	return "guide_world"
