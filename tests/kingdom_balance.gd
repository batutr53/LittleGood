extends SceneTree
const K=preload("res://scripts/kingdom.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var rows=[];var failures=[]
	for seed in range(1,51):
		var driver=preload("res://scripts/kingdom_progression_probe.gd").new();driver.start(seed)
		var completed=driver.through_first_flame();var w=driver.world;var tick_count=driver.ticks
		var claimed=w.kingdom.claimed.duplicate();var now=w.saved_at+28800
		Persistence.offline(w,now)
		var valid=Persistence.validate(w) and w.kingdom.claimed==claimed and w.kingdom.workers.size()<=floori(K.home(w).population)
		var frozen=w.kingdom.duplicate(true);Persistence.offline(w,now)
		valid=valid and frozen==w.kingdom
		rows.append({"seed":seed,"completed":completed,"active_simulation_ticks":tick_count,"offline_hours":8,"consistent":valid,"workers":w.kingdom.workers.size(),"population":K.home(w).population})
		if not completed or not valid:failures.append(seed)
	var f=FileAccess.open("res://builds/phase085/balance.json",FileAccess.WRITE);f.store_string(JSON.stringify({"scenarios":rows,"failures":failures,"count":rows.size(),"source":"legal_model_actions_then_bounded_offline_replay"}));f.close()
	print("KINGDOM BALANCE ",rows.size()," scenarios; failures: ",failures);quit(0 if failures.is_empty() else 1)
