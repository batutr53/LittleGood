extends Node2D
const S=preload("res://scripts/sanctuary.gd")
const MAP=preload("res://scripts/sanctuary_map.gd")
var terrain=preload("res://assets/adventure/sanctuary-ground.svg")
var door_shapes={}
var parent
var pulses={}
var last_phases={}
var last_doors=[]
var last_visual=[]
func _ready() -> void:
	parent=get_parent()
	last_doors=MAP.doors(parent.game.world.kingdom.adventure.run)
	for key in MAP.DOORS:
		var body=StaticBody2D.new();body.position=MAP.DOORS[key].get_center();var shape=CollisionShape2D.new();var rect=RectangleShape2D.new();rect.size=MAP.DOORS[key].size;shape.shape=rect;body.add_child(shape);add_child(body);door_shapes[key]=shape;pulses[key]=1.0
func _physics_process(delta: float) -> void:
	var r=parent.game.world.kingdom.adventure.run
	if r.get("region","")!="sanctuary":return
	var closed=MAP.doors(r)
	if closed!=last_doors:parent.game.audio.sanctuary("door");last_doors=closed.duplicate()
	for key in MAP.HAZARDS:
		var phase=S.phase(r,key)
		if last_phases.has(key) and last_phases[key]!=phase and phase!="safe":parent.game.audio.sanctuary("trap_"+("active" if phase=="active" else "warning"))
		last_phases[key]=phase
	for key in door_shapes:
		var disabled=not closed.has(key)
		if door_shapes[key].disabled!=disabled:door_shapes[key].set_deferred("disabled",disabled)
		pulses[key]=move_toward(pulses[key],1.0 if closed.has(key) else .0,delta*4)
	# Static inscriptions and geometry retain their canvas commands. Only actual
	# mechanisms, phase changes and a moving door fade need rebuilt commands.
	var visual=[r.mechanisms.plates,r.mechanisms.switches,r.mechanisms.secret,last_phases.duplicate(),pulses.duplicate()]
	if visual!=last_visual:last_visual=visual;queue_redraw()
func _draw() -> void:
	if not parent:return
	var r=parent.game.world.kingdom.adventure.run;var font=parent.game.ui.ui_font()
	for key in MAP.DOORS:
		var rect=MAP.DOORS[key];var alpha=pulses.get(key,1.0)
		draw_rect(rect,Color(.63,.71,.65,alpha));draw_rect(rect.grow(3),Color(.9,.78,.5,alpha),false,3)
	for i in range(2):
		var p=MAP.PLATES[i];var active=r.mechanisms.plates>=i+1
		draw_circle(p,30,Color("b7d9a5") if active else Color("426278"));draw_arc(p,35,0,TAU,32,Color("e1c98c"),3,true)
		draw_string(font,p+Vector2(-18,7),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("fff0b5"))
		draw_string(font,p+Vector2(-25,56),parent.say(["Sun","Moon"][i],["Güneş","Ay"][i]),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("ead99b"))
	for i in range(3):
		var p=MAP.SWITCHES[i];var active=r.mechanisms.switches>i
		draw_rect(Rect2(p-Vector2(23,35),Vector2(46,60)),Color("679c91") if active else Color("36536d"));draw_arc(p-Vector2(0,8),18,0,TAU,24,Color("e4c98b"),3,true)
		draw_string(font,p+Vector2(-30,45),parent.say(["Sun","Moon","Star"][i],["Güneş","Ay","Yıldız"][i]),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f8e8b1"))
	for key in MAP.HAZARDS:
		var rect=MAP.HAZARDS[key].rect;var state=S.phase(r,key);var color=Color(.9,.25,.19,.62) if state=="active" else Color(1,.65,.24,.33) if state=="warning" else Color(.7,.69,.57,.13)
		draw_rect(rect,color);draw_rect(rect,Color("e3bb80"),false,2)
		for x in range(int(rect.position.x)+10,int(rect.end.x)-5,25):
			draw_line(Vector2(x,rect.position.y+15),Vector2(x+10,rect.position.y+40),Color("f0d0a0"),3,true)
	draw_string(font,MAP.INSCRIPTION+Vector2(-100,60),parent.say("Sun → Moon · Sun → Moon → Star","Güneş → Ay · Güneş → Ay → Yıldız"),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ead99b"))
	draw_string(font,MAP.SECRET+Vector2(-90,40),parent.say("Light through cracked stone · Inspect","Çatlak taştan ışık · İncele"),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("c6d8ad"))
	for p in [MAP.INSCRIPTION,MAP.TREASURE,MAP.LORE,MAP.RELIC]:draw_arc(p,46,0,TAU,32,Color("dbc28a"),2,true)
