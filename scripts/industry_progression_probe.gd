extends RefCounted
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
var driver=preload("res://scripts/kingdom_progression_probe.gd").new()
var world: Dictionary
var error=""
func wait_stock(resource: String,units: float,limit: int=600) -> bool:
	for i in range(limit):
		if int(world.kingdom.stock[resource])>=roundi(units*K.SCALE):return true
		driver.step()
	error="insufficient "+resource;return false
func forge_stage(seed: int=2026) -> bool:
	driver.start(seed)
	if not driver.through_first_flame():error="chapter1";return false
	world=driver.world
	if not I.enable(world):error="chapter2 activation";return false
	var quarry=driver.build("quarry")
	if quarry<0 or not K.assign(world,int(world.kingdom.workers[2].id),quarry) or not driver.finish_current():error="quarry";return false
	var mine=driver.build("mine")
	if mine<0 or not K.assign(world,int(world.kingdom.workers[2].id),mine) or not driver.finish_current():error="mine";return false
	if not wait_stock("ore",12):return false
	var furnace=driver.build("furnace")
	if furnace<0 or not K.assign(world,int(world.kingdom.workers[2].id),furnace) or not driver.finish_current():error="furnace";return false
	if not wait_stock("iron",6):return false
	var forge=driver.build("forge")
	if forge<0 or not K.assign(world,int(world.kingdom.workers[2].id),forge):error="forge";return false
	return true
func complete_from_forge() -> bool:
	var forge=world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	if not I.queue(world,"forest_axe",int(forge.id)) or not I.queue(world,"iron_pick",int(forge.id)):error="craft queue";return false
	if not driver.finish_current():error="crafting";return false
	var items=world.kingdom.industry.items
	if not I.equip(world,int(world.kingdom.workers[0].id),int(items[0].id)) or not I.equip(world,int(world.kingdom.workers[2].id),int(items[1].id)):error="equipment";return false
	var mine=world.kingdom.buildings.filter(func(b):return b.kind=="mine")[0]
	if not K.assign(world,int(world.kingdom.workers[2].id),int(mine.id)) or not driver.finish_current():error="tool work";return false
	return world.kingdom.claimed.size()==10 and K.level(world)==10 and K.current(world).is_empty()
func through_iron_age(seed: int=2026) -> bool:
	return forge_stage(seed) and complete_from_forge()
