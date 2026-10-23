extends Node2D
const MAP=preload("res://scripts/wildwood_map.gd")
func _draw() -> void:
	draw_rect(Rect2(0,0,960,1440),Color("355c51"))
	var rng=RandomNumberGenerator.new();rng.seed=19
	for i in range(430):
		var p=Vector2(rng.randf_range(18,942),rng.randf_range(18,1422));draw_circle(p,rng.randf_range(3,19),Color(.5,.66,.45,rng.randf_range(.05,.16)))
	var path=PackedVector2Array([Vector2(240,1420),Vector2(240,1060),Vector2(480,920),Vector2(480,650),Vector2(720,510),Vector2(720,150)])
	draw_polyline(path,Color("6f9475"),114,true);draw_polyline(path,Color("9caf88"),74,true)
	draw_rect(Rect2(20,500,280,300),Color("387d83"));draw_rect(Rect2(26,510,266,280),Color("5caaa6"))
	for i in range(8):draw_line(Vector2(45,530+i*34),Vector2(270,530+i*34),Color(.7,.93,.83,.27),2,true)
	for p in [MAP.START,MAP.LANDMARK,MAP.BOSS]:
		draw_circle(p,68,Color("648b75"));draw_arc(p,66,0,TAU,40,Color("c7c39b"),3,true)
	for r in [Rect2(590,980,140,120),Rect2(90,880,80,100),Rect2(360,300,140,220)]:
		draw_style_box(rock_style(),r)
func rock_style() -> StyleBoxFlat:
	var s=StyleBoxFlat.new();s.bg_color=Color("73988a");s.border_color=Color("b1c2a0");s.set_border_width_all(3);s.set_corner_radius_all(25);return s
