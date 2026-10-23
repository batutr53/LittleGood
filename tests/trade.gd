extends SceneTree
const T=preload("res://scripts/trade.gd")
const K=preload("res://scripts/kingdom.gd")
const M=preload("res://scripts/military.gd")
func _initialize() -> void:
	var p=preload("res://scripts/trade_progression_probe.gd").new();var checks={"legal_market21":p.marketplace()}
	if not checks.legal_market21:print(p.error);quit(1);return
	var w=p.world;checks.valid=Persistence.validate(w)
	checks.no_negative=not T.transaction(w,"wood",-1,true);checks.no_zero=not T.transaction(w,"wood",0,false);checks.no_fraction=not T.transaction(w,"wood",1.5,true);checks.no_bool=not T.transaction(w,"wood",true,true)
	checks.protect_heart=not T.transaction(w,"heart",1,false) and T.quote(w,"river",{"heart":1}).is_empty()
	checks.no_oversize=T.quote(w,"river",{"wood":9}).is_empty()
	checks.no_fractional_cargo=T.quote(w,"river",{"wood":1.5}).is_empty()
	var gold=int(w.kingdom.stock.gold);var wood=int(w.kingdom.stock.wood);var ore=int(w.kingdom.stock.ore)
	checks.real_buy=T.transaction(w,"ore",1,true) and w.kingdom.stock.ore==ore+1000 and w.kingdom.stock.gold==gold-2500
	checks.real_sell=T.transaction(w,"ore",1,false) and w.kingdom.stock.ore==ore and w.kingdom.stock.gold==gold-1900
	checks.no_arbitrage=true
	for good in T.PRICES:
		for route in T.routes().values():checks.no_arbitrage=checks.no_arbitrage and route.sell[good]<T.PRICES[good][0]
	var ro=w.duplicate(true);ro._read_only=true;var before=ro.kingdom.duplicate(true)
	checks.readonly=not T.enable(ro) and not T.transaction(ro,"wood",1,true) and T.dispatch(ro,"river",p.merchant,[],{"wood":1})<0 and not T.inspect_prices(ro) and not T.resolve(ro,1,true) and not T.collect(ro,1) and not T.salvage(ro,1)
	T.tick(ro);checks.readonly=checks.readonly and ro.kingdom==before
	var escorts=M.available(w).slice(0,2).map(func(u):return int(u.id));var items=w.kingdom.industry.items.duplicate(true);var citizen_count=w.kingdom.workers.size()
	wood=int(w.kingdom.stock.wood);gold=int(w.kingdom.stock.gold);var food=K.home(w).food
	var id=T.dispatch(w,"river",p.merchant,escorts,{"wood":4});var c=T.caravan(w,id)
	checks.atomic_dispatch=id>0 and w.kingdom.stock.wood==wood-4000 and w.kingdom.stock.gold==gold-1000 and is_equal_approx(K.home(w).food,food-2.4)
	checks.merchant_reserved=not K.assign(w,p.merchant,0) and T.worker_reserved(w,p.merchant)
	checks.guard_reserved=not M.available(w).any(func(u):return escorts.has(int(u.id))) and not M.retire(w,escorts[0]) and not M.recover(w,escorts[0]) and not M.deploy(w,"raid",escorts)
	checks.no_double_dispatch=T.dispatch(w,"river",p.merchant,[],{"wood":1})<0
	checks.no_early_collection=not T.collect(w,id)
	checks.no_equipment_loss=w.kingdom.industry.items==items and w.kingdom.workers.size()==citizen_count
	checks.pending_save=Persistence.save_world(w,"user://trade-pending.json") and Persistence.load_world("user://trade-pending.json").kingdom==w.kingdom
	var market_id=int(T.market(w)[0].id);var spare=int(w.kingdom.workers[2].id)
	var market_before=T.market(w)[0].duplicate(true)
	checks.pending_market_upgrade_safe=not K.upgrade(w,market_id) and T.market(w)[0]==market_before
	checks.reserved_market_capacity=K.assign(w,spare,market_id) and not K.assign(w,int(w.kingdom.workers[0].id),market_id) and K.occupied(w,market_id)==2 and Persistence.validate(w)
	K.assign(w,spare,0)
	before=c.duplicate(true);T.tick(w);checks.idempotent_tick=c==before
	for i in range(7):p.base.driver.step()
	checks.escort_pass=c.encountered and c.outcome=="escorted" and c.state=="outbound"
	checks.progress_save=Persistence.save_world(w,"user://trade-midway.json") and Persistence.load_world("user://trade-midway.json").kingdom==w.kingdom
	gold=int(w.kingdom.stock.gold);w.user_paused=false;Persistence.offline(w,w.saved_at+3600)
	p.base.driver.rng.state=int(w.rng_state)
	checks.offline_arrival=c.state=="ready" and c.sold and w.kingdom.stock.gold==gold
	checks.returned_merchant_clears_stock=T.merchants(w).is_empty() and T.transaction(w,"wood",1,false) and c.state=="ready" and T.worker_reserved(w,p.merchant)
	gold=int(w.kingdom.stock.gold);checks.once_delivery=T.collect(w,id) and w.kingdom.stock.gold==gold+2400 and not T.collect(w,id) and w.kingdom.stock.gold==gold+2400
	checks.release=T.merchants(w).any(func(x):return x.id==p.merchant) and M.available(w).any(func(u):return int(u.id)==escorts[0])
	checks.quest21=K.claim(w,"main_21") and K.level(w)==21 and w.kingdom.claimed.size()==21 and K.current(w).is_empty() and not K.claim(w,"main_21")
	# A dangerous trip pauses for a decision; offline time cannot destroy cargo or people.
	id=T.dispatch(w,"hills",p.merchant,[],{"wood":2});c=T.caravan(w,id)
	checks.unescorted_departure=id>0
	for i in range(12):p.base.driver.step()
	checks.risk_blocks=c.state=="blocked" and not c.sold
	var stock=w.kingdom.stock.duplicate(true);var units=w.kingdom.military.units.duplicate(true);w.saved_at=Time.get_unix_time_from_system()
	Persistence.offline(w,w.saved_at+86400);p.base.driver.rng.state=int(w.rng_state);checks.offline_risk_safe=c.state=="blocked" and w.kingdom.military.units==units and w.kingdom.stock.wood>=stock.wood
	checks.detour=T.resolve(w,id,true) and c.state=="outbound" and c.leg_ticks==24
	checks.no_repeat_detour=not T.resolve(w,id,true)
	for i in range(50):p.base.driver.step()
	checks.detour_return=c.state=="ready" and T.collect(w,id)
	# Retreat returns the actual cargo, never a sale payout.
	id=T.dispatch(w,"river",p.merchant,[],{"stone":1});c=T.caravan(w,id)
	for i in range(7):p.base.driver.step()
	checks.retreat=T.resolve(w,id,false)
	for i in range(10):p.base.driver.step()
	gold=int(w.kingdom.stock.gold);var stone=int(w.kingdom.stock.stone)
	checks.return_cargo=T.collect(w,id) and w.kingdom.stock.gold==gold and w.kingdom.stock.stone==stone+1000 and not c.sold
	checks.valid_end=Persistence.validate(w)
	var bad=w.duplicate(true);bad.kingdom.trade.caravans[0].payout+=1;checks.bad_payout=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.trade.caravans[0].cargo.heart=1;checks.bad_cargo=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.trade.caravans[1].id=bad.kingdom.trade.caravans[0].id;checks.duplicate_caravan=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.kingdom.trade.caravans[0].progress=999;checks.bad_progress=not Persistence.validate(bad)
	var d=Persistence.load_world("res://tests/fixtures/planet-v085d.json");checks.authentic_d=not d.is_empty() and Persistence.validate(d)
	before=d.kingdom.duplicate(true);checks.d_optin=T.enable(d)
	checks.d_conservation=d.kingdom.military==before.military and d.kingdom.industry==before.industry and d.kingdom.adventure==before.adventure and d.kingdom.stock==before.stock
	checks.d_pending=not d.kingdom.industry.queue.is_empty();checks.d_once=not T.enable(d) and Persistence.validate(d)
	var salvage=w.duplicate(true);var equipment=salvage.kingdom.adventure.hero.equipment
	checks.protect_equipped=not T.salvage(salvage,int(equipment.weapon))
	checks.protect_army=not T.salvage(salvage,int(salvage.kingdom.military.units[0].gear))
	# Synthetic capacity/overflow boundary only; legal campaign above uses actual production.
	var inventory=salvage.kingdom.industry;var pending=inventory.queue.duplicate(true)
	while inventory.items.size()+inventory.queue.size()<32:
		inventory.items.append({"id":int(inventory.next_item),"recipe":"iron_sword"});inventory.next_item+=1
	for key in T.PRICES:salvage.kingdom.stock[key]=roundi(K.storage(salvage)*1000)
	var scrap=int(inventory.items[-1].id);var n=inventory.items.size();stock=salvage.kingdom.stock.duplicate(true)
	checks.full_capacity_valid=Persistence.validate(salvage)
	checks.salvage_frees_full=T.salvage(salvage,scrap) and inventory.items.size()==n-1 and salvage.kingdom.stock==stock and inventory.queue==pending
	checks.salvage_once=not T.salvage(salvage,scrap) and Persistence.validate(salvage)
	# Recovery is also available before Chapter V, so a full C/D inventory cannot gate military crafting.
	var legacy=Persistence.load_world("res://tests/fixtures/planet-v085d.json");var old_queue=legacy.kingdom.industry.queue.duplicate(true)
	var unused=legacy.kingdom.industry.items.filter(func(x):return not legacy.kingdom.adventure.hero.equipment.values().has(int(x.id)) and not M.item_reserved(legacy,int(x.id)) and not legacy.kingdom.industry.equipped.any(func(s):return int(s.item)==int(x.id)))
	checks.legacy_salvage=not unused.is_empty() and T.salvage(legacy,int(unused[0].id)) and not T.enabled(legacy) and legacy.kingdom.industry.queue==old_queue and Persistence.validate(legacy)
	# Unique artifact protection uses the real existing heartward recipe.
	checks.artifact_forged=p.base.base.craft("heartward")
	var artifacts=w.kingdom.industry.items.filter(func(x):return x.recipe=="heartward")
	checks.protect_artifact=not artifacts.is_empty() and not T.salvage(w,int(artifacts[0].id))
	print("E1_TRADE_CHECKS ",checks);quit(1 if checks.values().has(false) else 0)
