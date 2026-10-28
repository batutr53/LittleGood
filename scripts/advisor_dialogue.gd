extends RefCounted
const K=preload("res://scripts/kingdom.gd")
const J=preload("res://scripts/journey.gd")
var p
var game
var state="closed"
func _init(owner):p=owner;game=p.game
func label(parent,value,size=17):
	var l=Label.new();l.text=value;l.add_theme_font_override("font",p.ui.ui_font());l.add_theme_font_size_override("font_size",roundi(size*p.ui.accessibility_scale));l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func action(parent,title,callback):
	var b=p.ui.button(title,callback);b.custom_minimum_size.y=48;b.add_theme_font_size_override("font_size",roundi(16*p.ui.accessibility_scale));b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(b);return b
func open():
	if not game.world.has("kingdom") or game.visiting:return
	state="opening";var v=p.surface(p.say("Arin · Village Elder","Arin · Köy Bilgesi"));game.npc_dialogue_open=true;p.ui.modal.name="AdvisorDialogue";p.ui.modal.set_meta("npc_id","arin")
	var title=p.ui.modal.find_child("SurfaceBack",true,false)
	if title:
		title.custom_minimum_size=Vector2.ONE*48;title.add_theme_font_size_override("font_size",24)
		title.get_parent().get_child(0).add_theme_font_size_override("font_size",20)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);v.add_child(row)
	var portrait=TextureRect.new();portrait.texture=load("res://assets/kingdom/arin.png");portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(76,92);row.add_child(portrait)
	var advice=J.report(game.world);label(row,game.realm_ui.localized(advice.message),18)
	var q=K.current(game.world)
	if not q.is_empty():
		label(v,game.realm_ui.localized(q.title),19)
		if K.complete(game.world,q) and K.level(game.world)>=int(q.level):
			label(v,p.say("The work is done. Your actual chapter reward is ready.","İş tamam. Bölümünün gerçek ödülü hazır."))
			var claim=action(v,p.say("Receive chapter reward","Bölüm ödülünü al"),func():
				if K.claim(game.world,str(q.id)):game.realm_ui.changed();game.checkpoint("npc-quest-reward");open()
				else:p.ui.toast(p.say("The objective changed. Review it again.","Hedef değişti. Yeniden incele.")));claim.name="AdvisorClaimReward"
	var go=action(v,p.say("Show my next step","Sıradaki adımı göster"),func():state="choice";p.route(advice.route,int(advice.argument)));go.name="AdvisorNextStep"
	var options=HBoxContainer.new();options.add_theme_constant_override("separation",8);v.add_child(options)
	for entry in [[p.say("Workers","İşçiler"),"workers"],[p.say("Equipment","Donanım"),"inventory"],[p.say("Hunts","Av bölgeleri"),"hunts"]]:
		var route=entry[1];var b=action(options,entry[0],func():p.route(route));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label(v,p.say("Your workers continue while we talk.","Biz konuşurken işçilerin çalışmayı sürdürür.") if not game.paused else p.say("You paused the world. Close this conversation and resume when ready.","Dünyayı sen duraklattın. Hazır olduğunda konuşmayı kapatıp sürdür."),15)
	var close=action(v,p.say("Resume world & return","Dünyayı sürdür ve köye dön") if game.paused else p.say("Back to the village","Köye dön"),func():
		state="closing"
		if game.paused:game.paused=false;game.schedule_save()
		p.ui.close();state="closed");close.name="AdvisorClose"
	state="speaking"
