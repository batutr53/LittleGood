extends RefCounted
var a
func _init(scene):a=scene
func build():
	var game=a.game;var p=game.ui.premium;var T=preload("res://scripts/premium_theme.gd")
	var layer=CanvasLayer.new();layer.layer=12;a.add_child(layer);a.hud=Control.new();a.hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(a.hud)
	var extent=a.get_viewport_rect().size;var width=extent.x;var height=extent.y;var s=minf(width/1280,height/720)
	var status=Panel.new();status.add_theme_stylebox_override("panel",T.skin());a.place(status,Rect2(5*s,5*s,235*s,61*s))
	a.health=game.ui.label("",int(13*s));a.place(a.health,Rect2(12*s,7*s,220*s,23*s))
	a.rpg_health_bar=ProgressBar.new();a.rpg_health_bar.show_percentage=false;var red=StyleBoxFlat.new();red.bg_color=Color("a32930");a.rpg_health_bar.add_theme_stylebox_override("fill",red);a.place(a.rpg_health_bar,Rect2(12*s,36*s,220*s,9*s))
	a.rpg_mana_bar=ProgressBar.new();a.rpg_mana_bar.show_percentage=false;var blue=StyleBoxFlat.new();blue.bg_color=Color("285daf");a.rpg_mana_bar.add_theme_stylebox_override("fill",blue);a.place(a.rpg_mana_bar,Rect2(12*s,48*s,220*s,9*s))
	a.mana_label=game.ui.premium.text("",17);a.mana_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;a.mana_label.add_theme_color_override("font_shadow_color",Color.BLACK);a.mana_label.add_theme_constant_override("shadow_outline_size",3);a.place(a.mana_label,Rect2(12*s,44*s,217*s,15*s))
	a.objective=game.ui.label("",int(12*s));a.place(a.objective,Rect2(width-240*s,6*s,232*s,47*s))
	var objective_back=Panel.new();objective_back.mouse_filter=Control.MOUSE_FILTER_IGNORE;objective_back.add_theme_stylebox_override("panel",T.skin());a.place(objective_back,a.objective.get_rect());a.hud.move_child(objective_back,a.objective.get_index())
	var mini=preload("res://scripts/rpg_minimap.gd").new();mini.game=game;mini.adventure=true;a.place(mini,Rect2(width-112*s,60*s,104*s,84*s))
	var chat=Panel.new();chat.add_theme_stylebox_override("panel",T.skin());a.place(chat,Rect2(6*s,height-230*s,448*s,181*s))
	var tabs=game.ui.label(a.say("GENERAL  ·  PRIVATE  ·  SYSTEM","GENEL  ·  ÖZEL  ·  SİSTEM"),int(11*s));a.place(tabs,Rect2(12*s,height-228*s,430*s,20*s))
	a.message=game.ui.label(a.say("Ready","Hazır"),int(12*s));a.place(a.message,Rect2(12*s,height-205*s,430*s,145*s))
	var bar=Panel.new();bar.add_theme_stylebox_override("panel",T.skin());a.place(bar,Rect2(0,height-40*s,width,40*s))
	var nav=HBoxContainer.new();nav.add_theme_constant_override("separation",0);a.place(nav,Rect2(width-400*s,height-44*s,392*s,44*s))
	for item in [["hero","hero",a.say("Char","Karakter")],["inventory","bag",a.say("Bag","Çanta")],["skills","sword",a.say("Skill","Beceri")],["attributes","shield",a.say("Stat","Stat")],["quest","quest",a.say("Quest","Görev")],["map","map",a.say("Town","Işınlan")],["chat","workers",a.say("Chat","Sohbet")],["menu","menu",a.say("Menu","Menü")]]:
		var key=item[0];var button=game.ui.premium.rpg.icon_action(nav,item[1],item[2],func():a.open_rpg_panel(key));button.name="CombatNav"+key.capitalize()
	a.rpg_experience_bar=ProgressBar.new();a.rpg_experience_bar.show_percentage=false;var xp_fill=StyleBoxFlat.new();xp_fill.bg_color=Color("b69bd9");a.rpg_experience_bar.add_theme_stylebox_override("fill",xp_fill);a.place(a.rpg_experience_bar,Rect2(15*s,height-17*s,maxf(100*s,width-440*s),8*s))
	a.experience_label=game.ui.premium.text("",16);a.place(a.experience_label,Rect2(15*s,height-36*s,maxf(100*s,width-440*s),17*s))
	for row in [["attack","attack",Vector2(width-130*s,height-193*s),100],["skill","fire",Vector2(width-205*s,height-160*s),57],["rpg_skill1","ice",Vector2(width-212*s,height-232*s),57],["rpg_skill2","bolt",Vector2(width-141*s,height-268*s),57],["dodge","dodge",Vector2(width-283*s,height-230*s),57],["heal","potion",Vector2(width-281*s,height-154*s),57],["interact","hand",Vector2(width-353*s,height-153*s),57],["target","target",Vector2(width-354*s,height-230*s),57]]:
		var key=row[0];var diameter=float(row[3])*s
		a.add_button(key,"",Rect2(row[2],Vector2.ONE*diameter),func():
			if key=="interact":a.interact()
			elif key=="target" and is_instance_valid(a.targeting):a.targeting.cycle()
			elif key.begins_with("rpg_skill"):a.actions.skill=true;a.actions.skill_slot=int(key.substr(9))
			else:a.actions[key]=true)
		var b=a.buttons[key];b.icon=T.icon(row[1]);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(diameter-4*s));b.custom_minimum_size=Vector2.ONE*diameter;b.size=Vector2.ONE*diameter;b.add_theme_font_size_override("font_size",int(12*s));b.tooltip_text=key.capitalize()
		var badge=preload("res://scripts/action_badge.gd").new();badge.name="ActionBadge";b.add_child(badge)
		for state in ["normal","hover","pressed","disabled","focus"]:
			var skin=StyleBoxFlat.new();skin.bg_color=Color(0,0,0,0);skin.set_content_margin_all(0);skin.set_corner_radius_all(int(diameter*.5));b.add_theme_stylebox_override(state,skin)
		if key=="attack":b.button_down.connect(func():a.attack_held=true);b.button_up.connect(func():a.attack_held=false)
		var names={"attack":a.say("Attack","Saldır"),"skill":a.say("Skill I","Beceri I"),"rpg_skill1":a.say("Skill II","Beceri II"),"rpg_skill2":a.say("Skill III","Beceri III"),"dodge":a.say("Dodge","Kaçın"),"heal":a.say("Potion","İksir"),"interact":a.say("Inspect","İncele"),"target":a.say("Target · Z","Hedef · Z")};b.tooltip_text=names[key]
		var caption=game.ui.premium.text(names[key],16,T.CREAM);caption.autowrap_mode=TextServer.AUTOWRAP_OFF;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_outline_size",3);a.place(caption,Rect2(row[2]+Vector2(-5*s,diameter-2*s),Vector2(diameter+10*s,17*s)))
		a.action_captions[key]=caption
	for row in [["return",a.say("Home","Dön"),Vector2(width-226*s,66*s),a.go_home],["pause",a.say("Pause","Dur"),Vector2(width-226*s,104*s),a.toggle_pause]]:
		a.add_button(row[0],row[1],Rect2(row[2],Vector2(102*s,30*s)),row[3]);var b=a.buttons[row[0]];b.custom_minimum_size=Vector2(102*s,30*s);b.add_theme_font_size_override("font_size",int(12*s));game.ui.premium.rpg.compact_button(b)
	a.stick=preload("res://scripts/adventure_stick.gd").new();a.stick.radius=55*s;a.stick.position=Vector2(85*s,height-300*s);layer.add_child(a.stick)
	var movement_help=game.ui.premium.text(a.say("Drag / WASD","Sürükle / WASD"),17,T.CREAM);movement_help.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;a.place(movement_help,Rect2(15*s,height-240*s,140*s,19*s))
	a.add_button("hunts",a.say("Boss / Hunt","Boss / Av"),Rect2(width-226*s,143*s,102*s,36*s),func():a.open_rpg_panel("hunts"));game.ui.premium.rpg.compact_button(a.buttons.hunts);a.buttons.hunts.custom_minimum_size.y=36*s;a.buttons.hunts.add_theme_font_size_override("font_size",int(12*s))
	if a.region=="sanctuary":a.add_button("pack",a.say("Pack","Çanta"),Rect2(246*s,8*s,65*s,29*s),a.toggle_pack)
	a.refresh_hud()
