extends Control
var world: Dictionary={}
var item_id=0
var reduce_motion=false
var clock=0.0
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta):
	clock+=delta
	if is_visible_in_tree():queue_redraw()
func _draw():
	var data=load("res://scripts/armory.gd").glow(world,item_id)
	if data.strength<=0:return
	var point=size*.5;var radius=minf(size.x,size.y)*.43;var alpha=data.strength*(.7 if reduce_motion else .65+.2*sin(clock*2.5));var color=Color(data.color,alpha)
	draw_arc(point,radius,0,TAU,32,Color(color,.15),6,true);draw_arc(point,radius,0,TAU,32,color,1.5,true)
	if not reduce_motion:
		for i in range(3):draw_circle(point+Vector2.from_angle(clock*.8+i*TAU/3)*radius,1.8,color)
