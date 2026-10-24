extends RefCounted
const SIZE=Vector2(960,1440)
const START=Vector2(240,1260)
const INSCRIPTION=Vector2(240,1190)
const PLATES=[Vector2(650,1300),Vector2(800,1130)]
const SWITCHES=[Vector2(610,780),Vector2(820,780),Vector2(820,560)]
const SECRET=Vector2(240,1015)
const TREASURE=Vector2(240,760)
const LORE=Vector2(240,600)
const RELIC=Vector2(210,185)
const DOORS={"stone":Rect2(650,960,170,24),"runes":Rect2(650,460,170,24),"secret":Rect2(170,960,160,24),"relic":Rect2(350,300,24,120)}
const HAZARDS={"spikes":{"rect":Rect2(590,1040,240,65),"period":4000,"offset":0,"warning":1000,"active":1800,"end":2050,"damage":16},"runes":{"rect":Rect2(610,515,210,65),"period":5000,"offset":750,"warning":1000,"active":1900,"end":2200,"damage":20}}
const WALLS=[Rect2(0,0,960,18),Rect2(0,1422,960,18),Rect2(0,0,18,1440),Rect2(942,0,18,1440),Rect2(465,480,26,700),Rect2(465,1295,26,130),Rect2(20,960,150,24),Rect2(330,960,135,24),Rect2(491,960,159,24),Rect2(820,960,125,24),Rect2(20,460,630,24),Rect2(820,460,125,24),Rect2(350,20,24,280),Rect2(350,420,24,40),Rect2(600,650,75,65),Rect2(710,195,65,70)]
static func trees() -> Array:return []
static func solids(_gate: bool=false) -> Array:return WALLS
static func doors(r: Dictionary) -> Array:
	var list=[]
	if r.mechanisms.plates<2:list.append("stone")
	if r.mechanisms.switches<3:list.append("runes")
	if not r.mechanisms.secret:list.append("secret")
	if r.enemies.any(func(e):return e.kind=="sunward_warden" and e.hp>0):list.append("relic")
	return list
static func clear(p: Vector2,r: Dictionary,radius: float=14) -> bool:
	for wall in WALLS:
		if wall.grow(radius).has_point(p):return false
	for key in doors(r):
		if DOORS[key].grow(radius).has_point(p):return false
	return true
static func move(p: Vector2,delta: Vector2,r: Dictionary) -> Vector2:
	var steps=maxi(1,ceili(delta.length()/4));var part=delta/steps
	for i in range(steps):
		if clear(p+Vector2(part.x,0),r):p.x+=part.x
		if clear(p+Vector2(0,part.y),r):p.y+=part.y
	return p.round()
static func path(from: Vector2,to: Vector2,r: Dictionary) -> PackedVector2Array:
	var grid=AStarGrid2D.new();grid.region=Rect2i(0,0,40,60);grid.cell_size=Vector2(24,24);grid.offset=Vector2(12,12);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
	for y in range(60):
		for x in range(40):
			if not clear(Vector2(x*24+12,y*24+12),r,17):grid.set_point_solid(Vector2i(x,y))
	var a=Vector2i(from/24);var b=Vector2i(to/24)
	if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b) or not clear(to,r):return PackedVector2Array()
	grid.set_point_solid(a,false)
	# Actors can stand beside an obstacle where the containing cell's centre is
	# blocked. Route to a nearby reachable cell within interaction/melee range.
	var goals=[]
	for y in range(b.y-2,b.y+3):
		for x in range(b.x-2,b.x+3):
			var cell=Vector2i(x,y);var centre=Vector2(x*24+12,y*24+12)
			if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell) and centre.distance_to(to)<49:goals.append(cell)
	goals.sort_custom(func(c,d):return grid.get_point_position(c).distance_squared_to(to)<grid.get_point_position(d).distance_squared_to(to))
	for goal in goals:
		var route=grid.get_point_path(a,goal)
		if not route.is_empty():return route
	return PackedVector2Array()
