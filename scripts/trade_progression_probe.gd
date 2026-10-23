extends RefCounted
const T=preload("res://scripts/trade.gd")
const K=preload("res://scripts/kingdom.gd")
const M=preload("res://scripts/military.gd")
var base=preload("res://scripts/military_progression_probe.gd").new()
var world: Dictionary
var merchant=0
var error=""
func marketplace(seed: int=2026) -> bool:
	if not base.complete(seed):error=base.error;return false
	world=base.world
	if not T.enable(world):error="enable";return false
	if base.build("marketplace")<0:error="market construction level="+str(K.level(world))+" stock="+str(world.kingdom.stock);return false
	if K.home(world).population>=K.capacity(world) and base.build("house")<0:error="merchant housing";return false
	if not K.recruit(world):error="recruit pop="+str(K.home(world).population)+" capacity="+str(K.capacity(world));return false
	merchant=int(world.kingdom.workers[-1].id)
	if not K.assign(world,merchant,int(T.market(world)[0].id)) or not T.inspect_prices(world):error="merchant/prices";return false
	return true
func complete(seed: int=2026) -> bool:
	if not marketplace(seed):return false
	var id=T.dispatch(world,"river",merchant,M.available(world).slice(0,2).map(func(u):return int(u.id)),{"wood":4})
	if id<0:error="dispatch";return false
	for i in range(30):base.driver.step()
	if not T.collect(world,id) or not K.claim(world,"main_21"):error="delivery/quest21 "+str(T.caravan(world,id));return false
	return true
