extends RefCounted
const INK=Color("0d141c")
const SURFACE=Color("202c38")
const CREAM=Color("f3ecdc")
const GOLD=Color("d7b675")
const MUTED=Color("c2c9cb")
static func box(color: Color= SURFACE,primary: bool=false) -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(3);s.set_border_width_all(1);s.border_color=GOLD if primary else Color("68747c");s.shadow_color=Color(0,0,0,.7);s.shadow_size=3;s.shadow_offset=Vector2(1,2)
 s.content_margin_left=6;s.content_margin_right=6;s.content_margin_top=4;s.content_margin_bottom=4
 return s
static func icon(key: String) -> Texture2D:
 var libreko={"hero":"user","bag":"bag","quest":"scroll","hammer":"hammer","workers":"users-three","menu":"sliders","map":"pin","shield":"combat-defence"}
 if libreko.has(key):return load("res://assets/third_party/libreko/"+libreko[key]+".svg")
 if ResourceLoader.exists("res://assets/ui_classic/"+key+".svg"):return load("res://assets/ui_classic/"+key+".svg")
 return load("res://assets/ui_rebirth/"+key+".svg")
