extends RefCounted
const BASE=preload("res://scripts/iron_hills_map.gd")
const SIZE=Vector2(960,1440)
const START=Vector2(240,1260)
const LANDMARK=Vector2(640,900)
const ROAD=Vector2(300,610)
const CRYSTAL=Vector2(780,530)
const NODES={"crystal":{"point":CRYSTAL,"resource":"desert_crystal","amount":6}}
const WALLS=[Rect2(0,0,960,18),Rect2(0,1422,960,18),Rect2(0,0,18,1440),Rect2(942,0,18,1440),Rect2(40,910,120,230),Rect2(340,1010,160,110),Rect2(450,700,100,100),Rect2(600,710,180,95),Rect2(40,360,140,220),Rect2(400,300,135,200),Rect2(760,170,170,180)]
static func trees() -> Array:return [Vector2(570,870),Vector2(780,860),Vector2(700,1030),Vector2(150,730),Vector2(800,1180)]
static func solids(_gate: bool=false) -> Array:return WALLS
static func clear(p: Vector2,_gate: bool=false,radius: float=14) -> bool:
	for r in WALLS:
		if r.grow(radius).has_point(p):return false
	return true
static func move(p: Vector2,delta: Vector2,_gate: bool=false) -> Vector2:
	var steps=maxi(1,ceili(delta.length()/4));var part=delta/steps
	for i in range(steps):
		if clear(p+Vector2(part.x,0)):p.x+=part.x
		if clear(p+Vector2(0,part.y)):p.y+=part.y
	return p.round()
static func path(from: Vector2,to: Vector2,_gate: bool=false) -> PackedVector2Array:
	var grid=AStarGrid2D.new();grid.region=Rect2i(0,0,40,60);grid.cell_size=Vector2(24,24);grid.offset=Vector2(12,12);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
	for y in range(60):
		for x in range(40):
			if not clear(Vector2(x*24+12,y*24+12),false,17):grid.set_point_solid(Vector2i(x,y))
	var a=Vector2i(from/24);var b=Vector2i(to/24)
	if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b) or not clear(to):return PackedVector2Array()
	grid.set_point_solid(a,false)
	return grid.get_point_path(a,b)
