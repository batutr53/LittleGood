extends RefCounted
const INK=Color("14212b")
const SURFACE=Color("20313c")
const CREAM=Color("edf4f5")
const GOLD=Color("8adcc1")
const MUTED=Color("a4b7c2")
static func box(color:Color=SURFACE,primary:bool=false)->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(9);s.set_border_width_all(1);s.border_color=Color("46616c") if primary else Color("304652");s.shadow_color=Color(0,0,0,.18);s.shadow_size=4;s.shadow_offset=Vector2(0,2)
 s.content_margin_left=8;s.content_margin_right=8;s.content_margin_top=5;s.content_margin_bottom=5
 return s
static func skin(kind="frame")->StyleBoxFlat:
 var color={"frame":Color(.065,.105,.14,.96),"button":Color("243845"),"hover":Color("304b59"),"pressed":Color("28594e"),"disabled":Color("192832")}.get(kind,INK)
 var s=box(color);s.set_corner_radius_all(10 if kind=="frame" else 7);s.border_color=GOLD if kind=="pressed" else Color("304652")
 s.set_content_margin_all(12 if kind=="frame" else 6)
 return s
static func nav(active=false)->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=Color(.4,.85,.72,.14) if active else Color(0,0,0,0);s.set_corner_radius_all(7);s.set_content_margin_all(0)
 if active:s.border_color=GOLD;s.border_width_bottom=2
 return s
static func controls(font:Font,scale=1.0)->Theme:
 var t=Theme.new();t.default_font=font;t.default_font_size=maxi(11,roundi(14*scale))
 for type in ["Label","Button","LineEdit","CheckButton","OptionButton","PopupMenu"]:
  t.set_color("font_color",type,CREAM);t.set_color("font_hover_color",type,CREAM);t.set_color("font_pressed_color",type,CREAM);t.set_color("font_disabled_color",type,MUTED)
 for type in ["Button","OptionButton"]:
  for state in ["normal","hover","pressed","disabled"]:t.set_stylebox(state,type,skin({"normal":"button"}.get(state,state)))
 for type in ["LineEdit","TextEdit"]:
  t.set_stylebox("normal",type,skin("button"));t.set_stylebox("focus",type,skin("pressed"));t.set_stylebox("read_only",type,skin("disabled"));t.set_color("font_color",type,CREAM);t.set_color("font_placeholder_color",type,MUTED);t.set_color("caret_color",type,GOLD)
 t.set_stylebox("panel","PopupMenu",skin());t.set_stylebox("hover","PopupMenu",skin("hover"))
 for type in ["VScrollBar","HScrollBar"]:
  t.set_stylebox("scroll",type,box(Color(.04,.07,.1,.4)));t.set_stylebox("grabber",type,box(Color("496471")));t.set_stylebox("grabber_highlight",type,box(GOLD))
 return t
static func icon(key: String) -> Texture2D:
 if ResourceLoader.exists("res://assets/ui_simple/"+key+".svg"):return load("res://assets/ui_simple/"+key+".svg")
 var libreko={"hero":"user","bag":"bag","quest":"scroll","hammer":"hammer","workers":"users-three","menu":"sliders","map":"pin","shield":"combat-defence"}
 if libreko.has(key):return load("res://assets/third_party/libreko/"+libreko[key]+".svg")
 if ResourceLoader.exists("res://assets/ui_classic/"+key+".svg"):return load("res://assets/ui_classic/"+key+".svg")
 return load("res://assets/ui_rebirth/"+key+".svg")
