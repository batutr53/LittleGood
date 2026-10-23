extends RefCounted
const A=preload("res://scripts/adventure.gd")
const R=preload("res://scripts/regions.gd")
const MAP=preload("res://scripts/iron_hills_map.gd")
var base=preload("res://scripts/trade_progression_probe.gd").new()
var world: Dictionary
var steps=0
var error=""
func tick(input: Dictionary) -> void:A.step(world,input);steps+=1
func command(target: Vector2) -> Dictionary:
	var p=Vector2(world.kingdom.adventure.run.x,world.kingdom.adventure.run.y)
	var input={"move":(target-p).normalized() if p.distance_to(target)>10 else Vector2.ZERO,"attack":true,"skill":true,"heal":true}
	for e in world.kingdom.adventure.run.enemies:
		if e.hp>0 and e.state=="windup" and e.timer<=250 and p.distance_to(Vector2(e.x,e.y))<130:
			input.move=(p-Vector2(e.x,e.y)).normalized();input.dodge=true
	return input
func travel(target: Vector2) -> bool:
	var r=world.kingdom.adventure.run;var path=MAP.path(Vector2(r.x,r.y),target)
	if path.is_empty():error="no regional path "+str(target);return false
	for point in path:
		for i in range(90):
			if Vector2(r.x,r.y).distance_to(point)<13:break
			tick(command(point))
			if world.kingdom.adventure.hero.defeated:error="defeat while exploring";return false
	return Vector2(r.x,r.y).distance_to(target)<70
func fight(e: Dictionary) -> bool:
	for i in range(2400):
		if e.hp<=0:return true
		var p=Vector2(world.kingdom.adventure.run.x,world.kingdom.adventure.run.y);var target=Vector2(e.x,e.y)
		var input=command(target)
		if p.distance_to(target)<59 and not input.get("dodge",false):input.move=Vector2.ZERO
		tick(input)
		if world.kingdom.adventure.hero.defeated:error="regional combat defeat";return false
	error="regional fight timeout";return false
func explore(seed: int=42) -> bool:
	if not base.complete(seed):error=base.error;return false
	world=base.world
	if not A.enter(world,true,"iron_hills"):error="regional entry";return false
	for id in MAP.NODES:
		if not travel(MAP.NODES[id].point):return false
		if A.interact(world)!="mineral":error="gather "+id;return false
	for e in world.kingdom.adventure.run.enemies:
		if not travel(Vector2(e.x,e.y)) or not fight(e):return false
	for l in world.kingdom.adventure.run.loot:
		if not l.taken:
			if not travel(Vector2(l.x,l.y)) or not A.pickup(world,l):error="loot";return false
	if not travel(MAP.LANDMARK) or A.interact(world)!="mine":error="mine";return false
	return A.exit(world)
