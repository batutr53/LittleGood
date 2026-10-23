extends RefCounted
const MAX_PLACEMENTS=32
static var catalog: Dictionary={}
static var textures: Dictionary={}
static func number(v: Variant,lo: float,hi: float,whole: bool=false) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and v>=lo and v<=hi and (not whole or floorf(v)==float(v))
static func shape(v: Variant,keys: Array) -> bool:
	if not v is Dictionary or v.size()!=keys.size():return false
	for key in keys:
		if not v.has(key):return false
	return true
static func items() -> Dictionary:
	if catalog.is_empty():
		for item in JSON.parse_string(FileAccess.get_file_as_string("res://assets/cosmetics/catalog.json")):catalog[item.id]=item
	return catalog
static func texture(id: String) -> AtlasTexture:
	if not textures.has(id):
		var region=AtlasTexture.new();region.atlas=preload("res://assets/cosmetics/atlas.svg")
		var index=items().keys().find(id)
		region.region=Rect2((index%6)*128,(index/6)*128,128,128)
		textures[id]=region
	return textures[id]
static func fresh() -> Dictionary:
	return {"version":1,"dust":35,"earned":35,"spent":0,"claimed":["welcome"],"owned":["enchanted","flowers","stones"],"favorites":[],"theme":"enchanted","sky":"","frame":"","placements":[],"coats":[],"next_id":1}
static func ensure(w: Dictionary) -> void:
	if not w.has("wardrobe") and not w.get("_read_only",false):w.wardrobe=fresh()
static func gate(w: Dictionary,key: String) -> bool:
	match key:
		"none":return true
		"species2":return w.discoveries.size()>=2
		"finding1":return w.living.findings.size()>=1
		"secret1":return w.living.secrets.size()>=1
		"village1":return not w.settlements.is_empty()
	return false
static func reward(w: Dictionary,key: String,amount: int) -> void:
	if not w.wardrobe.claimed.has(key):
		w.wardrobe.claimed.append(key);w.wardrobe.dust+=amount;w.wardrobe.earned+=amount
static func reconcile(w: Dictionary) -> int:
	if w.get("_read_only",false):return 0
	ensure(w)
	var before=int(w.wardrobe.dust)
	for species in w.discoveries:reward(w,"species:"+str(int(species)),20)
	for key in w.living.findings:reward(w,"finding:"+key,25)
	for key in w.living.secrets:reward(w,"secret:"+key,35)
	for stage in range(3):
		if w.settlements.any(func(s):return int(s.stage)>=stage):reward(w,"stage:"+str(stage),25)
	if w.settlements.any(func(s):return s.get("landmark",false)):reward(w,"monument",50)
	if w.living.get("gifts",0)>=2 and w.cells.filter(func(c):return c.plants>=.75 and c.moisture>=.7).size()>=3:reward(w,"restoration",40)
	var active: Dictionary={}
	for cr in w.creatures:active[int(cr.identity)]=true
	w.wardrobe.coats=w.wardrobe.coats.filter(func(c):return active.has(int(c.id)))
	return int(w.wardrobe.dust)-before
static func buy(w: Dictionary,id: String) -> bool:
	if w.get("_read_only",false) or not items().has(id):return false
	ensure(w)
	var item=items()[id]
	if item.premium or w.wardrobe.owned.has(id) or not gate(w,item.gate) or int(w.wardrobe.dust)<int(item.price):return false
	w.wardrobe.dust-=int(item.price);w.wardrobe.spent+=int(item.price);w.wardrobe.owned.append(id)
	return true
static func owned(w: Dictionary,id: String) -> bool:return w.get("wardrobe",{}).get("owned",[]).has(id) and items().has(id) and not items()[id].premium
static func equip(w: Dictionary,id: String,identity: int=-1) -> bool:
	if w.get("_read_only",false) or not owned(w,id):return false
	var kind=items()[id].category
	if kind in ["theme","sky","frame"]:w.wardrobe[kind]=id;return true
	if kind=="creature" and w.creatures.any(func(cr):return int(cr.identity)==identity):
		w.wardrobe.coats=w.wardrobe.coats.filter(func(c):return int(c.id)!=identity)
		w.wardrobe.coats.append({"id":identity,"item":id});return true
	return false
static func unequip(w: Dictionary,kind: String,identity: int=-1) -> bool:
	if w.get("_read_only",false):return false
	ensure(w)
	if kind in ["theme","sky","frame"]:w.wardrobe[kind]="enchanted" if kind=="theme" else "";return true
	if kind=="creature":w.wardrobe.coats=w.wardrobe.coats.filter(func(c):return int(c.id)!=identity);return true
	return false
static func valid_place(w: Dictionary,id: String,cell: int,ignore: int=-1) -> bool:
	if not items().has(id) or not items()[id].category in ["decor","settlement"] or cell<0 or cell>=w.cells.size():return false
	if ignore<0 and w.get("wardrobe",{}).get("placements",[]).size()>=MAX_PLACEMENTS:return false
	if w.has("kingdom") and w.kingdom.buildings.any(func(b):return int(b.cell)==cell):return false
	for p in w.get("wardrobe",{}).get("placements",[]):
		if int(p.cell)==cell and int(p.id)!=ignore:return false
	var home=w.settlements.any(func(s):return int(s.cell)==cell)
	if items()[id].category=="settlement":return home
	if home:return false
	var c=w.cells[cell]
	if id in ["willow","ruins","obelisk","prisms"]:
		for s in w.settlements:
			var h=w.cells[int(s.cell)]
			if absf(c.x-h.x)<=1 and absf(c.y-h.y)<=1:return false
	if id=="falls":
		if int(c.biome)!=6:return false
		var neighbors=0
		for other in w.cells:
			if absf(other.x-c.x)+absf(other.y-c.y)==1:neighbors+=1
		return neighbors<4
	return int(c.biome)!=6
static func place(w: Dictionary,item: String,cell: int,rotation: int=0,moving: int=-1) -> int:
	if w.get("_read_only",false) or not owned(w,item) or rotation<0 or rotation>3 or not valid_place(w,item,cell,moving):return -1
	if moving>=0:
		for p in w.wardrobe.placements:
			if int(p.id)==moving and p.item==item:p.cell=cell;p.rotation=rotation;return moving
		return -1
	if w.wardrobe.placements.size()>=MAX_PLACEMENTS:return -1
	var id=int(w.wardrobe.next_id);w.wardrobe.next_id=id+1
	w.wardrobe.placements.append({"id":id,"item":item,"cell":cell,"rotation":rotation})
	return id
static func remove(w: Dictionary,id: int) -> bool:
	if w.get("_read_only",false):return false
	var before=w.wardrobe.placements.size()
	w.wardrobe.placements=w.wardrobe.placements.filter(func(p):return int(p.id)!=id)
	return before>w.wardrobe.placements.size()
static func coat(w: Dictionary,id: int) -> String:
	for c in w.get("wardrobe",{}).get("coats",[]):
		if int(c.id)==id:return c.item
	return ""
static func favorite(w: Dictionary,id: String) -> bool:
	if w.get("_read_only",false) or not items().has(id):return false
	ensure(w)
	if w.wardrobe.favorites.has(id):w.wardrobe.favorites.erase(id)
	else:w.wardrobe.favorites.append(id)
	return true
static func appearance(w: Dictionary,ids: Dictionary={}) -> Dictionary:
	var d=w.get("wardrobe",fresh())
	var a={"theme":d.theme,"sky":d.sky,"frame":d.frame,"placements":[],"coats":[]}
	for p in d.placements:a.placements.append({"id":a.placements.size()+1,"item":p.item,"cell":int(p.cell),"rotation":int(p.rotation)})
	for c in d.coats:
		var id=int(c.id) if ids.is_empty() else int(ids.get(int(c.id),-1))
		if id>=0 and w.creatures.any(func(cr):return int(cr.identity)==int(c.id)):a.coats.append({"id":id,"item":c.item})
	return a
static func public_valid(a: Variant,cells: int,creatures: int) -> bool:
	if not shape(a,["theme","sky","frame","placements","coats"]):return false
	for key in ["theme","sky","frame"]:
		if not a[key] is String:return false
		if a[key]=="" and key!="theme":continue
		if not items().has(a[key]) or items()[a[key]].category!=key or items()[a[key]].premium:return false
	if not a.placements is Array or a.placements.size()>MAX_PLACEMENTS or not a.coats is Array or a.coats.size()>100:return false
	var used: Dictionary={};var places: Dictionary={}
	for p in a.placements:
		if not shape(p,["id","item","cell","rotation"]) or not number(p.id,1,MAX_PLACEMENTS,true) or used.has(int(p.id)) or not number(p.cell,0,cells-1,true) or places.has(int(p.cell)) or not number(p.rotation,0,3,true):return false
		if not p.item is String or not items().has(p.item) or not items()[p.item].category in ["decor","settlement"] or items()[p.item].premium:return false
		used[int(p.id)]=true;places[int(p.cell)]=true
	used.clear()
	for c in a.coats:
		if not shape(c,["id","item"]) or not number(c.id,0,creatures-1,true) or used.has(int(c.id)) or not c.item is String or not items().has(c.item) or items()[c.item].category!="creature" or items()[c.item].premium:return false
		used[int(c.id)]=true
	return true
static func from_appearance(a: Dictionary) -> Dictionary:
	var d=fresh()
	d.theme=a.theme;d.sky=a.sky;d.frame=a.frame;d.placements=a.placements.duplicate(true);d.coats=a.coats.duplicate(true)
	return d
static func validate(w: Dictionary) -> bool:
	if not w.has("wardrobe"):return true
	var d=w.wardrobe
	if not d is Dictionary or d.keys().size()!=13:return false
	for key in ["version","dust","earned","spent","next_id"]:
		if not number(d.get(key),0,1000000,true):return false
	if d.version!=1 or d.next_id<1 or d.dust!=d.earned-d.spent:return false
	if not d.get("claimed") is Array or d.claimed.size()>32 or not d.get("owned") is Array or d.owned.size()>items().size() or not d.get("favorites") is Array or d.favorites.size()>items().size():return false
	var expected=0;var seen: Dictionary={}
	for key in d.claimed:
		if not key is String or seen.has(key):return false
		seen[key]=true
		if key=="welcome":expected+=35
		elif key in ["monument"]:expected+=50
		elif key=="restoration":expected+=40
		elif key in ["stage:0","stage:1","stage:2"]:expected+=25
		elif key.begins_with("species:") and key.trim_prefix("species:") in ["0","1","2","3","4","5"]:expected+=20
		elif key.begins_with("finding:") and key.trim_prefix("finding:") in LivingStories.FINDINGS:expected+=25
		elif key.begins_with("secret:") and key.trim_prefix("secret:") in LivingStories.SECRETS:expected+=35
		else:return false
	if int(d.earned)!=expected:return false
	var cost=0;seen.clear()
	for id in d.owned:
		if not id is String or not items().has(id) or items()[id].premium or seen.has(id):return false
		seen[id]=true;cost+=int(items()[id].price)
	if int(d.spent)!=cost or not d.owned.has("enchanted"):return false
	seen.clear()
	for id in d.favorites:
		if not id is String or not items().has(id) or seen.has(id):return false
		seen[id]=true
	for kind in ["theme","sky","frame"]:
		if not d.get(kind) is String:return false
		if d[kind]!="" and (not d.owned.has(d[kind]) or items()[d[kind]].category!=kind):return false
	if d.theme.is_empty() or not d.get("placements") is Array or d.placements.size()>MAX_PLACEMENTS or not d.get("coats") is Array or d.coats.size()>100:return false
	seen.clear();var cells: Dictionary={}
	for p in d.placements:
		if not shape(p,["id","item","cell","rotation"]):return false
		if not number(p.id,1,d.next_id-1,true) or seen.has(int(p.id)) or not number(p.cell,0,w.cells.size()-1,true) or cells.has(int(p.cell)) or not number(p.rotation,0,3,true):return false
		if not d.owned.has(p.item) or not items()[p.item].category in ["decor","settlement"]:return false
		seen[int(p.id)]=true;cells[int(p.cell)]=true
	seen.clear()
	for c in d.coats:
		if not shape(c,["id","item"]) or not number(c.id,0,1000000,true) or seen.has(int(c.id)) or not d.owned.has(c.item) or items()[c.item].category!="creature":return false
		seen[int(c.id)]=true
	return true
