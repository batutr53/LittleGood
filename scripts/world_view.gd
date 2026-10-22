extends Node2D

var static_pass = false
var terrain_cache: SubViewport
var terrain_painter: Node2D
var cache_age = 1.0
var cached_tick = -1
var cached_xp = -1
var world: Dictionary = {}
var pan = Vector2.ZERO
var zoom = 0.88
var time = 0.0
var selected = -1
var effects: Array = []
var tree_texture: Texture2D
var creature_positions: Dictionary = {}

func _ready() -> void:
	if not static_pass:
		terrain_cache = SubViewport.new()
		terrain_cache.size = Vector2i(1024, 1024)
		terrain_cache.transparent_bg = true
		terrain_cache.disable_3d = true
		terrain_cache.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(terrain_cache)
		terrain_painter = load("res://scripts/world_view.gd").new()
		terrain_painter.static_pass = true
		terrain_painter.pan = Vector2(152, -108)
		terrain_painter.zoom = 1.0
		terrain_cache.add_child(terrain_painter)
	if ResourceLoader.exists("res://assets/tree.png"): tree_texture = load("res://assets/tree.png")

func project(c: Dictionary) -> Vector2:
	return Vector2((c.x - c.y) * 25, (c.x + c.y - 16) * 13 - c.height * 34)

func screen_point(c: Dictionary) -> Vector2:
	return Vector2(360, 620) + pan + project(c) * zoom

func pick(pos: Vector2) -> int:
	var result = -1
	var best = 100000.0
	for i in range(world.get("cells", []).size()):
		var d = (screen_point(world.cells[i]) - pos) / Vector2(1, 0.52)
		if d.length() < 28 * zoom and d.length() < best:
			best = d.length()
			result = i
	return result

func _process(delta: float) -> void:
	if static_pass: return
	cache_age += delta
	if terrain_painter and not world.is_empty() and (cache_age > 0.25 or cached_tick != int(world.tick) or cached_xp != int(world.xp)):
		terrain_painter.world = world
		terrain_painter.time = time
		terrain_painter.tree_texture = tree_texture
		terrain_painter.queue_redraw()
		terrain_cache.render_target_update_mode = SubViewport.UPDATE_ONCE
		cache_age = 0
		cached_tick = int(world.tick)
		cached_xp = int(world.xp)
	time += delta
	for i in range(effects.size() - 1, -1, -1):
		effects[i].age += delta
		if effects[i].age > 1.4: effects.remove_at(i)
	queue_redraw()

func diamond(p: Vector2, color: Color, depth: float) -> void:
	var top = PackedVector2Array([p + Vector2(0, -13), p + Vector2(25, 0), p + Vector2(0, 13), p + Vector2(-25, 0)])
	draw_colored_polygon(PackedVector2Array([top[3], top[2], top[2] + Vector2(0, depth), top[3] + Vector2(0, depth)]), color.darkened(0.32))
	draw_colored_polygon(PackedVector2Array([top[2], top[1], top[1] + Vector2(0, depth), top[2] + Vector2(0, depth)]), color.darkened(0.45))
	draw_colored_polygon(top, color)
	draw_polyline(PackedVector2Array([top[3], top[0], top[1]]), color.lightened(0.07), 0.7, true)

func world_transform(offset: Vector2 = Vector2.ZERO, stretch: Vector2 = Vector2.ONE) -> void:
	draw_set_transform(Vector2(360, 620) + pan + offset * zoom, 0, stretch * zoom)

func tree(p: Vector2, h: float, shade: Color, phase: float) -> void:
	var sway = sin(time * 1.2 + phase) * 1.6
	world_transform(p, Vector2(1, 0.45))
	draw_circle(Vector2(1, 0), 14, Color(0.05, 0.17, 0.13, 0.16))
	world_transform()
	draw_line(p, p + Vector2(sway * 0.4, -h * 0.8), Color("795d47"), 4, true)
	if tree_texture:
		draw_texture_rect(tree_texture, Rect2(p + Vector2(-h * 0.65 + sway, -h * 1.5), Vector2(h * 1.3, h * 1.6)), false, shade.lightened(0.4))
	else:
		for n in range(3):
			var v = p + Vector2((n - 1) * 6 + sway, -h + abs(n - 1) * 5)
			draw_circle(v + Vector2(1, 3), h * 0.47, shade.darkened(0.12))
			draw_circle(v, h * 0.46, shade.lightened(n * 0.06))
			draw_circle(v + Vector2(-3, -5), h * 0.25, shade.lightened(0.18))

func creature(p: Vector2, s: int, phase: float) -> void:
	var colors = [Color("eee2bc"), Color("dc9778"), Color("e7c38b"), Color("c0c4ca"), Color("f0f7f4"), Color("9ad1c5")]
	var bob = sin(time * 5 + phase) * 1.4
	world_transform(p + Vector2(0, 3), Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 9, Color(0.04, 0.12, 0.12, 0.2))
	world_transform(p + Vector2(0, bob))
	var col = colors[s]
	draw_circle(Vector2(-3, -5), 7, col.darkened(0.12))
	draw_circle(Vector2(3, -8), 7, col)
	if s == 0 or s == 4:
		draw_line(Vector2(0, -12), Vector2(-2, -21), col, 4, true)
		draw_line(Vector2(6, -12), Vector2(8, -20), col, 4, true)
	elif s == 1:
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -12), Vector2(-2, -21), Vector2(4, -14)]), col)
		draw_circle(Vector2(-10, -7), 5, Color("f2d698"))
	elif s == 2:
		draw_circle(Vector2(-2, -14), 4, col.lightened(0.1))
	elif s == 3:
		draw_line(Vector2(1, -13), Vector2(-1, -20), Color("f5e2b1"), 3, true)
		draw_line(Vector2(6, -13), Vector2(9, -20), Color("f5e2b1"), 3, true)
	elif s == 5:
		draw_arc(Vector2(-6, -9), 9, -2.0 + sin(time * 7) * 0.5, 0.0, 10, col.lightened(0.2), 3, true)
	draw_circle(Vector2(6, -9), 1.25, Color("173e43"))
	draw_circle(Vector2(7, -6), 1.6, Color("e1a299"))
	draw_line(Vector2(-4, 0), Vector2(-3 + sin(time * 5 + phase) * 2, 3), col.darkened(0.3), 2, true)
	draw_line(Vector2(3, 0), Vector2(4 - sin(time * 5 + phase) * 2, 3), col.darkened(0.3), 2, true)
	world_transform()

func building(p: Vector2, stage: int) -> void:
	var count = 1 + stage * 2
	for n in range(count):
		var v = p + Vector2((n % 3 - 1) * 13, (n / 3) * 10 - 4)
		draw_rect(Rect2(v + Vector2(-6, -12), Vector2(13, 13)), Color("e9cf9c"))
		draw_colored_polygon(PackedVector2Array([v + Vector2(-9, -12), v + Vector2(0, -23), v + Vector2(10, -12)]), Color("b96e60"))
		draw_rect(Rect2(v + Vector2(0, -7), Vector2(4, 7)), Color("745c51"))
		draw_rect(Rect2(v + Vector2(-4, -9), Vector2(3, 3)), Color("ffdf9a"))
		var smoke = fmod(time * 8 + n * 6, 20)
		draw_circle(v + Vector2(5 + sin(time + n) * 3, -24 - smoke), 2 + smoke * 0.1, Color(0.9, 0.94, 0.88, 0.25 * (1 - smoke / 20)))

func _draw() -> void:
	if not static_pass:
		# Deep atmospheric sky, constellation dust, drifting clouds, island halo.
		if world.get("theme", 0) != 0: draw_rect(Rect2(0, 0, 720, 1280), Color("29273d"))
		for i in range(90):
			var p = Vector2(fmod(i * 137.7, 720), fmod(i * 83.3, 1280))
			draw_circle(p, 0.7 + (i % 3) * 0.4, Color(0.7, 0.9, 0.82, 0.08 + sin(time * 0.4 + i) * 0.04))
		for i in range(12, 0, -1):
			draw_set_transform(Vector2(360, 650), 0, Vector2(1, 0.58))
			draw_circle(Vector2.ZERO, 210 + i * 11, Color(0.24, 0.59, 0.53, 0.012))
		draw_set_transform(Vector2.ZERO)
	if world.is_empty(): return
	draw_set_transform(Vector2(360, 620) + pan, 0, Vector2.ONE * zoom)
	if static_pass:
		var ordered = world.cells.duplicate()
		ordered.sort_custom(func(a, b): return a.x + a.y < b.x + b.y)
		for c in ordered:
			var p = project(c)
			var color = Biomes.COLORS[int(c.biome)].lightened((c.detail - 0.5) * 0.1)
			diamond(p, color, 20 + c.height * 25)
			if c.biome == 6:
				for n in range(2):
					var wave = p + Vector2(-9 + n * 11, sin(time * 1.8 + c.y + n) * 2)
					draw_line(wave, wave + Vector2(9, -2), Color(0.76, 0.95, 0.88, 0.45), 1.2, true)
			elif c.biome == 3 or c.biome == 4:
				if c.detail > 0.3:
					var h = 20 + c.detail * 27
					draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 3), p + Vector2(0, -h), p + Vector2(17, 5)]), Color("718b90") if c.biome == 3 else Color("a9c3c5"))
					draw_colored_polygon(PackedVector2Array([p + Vector2(0, -h), p + Vector2(3, 5), p + Vector2(17, 5)]), Color("8ea4a5") if c.biome == 3 else Color("dbe8df"))
					draw_colored_polygon(PackedVector2Array([p + Vector2(-6, -h + 15), p + Vector2(0, -h), p + Vector2(7, -h + 17), p + Vector2(1, -h + 13)]), Color("f0f0dc"))
			elif c.biome == 1 and c.plants > 0.25:
				tree(p + Vector2(0, -2), 20 + c.plants * 8, Color("397e63"), c.detail * 18)
			elif c.biome == 0:
				if c.detail > 0.78 and c.plants > 0.55: tree(p, 21, Color("78a66c"), c.detail * 12)
				elif c.detail > 0.3:
					for f in range(3):
						var v = p + Vector2(f * 5 - 6, sin(f + c.detail * 5) * 4)
						draw_line(v, v + Vector2(0, -4), Color("4e9368"), 1)
						draw_circle(v + Vector2(0, -5), 1.7, Color("f6deae") if f % 2 == 0 else Color("e2a4ab"))
			elif c.biome == 2:
				if c.detail > 0.8:
					draw_line(p, p + Vector2(0, -17), Color("718d65"), 5, true)
					draw_line(p + Vector2(-5, -8), p + Vector2(3, -8), Color("718d65"), 4, true)
				elif c.detail > 0.4: draw_arc(p, 10, 3.4, 5.6, 12, Color("edd0a0"), 1.4, true)
			elif c.biome == 5:
				for r in range(3):
					var v = p + Vector2(r * 5 - 5, 0)
					draw_line(v, v + Vector2(sin(time + c.detail * 7) * 2, -10 - r * 2), Color("467e6e"), 2, true)
		return
	if terrain_cache:
		draw_set_transform(Vector2.ZERO)
		draw_texture_rect(terrain_cache.get_texture(), Rect2(Vector2(360, 620) + pan - Vector2(512, 512) * zoom, Vector2(1024, 1024) * zoom), false)
	world_transform()
	for s in world.settlements: building(project(world.cells[int(s.cell)]), int(s.stage))
	for i in range(world.creatures.size()):
		var cr = world.creatures[i]
		var p = project(world.cells[int(cr.cell)])
		var target = p + Vector2(sin(time * 0.8 + cr.phase) * 9, cos(time * 0.6 + cr.phase) * 4)
		var prev = creature_positions.get(i, target)
		var position_now = prev.lerp(target, 0.07)
		creature_positions[i] = position_now
		creature(position_now, int(cr.species), cr.phase)
	if selected >= 0 and selected < world.cells.size():
		var p = project(world.cells[selected])
		draw_polyline(PackedVector2Array([p + Vector2(0, -14), p + Vector2(26, 0), p + Vector2(0, 14), p + Vector2(-26, 0), p + Vector2(0, -14)]), Color("ffe2a0"), 2, true)
	for e in effects:
		var p = project(world.cells[int(e.cell)])
		var alpha = 1 - e.age / 1.4
		draw_arc(p + Vector2(0, -e.age * 25), 8 + e.age * 35, 0, TAU, 40, Color(1, 0.87, 0.58, alpha), 2.5, true)
		for i in range(12):
			var v = Vector2.from_angle(i * TAU / 12 + e.age) * e.age * 42
			draw_circle(p + v + Vector2(0, -e.age * 30), 2.5 * alpha, Color(0.8, 1, 0.8, alpha))
	draw_set_transform(Vector2.ZERO)
	# Air currents float past rather than obscuring the playable surface.
	for i in range(4):
		var v = Vector2(fmod(time * (4 + i) + i * 237, 1000) - 150, 380 + i * 150)
		draw_set_transform(v, 0, Vector2(1, 0.45))
		draw_circle(Vector2.ZERO, 34, Color(0.78, 0.91, 0.87, 0.045))
		draw_circle(Vector2(32, 9), 25, Color(0.78, 0.91, 0.87, 0.035))
	draw_set_transform(Vector2.ZERO)
	if world.weather == 1:
		for i in range(70):
			var p = Vector2(fmod(i * 137.8 + time * 40, 720), 280 + fmod(i * 79.3 + time * 360, 650))
			draw_line(p, p + Vector2(-3, 10), Color(0.62, 0.84, 0.88, 0.23), 1, true)
	var night = maxf(0, -sin(float(world.tick) / 30.0)) * 0.22
	draw_rect(Rect2(0, 250, 720, 740), Color(0.03, 0.06, 0.18, night))
	if int(world.tick) >= 150 and int(world.tick) % 150 < 10:
		for band in range(3):
			var points = PackedVector2Array()
			for x in range(0, 721, 12): points.append(Vector2(x, 310 + band * 18 + sin(x * 0.008 + time * 0.3 + band) * 45))
			draw_polyline(points, Color(0.48, 0.9, 0.71, 0.12), 12, true)
