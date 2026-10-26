class_name TerrainSurface
extends Node2D

const PALETTE = [Color("97ba79"), Color("638e64"), Color("dfbd83"), Color("a6b2a1"), Color("d6e6db"), Color("72b4a0"), Color("388f9c")]
var view: Node2D
var land: MeshInstance2D
var water: MeshInstance2D
var details: MeshInstance2D
var lookup: Dictionary = {}
var rebuilds = 0
var build_ms = 0.0
var corner_cache: Dictionary = {}
var color_cache: Dictionary = {}

func _ready() -> void:
	land = MeshInstance2D.new()
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://assets/phase2/terrain.gdshader")
	land.material = mat
	add_child(land)
	water = MeshInstance2D.new()
	var water_mat = ShaderMaterial.new()
	water_mat.shader = preload("res://assets/phase2/water.gdshader")
	water.material = water_mat
	add_child(water)
	details = MeshInstance2D.new()
	add_child(details)

func corner(x: float, y: float) -> Vector2:
	var key = Vector2(x, y)
	if corner_cache.has(key): return corner_cache[key]
	var height_sum = 0.0
	var n = 0
	for cy in [floori(y), ceili(y)]:
		for cx in [floori(x), ceili(x)]:
			if lookup.has(Vector2i(cx, cy)):
				height_sum += lookup[Vector2i(cx, cy)].height
				n += 1
	var pitch=1.65 if view.world.cells.size()>400 else 1.0
	var result = Vector2((x - y) * 30*pitch, (x + y - 16) * 15*pitch - height_sum / maxf(1, n) * 42)
	corner_cache[key] = result
	return result

func corner_color(x: float, y: float, water_tile: bool) -> Color:
	var key = Vector3(x, y, 1 if water_tile else 0)
	if color_cache.has(key): return color_cache[key]
	var color = Color(0, 0, 0, 0)
	var count = 0.0
	for cy in [floori(y), ceili(y)]:
		for cx in [floori(x), ceili(x)]:
			var c = lookup.get(Vector2i(cx, cy))
			if c == null: continue
			if (int(c.biome) == 6) != water_tile: continue
			var base = PALETTE[int(c.biome)]
			if c.biome != 6: base = base.darkened((1.0 - c.plants) * 0.09)
			color += base
			count += 1
	var result = color / maxf(1, count)
	color_cache[key] = result
	return result

func triangle(vertices: Array, colors: Array, points: Array, shades: Array) -> void:
	for i in range(3):
		vertices.append(Vector3(points[i].x, points[i].y, 0))
		colors.append(shades[i])

func quad(v: Array, colors: Array, p: Array, shades: Array) -> void:
	triangle(v, colors, [p[0], p[1], p[2]], [shades[0], shades[1], shades[2]])
	triangle(v, colors, [p[0], p[2], p[3]], [shades[0], shades[2], shades[3]])

func make_mesh(v: Array, colors: Array) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	if v.is_empty(): return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(v)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colors)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func rebuild(w: Dictionary) -> void:
	var start = Time.get_ticks_usec()
	lookup.clear()
	corner_cache.clear()
	color_cache.clear()
	for c in w.cells: lookup[Vector2i(c.x, c.y)] = c
	var v: Array = []
	var colors: Array = []
	var water_v: Array = []
	var water_c: Array = []
	var decor_v: Array = []
	var decor_c: Array = []
	var ordered = w.cells.duplicate()
	ordered.sort_custom(func(a, b): return a.x + a.y < b.x + b.y)
	# Only the outer exposed faces have thickness. Shared corners remove the block grid.
	for c in ordered:
		var corners = [corner(c.x - .5, c.y - .5), corner(c.x + .5, c.y - .5), corner(c.x + .5, c.y + .5), corner(c.x - .5, c.y + .5)]
		for edge in [1, 2]:
			var neighbour = Vector2i(c.x + (1 if edge == 1 else 0), c.y + (1 if edge == 2 else 0))
			if lookup.has(neighbour): continue
			var a = corners[edge]
			var b = corners[(edge + 1) % 4]
			var depth = 50 + c.height * 20 + c.detail * 18
			var previous_a = a
			var previous_b = b
			for layer in range(3):
				var t = float(layer + 1) / 3.0
				var next_a = Vector2(a.x * (1 - t * .1), a.y + depth * t)
				var next_b = Vector2(b.x * (1 - t * .1), b.y + depth * t)
				var base = [Color("9b9673"), Color("777b62"), Color("4d675b")][layer].darkened(.08 if edge == 1 else 0)
				quad(v, colors, [previous_a, previous_b, next_b, next_a], [base.lightened(.035), base, base.darkened(.09), base.darkened(.04)])
				previous_a = next_a
				previous_b = next_b
	for c in ordered:
		var p = [corner(c.x - .5, c.y - .5), corner(c.x + .5, c.y - .5), corner(c.x + .5, c.y + .5), corner(c.x - .5, c.y + .5)]
		var water_tile = int(c.biome) == 6
		var shades = [corner_color(c.x - .5, c.y - .5, water_tile), corner_color(c.x + .5, c.y - .5, water_tile), corner_color(c.x + .5, c.y + .5, water_tile), corner_color(c.x - .5, c.y + .5, water_tile)]
		if water_tile: quad(water_v, water_c, p, shades)
		else: quad(v, colors, p, shades)
		# Narrow, continuous riparian banks follow the actual water cells.
		if water_tile:
			var neighbours = [Vector2i(c.x, c.y - 1), Vector2i(c.x + 1, c.y), Vector2i(c.x, c.y + 1), Vector2i(c.x - 1, c.y)]
			for edge in range(4):
				var other = lookup.get(neighbours[edge])
				if other == null:
					if edge in [1, 2]:
						var a = p[edge]
						var b = p[(edge + 1) % 4]
						quad(water_v, water_c, [a, b, b + Vector2(-3, 64), a + Vector2(3, 64)], [Color("6ac9c5"), Color("a2e5d5"), Color(.21,.55,.6,.05), Color(.21,.55,.6,.05)])
					continue
				if int(other.biome) == 6: continue
				var a = p[edge]
				var b = p[(edge + 1) % 4]
				var centre = (p[0] + p[2]) * .5
				var shore = Color("d5d6a5")
				quad(decor_v, decor_c, [a, b, b.lerp(centre, .12), a.lerp(centre, .12)], [shore, shore, Color("78c0ad"), Color("78c0ad")])
		elif c.biome in [0, 1, 5]:
			var centre = view.project(c)
			for n in range(4 if c.biome != 1 else 2):
				var q = centre + Vector2(sin(c.detail * 50 + n * 12) * 18, cos(c.detail * 22 + n * 7) * 7)
				var green = Color("608b58") if c.biome != 5 else Color("397d6d")
				triangle(decor_v, decor_c, [q + Vector2(-1, 0), q + Vector2(1, 0), q + Vector2(sin(n) * 2, -4 - n)], [green, green, green.lightened(.12)])
				if c.biome == 0 and c.plants > .5:
					var f = Color("f3ddac") if n % 2 else Color("d9a6ba")
					quad(decor_v, decor_c, [q + Vector2(-1.6, -5), q + Vector2(1, -6), q + Vector2(2, -4), q + Vector2(-1, -3)], [f, f, f, f])
	for settlement in w.settlements:
		var centre = view.project(w.cells[int(settlement.cell)])
		var radius = 22 + int(settlement.stage) * 14
		for n in range(20):
			var a = centre + Vector2(cos(n * TAU / 20) * radius, sin(n * TAU / 20) * radius * .45)
			var b = centre + Vector2(cos((n + 1) * TAU / 20) * radius, sin((n + 1) * TAU / 20) * radius * .45)
			triangle(decor_v, decor_c, [centre, a, b], [Color(.75,.65,.43,.5), Color(.75,.65,.43,0), Color(.75,.65,.43,0)])
	land.mesh = make_mesh(v, colors)
	water.mesh = make_mesh(water_v, water_c)
	details.mesh = make_mesh(decor_v, decor_c)
	rebuilds += 1
	build_ms = (Time.get_ticks_usec() - start) / 1000.0
