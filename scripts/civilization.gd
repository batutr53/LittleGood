class_name Civilization
extends RefCounted

static func tick(w: Dictionary) -> void:
	LivingStories.ensure(w)
	for s in w.settlements:
		var c = w.cells[int(s.cell)]
		var harvest = minf(c.resources, 0.35 + c.plants * 0.6)
		c.resources -= harvest
		s.food = clampf(s.food + harvest - s.population * 0.009, 0, 100)
		s.population = clampf(s.population + (0.08 if s.food > 5 else -0.025) + (0.05 if s.blessing > 0 else 0.0), 3, 80)
		s.blessing = maxi(0, int(s.blessing) - 1)
		s.tech += 0.015 * c.plants
		var stage = 2 if s.population >= 28 else 1 if s.population >= 12 else 0
		if stage != int(s.stage):
			s.stage = stage
			w.xp += 20
			Ecosystem.event(w, "settlement", stage)
			if stage >= 1: LivingStories.discover(w, "first_village", int(s.cell), s.given_name)
		c.plants = maxf(0.15, c.plants - s.population * 0.00008)
	# Neighboring communities share surplus food.
	if w.settlements.size() > 1:
		var average = 0.0
		for s in w.settlements: average += s.food / w.settlements.size()
		for s in w.settlements: s.food = lerpf(s.food, average, 0.02)
	if int(w.tick) % 240 == 0 and w.settlements.size() < 4:
		for i in range(w.cells.size()):
			var c = w.cells[i]
			if c.biome != 0 or c.plants < 0.6: continue
			var suitable = true
			for s in w.settlements:
				var sc = w.cells[int(s.cell)]
				if Vector2(c.x - sc.x, c.y - sc.y).length() < 4: suitable = false
			if suitable:
				w.settlements.append({"cell": i, "population": 5.0, "food": 20.0, "stage": 0, "tech": 0.0, "blessing": 0})
				Ecosystem.event(w, "founded")
				LivingStories.ensure(w)
				break
