extends Control
# Quiet retained surface: the surrounding panel owns its single border and shadow.
var book=false
func _draw():
 draw_line(Vector2(14,38),Vector2(maxf(14,size.x-14),38),Color(.65,.8,.85,.12),1)
