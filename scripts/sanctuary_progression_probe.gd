extends RefCounted
const A=preload("res://scripts/adventure.gd")
const MAP=preload("res://scripts/sanctuary_map.gd")
var base=preload("res://scripts/desert_progression_probe.gd").new()
var driver=preload("res://scripts/regional_progression_probe.gd").new()
var world: Dictionary
var error=""
func travel(target: Vector2) -> bool:
	var r=world.kingdom.adventure.run;var route=MAP.path(Vector2(r.x,r.y),target,r)
	if route.is_empty():error="sanctuary path "+str(target);return false
	for point in route:
		for i in range(100):
			if Vector2(r.x,r.y).distance_to(point)<13:break
			A.step(world,driver.command(point))
			if world.kingdom.adventure.hero.defeated:error="sanctuary travel defeat";return false
	if Vector2(r.x,r.y).distance_to(target)>=70:error="sanctuary route blocked "+str(target);return false
	return true
func inspect(target: Vector2,expected: String) -> bool:
	if not travel(target):return false
	var result=A.interact(world)
	if result!=expected:error="interaction "+expected+" received "+result;return false
	return true
func explore() -> bool:
	driver.world=world
	if not A.enter(world,true,"sanctuary"):error="sanctuary entry";return false
	if not inspect(MAP.INSCRIPTION,"inscription"):return false
	for p in MAP.PLATES:
		if not travel(p):return false
	for i in range(3):
		if not inspect(MAP.SWITCHES[i],"runes_open" if i==2 else "switch"):return false
	var r=world.kingdom.adventure.run
	for e in r.enemies:
		if e.hp>0 and (not travel(Vector2(e.x,e.y)) or not driver.fight(e)):error+=" fight "+driver.error;return false
	if not inspect(MAP.RELIC,"relic"):return false
	if not inspect(MAP.SECRET,"secret") or not inspect(MAP.LORE,"lore") or not inspect(MAP.TREASURE,"treasury"):return false
	for loot in r.loot:
		if not loot.taken and (not travel(Vector2(loot.x,loot.y)) or not A.pickup(world,loot)):error="sanctuary pickup";return false
	return A.exit(world) and preload("res://scripts/sanctuary.gd").research(world)
func complete(seed: int=42) -> bool:
	if not base.complete(seed):error=base.error;return false
	world=base.world
	if not explore():return false
	var crafter=base.base.base.base.base
	for recipe in preload("res://scripts/sanctuary.gd").GEAR:
		if not crafter.craft(recipe):error="ancient forging "+crafter.error;return false
		var item=world.kingdom.industry.items.filter(func(i):return i.recipe==recipe)[0]
		if not preload("res://scripts/hero.gd").equip(world,preload("res://scripts/industry.gd").recipes()[recipe].category,int(item.id)):error="ancient equip";return false
	if not preload("res://scripts/kingdom.gd").claim(world,"main_23"):error="quest23";return false
	return true
