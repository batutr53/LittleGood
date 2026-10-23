extends SceneTree
const H=preload("res://scripts/hero.gd")
const I=preload("res://scripts/industry.gd")
const K=preload("res://scripts/kingdom.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var w=Persistence.load_world("res://tests/fixtures/planet-v085b.json");var old=w.duplicate(true);var checks={}
	checks.actual_b_fixture=not w.is_empty() and w.kingdom.version==2 and not w.kingdom.industry.queue.is_empty()
	checks.migrate_once=H.enable(w) and not H.enable(w) and K.level(w)==11
	checks.conservation=w.kingdom.xp==2200 and w.kingdom.claimed==old.kingdom.claimed and w.kingdom.industry==old.kingdom.industry and w.cells==old.cells
	checks.no_replay=not K.claim(w,"main_10")
	checks.recruit=H.recruit(w,"Arda") and not H.recruit(w,"Other") and H.level(w.kingdom.adventure.hero)==1
	checks.reject_name=not H.valid_name("<bad>") and H.valid_name("Yağmur")
	var civilian=w.kingdom.industry.items[0];checks.slots=not H.equip(w,"weapon",int(civilian.id)) and not H.equip(w,"helmet",0)
	var probe=preload("res://scripts/hero_progression_probe.gd").new();checks.legal_11=probe.armed()
	w=probe.world;checks.real_equipment=H.stats(w).attack==18 and w.kingdom.claimed.size()==11 and w.kingdom.adventure.hero.xp==0
	checks.exact_save=Persistence.save_world(w,"user://hero-check.json") and Persistence.load_world("user://hero-check.json").kingdom==w.kingdom
	var bad=w.duplicate(true);bad.kingdom.adventure.hero.equipment.weapon=999;checks.dangling=not Persistence.validate(bad)
	var ro=w.duplicate(true);ro._read_only=true;var frozen=ro.duplicate(true);H.enable(ro);H.recruit(ro,"No");H.equip(ro,"weapon",0);checks.readonly=ro==frozen
	var failed=checks.values().has(false);print("HERO_C1 ",checks);quit(1 if failed else 0)
