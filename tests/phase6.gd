extends SceneTree

const Showcase = preload("res://scripts/planet_showcase.gd")
const Connections = preload("res://scripts/world_connections.gd")
var passed = 0
var failed = 0
const SLOT = "user://phase6-world.json"

func verify(ok: bool, message: String) -> void:
	if ok: passed += 1; print("PASS: ",message)
	else: failed += 1; printerr("FAIL: ",message)

func _initialize() -> void:
	run.call_deferred()

func simulate(w: Dictionary, count: int) -> void:
	var rng = RandomNumberGenerator.new()
	rng.state = int(w.rng_state)
	for i in range(count): Ecosystem.tick(w,rng); Civilization.tick(w)
	w.rng_state = str(rng.state)

func run() -> void:
	var player_before = FileAccess.get_file_as_bytes(Persistence.PATH)
	var w = WorldGen.generate(2026,"Mavi Evren")
	simulate(w,100)
	var snapshot = w.duplicate(true)
	var encoded = Showcase.encode(w)
	verify(not encoded.is_empty() and encoded.to_utf8_buffer().size()<Showcase.MAX_BYTES,"Actual world exports within the public size budget")
	verify(w==snapshot,"Export never changes the source planet")
	var data = Showcase.parse(encoded)
	verify(Showcase.validate(data) and data.planet.name==w.name,"Versioned showcase JSON round-trips Unicode names")
	verify(not data.has("seed") and not data.planet.has("seed") and not encoded.contains("rng_state") and not encoded.contains("saved_at") and not encoded.contains("diagnostics"),"Shared format omits private save and diagnostic metadata")
	var ro = Showcase.world_from(data)
	verify(ro.get("_read_only",false) and ro.creatures.size()==w.creatures.size() and ro.settlements.size()==w.settlements.size(),"Preview reconstructs real ecosystems and communities")
	verify(ro.living.memories.size()==w.living.memories.size(),"Showcase preserves recorded milestones")
	var frozen = ro.duplicate(true)
	var rng = RandomNumberGenerator.new()
	Ecosystem.tick(ro,rng); Civilization.tick(ro); LivingStories.tick(ro); Connections.tick(ro)
	verify(ro==frozen,"All simulation entry points leave visits frozen")
	verify(not Powers.apply(ro,4,0) and not LivingStories.observe(ro,ro.creatures[0]),"Visitors cannot cast powers or change discoveries")
	verify(not LivingStories.rename_subject(ro.creatures[0],"Changed") and not LivingStories.favorite(ro,0) and not Connections.favorite_creature(ro,ro.creatures[0]),"Visitors cannot rename or favorite imported world records")
	LivingStories.discover(ro,"rain_bloom",0); LivingStories.secret(ro,"silver_fox",0)
	verify(ro==frozen,"Discovery helpers cannot bypass read-only visits")
	Persistence.offline(ro,1000000)
	verify(ro==frozen and not Persistence.save_world(ro,SLOT),"Offline replay and saves cannot write a visiting planet")
	var unsafe = w.duplicate(true)
	unsafe.name = "C:\\Users\\PRIVATE\\planet"
	unsafe.creatures[0].given_name = "user://planet.json"
	unsafe.creatures[0].parent_name = "https://private.example"
	var safe_export = Showcase.encode(unsafe)
	verify(not safe_export.is_empty() and not safe_export.contains("PRIVATE") and not safe_export.contains("user://") and not safe_export.contains("private.example"),"Export replaces path-like names rather than revealing private paths")
	verify(Showcase.parse("[gd_resource type=Script]").is_empty(),"Godot resources are never loaded as shared data")
	verify(Showcase.parse("{").is_empty(),"Malformed JSON is rejected")
	verify(Showcase.parse("[".repeat(40)+"0"+"]".repeat(40)).is_empty(),"Deep nesting is rejected before JSON allocation")
	verify(Showcase.parse(" ".repeat(Showcase.MAX_BYTES+1)).is_empty(),"Oversized text is rejected")
	for key in ["version","planet","cells","creatures","settlements","memories"]:
		var bad = data.duplicate(true); bad[key] = "wrong type"
		verify(Showcase.parse(JSON.stringify(bad)).is_empty(),"Untrusted field type rejected: "+key)
	var bad = data.duplicate(true); bad.version = 99
	verify(not Showcase.validate(bad),"Unsupported future format versions are rejected")
	bad = data.duplicate(true); bad.cells[0].canopy_arch=true;bad.cells[1].canopy_arch=true
	verify(not Showcase.validate(bad),"Imported landmarks cannot exceed systemic per-kind limits")
	bad = data.duplicate(true); bad.script = "res://scripts/main.gd"
	verify(not Showcase.validate(bad),"Embedded script and unknown root fields are rejected")
	bad = data.duplicate(true); bad.cells[0].resource_path = "user://planet.json"
	verify(not Showcase.validate(bad),"Unknown nested fields cannot carry resource references")
	bad = data.duplicate(true); bad.cells[0].height = INF
	verify(not Showcase.validate(bad),"Non-finite terrain is rejected")
	bad = data.duplicate(true); bad.cells[1].x=bad.cells[0].x; bad.cells[1].y=bad.cells[0].y
	verify(not Showcase.validate(bad),"Duplicate map coordinates are rejected")
	bad = data.duplicate(true); bad.creatures[0].cell=999999
	verify(not Showcase.validate(bad),"Out-of-map creature locations are rejected")
	bad = data.duplicate(true); bad.creatures[0].companion=bad.creatures.size()
	verify(not Showcase.validate(bad),"Dangling creature relationships are rejected")
	bad = data.duplicate(true); bad.creatures[0].id=.5
	verify(not Showcase.validate(bad),"Fractional identities are rejected")
	bad = data.duplicate(true); bad.creatures[0].name="<script>"
	verify(not Showcase.validate(bad),"Markup-bearing imported names are rejected")
	bad = data.duplicate(true); bad.planet.name="malicious\nname"
	verify(not Showcase.validate(bad),"Control characters are rejected")
	bad = data.duplicate(true); bad.settlements[0].allies=[999]
	verify(not Showcase.validate(bad),"Dangling community references are rejected")
	bad = data.duplicate(true); bad.memories[0].key="run_code"
	verify(not Showcase.validate(bad),"Unknown event keys cannot call arbitrary UI behavior")
	bad = data.duplicate(true); bad.memories[0].subject="x".repeat(193)
	verify(not Showcase.validate(bad),"Oversized historical subjects are rejected")
	bad = data.duplicate(true); bad.creatures.resize(101)
	verify(not Showcase.validate(bad),"Imported population allocation is bounded")
	var store = Showcase.new()
	store.directory="user://phase6-library-"+str(Time.get_ticks_usec())
	var id = store.import_text(encoded)
	verify(id.length()==64 and store.entries()==[id],"Validated imports enter the local library")
	verify(store.import_text(encoded)==id and store.entries().size()==1,"Repeated imports deduplicate by public content")
	verify(not store.react("../planet",1) and store.get_planet("../planet").is_empty(),"Library IDs cannot traverse private paths")
	verify(store.react(id,2) and store.reaction(id)==2,"Friendly reactions persist locally without sending")
	verify(not store.react(id,4),"Invalid reactions are rejected")
	var source_bytes = FileAccess.get_file_as_bytes(store.directory.path_join(id+".lgplanet"))
	for i in range(7):
		var other = data.duplicate(true); other.planet.name="Guest "+str(i)
		store.import_text(JSON.stringify(other))
	var ninth = data.duplicate(true); ninth.planet.name="Ninth"
	verify(store.entries().size()==8 and store.import_text(JSON.stringify(ninth)).is_empty(),"Library storage is bounded at eight independent planets")
	var removed=store.entries().filter(func(item):return item!=id)[0]
	verify(not store.remove("../planet") and store.remove(removed) and not store.import_text(JSON.stringify(ninth)).is_empty(),"Players can safely replace a local copy in a full library")
	var legacy=Persistence.load_world("res://tests/fixtures/planet-v05.json")
	verify(not legacy.is_empty() and legacy.name=="Legacy 0.5" and legacy.living.has("favorite_creatures") and legacy.creatures[0].has("lineage"),"An actual tagged-0.5 save gains optional social fields without losing its planet")
	var diag=LocalDiagnostics.new()
	diag.configure("user://phase6-metrics.json","simulated");diag.clear();diag.begin()
	diag.record("first_launch",0,true);diag.record("first_launch",0,true);diag.advance(.5);diag.finish()
	verify(diag.feedback().events.filter(func(e):return e.event=="first_launch").size()==1,"First launch is recorded once in local diagnostic export")
	verify(diag.feedback().events.all(func(e):return e.source=="simulated") and diag.feedback().game_version==ProjectSettings.get_setting("application/config/version"),"Automated diagnostic evidence stays labeled simulated")
	diag.begin()
	var interrupted=LocalDiagnostics.new();interrupted.configure("user://phase6-metrics.json","simulated");interrupted.begin();interrupted.finish()
	verify(interrupted.feedback().events.any(func(e):return e.event=="unclean_previous_session"),"An unfinished session is detectable without claiming a confirmed crash")
	var cr = w.creatures[0]
	verify(Connections.favorite_creature(w,cr) and Connections.is_favorite(w,int(cr.identity)),"Favorite creatures use stable identities")
	verify(Connections.favorite_creature(w,cr) and not Connections.is_favorite(w,int(cr.identity)),"A creature favorite toggles without duplicates")
	Connections.favorite_creature(w,cr)
	verify(Persistence.save_world(w,SLOT) and not Persistence.load_world(SLOT).living.favorite_creatures.is_empty(),"Favorite creature records survive save/load")
	var habitat = WorldGen.generate(7,"Opportunities")
	for c in habitat.cells: c.biome=0; c.moisture=.2; c.plants=.4
	habitat.tick=90
	var population=habitat.creatures.size()
	Connections.tick(habitat)
	verify(habitat.creatures.size()==population,"A dry world does not fabricate a migrant")
	habitat.cells[0].biome=5; habitat.cells[0].moisture=.9; habitat.cells[0].plants=.8
	Connections.tick(habitat)
	verify(habitat.creatures.size()==population+1 and habitat.creatures.back().get("migrant",false),"Real wetland conditions admit a migratory bird")
	var next_migration=habitat.living.next_migration
	Connections.tick(habitat)
	verify(habitat.creatures.size()==population+1 and next_migration==570,"Migration has a simulation-based cooldown without calendar punishment")
	var gardener=habitat.creatures[0]
	gardener.cell=1; gardener.trait="gardener"
	habitat.cells[1].biome=1;habitat.cells[1].moisture=.9;habitat.cells[1].plants=1;habitat.cells[1].detail=.95
	Connections.tick(habitat)
	verify(habitat.cells[1].get("canopy_arch",false),"A gardener in thriving forest creates an actual discoverable canopy")
	var bird=habitat.creatures.back()
	var bun=habitat.creatures[1]
	bun.species=0;bun.cell=0;bun.hunger=.7
	Connections.tick(habitat)
	verify(habitat.cells[0].get("reed_shelter",false) and bun.hunger<.7,"Co-located wetland birds shelter grazing mossbuns")
	var first=habitat.settlements[0]
	var second=first.duplicate(true)
	second.cell=int(first.cell)+1; second.given_name="Neighbor"; second.allies=[int(first.cell)]
	first.allies=[int(second.cell)];first.food=90;second.food=10
	habitat.settlements.append(second)
	var food=first.food+second.food
	Connections.tick(habitat)
	verify(first.food<90 and second.food>10 and is_equal_approx(food,first.food+second.food),"Trade redistributes actual surplus while conserving food")
	verify(not habitat.living.trades.is_empty() and first.trade_until>habitat.tick,"Trade produces a saved route and visible activity window")
	first.allies=[];second.allies=[]
	habitat.cells[int(first.cell)].resources=1;habitat.cells[int(second.cell)].resources=1
	Connections.tick(habitat)
	verify(first.rival_cell==second.cell and second.rival_cell==first.cell,"Resource competition emerges from actual depleted neighboring land")
	var third=second.duplicate(true);third.cell=int(second.cell)+1;third.rival_cell=-1;third.allies=[]
	habitat.settlements.append(third);habitat.cells[int(third.cell)].resources=1
	Connections.tick(habitat)
	verify(first.rival_cell==second.cell and second.rival_cell==first.cell and third.rival_cell==-1,"A third community cannot overwrite an existing reciprocal rivalry")
	habitat.cells[int(first.cell)].resources=20;habitat.cells[int(second.cell)].resources=20
	Connections.tick(habitat)
	verify(first.rival_cell==-1 and habitat.living.memories.any(func(m):return m.key=="cooperation"),"Restoring resources resolves community tension")
	verify(not Connections.opportunities(habitat).is_empty(),"Returning players receive actionable state-based opportunities")
	var offline=WorldGen.generate(2026,"Return")
	var report=Persistence.offline(offline,offline.saved_at+86400)
	verify(report.memories.any(func(m):return m.key=="migration"),"Actual offline migration appears in return memories")
	verify(Persistence.validate(offline),"New encounters retain save consistency after bounded offline replay")
	var game=load("res://scenes/main.tscn").instantiate()
	game.is_test_session=true
	root.add_child(game)
	game.save_path=SLOT
	game.new_planet(99,"My own world",false)
	game.world.cells[0].meadow=true
	game.view.invalidate();game.view._process(.01)
	verify(game.view.decoration_cells.has(game.world.cells[0]),"Foreground indexing retains decorations after real world invalidation")
	game.has_player_world=true
	game.is_test_session=false
	game.diagnostics.configure("user://phase6-diag.json","simulated")
	game.showcases=store
	verify(game.visit_planet(data,id),"A validated local planet opens in the actual game scene")
	verify(game.view.decoration_cells.is_empty(),"Switching worlds clears cached foreground references")
	var own_frozen=game.visit_origin.world.duplicate(true)
	var visit_frozen=game.world.duplicate(true)
	var saved_while_visiting=FileAccess.get_file_as_bytes(SLOT)
	game.advance_tick();game.checkpoint();game.schedule_save();game.new_planet(0,"No",true)
	game.ui.neighbors();game.ui.history();game.ui.planet_profile()
	verify(game.world==visit_frozen and game.visit_origin.world==own_frozen,"Visiting UI and gameplay do not mutate either planet")
	verify(FileAccess.get_file_as_bytes(SLOT)==saved_while_visiting and FileAccess.get_file_as_bytes(store.directory.path_join(id+".lgplanet"))==source_bytes,"Visiting leaves own save and shared source bytes unchanged")
	game.ui.close()
	game.suspend_session();await game.resume_session(Time.get_unix_time_from_system()+86400)
	verify(game.visiting and game.world==visit_frozen,"Android lifecycle cannot replay offline events into a visit")
	game.ui.visit_menu();game.navigate_back()
	verify(not game.visiting and game.world.name=="My own world" and not game.world.get("_read_only",false),"Back returns from a visit to the original world")
	verify(Persistence.load_world(SLOT).name=="My own world","A visitor never replaces the player's save slot")
	game.is_test_session=true
	game.ui.local_universe();game.ui.wonders();game.ui.neighbors()
	verify(game.ui.page=="neighbors","The illustrated collection remains navigable after a visit")
	game.diagnostics.finish()
	game.queue_free();await process_frame
	verify(FileAccess.get_file_as_bytes(Persistence.PATH)==player_before,"All phase-six verification preserves the player's real save")
	print("PHASE6_RESULT: %d passed, %d failed" % [passed,failed])
	quit(0 if failed==0 else 1)
