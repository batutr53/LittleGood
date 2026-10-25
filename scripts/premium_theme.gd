extends RefCounted
const INK=Color("181a13")
const SURFACE=Color("292a20")
const CREAM=Color("eee4ca")
const GOLD=Color("c5a46b")
const MUTED=Color("b5ad92")
static func box(color: Color= SURFACE,primary: bool=false) -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(4);s.set_border_width_all(1);s.border_color=GOLD if primary else Color("68604a");s.shadow_color=Color(0,0,0,.3);s.shadow_size=6;s.shadow_offset=Vector2(0,3)
 s.content_margin_left=20;s.content_margin_right=20;s.content_margin_top=16;s.content_margin_bottom=16
 return s
static func icon(key: String) -> Texture2D:
 return load("res://assets/ui_rebirth/"+key+".svg")
