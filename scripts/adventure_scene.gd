extends Node2D
const A=preload("res://scripts/adventure.gd")
const H=preload("res://scripts/hero.gd")
const MAP=preload("res://scripts/wildwood_map.gd")
var region="wildwood"
var region_map=MAP
var regional_textures: Dictionary={}
var game
var bodies: Dictionary={}
var actors: Node2D
var camera: Camera2D
var hud: Control
var health: Label
var objective: Label
var message: Label
var stick
var stick_index=-1
var movement=Vector2.ZERO
var actions: Dictionary={}
var buttons: Dictionary={}
var accumulator=0.0
var save_clock=0.0
var hud_clock=0.0
var frozen=false
var controlled=false
var physics_steps=0
var combat_cpu_us=0
var startup_ms=0.0
var effects
var props
var floats: Array=[]
var effect_textures: Dictionary={}
var attack_held=false
var mouse_aim=Vector2.ZERO
var button_titles: Dictionary={}
var action_counts: Dictionary={}
var death_ages: Dictionary={}
var effects_were_dynamic=true
func say(en: String,tr: String) -> String:return tr if game.ui.language=="tr" else en
func _ready() -> void:
	var started=Time.get_ticks_usec();game.show_world(false);game.ui.root.hide()
	region=preload("res://scripts/regions.gd").current(game.world);region_map=preload("res://scripts/regions.gd").map(region)
	for key in ["chest","herb"]:effect_textures[key]=load("res://assets/adventure/"+key+".svg")
	var ground=preload("res://scripts/iron_hills_ground.gd").new() if region=="iron_hills" else preload("res://scripts/wildwood_ground.gd").new();add_child(ground)
	actors=Node2D.new();actors.y_sort_enabled=true;add_child(actors)
	for p in region_map.trees():
		var tree=Sprite2D.new() if region=="iron_hills" else GameArt.sprite(7 if int(p.x)%2==0 else 12,100);tree.position=p
		if region=="iron_hills":tree.texture=load("res://assets/adventure/mountain-pine.svg");tree.scale=Vector2.ONE*.7;tree.position.y-=55
		elif not game.view.low_quality:tree.material=GameArt.foliage()
		actors.add_child(tree)
	for rect in region_map.solids(game.world.kingdom.claimed.size()<14):
		var wall=StaticBody2D.new();wall.position=rect.get_center();var shape=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=rect.size;shape.shape=box;wall.add_child(shape);add_child(wall)
		if region=="iron_hills" and rect.size.x>60 and rect.size.y>60:
			# Art follows the physical obstacle footprint, rather than blocking invisible ground.
			var art=Sprite2D.new();art.texture=load("res://assets/adventure/mountain-rock.svg");art.position=rect.get_center();art.scale=rect.size/Vector2(180,160);art.position.y-=rect.size.y*.15;actors.add_child(art)
	if region=="iron_hills":
		for key in ["ore-vein","mountain-rock","forgotten-mine","mine-cart"]:regional_textures[key]=load("res://assets/adventure/"+key+".svg")
		regional_prop("forgotten-mine",Vector2(480,310),250,.5)
		regional_prop("mine-cart",Vector2(560,370),100,.5)
		for key in region_map.NODES:regional_prop("ore-vein" if key=="ore" else "mountain-rock",region_map.NODES[key].point,110,.42,.4 if game.world.kingdom.adventure.run.nodes[key] else 1.0)
	make_body(0,Vector2(game.world.kingdom.adventure.run.x,game.world.kingdom.adventure.run.y),load("res://assets/adventure/warrior.png"),110)
	for e in game.world.kingdom.adventure.run.enemies:make_body(int(e.id),Vector2(e.x,e.y),load("res://assets/adventure/"+e.kind+".svg"),180 if e.kind=="thornheart" else 100)
	props=preload("res://scripts/adventure_props.gd").new();add_child(props)
	effects=preload("res://scripts/adventure_effects.gd").new();add_child(effects)
	camera=Camera2D.new();camera.zoom=Vector2.ONE*1.15;camera.position=camera_target();camera.position_smoothing_enabled=false;add_child(camera);camera.make_current()
	build_hud();startup_ms=(Time.get_ticks_usec()-started)/1000.0
func regional_prop(key: String,point: Vector2,size: float,anchor: float,alpha: float=1.0) -> void:
	var base=Node2D.new();base.position=point;actors.add_child(base)
	var sprite=Sprite2D.new();sprite.texture=regional_textures[key];sprite.position.y=-size*anchor;sprite.scale=Vector2.ONE*size/sprite.texture.get_width();sprite.modulate.a=alpha;base.add_child(sprite)
	if key in ["ore-vein","mountain-rock"]:base.name="deposit_ore" if key=="ore-vein" else "deposit_stone"
func camera_target() -> Vector2:
	var half=get_viewport_rect().size/(camera.zoom*2);var p=bodies[0].position
	return Vector2(clampf(p.x,half.x,region_map.SIZE.x-half.x),clampf(p.y+100/camera.zoom.y,half.y-165/camera.zoom.y,region_map.SIZE.y-half.y+350/camera.zoom.y))
func make_body(id: int,p: Vector2,texture: Texture2D,size: float) -> void:
	var body=CharacterBody2D.new();body.position=p;body.collision_layer=2;body.collision_mask=1;actors.add_child(body)
	var collision=CollisionShape2D.new();var circle=CircleShape2D.new();circle.radius=14;collision.shape=circle;body.add_child(collision)
	var sprite=Sprite2D.new();sprite.name="Art";sprite.texture=texture;sprite.scale=Vector2.ONE*size/texture.get_width();sprite.position.y=-size*.42;body.add_child(sprite);bodies[id]=body
func move_body(id: int,p: Vector2,delta: Vector2) -> Vector2:
	if not bodies.has(id):return region_map.move(p,delta,game.world.kingdom.claimed.size()<14)
	var body=bodies[id];body.position=p;body.move_and_collide(delta);return body.position.round()
func place(node: Control,rect: Rect2) -> void:
	hud.add_child(node);node.position=rect.position;node.size=rect.size
func add_button(id: String,text: String,rect: Rect2,cb: Callable) -> void:
	var b=game.ui.button(text,cb,true);b.add_theme_font_size_override("font_size",18);place(b,rect);buttons[id]=b;button_titles[id]=text
func build_hud() -> void:
	var layer=CanvasLayer.new();layer.layer=12;add_child(layer);hud=Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(hud)
	var height=get_viewport_rect().size.y
	var bg=ColorRect.new();bg.color=Color(.035,.09,.12,.92);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;place(bg,Rect2(0,0,720,190))
	health=game.ui.label("",24,Color("d7e5ba"));place(health,Rect2(25,30,550,35))
	objective=game.ui.label("",19);place(objective,Rect2(25,75,650,77))
	var message_bg=ColorRect.new();message_bg.color=Color(.035,.09,.12,.86);message_bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;place(message_bg,Rect2(20,height-386,680,70))
	message=game.ui.label(say("Move: stick / WASD · Attack: Space · Strike: Q\nDodge: Shift · Inspect: E · Heal: F", "Yürü: çubuk / WASD · Saldır: Boşluk · Darbe: Q\nKaçın: Shift · İncele: E · İyileş: F"),18,Color("f0e4bc"));place(message,Rect2(30,height-380,660,65))
	add_button("return",say("Home","Dön"),Rect2(582,15,116,78),go_home)
	add_button("interact",say("Inspect","İncele"),Rect2(588,height-192,110,85),interact)
	buttons.interact.position=Vector2(582,height-300);buttons.interact.size=Vector2(115,76)
	for row in [["attack",say("Attack","Saldır"),Vector2(460,height-178)],["skill",say("Strike","Darbe"),Vector2(582,height-178)],["dodge",say("Dodge","Kaçın"),Vector2(338,height-178)],["heal",say("Heal","İyileş"),Vector2(460,height-300)]]:
		var key=row[0];add_button(key,row[1],Rect2(row[2],Vector2(112,76)),func():actions[key]=true)
		if key=="attack":
			buttons[key].button_down.connect(func():attack_held=true;actions.attack=true)
			buttons[key].button_up.connect(func():attack_held=false)
	add_button("pause",say("Pause","Dur"),Rect2(582,103,116,78),toggle_pause)
	stick=preload("res://scripts/adventure_stick.gd").new();stick.position=Vector2(125,height-145);layer.add_child(stick)
	refresh_hud()
func refresh_hud() -> void:
	var h=game.world.kingdom.adventure.hero;var r=game.world.kingdom.adventure.run
	health.text=h.name+" · "+str(int(h.hp))+" / "+str(H.stats(game.world).health)+say(" HP"," Can")
	for key in ["attack","skill","dodge","heal"]:
		var cd=int(h.cooldowns[key]);buttons[key].text=button_titles[key]+("\n"+str(snappedf(cd/1000.0,.1))+"s" if cd>0 else "")
	var q=preload("res://scripts/kingdom.gd").current(game.world)
	objective.text=say("IRON HILLS · Find the mine to the north.\nInspect ore veins; take materials home.","DEMİR TEPELER · Kuzeydeki madeni bul.\nCevheri incele; malzemeyi eve taşı.") if region=="iron_hills" else say("WILDWOOD · ","YABANORMAN · ")+(game.realm_ui.localized(q.title) if not q.is_empty() else say("Explore and return safely","Keşfet ve güvenle dön"))
	if region=="iron_hills" and r.landmark:objective.text=say("IRON HILLS · Forgotten Mine discovered\nOre and stone are finite · Home banks cargo.","DEMİR TEPELER · Unutulmuş Maden keşfedildi\nCevher ve taş sınırlı · Dön ganimeti depolar.")
	for e in r.enemies:
		if e.kind=="thornheart" and e.hp>0 and Vector2(r.x,r.y).distance_to(Vector2(e.x,e.y))<320:objective.text+="\nThornheart · "+str(int(e.hp))+" / 220 · "+say("Phase ","Evre ")+("II" if e.hp<=110 else "I")
	if h.defeated:message.text=say("Your champion fell. Home restores health and keeps your collected loot.","Şampiyonun düştü. Dön canı yeniler; toplanmış ganimetin korunur.")
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		action_counts.touch=int(action_counts.get("touch",0))+1
		if event.pressed and event.position.distance_to(stick.position)<115 and stick_index<0:stick_index=event.index
		elif not event.pressed and event.index==stick_index:stick_index=-1;movement=Vector2.ZERO
	if event is InputEventScreenDrag and event.index==stick_index:
		movement=((event.position-stick.position)/65).limit_length(1);action_counts.drag=int(action_counts.get("drag",0))+1
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_E:interact()
		if event.keycode==KEY_SPACE:actions.attack=true
		if event.keycode==KEY_Q:actions.skill=true
		if event.keycode==KEY_SHIFT:actions.dodge=true
		if event.keycode==KEY_F:actions.heal=true
		if event.keycode==KEY_ESCAPE:toggle_pause()
func toggle_pause() -> void:
	frozen=not frozen;attack_held=false;actions.clear();movement=Vector2.ZERO
	buttons.pause.text=say("Resume","Sürdür") if frozen else button_titles.pause
	message.text=say("Paused · Resume to continue; Home keeps collected loot.","Duraklatıldı · Sürdür ile devam et; Dön ganimeti korur.") if frozen else say("Watch the warning, then dodge. Attack during recovery.","Uyarıyı izle, sonra kaçın. Dinlenme aralığında saldır.")
func _unhandled_input(event: InputEvent) -> void:
	if not OS.has_feature("mobile") and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		mouse_aim=get_global_mouse_position()-bodies[0].position;actions.attack=true
func _physics_process(delta: float) -> void:
	if frozen or game.suspended:return
	var direction=movement
	if not controlled:
		direction+=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	stick.vector=direction.limit_length(1);stick.queue_redraw();accumulator+=minf(delta,.2)
	while accumulator>=.05:
		accumulator-=.05;var started=Time.get_ticks_usec();var command=actions.duplicate();command.move=direction
		if attack_held or (not controlled and Input.is_physical_key_pressed(KEY_SPACE)):command.attack=true
		if mouse_aim.length()>.1:command.aim=mouse_aim;mouse_aim=Vector2.ZERO
		for key in ["attack","skill","dodge","heal"]:
			if command.get(key,false):action_counts[key]=int(action_counts.get(key,0))+1
		var feedback=A.step(game.world,command,move_body);actions.clear();combat_cpu_us+=Time.get_ticks_usec()-started;physics_steps+=1
		for cue in feedback:
			if cue is Dictionary:floats.append({"point":Vector2(cue.x,cue.y),"text":str(cue.damage),"age":0.0})
			elif cue in ["swing","kill","boss","heal"]:game.audio.chime(6 if cue in ["kill","boss"] else 0 if cue=="swing" else 5)
			elif cue=="hurt":game.audio.chime(2)
			if cue is String and cue=="boss":message.text=say("Thornheart falls! Inspect the living heart, then return to Arin.","Dikenyürek düştü! Yaşayan kalbi İncele ile al; Arin'e dön.")
	var r=game.world.kingdom.adventure.run;bodies[0].position=Vector2(r.x,r.y)
	bodies[0].get_node("Art").rotation=sin(r.clock*.012)*.025*direction.length()
	bodies[0].get_node("Art").position.y=-46.2-absf(sin(r.clock*.015))*3*direction.length()
	if r.swing>0:bodies[0].get_node("Art").rotation+=sin(r.swing/200.0*PI)*.2
	for e in r.enemies:
		var body=bodies[int(e.id)];body.position=Vector2(e.x,e.y);var sprite=body.get_node("Art");sprite.rotation=sin(r.clock*.012+int(e.id))*(.12 if e.state=="windup" else .035);sprite.modulate.a=.22 if e.hp==0 else 1.0
		if e.kind=="thornheart" and e.hp>0 and bodies[0].position.y<e.y and bodies[0].position.distance_to(body.position)<110:sprite.modulate.a=.48
		if e.hp==0:
			death_ages[e.id]=minf(1.0,float(death_ages.get(e.id,0))+delta);sprite.modulate.a=lerpf(1,.16,death_ages[e.id]);sprite.rotation=death_ages[e.id]*.22
	bodies[0].get_node("Art").modulate=Color(1,.7,.6) if r.invulnerable>0 and r.dash==0 else Color(1,1,1,.6) if r.dash>0 else Color.WHITE
	for f in floats:f.age+=delta;f.point.y-=delta*30
	floats=floats.filter(func(f):return f.age<.8)
	camera.position=camera.position.lerp(camera_target(),1-exp(-delta*7))
	hud_clock+=delta;save_clock+=delta
	if hud_clock>.2:hud_clock=0;refresh_hud()
	if save_clock>5:save_clock=0;game.checkpoint("adventure")
	var visible_world=Rect2(camera.position-get_viewport_rect().size/camera.zoom/2,get_viewport_rect().size/camera.zoom).grow(180)
	var dynamic=r.enemies.any(func(e):return e.hp>0 and visible_world.has_point(Vector2(e.x,e.y))) or r.swing>0 or r.dash>0 or not floats.is_empty() or death_ages.values().any(func(age):return age<1)
	if dynamic or effects_were_dynamic:effects.queue_redraw()
	effects_were_dynamic=dynamic
func draw_effects(canvas: Node2D) -> void:
	if not game:return
	var r=game.world.kingdom.adventure.run
	for e in r.enemies:
		if e.hp<=0:continue
		var p=Vector2(e.x,e.y);var data=A.enemies()[e.kind]
		canvas.draw_rect(Rect2(p-Vector2(30,95),Vector2(60,6)),Color("203e3e"));canvas.draw_rect(Rect2(p-Vector2(30,95),Vector2(60*e.hp/float(data.health),6)),Color("d3d09c"))
		if e.state=="windup":
			if e.kind=="thornheart" and e.pattern==0:
				var angle=(Vector2(e.aimx,e.aimy)-p).angle();var points=PackedVector2Array([p])
				for i in range(25):points.append(p+Vector2.from_angle(angle-1.21+i*2.42/24)*140)
				canvas.draw_colored_polygon(points,Color(.95,.38,.24,.3));canvas.draw_arc(p,140,angle-1.21,angle+1.21,32,Color("f3bb7b"),3,true);continue
			var root=e.kind=="thornheart" and e.pattern==1
			var warning=Vector2(e.aimx,e.aimy) if e.kind in ["spider","cave_stalker"] or root else p;var radius=55 if e.kind=="cave_stalker" else 60 if e.kind=="spider" else 85 if root else 145 if e.kind=="thornheart" else int(data.range)+12
			canvas.draw_circle(warning,radius,Color(.95,.38,.24,.25));canvas.draw_arc(warning,radius,0,TAU,40,Color("f3bb7b"),3,true)
	if r.swing>0:
		var p=Vector2(r.x,r.y);var angle=Vector2(r.facing[0],r.facing[1]).angle();canvas.draw_arc(p,65,angle-.9,angle+.9,20,Color("f8e3a7"),9,true)
	if r.dash>0:
		var heading=Vector2(r.facing[0],r.facing[1]).normalized()
		for i in range(1,4):canvas.draw_circle(Vector2(r.x,r.y)-heading*i*16,15-i*3,Color(.75,.9,.8,.5-i*.1))
	for l in r.loot:
		if not l.taken:
			var p=Vector2(l.x,l.y);var color=Color("f3cf7f") if l.resource=="heart" else Color("9ed9d5") if not l.recipe.is_empty() else Color("c5d39c");canvas.draw_circle(p,11,color);canvas.draw_arc(p,18,0,TAU,24,color,2,true)
			if l.resource=="heart":
				for i in range(6):canvas.draw_line(p+Vector2.from_angle(i*TAU/6)*23,p+Vector2.from_angle(i*TAU/6)*30,color,3,true)
	for f in floats:canvas.draw_string(ThemeDB.fallback_font,f.point,f.text,HORIZONTAL_ALIGNMENT_CENTER,-1,24,Color("ffe4a7"))
func draw_props(canvas: Node2D) -> void:
	var r=game.world.kingdom.adventure.run
	if region=="iron_hills":
		for id in region_map.NODES:
			var node=region_map.NODES[id];var p=node.point
			actors.get_node("deposit_"+id).get_child(0).modulate.a=.4 if r.nodes[id] else 1.0
			if not r.nodes[id]:canvas.draw_arc(p,48,0,TAU,32,Color("edc886"),2,true)
			canvas.draw_string(game.ui.ui_font(),p+Vector2(-72,45),say("Ore · Inspect","Cevher · İncele") if id=="ore" else say("Stone · Inspect","Taş · İncele"),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("f0d6a3"))
		canvas.draw_arc(region_map.LANDMARK,70,0,TAU,32,Color("b4dbc6") if r.landmark else Color("f0c987"),3,true)
		canvas.draw_string(game.ui.ui_font(),region_map.LANDMARK+Vector2(-120,85),say("The Forgotten Mine","Unutulmuş Maden"),HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("f0d6a3"))
		return
	if game.world.kingdom.claimed.size()<14:
		canvas.draw_line(Vector2(560,362),Vector2(942,362),Color("aec18a"),14,true);canvas.draw_string(game.ui.ui_font(),Vector2(580,345),say("Roots sealed · quest 14","Kökler mühürlü · görev 14"),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f2dfab"))
	for p in [MAP.CHEST,MAP.HERBS]:
		var image=effect_textures["chest" if p==MAP.CHEST else "herb"];canvas.draw_texture_rect(image,Rect2(p-Vector2(38,55),Vector2(76,76)),false,Color(1,1,1,.4 if (r.chest if p==MAP.CHEST else r.harvest) else 1))
func ruin_style() -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color("9cbbaa");style.border_color=Color("d8d8ae");style.set_border_width_all(4);style.set_corner_radius_all(9);return style
func interact() -> void:
	action_counts.interact=int(action_counts.get("interact",0))+1
	var before=game.world.kingdom.adventure.run.loot.filter(func(l):return l.taken).map(func(l):return l.id)
	var result=A.interact(game.world)
	props.queue_redraw();effects.queue_redraw()
	if result=="landmark":message.text=say("The Sunstone remembers your kingdom. Arin will want to hear this.","Güneştaşı krallığını hatırlıyor. Arin bunu duymak isteyecek.");game.audio.chime(6);game.checkpoint("landmark")
	elif result=="mine":message.text=say("Forgotten Mine discovered. Its last miners left rails pointing home. Recorded in the chronicle.","Unutulmuş Maden keşfedildi. Son madenciler eve uzanan raylar bıraktı. Tarihçeye kaydedildi.");game.audio.chime(6);game.checkpoint("forgotten-mine")
	elif result=="mineral":message.text=say("Mineral gathered · finite vein. Return home to smelt ore or build with stone.","Maden toplandı · damar sınırlı. Cevheri eritmek veya taşla inşa etmek için eve dön.");game.audio.chime(5);game.checkpoint("mineral")
	elif result=="full":message.text=say("Storage is full. Loot stays here; return home to use materials or equipment.","Depo dolu. Ganimet burada kalır; malzeme veya donanımı kullanmak için eve dön.")
	elif not result.is_empty():message.text=say("Collected · loot stays yours when you return. Herbs can heal (F).","Toplandı · döndüğünde ganimet senin. Bitkiler iyileştirir (F).");game.audio.chime(5);game.checkpoint("loot")
	if result=="loot":
		for l in game.world.kingdom.adventure.run.loot:
			if l.taken and not before.has(l.id):message.text="+ "+(game.realm_ui.cost({l.resource:l.amount}) if l.recipe.is_empty() else game.realm_ui.localized(preload("res://scripts/industry.gd").recipes()[l.recipe].name))+say(" · Safe when you return home."," · Eve döndüğünde depolanır.")
	refresh_hud()
func go_home() -> void:
	var paused=game.world.kingdom.adventure.run.home_paused
	if not A.exit(game.world):return
	game.adventure_scene=null;game.paused=paused;game.show_world(true);game.ui.root.show();game.ui.close();game.ui.refresh();game.checkpoint("return-home");queue_free()
