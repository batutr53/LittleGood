extends RefCounted
const T=preload("res://scripts/premium_theme.gd")
var a
func _init(scene):a=scene
func build():
	var game=a.game;var extent=a.get_viewport_rect().size;var s=minf(extent.x/1280,extent.y/720)
	var layer=CanvasLayer.new();layer.layer=12;a.add_child(layer);a.hud=Control.new();a.hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;a.hud.theme=T.controls(game.ui.ui_font(),s);layer.add_child(a.hud)
	var panel=Panel.new();panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_theme_stylebox_override("panel",T.skin());a.place(panel,Rect2(12*s,12*s,430*s,88*s))
	a.title=game.ui.label("",16,T.CREAM);a.title.autowrap_mode=TextServer.AUTOWRAP_OFF;a.place(a.title,Rect2(26*s,21*s,400*s,25*s))
	a.status=game.ui.label("",12,T.MUTED);a.place(a.status,Rect2(26*s,49*s,400*s,44*s))
	var width=840*s;var left=(extent.x-width)*.5;var top=extent.y-62*s;panel=Panel.new();panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_theme_stylebox_override("panel",T.skin());a.place(panel,Rect2(left-10*s,top-8*s,width+20*s,60*s))
	var keys=["advance","hold","retreat","balanced","defensive","assault","pause","home"]
	var titles=[a.say("Advance","İlerle"),a.say("Hold","Tut"),a.say("Retreat","Geri çekil"),a.say("Balanced","Dengeli"),a.say("Defensive","Savunma"),a.say("Assault","Hücum"),a.say("Pause","Dur"),a.say("Return","Eve dön")]
	for i in range(keys.size()):
		var key=keys[i];var cb=a.toggle_pause if key=="pause" else a.go_home if key=="home" else func():
			if key in ["advance","hold","retreat"]:a.M.order(game.world,key)
			else:a.M.formation(game.world,key)
			game.checkpoint("army-command")
		a.button(key,titles[i],Rect2(left+i*106*s,top,98*s,44*s),cb);var b=a.buttons[key];b.add_theme_font_size_override("font_size",maxi(10,int(13*s)))
		if key not in ["pause","home"]:b.toggle_mode=true
