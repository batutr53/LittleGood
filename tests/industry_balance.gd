extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var rows=[];var failures=[]
	for seed in range(1,51):
		var probe=preload("res://scripts/industry_progression_probe.gd").new();var completed=probe.through_iron_age(seed);var w=probe.world
		var valid=not w.is_empty() and Persistence.validate(w)
		if completed:
			var claims=w.kingdom.claimed.duplicate();var items=w.kingdom.industry.items.duplicate(true);var now=w.saved_at+28800
			Persistence.offline(w,now);var frozen=w.kingdom.duplicate(true);Persistence.offline(w,now)
			valid=valid and Persistence.validate(w) and w.kingdom==frozen and w.kingdom.claimed==claims and w.kingdom.industry.items==items
		rows.append({"seed":seed,"completed":completed,"consistent":valid,"ticks":probe.driver.ticks,"offline_hours":8,"error":probe.error})
		if not completed or not valid:failures.append(seed)
	var f=FileAccess.open("res://builds/phase09/balance.json",FileAccess.WRITE);f.store_string(JSON.stringify({"count":rows.size(),"failures":failures,"scenarios":rows,"source":"legal_ten_quest_journeys_then_eight_hour_bounded_offline_replay"}));f.close()
	print("INDUSTRY_BALANCE ",rows.size()," scenarios; failures: ",failures);quit(0 if failures.is_empty() else 1)
