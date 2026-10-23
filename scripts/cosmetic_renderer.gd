extends Node2D
const Model=preload("res://scripts/cosmetics.gd")
var view
var sprites: Array=[]
var coats: Dictionary={}
var time=0.0
var theme="enchanted"
var sky=""
var frame=""
var sync_ms=0.0
var animate_ms=0.0
var draw_ms=0.0
var signature=""
var placement_signature=""
func sync(w: Dictionary) -> void:
	var start=Time.get_ticks_usec()
	var d=w.get("wardrobe",Model.fresh())
	var key=str(w.seed)+JSON.stringify([d.theme,d.sky,d.frame,d.placements,d.coats,view.low_quality])
	for p in d.placements:key+=str(w.cells[int(p.cell)].height)
	if key==signature:return
	signature=key
	var placement_key=str(w.seed)+JSON.stringify([d.placements,view.low_quality])
	for p in d.placements:placement_key+=str(w.cells[int(p.cell)].height)
	theme=d.theme;sky=d.sky;frame=d.frame
	coats.clear()
	for c in d.coats:coats[int(c.id)]=c.item
	if placement_key!=placement_signature:
		placement_signature=placement_key
		for sprite in sprites:
			if is_instance_valid(sprite):sprite.queue_free()
		sprites.clear()
		for p in d.placements:
			var sprite=Sprite2D.new()
			sprite.texture=Model.texture(p.item)
			sprite.centered=false;sprite.offset=Vector2(-64,-112)
			sprite.position=view.project(w.cells[int(p.cell)])
			if Model.items()[p.item].category=="settlement":sprite.position+=Vector2(27,10)
			sprite.scale=Vector2(.34,.34) if p.item in ["flowers","stones","banner","lanterns","statue"] else Vector2(.48,.48)
			if int(p.rotation)%2==1:sprite.flip_h=true
			if int(p.rotation)>=2:sprite.scale*=.85
			if p.item=="willow" and not view.low_quality:sprite.material=GameArt.foliage()
			view.inhabitants.props.add_child(sprite);sprites.append(sprite)
	var tint={"enchanted":Color.WHITE,"crystal":Color(.76,.94,1.08),"celestial":Color(.62,.75,1.0),"ancient":Color(1.1,.93,.74)}.get(theme,Color.WHITE)
	view.terrain.land.material.set_shader_parameter("cosmetic_tint",Vector3(tint.r,tint.g,tint.b))
	var water_tint=Color(.73,.96,1.08) if theme=="crystal" else Color(.7,.8,1.05) if theme=="celestial" else Color.WHITE
	view.terrain.water.material.set_shader_parameter("cosmetic_tint",Vector3(water_tint.r,water_tint.g,water_tint.b))
	view.inhabitants.props.self_modulate=tint.lerp(Color.WHITE,.5)
	var material=view.get_parent().get_node("Atmosphere").material
	material.set_shader_parameter("palette",["enchanted","crystal","celestial","ancient"].find(theme))
	sync_ms=(Time.get_ticks_usec()-start)/1000.0
func animate(delta: float) -> void:
	var start=Time.get_ticks_usec();time+=delta;queue_redraw();animate_ms=(Time.get_ticks_usec()-start)/1000.0
func _draw() -> void:
	if view.world.is_empty():return
	var started=Time.get_ticks_usec()
	var glints=PackedVector2Array()
	for p in view.world.get("wardrobe",{}).get("placements",[]):
		var point=view.project(view.world.cells[int(p.cell)])
		if p.item in ["fireflies","glowfern","prisms"]:
			for i in range(2 if view.low_quality else 5):
				var pos=point+Vector2(sin(time*.7+i*2)*15,-12+cos(time*.6+i*3)*10)
				var size=1.0+sin(time+i)*.3
				glints.append(pos-Vector2(size,0));glints.append(pos+Vector2(size,0))
		if p.item=="falls":
			for i in range(2 if view.low_quality else 5):
				var y=fmod(time*12+i*7,36)
				draw_line(point+Vector2(-8+i*4,y-18),point+Vector2(-8+i*4,y-10),Color(.8,.95,1,.5),1.4)
	if not glints.is_empty():draw_multiline(glints,Color(.9,.9,.62,.7),1.4,false)
	for i in range(mini(view.inhabitants.animals.size(),view.world.creatures.size())):
		var cr=view.world.creatures[i]
		if coats.get(int(cr.identity),"")=="starband":
			var pos=view.inhabitants.animals[i].position+Vector2(0,-27)
			draw_line(pos-Vector2(6,0),pos+Vector2(6,0),Color("e7ce91"),2)
			draw_circle(pos+Vector2(0,-4),3,Color("fae4ae"))
	draw_ms=(Time.get_ticks_usec()-started)/1000.0
