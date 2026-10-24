extends Control
# Retained fantasy surface detailing. No per-frame repaint or gameplay state.
var book=false
func _draw():
 var w=size.x;var h=size.y
 draw_rect(Rect2(Vector2.ZERO,size),Color("101f2b"))
 draw_rect(Rect2(6,6,w-12,h-12),Color("243d46"),false,1)
 draw_line(Vector2(22,12),Vector2(w-22,12),Color("aa8c59"),2,true)
 for x in [22.0,w-22]:
  for y in [22.0,h-22]:
   var s=1 if x<30 else -1;var v=1 if y<30 else -1
   draw_line(Vector2(x,y),Vector2(x+30*s,y),Color("c5a46b"),2,true);draw_line(Vector2(x,y),Vector2(x,y+30*v),Color("c5a46b"),2,true)
   draw_circle(Vector2(x+6*s,y+6*v),2,Color("c5a46b"))
 if book:
  draw_rect(Rect2(0,0,8,h),Color("6e644d"));draw_line(Vector2(14,34),Vector2(14,h-34),Color("c0ab79"),1,true)
