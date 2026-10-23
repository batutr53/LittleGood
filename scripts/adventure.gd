extends RefCounted
const H=preload("res://scripts/hero.gd")
const I=preload("res://scripts/industry.gd")
const MAP=preload("res://scripts/wildwood_map.gd")
const STEP=50
static func enter(w: Dictionary,home_paused: bool=false) -> bool:
	if not H.writable(w) or w.kingdom.claimed.size()<11 or H.progress(w,"hero_armed")==0 or w.kingdom.adventure.hero.defeated:return false
	var a=w.kingdom.adventure
	if a.run.is_empty():
		a.run={"id":int(a.next_run),"active":true,"home_paused":home_paused,"clock":0,"x":240,"y":1260,"facing":[0,-1000],"invulnerable":0,"swing":0,"enemies":[],"loot":[],"cargo":{},"picked":0,"chest":false,"harvest":false,"landmark":false,"rng":str(int(w.seed)+int(a.next_run)*7919)};a.next_run+=1
	else:a.run.active=true;a.run.home_paused=home_paused
	return true
static func exit(w: Dictionary) -> bool:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return false
	var a=w.kingdom.adventure;var r=a.run
	for key in r.cargo:w.kingdom.stock[key]+=int(r.cargo[key])*1000
	H.event(w,"banked",int(r.picked));r.cargo={};r.picked=0;r.active=false
	H.event(w,"returned");a.hero.hp=int(H.stats(w).health);a.hero.defeated=false
	for key in a.hero.cooldowns:a.hero.cooldowns[key]=0
	r.x=240;r.y=1260;return true
static func move_actor(w: Dictionary,id: int,p: Vector2,delta: Vector2,mover: Callable) -> Vector2:
	return mover.call(id,p,delta) if mover.is_valid() else MAP.move(p,delta,w.kingdom.claimed.size()<14)
static func step(w: Dictionary,input: Dictionary,mover: Callable=Callable()) -> Array:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return []
	var a=w.kingdom.adventure;var r=a.run;var h=a.hero;r.clock+=STEP
	for key in h.cooldowns:h.cooldowns[key]=maxi(0,int(h.cooldowns[key])-STEP)
	r.invulnerable=maxi(0,int(r.invulnerable)-STEP);r.swing=maxi(0,int(r.swing)-STEP)
	if h.defeated:return []
	var direction=Vector2(input.get("move",Vector2.ZERO)).limit_length(1)
	if direction.length()>.1:r.facing=[roundi(direction.x*1000),roundi(direction.y*1000)]
	var p=move_actor(w,0,Vector2(r.x,r.y),direction*int(H.stats(w).speed)*.05,mover);r.x=roundi(p.x);r.y=roundi(p.y)
	return []
static func interact(w: Dictionary) -> String:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return ""
	var r=w.kingdom.adventure.run;var p=Vector2(r.x,r.y)
	if p.distance_to(MAP.LANDMARK)<85 and not r.landmark:r.landmark=true;H.event(w,"landmark");return "landmark"
	return ""
static func normalize(w: Dictionary) -> void:
	var r=w.kingdom.adventure.run
	if r.is_empty():return
	for key in ["id","clock","x","y","invulnerable","swing","picked"]:r[key]=int(r[key])
	for i in range(2):r.facing[i]=int(r.facing[i])
	for key in r.cargo:r.cargo[key]=int(r.cargo[key])
static func validate(w: Dictionary) -> bool:
	var r=w.kingdom.adventure.run
	if r.is_empty():return true
	var C=preload("res://scripts/cosmetics.gd")
	if not C.shape(r,["id","active","home_paused","clock","x","y","facing","invulnerable","swing","enemies","loot","cargo","picked","chest","harvest","landmark","rng"]):return false
	for key in ["active","home_paused","chest","harvest","landmark"]:
		if not r[key] is bool:return false
	for key in ["id","clock","x","y","invulnerable","swing","picked"]:
		if not C.number(r[key],0,100000000,true):return false
	if r.x>960 or r.y>1440 or not r.facing is Array or r.facing.size()!=2 or not r.rng is String or not r.rng.is_valid_int() or not r.cargo is Dictionary or r.cargo.size()>9:return false
	for n in r.facing:
		if not C.number(n,-1000,1000,true):return false
	for key in r.cargo:
		if not key in w.kingdom.stock or not C.number(r.cargo[key],0,1000,true):return false
	return r.enemies is Array and r.enemies.is_empty() and r.loot is Array and r.loot.is_empty()
