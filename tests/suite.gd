extends SceneTree

var checks = 0
var failures: Array = []

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message); printerr("FAIL: " + message)
	else: print("PASS: " + message)

func _initialize() -> void:
	var w = WorldGen.generate(2026, "Test")
	var same = WorldGen.generate(2026, "Test")
	check(w.cells == same.cells and w.creatures == same.creatures and w.rng_state == same.rng_state, "Seed reproduces terrain, wildlife and RNG state")
	check(w.cells != WorldGen.generate(123, "Other").cells, "Different seeds vary terrain")
	var biomes: Array = []
	var species: Array = []
	for c in w.cells:
		if not biomes.has(c.biome): biomes.append(c.biome)
	for c in w.creatures:
		if not species.has(c.species): species.append(c.species)
	check(biomes.size() == 7, "Six land biomes plus river")
	check(species.size() == 6, "Six autonomous creature species")
	check(Persistence.validate(w), "Generated world validates")
	var rng = RandomNumberGenerator.new()
	rng.state = int(w.rng_state)
	var beginning = w.duplicate(true)
	var started = Time.get_ticks_msec()
	for n in range(1800):
		Ecosystem.tick(w, rng)
		Civilization.tick(w)
	check(w.tick == 1800, "1800 simulation ticks complete")
	check(Persistence.validate(w), "Long simulation preserves valid state")
	check(w.creatures.size() <= 70 and w.creatures.size() >= 6, "Creature population remains bounded")
	check(w.discoveries.size() == 6, "Discoveries recorded from actual species")
	check(w.settlements[0].stage == 2, "Settlement develops from camp through village to town")
	check(w.events.size() <= 160, "Event history bounded")
	check(w.achievements.has("season"), "Season milestone awarded")
	print("PROFILE: 1800 ticks in ", Time.get_ticks_msec() - started, " ms")
	for p in range(6):
		var test = beginning.duplicate(true)
		var index = int(test.settlements[0].cell) if p == 5 else 10
		var old = test.duplicate(true)
		check(Powers.apply(test, p, index), "Power %d succeeds" % p)
		check(test.energy == old.energy - Powers.COSTS[p], "Power %d charges correct energy" % p)
		check(test.cells != old.cells or test.creatures != old.creatures or test.settlements != old.settlements, "Power %d changes simulation state" % p)
	var test = beginning.duplicate(true)
	test.energy = 0
	check(not Powers.apply(test, 0, 1), "Insufficient spirit rejects power")
	check(not Powers.apply(test, 5, -1), "Invalid cell rejected")
	var path = "user://test_planet.json"
	for n in range(5):
		check(Persistence.save_world(w, path), "Atomic save round %d" % n)
		var loaded = Persistence.load_world(path)
		check(not loaded.is_empty() and loaded.rng_state == w.rng_state and loaded.creatures.size() == w.creatures.size() and is_equal_approx(loaded.cells[0].plants, w.cells[0].plants) and is_equal_approx(loaded.settlements[0].population, w.settlements[0].population), "Round-trip preserves world and exact RNG %d" % n)
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("corrupted")
	f.close()
	check(not Persistence.load_world(path).is_empty(), "Corruption recovers previous backup")
	check(Persistence.load_world(path, false).is_empty(), "Invalid save rejected safely")
	var offline = beginning.duplicate(true)
	offline.saved_at = 1000
	var report = Persistence.offline(offline, 1000 + 86400 * 10)
	check(report.ticks == 480 and offline.tick == 480, "Ten-day absence bounded to eight-hour progression")
	check(not report.events.is_empty(), "Return summary contains actual events")
	check(Persistence.offline(offline, offline.saved_at - 1000).ticks == 0, "Clock rollback does not reverse simulation")
	var malformed = beginning.duplicate(true)
	malformed.creatures[0].cell = 99999
	check(not Persistence.validate(malformed), "Out-of-range creature rejected")
	malformed = beginning.duplicate(true)
	malformed.tick = "invalid"
	check(not Persistence.validate(malformed), "Invalid numeric save field rejected")
	malformed = beginning.duplicate(true)
	malformed.rng_state = 1.2
	check(not Persistence.validate(malformed), "Imprecise RNG save field rejected")
	malformed = beginning.duplicate(true)
	malformed.settlements = [12]
	check(not Persistence.validate(malformed), "Malformed settlement record rejected without exception")
	print("RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
