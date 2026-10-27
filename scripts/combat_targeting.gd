extends Node2D
# Transient selection; never writes targets into a saved run.
const A=preload("res://scripts/adventure.gd")
const R=preload("res://scripts/rpg_progression.gd")
const T=preload("res://scripts/premium_theme.gd")
var a
var selected_id=0
var card: Panel
var title: Label
var detail: Label
var hp: ProgressBar
var warning: Label
var timer=0.0
func _ready():
	a=get_parent();var s=a.game.ui.premium.scale_ui();var extent=get_viewport_rect().size
	card=Panel.new();card.name="SelectedEnemy";card.add_theme_stylebox_override("panel",T.box(Color("171e27"),true));a.place(card,Rect2(extent.x*.5-155*s,8*s,310*s,67*s));card.hide()
	title=Label.new();title.name="TargetName";title.add_theme_font_override("font",a.game.ui.ui_font());title.add_theme_font_size_override("font_size",int(15*s));title.add_theme_color_override("font_color",Color("fff0cf"));title.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(title);title.position=Vector2(10,4)*s;title.size=Vector2(245,23)*s;title.clip_text=true
	detail=Label.new();detail.add_theme_font_override("font",a.game.ui.ui_font());detail.add_theme_font_size_override("font_size",int(12*s));detail.add_theme_color_override("font_color",Color("ddd7c4"));detail.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(detail);detail.position=Vector2(10,39)*s
	hp=ProgressBar.new();hp.name="TargetHealth";hp.show_percentage=false;hp.mouse_filter=Control.MOUSE_FILTER_IGNORE;hp.add_theme_stylebox_override("background",T.box(Color("090d14")));var fill=StyleBoxFlat.new();fill.bg_color=Color("c54b49");hp.add_theme_stylebox_override("fill",fill);card.add_child(hp);hp.position=Vector2(10,29)*s;hp.size=Vector2(242,8)*s
	var close=a.game.ui.button("×",clear);close.name="ClearTarget";a.game.ui.premium.rpg.compact_button(close);card.add_child(close);close.position=Vector2(260,9)*s;close.custom_minimum_size=Vector2.ONE*48*s;close.size=Vector2.ONE*48*s
	warning=a.game.ui.premium.text("",22,Color("ffe7a9"));warning.name="CombatWarning";warning.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;warning.add_theme_color_override("font_shadow_color",Color("10141b"));warning.add_theme_constant_override("shadow_outline_size",5);a.place(warning,Rect2(extent.x*.5-180*s,82*s,360*s,28*s))
func run_data() -> Dictionary:return a.game.world.kingdom.adventure.run
func target() -> Dictionary:
	for e in run_data().enemies:
		if int(e.id)==selected_id and e.hp>0:return e
	return {}
func clear():selected_id=0;refresh();queue_redraw()
func choose(id: int):
	if selected_id==id:return
	selected_id=id;refresh();queue_redraw();a.game.audio.button_sound()
	if OS.has_feature("mobile") and a.game.haptics:Input.vibrate_handheld(12,.2)
func select_at(screen: Vector2) -> bool:
	if a.frozen or a.rpg_overlay:return false
	var found=0;var nearest=INF
	for e in run_data().enemies:
		if e.hp<=0:continue
		var point=a.get_canvas_transform()*Vector2(e.x,e.y-35);var radius=65.0 if e.kind=="thornheart" else 42.0;var distance=point.distance_to(screen)
		if distance<radius*a.camera.zoom.x and distance<nearest:found=int(e.id);nearest=distance
	if found>0:choose(found);return true
	clear();return false
func cycle():
	if a.frozen or a.rpg_overlay:return
	var candidates=run_data().enemies.filter(func(e):return e.hp>0 and get_viewport_rect().grow(24).has_point(a.get_canvas_transform()*Vector2(e.x,e.y-25)))
	candidates.sort_custom(func(left,right):return int(left.id)<int(right.id))
	if candidates.is_empty():clear();a.message.text=a.say("No visible target. Explore the trail.","Görünen hedef yok. Patikada ilerle.");return
	var index=-1
	for i in range(candidates.size()):
		if int(candidates[i].id)==selected_id:index=i
	choose(int(candidates[(index+1)%candidates.size()].id))
func in_range() -> bool:
	var e=target();var run=run_data()
	return not e.is_empty() and Vector2(run.x,run.y).distance_to(Vector2(e.x,e.y))<=R.basic_range(a.game.world) and R.clear_shot(a.game.world,Vector2(run.x,run.y),Vector2(e.x,e.y))
func refresh():
	if not is_instance_valid(card):return
	var hero=a.game.world.kingdom.adventure.hero;var run=run_data()
	warning.text=a.say("LOW HEALTH · potion or retreat","CAN AZ · iksir veya geri çekil") if hero.hp<load("res://scripts/hero.gd").stats(a.game.world).health*.25 else ""
	var incoming=run.enemies.any(func(enemy):return enemy.hp>0 and enemy.state=="windup" and Vector2(enemy.x,enemy.y).distance_to(Vector2(run.x,run.y))<250)
	if incoming:warning.text=a.say("ATTACK INCOMING · DODGE","SALDIRI GELİYOR · KAÇIN")
	if hero.defeated:warning.text=a.say("DEFEATED · return home safely","YENİLDİN · güvenle eve dön")
	warning.visible=not a.rpg_overlay
	var e=target();card.visible=not e.is_empty() and not a.rpg_overlay
	if e.is_empty():selected_id=0;return
	var d=A.enemies()[e.kind];title.text="◆ "+a.game.realm_ui.localized(d.name);hp.max_value=d.health;hp.value=e.hp
	var state=a.say("IN RANGE","MENZİLDE") if in_range() else a.say("APPROACH · range / obstacle","YAKLAŞ · menzil / engel")
	if e.state=="windup":state=a.say("ATTACK · DODGE","SALDIRI · KAÇIN")
	detail.text=str(int(e.hp))+" / "+str(int(d.health))+"  ·  "+state
func _process(delta):
	timer+=delta
	if timer<.1:return
	timer=0;refresh();queue_redraw()
func _draw():
	if a==null or a.rpg_overlay:return
	var e=target()
	if e.is_empty():return
	var run=run_data();var point=Vector2(e.x,e.y);var hero=Vector2(run.x,run.y);var color=Color("ffcd79") if in_range() else Color("ff7f6b")
	draw_set_transform(point,0,Vector2(1,.45));draw_arc(Vector2.ZERO,38,0,TAU,48,Color("10151c"),7,true);draw_arc(Vector2.ZERO,38,0,TAU,48,color,3,true);draw_set_transform(Vector2.ZERO)
	for side in [-1,1]:draw_line(point+Vector2(side*46,-12),point+Vector2(side*35,-5),color,3,true)
	draw_colored_polygon(PackedVector2Array([point+Vector2(-8,-103),point+Vector2(8,-103),point+Vector2(0,-92)]),color)
	draw_dashed_line(hero,point,Color(color,.65),1.5,8)
	var radius=float(R.basic_range(a.game.world));draw_arc(hero,radius,-PI*.5,PI*1.5,72,Color(.9,.78,.47,.23),1.4,true)
