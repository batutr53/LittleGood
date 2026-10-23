extends RefCounted
const H=preload("res://scripts/hero.gd")
const I=preload("res://scripts/industry.gd")
const MAP=preload("res://scripts/wildwood_map.gd")
const STEP=50
static var enemy_data: Dictionary={}
static func enemies() -> Dictionary:
	if enemy_data.is_empty():
		for e in JSON.parse_string(FileAccess.get_file_as_string("res://assets/adventure/enemies.json")):enemy_data[e.id]=e
	return enemy_data
static func new_enemies() -> Array:
	var result=[];var id=1
	for row in [["wolf",730,1120],["thorn",730,760],["spider",240,400]]:
		result.append({"id":id,"kind":row[0],"x":row[1],"y":row[2],"hp":int(enemies()[row[0]].health),"state":"idle","timer":0,"aimx":0,"aimy":0,"pattern":0});id+=1
	return result
static func enter(w: Dictionary,home_paused: bool=false) -> bool:
	if not H.writable(w) or w.kingdom.claimed.size()<11 or H.progress(w,"hero_armed")==0:return false
	var a=w.kingdom.adventure
	if a.run.is_empty():
		a.run={"id":int(a.next_run),"active":true,"home_paused":home_paused,"clock":0,"x":240,"y":1260,"facing":[0,-1000],"invulnerable":0,"dash":0,"swing":0,"enemies":new_enemies(),"loot":[],"cargo":{},"picked":0,"chest":false,"harvest":false,"landmark":false,"rng":str(int(w.seed)+int(a.next_run)*7919)};a.next_run+=1
	else:a.run.active=true;a.run.home_paused=home_paused
	return true
static func exit(w: Dictionary) -> bool:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return false
	var a=w.kingdom.adventure;var r=a.run
	for key in r.cargo:w.kingdom.stock[key]+=int(r.cargo[key])*1000
	H.event(w,"banked",int(r.picked));r.cargo={};r.picked=0;r.active=false
	H.event(w,"returned");a.hero.hp=int(H.stats(w).health);a.hero.defeated=false
	for key in a.hero.cooldowns:a.hero.cooldowns[key]=0
	r.x=240;r.y=1260;return true
static func revisit(w: Dictionary) -> bool:
	if not H.writable(w):return false
	var r=w.kingdom.adventure.run
	if r.is_empty() or r.active or r.enemies.any(func(e):return e.hp>0) or r.loot.any(func(l):return not l.taken):return false
	w.kingdom.adventure.run={};return true
static func move_actor(w: Dictionary,id: int,p: Vector2,delta: Vector2,mover: Callable) -> Vector2:
	return mover.call(id,p,delta) if mover.is_valid() else MAP.move(p,delta,w.kingdom.claimed.size()<14)
static func step(w: Dictionary,input: Dictionary,mover: Callable=Callable()) -> Array:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return []
	var a=w.kingdom.adventure;var r=a.run;var h=a.hero;r.clock+=STEP
	var feedback=[]
	for key in h.cooldowns:h.cooldowns[key]=maxi(0,int(h.cooldowns[key])-STEP)
	r.invulnerable=maxi(0,int(r.invulnerable)-STEP);r.swing=maxi(0,int(r.swing)-STEP)
	r.dash=maxi(0,int(r.get("dash",0))-STEP)
	if h.defeated:return []
	var direction=Vector2(input.get("move",Vector2.ZERO)).limit_length(1)
	if input.get("dodge",false) and h.cooldowns.dodge==0:
		h.cooldowns.dodge=1200;r.invulnerable=300;r.dash=250;H.event(w,"dodged");feedback.append("dodge")
	if direction.length()>.1:r.facing=[roundi(direction.x*1000),roundi(direction.y*1000)]
	if r.dash>0 and direction.length()<.1:direction=Vector2(r.facing[0],r.facing[1]).normalized()
	var p=move_actor(w,0,Vector2(r.x,r.y),direction*(450 if r.dash>0 else int(H.stats(w).speed))*.05,mover);r.x=roundi(p.x);r.y=roundi(p.y)
	if input.get("heal",false) and heal(w):feedback.append("heal")
	if (input.get("attack",false) and h.cooldowns.attack==0) or (input.get("skill",false) and h.cooldowns.skill==0):
		var heavy=input.get("skill",false) and h.cooldowns.skill==0
		h.cooldowns.attack=500
		if heavy:h.cooldowns.skill=4000
		r.swing=200
		var aim=Vector2(input.get("aim",Vector2.ZERO));var nearest=INF
		if aim.length()<.1:
			for e in r.enemies:
				var distance=p.distance_to(Vector2(e.x,e.y))
				if e.hp>0 and distance<nearest:nearest=distance;aim=Vector2(e.x,e.y)-p
		if aim.length()>.1:r.facing=[roundi(aim.normalized().x*1000),roundi(aim.normalized().y*1000)]
		feedback.append("swing")
		for e in r.enemies:
			var offset=Vector2(e.x,e.y)-p
			if e.hp<=0 or offset.length()>(105 if heavy else 78):continue
			if not heavy and offset.length()>1 and offset.normalized().dot(Vector2(r.facing[0],r.facing[1]).normalized())<.15:continue
			var rng=RandomNumberGenerator.new();rng.state=int(r.rng);var critical=rng.randi_range(0,999)<int(H.stats(w).crit);r.rng=str(rng.state)
			var hit=maxi(1,roundi(int(H.stats(w).attack)*(1.6 if heavy else 1.0)*(1.5 if critical else 1.0))-int(enemies()[e.kind].defense))
			e.hp=maxi(0,int(e.hp)-hit);feedback.append({"damage":hit,"x":e.x,"y":e.y})
			if e.hp==0:defeat_enemy(w,e);feedback.append("kill")
	for e in r.enemies:
		if e.hp<=0:continue
		var data=enemies()[e.kind];var ep=Vector2(e.x,e.y);var offset=p-ep;var distance=offset.length();e.timer=maxi(0,int(e.timer)-STEP)
		if e.state=="windup":
			if e.timer==0:
				var hit=false
				if e.kind=="spider":
					var landing=Vector2(e.aimx,e.aimy);var moved=move_actor(w,int(e.id),ep,(landing-ep).limit_length(180),mover);e.x=roundi(moved.x);e.y=roundi(moved.y);hit=p.distance_to(landing)<60
				else:hit=distance<float(data.range)+12
				if hit and hurt(w,int(data.attack)):feedback.append("hurt")
				e.state="recover";e.timer=int(data.cooldown)
			continue
		if e.state=="recover" and e.timer>0:continue
		if distance>270:e.state="idle";continue
		if distance<=float(data.range):e.state="windup";e.timer=int(data.warning);e.aimx=r.x;e.aimy=r.y;continue
		e.state="chase";var motion=offset.normalized()*float(data.speed)*.05
		var moved=move_actor(w,int(e.id),ep,motion,mover)
		if moved.distance_to(ep)<1:motion=offset.normalized().orthogonal()*float(data.speed)*.05;moved=move_actor(w,int(e.id),ep,motion,mover)
		e.x=roundi(moved.x);e.y=roundi(moved.y)
	return feedback
static func hurt(w: Dictionary,raw: int) -> bool:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return false
	var a=w.kingdom.adventure;var h=a.hero
	if h.defeated or a.run.invulnerable>0:return false
	h.hp=maxi(0,int(h.hp)-maxi(1,raw-int(H.stats(w).defense)));a.run.invulnerable=250;h.defeated=h.hp==0;return true
static func heal(w: Dictionary) -> bool:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return false
	var a=w.kingdom.adventure;var h=a.hero
	if h.defeated or h.hp>=H.stats(w).health or h.cooldowns.heal>0:return false
	var potion=I.item(w,0)
	for item in w.kingdom.industry.items:
		if item.recipe=="healing_potion":potion=item;break
	if not potion.is_empty():w.kingdom.industry.items.erase(potion);h.hp=mini(int(H.stats(w).health),int(h.hp)+35)
	elif a.run.cargo.get("herb",0)>0:a.run.cargo.herb-=1;h.hp=mini(int(H.stats(w).health),int(h.hp)+25)
	elif w.kingdom.stock.herb>=1000:w.kingdom.stock.herb-=1000;h.hp=mini(int(H.stats(w).health),int(h.hp)+25)
	else:return false
	h.cooldowns.heal=1500;H.event(w,"healed");return true
static func drop(r: Dictionary,id: int,p: Vector2,resource: String,amount: int,recipe: String="") -> void:
	if r.loot.any(func(l):return int(l.id)==id):return
	r.loot.append({"id":id,"x":roundi(p.x),"y":roundi(p.y),"resource":resource,"amount":amount,"recipe":recipe,"taken":false})
static func defeat_enemy(w: Dictionary,e: Dictionary) -> void:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return
	var candidates=w.kingdom.adventure.run.enemies.filter(func(other):return int(other.id)==int(e.id))
	if candidates.is_empty():return
	e=candidates[0]
	if e.state=="dead" or e.hp>0:return
	e.state="dead";var a=w.kingdom.adventure;var r=a.run;var data=enemies()[e.kind];var before=int(H.stats(w).health);a.hero.xp+=int(data.xp);a.hero.hp+=int(H.stats(w).health)-before;H.event(w,"kills")
	drop(r,int(e.id)*10,Vector2(e.x,e.y),data.material,int(data.quantity))
	var rng=RandomNumberGenerator.new();rng.state=int(r.rng);var total=0
	for row in data.weights:total+=int(row[1])
	var pick=rng.randi_range(1,total);r.rng=str(rng.state)
	for row in data.weights:
		pick-=int(row[1])
		if pick<=0:drop(r,int(e.id)*10+1,Vector2(e.x+22,e.y),row[0],1);break
static func pickup(w: Dictionary,l: Dictionary) -> bool:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active or w.kingdom.adventure.hero.defeated:return false
	var r=w.kingdom.adventure.run
	var candidates=r.loot.filter(func(other):return int(other.id)==int(l.id))
	if candidates.is_empty():return false
	l=candidates[0]
	if l.taken or Vector2(r.x,r.y).distance_to(Vector2(l.x,l.y))>90:return false
	if not l.recipe.is_empty():
		var state=w.kingdom.industry
		if state.items.size()+state.queue.size()>=I.MAX_ITEMS:return false
		state.items.append({"id":int(state.next_item),"recipe":l.recipe});state.next_item+=1
	else:
		if w.kingdom.stock[l.resource]+(int(r.cargo.get(l.resource,0))+int(l.amount))*1000>10000000:return false
		r.cargo[l.resource]=int(r.cargo.get(l.resource,0))+int(l.amount)
	l.taken=true;r.picked+=1;H.event(w,"picked");return true
static func interact(w: Dictionary) -> String:
	if not H.writable(w) or w.kingdom.adventure.run.is_empty() or not w.kingdom.adventure.run.active:return ""
	if w.kingdom.adventure.hero.defeated:return ""
	var r=w.kingdom.adventure.run;var p=Vector2(r.x,r.y)
	for l in r.loot:
		if pickup(w,l):return "loot"
	if p.distance_to(MAP.LANDMARK)<85 and not r.landmark:r.landmark=true;H.event(w,"landmark");return "landmark"
	if p.distance_to(MAP.HERBS)<85 and not r.harvest:r.harvest=true;drop(r,90001,MAP.HERBS,"herb",3);H.event(w,"harvest");return "herb"
	if p.distance_to(MAP.CHEST)<85 and not r.chest:r.chest=true;drop(r,90002,MAP.CHEST,"gold",4);drop(r,90003,MAP.CHEST+Vector2(20,0),"",1,"reinforced_shield");H.event(w,"chest");return "chest"
	return ""
static func normalize(w: Dictionary) -> void:
	var r=w.kingdom.adventure.run
	if r.is_empty():return
	for key in ["id","clock","x","y","invulnerable","swing","picked"]:r[key]=int(r[key])
	r.dash=int(r.get("dash",0))
	for i in range(2):r.facing[i]=int(r.facing[i])
	for key in r.cargo:r.cargo[key]=int(r.cargo[key])
	for e in r.enemies:
		for key in ["id","x","y","hp","timer","aimx","aimy","pattern"]:e[key]=int(e[key])
	for l in r.loot:
		for key in ["id","x","y","amount"]:l[key]=int(l[key])
static func validate(w: Dictionary) -> bool:
	var r=w.kingdom.adventure.run
	if r.is_empty():return true
	var C=preload("res://scripts/cosmetics.gd")
	var keys=["id","active","home_paused","clock","x","y","facing","invulnerable","swing","enemies","loot","cargo","picked","chest","harvest","landmark","rng"]
	if r.has("dash"):keys.append("dash")
	if not C.shape(r,keys) or (r.has("dash") and not C.number(r.dash,0,300,true)):return false
	for key in ["active","home_paused","chest","harvest","landmark"]:
		if not r[key] is bool:return false
	for key in ["id","clock","x","y","invulnerable","swing","picked"]:
		if not C.number(r[key],0,100000000,true):return false
	if r.x>960 or r.y>1440 or not r.facing is Array or r.facing.size()!=2 or not r.rng is String or not r.rng.is_valid_int() or not r.cargo is Dictionary or r.cargo.size()>9:return false
	for n in r.facing:
		if not C.number(n,-1000,1000,true):return false
	for key in r.cargo:
		if not key in w.kingdom.stock or not C.number(r.cargo[key],0,1000,true):return false
	if not r.enemies is Array or r.enemies.size()>4 or not r.loot is Array or r.loot.size()>20:return false
	var ids=[]
	for e in r.enemies:
		if not C.shape(e,["id","kind","x","y","hp","state","timer","aimx","aimy","pattern"]) or not enemies().has(e.get("kind")) or not C.number(e.id,1,4,true) or ids.has(int(e.id)) or not e.state in ["idle","chase","windup","recover","dead"]:return false
		ids.append(int(e.id))
		for key in ["x","y","hp","timer","aimx","aimy","pattern"]:
			if not C.number(e[key],0,100000,true):return false
		if e.hp>int(enemies()[e.kind].health) or (e.hp==0)!=(e.state=="dead") or e.x>960 or e.y>1440:return false
	ids=[]
	for l in r.loot:
		if not C.shape(l,["id","x","y","resource","amount","recipe","taken"]) or not C.number(l.id,1,100000,true) or ids.has(int(l.id)) or not l.taken is bool:return false
		ids.append(int(l.id))
		if not C.number(l.x,0,960,true) or not C.number(l.y,0,1440,true) or not C.number(l.amount,1,10,true) or not l.recipe is String or not l.resource is String:return false
		if l.recipe.is_empty():
			if not w.kingdom.stock.has(l.resource):return false
		elif not I.recipes().has(l.recipe) or not l.resource.is_empty() or l.amount!=1:return false
	return true
