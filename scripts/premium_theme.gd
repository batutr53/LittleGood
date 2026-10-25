extends RefCounted
const INK=Color("0c100b")
const SURFACE=Color("282d1c")
const CREAM=Color("eee4ca")
const GOLD=Color("c5a46b")
const MUTED=Color("b5ad92")
static func box(color: Color= SURFACE,primary: bool=false) -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(2);s.set_border_width_all(1);s.border_color=GOLD if primary else Color("646847");s.shadow_color=Color(0,0,0,.55);s.shadow_size=2;s.shadow_offset=Vector2(1,1)
 s.content_margin_left=6;s.content_margin_right=6;s.content_margin_top=4;s.content_margin_bottom=4
 return s
static func icon(key: String) -> Texture2D:
 if ResourceLoader.exists("res://assets/ui_classic/"+key+".svg"):return load("res://assets/ui_classic/"+key+".svg")
 return load("res://assets/ui_rebirth/"+key+".svg")
