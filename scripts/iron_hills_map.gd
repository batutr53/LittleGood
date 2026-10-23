extends RefCounted
const SIZE=Vector2(960,1440)
const START=Vector2(240,1260)
const LANDMARK=Vector2(480,360)
const NODES={"ore":{"point":Vector2(775,700),"resource":"ore","amount":6},"stone":{"point":Vector2(250,970),"resource":"stone","amount":5}}
static func trees() -> Array:return [Vector2(110,1140),Vector2(825,1090),Vector2(145,680),Vector2(790,350),Vector2(180,350)]
static func solids(_gate: bool=false) -> Array:
	return [Rect2(0,0,960,18),Rect2(0,1422,960,18),Rect2(0,0,18,1440),Rect2(942,0,18,1440),Rect2(20,40,300,180),Rect2(670,50,270,200),Rect2(20,720,150,300),Rect2(370,750,110,220),Rect2(630,1120,310,140),Rect2(260,390,135,190),Rect2(660,440,280,120)]
static func clear(p: Vector2,gate: bool=false,radius: float=14) -> bool:
	for r in solids(gate):
		if r.grow(radius).has_point(p):return false
	return true
static func move(p: Vector2,delta: Vector2,gate: bool=false) -> Vector2:
	var steps=maxi(1,ceili(delta.length()/4));var part=delta/steps
	for i in range(steps):
		if clear(p+Vector2(part.x,0),gate):p.x+=part.x
		if clear(p+Vector2(0,part.y),gate):p.y+=part.y
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
