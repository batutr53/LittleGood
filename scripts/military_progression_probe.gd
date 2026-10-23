extends RefCounted
const K=preload("res://scripts/kingdom.gd")
const M=preload("res://scripts/military.gd")
const I=preload("res://scripts/industry.gd")
var base=preload("res://scripts/adventure_progression_probe.gd").new()
var world: Dictionary
var driver
var error=""
func supplies(cost: Dictionary) -> bool:
	for key in cost:
		if key in ["wood","stone"] and world.kingdom.stock[key]<cost[key]*1000:
			if not driver.gather(key,cost[key]-world.kingdom.stock[key]/1000.0+1):error="gather "+key;return false
	return K.afford(world,cost)
func build(kind: String) -> int:
	if not supplies(K.buildings()[kind].cost):return -1
	K.assign(world,int(world.kingdom.workers[2].id),0)
	return driver.build(kind)
func trained(seed: int=2026) -> bool:
	if not base.complete(seed):error="C "+base.error;return false
	world=base.world;driver=base.foundation.base.driver
	if not M.enable(world):error="enable";return false
	var barracks=build("barracks")
	if barracks<0:error="barracks";return false
	# Keep the original producers; recruit one instructor and three soldiers.
	for i in range(4):
		if not K.recruit(world):error="recruit "+str(i);return false
	var instructor=int(world.kingdom.workers[-4].id)
	if not K.assign(world,instructor,barracks) or not K.claim(world,"main_16"):error="quest16";return false
	for i in range(3):
		var kind=["militia","spearman","archer"][i]
		if not supplies({"wood":2}) or not base.craft(kind+"_kit"):error="craft "+kind+" "+base.error;return false
		var kit=world.kingdom.industry.items.filter(func(x):return x.recipe==kind+"_kit")[0]
		if not M.train(world,int(world.kingdom.workers[-3+i].id),kind,int(kit.id),barracks):error="train "+kind;return false
	for i in range(30):driver.step()
	if not K.claim(world,"main_17"):error="quest17";return false
	return true
func defended(seed: int=2026) -> bool:
	if not trained(seed):return false
	if build("watchtower")<0 or build("wall")<0:error="defenses";return false
	if not M.formation(world,"defensive") or not K.claim(world,"main_18"):error="quest18";return false
	return true
func battle(mission: String) -> bool:
	var ids=M.available(world).map(func(u):return int(u.id))
	if not M.deploy(world,mission,ids):error="deploy "+mission;return false
	for i in range(4000):
		M.step(world)
		if not world.kingdom.military.battle.result.is_empty():break
	if world.kingdom.military.battle.result!="won":error="battle "+mission+" "+str(world.kingdom.military.battle);return false
	return M.return_home(world)
func complete(seed: int=2026) -> bool:
	if not defended(seed) or not battle("raid") or not K.claim(world,"main_19"):return false
	M.formation(world,"assault")
	if not battle("camp") or not K.claim(world,"main_20"):error+=" quest20";return false
	return true
