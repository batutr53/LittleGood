extends RefCounted
const A=preload("res://scripts/adventure.gd")
const D=preload("res://scripts/ashen_desert.gd")
const MAP=preload("res://scripts/ashen_desert_map.gd")
var base=preload("res://scripts/regional_progression_probe.gd").new()
var driver=preload("res://scripts/regional_progression_probe.gd").new()
var world: Dictionary
var error=""
func travel(target: Vector2) -> bool:
	var r=world.kingdom.adventure.run;var path=MAP.path(Vector2(r.x,r.y),target)
	if path.is_empty():error="desert path "+str(target);return false
	for dest in path:
		for i in range(100):
			if Vector2(r.x,r.y).distance_to(dest)<13:break
			A.step(world,driver.command(dest))
			if world.kingdom.adventure.hero.defeated:error="desert travel defeat";return false
	return Vector2(r.x,r.y).distance_to(target)<80
func prepare(seed: int=42) -> bool:
	if not base.explore(seed):error=base.error;return false
	world=base.world;driver.world=world
	return A.enter(world,true,"ashen_desert")
func explore() -> bool:
	if not travel(MAP.LANDMARK) or A.interact(world)!="oasis":error="oasis "+error;return false
	var r=world.kingdom.adventure.run
	for e in r.enemies:
		if not travel(Vector2(e.x,e.y)) or not driver.fight(e):error="desert fight "+driver.error;return false
	for l in r.loot:
		if not l.taken and (not travel(Vector2(l.x,l.y)) or not A.pickup(world,l)):error="desert loot "+str(l)+" stock="+str(world.kingdom.stock.get(l.resource,0));return false
	if not travel(MAP.CRYSTAL) or A.interact(world)!="crystal":error="crystal "+error;return false
	if not travel(MAP.ROAD) or A.interact(world)!="road":error="road "+error;return false
	return A.exit(world) and D.register(world) and preload("res://scripts/kingdom.gd").claim(world,"main_22")
func complete(seed: int=42) -> bool:return prepare(seed) and explore()
