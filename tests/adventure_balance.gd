extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var rows=[]
	for seed in range(1,21):
		var p=preload("res://scripts/adventure_progression_probe.gd").new();var ok=p.complete(seed)
		rows.append({"seed":seed,"complete":ok,"error":p.error,"claims":p.world.kingdom.claimed.size(),"hero_xp":p.world.kingdom.adventure.hero.xp,"combat_steps":p.steps})
	var report={"source":"headless_legal_campaign_real_jobs_crafting_and_combat_inputs","scenarios":rows,"failed":rows.filter(func(row):return not row.complete).size()}
	var f=FileAccess.open("res://builds/phase085c/legal-campaigns.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("C6_LEGAL_CAMPAIGNS ",rows.size()," scenarios ",report.failed," failed");quit(0 if report.failed==0 else 1)
