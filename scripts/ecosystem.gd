class_name Ecosystem
extends RefCounted

const SPECIES = ["Mossbun", "Lanternfox", "Duneling", "Pebblehorn", "Frostpuff", "Reedwing"]
const SPECIES_TR = ["Yosunpon", "Fener tilkisi", "Kumcuk", "Çakılboynuz", "Karpon", "Sazkanat"]

static func event(w: Dictionary, key: String, amount: int = 0) -> void:
	w.events.append({"tick": w.tick, "key": key, "amount": amount})
	if w.events.size() > 160: w.events.pop_front()

static func tick(w: Dictionary, rng: RandomNumberGenerator) -> void:
	LivingStories.ensure(w)
	w.tick = int(w.tick) + 1
	w.energy = minf(100, w.energy + 0.45)
	if w.tick % 20 == 0:
		w.weather = rng.randi_range(0, 3)
		if w.weather == 1: event(w, "rain")
		if w.weather == 3: event(w, "drought")
	var season = (int(w.tick) / 120) % 4
	for c in w.cells:
		c.moisture = clampf(c.moisture + (0.035 if w.weather == 1 else -0.004 if w.weather == 3 else -0.001), 0.08, 1)
		c.temperature = 24.0 - c.y * 1.8 + sin(season * PI / 2) * 7
		var growth = Biomes.GROWTH[int(c.biome)] * c.moisture * (0.4 if season == 3 else 1.0)
		c.plants = clampf(c.plants + growth - (0.008 if w.weather == 3 else 0.001), 0.08, 1)
		c.resources = minf(100, c.resources + 0.25 + c.plants * 0.5)
	# Four direct neighbor lookups replace a complete cell scan for each animal.
	var cell_index: Dictionary = {}
	for i in range(w.cells.size()): cell_index[Vector2i(w.cells[i].x, w.cells[i].y)] = i
	for cr in w.creatures:
		var c = w.cells[int(cr.cell)]
		cr.hunger = clampf(cr.hunger + 0.025 - c.plants * 0.04, 0, 1)
		c.plants = maxf(0.08, c.plants - 0.003)
		# Foxes control herbivores indirectly by increasing nearby hunger.
		if cr.species == 1:
			for prey in w.creatures:
				if prey.species == 0 and prey.cell == cr.cell: prey.hunger = minf(1, prey.hunger + 0.06)
		if rng.randf() < 0.22:
			var candidates: Array = []
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var i = int(cell_index.get(Vector2i(c.x, c.y) + direction, -1))
				if i < 0: continue
				var other = w.cells[i]
				if other.biome != 6 and (other.biome == cr.species or cr.hunger > .65 or cr.trait == "explorer"):
					candidates.append(i)
			if not candidates.is_empty():
				var safe = candidates.filter(func(i):
					return not w.creatures.any(func(other): return int(other.identity) == int(cr.rival) and int(other.cell) == int(i))) if int(cr.rival) >= 0 else candidates
				if not safe.is_empty(): candidates = safe
				cr.cell = candidates[rng.randi_range(0, candidates.size() - 1)]
				if cr.trait == "friendly":
					for home in w.settlements:
						var h = w.cells[int(home.cell)]
						if absf(h.x - c.x) + absf(h.y - c.y) > 4: continue
						var best = INF
						for i in candidates:
							var distance = absf(h.x - w.cells[i].x) + absf(h.y - w.cells[i].y)
							if distance < best: best = distance; cr.cell = i
		if not w.discoveries.has(cr.species) and int(w.tick) >= int(cr.species) * 15:
			w.discoveries.append(cr.species)
			w.xp += 8
			event(w, "discovery", int(cr.species))
	if w.tick % 45 == 0 and w.creatures.size() < 70 and not w.creatures.is_empty():
		var parent = w.creatures[rng.randi_range(0, w.creatures.size() - 1)]
		if parent.hunger < 0.6:
			w.creatures.append({"species": parent.species, "cell": parent.cell, "hunger": 0.2, "phase": rng.randf() * TAU, "born_here": true, "parent_id": int(parent.identity)})
			event(w, "birth", int(parent.species))
	if w.tick % 60 == 0:
		for i in range(w.creatures.size() - 1, -1, -1):
			if w.creatures[i].hunger > 0.95 and w.creatures.size() > 6:
				w.creatures.remove_at(i)
				event(w, "cycle")
	if w.tick % 150 == 0:
		event(w, "aurora")
		w.xp += 15
	if w.creatures.size() >= 24 and not w.achievements.has("sanctuary"):
		w.achievements.append("sanctuary")
		event(w, "sanctuary")
	if w.tick >= 120 and not w.achievements.has("season"):
		w.achievements.append("season")
		event(w, "season")
	LivingStories.tick(w)
