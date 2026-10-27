extends Node2D
const E=preload("res://scripts/estate.gd")
const K=preload("res://scripts/kingdom.gd")
var view
var land_mode=false
var rewards: Array=[]
var clock=0.0
var icons={}
var work_skin
func _ready():
	work_skin=preload("res://scripts/premium_theme.gd").box(Color("17211e"),true)
	for key in ["wood","stone","food","gold","hammer"]:icons[key]=preload("res://scripts/premium_theme.gd").icon(key)
	icons.ore=icons.stone;icons.iron=icons.hammer
func _process(delta):
	clock+=delta
	for reward in rewards:reward.age+=delta
	rewards=rewards.filter(func(r):return r.age<1.8)
	queue_redraw()
func bubble(b: Dictionary) -> Vector2:
	var point=view.screen_point(view.world.cells[int(b.cell)])
	var height=(100+int(b.level)*5)*view.display_zoom
	return point-Vector2(0,height+17+sin(clock*2+int(b.id)) * 2)
func plot_point(p: Vector2i) -> Vector2:
	return view.to_screen(view.project({"x":p.x*8+3.5,"y":p.y*8+3.5,"height":.2}))
func worker_bubble(index):
	return view.to_screen(view.kingdom_layer.workers[index].position)-Vector2(0,72*view.display_zoom)
func collect_worker(id,at):
	var game=view.get_parent();var C=load("res://scripts/colony.gd");var resource=view.world.colony.jobs[str(id)].resource;var amount=C.collect(view.world,id)
	view.select_worker(id)
	if amount<=0:game.ui.toast("Depo dolu · önce yer aç" if game.ui.language=="tr" else "Storage full · make room first");return
	rewards.append({"position":at,"age":0.0,"text":"+"+str(amount/1000.0)+" "+C.NAMES[resource][1 if game.ui.language=="tr" else 0]});game.schedule_save();game.ui.refresh();view.invalidate();game.audio.chime(1)
	if game.haptics and OS.has_feature("mobile"):Input.vibrate_handheld(22,.25)
func collect(id: int) -> bool:
	var game=view.get_parent();var result=E.collect(view.world,id)
	if result.is_empty():game.ui.toast("Depo dolu · önce yer aç" if game.ui.language=="tr" else "Storage full · make room first");return false
	var words=[]
	for key in result:
		if key=="crafted":words.append(("Üretim toplandı ×" if game.ui.language=="tr" else "Craft collected ×")+str(int(result[key])));continue
		var names={"wood":"Odun","stone":"Taş","gold":"Altın","food":"Yiyecek","ore":"Cevher","iron":"Demir"}
		words.append(("Tamamlandı!" if game.ui.language=="tr" else "Completed!") if key=="built" else "+%.2f %s"%[int(result[key])/1000.0,names.get(key,key) if game.ui.language=="tr" else key])
	var b=view.world.kingdom.buildings.filter(func(item):return int(item.id)==id)[0]
	view.select_cell(int(b.cell))
	rewards.append({"position":bubble(b),"age":0.0,"text":" · ".join(words)})
	game.schedule_save();game.ui.refresh();view.invalidate();game.audio.chime(1)
	if game.haptics and OS.has_feature("mobile"):Input.vibrate_handheld(22,.25)
	return true
func pick(pos: Vector2) -> bool:
	if not E.enabled(view.world):return false
	var game=view.get_parent();var buildings=view.world.get("kingdom",{}).get("buildings",[]).duplicate()
	buildings.sort_custom(func(a,b):return view.project(view.world.cells[int(a.cell)]).y>view.project(view.world.cells[int(b.cell)]).y)
	# Ready bubbles always win over roofs, creatures and terrain.
	for b in buildings:
		if E.status(view.world,b)!="" and bubble(b).distance_to(pos)<=26:collect(int(b.id));return true
	var C=load("res://scripts/colony.gd")
	if C.enabled(view.world):
		for i in range(mini(view.kingdom_layer.workers.size(),view.world.kingdom.workers.size())):
			var id=int(view.world.kingdom.workers[i].id)
			if C.reserved(view.world,id) and int(view.world.colony.jobs[str(id)].buffer)>0 and worker_bubble(i).distance_to(pos)<=25:collect_worker(id,worker_bubble(i));return true
	for i in range(mini(view.kingdom_layer.workers.size(),view.world.get("kingdom",{}).get("workers",[]).size())):
		var worker=view.kingdom_layer.workers[i]
		if load("res://scripts/selection_outline.gd").hit(worker,pos):game.ui.premium.route("worker",int(view.world.kingdom.workers[i].id));return true
	if land_mode:
		for p in E.candidates(view.world):
			if plot_point(p).distance_to(pos)<26:game.ui.premium.estate_selected=p;game.ui.premium.route("estate");return true
	for b in buildings:
		var point=view.screen_point(view.world.cells[int(b.cell)]);var z=view.display_zoom
		if view.kingdom_layer.structures.has(int(b.id)) and load("res://scripts/selection_outline.gd").hit(view.kingdom_layer.structures[int(b.id)].sprite,pos):game.realm_ui.inspect_building(int(b.id));return true
	return false
func _draw():
	if view==null or not E.enabled(view.world):return
	var game=view.get_parent()
	var C=load("res://scripts/colony.gd")
	if C.enabled(view.world):
		for i in range(mini(view.kingdom_layer.workers.size(),view.world.kingdom.workers.size())):
			var worker=view.world.kingdom.workers[i];var id=int(worker.id)
			if not C.reserved(view.world,id):continue
			var job=view.world.colony.jobs[str(id)];var at=view.to_screen(view.kingdom_layer.workers[i].position)-Vector2(0,48*view.display_zoom)
			if not get_viewport_rect().grow(70).has_point(at):continue
			var text=worker.name+" · "+C.NAMES[job.resource][1 if game.ui.language=="tr" else 0];draw_string_outline(game.ui.ui_font(),at-Vector2(65,0),text,HORIZONTAL_ALIGNMENT_CENTER,130,13,4,Color("101a22"));draw_string(game.ui.ui_font(),at-Vector2(65,0),text,HORIZONTAL_ALIGNMENT_CENTER,130,13,Color("ffe4a7"))
			if int(job.buffer)>0:
				var point=worker_bubble(i);draw_circle(point,24,Color("f5e7b0"));draw_arc(point,24,0,TAU,32,Color("a47737"),2,true)
				draw_string(game.ui.ui_font(),point+Vector2(-18,6),"+"+str(job.buffer/1000.0),HORIZONTAL_ALIGNMENT_CENTER,36,15,Color("365c3b"))
	if game.realm_ui!=null and game.realm_ui.active and game.realm_ui.cell>=0:
		var placement=game.realm_ui;var point=view.screen_point(view.world.cells[placement.cell]);var z=view.display_zoom;var valid=placement.valid(placement.cell);var tint=Color(.45,1,.6,.7) if valid else Color(1,.3,.25,.7)
		var pitch=1.65 if view.world.cells.size()>400 else 1.0
		var ring=PackedVector2Array([point+Vector2(-30,0)*z*pitch,point+Vector2(0,-15)*z*pitch,point+Vector2(30,0)*z*pitch,point+Vector2(0,15)*z*pitch,point+Vector2(-30,0)*z*pitch])
		draw_colored_polygon(ring,tint*Color(1,1,1,.3));draw_polyline(ring,tint,3,true)
		if placement.mode=="build":draw_texture_rect(view.kingdom_layer.texture(placement.kind),Rect2(point+Vector2(-70,-123)*z,Vector2(140,140)*z),false,tint)
	if land_mode:
		for p in E.candidates(view.world):
			var polygon=PackedVector2Array()
			for d in [Vector2(-.5,-.5),Vector2(7.5,-.5),Vector2(7.5,7.5),Vector2(-.5,7.5),Vector2(-.5,-.5)]:
				polygon.append(view.to_screen(view.project({"x":p.x*8+d.x,"y":p.y*8+d.y,"height":.2})))
			draw_colored_polygon(polygon,Color(.66,.85,.65,.075));draw_polyline(polygon,Color(.94,.84,.53,.65),1.5,true)
			var at=plot_point(p);draw_circle(at,24,Color("273c32"));draw_arc(at,24,0,TAU,32,Color("d6b66a"),2,true)
			draw_line(at-Vector2(8,0),at+Vector2(8,0),Color("ffe4a0"),3,true);draw_line(at-Vector2(0,8),at+Vector2(0,8),Color("ffe4a0"),3,true)
	for b in view.world.get("kingdom",{}).get("buildings",[]):
		if not K.ready(b):
			var at=bubble(b);var free=K.assigned(view.world,0).size();var queue=view.world.kingdom.buildings.filter(func(site):return not K.ready(site));var queued=queue[0].id!=b.id
			if get_viewport_rect().grow(60).has_point(at):
				var color=Color("f0bd61") if free>0 else Color("ef7770")
				draw_style_box(work_skin,Rect2(at-Vector2(62,22),Vector2(124,38)))
				var caption=("Sırada" if game.ui.language=="tr" else "Queued") if queued else (str(free)+(" inşaatçı" if game.ui.language=="tr" else " builders")) if free>0 else ("İşçi gerekli" if game.ui.language=="tr" else "Needs builder")
				draw_string(ThemeDB.fallback_font,at+Vector2(-55,-5),caption,HORIZONTAL_ALIGNMENT_LEFT,114,13,color)
				draw_rect(Rect2(at+Vector2(-55,4),Vector2(110,5)),Color("37413a"));draw_rect(Rect2(at+Vector2(-55,4),Vector2(110*float(b.progress)/maxf(1,b.required),5)),color)
			continue
		var status=E.status(view.world,b)
		if status.is_empty():continue
		var point=bubble(b)
		if not get_viewport_rect().grow(30).has_point(point):continue
		draw_circle(point+Vector2(0,3),25,Color(0,0,0,.28));draw_circle(point,24,Color("f5e7b0"));draw_arc(point,24,0,TAU,32,Color("a47737"),2,true)
		draw_colored_polygon(PackedVector2Array([point+Vector2(-6,22),point+Vector2(0,30),point+Vector2(6,22)]),Color("d9be7c"))
		var key="hammer" if status in ["built","crafted"] else K.buildings()[b.kind].output
		if icons.get(key)!=null:draw_texture_rect(icons[key],Rect2(point-Vector2(16,16),Vector2(32,32)),false,Color("435b3e"))
		else:draw_string(ThemeDB.fallback_font,point+Vector2(-8,7),"✓",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("365c3b"))
	for reward in rewards:
		var alpha=clampf((1.8-reward.age)*2,0,1);var at=reward.position+Vector2(-35,-reward.age*38)
		draw_string_outline(ThemeDB.fallback_font,at,reward.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,4,Color(0,0,0,alpha));draw_string(ThemeDB.fallback_font,at,reward.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(1,.93,.63,alpha))
