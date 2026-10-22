class_name WorldGen
extends RefCounted

static func generate(seed_value: int, planet_name: String) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.13
	var cells: Array = []
	for y in range(17):
		for x in range(17):
			var distance = Vector2(x - 8, y - 8).length()
			if distance > 8.0 + noise.get_noise_2d(x * 4, y * 4):
				continue
			var elevation = clampf((8.5 - distance) / 9.0 + noise.get_noise_2d(x, y) * 0.5, 0, 1)
			var moisture = clampf(0.5 + noise.get_noise_2d(x + 70, y + 50), 0.05, 1)
			var b = 0
			if x < 5: b = 2
			elif y < 4: b = 4
			elif x > 11 and y < 10: b = 3
			elif y > 11: b = 5
			elif moisture > 0.48: b = 1
			if absf(x - 8.0 - sin(y * 0.6) * 1.8) < 0.7 and y > 3: b = 6
			cells.append({"x": x, "y": y, "biome": b, "height": elevation, "moisture": moisture, "plants": rng.randf_range(0.3, 0.95), "resources": 15.0, "temperature": 25.0 - y * 2.0, "detail": rng.randf()})
	var world = {"version": 1, "seed": seed_value, "name": planet_name.left(32), "tick": 0, "energy": 100.0, "xp": 0, "weather": 0, "cells": cells, "creatures": [], "settlements": [], "discoveries": [], "achievements": [], "events": [], "saved_at": Time.get_unix_time_from_system(), "rng_state": str(rng.state), "theme": 0}
	for s in range(6):
		for n in range(3):
			for i in range(cells.size()):
				if cells[i].biome == s and rng.randf() < 0.2:
					world.creatures.append({"species": s, "cell": i, "hunger": 0.2, "phase": rng.randf() * TAU})
					break
	for i in range(cells.size()):
		if cells[i].biome == 0 and cells[i].x > 7:
			world.settlements.append({"cell": i, "population": 5.0, "food": 20.0, "stage": 0, "tech": 0.0, "blessing": 0})
			break
	world.rng_state = str(rng.state)
	LivingStories.ensure(world)
	return world
