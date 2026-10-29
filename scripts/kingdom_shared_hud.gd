extends RefCounted
const T=preload("res://scripts/premium_theme.gd")
var h
var ui
var scale=1.0
var extent
var root
func _init(hunt):h=hunt;ui=h.game.ui
func put(node,rect):node.position=rect.position*scale;node.size=rect.size*scale;root.add_child(node);return node
func label(value,rect,n=14):
	var l=ui.label(value,n,T.CREAM);l.add_theme_font_size_override("font_size",maxi(11,int(n*scale)));l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;return put(l,rect)
func panel(rect):
	var p=Panel.new();p.add_theme_stylebox_override("panel",T.skin());p.mouse_filter=Control.MOUSE_FILTER_IGNORE;return put(p,rect)
func bar(rect,color):
	var b=ProgressBar.new();b.show_percentage=false;b.mouse_filter=Control.MOUSE_FILTER_IGNORE;var back=T.box(Color("090b08"));var fill=StyleBoxFlat.new();fill.bg_color=Color(color);b.add_theme_stylebox_override("background",back);b.add_theme_stylebox_override("fill",fill);return put(b,rect)
func action(title,key,rect,callback,name):
	var b=h.button(root,title,Rect2(rect.position*scale,rect.size*scale),callback,name);b.custom_minimum_size=Vector2.ZERO;b.add_theme_font_size_override("font_size",maxi(11,int(13*scale)));b.icon=T.icon(key) if not key.is_empty() else null;b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(23*scale));b.tooltip_text=title;return b
func orb(key,rect,callback,name):
	var b=action("",key,rect,callback,name);b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.add_theme_constant_override("icon_max_width",int(rect.size.x*scale*.72))
	for state in ["normal","hover","pressed","disabled"]:
		var skin=T.box(Color("28594e") if state=="pressed" else T.INK,true);skin.set_corner_radius_all(int(rect.size.x*scale*.5));skin.set_border_width_all(1);b.add_theme_stylebox_override(state,skin)
	return b
func build():
	extent=h.get_viewport_rect().size;scale=minf(extent.x/1280,extent.y/720);var w=extent.x/scale;var height=extent.y/scale;var layer=CanvasLayer.new();layer.layer=12;h.add_child(layer);root=Control.new();root.mouse_filter=Control.MOUSE_FILTER_IGNORE;h.hud=root;layer.add_child(root);root.theme=T.controls(ui.ui_font(),scale)
	panel(Rect2(12,12,250,103));h.status=label(h.say("Connecting…","Bağlanıyor…"),Rect2(23,17,232,25),14)
	h.hp_bar=bar(Rect2(23,45,226,13),"dc727a");h.mp_bar=bar(Rect2(23,62,226,13),"76a9e0");h.xp_bar=bar(Rect2(23,79,226,8),"8adcc1");h.vitals=label("",Rect2(25,88,220,16),11)
	h.target_label=label("",Rect2(w*.5-150,18,300,40),16);h.target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	panel(Rect2(w-214,12,200,170));label(h.say("HEARTH · SHARED HUNT","HEARTH · ORTAK AV"),Rect2(w-200,20,180,22),13).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;h.mini=put(load("res://scripts/shared_minimap.gd").new(),Rect2(w-200,48,170,122));h.mini.hunt=h
	h.exit_button=action(h.say("Town","Şehir"),"map",Rect2(w-210,190,94,42),h.leave,"LeaveSharedHunt");action(h.say("Options","Ayarlar"),"menu",Rect2(w-110,190,96,42),func():h.open_panel("settings"),"SharedOptions")
	panel(Rect2(12,height-216,370,157));action(h.say("General","Genel"),"",Rect2(23,height-206,100,26),func():h.choose_chat("general"),"FeedGeneral");action(h.say("Private","Özel"),"",Rect2(128,height-206,100,26),func():h.open_chat("private"),"FeedPrivate");action(h.say("System","Sistem"),"",Rect2(233,height-206,100,26),func():h.choose_chat("system"),"FeedSystem")
	h.chat_log=label(h.say("Welcome to Hearth.\nYour companions and other travelers share this clearing.","Hearth'e hoş geldin.\nYoldaşların ve diğer yolcular bu av alanını paylaşır."),Rect2(24,height-174,345,76),13);h.chat_log.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	action(h.say("Write a message…","Mesaj yaz…"),"workers",Rect2(24,height-96,340,28),func():h.open_chat("general"),"SharedChat")
	panel(Rect2(w*.5-312,height-54,624,50));var nav=HBoxContainer.new();nav.add_theme_constant_override("separation",3);put(nav,Rect2(w*.5-300,height-46,600,44))
	for item in [["hero","hero",h.say("Character","Karakter")],["inventory","bag",h.say("Bag","Çanta")],["skills","sword",h.say("Skills","Beceri")],["attributes","shield","Stat"],["quest","quest",h.say("Quest","Görev")],["map","map",h.say("Regions","Bölgeler")],["menu","menu",h.say("Menu","Menü")]]:
		var key=item[0];var b=ui.premium.rpg.icon_action(nav,item[1],item[2],func():h.open_panel(key));b.name="SharedNav"+key.capitalize()
	h.attack_button=orb("attack",Rect2(w-124,height-185,106,106),func():h.pending_action="attack","SharedAttack");h.attack_button.tooltip_text=h.say("Attack · hold","Saldır · basılı tut");h.attack_button.button_down.connect(func():h.attack_held=true);h.attack_button.button_up.connect(func():h.attack_held=false)
	h.skill_button=orb("fire",Rect2(w-208,height-171,68,68),func():h.pending_action="skill","SharedSkill");h.skill_button.tooltip_text=h.say("Class ability · 8 MP","Sınıf becerisi · 8 MP")
	h.target_button=orb("target",Rect2(w-208,height-252,68,68),h.cycle_target,"SharedTarget");h.target_button.tooltip_text=h.say("Select target","Hedef seç")
	orb("dodge",Rect2(w-291,height-171,68,68),func():h.pending_action="dodge","SharedDodge").tooltip_text=h.say("Dodge","Kaçın")
	label(h.say("Class skill","Sınıf becerisi"),Rect2(w-212,height-101,82,28),11).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label(h.say("Attack","Saldır"),Rect2(w-110,height-77,85,22),12).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	h.stick_center=Vector2(85,height-290)*scale;var stick=load("res://scripts/adventure_stick.gd").new();stick.position=h.stick_center;stick.radius=48*scale;layer.add_child(stick)

	h.choose_chat("general")
