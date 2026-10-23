extends RefCounted
# Trusted, local scene registry. Trade destinations remain owned by trade.gd.
const WILD=preload("res://scripts/wildwood_map.gd")
const HILLS=preload("res://scripts/iron_hills_map.gd")
const DESERT=preload("res://scripts/ashen_desert_map.gd")
const IDS=["wildwood","iron_hills","ashen_desert"]
static func data(id: String) -> Dictionary:
	return {
		"wildwood":{"name":["Wildwood","Yabanorman"],"level":2,"risk":["Familiar trail","Tanıdık patika"],"resources":["Herbs · leather · thornhide","Bitki · deri · diken postu"],"enemies":["Wolves · thorn beasts · ancient spiders","Kurt · diken canavarı · kadim örümcek"],"landmark":["Sunstone · guardian's grove","Güneştaşı · muhafız korusu"],"preview":"wildwood-ground","playable":true},
		"iron_hills":{"name":["Iron Hills","Demir Tepeler"],"level":4,"risk":["Armored enemies · dodge heavy strikes","Zırhlı düşman · ağır darbelerden kaçın"],"resources":["Iron ore → furnace · mountain stone → building","Demir cevheri → fırın · dağ taşı → inşaat"],"enemies":["Stone Crawler · Cave Stalker","Taş Sürüngeni · Mağara Avcısı"],"landmark":["The Forgotten Mine","Unutulmuş Maden"],"preview":"iron-hills-preview","playable":true},
		"ashen_desert":{"name":["Ashen Desert","Kül Çölü"],"level":5,"risk":["Venom · dodge stings and glowing targets","Zehir · iğneden ve parlayan hedeften kaç"],"resources":["Desert Crystal → curative forge tonic","Çöl Kristali → demircide arındırıcı iksir"],"enemies":["Sand Stalker · Dune Scorpion · Ruin Sentinel","Kum Avcısı · Kumul Akrebi · Harabe Nöbetçisi"],"landmark":["Oasis · ancient road","Vaha · kadim yol"],"preview":"ashen-desert-preview","playable":true}
	}.get(id,{})
static func current(w: Dictionary) -> String:return str(w.kingdom.adventure.run.get("region","wildwood"))
static func map(id: String):return DESERT if id=="ashen_desert" else HILLS if id=="iron_hills" else WILD
static func unlocked(w: Dictionary,id: String) -> bool:
	if not id in IDS or not data(id).playable:return false
	var H=load("res://scripts/hero.gd")
	return H.writable(w) and not w.kingdom.adventure.hero.is_empty() and H.progress(w,"hero_armed")>0 and w.kingdom.claimed.size()>=(21 if id!="wildwood" else 11) and (id!="ashen_desert" or load("res://scripts/ashen_desert.gd").mine_found(w))
static func seen(w: Dictionary,id: String) -> bool:
	var a=w.kingdom.adventure
	return (not a.run.is_empty() and current(w)==id) or a.get("regions",{}).get("stored",{}).has(id)
static func capacity(w: Dictionary) -> int:return mini(10000000,roundi(load("res://scripts/kingdom.gd").storage(w)*1000))
static func prepare(w: Dictionary,id: String) -> bool:
	if not unlocked(w,id):return false
	var a=w.kingdom.adventure
	if not a.run.is_empty() and a.run.active:return false
	if id=="ashen_desert" and not load("res://scripts/ashen_desert.gd").enable(w):return false
	if current(w)==id:return true
	if not a.has("regions"):a.regions={"version":1,"stored":{}}
	if not a.run.is_empty():a.regions.stored[current(w)]=a.run
	a.run=a.regions.stored.get(id,{})
	a.regions.stored.erase(id)
	return true
static func create(id: int,paused: bool,seed_value: int) -> Dictionary:
	var enemies=[];var n=1
	for row in [["stone_crawler",610,940],["cave_stalker",540,485]]:
		var d=load("res://scripts/adventure.gd").enemies()[row[0]]
		enemies.append({"id":n,"kind":row[0],"x":row[1],"y":row[2],"hp":int(d.health),"state":"idle","timer":0,"aimx":0,"aimy":0,"pattern":0});n+=1
	return {"id":id,"region":"iron_hills","nodes":{"ore":false,"stone":false},"active":true,"home_paused":paused,"clock":0,"x":240,"y":1260,"facing":[0,-1000],"invulnerable":0,"dash":0,"swing":0,"enemies":enemies,"loot":[],"cargo":{},"picked":0,"chest":false,"harvest":false,"landmark":false,"rng":str(seed_value+id*7919)}
static func interact(w: Dictionary) -> String:
	if not load("res://scripts/hero.gd").writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active or w.kingdom.adventure.hero.defeated or current(w)!="iron_hills":return ""
	var r=w.kingdom.adventure.run;var p=Vector2(r.x,r.y)
	if not r.landmark and p.distance_to(HILLS.LANDMARK)<85:
		r.landmark=true
		load("res://scripts/kingdom.gd").record(w,"exploration","forgotten_mine")
		return "mine"
	for id in HILLS.NODES:
		var node=HILLS.NODES[id]
		if not r.nodes[id] and p.distance_to(node.point)<85:
			# Depletion happens only once a real, capacity-checked pickup succeeds.
			var A=load("res://scripts/adventure.gd");var loot_id=91000 if id=="ore" else 91001
			if w.kingdom.stock[node.resource]+(int(r.cargo.get(node.resource,0))+int(node.amount))*1000>capacity(w):return "full"
			A.drop(r,loot_id,node.point,node.resource,int(node.amount))
			var loot=r.loot.filter(func(l):return l.id==loot_id)[0]
			if not A.pickup(w,loot):return "full"
			r.nodes[id]=true;return "mineral"
	return ""
static func normalize(w: Dictionary) -> void:
	var a=w.kingdom.adventure
	if not a.has("regions"):return
	a.regions.version=int(a.regions.version)
	for id in a.regions.stored:load("res://scripts/adventure.gd").normalize_run(a.regions.stored[id])
static func validate(w: Dictionary) -> bool:
	var a=w.kingdom.adventure
	if not a.has("regions"):return a.run.get("region","wildwood")=="wildwood"
	var C=load("res://scripts/cosmetics.gd");var r=a.regions
	var fields=["version","stored"]
	if int(r.get("version",0))==2:fields.append("quest")
	if w.kingdom.claimed.size()<21 or not C.shape(r,fields) or not C.number(r.version,1,2,true) or not r.stored is Dictionary or r.stored.size()>2:return false
	var ids=[]
	if not a.run.is_empty():ids.append(int(a.run.id))
	for id in r.stored:
		var s=r.stored[id]
		if not id in IDS or id==current(w) or not s is Dictionary or s.is_empty() or s.get("region","wildwood")!=id or s.get("active",true):return false
		if not load("res://scripts/adventure.gd").validate_run(w,s) or ids.has(int(s.id)):return false
		ids.append(int(s.id))
	return load("res://scripts/ashen_desert.gd").validate(w)
static func validate_nodes(r: Dictionary) -> bool:
	for id in HILLS.NODES:
		var loot_id=91000 if id=="ore" else 91001;var node=HILLS.NODES[id]
		var rows=r.loot.filter(func(l):return int(l.id)==loot_id)
		if r.nodes[id]:
			if rows.size()!=1:return false
			var l=rows[0]
			if not l.taken or l.resource!=node.resource or int(l.amount)!=node.amount or l.recipe!="" or Vector2(l.x,l.y)!=node.point:return false
		elif not rows.is_empty():return false
	return true
