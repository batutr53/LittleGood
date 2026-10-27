extends Node2D
var spells: Array=[]
var reduce_motion=false
var low_quality=false
var weapon_trails: Array=[]
var aura_position=Vector2.ZERO
var aura_direction=Vector2.UP
var aura={"strength":0.0,"color":Color.WHITE}
func weapon_swing(point: Vector2,facing: Vector2,profile: Dictionary):
	# Presentation is emitted only after the simulation accepts a swing.
	weapon_trails.append({"point":point+Vector2(0,-28),"facing":facing.normalized(),"age":0.0,"profile":profile.duplicate()})
	while weapon_trails.size()>(2 if low_quality else 6):weapon_trails.pop_front()
func cast(point: Vector2,cls: String,index: int,facing: Vector2):
	spells.append({"point":point,"class":cls,"index":index,"facing":facing.normalized(),"age":0.0})
	if spells.size()>8:spells.pop_front()
func _process(delta):
	for spell in spells:spell.age+=delta
	spells=spells.filter(func(s):return s.age<.85)
	for trail in weapon_trails:trail.age+=delta
	var had_trails=not weapon_trails.is_empty()
	weapon_trails=weapon_trails.filter(func(s):return s.age<.32)
	if not spells.is_empty() or aura.strength>0 or had_trails or _was_drawing:queue_redraw()
	_was_drawing=not spells.is_empty() or aura.strength>0 or not weapon_trails.is_empty()
var _was_drawing=false
func draw_weapon_trail(s: Dictionary):
	var t=clampf(s.age/.32,0,1);var profile=s.profile;var color=Color(profile.color,(1-t)*(.55 if reduce_motion else .8))
	var angle=s.facing.angle();var reach=40.0+float(profile.get("level",0))*2
	var sweep=.55 if reduce_motion else 1.3
	var head=angle-sweep+t*sweep*2
	var tail=maxf(angle-sweep,head-.85*(1-t))
	draw_arc(s.point,reach,tail,head,10 if low_quality else 20,Color(color,.12*(1-t)),12,true)
	draw_arc(s.point,reach,tail,head,10 if low_quality else 20,color,3,true)
	var tip=s.point+Vector2.from_angle(head)*reach
	match profile.get("element","none"):
		"fire":
			if not reduce_motion:
				for i in range(2 if low_quality else 4):
					var a=head-i*.16;var p=s.point+Vector2.from_angle(a)*(reach+i*2)
					draw_line(p,p+Vector2(2,-8-i*2)*(1-t),color,2,true)
		"frost":
			draw_line(tip-Vector2(4,0),tip+Vector2(4,0),color,2,true);draw_line(tip-Vector2(0,4),tip+Vector2(0,4),color,2,true)
		"lightning":
			var bolt=PackedVector2Array([s.point+s.facing*20,tip+s.facing.orthogonal()*5,tip-s.facing*8,tip+s.facing*6])
			draw_polyline(bolt,color,2,true)
		"poison":
			draw_circle(tip,3*(1-t)+1,color);draw_circle(tip+Vector2(-5,7)*(1-t),2,color)
func _draw():
	if aura.strength>0:
		var at=aura_position+aura_direction*21+Vector2(0,-28);var color=Color(aura.color,aura.strength*(.5 if reduce_motion else .45+.15*sin(Time.get_ticks_msec()*.003)))
		draw_line(at-aura_direction*8,at+aura_direction*20,Color(color,.15),12,true);draw_line(at-aura_direction*8,at+aura_direction*20,color,3,true)
	for trail in weapon_trails:draw_weapon_trail(trail)
	for s in spells:
		var t=s.age/.85;var alpha=(1-t)*.8;var point=s.point;var radius=30+(15+s.index*7)*sin(t*PI*.5)
		var color={"warrior":Color("ffca6a"),"priest":Color("fff3bf"),"mage":Color("83dfff"),"rogue":Color("98f6b0")}[s.class]
		if s.class=="mage":color=[Color("ff995b"),Color("8cdaff"),Color("d4acff"),Color("ff745d"),Color("85b5fc"),Color("b2a8ff")][s.index]
		color.a=alpha
		if s.class=="warrior":
			var angle=s.facing.angle();draw_arc(point,radius,angle-1.2,angle+1.2,24,color,5*(1-t)+1,true)
			if s.index in [1,3,5]:draw_arc(point,radius*.7,0,TAU,32,color,2,true)
		elif s.class=="priest":
			draw_arc(point,radius,0,TAU,40,color,2,true);draw_line(point-Vector2(0,32),point+Vector2(0,20),color,4,true);draw_line(point-Vector2(19,8),point+Vector2(19,-8),color,4,true)
		elif s.class=="mage":
			draw_arc(point,radius,0,TAU,40,color,3,true)
			for i in range(6+s.index):
				var angle=i*TAU/(6+s.index)+(0 if reduce_motion else t*.8);var at=point+Vector2.from_angle(angle)*radius
				draw_line(at,at+Vector2.from_angle(angle)*12,color,2,true)
		else:
			var direction=s.facing;var normal=direction.orthogonal()
			for i in range(3):
				var at=point+normal*(i-1)*13+direction*(t*90)
				draw_line(at-direction*28,at+direction*18,color,2,true)
		if not reduce_motion:
			for i in range(5):draw_circle(point+Vector2.from_angle(i*TAU/5+s.index)*radius*(.5+t),maxf(.5,2*(1-t)),color)
