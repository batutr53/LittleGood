extends Node2D
# Visual events derive from authoritative before/after state, never award resources.
const A=preload("res://scripts/adventure.gd")
const H=preload("res://scripts/hero.gd")
const R=preload("res://scripts/rpg_progression.gd")
const I=preload("res://scripts/industry.gd")
var a
var hurt_flash=0.0
var banner=""
var banner_time=0.0
var banner_priority=0
var pending_banner=""
var impacts=[]
var events=[]
var selected_loot=0
var drop_ages={}
var overlay
func _ready():
	a=get_parent();overlay=preload("res://scripts/combat_feedback_overlay.gd").new();overlay.feedback=self;overlay.name="BattleFeedbackOverlay";a.hud.add_child(overlay)
func run_data():return a.game.world.kingdom.adventure.run
func snapshot() -> Dictionary:
	var w=a.game.world;var hero=w.kingdom.adventure.hero;var run=run_data()
	return {"hp":int(hero.hp),"mana":float(R.selected(w).mana) if w.has("rpg") else 0.0,"xp":int(hero.xp),"level":H.level(hero),"loot":run.loot.map(func(l):return int(l.id)),"taken":run.loot.filter(func(l):return l.taken).map(func(l):return int(l.id)),"living":run.enemies.filter(func(e):return e.hp>0).map(func(e):return int(e.id))}
func event(kind: String,amount: float=0):
	events.append({"kind":kind,"amount":amount})
	if events.size()>40:events.pop_front()
func popup(point: Vector2,text: String,color: Color,size=24):
	a.floats.append({"point":point,"text":text,"color":color,"size":size,"age":0.0})
	if a.floats.size()>40:a.floats.pop_front()
func announce(text: String,priority=0):
	if banner_time>0 and banner_priority>priority:pending_banner=text;return
	banner=text if text.length()<=44 else text.left(41)+"...";banner_time=1.5;banner_priority=priority
func resolve(before: Dictionary,cues: Array=[],command: Dictionary={}):
	var w=a.game.world;var hero=w.kingdom.adventure.hero;var run=run_data();var point=Vector2(run.x,run.y)
	for cue in cues:
		if not cue is Dictionary or not cue.has("damage"):continue
		var hit=Vector2(cue.x,cue.y);var critical=cue.get("critical",false);popup(hit+Vector2(60,-112),("CRIT " if critical else "")+str(int(cue.damage)),Color("fff19f") if critical else Color("fff2d0"),29 if critical else 24);impacts.append({"point":hit-Vector2(0,35),"age":0.0,"critical":critical});event("critical" if critical else "hit",cue.damage)
		if cue.has("enemy_id") and a.bodies.has(int(cue.enemy_id)):a.bodies[int(cue.enemy_id)].get_node("Art").self_modulate=Color(1.65,1.4,1.2)
	var hp=int(hero.hp)-int(before.hp)
	if hp<0:
		popup(point-Vector2(72,105),str(hp)+" HP",Color("ff796b"),28);hurt_flash=.3;event("hurt",-hp)
		if OS.has_feature("mobile") and a.game.haptics:Input.vibrate_handheld(25,.3)
	elif hp>0:popup(point-Vector2(72,78),"+"+str(hp)+" HP",Color("9cf1b5"));event("heal",hp)
	var mana=float(R.selected(w).mana) if w.has("rpg") else 0.0
	if mana<float(before.mana)-.5:popup(point-Vector2(100,50),"−"+str(roundi(float(before.mana)-mana))+" MP",Color("80c9ff"),20);event("mana_spent",float(before.mana)-mana)
	var xp=int(hero.xp)-int(before.xp)
	if xp>0:popup(point+Vector2(-100,-24),"+"+str(xp)+" EXP",Color("e2b4ff"),25);event("experience",xp)
	if H.level(hero)>int(before.level):announce(a.say("LEVEL UP · ","SEVİYE ATLADIN · ")+str(H.level(hero)),2);event("level_up",H.level(hero));a.game.audio.chime(6)
	for loot in run.loot:
		if not before.loot.has(int(loot.id)):event("drop",loot.amount);drop_ages[int(loot.id)]=0.0;impacts.append({"point":Vector2(loot.x,loot.y),"age":0.0,"critical":false})
		if loot.taken and not before.taken.has(int(loot.id)):
			var name=loot_name(loot);popup(Vector2(loot.x+55,loot.y-60),"+ "+name,Color("ffe4a4"),19);announce(a.say("Collected · ","Toplandı · ")+name);event("pickup",loot.amount);selected_loot=0
	if command.get("heal",false) and hp<=0 and not cues.has("heal"):
		announce(a.say("Health is already full","Canın zaten dolu") if hero.hp>=H.stats(w).health else a.say("Potion is cooling down","İksir bekleme süresinde") if hero.cooldowns.heal>0 else a.say("No potion or healing herb available","İksir veya iyileştirici bitki yok"))
	if impacts.size()>24:impacts=impacts.slice(-24)
func loot_name(loot: Dictionary) -> String:
	return a.game.realm_ui.localized(I.recipes()[loot.recipe].name) if not str(loot.recipe).is_empty() else a.game.realm_ui.cost({loot.resource:loot.amount})
func loot_point(loot: Dictionary) -> Vector2:
	var point=Vector2(loot.x,loot.y);var age=float(drop_ages.get(int(loot.id),1.0))
	if not a.game.ui.reduce_motion and age<1:point.y-=45*pow(1-age,2)-sin(age*PI*3)*5*(1-age)
	return point
func pick_at(screen: Vector2) -> bool:
	if a.frozen or a.rpg_overlay:return false
	var nearest=28.0;var found={}
	for loot in run_data().loot:
		if loot.taken:continue
		var distance=(a.get_canvas_transform()*loot_point(loot)).distance_to(screen)
		if distance<nearest:found=loot;nearest=distance
	if found.is_empty():selected_loot=0;return false
	selected_loot=int(found.id);a.targeting.clear()
	if Vector2(run_data().x,run_data().y).distance_to(Vector2(found.x,found.y))<=90:a.interact()
	else:announce(a.say("Approach to collect · ","Toplamak için yaklaş · ")+loot_name(found))
	return true
func _process(delta):
	if a==null:return
	var active=hurt_flash>0 or banner_time>0;hurt_flash=maxf(0,hurt_flash-delta);banner_time=maxf(0,banner_time-delta)
	if banner_time<=0 and not pending_banner.is_empty():
		var next=pending_banner;pending_banner="";banner_priority=0;announce(next)
	var had_impacts=not impacts.is_empty()
	var falling=false
	for id in drop_ages:
		if float(drop_ages[id])<1:falling=true;drop_ages[id]=minf(1,float(drop_ages[id])+delta)
	if falling:a.effects.queue_redraw()
	for impact in impacts:impact.age+=delta
	impacts=impacts.filter(func(impact):return impact.age<.3)
	for body in a.bodies.values():
		var art=body.get_node("Art");art.self_modulate=art.self_modulate.lerp(Color.WHITE,minf(1,delta*14))
	if active:overlay.queue_redraw()
	if had_impacts or not impacts.is_empty():queue_redraw()
func _draw():
	for impact in impacts:
		var alpha=1-impact.age/.3;var color=Color(1,.9,.55,alpha)
		draw_arc(impact.point,8+impact.age*50,0,TAU,18,color,2,true)
		for i in range(6):
			var direction=Vector2.from_angle(i*TAU/6);draw_line(impact.point+direction*(8+impact.age*30),impact.point+direction*(15+impact.age*65),color,2,true)
