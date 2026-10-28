extends RefCounted
# Measurements are proportional to the inspected 1048x577 mobile reference.
# Art is original; this adapter owns presentation only.
var r
var p
var ui
var game
var hp: ProgressBar
var mp: ProgressBar
var xp: ProgressBar
var log: Label
func _init(owner):r=owner;p=r.p;ui=r.ui;game=r.game
func bar(color: Color,rect: Rect2) -> ProgressBar:
	var b=ProgressBar.new();b.show_percentage=false;b.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var back=StyleBoxFlat.new();back.bg_color=Color("090c0d");back.set_border_width_all(1);back.border_color=Color("8e937f")
	var fill=StyleBoxFlat.new();fill.bg_color=color;b.add_theme_stylebox_override("background",back);b.add_theme_stylebox_override("fill",fill);p.put(b,rect);return b
func label_at(text: String,rect: Rect2,font_size=13,color=Color("ece6d0")) -> Label:
	var l=p.text(text,20,color);l.add_theme_font_size_override("font_size",int(p.px(font_size)));p.put(l,rect);return l
func build():
	load("res://scripts/colony.gd").ensure(game.world)
	load("res://scripts/rpg_progression.gd").ensure(game.world)
	load("res://scripts/armory.gd").ensure(game.world)
	if is_instance_valid(ui.root):ui.remove_child(ui.root);ui.root.queue_free()
	ui.modal=null;ui.veil=null;ui.root=Control.new();ui.root.name="WorldHUD";ui.root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.root.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(ui.root)
	var s=p.size();var z=p.scale_ui();var bottom=s.y-p.px(40)
	r.card(Rect2(p.px(5),p.px(5),p.px(235),p.px(61)))
	r.hud_portrait=p.image(load("res://assets/rpg/warrior.png"),Vector2.ZERO);r.hud_class="";p.put(r.hud_portrait,Rect2(p.px(9),p.px(7),p.px(30),p.px(55)))
	ui.header=label_at("",Rect2(p.px(43),p.px(7),p.px(185),p.px(17)),13)
	ui.stats=label_at("",Rect2(p.px(43),p.px(23),p.px(185),p.px(12)),10)
	hp=bar(Color("9d262d"),Rect2(p.px(43),p.px(37),p.px(185),p.px(9)));mp=bar(Color("245cb3"),Rect2(p.px(43),p.px(48),p.px(185),p.px(9)))
	ui.spirit=label_at("",Rect2(p.px(252),p.px(8),p.px(160),p.px(20)),12)
	ui.realm_bar=ui.button("",func():p.route("menu"));ui.root.add_child(ui.realm_bar);ui.realm_bar.hide()
	var resources=HBoxContainer.new();p.put(resources,Rect2(p.px(252),p.px(31),p.px(275),p.px(25)));p.resource_labels.clear()
	for key in ["wood","stone","gold","food"]:
		var row=HBoxContainer.new();row.custom_minimum_size.x=p.px(65);resources.add_child(row);row.add_child(p.image(r.T.icon(key),Vector2.ONE*p.px(16)));var l=p.text("0",18);l.autowrap_mode=TextServer.AUTOWRAP_OFF;l.custom_minimum_size.x=p.px(42);row.add_child(l);p.resource_labels[key]=l
	ui.chapter=ui.button("",func():p.route("quest") if game.world.has("kingdom") else game.realm_ui.intro());r.compact_button(ui.chapter);ui.chapter.name="CurrentObjective";ui.chapter.custom_minimum_size=Vector2.ZERO;ui.chapter.add_theme_font_size_override("font_size",int(p.px(12)));p.put(ui.chapter,Rect2(s.x-p.px(205),p.px(5),p.px(200),p.px(47)))
	var mini=preload("res://scripts/rpg_minimap.gd").new();mini.game=game;p.put(mini,Rect2(s.x-p.px(110),p.px(60),p.px(104),p.px(84)))
	var selection=preload("res://scripts/world_selection.gd").new();selection.game=game;selection.name="WorldSelection";p.put(selection,Rect2(s.x*.5-p.px(180),p.px(76),p.px(360),p.px(64)))
	ui.hint=label_at("",Rect2(s.x-p.px(240),p.px(153),p.px(230),p.px(42)),13,Color("ffc36d"))
	# The visual strip is 5.6% of the reference height. Icons keep separate labels.
	r.card(Rect2(0,bottom,s.x,p.px(40)))
	var nav=HBoxContainer.new();nav.add_theme_constant_override("separation",0);p.put(nav,Rect2(s.x-p.px(9*49+8),bottom-p.px(4),p.px(9*49),p.px(44)))
	for entry in [["hero","hero",r.say("Char","Karakter")],["inventory","bag",r.say("Bag","Çanta")],["skills","sword",r.say("Skill","Beceri")],["attributes","shield",r.say("Stat","Stat")],["quest","quest",r.say("Quest","Görev")],["map","map",r.say("Regions","Bölgeler")],["construction","hammer",r.say("Build","İnşa")],["workers","workers",r.say("People","Halk")],["menu","menu",r.say("Menu","Menü")]]:
		var key=entry[0];var b=r.icon_action(nav,entry[1],entry[2],func():p.route(key));b.name="WorldMenu" if key=="menu" else "Nav"+key.capitalize()
		b.set_meta("nav_key",key)
	var left=HBoxContainer.new();p.put(left,Rect2(p.px(7),bottom-p.px(4),p.px(150),p.px(44)))
	r.icon_action(left,"menu",r.say("Colony","Koloni"),func():p.route("colony"));var hunts=r.icon_action(left,"sword",r.say("Hunt","Boss"),func():p.route("hunts"));hunts.tooltip_text=r.say("Boss / Hunt","Boss / Av");hunts.name="OpenHunts";r.icon_action(left,"workers",r.say("Chat","Sohbet"),func():p.route("chat"))
	xp=bar(Color("70943e"),Rect2(p.px(170),bottom+p.px(15),maxf(p.px(60),s.x-p.px(635)),p.px(9)))
	r.chat_box=r.card(Rect2(p.px(6),bottom-p.px(190),p.px(448),p.px(185)));r.chat_box.name="ChatPanel"
	var tabs=p.text(r.say("GENERAL     PRIVATE     SYSTEM","GENEL       ÖZEL       SİSTEM"),17,Color("d8c68f"));tabs.autowrap_mode=TextServer.AUTOWRAP_OFF;r.chat_box.add_child(tabs);tabs.name="ChatPreviewTabs";tabs.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tabs.position=Vector2(p.px(12),p.px(9));tabs.size=Vector2(p.px(424),p.px(21))
	log=p.text("",20,Color("c8c18b"));r.chat_box.add_child(log);log.position=Vector2(p.px(12),p.px(35));log.size=Vector2(p.px(424),p.px(106));log.clip_text=true
	var open=ui.button(r.say("Enter message…","Mesaj yaz…"),func():p.route("chat"));r.compact_button(open);open.custom_minimum_size=Vector2.ZERO;open.add_theme_font_size_override("font_size",int(p.px(11)));r.chat_box.add_child(open);open.position=Vector2(p.px(12),p.px(149));open.size=Vector2(p.px(388),p.px(27));open.alignment=HORIZONTAL_ALIGNMENT_LEFT
	r.chat_reopen=ui.button(r.say("Chat +","Sohbet +"),func():r.chat_collapsed=false;r.refresh_portrait());r.chat_reopen.name="ReopenChat";r.compact_button(r.chat_reopen);r.chat_reopen.custom_minimum_size=Vector2.ZERO;p.put(r.chat_reopen,Rect2(p.px(6),bottom-p.px(37),p.px(95),p.px(30)));r.chat_reopen.hide()
	var collapse=ui.button("−",func():r.chat_collapsed=true;r.refresh_portrait());collapse.name="CollapseChat";r.compact_button(collapse);collapse.custom_minimum_size=Vector2.ZERO;r.chat_box.add_child(collapse);collapse.position=Vector2(p.px(406),p.px(149));collapse.size=Vector2(p.px(30),p.px(27))
	var controls=HBoxContainer.new();p.put(controls,Rect2(s.x-p.px(161),bottom-p.px(57),p.px(153),p.px(48)))
	r.icon_action(controls,"gift",r.say("Gifts","Güçler"),func():p.gifts_open=not p.gifts_open;p.tray.visible=p.gifts_open)
	ui.speed_button=r.icon_action(controls,"crown","1×",func():game.speed=3 if game.speed==1 else 1;ui.refresh())
	r.icon_action(controls,"map",r.say("Center","Ortala"),func():game.view.pan=Vector2.ZERO)
	p.tray=HBoxContainer.new();p.tray.name="GiftPalette";p.tray.visible=false;p.put(p.tray,Rect2(s.x-p.px(510),bottom-p.px(110),p.px(500),p.px(44)));ui.power_buttons.clear();ui.power_icons.clear()
	for i in range(6):
		var b=ui.button(ui.t(ui.POWER_KEYS[i]),func():ui.choose_power(i));b.custom_minimum_size=Vector2.ZERO;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;p.tray.add_child(b);ui.power_buttons.append(b)
		if i==3:b.hide();b.disabled=true
	var land=ui.button(r.say("LAND +","ARAZİ +"),func():p.route("estate"));land.name="ExpandLand";r.compact_button(land);p.put(land,Rect2(p.px(535),p.px(8),p.px(90),p.px(48)))
	var zoom_out=ui.button("−",func():game.view.zoom_at(game.view.origin,.8));zoom_out.name="ZoomOut";r.compact_button(zoom_out);p.put(zoom_out,Rect2(p.px(632),p.px(8),p.px(48),p.px(48)))
	var zoom_in=ui.button("+",func():game.view.zoom_at(game.view.origin,1.25));zoom_in.name="ZoomIn";r.compact_button(zoom_in);p.put(zoom_in,Rect2(p.px(684),p.px(8),p.px(48),p.px(48)))
	ui.refresh()
func refresh():
	if not is_instance_valid(ui.header) or game.world.is_empty():return
	r.highlight_navigation()
	var w=game.world;ui.header.add_theme_font_size_override("font_size",int(p.px(13)));ui.stats.add_theme_font_size_override("font_size",int(p.px(10)));ui.realm_bar.hide()
	if r.R.available(w):
		var h=w.kingdom.adventure.hero;var level=r.H.level(h);hp.max_value=r.H.stats(w).health;hp.value=h.hp;mp.max_value=r.R.modifiers(w).mana;mp.value=w.rpg.progression[w.rpg.active].mana if w.has("rpg") else 100
		ui.header.text=h.name+"   "+str(level);ui.stats.text=r.R.NAMES[h.get("class","warrior")]+" · "+str(int(h.hp))+" / "+str(int(hp.max_value))+" HP"
		xp.max_value=40*(level*level-(level-1)*(level-1));xp.value=h.xp-40*(level-1)*(level-1)
	else:ui.header.text=r.say("LittleGod · Your realm","LittleGod · Krallığın");hp.value=100;mp.value=100
	var lines=[]
	for event in ui.system_events(4):lines.append(ui.event_text(event))
	log.text="\n".join(lines) if not lines.is_empty() else r.say("Your world is ready.\nSystem events appear here.","Dünyan hazır.\nOyun olayları burada görünür.")
