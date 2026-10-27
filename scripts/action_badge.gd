extends Control
var remaining=0.0
var duration=1.0
var locked=false
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func sample(milliseconds: float,total: float,is_locked=false):
	if remaining==milliseconds and duration==total and locked==is_locked:return
	remaining=milliseconds;duration=maxf(1,total);locked=is_locked;queue_redraw()
func _draw():
	var radius=minf(size.x,size.y)*.46;var center=size*.5
	if locked:
		draw_line(center+Vector2(-9,-9),center+Vector2(9,9),Color("a9afb5"),3,true);draw_line(center+Vector2(-9,9),center+Vector2(9,-9),Color("a9afb5"),3,true)
	elif remaining>0:
		draw_arc(center,radius,-PI*.5,-PI*.5+TAU*clampf(remaining/duration,0,1),48,Color("ffe0a2"),3,true)
