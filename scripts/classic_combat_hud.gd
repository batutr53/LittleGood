extends RefCounted
var a
func _init(scene):a=scene
func build():
	var game=a.game;var p=game.ui.premium;var T=preload("res://scripts/premium_theme.gd")
	var layer=CanvasLayer.new();layer.layer=12;a.add_child(layer);a.hud=Control.new();a.hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(a.hud)
	var extent=a.get_viewport_rect().size;var width=extent.x;var height=extent.y;var s=minf(width/1280,height/720)
	var status=Panel.new();status.add_theme_stylebox_override("panel",T.box(Color(.035,.045,.025,.85),true));a.place(status,Rect2(5*s,5*s,235*s,61*s))
	a.health=game.ui.label("",int(13*s));a.place(a.health,Rect2(12*s,7*s,220*s,23*s))
	a.rpg_health_bar=ProgressBar.new();a.rpg_health_bar.show_percentage=false;var red=StyleBoxFlat.new();red.bg_color=Color("a32930");a.rpg_health_bar.add_theme_stylebox_override("fill",red);a.place(a.rpg_health_bar,Rect2(12*s,36*s,220*s,9*s))
	a.rpg_mana_bar=ProgressBar.new();a.rpg_mana_bar.show_percentage=false;var blue=StyleBoxFlat.new();blue.bg_color=Color("285daf");a.rpg_mana_bar.add_theme_stylebox_override("fill",blue);a.place(a.rpg_mana_bar,Rect2(12*s,48*s,220*s,9*s))
	a.objective=game.ui.label("",int(12*s));a.place(a.objective,Rect2(width-240*s,6*s,232*s,47*s))
	var mini=preload("res://scripts/rpg_minimap.gd").new();mini.game=game;mini.adventure=true;a.place(mini,Rect2(width-112*s,60*s,104*s,84*s))
	var chat=Panel.new();chat.add_theme_stylebox_override("panel",T.box(Color(.02,.035,.025,.64),true));a.place(chat,Rect2(6*s,height-230*s,448*s,181*s))
	var tabs=game.ui.label(a.say("GENERAL  ·  PRIVATE  ·  SYSTEM","GENEL  ·  ÖZEL  ·  SİSTEM"),int(11*s));a.place(tabs,Rect2(12*s,height-228*s,430*s,20*s))
	a.message=game.ui.label(a.say("Ready","Hazır"),int(12*s));a.place(a.message,Rect2(12*s,height-205*s,430*s,145*s))
	var bar=Panel.new();bar.add_theme_stylebox_override("panel",T.box(Color("151b11"),true));a.place(bar,Rect2(0,height-40*s,width,40*s))
	var nav=HBoxContainer.new();nav.add_theme_constant_override("separation",0);a.place(nav,Rect2(width-400*s,height-44*s,392*s,44*s))
	for item in [["hero","hero",a.say("Char","Karakter")],["inventory","bag",a.say("Bag","Çanta")],["skills","sword",a.say("Skill","Beceri")],["attributes","shield",a.say("Stat","Stat")],["quest","quest",a.say("Quest","Görev")],["map","map",a.say("Town","Işınlan")],["chat","workers",a.say("Chat","Sohbet")],["menu","menu",a.say("Menu","Menü")]]:
		var key=item[0];game.ui.premium.rpg.icon_action(nav,item[1],item[2],func():a.open_rpg_panel(key))
	var level=preload("res://scripts/hero.gd").level(game.world.kingdom.adventure.hero);var xp=ProgressBar.new();xp.show_percentage=false;xp.max_value=40*(2*level-1);xp.value=game.world.kingdom.adventure.hero.xp-40*(level-1)*(level-1);a.place(xp,Rect2(15*s,height-23*s,maxf(100*s,width-440*s),8*s))
	for row in [["attack","attack",Vector2(width-130*s,height-193*s),100],["skill","fire",Vector2(width-205*s,height-160*s),57],["rpg_skill1","ice",Vector2(width-212*s,height-232*s),57],["rpg_skill2","bolt",Vector2(width-141*s,height-268*s),57],["dodge","dodge",Vector2(width-283*s,height-230*s),57],["heal","potion",Vector2(width-281*s,height-154*s),57],["interact","hand",Vector2(width-353*s,height-153*s),57]]:
		var key=row[0];var diameter=float(row[3])*s
		a.add_button(key,"",Rect2(row[2],Vector2.ONE*diameter),func():
			if key=="interact":a.interact()
			elif key.begins_with("rpg_skill"):a.actions.skill=true;a.actions.skill_slot=int(key.substr(9))
			else:a.actions[key]=true)
		var b=a.buttons[key];b.icon=T.icon(row[1]);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(diameter-4*s));b.custom_minimum_size=Vector2.ONE*diameter;b.size=Vector2.ONE*diameter;b.add_theme_font_size_override("font_size",int(12*s));b.tooltip_text=key.capitalize()
		for state in ["normal","hover","pressed","disabled","focus"]:
			var skin=StyleBoxFlat.new();skin.bg_color=Color(0,0,0,0);skin.set_content_margin_all(0);skin.set_corner_radius_all(int(diameter*.5));b.add_theme_stylebox_override(state,skin)
		if key=="attack":b.button_down.connect(func():a.attack_held=true);b.button_up.connect(func():a.attack_held=false)
	for row in [["return",a.say("Home","Dön"),Vector2(width-226*s,66*s),a.go_home],["pause",a.say("Pause","Dur"),Vector2(width-226*s,104*s),a.toggle_pause]]:
		a.add_button(row[0],row[1],Rect2(row[2],Vector2(102*s,30*s)),row[3]);var b=a.buttons[row[0]];b.custom_minimum_size=Vector2(102*s,30*s);b.add_theme_font_size_override("font_size",int(12*s));game.ui.premium.rpg.compact_button(b)
	a.stick=preload("res://scripts/adventure_stick.gd").new();a.stick.radius=55*s;a.stick.position=Vector2(85*s,height-300*s);layer.add_child(a.stick)
	if a.region=="sanctuary":a.add_button("pack",a.say("Pack","Çanta"),Rect2(246*s,8*s,65*s,29*s),a.toggle_pack)
	a.refresh_hud()
