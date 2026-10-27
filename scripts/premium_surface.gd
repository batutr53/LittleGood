extends Control
# Retained fantasy surface detailing. No per-frame repaint or gameplay state.
var book=false
func _draw():
 var w=size.x;var h=size.y
 draw_rect(Rect2(Vector2.ZERO,size),Color("101922"))
 # Original subtle leather grain, deterministic and retained between redraws.
 for i in range(85):
  var x=fposmod(i*137.37,w);var y=fposmod(i*79.73,h)
  draw_line(Vector2(x,y),Vector2(minf(w,x+8+fmod(i,21)),y+1),Color(.55,.47,.29,.045),1)
 draw_rect(Rect2(2,2,w-4,h-4),Color("667380"),false,1)
 for y in range(27):draw_line(Vector2(4,y+3),Vector2(w-4,y+3),Color(.22-y*.003,.28-y*.004,.34-y*.004),1)
 draw_line(Vector2(5,31),Vector2(w-5,31),Color("d0ac6e"),1,true)
 draw_line(Vector2(5,33),Vector2(w-5,33),Color("030a11"),2,true)
 for x in [5.0,w-5]:
  for y in [5.0,h-5]:
   var s=1 if x<30 else -1;var v=1 if y<30 else -1
   draw_line(Vector2(x,y),Vector2(x+10*s,y),Color("c5a46b"),1,true);draw_line(Vector2(x,y),Vector2(x,y+10*v),Color("c5a46b"),1,true)
   draw_circle(Vector2(x+2*s,y+2*v),1,Color("c5a46b"))
 if book:
  draw_rect(Rect2(0,0,8,h),Color("6e644d"));draw_line(Vector2(14,34),Vector2(14,h-34),Color("c0ab79"),1,true)
