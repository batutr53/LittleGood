extends RefCounted
const I=preload("res://scripts/industry.gd")
const CAP=20
const TYPES={"militia":{"attack":11,"defense":3,"range":48,"speed":100},"spearman":{"attack":14,"defense":2,"range":78,"speed":90},"archer":{"attack":10,"defense":1,"range":190,"speed":85}}
const FORMATIONS={"balanced":[100,100],"defensive":[80,140],"assault":[130,75]}
static func enabled(w: Dictionary) -> bool:return w.has("kingdom") and w.kingdom.has("military")
static func writable(w: Dictionary) -> bool:return enabled(w) and not w.get("_read_only",false)
static func K():return load("res://scripts/kingdom.gd")
static func enable(w: Dictionary) -> bool:
	if w.get("_read_only",false) or enabled(w) or not w.has("kingdom") or w.kingdom.version!=3 or w.kingdom.claimed.size()!=15 or w.kingdom.adventure.run.get("active",false):return false
	w.kingdom.military={"version":1,"next_unit":1,"next_battle":1,"last_tick":int(w.tick),"units":[],"formation":"balanced","formed":false,"commander":1,"battle":{},"victories":{"raid":false,"camp":false},"returned":{"raid":false,"camp":false}}
	return true
static func unit(w: Dictionary,id: int) -> Dictionary:
	if enabled(w):
		for u in w.kingdom.military.units:
			if int(u.id)==id:return u
	return {}
static func worker_reserved(w: Dictionary,id: int) -> bool:return enabled(w) and w.kingdom.military.units.any(func(u):return int(u.worker)==id)
static func item_reserved(w: Dictionary,id: int) -> bool:return enabled(w) and w.kingdom.military.units.any(func(u):return int(u.gear)==id)
static func available(w: Dictionary) -> Array:return w.kingdom.military.units.filter(func(u):return u.status=="ready" and u.hp>0 and not load("res://scripts/trade.gd").guard_reserved(w,int(u.id))) if enabled(w) else []
static func train(w: Dictionary,worker: int,kind: String,gear: int,barracks: int) -> bool:
	if not writable(w) or not TYPES.has(kind) or w.kingdom.military.units.size()>=6 or K().home(w).food<3 or not K().afford(w,{"gold":2}) or worker_reserved(w,worker):return false
	var citizens=w.kingdom.workers.filter(func(c):return int(c.id)==worker and c.building==0)
	if citizens.is_empty() or not w.kingdom.buildings.any(func(b):return int(b.id)==barracks and b.kind=="barracks" and K().ready(b)) or K().assigned(w,barracks).is_empty():return false
	var owned=I.item(w,gear)
	if owned.is_empty() or owned.recipe!=kind+"_kit" or item_reserved(w,gear):return false
	I.equip(w,worker,0);K().spend(w,{"gold":2});K().home(w).food-=3
	var m=w.kingdom.military;m.units.append({"id":int(m.next_unit),"worker":worker,"kind":kind,"gear":gear,"barracks":barracks,"hp":100,"status":"training","progress":0,"xp":0});m.next_unit+=1
	return true
static func retire(w: Dictionary,id: int) -> bool:
	if not writable(w):return false
	var u=unit(w,id)
	if u.is_empty() or not u.status in ["ready","injured"]:return false
	if load("res://scripts/trade.gd").guard_reserved(w,id):return false
	if w.kingdom.military.battle.get("active",false):return false
	if w.kingdom.military.battle.get("friends",[]).any(func(a):return int(a.id)==id):w.kingdom.military.battle={}
	w.kingdom.military.units.erase(u);return true
static func recover(w: Dictionary,id: int) -> bool:
	if not writable(w) or K().home(w).food<2 or not K().afford(w,{"gold":1}):return false
	var u=unit(w,id)
	if u.is_empty() or not u.status in ["injured","ready"] or u.hp>=100 or w.kingdom.military.battle.get("active",false):return false
	if load("res://scripts/trade.gd").guard_reserved(w,id):return false
	K().home(w).food-=2;K().spend(w,{"gold":1});u.status="recovering";u.progress=0;return true
static func tick(w: Dictionary) -> void:
	if not writable(w) or w.kingdom.military.last_tick>=w.tick:return
	var m=w.kingdom.military;m.last_tick=int(w.tick)
	K().home(w).food=maxf(0,K().home(w).food-m.units.size()*.01)
	if K().home(w).food<2:return
	var budgets={}
	for u in m.units:
		if not u.status in ["training","recovering"]:continue
		var id=int(u.barracks)
		if not budgets.has(id):budgets[id]=K().assigned(w,id).size()*1000
		var work=mini(int(budgets[id]),6000-int(u.progress));u.progress+=work;budgets[id]-=work
		if u.progress>=6000:u.status="ready";u.hp=100
static func formation(w: Dictionary,value: String) -> bool:
	if not writable(w) or not FORMATIONS.has(value):return false
	w.kingdom.military.formation=value;w.kingdom.military.formed=true;return true
static func stats(w: Dictionary,u: Dictionary,defending: bool=false) -> Dictionary:
	var s=I.recipes()[I.item(w,int(u.gear)).recipe].effects.duplicate();var f=FORMATIONS[w.kingdom.military.formation];var veteran=mini(4,int(u.xp)/40)
	s.attack=maxi(1,int((int(s.attack)+veteran)*f[0]/100.0));s.defense=maxi(0,int((int(s.defense)+veteran)*f[1]/100.0))
	if defending:s.attack+=K().count(w,"watchtower")*2;s.defense+=K().count(w,"wall")*3
	return s
static func progress(w: Dictionary,key: String) -> float:
	if not enabled(w):return 0
	var m=w.kingdom.military
	if key=="trained":return available(w).size()
	if key=="instructor":
		var count=0
		for b in w.kingdom.buildings:
			if b.kind=="barracks" and K().ready(b):count+=K().assigned(w,int(b.id)).size()
		return count
	if key=="formation":return int(m.formed)
	if key in m.victories:return int(m.victories[key])
	if key.ends_with("_returned"):return int(m.returned.get(key.trim_suffix("_returned"),false))
	return 0
static func deploy(w: Dictionary,mission: String,ids: Array) -> bool:
	if not writable(w) or not mission in ["raid","camp"] or ids.is_empty() or ids.size()>6 or K().home(w).food<3 or w.kingdom.adventure.run.get("active",false):return false
	var m=w.kingdom.military
	if m.battle.get("active",false) or w.kingdom.claimed.size()<(18 if mission=="raid" else 19):return false
	var seen=[]
	for id in ids:
		var u=unit(w,int(id))
		if seen.has(int(id)) or u.is_empty() or u.status!="ready" or u.hp<=0 or load("res://scripts/trade.gd").guard_reserved(w,int(id)):return false
		seen.append(int(id))
	K().home(w).food-=3
	var friends=[];var enemies=[]
	for i in range(ids.size()):
		unit(w,int(ids[i])).status="deployed";friends.append({"id":int(ids[i]),"x":150,"y":260+i*65,"timer":0,"target":0,"state":"move"})
	var kinds=["raider","raider","bow"] if mission=="raid" else ["raider","bow","captain"]
	for i in range(kinds.size()):enemies.append({"id":i+1,"kind":kinds[i],"hp":150 if kinds[i]=="captain" else 48,"x":760,"y":260+i*95,"timer":0,"target":0,"state":"move"})
	m.battle={"id":int(m.next_battle),"mission":mission,"active":true,"clock":0,"order":"advance","result":"","rewarded":false,"friends":friends,"enemies":enemies};m.next_battle+=1;return true
static func order(w: Dictionary,value: String) -> bool:
	if not writable(w) or not value in ["advance","hold","retreat"] or not w.kingdom.military.battle.get("active",false):return false
	w.kingdom.military.battle.order=value
	if value=="retreat" and w.kingdom.military.battle.result.is_empty():w.kingdom.military.battle.result="retreat"
	return true
static func move(p: Vector2,d: Vector2,camp: bool) -> Vector2:
	var result=(p+d).clamp(Vector2(45,190),Vector2(915,720))
	if camp and Rect2(430,350,90,120).grow(14).has_point(result):
		result=(p+Vector2(0,-absf(d.length()) if p.y<410 else absf(d.length()))).clamp(Vector2(45,190),Vector2(915,720))
	return result.round()
static func step(w: Dictionary) -> Array:
	if not writable(w) or not w.kingdom.military.battle.get("active",false):return []
	var m=w.kingdom.military;var b=m.battle;var cues=[]
	if not b.result.is_empty():return cues
	b.clock+=50
	for friendly in [true,false]:
		var actors=b.friends if friendly else b.enemies;var targets=b.enemies if friendly else b.friends
		for actor in actors:
			var u=unit(w,int(actor.id)) if friendly else actor
			if u.hp<=0:continue
			var s=stats(w,u,b.mission=="raid") if friendly else {"attack":14 if u.kind=="captain" else 8,"defense":4 if u.kind=="captain" else 1,"range":180 if u.kind=="bow" else 52,"speed":75}
			actor.timer=maxi(0,int(actor.timer)-50)
			var alive=targets.filter(func(t):return t.hp>0 if friendly else unit(w,int(t.id)).hp>0)
			if alive.is_empty():continue
			var p=Vector2(actor.x,actor.y);alive.sort_custom(func(a,c):return p.distance_squared_to(Vector2(a.x,a.y))<p.distance_squared_to(Vector2(c.x,c.y)))
			var target=alive[0];var t=target if friendly else unit(w,int(target.id));var offset=Vector2(target.x,target.y)-p
			if actor.state=="windup":
				if actor.timer==0:
					var locked=targets.filter(func(a):return int(a.id)==int(actor.target))
					if not locked.is_empty():
						var victim=locked[0];var health=victim if friendly else unit(w,int(victim.id));var defense=int(health.get("defense",4 if health.get("kind")=="captain" else 1)) if friendly else int(stats(w,health,b.mission=="raid").defense)
						if health.hp>0 and p.distance_to(Vector2(victim.x,victim.y))<=int(s.range)+15:
							var damage=maxi(1,int(s.attack)-defense);health.hp=maxi(0,int(health.hp)-damage);cues.append({"x":victim.x,"y":victim.y,"damage":damage,"friendly":friendly})
							if not friendly and health.hp==0:health.status="injured";health.progress=0
					actor.state="recover";actor.timer=650
				continue
			if actor.timer>0:continue
			if offset.length()<=s.range:actor.state="windup";actor.target=int(target.id);actor.timer=450 if friendly else 650
			elif not friendly or b.order=="advance":
				var next=move(p,offset.normalized()*s.speed*.05,b.mission=="camp");actor.x=roundi(next.x);actor.y=roundi(next.y);actor.state="move"
	if b.enemies.all(func(e):return e.hp<=0):
		b.result="won"
		if not m.victories[b.mission]:
			m.victories[b.mission]=true;b.rewarded=true;w.kingdom.stock.gold+=4000;w.kingdom.stock.wood+=6000;K().record(w,"military",b.mission)
			for a in b.friends:unit(w,int(a.id)).xp+=20
	elif b.friends.all(func(a):return unit(w,int(a.id)).hp<=0):b.result="lost"
	return cues
static func return_home(w: Dictionary) -> bool:
	if not writable(w) or not w.kingdom.military.battle.get("active",false):return false
	var m=w.kingdom.military;var b=m.battle
	if b.result.is_empty():return false
	for a in b.friends:
		var u=unit(w,int(a.id));u.status="ready" if u.hp>0 else "injured"
	if b.result=="won":m.returned[b.mission]=true
	b.active=false;return true
static func normalize(w: Dictionary) -> void:
	if not enabled(w):return
	var m=w.kingdom.military
	for k in ["version","next_unit","next_battle","last_tick","commander"]:m[k]=int(m[k])
	for u in m.units:
		for k in ["id","worker","gear","barracks","hp","progress","xp"]:u[k]=int(u[k])
	if not m.battle.is_empty():
		for k in ["id","clock"]:m.battle[k]=int(m.battle[k])
		for a in m.battle.friends+m.battle.enemies:
			for k in ["id","x","y","timer","target"]:a[k]=int(a[k])
			if a.has("hp"):a.hp=int(a.hp)
static func validate(w: Dictionary) -> bool:
	if not enabled(w):return true
	var C=preload("res://scripts/cosmetics.gd");var m=w.kingdom.military
	if not C.shape(m,["version","next_unit","next_battle","last_tick","units","formation","formed","commander","battle","victories","returned"]) or w.kingdom.version!=3 or w.kingdom.claimed.size()<15:return false
	if not C.number(m.version,1,1,true) or not C.number(m.next_unit,1,100000,true) or not C.number(m.next_battle,1,100000,true) or not C.number(m.last_tick,0,w.tick,true) or not C.number(m.commander,1,1,true) or not m.formed is bool or not FORMATIONS.has(m.formation):return false
	for key in ["victories","returned"]:
		if not C.shape(m[key],["raid","camp"]):return false
		for value in m[key].values():
			if not value is bool:return false
	for key in ["raid","camp"]:
		if m.returned[key] and not m.victories[key]:return false
	if not m.units is Array or m.units.size()>6:return false
	var ids=[];var workers=[];var items=[]
	for u in m.units:
		if not C.shape(u,["id","worker","kind","gear","barracks","hp","status","progress","xp"]):return false
		if not C.number(u.id,1,m.next_unit-1,true) or ids.has(int(u.id)) or not TYPES.has(u.kind) or not u.status in ["training","ready","deployed","injured","recovering"]:return false
		for key in ["worker","gear","barracks"]:
			if not C.number(u[key],1,100000,true):return false
		if not C.number(u.hp,0,100,true) or not C.number(u.progress,0,6000,true) or not C.number(u.xp,0,100000,true):return false
		if u.status=="injured" and u.hp!=0:return false
		if u.status in ["training","ready","deployed"] and u.hp==0:return false
		if u.status in ["training","recovering"] and u.progress>=6000:return false
		if u.status in ["ready","deployed"] and u.progress!=6000:return false
		if workers.has(int(u.worker)) or items.has(int(u.gear)) or I.item(w,int(u.gear)).get("recipe")!=u.kind+"_kit":return false
		if not w.kingdom.workers.any(func(c):return int(c.id)==int(u.worker) and c.building==0) or not I.tool(w,int(u.worker)).is_empty():return false
		if not w.kingdom.buildings.any(func(b):return int(b.id)==int(u.barracks) and b.kind=="barracks"):return false
		ids.append(int(u.id));workers.append(int(u.worker));items.append(int(u.gear))
	if not m.battle is Dictionary:return false
	if m.battle.is_empty():return not m.units.any(func(u):return u.status=="deployed")
	var b=m.battle
	if not C.shape(b,["id","mission","active","clock","order","result","rewarded","friends","enemies"]) or not C.number(b.id,1,m.next_battle-1,true) or not C.number(b.clock,0,100000000,true) or not b.mission in ["raid","camp"] or not b.active is bool or not b.rewarded is bool or not b.order in ["advance","hold","retreat"] or not b.result in ["","won","lost","retreat"]:return false
	if not b.friends is Array or b.friends.is_empty() or b.friends.size()>6 or not b.enemies is Array or b.enemies.size()!=3:return false
	if not b.active and b.result.is_empty():return false
	if int(b.clock)%50!=0:return false
	var seen=[]
	var actors=b.friends+b.enemies
	for index in range(actors.size()):
		var a=actors[index];var enemy=index>=b.friends.size();var fields=["id","x","y","timer","target","state"]
		if enemy:fields.append_array(["kind","hp"])
		if not C.shape(a,fields) or not C.number(a.id,1,100000,true) or not C.number(a.x,45,915,true) or not C.number(a.y,190,720,true) or not C.number(a.timer,0,1000,true) or not C.number(a.target,0,100000,true) or not a.state in ["move","windup","recover"]:return false
		var key=("e" if enemy else "f")+str(int(a.id))
		if seen.has(key):return false
		seen.append(key)
		if enemy:
			if not C.number(a.id,1,3,true) or not a.kind in ["raider","bow","captain"] or not C.number(a.hp,0,150 if a.kind=="captain" else 48,true):return false
		elif not ids.has(int(a.id)) or (b.active and unit(w,int(a.id)).status!=("deployed" if unit(w,int(a.id)).hp>0 else "injured")):return false
	if b.result=="won" and (not b.enemies.all(func(e):return e.hp==0) or not m.victories[b.mission]):return false
	if b.result=="lost" and not b.friends.all(func(a):return unit(w,int(a.id)).hp==0):return false
	if b.rewarded and b.result!="won":return false
	if b.active and w.kingdom.adventure.run.get("active",false):return false
	return m.units.all(func(u):return u.status!="deployed" or (b.active and b.friends.any(func(a):return int(a.id)==int(u.id))))
