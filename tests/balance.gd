extends SceneTree

# Reproducible simulation evidence, not human engagement or retention data.
func _initialize() -> void:
	var rows: Array = []
	var failures: Array = []
	var start = Time.get_ticks_msec()
	for seed_value in [2026, 42, 7, 301, 99991]:
		for scenario in ["10m", "1h", "24h_offline", "7d_offline"]:
			for intervene in [false, true]:
				var w = WorldGen.generate(seed_value, "Balance")
				if intervene:
					var home_cell = int(w.settlements[0].cell)
					Powers.apply(w, 5, home_cell)
					w.energy = 100
					Powers.apply(w, 4, home_cell)
					# Deliberate spatial experiment: mountain beside a forest.
					for i in range(w.cells.size()):
						var found = false
						for j in range(w.cells.size()):
							if absf(w.cells[i].x - w.cells[j].x) + absf(w.cells[i].y - w.cells[j].y) != 1: continue
							w.energy = 100; Powers.apply(w, 2, i)
							w.energy = 100; Powers.apply(w, 1, j)
							found = true; break
						if found: break
				var rng = RandomNumberGenerator.new()
				rng.state = int(w.rng_state)
				var cpu_start = Time.get_ticks_usec()
				var peak = 0.0
				var ticks = 300 if scenario == "10m" else 1800 if scenario == "1h" else 480
				if scenario.ends_with("offline"):
					var report = Persistence.offline(w, w.saved_at + (86400 if scenario == "24h_offline" else 604800))
					if report.ticks != ticks: failures.append("offline cap")
				else:
					for i in range(ticks):
						var tick_start = Time.get_ticks_usec()
						Ecosystem.tick(w, rng); Civilization.tick(w)
						peak = maxf(peak, (Time.get_ticks_usec() - tick_start) / 1000.0)
					w.rng_state = str(rng.state)
				var elapsed = (Time.get_ticks_usec() - cpu_start) / 1000.0
				var people = 0.0
				var food = 0.0
				var stages: Array = []
				for s in w.settlements: people += s.population; food += s.food; stages.append(int(s.stage))
				var valid = Persistence.validate(w)
				var saved = Persistence.save_world(w, "user://phase5-balance.json")
				var restored = Persistence.load_world("user://phase5-balance.json")
				var compatible = not restored.is_empty() and restored.living.memories == w.living.memories and restored.creatures.size() == w.creatures.size()
				if not valid or not saved or not compatible or w.creatures.size() < 6 or w.creatures.size() > 70: failures.append(str(seed_value) + ":" + scenario)
				rows.append({"seed": seed_value, "scenario": scenario, "interventions": intervene, "ticks": ticks, "creatures": w.creatures.size(), "settlements": w.settlements.size(), "people": snappedf(people,.01), "food": snappedf(food,.01), "stages": stages, "memories": w.living.memories.size(), "secrets": w.living.secrets.duplicate(), "chapters": w.living.findings.size(), "energy": w.energy, "valid": valid, "save_compatible": compatible, "simulation_ms": elapsed, "peak_live_tick_ms": peak})
	var report = {"source": "seeded_automated_simulation", "live_seconds_per_tick": 2, "offline_seconds_per_tick": 60, "offline_cap_ticks": 480, "rows": rows, "failures": failures, "wall_ms": Time.get_ticks_msec() - start}
	DirAccess.make_dir_recursive_absolute("res://builds/phase5")
	var file = FileAccess.open("res://builds/phase5/balance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t")); file.close()
	print("BALANCE_RESULT: %d scenarios, %d failures; %d ms" % [rows.size(), failures.size(), report.wall_ms])
	quit(0 if failures.is_empty() else 1)
