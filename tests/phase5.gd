extends SceneTree

var passed = 0
var failed = 0
const SLOT = "user://phase5-world.json"

func verify(value: bool, message: String) -> void:
	if value: passed += 1; print("PASS: ", message)
	else: failed += 1; printerr("FAIL: ", message)

func _initialize() -> void:
	run.call_deferred()

func simulate(w: Dictionary, ticks: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.state = int(w.rng_state)
	for i in range(ticks): Ecosystem.tick(w, rng); Civilization.tick(w)
	w.rng_state = str(rng.state)

func run() -> void:
	var original = FileAccess.get_file_as_string(Persistence.PATH) if FileAccess.file_exists(Persistence.PATH) else ""
	var w = WorldGen.generate(2026, "Chronicle test")
	verify(w.living.memories.is_empty() and w.living.secrets.is_empty(), "New worlds do not invent historical events")
	verify(w.creatures.all(func(cr): return cr.recorded_at == 0 and cr.preferred == cr.species), "Creatures receive recorded ages and species habitats")
	var cell = int(w.creatures[0].cell)
	var a = w.creatures[0]
	var b = w.creatures[1]
	b.cell = cell
	b.species = a.species
	a.hunger = .2
	b.hunger = .2
	# A small controlled fixture isolates repeated actual co-location.
	w.creatures = [a, b]
	for i in range(6): w.tick += 1; LivingStories.tick(w)
	verify(int(a.companion) == int(b.identity) and int(b.companion) == int(a.identity), "Six repeated meetings form a symmetric companionship")
	verify(b.hunger < .2, "Companions have a real foraging benefit")
	verify(w.living.memories.filter(func(e): return e.key == "companions").size() == 1, "Companionship creates one persistent memory")
	var fox = b.duplicate(true)
	fox.species = 1
	fox.identity = 999
	a.species = 0
	a.hunger = .9
	w.creatures = [a, fox]
	LivingStories.tick(w)
	verify(a.rival == 999 and w.living.memories.any(func(e): return e.key == "rivalry"), "Hungry herbivores recognize actual co-located predators")
	var mountain = -1
	var forest = -1
	for i in range(w.cells.size()):
		for j in range(w.cells.size()):
			if absf(w.cells[i].x - w.cells[j].x) + absf(w.cells[i].y - w.cells[j].y) == 1:
				mountain = i; forest = j; break
		if mountain >= 0: break
	w.energy = 100
	Powers.apply(w, 2, mountain)
	w.energy = 100
	Powers.apply(w, 1, forest)
	LivingStories.tick(w)
	verify(w.cells[mountain].get("spring", false) and w.living.secrets.has("mountain_spring"), "Adjacent raised mountain and wet forest awaken a spring")
	w.cells[forest].moisture = .7
	LivingStories.tick(w)
	verify(w.cells[forest].moisture > .7, "Spring has a localized moisture consequence")
	w.energy = 100
	Powers.apply(w, 0, mountain)
	verify(not w.cells[mountain].has("spring"), "Terraforming removes a displaced spring")
	fox.cell = forest
	fox.preferred = 1
	fox.hunger = .1
	fox.trait = "patient"
	fox.habitat_ticks = 359
	w.cells[forest].grove_until = w.tick + 10
	w.creatures = [fox]
	LivingStories.tick(w)
	verify(fox.get("silver", false) and w.living.secrets.has("silver_fox"), "Thriving forest fox discovers its silver variant during a lantern night")
	var rare_count = w.living.memories.size()
	LivingStories.tick(w)
	verify(w.living.memories.size() == rare_count, "Rare variants never farm repeated rewards or memories")
	fox.species = 5
	fox.cell = forest
	w.cells[forest].moisture = .95
	w.cells[forest].plants = .4
	w.tick = 80
	w.weather = 0
	w.living.previous_weather = 1
	LivingStories.tick(w)
	verify(w.living.secrets.has("rainbow_choir") and w.cells[forest].plants > .4, "A wetland bird after actual clearing rain restores plants")
	verify(w.living.choir_until > w.tick, "Choir starts a bounded rendered rainbow presentation")
	fox.trail = [0,1,2,3,4,5,6,7]
	fox.recorded_at = 0
	w.tick = 450
	LivingStories.tick(w)
	verify(w.living.memories.any(func(e): return e.key == "explored") and w.living.memories.any(func(e): return e.key == "elder"), "Exploration and recorded survival produce distinct histories")
	var home = w.settlements[0]
	home.stage = 1
	home.food = 60
	home.tech = 2
	home.population = 14
	LivingStories.tick(w)
	verify(home.landmark, "Well supplied village builds a cultural landmark")
	home.custom = "orchard"
	home.food = 50
	LivingStories.tick(w)
	verify(home.food >= 52, "Orchard tradition improves harvest on festival ticks")
	home.custom = "riverfolk"
	w.cells[int(home.cell)].moisture = .5
	LivingStories.tick(w)
	verify(w.cells[int(home.cell)].moisture > .5, "Riverfolk tradition conserves home water")
	var neighbor = home.duplicate(true)
	neighbor.cell = int(home.cell) + 1
	neighbor.given_name = "Second haven"
	neighbor.allies = []
	w.settlements.append(neighbor)
	LivingStories.tick(w)
	verify(home.allies.has(int(neighbor.cell)) and neighbor.allies.has(int(home.cell)), "Prosperous nearby villages form symmetric learning alliances")
	home.dry_ticks = 12
	w.cells[int(home.cell)].moisture = .8
	LivingStories.tick(w)
	verify(home.helped and w.living.memories.any(func(e): return e.key == "rescue"), "Recovery memory requires a recorded dry spell and restored moisture")
	verify(LivingStories.rename_subject(fox, "  Ay Işığı  ") and fox.given_name == "Ay Işığı", "Personal names support Turkish and trim edges")
	verify(not LivingStories.rename_subject(home, " ") and not LivingStories.rename_subject(home, "x".repeat(25)), "Empty and excessive names are rejected")
	verify(LivingStories.rename_subject(home, "My Haven"), "Settlements can be personalized")
	for i in range(5): LivingStories.favorite(w, i)
	verify(w.living.favorites.size() == 5 and not LivingStories.favorite(w, 5), "Favorite places are bounded at five")
	verify(LivingStories.favorite(w, 1) and not w.living.favorites.has(1), "Favorite places toggle without duplicates")
	verify(Persistence.save_world(w, SLOT), "Expanded world validates and saves transactionally")
	var loaded = Persistence.load_world(SLOT)
	verify(not loaded.is_empty() and loaded.living.memories == w.living.memories, "Chronicle survives save and integer normalization")
	verify(loaded.creatures[0].given_name == fox.given_name and loaded.settlements[0].given_name == "My Haven" and loaded.living.favorites == w.living.favorites, "Names and favorites persist")
	var malformed = w.duplicate(true)
	malformed.living.memories[0].cell = 9999
	verify(not Persistence.validate(malformed), "Out-of-world memory locations are rejected")
	malformed = w.duplicate(true)
	malformed.creatures[0].trail = [INF]
	verify(not Persistence.validate(malformed), "Non-finite exploration locations are rejected")
	for fixture in ["planet-v1.json", "planet-v02.json", "planet-v03.json", "planet-v04.json"]:
		var path = "res://tests/fixtures/" + fixture
		if not FileAccess.file_exists(path): continue
		var legacy = Persistence.load_world(path, false)
		verify(not legacy.is_empty() and legacy.living.has("memories"), "Legacy world gains optional history fields: " + fixture)
	var offline = WorldGen.generate(2026, "Offline")
	var s = offline.settlements[0]
	s.stage = 1; s.population = 14; s.food = 60; s.tech = 2
	var report = Persistence.offline(offline, offline.saved_at + 86400)
	verify(report.memories.any(func(e): return e.key == "landmark"), "Return report includes actual offline milestones")
	verify(report.memories.all(func(e): return offline.living.memories.has(e)), "Return report never fabricates a memory")
	var seven = WorldGen.generate(2026, "Seven")
	var seven_report = Persistence.offline(seven, seven.saved_at + 604800)
	verify(seven_report.ticks == 480, "Seven-day absence remains gently bounded")
	verify(seven_report.minutes == 10080, "Return report distinguishes actual seven-day absence from capped simulation")
	var same_a = WorldGen.generate(42, "Same")
	var same_b = same_a.duplicate(true)
	simulate(same_a, 500); simulate(same_b, 500)
	verify(same_a == same_b, "New histories and relationships are deterministic for the same seed")
	verify(same_a.living.memories.size() <= 64 and same_a.living.remembered.size() <= 128, "Individual histories remain bounded")
	var anthology = same_a.duplicate(true)
	for i in range(180): LivingStories.remember(anthology, "explored:qa" + str(i), "explored", 0, "QA")
	verify(anthology.living.memories.size() == 64 and anthology.living.remembered.size() <= 128, "Long running history rotates old individual episodes")
	verify(anthology.living.memories.any(func(e): return e.key == "first_birth"), "Collectible first birth survives rotating individual histories")
	var game = load("res://scenes/main.tscn").instantiate()
	game.is_test_session = true
	root.add_child(game)
	verify(not quit_on_go_back, "Android back auto-quit is disabled at the SceneTree boundary")
	game.new_planet(2026, "UI", false)
	game.world = loaded
	game.view.world = loaded
	game.ui.history()
	verify(game.ui.page == "history", "Illustrated Chronicle opens in the actual scene")
	game.ui.focus_place(int(fox.cell))
	verify(game.view.selected == int(fox.cell) and not game.in_menu, "Memory revisit focuses its real recorded place")
	game.view.selected_creature = 0
	game.ui.inspect_selected()
	verify(game.ui.page == "detail", "Personalization and individual history open for a selected creature")
	game.get_window().go_back_requested.emit()
	verify(game.ui.page == "menu" and game.in_menu, "Window back requests reach menu navigation exactly once")
	game.world = anthology
	game.view.world = anthology
	game.rng.state = int(anthology.rng_state)
	game.world.energy = 100
	Powers.apply(game.world, 1, forest)
	game.world.energy = 100
	Powers.apply(game.world, 2, mountain)
	game.ui.close()
	game.ui.hint.text = ""
	game.advance_tick()
	verify(game.world.living.memories.size() == 64 and game.ui.hint.text == game.ui.t("mountain_spring"), "A full Chronicle still celebrates a newly discovered secret")
	game.ui.postcard_image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	game.ui.postcard_image.fill(Color("abcabc"))
	verify(game.ui.save_postcard("user://phase5-test.png") and Image.load_from_file("user://phase5-test.png").get_size() == Vector2i(64,64), "PNG export writes a real independently readable image")
	game.ui.postcard_image = null
	verify(not game.ui.save_postcard("user://phase5-empty.png"), "Screenshot export rejects an absent image")
	verify(FileAccess.get_file_as_string(Persistence.PATH) == original if not original.is_empty() else not FileAccess.file_exists(Persistence.PATH), "Phase five QA leaves the player's world untouched")
	game.queue_free()
	await process_frame
	print("PHASE5_RESULT: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
