extends Control
var hunt
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw():
	draw_style_box(preload("res://scripts/premium_theme.gd").skin(),Rect2(Vector2.ZERO,size))
	var inner=Rect2(10,10,size.x-20,size.y-20)
	draw_rect(inner,Color("14212b"));draw_line(inner.position+inner.size*Vector2(.25,.1),inner.position+inner.size*Vector2(.65,.9),Color("597580"),5)
	for e in hunt.snapshot.enemies:
		if e.hp>0:draw_circle(inner.position+Vector2(e.x/1300.0,e.y/960.0)*inner.size,3,Color("d26a54"))
	for p in hunt.snapshot.players:draw_circle(inner.position+Vector2(p.x/1300.0,p.y/960.0)*inner.size,4,Color("8adcc1") if p.id==hunt.character.id else Color("72b8b2"))
