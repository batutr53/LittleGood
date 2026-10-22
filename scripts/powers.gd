class_name Powers
extends RefCounted

const COSTS = [12, 15, 18, 20, 22, 25]
static func apply(w: Dictionary, power: int, cell: int) -> bool:
	if power < 0 or power >= 6 or cell < 0 or cell >= w.cells.size() or w.energy < COSTS[power]: return false
	var c = w.cells[cell]
	if power == 5:
		var found = false
		for s in w.settlements:
			if s.cell == cell:
				s.blessing = 120
				s.food = minf(100, s.food + 25)
				found = true
		if not found: return false
	w.energy -= COSTS[power]
	w.xp += 3
	match power:
		0:
			c.biome = 6
			c.moisture = 1.0
		1:
			c.biome = 1
			c.plants = 1.0
			c.moisture = maxf(0.65, c.moisture)
		2:
			c.biome = 3
			c.height = minf(1.2, c.height + 0.4)
		3:
			if w.creatures.size() < 70:
				w.creatures.append({"species": mini(int(c.biome), 5), "cell": cell, "hunger": 0.1, "phase": 0.0})
		4:
			w.weather = 1
			for tile in w.cells: tile.moisture = minf(1, tile.moisture + 0.2)
			Ecosystem.event(w, "rain")
	Ecosystem.event(w, "power", power)
	return true
