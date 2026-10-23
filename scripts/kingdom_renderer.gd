extends Node2D
const K=preload("res://scripts/kingdom.gd")
const ATLAS=preload("res://assets/kingdom/buildings-atlas.svg")
const INDUSTRY_ATLAS=preload("res://assets/kingdom/industry-atlas.svg")
var view
var structures: Dictionary={}
var workers: Array=[]
var clock=0.0
var seed_key=""
var rates: Dictionary={}
func texture(kind: String) -> Texture2D:
	if kind in ["barracks","watchtower","wall","marketplace"]:return load("res://assets/kingdom/"+kind+".svg")
	var t=AtlasTexture.new();var index=["lumber","farm","house","storage","townhall","scaffold"].find(kind)
	if index>=0:t.atlas=ATLAS;t.region=Rect2((index%3)*192,(index/3)*192,192,192)
	else:t.atlas=INDUSTRY_ATLAS;t.region=Rect2(["quarry","mine","furnace","forge"].find(kind)*192,0,192,192)
	return t
func sync(w: Dictionary) -> void:
	var key=str(w.seed)+str(w.has("kingdom"))
	if seed_key!=key:
		for data in structures.values():data.sprite.queue_free();data.scaffold.queue_free()
		structures.clear();seed_key=key
	if not w.has("kingdom"):
		for worker in workers:worker.queue_free()
		workers.clear();return
	var ids: Dictionary={};rates.clear()
	for b in w.kingdom.buildings:
		var id=int(b.id);ids[id]=true
		if not structures.has(id):
			var sprite=Sprite2D.new();sprite.texture=texture(b.kind);sprite.centered=false;sprite.offset=Vector2(-96,-145);view.inhabitants.props.add_child(sprite)
			var scaffold=Sprite2D.new();scaffold.texture=texture("scaffold");scaffold.centered=false;scaffold.offset=Vector2(-96,-145);view.inhabitants.props.add_child(scaffold)
			structures[id]={"sprite":sprite,"scaffold":scaffold,"kind":b.kind}
		var data=structures[id];var scale_value=.34+int(b.level)*.025
		if data.kind!=b.kind:data.sprite.texture=texture(b.kind);data.kind=b.kind
		for sprite in [data.sprite,data.scaffold]:sprite.position=view.project(w.cells[int(b.cell)]);sprite.scale=Vector2.ONE*scale_value
		data.sprite.modulate=Color(1,1,1,.3+.7*float(b.progress)/float(b.required));data.scaffold.visible=not K.ready(b)
		rates[id]=K.activity_rate(w,b)
	for id in structures.keys():
		if not ids.has(id):structures[id].sprite.queue_free();structures[id].scaffold.queue_free();structures.erase(id)
	while workers.size()<w.kingdom.workers.size():
		var sprite=GameArt.sprite(14,17);view.inhabitants.add_child(sprite);workers.append(sprite)
	while workers.size()>w.kingdom.workers.size():workers.pop_back().queue_free()
func animate(delta: float) -> void:
	clock+=delta
	var w=view.world
	if not w.has("kingdom"):return
	for b in w.kingdom.buildings:
		if b.kind in ["furnace","forge"] and structures.has(int(b.id)):
			var active=rates.get(int(b.id),0)>0
			structures[int(b.id)].sprite.self_modulate=Color(1.12+.06*sin(clock*5),1.03,.90) if active else Color.WHITE
	for i in range(mini(workers.size(),w.kingdom.workers.size())):
		var soldier=preload("res://scripts/military.gd").worker_reserved(w,int(w.kingdom.workers[i].id)) or preload("res://scripts/trade.gd").worker_reserved(w,int(w.kingdom.workers[i].id))
		workers[i].visible=not soldier
		if soldier:continue
		var worker=w.kingdom.workers[i];var target=int(K.home(w).cell);var working=false
		for b in w.kingdom.buildings:
			if int(worker.building)==int(b.id) or (int(worker.building)==0 and not K.ready(b)):
				target=int(b.cell);working=not K.ready(b) or rates.get(int(b.id),0)>0;break
		var point=view.project(w.cells[target]);var phase=i*2.17
		workers[i].position=point+Vector2(sin(clock*.8+phase)*12,10+cos(clock*.8+phase)*5)
		workers[i].rotation=sin(clock*(7 if working else 1)+phase)*(.13 if working else .02)
		workers[i].self_modulate=Color("e0d3a4") if int(worker.building)==0 else Color("abd6b8")
		workers[i].flip_h=sin(clock*.8+phase)<0
