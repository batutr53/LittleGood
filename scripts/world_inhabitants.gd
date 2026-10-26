class_name WorldInhabitants
extends Node2D

var view: Node2D
var props: Node2D
var walkers: Array = []
var animals: Array = []
var signature = ""
var time = 0.0
var position_memory: Dictionary = {}
var prop_cache: Dictionary = {}
var capture_key = ""
var sync_ms = 0.0
var props_created = 0
var animate_ms = 0.0
var cull_time=0.0

func _ready() -> void:
	y_sort_enabled = true
	props = Node2D.new()
	props.y_sort_enabled = true
	add_child(props)

func add_prop(frame: int, position_value: Vector2, size: float, sway: bool = false) -> Sprite2D:
	var sprite = GameArt.sprite(frame, size)
	sprite.position = position_value
	if sway and not view.low_quality: sprite.material = GameArt.foliage()
	props.add_child(sprite)
	if not capture_key.is_empty(): prop_cache[capture_key].sprites.append(sprite)
	props_created += 1
	return sprite

func begin_props(key: String, value: String) -> bool:
	capture_key = key
	if prop_cache.has(key) and prop_cache[key].signature == value: return false
	if prop_cache.has(key):
		for sprite in prop_cache[key].sprites:
			props.remove_child(sprite)
			sprite.queue_free()
	prop_cache[key] = {"signature": value, "sprites": []}
	return true

func sync(w: Dictionary) -> void:
	var start = Time.get_ticks_usec()
	var valid: Dictionary = {}
	var base = str(w.seed) + ":" + str(view.low_quality)+":"+str(w.has("estate"))
	var occupied_cells={}
	for building in w.get("kingdom",{}).get("buildings",[]):
		var at=w.cells[int(building.cell)]
		var radius=1 if w.has("estate") else 0
		for dy in range(-radius,radius+1):
			for dx in range(-radius,radius+1):occupied_cells[Vector2i(at.x+dx,at.y+dy)]=true
	for i in range(w.cells.size()):
		var c = w.cells[i]
		var p = view.project(c)
		var b = int(c.biome)
		var d = c.detail
		var occupied = false
		if occupied_cells.has(Vector2i(c.x,c.y)):occupied=true
		for s in w.settlements:
			var home = w.cells[int(s.cell)]
			var separation = p - view.project(home)
			if (absf(home.x - c.x) <= 1 and absf(home.y - c.y) <= 1) or (absf(separation.x) < 65 and separation.y > -10 and separation.y < 80): occupied = true
		var key = "c:" + str(i)
		valid[key] = true
		var value = base + ":%d:%d:%d:%d:%s" % [b, int(c.height * 1000), int(c.plants * 8), int(c.get("last_gift", -1)), str(occupied)]
		value += str(c.plants > .25) + str(c.plants > .55)
		if not begin_props(key, value) or occupied: continue
		if w.has("estate") and d<(.89 if view.low_quality else .77 if b in [3,4] else .62):continue
		if b == 1 and c.plants > .25 and (d > .22 or c.get("last_gift", -1) == 1): add_prop(12 if d > .5 else 7, p, 40 + c.plants * 14 + d * 9, true)
		elif b == 0 and d > .87 and c.plants > .55: add_prop(12, p, 42, true)
		elif b == 3 and (d > .62 or c.get("last_gift", -1) == 2): add_prop(6, p, 64 + d * 27)
		elif b == 4:
			if d > .72: add_prop(6, p, 73 + d * 21).modulate = Color("e1f5f4")
			elif d < .18: add_prop(7, p, 35, true).modulate = Color("c4dfd8")
		elif b == 2 and d > .84: add_prop(10, p, 48 + d * 8, true)
		elif b == 5 and d > .84: add_prop(11, p, 27)
		elif b == 0 and d < .07: add_prop(11, p, 26)
	for s in w.settlements:
		var key = "s:" + str(s.cell)
		valid[key] = true
		var c = w.cells[int(s.cell)]
		if not begin_props(key, base + ":" + str(s.stage) + ":" + str(c.height) + ":" + str(s.get("landmark", false)) + str(s.custom)): continue
		var p = view.project(c)
		if w.has("estate"):
			var house=add_prop(13,p,50);house.hframes=1;house.vframes=1;house.frame=0;house.texture=view.kingdom_layer.texture("house" if int(s.stage)<2 else "townhall");house.centered=false;house.offset=Vector2(-256,-450);house.scale=Vector2.ONE*(.24+.035*int(s.stage))
		elif s.stage == 0: add_prop(13, p, 50)
		else:
			add_prop(8 if s.stage == 1 else 9, p, 50 if s.stage == 1 else 68)
			add_prop(8, p + Vector2(-30, 12), 35)
			if s.stage == 2: add_prop(8, p + Vector2(31, 15), 39)
		if s.get("landmark", false):
			var frame = 12 if s.custom == "orchard" else 11 if s.custom == "riverfolk" else 6
			add_prop(frame, p + Vector2(34, -9), 32).modulate = Color("f6e4b4")
		var culture_color = {"orchard":Color("e6efd1"),"riverfolk":Color("c9eee8"),"stargazers":Color("e1d9ed")}[s.custom]
		for building in prop_cache[key].sprites: building.modulate *= culture_color
	for key in prop_cache.keys():
		if not valid.has(key):
			for sprite in prop_cache[key].sprites:
				props.remove_child(sprite)
				sprite.queue_free()
			prop_cache.erase(key)
	capture_key = ""
	while animals.size() < w.creatures.size():
		var animal = GameArt.sprite(0, 31)
		add_child(animal)
		animals.append(animal)
	while animals.size() > w.creatures.size(): animals.pop_back().queue_free()
	var desired_walkers = mini(12, w.settlements.size() * 3)
	while walkers.size() < desired_walkers:
		var villager = GameArt.sprite(14, 15)
		add_child(villager)
		walkers.append(villager)
	while walkers.size() > desired_walkers: walkers.pop_back().queue_free()

	signature = base
	sync_ms = (Time.get_ticks_usec() - start) / 1000.0

func animate(w: Dictionary, delta: float) -> void:
	var started = Time.get_ticks_usec()
	time += delta
	cull_time+=delta
	if w.has("estate") and cull_time>.15:
		cull_time=0
		var inverse=view.world_root.global_transform.affine_inverse();var rect=Rect2(inverse*Vector2.ZERO,Vector2.ZERO).expand(inverse*view.get_viewport_rect().size).grow(150)
		for entry in prop_cache.values():
			for sprite in entry.sprites:sprite.visible=rect.has_point(sprite.position)
	var decay = 1 - exp(-delta * 2.3)
	for i in range(mini(animals.size(), w.creatures.size())):
		var cr = w.creatures[i]
		var sprite = animals[i]
		var p = view.project(w.cells[int(cr.cell)])
		var phase = float(cr.phase)
		var grazing = cr.hunger < .5 and sin(time * .65 + phase) > .45
		var radius = 3.0 if grazing else (15.0 if cr.get("trait") == "explorer" else 10.0)
		var target = p + Vector2(sin(time * .42 + phase) * radius, cos(time * .38 + phase) * radius * .42)
		if int(w.weather) == 1: target = target.lerp(p + Vector2(-4, 3), .7)
		for home in w.settlements:
			if int(home.cell) == int(cr.cell): target += Vector2(23 if i % 2 == 0 else -23, 12)
		var identity = int(cr.get("identity", i))
		var previous = position_memory.get(identity, target)
		var next = previous.lerp(target, decay)
		# A gift can change a cell while a creature is present; its feet still follow the live terrain.
		position_memory[identity] = next
		var moving = previous.distance_to(target) > .8
		var bob = absf(sin(time * (5.0 if cr.species != 5 else 7.0) + phase)) * (1.8 if moving else .35)
		if cr.species == 5: bob += 2 + sin(time * 2 + phase) * 1.6
		sprite.position = next - Vector2(0, bob)
		if sprite.frame != int(cr.species): sprite.frame = int(cr.species)
		if absf(target.x - previous.x) > .05: sprite.flip_h = target.x < previous.x
		var size = (33.0 if cr.species != 1 else 37.0) / 232.0
		var breath = sin(time * 2 + phase) * .018
		sprite.scale = Vector2(size * (1 - breath), size * (1 + breath))
		if int(w.weather) == 1: sprite.scale.y *= .94
		sprite.rotation = sin(time * 3 + phase) * (.045 if grazing else .012)
		if int(cr.species) == 1: sprite.self_modulate = Color(1, .96 + sin(time * 2 + phase) * .025, .94)
		var desired_material = GameArt.silver() if cr.get("silver", false) else null
		if sprite.material != desired_material: sprite.material = desired_material
		if cr.get("silver", false): sprite.self_modulate = Color.WHITE
		var coat=view.cosmetic_layer.coats.get(identity,"")
		if coat=="mint":sprite.self_modulate=Color(.77,1,.88)
		elif coat=="sunset":sprite.self_modulate=Color(1,.82,.74)
		elif int(cr.species)!=1 and not cr.get("silver",false):sprite.self_modulate=Color.WHITE
		if coat=="dreamer":
			var flourish=maxf(0,sin(time*.6+phase)-.85)
			sprite.position.y-=flourish*13;sprite.rotation+=flourish*sin(time*8)*.6
	for i in range(walkers.size()):
		var settlement = w.settlements[i / 3]
		var p = view.project(w.cells[int(settlement.cell)])
		var radius = 12 + int(settlement.stage) * 7
		var angle = time * .32 + i * 2.1
		walkers[i].position = p + Vector2(sin(angle) * radius, cos(angle) * radius * .42 + 9)
		walkers[i].flip_h = cos(angle) < 0
		walkers[i].visible = settlement.food > 1 and (i % 3) < 1 + int(settlement.stage)
		if w.has("kingdom") and i<3:walkers[i].visible=false
	animate_ms = (Time.get_ticks_usec()-started)/1000.0

func closest_creature(pos: Vector2, radius: float = 32) -> int:
	var best = radius
	var found = -1
	for i in range(animals.size()):
		var p = view.to_screen(animals[i].position + Vector2(0, -12))
		var d = pos.distance_to(p)
		if d < best: best = d; found = i
	return found
