extends SceneTree

var passed = 0
var failed = 0

func verify(value: bool, message: String) -> void:
	if value: passed += 1; print("PASS: ", message)
	else: failed += 1; printerr("FAIL: ", message)

func named_button(node: Node, fragment: String) -> Button:
	if node is Button and node.text.contains(fragment): return node
	for child in node.get_children():
		var found=named_button(child,fragment)
		if found!=null:return found
	return null

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var w = WorldGen.generate(2026, "Living Test")
	var again = WorldGen.generate(2026, "Living Test")
	verify(w.creatures == again.creatures, "Creature identities and traits reproduce from seed")
	var names: Dictionary = {}
	var traits: Dictionary = {}
	for cr in w.creatures: names[cr.given_name] = true; traits[cr.trait] = true
	verify(names.size() == w.creatures.size(), "Every starting creature has a unique name")
	verify(traits.size() == 4, "All four behavioral traits occur")
	verify(w.settlements[0].given_name == again.settlements[0].given_name, "Settlement identity is deterministic")
	verify(LivingStories.objective(w) == "guide_rain", "Opening offers an actionable first gift")
	var cr = w.creatures[0]
	var xp = w.xp
	verify(LivingStories.observe(w, cr) and w.xp > xp, "Observation rewards meeting a real individual")
	xp = w.xp
	verify(not LivingStories.observe(w, cr) and w.xp == xp, "Repeated observation does not farm rewards")
	var cell = int(cr.cell)
	cr.trait = "gardener"
	w.cells[cell].plants = .3
	LivingStories.tick(w)
	verify(w.cells[cell].plants > .3, "Gardener trait restores real vegetation")
	cr.trait = "patient"
	cr.hunger = .5
	LivingStories.tick(w)
	verify(cr.hunger < .5, "Patient trait reduces real hunger")
	var home = w.settlements[0]
	w.creatures = [cr]
	cr.trait = "friendly"
	cr.cell = home.cell
	var food = home.food
	for i in range(4): LivingStories.tick(w)
	verify(home.food > food and home.visitors >= 4, "Friendly visitors share food with a settlement")
	verify(w.living.findings.has("friendship") and home.friend_id == cr.identity, "Repeated visits create a persistent friendship")
	verify(w.living.records.friendship.subject.contains(cr.given_name), "Journal records the actual creature involved")
	var desert = -1
	for i in range(w.cells.size()):
		if w.cells[i].biome == 2: desert = i; break
	w.weather = 0
	w.cells[desert].moisture = .8
	w.cells[desert].plants = .8
	LivingStories.tick(w)
	verify(w.cells[desert].biome == 2, "Desert bloom requires rain")
	w.weather = 1
	w.cells[desert].moisture = .1
	for c in w.cells:
		if c.biome == 2: c.moisture = .1
	LivingStories.tick(w)
	verify(not w.living.findings.has("rain_bloom"), "Rain alone cannot bloom an arid patch")
	w.cells[desert].moisture = .8
	LivingStories.tick(w)
	verify(w.cells[desert].biome == 0 and w.cells[desert].meadow and w.cells[desert].plants == 1, "Wet desert becomes permanent flowering grazing land")
	verify(w.living.findings.has("rain_bloom"), "Actual biome transformation unlocks discovery")
	var blooms = w.living.findings.size()
	LivingStories.tick(w)
	verify(w.living.findings.size() == blooms, "Discovery rewards are awarded once")
	var forest = -1
	for i in range(w.cells.size()):
		if w.cells[i].biome == 1: forest = i; break
	cr.species = 1
	cr.cell = forest
	cr.hunger = .8
	w.cells[forest].plants = 1
	w.tick = 45
	LivingStories.tick(w)
	verify(not w.living.findings.has("lantern_grove"), "Hungry fox cannot trigger a lantern grove")
	cr.hunger = .1
	w.cells[forest].resources = 15
	LivingStories.tick(w)
	verify(w.living.findings.has("lantern_grove") and w.cells[forest].resources == 27 and w.cells[forest].grove_until == 80, "Content forest fox creates visible resource-rich lantern grove")
	home.stage = 1
	LivingStories.tick(w)
	verify(w.living.findings.has("first_village"), "Civilization milestone follows actual settlement stage")
	verify(w.living.findings.size() == 4, "All four living chapters are reachable by rules")
	var saved_names = w.creatures.duplicate(true)
	verify(Persistence.save_world(w, "user://phase3-test.json"), "Extended version-one save writes successfully")
	var loaded = Persistence.load_world("user://phase3-test.json", false)
	var same_identity = not loaded.is_empty() and loaded.living.findings == w.living.findings
	for i in range(saved_names.size()):
		for key in ["identity", "given_name", "trait", "visits"]:
			same_identity = same_identity and loaded.creatures[i][key] == saved_names[i][key]
	verify(same_identity and loaded.settlements[0].friend_id == home.friend_id, "Names, traits, friendships and discoveries survive save/load")
	verify(loaded.living.records.friendship.subject == w.living.records.friendship.subject, "World history keeps its named subjects after loading")
	w.energy = 100
	w.cells[desert].grove_until = 99
	Powers.apply(w, 0, desert)
	verify(not w.cells[desert].has("meadow") and not w.cells[desert].has("grove_until"), "Terraforming removes obsolete meadow and grove visuals")
	var legacy = Persistence.load_world("res://tests/fixtures/planet-v1.json", false)
	verify(not legacy.is_empty() and legacy.creatures[0].has("identity") and legacy.living.findings.is_empty(), "Legacy save receives optional identities without invented discoveries")
	var offline_world = WorldGen.generate(2026, "Return Test")
	Powers.apply(offline_world, 4, 0)
	offline_world.saved_at = 1000
	var report = Persistence.offline(offline_world, 1180)
	verify(report.ticks == 3 and offline_world.living.findings.has("rain_bloom"), "Offline simulation can cause an actual biome discovery")
	verify(report.events.any(func(e): return e.key == "rain_bloom"), "Return report includes actual living chapter event")
	verify(report.new_chapters == 1 and report.creature_change == 0 and report.people_change >= 0, "Return summary reports measured world changes")
	verify(Persistence.validate(offline_world), "Offline transformed world remains consistent")
	var threshold_world = WorldGen.generate(2026, "Village threshold")
	threshold_world.settlements[0].population = 11.99
	threshold_world.saved_at = 1000
	var threshold_report = Persistence.offline(threshold_world, 1060)
	verify(threshold_report.events.any(func(e): return e.key == "first_village"), "Village discovery is included even on the final offline tick")
	threshold_world.tick = 240
	for c in threshold_world.cells:
		if c.biome == 0: c.plants = 1
	Civilization.tick(threshold_world)
	verify(threshold_world.settlements.size() == 2 and threshold_world.settlements.back().has("custom"), "Newly founded communities immediately receive usable identities")
	var explorers = WorldGen.generate(2026, "Trait experiment")
	explorers.creatures = [explorers.creatures[0]]
	var animal = explorers.creatures[0]
	animal.trait = "explorer"
	animal.species = 0
	for c in explorers.cells: c.biome = 1; c.plants = 1.0
	explorers.cells[int(animal.cell)].biome = 0
	var resident = explorers.duplicate(true)
	resident.creatures[0].trait = "gardener"
	var rng_a = RandomNumberGenerator.new()
	var rng_b = RandomNumberGenerator.new()
	rng_a.seed = 1234
	rng_b.seed = 1234
	var explored = false
	for i in range(20):
		Ecosystem.tick(explorers, rng_a)
		Ecosystem.tick(resident, rng_b)
		if explorers.cells[int(animal.cell)].biome != 0: explored = true
	verify(explored and resident.cells[int(resident.creatures[0].cell)].biome == 0, "Explorer crosses habitat boundaries while a content resident stays home")
	var society = explorers.settlements[0]
	society.custom = "orchard"
	explorers.cells[int(society.cell)].plants = .3
	LivingStories.tick(explorers)
	verify(explorers.cells[int(society.cell)].plants > .3, "Orchard custom cultivates the settlement's actual land")
	society.custom = "riverfolk"
	explorers.weather = 1
	society.food = 10
	LivingStories.tick(explorers)
	verify(society.food > 10, "Riverfolk custom gathers food during actual rain")
	society.custom = "stargazers"
	explorers.weather = 0
	var tech = society.tech
	LivingStories.tick(explorers)
	verify(society.tech > tech, "Stargazer custom advances technology in clear weather")
	var original_id = int(animal.identity)
	Powers.apply(explorers, 3, int(animal.cell))
	verify(explorers.creatures.back().identity != original_id and animal.identity == original_id, "New wildlife receives a fresh identity without renaming existing creatures")
	var full_world = WorldGen.generate(2026, "Full habitat")
	while full_world.creatures.size() < 70:
		var new_creature = full_world.creatures[0].duplicate(true)
		new_creature.erase("identity")
		full_world.creatures.append(new_creature)
	LivingStories.ensure(full_world)
	var full_state = full_world.duplicate(true)
	verify(not Powers.apply(full_world, 3, int(full_world.settlements[0].cell)) and full_world == full_state, "Full wildlife habitat rejects gifts without charging spirit or changing traits")
	var invalid = w.duplicate(true)
	invalid.living = "broken"
	verify(not Persistence.validate(invalid), "Malformed optional story data is rejected safely")
	invalid = w.duplicate(true)
	invalid.creatures[0].trait = "invalid"
	verify(not Persistence.validate(invalid), "Unknown saved behavioral trait is rejected")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.is_test_session = true
	game.new_planet(2026, "Opening Test", false)
	game.ui.close()
	await process_frame
	game.ui.follow_chapter()
	verify(game.power == 4 and game.view.selected >= 0, "Onboarding focuses a real rain target")
	game.touch_world(game.view.screen_point(game.world.cells[game.view.selected]))
	verify(game.world.weather == 1 and game.world.living.gifts == 1 and game.power == -1, "Guided gift affects weather and safely returns to inspection")
	game.advance_tick()
	game.ui.follow_chapter()
	verify(game.world.living.observed.size() == 1 and game.view.selected_creature == 0, "Guided observation reveals a named visible creature")
	game.ui.follow_chapter()
	game.touch_world(game.view.screen_point(game.world.cells[game.view.selected]))
	verify(game.world.creatures.back().trait == "friendly", "Wildlife welcomed at camp can form a friendship")
	for i in range(4): game.advance_tick()
	verify(game.world.living.findings.has("friendship"), "Opening friendship occurs through ordinary simulation")
	game.ui.follow_chapter()
	game.touch_world(game.view.screen_point(game.world.cells[game.view.selected]))
	for i in range(70): game.advance_tick()
	verify(game.world.living.findings.has("first_village"), "Care loop reaches a real village within a short session")
	verify(Persistence.validate(game.world), "Full onboarding leaves a valid saveable world")
	game.in_menu = true
	game.ui.neighbors()
	await process_frame
	var neighbor=named_button(game.ui.modal,game.world.creatures[0].given_name)
	verify(neighbor!=null,"Neighbor album exposes the actual named creature")
	if neighbor!=null:neighbor.pressed.emit()
	verify(not game.in_menu and game.view.selected_identity == int(game.world.creatures[0].identity), "Neighbor album returns to the actual named creature")
	game.view.focus_creature(2)
	var selected_id = game.view.selected_identity
	game.world.creatures.remove_at(0)
	game.view.reconcile_selection()
	verify(game.view.selected_identity == selected_id and game.view.selected_creature == 1, "Selection follows identity when another creature leaves the population")
	game.in_menu = true
	print("PHASE3_RESULT: ", passed, " passed, ", failed, " failed")
	quit(0 if failed == 0 else 1)
