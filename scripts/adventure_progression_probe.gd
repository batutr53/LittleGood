extends RefCounted
const A=preload("res://scripts/adventure.gd")
const H=preload("res://scripts/hero.gd")
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
const MAP=preload("res://scripts/wildwood_map.gd")
var foundation=preload("res://scripts/hero_progression_probe.gd").new()
var world: Dictionary
var steps=0
var error=""
func command(target: Vector2,attack: bool=true) -> Dictionary:
	var r=world.kingdom.adventure.run;var p=Vector2(r.x,r.y);var direction=(target-p).normalized() if p.distance_to(target)>8 else Vector2.ZERO
	var input={"move":direction,"attack":attack,"skill":attack,"heal":world.kingdom.adventure.hero.hp<H.stats(world).health}
	for e in r.enemies:
		if e.hp>0 and e.state=="windup" and e.timer<=250:
			var danger=Vector2(e.aimx,e.aimy) if e.kind=="spider" else Vector2(e.x,e.y)
			if p.distance_to(danger)<110:input.move=(p-danger).normalized();input.dodge=true
	return input
func tick(input: Dictionary) -> void:A.step(world,input);steps+=1
func travel(target: Vector2) -> bool:
	var r=world.kingdom.adventure.run;var path=MAP.path(Vector2(r.x,r.y),target,world.kingdom.claimed.size()<14)
	if path.is_empty():error="no path";return false
	for point in path:
		for i in range(90):
			if Vector2(r.x,r.y).distance_to(point)<12:break
			tick(command(point))
			if world.kingdom.adventure.hero.defeated:error="defeat while traveling";return false
	return Vector2(r.x,r.y).distance_to(target)<85
func fight(e: Dictionary,allow_hit: bool=false) -> bool:
	var r=world.kingdom.adventure.run
	for i in range(3000):
		if e.hp<=0:return true
		var p=Vector2(r.x,r.y);var ep=Vector2(e.x,e.y)
		var input=command(ep)
		if p.distance_to(ep)<60:input.move=Vector2.ZERO
		if allow_hit and world.kingdom.adventure.hero.hp==H.stats(world).health:input={"move":Vector2.ZERO} if p.distance_to(ep)<60 else {"move":(ep-p).normalized()}
		tick(input)
		if world.kingdom.adventure.hero.defeated:error="combat defeat";return false
	error="combat timeout";return false
func pickups() -> void:
	var r=world.kingdom.adventure.run
	for l in r.loot:
		if not l.taken:
			travel(Vector2(l.x,l.y));A.pickup(world,l)
func hunt(seed: int=2026) -> bool:
	if not foundation.armed(seed):error="hero foundation";return false
	world=foundation.world
	if not A.enter(world) or not travel(MAP.LANDMARK):error="landmark route";return false
	A.interact(world)
	if not A.exit(world) or not K.claim(world,"main_12"):error="quest12";return false
	A.enter(world)
	if not travel(MAP.HERBS):error="herbs route";return false
	A.interact(world);A.interact(world)
	for e in world.kingdom.adventure.run.enemies:
		if not travel(Vector2(e.x,e.y)) or not fight(e,H.progress(world,"healed")==0):return false
		pickups()
	if not A.exit(world) or not K.claim(world,"main_13"):error="quest13";return false
	return true
func craft(recipe: String) -> bool:
	var data=I.recipes()[recipe];var base=foundation.base
	var mine=world.kingdom.buildings.filter(func(b):return b.kind=="mine")[0];var furnace=world.kingdom.buildings.filter(func(b):return b.kind=="furnace")[0];var forge=world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
	var required=float(data.cost.get("iron",0))
	if world.kingdom.stock.iron<required*1000:
		K.assign(world,int(world.kingdom.workers[2].id),int(mine.id))
		if not base.wait_stock("ore",required*2+2):return false
		K.assign(world,int(world.kingdom.workers[2].id),int(furnace.id))
		if not base.wait_stock("iron",required):return false
	K.assign(world,int(world.kingdom.workers[3].id),int(forge.id))
	if not I.queue(world,recipe,int(forge.id)):error="recipe "+recipe;return false
	for i in range(20):base.driver.step()
	return true
func equipped_upgrade(seed: int=2026) -> bool:
	if not hunt(seed) or not craft("thornblade"):return false
	var item=world.kingdom.industry.items.filter(func(owned):return owned.recipe=="thornblade")[0]
	if not H.equip(world,"weapon",int(item.id)) or not K.claim(world,"main_14"):error="quest14";return false
	if not craft("reinforced_shield"):return false
	item=world.kingdom.industry.items.filter(func(owned):return owned.recipe=="reinforced_shield")[0];return H.equip(world,"shield",int(item.id))
