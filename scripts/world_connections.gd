extends RefCounted

# State-driven opportunities. No calendar rewards, expiry, streaks or wall-clock RNG.
static func ensure(w: Dictionary) -> void:
	if w.get("_read_only",false): return
	for entry in [["favorite_creatures", []], ["places", []], ["trades", []], ["next_migration", 90]]:
		if not w.living.has(entry[0]): w.living[entry[0]] = entry[1].duplicate(true) if entry[1] is Array else entry[1]
	for cr in w.creatures:
		if not cr.has("origin_cell"): cr.origin_cell = int(cr.cell)
		if not cr.has("lineage"): cr.lineage = int(cr.identity)
		if not cr.has("parent_name"): cr.parent_name = ""
	for s in w.settlements:
		if not s.has("rival_cell"): s.rival_cell = -1
		if not s.has("trade_until"): s.trade_until = 0

static func favorite_creature(w: Dictionary, cr: Dictionary) -> bool:
	if w.get("_read_only",false): return false
	for item in w.living.favorite_creatures:
		if int(item.id) == int(cr.identity): w.living.favorite_creatures.erase(item); return true
	if w.living.favorite_creatures.size() >= 12: return false
	w.living.favorite_creatures.append({"id":int(cr.identity), "name":cr.given_name, "species":int(cr.species), "recorded_at":int(w.tick)})
	return true

static func is_favorite(w: Dictionary, identity: int) -> bool:
	return w.living.favorite_creatures.any(func(item): return int(item.id) == identity)

static func place(w: Dictionary, kind: String, cell: int, cr: Dictionary) -> void:
	if w.living.places.any(func(p): return p.kind == kind): return
	w.cells[cell][kind] = true
	w.living.places.append({"kind":kind, "cell":cell, "tick":int(w.tick)})
	LivingStories.remember(w,kind,kind,cell,cr.given_name,int(cr.identity),int(cr.species))

static func tick(w: Dictionary) -> void:
	if w.get("_read_only",false): return
	if int(w.tick) % 15 != 0: return
	for cr in w.creatures:
		var c = w.cells[int(cr.cell)]
		if cr.trait == "gardener" and c.biome == 1 and c.plants >= .9 and c.moisture >= .65 and c.detail > .75:
			place(w,"canopy_arch",int(cr.cell),cr)
			c.moisture = minf(1,c.moisture+.02)
		if cr.species == 5 and c.biome == 5 and c.moisture >= .8:
			for neighbor in w.creatures:
				if neighbor.species == 0 and neighbor.cell == cr.cell:
					neighbor.hunger = maxf(0,neighbor.hunger-.06)
					c.plants = minf(1,c.plants+.03)
					place(w,"reed_shelter",int(cr.cell),cr)
	# Migrants arrive only if the actual habitat can support them and the population has room.
	if int(w.tick) >= int(w.living.next_migration) and w.creatures.size() < 70:
		for i in range(w.cells.size()):
			var c = w.cells[i]
			if c.biome == 5 and c.moisture >= .75 and c.plants >= .65:
				w.creatures.append({"species":5,"cell":i,"hunger":.2,"phase":float(int(w.tick)%6),"migrant":true})
				LivingStories.ensure(w)
				w.living.next_migration = int(w.tick)+480
				var cr = w.creatures.back()
				LivingStories.remember(w,"migration:"+str(cr.identity),"migration",i,cr.given_name,int(cr.identity),5)
				break
	if int(w.tick)%30 != 0: return
	for a in w.settlements:
		for b in w.settlements:
			if int(a.cell) >= int(b.cell): continue
			var ac = w.cells[int(a.cell)]
			var bc = w.cells[int(b.cell)]
			if absf(ac.x-bc.x)+absf(ac.y-bc.y)>9: continue
			var pair = str(a.cell)+":"+str(b.cell)
			if int(a.rival_cell) == int(b.cell) and int(b.rival_cell) == int(a.cell) and (a.allies.has(int(b.cell)) or (ac.resources >= 12 and bc.resources >= 12)):
				a.rival_cell = -1; b.rival_cell = -1
				LivingStories.remember(w,"cooperation:"+pair,"cooperation",int(a.cell),a.given_name+" · "+b.given_name)
			if not a.allies.has(int(b.cell)) and int(a.rival_cell) == -1 and int(b.rival_cell) == -1 and ac.resources < 5 and bc.resources < 5:
				a.rival_cell = int(b.cell); b.rival_cell = int(a.cell)
				LivingStories.remember(w,"boundary:"+pair,"boundary",int(a.cell),a.given_name+" · "+b.given_name)
			if not a.allies.has(int(b.cell)) or absf(a.food-b.food) <= 10: continue
			var donor = a if a.food>b.food else b
			var receiver = b if a.food>b.food else a
			var amount = minf(3,(donor.food-receiver.food)*.1)
			donor.food -= amount; receiver.food += amount
			a.trade_until = int(w.tick)+20; b.trade_until = int(w.tick)+20
			var previous = w.living.trades.filter(func(t): return t.a==a.cell and t.b==b.cell)
			if previous.is_empty() and w.living.trades.size()<12:
				w.living.trades.append({"a":int(a.cell),"b":int(b.cell),"amount":amount,"tick":int(w.tick)})
			LivingStories.remember(w,"trade:"+pair,"trade",int(receiver.cell),donor.given_name+" · "+receiver.given_name)

static func opportunities(w: Dictionary) -> Array:
	var result: Array = []
	for i in range(w.cells.size()):
		var c = w.cells[i]
		if c.biome == 5:
			result.append({"key":"seek_migrant","cell":i,"power":4})
			break
	for cr in w.creatures:
		if cr.trait == "gardener":
			result.append({"key":"seek_canopy","cell":int(cr.cell),"power":1})
			break
	for s in w.settlements:
		result.append({"key":"seek_trade","cell":int(s.cell),"power":5})
		break
	return result

static func validate(w: Dictionary) -> bool:
	var l = w.living
	if l.has("next_migration") and (not (l.next_migration is int or l.next_migration is float) or not is_finite(float(l.next_migration)) or l.next_migration<0): return false
	for pair in [["favorite_creatures",12],["places",12],["trades",12]]:
		if l.has(pair[0]) and (not l[pair[0]] is Array or l[pair[0]].size()>pair[1]): return false
	for r in l.get("favorite_creatures",[]):
		if not r is Dictionary or not r.get("name") is String or r.name.length()>24: return false
		for key in ["id","species","recorded_at"]:
			if not (r.get(key) is int or r.get(key) is float) or not is_finite(float(r[key])) or r[key]<0: return false
		if r.species>5: return false
	for r in l.get("places",[]):
		if not r is Dictionary or not r.get("kind") in ["canopy_arch","reed_shelter"]: return false
		for key in ["cell","tick"]:
			if not (r.get(key) is int or r.get(key) is float) or not is_finite(float(r[key])) or r[key]<0: return false
		if r.cell>=w.cells.size(): return false
	for r in l.get("trades",[]):
		if not r is Dictionary: return false
		for key in ["a","b","amount","tick"]:
			if not (r.get(key) is int or r.get(key) is float) or not is_finite(float(r[key])) or r[key]<0: return false
		if r.a>=w.cells.size() or r.b>=w.cells.size() or r.amount>3: return false
	return true
