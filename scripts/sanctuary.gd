extends RefCounted
const MAP=preload("res://scripts/sanctuary_map.gd")
const GEAR=["ancient_blade","ruinwalker_armor","sunguard_shield","sunstone_talisman"]
const MATERIALS=["ancient_alloy","sentinel_core","sunstone_fragment"]
const KINDS=["ancient_sentinel","sun_shade","sunward_warden"]
static func enabled(w: Dictionary) -> bool:return int(w.get("kingdom",{}).get("adventure",{}).get("regions",{}).get("version",0))==3
static func writable(w: Dictionary) -> bool:return load("res://scripts/hero.gd").writable(w) and enabled(w)
static func enable(w: Dictionary) -> bool:
	if not load("res://scripts/hero.gd").writable(w) or (not w.kingdom.claimed.has("main_22") and not load("res://scripts/parallel_play.gd").enabled(w)):return false
	if enabled(w):return true
	if load("res://scripts/parallel_play.gd").enabled(w) and not load("res://scripts/ashen_desert.gd").enabled(w):
		if not load("res://scripts/ashen_desert.gd").enable(w):return false
	w.kingdom.adventure.regions.version=3
	w.kingdom.adventure.regions.ancients={"version":1,"relic_item":0,"returned":false,"researched":false}
	for key in MATERIALS:w.kingdom.stock[key]=0
	return true
static func defeated(w: Dictionary,e: Dictionary) -> void:
	if not writable(w) or not e.kind in KINDS:return
	var r=w.kingdom.adventure.run
	if r.get("region","")!="sanctuary" or not r.active or not r.enemies.has(e) or e.hp!=0 or e.state!="dead":return
	load("res://scripts/adventure.gd").drop(r,int(e.id)*10+2,Vector2(e.x-20,e.y),"sentinel_core" if e.kind=="ancient_sentinel" else "sunstone_fragment",1 if e.kind=="ancient_sentinel" else 2)
static func run_of(w: Dictionary) -> Dictionary:
	var a=w.kingdom.adventure
	return a.run if a.run.get("region","")=="sanctuary" else a.get("regions",{}).get("stored",{}).get("sanctuary",{})
static func create(id: int,paused: bool,seed_value: int) -> Dictionary:
	var r=load("res://scripts/regions.gd").create(id,paused,seed_value)
	r.region="sanctuary";r.nodes={};r.mechanisms={"plates":0,"last_plate":0,"switches":0,"secret":false};r.traps={"spikes":-1,"runes":-1}
	r.enemies=[];var index=1
	for row in [["ancient_sentinel",740,850],["sun_shade",740,610],["sunward_warden",570,270]]:
		var data=load("res://scripts/adventure.gd").enemies()[row[0]]
		r.enemies.append({"id":index,"kind":row[0],"x":row[1],"y":row[2],"hp":int(data.health),"state":"idle","timer":0,"aimx":0,"aimy":0,"pattern":0});index+=1
	return r
static func phase(r: Dictionary,key: String) -> String:
	var d=MAP.HAZARDS[key];var time=(int(r.clock)+int(d.offset))%int(d.period)
	return "active" if time>=d.active and time<d.end else "warning" if time>=d.warning and time<d.active else "safe"
static func tick(w: Dictionary) -> Array:
	if not writable(w):return []
	var r=w.kingdom.adventure.run
	if r.get("region","")!="sanctuary" or not r.active or w.kingdom.adventure.hero.defeated:return []
	var p=Vector2(r.x,r.y);var cues=[];var plate=0
	for i in range(2):
		if p.distance_to(MAP.PLATES[i])<40:plate=i+1
	if plate!=r.mechanisms.last_plate:
		r.mechanisms.last_plate=plate
		if plate>0 and r.mechanisms.plates<2:
			r.mechanisms.plates=plate if plate==r.mechanisms.plates+1 or plate==1 else 0
			cues.append("mechanism" if r.mechanisms.plates==2 else "plate")
	for key in MAP.HAZARDS:
		var d=MAP.HAZARDS[key];var cycle=(int(r.clock)+int(d.offset))/int(d.period)
		if phase(r,key)=="active" and d.rect.has_point(p) and r.traps[key]!=cycle and r.invulnerable==0:
			r.traps[key]=cycle
			if load("res://scripts/adventure.gd").hurt(w,maxi(1,int(d.damage)-int(load("res://scripts/hero.gd").stats(w).hazard_resist))):cues.append("hurt")
	return cues
static func line_clear(ep: Vector2,p: Vector2,r: Dictionary) -> bool:
	var steps=maxi(1,ceili(ep.distance_to(p)/18))
	for i in range(1,steps+1):
		if not MAP.clear(ep.lerp(p,float(i)/steps),r,2):return false
	return true
static func enemy_step(w: Dictionary,e: Dictionary,mover: Callable) -> Array:
	if not writable(w):return []
	var A=load("res://scripts/adventure.gd");var r=w.kingdom.adventure.run;var p=Vector2(r.x,r.y);var ep=Vector2(e.x,e.y);var delta=p-ep;var distance=delta.length();var d=A.enemies()[e.kind];var cues=[];e.timer=maxi(0,int(e.timer)-50)
	if e.state=="windup":
		if e.timer>0:return cues
		var aimed=Vector2(e.aimx,e.aimy)
		var hit=distance<110 and delta.normalized().dot((aimed-ep).normalized())>.35
		if e.kind=="sun_shade":
			var axis=(aimed-ep).normalized()
			hit=(p.distance_to(aimed)<70 if e.pattern==1 else distance<250 and absf(delta.cross(axis))<24 and delta.dot(axis)>0) and line_clear(ep,p,r)
		elif e.kind=="sunward_warden" and e.pattern==1:
			var axis=(aimed-ep).normalized();hit=distance<260 and absf(delta.cross(axis))<36 and delta.dot(axis)>0 and line_clear(ep,p,r)
		if hit and line_clear(ep,p,r) and A.hurt(w,int(d.attack)):cues.append("hurt")
		e.state="recover";e.timer=int(d.cooldown);e.pattern=(int(e.pattern)+1)%2;return cues
	if e.state=="recover" and e.timer>0:
		if e.kind=="sun_shade" and e.timer>int(d.cooldown)-400:
			var away=-delta.normalized() if distance>1 else Vector2.RIGHT
			var moved=A.move_actor(w,int(e.id),ep,(away+away.orthogonal()).normalized()*float(d.speed)*.05,mover);e.x=roundi(moved.x);e.y=roundi(moved.y)
		return cues
	var reach=220 if e.kind=="sun_shade" or (e.kind=="sunward_warden" and e.pattern==1) else int(d.range)
	if distance>310 or not line_clear(ep,p,r):e.state="idle";return cues
	if distance<=reach:
		e.state="windup";e.timer=int(d.warning);e.aimx=r.x;e.aimy=r.y;return cues
	e.state="chase";var moved=A.move_actor(w,int(e.id),ep,delta.normalized()*float(d.speed)*.05,mover);e.x=roundi(moved.x);e.y=roundi(moved.y);return cues
static func armor(e: Dictionary,ordinary: int) -> int:
	if e.kind=="sunward_warden":return 0 if e.state=="recover" else 18
	if e.kind=="ancient_sentinel" and e.pattern==1:return 0 if e.state=="recover" else ordinary+5
	return ordinary
static func struck(w: Dictionary,e: Dictionary) -> void:
	if not writable(w):return
	if e.kind=="ancient_sentinel" and e.pattern==1 and e.state in ["idle","chase"]:
		e.state="windup";e.timer=500;e.aimx=w.kingdom.adventure.run.x;e.aimy=w.kingdom.adventure.run.y
static func interact(w: Dictionary) -> String:
	if not writable(w):return ""
	var r=w.kingdom.adventure.run
	if r.get("region","")!="sanctuary" or not r.active or w.kingdom.adventure.hero.defeated:return ""
	var p=Vector2(r.x,r.y);var K=load("res://scripts/kingdom.gd");var A=load("res://scripts/adventure.gd")
	if not r.landmark and p.distance_to(MAP.INSCRIPTION)<85:r.landmark=true;K.record(w,"exploration","sunforged_inscription");return "inscription"
	if not r.harvest and p.distance_to(MAP.LORE)<85:r.harvest=true;K.record(w,"exploration","sunforged_forge");return "lore"
	if not r.mechanisms.secret and p.distance_to(MAP.SECRET)<85:r.mechanisms.secret=true;K.record(w,"exploration","hidden_treasury");return "secret"
	for i in range(3):
		if r.mechanisms.plates==2 and r.mechanisms.switches<3 and p.distance_to(MAP.SWITCHES[i])<75:
			r.mechanisms.switches=i+1 if i==r.mechanisms.switches else 1 if i==0 else 0
			return "runes_open" if r.mechanisms.switches==3 else "switch" if r.mechanisms.switches>0 else "wrong_switch"
	if not r.chest and r.mechanisms.secret and p.distance_to(MAP.TREASURE)<85:
		r.chest=true;A.drop(r,93001,MAP.TREASURE,"ancient_alloy",2);A.drop(r,93002,MAP.TREASURE+Vector2(22,0),"gold",3);K.record(w,"exploration","sunforged_treasure");return "treasury"
	if p.distance_to(MAP.RELIC)<85 and not r.enemies.any(func(e):return e.kind=="sunward_warden" and e.hp>0) and w.kingdom.adventure.regions.ancients.relic_item==0:
		A.drop(r,93003,MAP.RELIC,"",1,"sun_relic")
		if not A.pickup(w,r.loot.filter(func(l):return l.id==93003)[0]):return "full"
		return "relic"
	return ""
static func picked(w: Dictionary,l: Dictionary) -> void:
	if not writable(w):return
	if l.recipe=="sun_relic":
		var owned=w.kingdom.industry.items.filter(func(item):return item.recipe=="sun_relic")
		if owned.size()!=1 or not l.get("taken",false) or l.get("id",0)!=93003 or not run_of(w).get("loot",[]).has(l):return
		w.kingdom.adventure.regions.ancients.relic_item=int(owned[0].id)
		load("res://scripts/kingdom.gd").record(w,"exploration","sun_relic_chamber")
static func returning(w: Dictionary) -> void:
	if not writable(w):return
	if not w.kingdom.adventure.hero.defeated and w.kingdom.adventure.regions.ancients.relic_item>0:w.kingdom.adventure.regions.ancients.returned=true
static func research(w: Dictionary) -> bool:
	if not writable(w) or w.kingdom.adventure.run.get("active",false):return false
	var s=w.kingdom.adventure.regions.ancients
	if not s.returned or s.researched or s.relic_item==0:return false
	s.researched=true;load("res://scripts/kingdom.gd").record(w,"exploration","sun_relic_research");return true
static func progress(w: Dictionary,key: String) -> float:
	if not enabled(w):return 0
	var r=run_of(w);var s=w.kingdom.adventure.regions.ancients
	if key=="researched":return int(s.researched)
	if key=="returned":return int(s.returned)
	if key=="relic":return 1 if s.relic_item>0 else 0
	if key=="inscription":return int(r.get("landmark",false))
	if key=="mechanism":return 1 if r.get("mechanisms",{}).get("plates",0)==2 and r.mechanisms.switches==3 else 0
	if key=="warden":return 1 if not r.is_empty() and r.enemies.any(func(e):return e.kind=="sunward_warden" and e.hp==0) else 0
	if key=="equipped":
		for id in w.kingdom.adventure.hero.equipment.values():
			var item=load("res://scripts/industry.gd").item(w,int(id))
			if not item.is_empty() and item.recipe in GEAR and w.kingdom.events.get("craft_"+item.recipe,0)>0:return 1
	return 0
static func normalize(w: Dictionary) -> void:
	if enabled(w):w.kingdom.adventure.regions.ancients.version=int(w.kingdom.adventure.regions.ancients.version);w.kingdom.adventure.regions.ancients.relic_item=int(w.kingdom.adventure.regions.ancients.relic_item)
static func validate_run(w: Dictionary,r: Dictionary) -> bool:
	var C=load("res://scripts/cosmetics.gd")
	if not enabled(w) or not C.shape(r.nodes,[]) or not C.shape(r.mechanisms,["plates","last_plate","switches","secret"]) or not C.shape(r.traps,["spikes","runes"]):return false
	if not C.number(r.mechanisms.plates,0,2,true) or not C.number(r.mechanisms.last_plate,0,2,true) or not C.number(r.mechanisms.switches,0,3,true) or not r.mechanisms.secret is bool:return false
	for key in r.traps:
		if not C.number(r.traps[key],-1,floori(float(int(r.clock)+int(MAP.HAZARDS[key].offset))/int(MAP.HAZARDS[key].period)),true):return false
	if r.enemies.size()!=3 or (r.mechanisms.switches>0 and r.mechanisms.plates!=2):return false
	for e in r.enemies:
		var d=load("res://scripts/adventure.gd").enemies()[e.kind]
		for row in [[int(e.id)*10,d.material,int(d.quantity)],[int(e.id)*10+2,"sentinel_core" if e.kind=="ancient_sentinel" else "sunstone_fragment",1 if e.kind=="ancient_sentinel" else 2]]:
			var found=r.loot.filter(func(l):return int(l.id)==row[0])
			if e.hp==0:
				if found.size()!=1 or found[0].resource!=row[1] or found[0].amount!=row[2] or found[0].recipe!="":return false
			elif not found.is_empty():return false
	if r.chest and not r.mechanisms.secret:return false
	for row in [[93001,"ancient_alloy",2,MAP.TREASURE],[93002,"gold",3,MAP.TREASURE+Vector2(22,0)]]:
		var found=r.loot.filter(func(l):return l.id==row[0])
		if r.chest:
			if found.size()!=1 or found[0].resource!=row[1] or found[0].amount!=row[2] or found[0].recipe!="" or Vector2(found[0].x,found[0].y)!=row[3]:return false
		elif not found.is_empty():return false
	var relics=r.loot.filter(func(l):return l.id==93003 or l.recipe=="sun_relic")
	if not relics.is_empty():
		if relics.size()!=1 or relics[0].id!=93003 or relics[0].recipe!="sun_relic" or Vector2(relics[0].x,relics[0].y)!=MAP.RELIC or r.enemies.any(func(e):return e.kind=="sunward_warden" and e.hp>0):return false
		if relics[0].taken!=(w.kingdom.adventure.regions.ancients.relic_item>0):return false
	return true
static func validate(w: Dictionary) -> bool:
	if not enabled(w):return true
	var C=load("res://scripts/cosmetics.gd");var s=w.kingdom.adventure.regions.ancients;var r=run_of(w)
	if (not w.kingdom.claimed.has("main_22") and not load("res://scripts/parallel_play.gd").enabled(w)) or not C.shape(s,["version","relic_item","returned","researched"]) or not C.number(s.version,1,1,true) or not C.number(s.relic_item,0,100000,true) or not s.returned is bool or not s.researched is bool:return false
	if s.researched and not s.returned:return false
	if s.returned and s.relic_item==0:return false
	var relics=w.kingdom.industry.items.filter(func(item):return item.recipe=="sun_relic")
	if s.relic_item==0:return relics.is_empty()
	return relics.size()==1 and relics[0].id==s.relic_item and not r.is_empty() and r.loot.any(func(l):return l.recipe=="sun_relic" and l.taken) and progress(w,"warden")==1
