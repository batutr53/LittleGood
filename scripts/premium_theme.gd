extends RefCounted
const INK=Color("12150f")
const SURFACE=Color("26291f")
const CREAM=Color("eee5cb")
const GOLD=Color("d8bb70")
const MUTED=Color("b7b49c")
static func box(color: Color= SURFACE,primary: bool=false) -> StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(2);s.set_border_width_all(1);s.border_color=GOLD if primary else Color("6d6547");s.shadow_color=Color(0,0,0,.7);s.shadow_size=3;s.shadow_offset=Vector2(1,2)
 s.content_margin_left=6;s.content_margin_right=6;s.content_margin_top=4;s.content_margin_bottom=4
 return s
static func skin(kind="frame")->StyleBoxTexture:
 var s=StyleBoxTexture.new();s.texture=load("res://assets/ui_kingdom/"+kind+".svg")
 for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:s.set_texture_margin(side,12);s.set_content_margin(side,8 if kind=="frame" else 4)
 return s
static func icon(key: String) -> Texture2D:
 var libreko={"hero":"user","bag":"bag","quest":"scroll","hammer":"hammer","workers":"users-three","menu":"sliders","map":"pin","shield":"combat-defence"}
 if libreko.has(key):return load("res://assets/third_party/libreko/"+libreko[key]+".svg")
 if ResourceLoader.exists("res://assets/ui_classic/"+key+".svg"):return load("res://assets/ui_classic/"+key+".svg")
 return load("res://assets/ui_rebirth/"+key+".svg")
