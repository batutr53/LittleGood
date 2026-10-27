extends Control
var feedback
var skin
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE;size=feedback.a.get_viewport_rect().size;skin=preload("res://scripts/premium_theme.gd").box(Color("192333"),true)
func _draw():
	if feedback==null:return
	var s=feedback.a.game.ui.premium.scale_ui()
	if feedback.hurt_flash>0:
		var color=Color(1,.15,.12,feedback.hurt_flash*.35)
		draw_rect(Rect2(Vector2.ZERO,size),color,false,12*s)
	if feedback.banner_time>0:
		var at=Vector2(size.x*.5-190*s,116*s)
		draw_style_box(skin,Rect2(at,Vector2(380,40)*s));draw_string(feedback.a.game.ui.ui_font(),at+Vector2(8,27)*s,feedback.banner,HORIZONTAL_ALIGNMENT_CENTER,364*s,int(18*s),Color("ffe1a0"))
