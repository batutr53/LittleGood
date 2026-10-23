extends SceneTree
const C=preload("res://scripts/cosmetics.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var rows: Array=[];var failures: Array=[]
	for seed in [2026,42,7,301,99991]:
		for duration in [60,450,480]:
			for active in [false,true]:
				var w=WorldGen.generate(seed,"Economy simulation");C.ensure(w)
				var rng=RandomNumberGenerator.new();rng.state=int(w.rng_state)
				if active:
					for cr in w.creatures:LivingStories.observe(w,cr)
					Powers.apply(w,4,int(w.creatures[0].cell));Powers.apply(w,5,int(w.settlements[0].cell))
				for i in range(duration):Ecosystem.tick(w,rng);Civilization.tick(w);C.reconcile(w)
				var income=int(w.wardrobe.earned)
				for id in C.items():
					if not C.items()[id].premium and not C.owned(w,id):C.buy(w,id)
				var before=w.wardrobe.duplicate(true)
				for i in range(50):
					C.reconcile(w)
					for id in w.wardrobe.owned:C.buy(w,id)
				var idempotent=before==w.wardrobe
				var save=Persistence.save_world(w,"user://phase8-economy.json")
				var restored=Persistence.load_world("user://phase8-economy.json")
				var ok=C.validate(w) and save and restored.get("wardrobe",{})==w.wardrobe and idempotent and income<=525 and w.wardrobe.dust>=0
				if active and duration==60:ok=ok and w.wardrobe.owned.size()>=5
				if not ok:failures.append(str(seed)+":"+str(duration)+":"+str(active))
				rows.append({"seed":seed,"ticks":duration,"interventions":active,"earned":income,"spent":w.wardrobe.spent,"balance":w.wardrobe.dust,"owned":w.wardrobe.owned.size(),"idempotent":idempotent,"valid":ok})
	var cost=0
	for id in C.items():
		if not C.items()[id].premium:cost+=int(C.items()[id].price)
	if cost>525:failures.append("catalog_unaffordable")
	var f=FileAccess.open("res://builds/phase8/economy.json",FileAccess.WRITE);f.store_string(JSON.stringify({"source":"seeded_economy_simulation","scenarios":rows,"failures":failures,"lifetime_reward_cap":525,"catalog_cost":cost}));f.close()
	print("ECONOMY_RESULT ",rows.size()," scenarios, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
