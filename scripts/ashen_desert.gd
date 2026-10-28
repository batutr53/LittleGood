extends RefCounted
const MAP=preload("res://scripts/ashen_desert_map.gd")
const MATERIALS=["desert_crystal"]
const FLAGS=["entered","oasis","kill","picked","banked","returned","registered"]
const KINDS=["sand_stalker","dune_scorpion","ruin_sentinel"]
static func enabled(w: Dictionary) -> bool:return int(w.get("kingdom",{}).get("adventure",{}).get("regions",{}).get("version",1)) in [2,3]
static func mine_found(w: Dictionary) -> bool:
	var a=w.kingdom.adventure;var r=a.run if a.run.get("region","")=="iron_hills" else a.get("regions",{}).get("stored",{}).get("iron_hills",{})
	return r.get("landmark",false)
static func enable(w: Dictionary) -> bool:
	if not load("res://scripts/hero.gd").writable(w) or ((w.kingdom.claimed.size()<21 or not mine_found(w)) and not load("res://scripts/parallel_play.gd").enabled(w)):return false
	if enabled(w):return true
	w.kingdom.adventure.regions.version=2;var q={}
	for flag in FLAGS:q[flag]=false
	w.kingdom.adventure.regions.quest=q
	w.kingdom.stock.desert_crystal=0
	return true
static func create(id: int,paused: bool,seed_value: int) -> Dictionary:
	var r=load("res://scripts/regions.gd").create(id,paused,seed_value)
	r.region="ashen_desert";r.nodes={"crystal":false};r.poison_until=0;r.poison_next=0;r.recovered=false;r.road=false
	r.enemies=[];var index=1
	for row in [["sand_stalker",620,1140],["dune_scorpion",760,640],["ruin_sentinel",650,350]]:
		var data=load("res://scripts/adventure.gd").enemies()[row[0]]
		r.enemies.append({"id":index,"kind":row[0],"x":row[1],"y":row[2],"hp":int(data.health),"state":"idle","timer":0,"aimx":0,"aimy":0,"pattern":0});index+=1
	return r
static func progress(w: Dictionary,key: String) -> float:
	return 1 if enabled(w) and w.kingdom.adventure.regions.quest.get(key,false) else 0
static func poisoned(r: Dictionary) -> bool:return int(r.get("poison_next",0))>0 and int(r.poison_next)<=int(r.poison_until)
static func status_step(w: Dictionary) -> bool:
	if not load("res://scripts/hero.gd").writable(w):return false
	var r=w.kingdom.adventure.run;var h=w.kingdom.adventure.hero
	if r.get("region","")!="ashen_desert" or not r.active:return false
	var hit=false
	while poisoned(r) and r.clock>=r.poison_next and not h.defeated:
		r.poison_next+=1000;h.hp=maxi(0,int(h.hp)-2);h.defeated=h.hp==0;hit=true
	if not poisoned(r) or h.defeated:r.poison_next=0;r.poison_until=0
	return hit
static func poison(w: Dictionary) -> void:
	if not load("res://scripts/hero.gd").writable(w) or w.kingdom.adventure.run.get("region","")!="ashen_desert" or not w.kingdom.adventure.run.active or w.kingdom.adventure.hero.defeated:return
	var r=w.kingdom.adventure.run;r.poison_until=r.clock+4000;r.poison_next=r.clock+1000
static func line_clear(from: Vector2,to: Vector2) -> bool:
	var steps=maxi(1,ceili(from.distance_to(to)/16))
	for i in range(1,steps+1):
		if not MAP.clear(from.lerp(to,float(i)/steps),false,2):return false
	return true
static func enemy_step(w: Dictionary,e: Dictionary,mover: Callable) -> Array:
	var A=load("res://scripts/adventure.gd");var r=w.kingdom.adventure.run;var d=A.enemies()[e.kind];var p=Vector2(r.x,r.y);var ep=Vector2(e.x,e.y);var offset=p-ep;var distance=offset.length();var cues=[]
	e.timer=maxi(0,int(e.timer)-50)
	if e.state=="windup":
		if e.timer>0:return cues
		var hit=false
		if e.kind=="ruin_sentinel":hit=p.distance_to(Vector2(e.aimx,e.aimy))<65 and line_clear(ep,p)
		elif e.kind=="dune_scorpion":hit=distance<107 and offset.normalized().dot((Vector2(e.aimx,e.aimy)-ep).normalized())>.2
		else:hit=distance<65
		if hit and A.hurt(w,int(d.attack)):
			cues.append("hurt")
			if e.kind=="dune_scorpion":poison(w);cues.append("poison")
		e.state="recover";e.timer=int(d.cooldown);return cues
	if e.state=="recover" and e.timer>0:
		if e.kind=="sand_stalker" and e.timer>int(d.cooldown)-350:
			var away=-offset.normalized() if distance>1 else Vector2.LEFT
			var moved=A.move_actor(w,int(e.id),ep,(away+away.orthogonal()).normalized()*float(d.speed)*.05,mover);e.x=roundi(moved.x);e.y=roundi(moved.y)
		return cues
	if e.kind=="ruin_sentinel" and p.distance_to(Vector2(650,350))>330:
		e.state="guard";var moved=A.move_actor(w,int(e.id),ep,(Vector2(650,350)-ep).limit_length(float(d.speed)*.05),mover);e.x=roundi(moved.x);e.y=roundi(moved.y);return cues
	if distance>300:e.state="idle";return cues
	if distance<=float(d.range) and (e.kind!="ruin_sentinel" or line_clear(ep,p)):
		e.state="windup";e.timer=int(d.warning);e.aimx=r.x;e.aimy=r.y;return cues
	e.state="chase";var motion=offset.normalized()*float(d.speed)*.05
	var moved=A.move_actor(w,int(e.id),ep,motion,mover)
	if moved.distance_to(ep)<1:moved=A.move_actor(w,int(e.id),ep,motion.orthogonal(),mover)
	e.x=roundi(moved.x);e.y=roundi(moved.y);return cues
static func interact(w: Dictionary) -> String:
	if not load("res://scripts/hero.gd").writable(w) or w.kingdom.adventure.run.get("region","")!="ashen_desert" or not w.kingdom.adventure.run.active or w.kingdom.adventure.hero.defeated:return ""
	var r=w.kingdom.adventure.run;var p=Vector2(r.x,r.y);var q=w.kingdom.adventure.regions.quest
	if p.distance_to(MAP.LANDMARK)<85:
		if not r.landmark:
			r.landmark=true;q.oasis=true;load("res://scripts/kingdom.gd").record(w,"exploration","desert_oasis");return "oasis"
		if not r.recovered and w.kingdom.adventure.hero.hp<load("res://scripts/hero.gd").stats(w).health:
			r.recovered=true;r.poison_next=0;r.poison_until=0;w.kingdom.adventure.hero.hp=mini(int(load("res://scripts/hero.gd").stats(w).health),int(w.kingdom.adventure.hero.hp)+35);return "oasis_heal"
	if not r.road and p.distance_to(MAP.ROAD)<85:r.road=true;load("res://scripts/kingdom.gd").record(w,"exploration","ancient_road");return "road"
	if not r.nodes.crystal and p.distance_to(MAP.CRYSTAL)<85:
		var A=load("res://scripts/adventure.gd");var capacity=load("res://scripts/regions.gd").capacity(w)
		if w.kingdom.stock.desert_crystal+(int(r.cargo.get("desert_crystal",0))+6)*1000>capacity:return "full"
		A.drop(r,92000,MAP.CRYSTAL,"desert_crystal",6)
		if not A.pickup(w,r.loot.filter(func(l):return l.id==92000)[0]):return "full"
		r.nodes.crystal=true;return "crystal"
	return ""
static func returning(w: Dictionary) -> void:
	var r=w.kingdom.adventure.run;var q=w.kingdom.adventure.regions.quest
	if int(r.cargo.get("desert_crystal",0))>0:q.banked=true
	if not w.kingdom.adventure.hero.defeated and q.oasis and q.kill and q.picked and q.banked:q.returned=true
	r.poison_next=0;r.poison_until=0
static func register(w: Dictionary) -> bool:
	if not load("res://scripts/hero.gd").writable(w) or not enabled(w):return false
	var a=w.kingdom.adventure;var q=a.regions.quest
	if a.run.get("active",false) or not q.returned or q.registered or w.kingdom.stock.desert_crystal<1000:return false
	w.kingdom.stock.desert_crystal-=1000;q.registered=true;load("res://scripts/kingdom.gd").record(w,"exploration","desert_registered");return true
static func can_spend(w: Dictionary,amount: int) -> bool:
	if not enabled(w):return false
	var q=w.kingdom.adventure.regions.quest
	return w.kingdom.stock.desert_crystal>=amount+(1000 if q.picked and not q.registered else 0)
static func validate_run(w: Dictionary,r: Dictionary) -> bool:
	var C=load("res://scripts/cosmetics.gd")
	if not enabled(w) or not C.shape(r.nodes,["crystal"]) or not r.nodes.crystal is bool or not r.recovered is bool or not r.road is bool or r.harvest or r.chest:return false
	for key in ["poison_until","poison_next"]:
		if not C.number(r[key],0,int(r.clock)+4000,true):return false
	if (r.poison_next==0)!=(r.poison_until==0) or r.poison_next>r.poison_until or (r.poison_next>0 and (r.poison_next<=r.clock or not r.active or w.kingdom.adventure.hero.defeated)):return false
	var rows=r.loot.filter(func(l):return l.id==92000)
	if r.nodes.crystal:
		if rows.size()!=1 or not rows[0].taken or rows[0].resource!="desert_crystal" or rows[0].amount!=6 or rows[0].recipe!="" or Vector2(rows[0].x,rows[0].y)!=MAP.CRYSTAL:return false
	elif not rows.is_empty():return false
	return true
static func validate(w: Dictionary) -> bool:
	if not enabled(w):return true
	var C=load("res://scripts/cosmetics.gd");var q=w.kingdom.adventure.regions.quest
	if not C.shape(q,FLAGS) or (not mine_found(w) and not load("res://scripts/parallel_play.gd").enabled(w)):return false
	for flag in FLAGS:
		if not q[flag] is bool:return false
	if q.registered and not q.returned:return false
	if q.returned and not (q.oasis and q.kill and q.picked and q.banked):return false
	if q.banked and not q.picked:return false
	var a=w.kingdom.adventure;var r=a.run if a.run.get("region","")=="ashen_desert" else a.regions.stored.get("ashen_desert",{})
	if q.entered!=not r.is_empty():return false
	if q.oasis!=r.get("landmark",false):return false
	if q.kill!=(not r.is_empty() and r.enemies.any(func(e):return e.hp==0)):return false
	if q.picked!=(not r.is_empty() and r.loot.any(func(l):return l.taken and l.resource=="desert_crystal")):return false
	return true
