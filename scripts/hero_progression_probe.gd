extends RefCounted
const H=preload("res://scripts/hero.gd")
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
var base=preload("res://scripts/industry_progression_probe.gd").new()
var world: Dictionary
func armed(seed: int=2026) -> bool:
	if not base.through_iron_age(seed):return false
	world=base.world
	if not H.enable(world) or not H.recruit(world,"Lale"):return false
	var mine=world.kingdom.buildings.filter(func(b):return b.kind=="mine")[0];var furnace=world.kingdom.buildings.filter(func(b):return b.kind=="furnace")[0];var forge=world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	K.assign(world,int(world.kingdom.workers[2].id),int(mine.id))
	if not base.wait_stock("ore",8):return false
	K.assign(world,int(world.kingdom.workers[2].id),int(furnace.id));K.assign(world,int(world.kingdom.workers[3].id),int(forge.id))
	if not base.wait_stock("iron",2) or not I.queue(world,"iron_sword",int(forge.id)):return false
	for i in range(20):base.driver.step()
	var sword=world.kingdom.industry.items.filter(func(item):return item.recipe=="iron_sword")
	return not sword.is_empty() and H.equip(world,"weapon",int(sword[0].id)) and K.claim(world,"main_11")
