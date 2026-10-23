extends RefCounted
const SIZE=Vector2(960,1440)
const START=Vector2(240,1260)
const LANDMARK=Vector2(480,840)
const CHEST=Vector2(540,540)
const HERBS=Vector2(340,920)
const BOSS=Vector2(720,230)
static func trees() -> Array:
	var points=[]
	for y in range(120,1380,140):
		for x in range(80,920,140):
			if x in [220,500] or (y>1100 and x<400) or Vector2(x,y).distance_to(BOSS)<150 or Vector2(x,y).distance_to(LANDMARK)<110:continue
			if x<310 and y in [540,680]:continue
			points.append(Vector2(x+sin(x+y)*15,y))
	return points
static func solids(gate: bool=false) -> Array:
	var list=[Rect2(0,0,960,18),Rect2(0,1422,960,18),Rect2(0,0,18,1440),Rect2(942,0,18,1440),Rect2(20,500,280,300),Rect2(590,980,140,120),Rect2(90,880,80,100),Rect2(360,300,140,220)]
	for p in trees():list.append(Rect2(p-Vector2(8,9),Vector2(16,18)))
	if gate:list.append(Rect2(560,350,382,28))
	return list
static func clear(p: Vector2,gate: bool=false,radius: float=14) -> bool:
	for r in solids(gate):
		if r.grow(radius).has_point(p):return false
	return true
static func move(p: Vector2,delta: Vector2,gate: bool=false) -> Vector2:
	var steps=maxi(1,ceili(delta.length()/4));var part=delta/steps
	for i in range(steps):
		if clear(p+Vector2(part.x,0),gate):p.x+=part.x
		if clear(p+Vector2(0,part.y),gate):p.y+=part.y
	return Vector2(roundf(p.x),roundf(p.y))
static func path(from: Vector2,to: Vector2,gate: bool=false) -> PackedVector2Array:
	var grid=AStarGrid2D.new();grid.region=Rect2i(0,0,40,60);grid.cell_size=Vector2(24,24);grid.offset=Vector2(12,12);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
	for y in range(60):
		for x in range(40):
			if not clear(Vector2(x*24+12,y*24+12),gate,17):grid.set_point_solid(Vector2i(x,y))
	var a=Vector2i(from/24);var b=Vector2i(to/24)
	if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b):return PackedVector2Array()
	grid.set_point_solid(a,false);grid.set_point_solid(b,false)
	return grid.get_point_path(a,b)
