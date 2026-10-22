extends Node2D

var origin = Vector2(360, 585)
var world: Dictionary = {}
var pan = Vector2.ZERO
var zoom = 0.88
var display_pan = Vector2.ZERO
var display_zoom = 0.88
var time = 0.0
var selected = -1
var selected_creature = -1
var effects: Array = []
var creature_positions: Dictionary = {}
var low_quality = false
var world_root: Node2D
var terrain: TerrainSurface
var inhabitants: WorldInhabitants
var scenery_signature = ""
var update_accumulator = 0.0

func _ready() -> void:
	origin.y += maxf(0, get_viewport_rect().size.y - 1280) * .5
	world_root = Node2D.new()
	add_child(world_root)
	terrain = TerrainSurface.new()
	terrain.view = self
	world_root.add_child(terrain)
	inhabitants = WorldInhabitants.new()
	inhabitants.view = self
	world_root.add_child(inhabitants)

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
	if inhabitants: inhabitants.signature = ""
	selected_creature = -1

func set_quality(economy: bool) -> void:
	low_quality = economy
	Engine.max_fps = 30 if economy else 60
	if OS.has_feature("mobile"):
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT if economy else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	invalidate()

func _process(delta: float) -> void:
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
				terrain.rebuild(world)
				inhabitants.sync(world)
		inhabitants.animate(world, delta)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].age += delta
		if effects[i].age > 1.6: effects.remove_at(i)
	queue_redraw()

func ellipse(p: Vector2, radius: float, color: Color, ratio: float = .45) -> void:
	draw_set_transform(p, 0, Vector2(1, ratio))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if world.is_empty(): return
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
	if selected >= 0 and selected < world.cells.size():
		var selection = screen_point(world.cells[selected])
		canvas.draw_set_transform(selection, 0, Vector2(display_zoom, display_zoom * .5))
		canvas.draw_arc(Vector2.ZERO, 24 + sin(time * 3) * 1.3, 0, TAU, 36, Color("f6dea3"), 1.8, true)
		canvas.draw_set_transform(Vector2.ZERO)
	for s in world.settlements:
		var p = screen_point(world.cells[int(s.cell)])
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
		for i in range(44 if not low_quality else 18):
			var p = Vector2(fmod(i * 137.8 + time * 35, 720), 260 + fmod(i * 79.3 + time * 310, 680))
			canvas.draw_line(p, p + Vector2(-3, 11), Color(.7, .91, .94, .26), 1.0, false)
		for i in range(6):
			var p = origin + Vector2(sin(i * 9.7) * 210, cos(i * 11.3) * 95)
			var phase = fmod(time * .7 + i * .17, 1)
			canvas.draw_set_transform(p, 0, Vector2(1, .4))
			canvas.draw_arc(Vector2.ZERO, 4 + phase * 9, 0, TAU, 16, Color(.7, .95, .87, (1 - phase) * .18), .8, false)
	canvas.draw_set_transform(Vector2.ZERO)
	if selected_creature >= 0 and selected_creature < inhabitants.animals.size():
		var p = to_screen(inhabitants.animals[selected_creature].position)
		canvas.draw_arc(p - Vector2(0, 17), 21, 0, TAU, 32, Color(1, .89, .65, .7), 1.5, true)
	var night = maxf(0, -sin(float(world.tick) / 30.0)) * .17
	canvas.draw_rect(Rect2(0, 230, 720, 700), Color(.04, .08, .19, night))
	if int(world.tick) >= 150 and int(world.tick) % 150 < 10:
		for band in range(3):
			var points = PackedVector2Array()
			for x in range(0, 721, 16): points.append(Vector2(x, 310 + band * 18 + sin(x * .008 + time * .3 + band) * 45))
			canvas.draw_polyline(points, Color(.48, .9, .71, .12), 12, true)
