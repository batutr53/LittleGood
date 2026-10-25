extends Node2D

var origin = Vector2(520, 420)
var world: Dictionary = {}
var pan = Vector2.ZERO
var zoom = 0.88
var display_pan = Vector2.ZERO
var display_zoom = 0.88
var time = 0.0
var selected = -1
var selected_creature = -1
var selected_identity = -1
var effects: Array = []
var creature_positions: Dictionary = {}
var low_quality = false
var world_root: Node2D
var terrain: TerrainSurface
var inhabitants: WorldInhabitants
var scenery_signature = ""
var update_accumulator = 0.0
var terrain_signature = ""
var frame_cpu_ms = 0.0
var foreground_cpu_ms = 0.0
var decoration_cells: Array = []
var cosmetic_layer
var kingdom_layer
var layout_size = Vector2.ZERO

func _ready() -> void:
	update_landscape_layout()
	world_root = Node2D.new()
	add_child(world_root)
	terrain = TerrainSurface.new()
	terrain.view = self
	world_root.add_child(terrain)
	inhabitants = WorldInhabitants.new()
	inhabitants.view = self
	world_root.add_child(inhabitants)
	cosmetic_layer=preload("res://scripts/cosmetic_renderer.gd").new()
	cosmetic_layer.view=self
	world_root.add_child(cosmetic_layer)
	kingdom_layer=preload("res://scripts/kingdom_renderer.gd").new();kingdom_layer.view=self;world_root.add_child(kingdom_layer)

func update_landscape_layout() -> void:
	var viewport=get_viewport_rect().size
	if viewport==layout_size:return
	layout_size=viewport
	# The HUD reserves narrow action rails. Keep the whole miniature planet in the open centre,
	# rather than preserving the former portrait bottom-weighted camera.
	var left=clampf(viewport.y*.115,58.0,92.0)
	var right=clampf(viewport.y*.47,235.0,340.0)
	origin=Vector2(left+(viewport.x-left-right)*.5,viewport.y*.58)

func project(c: Dictionary) -> Vector2:
	return Vector2((c.x - c.y) * 30, (c.x + c.y - 16) * 15 - c.height * 42)

func to_screen(p: Vector2) -> Vector2:
	return origin + display_pan + p * display_zoom

func screen_point(c: Dictionary) -> Vector2:
	return to_screen(project(c))

func zoom_at(anchor: Vector2, factor: float) -> void:
	var old = zoom
	zoom = clampf(zoom * factor, .55, 1.8)
	pan = (pan + origin - anchor) * zoom / old - origin + anchor

func pick(pos: Vector2) -> int:
	var result = -1
	var best = INF
	for i in range(world.get("cells", []).size()):
		var d = (screen_point(world.cells[i]) - pos) / Vector2(1, .5)
		if d.length() < 33 * display_zoom and d.length() < best:
			best = d.length()
			result = i
	return result

func invalidate() -> void:
	scenery_signature = ""
	terrain_signature = ""
	decoration_cells.clear()
	selected_creature = -1
	selected_identity = -1
	if cosmetic_layer!=null:cosmetic_layer.signature=""

func invalidate_cosmetics() -> void:
	# Appearance changes do not change terrain geometry or creature selection.
	scenery_signature=""
	if cosmetic_layer!=null:cosmetic_layer.signature=""
	queue_redraw()

func focus_creature(index: int) -> void:
	selected_creature = index
	selected_identity = int(world.creatures[index].identity)
	selected = int(world.creatures[index].cell)

func reconcile_selection() -> void:
	if selected_identity < 0: return
	selected_creature = -1
	for i in range(world.creatures.size()):
		if int(world.creatures[i].identity) == selected_identity:
			selected_creature = i
			selected = int(world.creatures[i].cell)
			return
	selected_identity = -1

func set_quality(economy: bool) -> void:
	low_quality = economy
	Engine.max_fps = 30 if economy else 60
	if OS.has_feature("mobile"):
		# Render the existing 720-wide composition once, rather than shading at
		# native phone resolution. Smooth retains full effects and its 60-FPS cap.
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	invalidate()

func _process(delta: float) -> void:
	var started = Time.get_ticks_usec()
	update_landscape_layout()
	time += delta
	var weight = 1 - exp(-delta * 14)
	display_pan = display_pan.lerp(pan, weight)
	display_zoom = lerpf(display_zoom, zoom, weight)
	world_root.position = origin + display_pan
	world_root.scale = Vector2.ONE * display_zoom
	if not world.is_empty():
		update_accumulator += delta
		if update_accumulator > .3 or scenery_signature.is_empty():
			update_accumulator = 0
			var signature = str(world.seed) + ":" + str(world.xp) + ":" + str(world.tick)
			if signature != scenery_signature:
				scenery_signature = signature
				# Most cells have no foreground decoration. Index changed state once,
				# rather than dispatching five Dictionary lookups per tile per frame.
				decoration_cells.clear()
				for c in world.cells:
					if c.get("canopy_arch",false) or c.get("reed_shelter",false) or c.get("spring",false) or c.get("meadow",false) or int(c.get("grove_until",0))>int(world.tick): decoration_cells.append(c)
				# Topology gifts update immediately; slow vegetation tint refreshes every 8 ticks.
				var geometry = str(world.seed) + ":" + str(int(world.tick) / 8)
				for c in world.cells: geometry += ":%d,%d" % [int(c.biome), int(c.height * 1000)]
				if geometry != terrain_signature:
					terrain_signature = geometry
					terrain.rebuild(world)
				inhabitants.sync(world)
				cosmetic_layer.sync(world)
				kingdom_layer.sync(world)
				reconcile_selection()
		inhabitants.animate(world, delta)
		cosmetic_layer.animate(delta)
		kingdom_layer.animate(delta)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].age += delta
		if effects[i].age > 1.6: effects.remove_at(i)
	queue_redraw()
	frame_cpu_ms = (Time.get_ticks_usec()-started)/1000.0

func ellipse(p: Vector2, radius: float, color: Color, ratio: float = .45) -> void:
	draw_set_transform(p, 0, Vector2(1, ratio))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if world.is_empty(): return
	var appearance=world.get("wardrobe",{})
	var look=appearance.get("theme","enchanted")
	var hue={"enchanted":Color("b9d8a5"),"crystal":Color("b8d8ed"),"celestial":Color("c4c1ec"),"ancient":Color("e6c992")}.get(look,Color.WHITE)
	var moon=Vector2(570,330)
	draw_circle(moon,25,hue*Color(1,1,1,.16))
	draw_circle(moon,17,hue*Color(1,1,1,.32))
	if look=="celestial" or appearance.get("frame","")=="orbit":
		draw_set_transform(origin+display_pan+Vector2(0,22),-.14,Vector2(1,.44))
		draw_arc(Vector2.ZERO,325*display_zoom,0,TAU,64,Color(hue,.3),1.4,true)
		draw_set_transform(Vector2.ZERO)
	if look=="crystal":
		for i in range(5):
			var point=Vector2(100+i*122,340+sin(time*.3+i)*22)
			draw_colored_polygon(PackedVector2Array([point+Vector2(0,-8),point+Vector2(5,0),point+Vector2(0,8),point+Vector2(-5,0)]),Color(hue,.32))
	if look=="ancient":
		var motes=PackedVector2Array()
		for i in range(9):
			var point=Vector2(90+i*69,350+sin(time*.2+i)*20)
			motes.append(point-Vector2(1,0));motes.append(point+Vector2(1,0))
		draw_multiline(motes,Color(hue,.5),1.5,false)
	if look=="celestial" or appearance.get("sky","")=="comets":
		var stars=PackedVector2Array()
		for i in range(14):
			var point=Vector2(40+fmod(i*57.3,650),290+fmod(i*34.7,200))
			stars.append(point-Vector2(1+sin(time*.7+i)*.4,0));stars.append(point+Vector2(1,0))
		draw_multiline(stars,Color(hue,.55),1.4,false)
	if appearance.get("sky","")=="aurora":
		for band in range(2):
			var points=PackedVector2Array()
			for i in range(20):points.append(Vector2(i*38,330+band*18+sin(i*.25+time*.1)*27))
			draw_polyline(points,Color(.55,.8,.73,.09),10,true)
	if int(world.get("theme", 0)) != 0: draw_rect(Rect2(0, 0, 720, 1280), Color(.16, .15, .24, .65))
	ellipse(origin + display_pan + Vector2(0, 100) * display_zoom, 230 * display_zoom, Color(.02, .08, .1, .2), .35)
	for i in range(16 if not low_quality else 6):
		var p = Vector2(fmod(i * 139.7 + sin(time * .2 + i) * 12, 720), 260 + fmod(i * 83.3 - time * (2 + i % 3), 670))
		draw_circle(p, 1.2, Color(.95, .84, .55, .13 + sin(time + i) * .08))
	if selected >= 0 and selected < world.cells.size():
		var p = screen_point(world.cells[selected])
		ellipse(p, 19 * display_zoom, Color(1, .9, .65, .10))
		draw_set_transform(p, 0, Vector2(display_zoom, display_zoom * .5))
		draw_arc(Vector2.ZERO, 24 + sin(time * 3) * 1.3, 0, TAU, 36, Color("f6dea3"), 1.8, true)
		draw_set_transform(Vector2.ZERO)

func draw_foreground(canvas: Node2D) -> void:
	if world.is_empty(): return
	var started = Time.get_ticks_usec()
	var realm=get_parent().realm_ui
	if realm!=null and realm.active and realm.cell>=0:
		var point=screen_point(world.cells[realm.cell]);var tint=Color(.7,1,.7,.65) if realm.valid(realm.cell) else Color(1,.4,.3,.6)
		canvas.draw_arc(point,24*display_zoom,0,TAU,24,tint,2,true)
		if realm.mode=="build":canvas.draw_texture_rect(load("res://assets/kingdom/"+realm.kind+".svg"),Rect2(point-Vector2(35,53)*display_zoom,Vector2(70,70)*display_zoom),false,tint)
	var editor=get_parent().decorator
	if editor!=null and editor.active and editor.cell>=0:
		var point=screen_point(world.cells[editor.cell])
		var valid=preload("res://scripts/cosmetics.gd").valid_place(world,editor.item,editor.cell,editor.moving)
		var color=Color(.6,1,.75,.55) if valid else Color(1,.5,.45,.5)
		var size_scale=.34 if editor.item in ["flowers","stones","banner","lanterns","statue"] else .48
		if editor.rotation>=2:size_scale*=.85
		if preload("res://scripts/cosmetics.gd").items()[editor.item].category=="settlement":point+=Vector2(27,10)*display_zoom
		var rect=Rect2(point-Vector2(64,112)*size_scale*display_zoom,Vector2(128,128)*size_scale*display_zoom)
		if editor.rotation%2==1:rect.position.x+=rect.size.x;rect.size.x=-rect.size.x
		canvas.draw_texture_rect(load("res://assets/cosmetics/"+editor.item+".svg"),rect,false,color)
		canvas.draw_arc(point,23*display_zoom,0,TAU,24,color,2,true)
	for c in decoration_cells:
		if c.get("canopy_arch",false):
			var points = PackedVector2Array()
			var p = screen_point(c)
			for j in range(13): points.append(p+Vector2(-26+j*4.3,-20-sin(j*PI/12)*25)*display_zoom)
			canvas.draw_polyline(points,Color("9fcba4"),2.5*display_zoom,true)
			for j in [2,5,8,10]: canvas.draw_circle(points[j]+Vector2(sin(time+j),0),3*display_zoom,Color("d2e4a4"))
		if c.get("reed_shelter",false):
			var p = screen_point(c)
			for j in range(4):
				var reed = p+Vector2(-14+j*8,4)*display_zoom
				canvas.draw_line(reed,reed+Vector2(sin(time+j)*2,-18)*display_zoom,Color("a4c8a4"),1.4)
				canvas.draw_circle(reed+Vector2(sin(time+j)*2,-18)*display_zoom,2,Color("efdaa5"))
		if c.get("spring", false):
			var p = screen_point(c)
			for n in range(3):
				var flow = fmod(time * .6 + n * .33, 1)
				canvas.draw_line(p + Vector2(2, -22 + flow * 28) * display_zoom, p + Vector2(2, -16 + flow * 28) * display_zoom, Color(.6, .94, 1, 1 - flow * .5), 2 * display_zoom)
		if c.get("meadow", false):
			var center = screen_point(c)
			for i in range(8 if not low_quality else 4):
				var p = center + Vector2(sin(i * 8.3 + time * .3) * 20, cos(i * 6.7) * 9 - 3) * display_zoom
				canvas.draw_circle(p, 2 * display_zoom, Color("f4cfbb"))
		if int(c.get("grove_until", 0)) > int(world.tick):
			for i in range(8 if not low_quality else 4):
				var p = screen_point(c) + Vector2(sin(time + i * 2.1) * 24, -12 + cos(time * .7 + i) * 18) * display_zoom
				canvas.draw_circle(p, 2, Color(1, .87, .4, .55 + .3 * sin(time * 2 + i)))
	if selected >= 0 and selected < world.cells.size():
		var selection = screen_point(world.cells[selected])
		canvas.draw_set_transform(selection, 0, Vector2(display_zoom, display_zoom * .5))
		canvas.draw_arc(Vector2.ZERO, 24 + sin(time * 3) * 1.3, 0, TAU, 36, Color("f6dea3"), 1.8, true)
		canvas.draw_set_transform(Vector2.ZERO)
	for s in world.settlements:
		var p = screen_point(world.cells[int(s.cell)])
		if int(s.get("trade_until",0))>int(world.tick):
			for other in world.settlements:
				if int(other.cell)>int(s.cell) and s.allies.has(int(other.cell)):
					var end = screen_point(world.cells[int(other.cell)])
					canvas.draw_dashed_line(p+Vector2(0,8),end+Vector2(0,8),Color(.83,.83,.59,.35),1.2,5)
					canvas.draw_circle(p.lerp(end,fmod(time*.18,1))+Vector2(0,4),3,Color("efda9f"))
		if s.get("landmark", false):
			canvas.draw_line(p + Vector2(31, -17) * display_zoom, p + Vector2(31, -39) * display_zoom, Color("eddca3"), 1.5)
			canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(31, -39) * display_zoom, p + Vector2(47 + sin(time * 3) * 2, -35) * display_zoom, p + Vector2(31, -30) * display_zoom]), Color("b4d9b0"))
		if selected == int(s.cell) and selected_creature < 0:
			canvas.draw_string(preload("res://assets/phase2/nunito.ttf"), p + Vector2(-80, -64), str(s.get("given_name", "")), HORIZONTAL_ALIGNMENT_CENTER, 160, 18, Color("fff0c9"))
		if s.has("friend_id"):
			var heart = p + Vector2(-10, -42 - sin(time * 2) * 2) * display_zoom
			canvas.draw_circle(heart, 3, Color("f1c4a3"))
			canvas.draw_circle(heart + Vector2(4, 0), 3, Color("f1c4a3"))
			canvas.draw_colored_polygon(PackedVector2Array([heart + Vector2(-3, 1), heart + Vector2(7, 1), heart + Vector2(2, 7)]), Color("f1c4a3"))
		for i in range(2):
			var rise = fmod(time * 7 + i * 10, 22)
			canvas.draw_circle(p + Vector2(8 + sin(time + rise * .05) * 3, -35 - rise) * display_zoom, (2 + rise * .09) * display_zoom, Color(.88, .91, .82, .22 * (1 - rise / 22)))
	for e in effects:
		var p = screen_point(world.cells[int(e.cell)])
		var t = float(e.age)
		var alpha = 1 - t / 1.6
		var color = [Color("a4e8e3"), Color("b9e8a1"), Color("f2d3a1"), Color("f3c4ad"), Color("a9dce6"), Color("f4dc94")][int(e.get("power", 0))]
		canvas.draw_set_transform(p, 0, Vector2(1, .55))
		canvas.draw_arc(Vector2.ZERO, 10 + t * 65, 0, TAU, 40, Color(color, alpha * .85), 2.2, true)
		canvas.draw_set_transform(Vector2.ZERO)
		for n in range(12 if not low_quality else 6):
			var v = Vector2.from_angle(n * TAU / 12 + t * .4) * t * 40
			canvas.draw_circle(p + v + Vector2(0, -t * 45), maxf(.1, 2 * alpha), Color(color, alpha))
	for i in range(3 if not low_quality else 1):
		var p = Vector2(fmod(time * (4 + i) + i * 295, 1100) - 160, 330 + i * 215)
		canvas.draw_set_transform(p, 0, Vector2(1, .35))
		canvas.draw_circle(Vector2.ZERO, 42, Color(.85, .94, .9, .045))
		canvas.draw_circle(Vector2(38, 8), 30, Color(.85, .94, .9, .035))
	canvas.draw_set_transform(Vector2.ZERO)
	if int(world.weather) == 1:
		var rain_lines = PackedVector2Array()
		for i in range(44 if not low_quality else 18):
			var p = Vector2(fmod(i * 137.8 + time * 35, 720), 260 + fmod(i * 79.3 + time * 310, 680))
			rain_lines.append(p);rain_lines.append(p+Vector2(-3,11))
		canvas.draw_multiline(rain_lines, Color(.7,.91,.94,.26), 1.0, false)
		for i in range(6):
			var p = origin + Vector2(sin(i * 9.7) * 210, cos(i * 11.3) * 95)
			var phase = fmod(time * .7 + i * .17, 1)
			canvas.draw_set_transform(p, 0, Vector2(1, .4))
			canvas.draw_arc(Vector2.ZERO, 4 + phase * 9, 0, TAU, 16, Color(.7, .95, .87, (1 - phase) * .18), .8, false)
	canvas.draw_set_transform(Vector2.ZERO)
	for cell in world.living.get("favorites", []):
		var p = screen_point(world.cells[int(cell)])
		canvas.draw_arc(p, 9, 0, TAU, 20, Color(.95, .85, .6, .65), 1.2, true)
	var favorite_ids: Dictionary = {}
	for favorite in world.living.get("favorite_creatures",[]): favorite_ids[int(favorite.id)] = true
	for i in range(mini(world.creatures.size(), inhabitants.animals.size())):
		var cr = world.creatures[i]
		if int(cr.get("companion", -1)) >= 0:
			var p = to_screen(inhabitants.animals[i].position) - Vector2(0, 38 * display_zoom)
			canvas.draw_circle(p + Vector2(-2, 0), 2.8, Color(.96, .78, .7, .55 + sin(time * 2 + i) * .18))
			canvas.draw_circle(p + Vector2(2, 0), 2.8, Color(.96, .78, .7, .55 + sin(time * 2 + i) * .18))
		if favorite_ids.has(int(cr.identity)):
			var p = to_screen(inhabitants.animals[i].position)
			canvas.draw_arc(p-Vector2(0,20),18+sin(time*2)*1.5,0,TAU,20,Color(.95,.85,.55,.6),1.2,true)
	if int(world.living.get("choir_until", 0)) > int(world.tick):
		for i in range(3):
			canvas.draw_arc(origin + Vector2(0, 45), 170 + i * 7, PI * 1.15, PI * 1.85, 40, [Color(.95, .7, .6, .25), Color(.85, .9, .6, .22), Color(.6, .92, .86, .2)][i], 5, true)
	if selected_creature >= 0 and selected_creature < inhabitants.animals.size():
		var p = to_screen(inhabitants.animals[selected_creature].position)
		canvas.draw_arc(p - Vector2(0, 17), 21, 0, TAU, 32, Color(1, .89, .65, .7), 1.5, true)
		var cr = world.creatures[selected_creature]
		canvas.draw_string(preload("res://assets/phase2/nunito.ttf"), p + Vector2(-55, -49), str(cr.get("given_name", "")), HORIZONTAL_ALIGNMENT_CENTER, 110, 18, Color("fff0c9"))
	var night = maxf(0, -sin(float(world.tick) / 30.0)) * .17
	canvas.draw_rect(Rect2(0, 230, 720, 700), Color(.04, .08, .19, night))
	if int(world.tick) >= 150 and int(world.tick) % 150 < 10:
		for band in range(3):
			var points = PackedVector2Array()
			for x in range(0, 721, 16): points.append(Vector2(x, 310 + band * 18 + sin(x * .008 + time * .3 + band) * 45))
			canvas.draw_polyline(points, Color(.48, .9, .71, .12), 12, true)
	foreground_cpu_ms = (Time.get_ticks_usec()-started)/1000.0
