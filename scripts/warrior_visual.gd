extends Node2D
# Isolated V4B presentation. Never writes simulation, damage, rewards or saves.
const I=preload("res://scripts/industry.gd")
static var frames: SpriteFrames
static var poses: Dictionary={}
var sprite: AnimatedSprite2D
var state="idle"
var view_direction=0
var frame_index=0
var state_age=0
var last_clock=-1
var previous_position=Vector2.ZERO
var last_hp=-1
var last_swing=0
var last_dash=0
var gait_distance=0.0
var attack_heading=Vector2.DOWN
var sword_recipe=""
var shield_recipe=""
var debug_enabled=false
var damage_contacts: Array=[]
static func resources() -> SpriteFrames:
 if frames!=null:return frames
 poses=JSON.parse_string(FileAccess.get_file_as_string("res://assets/visual_v4/warrior-poses.json"))
 frames=SpriteFrames.new();frames.remove_animation("default")
 for key in poses.states:
  var texture=load("res://assets/visual_v4/warrior-"+key+".svg")
  for d in range(4):
   var animation=key+str(d);frames.add_animation(animation);frames.set_animation_loop(animation,false)
   for f in range(int(poses.states[key].frames)):
    var atlas=AtlasTexture.new();atlas.atlas=texture;atlas.region=Rect2(f*128,d*128,128,128);frames.add_frame(animation,atlas)
 return frames
func _ready() -> void:
 scale=Vector2.ONE*1.12
 sprite=AnimatedSprite2D.new();sprite.sprite_frames=resources();sprite.position=Vector2(0,-48);add_child(sprite)
func cardinal(heading: Vector2) -> int:
 if absf(heading.x)>absf(heading.y):return 1 if heading.x>0 else 3
 return 0 if heading.y>=0 else 2
func equip_from(w: Dictionary) -> void:
 var h=w.kingdom.adventure.hero
 var sword=I.item(w,int(h.equipment.weapon));var shield=I.item(w,int(h.equipment.shield))
 sword_recipe=sword.get("recipe","");shield_recipe=shield.get("recipe","")
func sample(w: Dictionary,feedback: Array=[]) -> void:
 var r=w.kingdom.adventure.run;var h=w.kingdom.adventure.hero;var now=int(r.clock);var p=Vector2(r.x,r.y)
 if now==last_clock:return
 var dt=0 if last_clock<0 else maxi(0,now-last_clock);var moved=0.0 if last_clock<0 else p.distance_to(previous_position)
 var heading=Vector2(r.facing[0],r.facing[1]).normalized();var desired="idle"
 if last_clock<0:equip_from(w)
 # Highest priority wins. Reaction does not modify gameplay invulnerability.
 if h.defeated:desired="defeat"
 elif int(r.dash)>0:desired="dodge"
 elif (last_hp>=0 and h.hp<last_hp) or (state=="hit" and state_age<150):desired="hit"
 elif int(r.swing)>0:desired="attack"
 elif moved>.25 and dt>0:desired="walk"
 if int(r.swing)>last_swing:attack_heading=heading
 if desired!=state:state=desired;state_age=0
 else:state_age+=dt
 if state=="walk":gait_distance+=moved
 if state=="attack":view_direction=cardinal(attack_heading)
 elif state not in ["hit","defeat"]:view_direction=cardinal(heading)
 var count=int(poses.states[state].frames)
 match state:
  "idle":frame_index=int(now/180)%count
  "walk":frame_index=int(gait_distance/9.0)%count
  "attack":frame_index=[2,3,4,4][clampi(int((200-int(r.swing))/50),0,3)] # E3 damage is immediate; no fake anticipation after contact.
  "dodge":frame_index=clampi(int((250-int(r.dash))/50),0,count-1)
  "hit":frame_index=mini(count-1,int(state_age/50))
  "defeat":frame_index=mini(count-1,int(state_age/100))
 sprite.animation=state+str(view_direction);sprite.set_frame_and_progress(frame_index,0)
 sprite.modulate=Color(1,.72,.62) if state=="hit" else Color(.8,.95,1,.72) if state=="dodge" else Color.WHITE
 for cue in feedback:
  if cue is Dictionary:damage_contacts.append({"point":Vector2(cue.x,cue.y),"until":now+200,"damage":cue.damage})
 damage_contacts=damage_contacts.filter(func(c):return c.until>now)
 previous_position=p;last_clock=now;last_hp=int(h.hp);last_swing=int(r.swing);last_dash=int(r.dash);queue_redraw()
func socket(name: String) -> Vector2:
 var row=poses.states[state].sockets[view_direction][frame_index][name]
 return Vector2(float(row[0])-64,float(row[1])-112)
func _draw() -> void:
 if sprite==null:return
 draw_ellipse_shadow()
 var sword=socket("sword");var shield=socket("shield")
 var row=poses.states[state].sockets[view_direction][frame_index]
 if not sword_recipe.is_empty():
  var angle=deg_to_rad(float(row.angle));var axis=Vector2.from_angle(angle);var normal=axis.orthogonal();var tip=sword+axis*31
  var tint=Color("a5c691") if sword_recipe=="thornblade" else Color("f4d684") if sword_recipe.begins_with("sun") else Color("d9e5de")
  draw_line(sword-axis*7,sword,Color("4c352a"),4,true);draw_line(sword-normal*6,sword+normal*6,Color("d4b478"),3,true)
  draw_colored_polygon(PackedVector2Array([sword+axis*3-normal*3,tip,sword+axis*3+normal*3]),tint)
  draw_line(sword+axis*4,tip,Color("fff0be"),1,true)
 if not shield_recipe.is_empty():
  var points=PackedVector2Array([shield+Vector2(-11,-14),shield+Vector2(10,-14),shield+Vector2(9,5),shield+Vector2(0,15),shield+Vector2(-10,5)])
  draw_colored_polygon(points,Color("bba56b"));draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[4],points[0]]),Color("173d47"),2,true)
  draw_line(shield-Vector2(0,9),shield+Vector2(0,8),Color("e5d9a5"),2,true)
 if debug_enabled and OS.is_debug_build():
  draw_circle(Vector2.ZERO,14/scale.x,Color(.4,1,.7,.15));draw_arc(Vector2.ZERO,14/scale.x,0,TAU,24,Color("8cf5bb"),1,true)
  draw_circle(sword,3,Color.MAGENTA)
  draw_line(sword,sword+Vector2.from_angle(deg_to_rad(float(row.angle)))*31,Color.MAGENTA,2,true)
  for c in damage_contacts:
   var contact=(c.point-previous_position)/scale.x
   draw_circle(contact,5,Color("fff0ba"));draw_line(contact-Vector2(8,0),contact+Vector2(8,0),Color.RED,2,true)
func draw_ellipse_shadow() -> void:
 var poly=PackedVector2Array()
 for i in range(24):poly.append(Vector2(cos(i*TAU/24)*18,sin(i*TAU/24)*5))
 draw_colored_polygon(poly,Color(.025,.075,.08,.3))
