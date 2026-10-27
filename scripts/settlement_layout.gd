extends RefCounted
# Conservative sprite footprints in the same isometric coordinates as WorldView.
static func point(w,cell):
	var c=w.cells[int(cell)];var pitch=1.65 if w.cells.size()>400 else 1.0
	return Vector2((c.x-c.y)*30*pitch,(c.x+c.y-16)*15*pitch-c.height*42)
static func footprint(w,cell):return Rect2(point(w,cell)+Vector2(-84,-134),Vector2(168,148))
static func clear(w,cell,ignore=0):
	var rect=footprint(w,cell)
	for b in w.kingdom.buildings:
		if int(b.id)!=ignore and rect.intersects(footprint(w,int(b.cell))):return false
	for home in w.settlements:
		if rect.intersects(footprint(w,int(home.cell))):return false
	return true
static func writable(w):return w.has("colony") and w.has("estate") and not w.get("_read_only",false) and not w.kingdom.get("adventure",{}).get("run",{}).get("active",false) and not w.kingdom.get("military",{}).get("battle",{}).get("active",false)
static func propose(w):
	if not writable(w):return []
	var K=load("res://scripts/kingdom.gd");var draft=w.duplicate();draft.kingdom=w.kingdom.duplicate(true);draft.kingdom.buildings=[];var plan=[]
	# Active caravan markets are fixed anchors; arrange other buildings around them.
	for b in w.kingdom.buildings:
		if load("res://scripts/trade.gd").building_reserved(w,int(b.id)):draft.kingdom.buildings.append(b.duplicate(true))
	for b in draft.kingdom.buildings:
		if not K.valid_site(draft,b.kind,int(b.cell),int(b.id)):return []
	for original in w.kingdom.buildings:
		var b=original.duplicate(true);var chosen=int(b.cell)
		if load("res://scripts/trade.gd").building_reserved(w,int(b.id)):plan.append({"id":int(b.id),"from":chosen,"to":chosen});continue
		if not K.valid_site(draft,b.kind,chosen):
			var distance=INF;chosen=-1;var anchor=point(w,int(b.cell))
			for cell in range(w.cells.size()):
				var value=point(w,cell).distance_squared_to(anchor)
				if value>=distance or not K.valid_site(draft,b.kind,cell):continue
				distance=value;chosen=cell
		if chosen<0:return []
		plan.append({"id":int(b.id),"from":int(b.cell),"to":chosen});b.cell=chosen;draft.kingdom.buildings.append(b)
	return plan
static func apply(w,plan):
	if not writable(w) or not plan is Array or plan.is_empty() or plan.size()!=w.kingdom.buildings.size():return false
	var K=load("res://scripts/kingdom.gd");var draft=w.duplicate();draft.kingdom=w.kingdom.duplicate(true);var ids={}
	for entry in plan:
		var C=load("res://scripts/cosmetics.gd")
		if not entry is Dictionary or not C.shape(entry,["id","from","to"]) or not C.number(entry.id,1,w.kingdom.next_building-1,true) or not C.number(entry.from,0,w.cells.size()-1,true) or not C.number(entry.to,0,w.cells.size()-1,true) or ids.has(int(entry.id)):return false
		if int(entry.from)!=int(entry.to) and load("res://scripts/trade.gd").building_reserved(w,int(entry.id)):return false
		var source=w.kingdom.buildings.filter(func(b):return int(b.id)==int(entry.id) and int(b.cell)==int(entry.from))
		if source.size()!=1:return false
		var b=draft.kingdom.buildings.filter(func(building):return int(building.id)==int(entry.id))[0];b.cell=int(entry.to);ids[int(entry.id)]=true
	for b in draft.kingdom.buildings:
		if not K.valid_site(draft,b.kind,int(b.cell),int(b.id)):return false
	w.kingdom.buildings=draft.kingdom.buildings;return true
