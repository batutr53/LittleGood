extends RefCounted
const M=preload("res://scripts/military.gd")
const I=preload("res://scripts/industry.gd")
const CAP=21 # E1 only; unfinished quests/regions are not unlocked.
const PRICES={"wood":[1000,250],"stone":[1500,350],"ore":[2500,600],"iron":[5000,1250],"leather":[3000,750],"herb":[2000,500]}
static var route_data={}
static func K():return load("res://scripts/kingdom.gd")
static func routes() -> Dictionary:
	if route_data.is_empty():
		for r in JSON.parse_string(FileAccess.get_file_as_string("res://assets/kingdom/trade_routes.json")):route_data[r.id]=r
	return route_data
static func enabled(w: Dictionary) -> bool:return w.get("kingdom",{}).has("trade")
static func writable(w: Dictionary) -> bool:return enabled(w) and not w.get("_read_only",false)
static func enable(w: Dictionary) -> bool:
	if w.get("_read_only",false) or enabled(w) or not M.enabled(w) or w.kingdom.claimed.size()!=20 or w.kingdom.military.battle.get("active",false) or w.kingdom.adventure.run.get("active",false):return false
	w.kingdom.trade={"version":1,"next_caravan":1,"last_tick":int(w.tick),"caravans":[],"inspected":false,"bought":0,"sold":0,"delivered":0};return true
static func active(c: Dictionary) -> bool:return c.state!="collected"
static func worker_reserved(w: Dictionary,id: int) -> bool:return enabled(w) and w.kingdom.trade.caravans.any(func(c):return active(c) and int(c.merchant)==id)
static func guard_reserved(w: Dictionary,id: int) -> bool:return enabled(w) and w.kingdom.trade.caravans.any(func(c):return active(c) and c.guards.has(id))
static func building_reserved(w: Dictionary,id: int) -> bool:return enabled(w) and w.kingdom.workers.any(func(c):return int(c.building)==id and worker_reserved(w,int(c.id)))
static func market(w: Dictionary) -> Array:return w.kingdom.buildings.filter(func(b):return b.kind=="marketplace" and K().ready(b)) if enabled(w) else []
static func merchants(w: Dictionary) -> Array:
	var result=[]
	for b in market(w):result.append_array(K().assigned(w,int(b.id)))
	return result
static func local_merchants(w: Dictionary) -> Array:
	var result=merchants(w)
	# A returned merchant can sell stock to make room for the waiting cargo.
	# Their caravan reservation still blocks another dispatch or job change.
	if enabled(w):
		for c in w.kingdom.trade.caravans:
			if c.state!="ready":continue
			for worker in w.kingdom.workers:
				if int(worker.id)==int(c.merchant) and not result.has(worker):result.append(worker)
	return result
static func inspect_prices(w: Dictionary) -> bool:
	if not writable(w) or market(w).is_empty():return false
	w.kingdom.trade.inspected=true;return true
static func transaction(w: Dictionary,good: String,quantity: Variant,buy: bool) -> bool:
	if not writable(w) or not PRICES.has(good) or not quantity is int or quantity<1 or quantity>20 or local_merchants(w).is_empty():return false
	var stock=w.kingdom.stock;var amount=quantity*1000;var price=int(PRICES[good][0 if buy else 1])*quantity
	if buy:
		if stock.gold<price or stock[good]+amount>roundi(K().storage(w)*1000):return false
		stock.gold-=price;stock[good]+=amount;w.kingdom.trade.bought=mini(1000000,int(w.kingdom.trade.bought)+quantity)
	else:
		if stock[good]<amount or stock.gold+price>10000000:return false
		stock[good]-=amount;stock.gold+=price;w.kingdom.trade.sold=mini(1000000,int(w.kingdom.trade.sold)+quantity)
	K().record(w,"trade",("buy:" if buy else "sell:")+good);return true
static func quote(w: Dictionary,route: String,cargo: Dictionary) -> Dictionary:
	if not routes().has(route) or cargo.is_empty() or cargo.size()>PRICES.size():return {}
	var r=routes()[route];var count=0;var payout=0
	for good in cargo:
		if not PRICES.has(good) or not cargo[good] is int or cargo[good]<1 or cargo[good]>8:return {}
		count+=cargo[good];payout+=cargo[good]*int(r.sell[good])
	if count>r.capacity:return {}
	return {"cargo_units":count,"payout":payout,"supplies":int(r.ticks)*200,"fee":int(r.fee),"ticks":int(r.ticks),"danger":int(r.danger)}
static func strength(w: Dictionary,guards: Array) -> int:
	var value=0
	for id in guards:
		var u=M.unit(w,int(id))
		if u.is_empty() or u.status!="ready":continue
		var s=M.stats(w,u);value+=int((int(s.attack)+int(s.defense))*int(u.hp)/100.0)
	return value
static func dispatch(w: Dictionary,route: String,merchant: int,guards: Array,cargo: Dictionary) -> int:
	if not writable(w) or guards.size()>2 or worker_reserved(w,merchant) or not merchants(w).any(func(c):return int(c.id)==merchant):return -1
	var t=w.kingdom.trade;var q=quote(w,route,cargo)
	if q.is_empty() or t.caravans.filter(func(c):return active(c)).size()>=2 or K().home(w).food<q.supplies/1000.0+3 or w.kingdom.stock.gold<q.fee:return -1
	var ids=[]
	for id in guards:
		if not id is int or ids.has(id) or not M.available(w).any(func(u):return int(u.id)==id):return -1
		ids.append(id)
	for good in cargo:
		if w.kingdom.stock[good]<cargo[good]*1000:return -1
	# All validation precedes the atomic reservation.
	for good in cargo:w.kingdom.stock[good]-=cargo[good]*1000
	K().home(w).food-=q.supplies/1000.0;w.kingdom.stock.gold-=q.fee
	var id=int(t.next_caravan);t.next_caravan+=1
	t.caravans.append({"id":id,"origin":"home","route":route,"merchant":merchant,"guards":guards.duplicate(),"cargo":cargo.duplicate(),"capacity":int(routes()[route].capacity),"supplies":int(q.supplies),"departed":int(w.tick),"progress":0,"leg_ticks":int(q.ticks),"state":"outbound","encountered":false,"outcome":"","sold":false,"payout":int(q.payout)})
	while t.caravans.size()>12:
		var old=t.caravans.filter(func(c):return not active(c))
		if old.is_empty():break
		t.caravans.erase(old[0])
	K().record(w,"trade","depart:"+route);return id
static func caravan(w: Dictionary,id: int) -> Dictionary:
	if enabled(w):
		for c in w.kingdom.trade.caravans:
			if int(c.id)==id:return c
	return {}
static func resolve(w: Dictionary,id: int,detour: bool) -> bool:
	if not writable(w):return false
	var c=caravan(w,id)
	if c.is_empty() or c.state!="blocked":return false
	if detour:
		if K().home(w).food<1.2:return false
		K().home(w).food-=1.2;c.supplies+=1200;c.leg_ticks+=6;c.outcome="detour";c.state="outbound"
	else:c.leg_ticks=maxi(1,int(c.progress));c.progress=0;c.state="returning";c.outcome="retreat"
	return true
static func tick(w: Dictionary) -> void:
	if not writable(w) or w.kingdom.trade.last_tick>=w.tick:return
	w.kingdom.trade.last_tick=int(w.tick)
	for c in w.kingdom.trade.caravans:
		if not c.state in ["outbound","returning"]:continue
		if c.supplies<100:c.state="blocked";continue
		c.progress+=1;c.supplies-=100
		if c.state=="outbound" and not c.encountered and c.progress>=int(routes()[c.route].ticks)/2:
			c.encountered=true
			if strength(w,c.guards)<int(routes()[c.route].danger):c.state="blocked";continue
			c.outcome="escorted"
		if c.progress>=c.leg_ticks:
			if c.state=="outbound":c.sold=true;c.state="returning";c.progress=0
			else:c.state="ready";K().record(w,"trade","return:"+c.route)
static func collect(w: Dictionary,id: int) -> bool:
	if not writable(w):return false
	var c=caravan(w,id)
	if c.is_empty() or c.state!="ready":return false
	if c.sold:
		if w.kingdom.stock.gold+c.payout>10000000:return false
		w.kingdom.stock.gold+=c.payout;w.kingdom.trade.delivered+=1
	else:
		for good in c.cargo:
			if w.kingdom.stock[good]+c.cargo[good]*1000>roundi(K().storage(w)*1000):return false
		for good in c.cargo:w.kingdom.stock[good]+=c.cargo[good]*1000
	K().home(w).food=minf(100,K().home(w).food+c.supplies/1000.0);c.supplies=0;c.state="collected";K().record(w,"trade","delivered:"+c.route);return true
static func salvage(w: Dictionary,id: int) -> bool:
	if w.get("_read_only",false) or not I.enabled(w) or M.item_reserved(w,id):return false
	if local_merchants(w).is_empty() and not w.kingdom.buildings.any(func(b):return b.kind=="forge" and K().ready(b) and not K().assigned(w,int(b.id)).is_empty()):return false
	var owned=I.item(w,id)
	if owned.is_empty() or I.recipes()[owned.recipe].get("category")=="artifact" or w.kingdom.industry.equipped.any(func(s):return int(s.item)==id) or w.kingdom.get("adventure",{}).get("hero",{}).get("equipment",{}).values().has(id):return false
	var refund=salvage_refund(w,id)
	w.kingdom.industry.items.erase(owned)
	for key in refund:w.kingdom.stock[key]+=refund[key]
	K().record(w,"trade","salvage:"+owned.recipe);return true
static func salvage_refund(w: Dictionary,id: int) -> Dictionary:
	var owned=I.item(w,id);var refund={}
	if owned.is_empty():return refund
	for key in I.recipes()[owned.recipe].cost:
		if PRICES.has(key):refund[key]=mini(int(I.recipes()[owned.recipe].cost[key])*500,maxi(0,roundi(K().storage(w)*1000)-int(w.kingdom.stock[key])))
	return refund
static func progress(w: Dictionary,key: String) -> float:
	if not enabled(w):return 0
	if key=="merchant":return merchants(w).size()+w.kingdom.trade.caravans.filter(func(c):return active(c)).size()
	if key=="prices":return int(w.kingdom.trade.inspected)
	return float(w.kingdom.trade.get(key,0))
static func normalize(w: Dictionary) -> void:
	if not enabled(w):return
	var t=w.kingdom.trade
	for key in ["version","next_caravan","last_tick","bought","sold","delivered"]:t[key]=int(t[key])
	for c in t.caravans:
		for key in ["id","merchant","capacity","supplies","departed","progress","leg_ticks","payout"]:c[key]=int(c[key])
		for key in c.cargo:c.cargo[key]=int(c.cargo[key])
		for i in range(c.guards.size()):c.guards[i]=int(c.guards[i])
static func validate(w: Dictionary) -> bool:
	if not enabled(w):return true
	var C=preload("res://scripts/cosmetics.gd");var t=w.kingdom.trade
	if not M.enabled(w) or w.kingdom.claimed.size()<20 or not C.shape(t,["version","next_caravan","last_tick","caravans","inspected","bought","sold","delivered"]):return false
	if not C.number(t.version,1,1,true) or not C.number(t.next_caravan,1,100000,true) or not C.number(t.last_tick,0,w.tick,true) or not t.inspected is bool or not t.caravans is Array or t.caravans.size()>12:return false
	for key in ["bought","sold","delivered"]:
		if not C.number(t[key],0,1000000,true):return false
	var ids=[];var workers=[];var guards=[];var count=0
	for c in t.caravans:
		if not C.shape(c,["id","origin","route","merchant","guards","cargo","capacity","supplies","departed","progress","leg_ticks","state","encountered","outcome","sold","payout"]):return false
		if not C.number(c.id,1,t.next_caravan-1,true) or ids.has(int(c.id)) or c.origin!="home" or not routes().has(c.route):return false
		if not C.number(c.merchant,1,w.kingdom.next_worker-1,true) or not C.number(c.departed,0,w.tick,true) or not C.number(c.leg_ticks,1,24,true) or not C.number(c.progress,0,c.leg_ticks,true) or not C.number(c.capacity,8,8,true) or not C.number(c.supplies,0,4800,true):return false
		if not c.state in ["outbound","blocked","returning","ready","collected"] or not c.outcome in ["","escorted","detour","retreat"] or not c.encountered is bool or not c.sold is bool or not c.cargo is Dictionary or not c.guards is Array or c.guards.size()>2:return false
		var cargo={}
		for good in c.cargo:
			if not C.number(c.cargo[good],1,8,true):return false
			cargo[good]=int(c.cargo[good])
		var q=quote(w,c.route,cargo)
		if q.is_empty() or not C.number(c.payout,q.payout,q.payout,true):return false
		if c.sold and (not c.encountered or c.outcome=="retreat" or c.state in ["outbound","blocked"]):return false
		var base_ticks=int(routes()[c.route].ticks);var leg=int(c.leg_ticks);var position=int(c.progress)
		if c.outcome=="retreat":
			if c.sold or not c.encountered or not c.state in ["returning","ready","collected"] or leg!=base_ticks/2:return false
		elif leg!=base_ticks+(6 if c.outcome=="detour" else 0):return false
		if c.state=="outbound" and (position>=leg or c.sold):return false
		if c.state=="blocked" and (not c.encountered or c.sold or not c.outcome.is_empty() or position!=base_ticks/2):return false
		if c.state=="returning" and position>=leg:return false
		if c.state in ["returning","ready","collected"] and not c.sold and c.outcome!="retreat":return false
		if c.state in ["ready","collected"] and position!=leg:return false
		var expected_supplies=(2*leg-position)*100 if c.state in ["outbound","blocked"] else (2*base_ticks-leg-position)*100 if c.outcome=="retreat" else (leg-position)*100
		if c.state!="collected" and c.supplies!=expected_supplies:return false
		if c.state=="collected" and c.supplies!=0:return false
		if not w.kingdom.workers.any(func(x):return int(x.id)==int(c.merchant)):return false
		if active(c):
			count+=1
			if workers.has(int(c.merchant)) or M.worker_reserved(w,int(c.merchant)) or not w.kingdom.workers.any(func(x):return int(x.id)==int(c.merchant) and w.kingdom.buildings.any(func(b):return int(b.id)==int(x.building) and b.kind=="marketplace" and K().ready(b))):return false
			workers.append(int(c.merchant))
		var local=[]
		for id in c.guards:
			if not C.number(id,1,100000,true) or local.has(int(id)):return false
			local.append(int(id))
			if active(c):
				if guards.has(int(id)) or M.unit(w,int(id)).get("status")!="ready":return false
				guards.append(int(id))
		ids.append(int(c.id))
	return count<=2 and t.delivered<t.next_caravan
