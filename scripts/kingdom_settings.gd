extends RefCounted
var p
var game
var ui
var tab="game"
var draft={}
func _init(presentation):p=presentation;game=p.game;ui=p.ui;draft={"sound":game.audio.enabled,"haptics":game.haptics,"battery":game.view.low_quality,"contrast":ui.high_contrast,"motion":ui.reduce_motion,"text":ui.accessibility_scale}
func say(en,tr):return p.say(en,tr)
func open():
	var v=p.surface(say("OPTIONS","AYARLAR"));v.add_child(p.text(say("Changes take effect when you press Apply.","Değişiklikler Uygula düğmesine bastığında kaydedilir."),19))
	var row=HBoxContainer.new();v.add_child(row);var tabs=VBoxContainer.new();tabs.custom_minimum_size.x=p.px(130);row.add_child(tabs);var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(body)
	for entry in [["game",say("Game","Oyun")],["sound",say("Sound","Ses")],["display",say("Display","Görünüm")],["controls",say("Controls","Kontroller")]]:
		var key=entry[0];p.playbook().button(tabs,entry[1],func():tab=key;open(),tab==key)
	if tab=="game":
		toggle(body,"haptics",say("Haptic feedback","Dokunsal geri bildirim"));toggle(body,"battery",say("Battery saver · 30 FPS cap","Pil tasarrufu · 30 FPS sınırı"));body.add_child(p.text(say("Travel and hero access have no city-level gate.","Seyahat ve kahraman erişiminde şehir seviyesi kilidi yok."),19))
	elif tab=="sound":toggle(body,"sound",say("Music and game sounds","Müzik ve oyun sesleri"))
	elif tab=="display":
		toggle(body,"contrast",say("High contrast","Yüksek kontrast"));toggle(body,"motion",say("Reduce motion","Hareketi azalt"));var text=CheckButton.new();text.text=say("Larger text · 115%","Büyük metin · %115");text.button_pressed=float(draft.text)>1.1;text.custom_minimum_size.y=p.px(44);body.add_child(text);text.toggled.connect(func(on):draft.text=1.15 if on else 1.0)
	else:
		body.add_child(p.text(say("Move · WASD / joystick\nAttack · Space / attack icon\nSkill · Q or 1 / ability icon\nTarget · Z\nDodge · Shift\nInspect · E\nBack / close · Escape","Yürü · WASD / çubuk\nSaldır · Boşluk / saldırı ikonu\nBeceri · Q veya 1 / beceri ikonu\nHedef · Z\nKaçın · Shift\nİncele · E\nGeri / kapat · Escape"),21))
	var actions=HBoxContainer.new();v.add_child(actions);p.playbook().button(actions,say("Reset draft","Taslağı sıfırla"),func():draft={"sound":true,"haptics":true,"battery":false,"contrast":false,"motion":false,"text":1.0};open())
	p.playbook().button(actions,say("APPLY","UYGULA"),func():game.audio.set_enabled(draft.sound);game.haptics=draft.haptics;game.view.set_quality(draft.battery);ui.high_contrast=draft.contrast;ui.reduce_motion=draft.motion;ui.accessibility_scale=draft.text;game.save_settings();ui.toast(say("Settings saved","Ayarlar kaydedildi"));open(),true).name="ApplyOptions"
func toggle(parent,key,title):
	var b=CheckButton.new();b.name="Option_"+key;b.text=title;b.button_pressed=draft[key];b.custom_minimum_size.y=p.px(48);b.add_theme_font_override("font",ui.ui_font());b.add_theme_font_size_override("font_size",int(p.px(16)));parent.add_child(b);b.toggled.connect(func(on):draft[key]=on)
