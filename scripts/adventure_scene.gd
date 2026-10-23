extends Node2D
const A=preload("res://scripts/adventure.gd")
const H=preload("res://scripts/hero.gd")
const MAP=preload("res://scripts/wildwood_map.gd")
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
func say(en: String,tr: String) -> String:return tr if game.ui.language=="tr" else en
func _ready() -> void:
	var started=Time.get_ticks_usec();game.show_world(false);game.ui.root.hide()
	var ground=preload("res://scripts/wildwood_ground.gd").new();add_child(ground)
	actors=Node2D.new();actors.y_sort_enabled=true;add_child(actors)
	for p in MAP.trees():
		var tree=GameArt.sprite(7 if int(p.x)%2==0 else 12,100);tree.position=p
		if not game.view.low_quality:tree.material=GameArt.foliage()
		actors.add_child(tree)
	for rect in MAP.solids(game.world.kingdom.claimed.size()<14):
		var wall=StaticBody2D.new();wall.position=rect.get_center();var shape=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=rect.size;shape.shape=box;wall.add_child(shape);add_child(wall)
	make_body(0,Vector2(game.world.kingdom.adventure.run.x,game.world.kingdom.adventure.run.y),load("res://assets/adventure/warrior.png"),110)
	camera=Camera2D.new();camera.zoom=Vector2.ONE*.9;camera.position=bodies[0].position;camera.position_smoothing_enabled=false;add_child(camera);camera.make_current()
	build_hud();startup_ms=(Time.get_ticks_usec()-started)/1000.0
func make_body(id: int,p: Vector2,texture: Texture2D,size: float) -> void:
	var body=CharacterBody2D.new();body.position=p;body.collision_layer=2;body.collision_mask=1;actors.add_child(body)
	var collision=CollisionShape2D.new();var circle=CircleShape2D.new();circle.radius=14;collision.shape=circle;body.add_child(collision)
	var sprite=Sprite2D.new();sprite.name="Art";sprite.texture=texture;sprite.scale=Vector2.ONE*size/texture.get_width();sprite.position.y=-size*.42;body.add_child(sprite);bodies[id]=body
func move_body(id: int,p: Vector2,delta: Vector2) -> Vector2:
	if not bodies.has(id):return MAP.move(p,delta,game.world.kingdom.claimed.size()<14)
	var body=bodies[id];body.position=p;body.move_and_collide(delta);return body.position.round()
func place(node: Control,rect: Rect2) -> void:
	hud.add_child(node);node.position=rect.position;node.size=rect.size
func add_button(id: String,text: String,rect: Rect2,cb: Callable) -> void:
	var b=game.ui.button(text,cb,true);b.add_theme_font_size_override("font_size",18);place(b,rect);buttons[id]=b
func build_hud() -> void:
	var layer=CanvasLayer.new();layer.layer=12;add_child(layer);hud=Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(hud)
	var height=get_viewport_rect().size.y
	var bg=ColorRect.new();bg.color=Color(.035,.09,.12,.92);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;place(bg,Rect2(0,0,720,165))
	health=game.ui.label("",24,Color("d7e5ba"));place(health,Rect2(25,30,550,35))
	objective=game.ui.label("",19);place(objective,Rect2(25,75,650,77))
	message=game.ui.label(say("Left stick / WASD to move · E to inspect the Sunstone.","Sol çubuk / WASD ile yürü · Güneştaşı için E veya İncele."),18);place(message,Rect2(30,height-340,660,65))
	add_button("return",say("Home","Dön"),Rect2(605,20,95,48),go_home)
	add_button("interact",say("Inspect","İncele"),Rect2(588,height-192,110,85),interact)
	stick=preload("res://scripts/adventure_stick.gd").new();stick.position=Vector2(125,height-145);layer.add_child(stick)
	refresh_hud()
func refresh_hud() -> void:
	var h=game.world.kingdom.adventure.hero;var r=game.world.kingdom.adventure.run
	health.text=h.name+" · "+str(int(h.hp))+" / "+str(H.stats(game.world).health)+say(" HP"," Can")
	objective.text=say("WILDWOOD · ","YABANORMAN · ")+(say("Sunstone found · return home","Güneştaşı bulundu · eve dön") if r.landmark else say("Find the ancient Sunstone on the north trail","Kuzey patikasında eski Güneştaşını bul"))
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(stick.position)<115 and stick_index<0:stick_index=event.index
		elif not event.pressed and event.index==stick_index:stick_index=-1;movement=Vector2.ZERO
	if event is InputEventScreenDrag and event.index==stick_index:movement=((event.position-stick.position)/65).limit_length(1)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_E:interact()
		if event.keycode==KEY_ESCAPE:frozen=not frozen;message.text=say("Paused · Escape to resume, Home to retreat.","Duraklatıldı · Escape sürdürür; Dön geri çeker.") if frozen else ""
func _physics_process(delta: float) -> void:
	if frozen or game.suspended:return
	var direction=movement
	if not controlled:
		direction+=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	stick.vector=direction.limit_length(1);stick.queue_redraw();accumulator+=minf(delta,.2)
	while accumulator>=.05:
		accumulator-=.05;var started=Time.get_ticks_usec();A.step(game.world,{"move":direction},move_body);combat_cpu_us+=Time.get_ticks_usec()-started;physics_steps+=1
	var r=game.world.kingdom.adventure.run;bodies[0].position=Vector2(r.x,r.y)
	bodies[0].get_node("Art").rotation=sin(r.clock*.012)*.025*direction.length()
	camera.position=camera.position.lerp(bodies[0].position,1-exp(-delta*7))
	hud_clock+=delta;save_clock+=delta
	if hud_clock>.2:hud_clock=0;refresh_hud()
	if save_clock>5:save_clock=0;game.checkpoint("adventure")
	queue_redraw()
func _draw() -> void:
	if not game:return
	var r=game.world.kingdom.adventure.run
	draw_circle(MAP.START,34,Color(.7,.85,.65,.5));draw_arc(MAP.START,40,0,TAU,32,Color("e8d7a4"),3,true)
	draw_style_box(ruin_style(),Rect2(MAP.LANDMARK-Vector2(22,65),Vector2(44,72)))
	draw_arc(MAP.LANDMARK-Vector2(0,45),18,0,TAU,24,Color("ead797"),4,true)
func ruin_style() -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=Color("9cbbaa");style.border_color=Color("d8d8ae");style.set_border_width_all(4);style.set_corner_radius_all(9);return style
func interact() -> void:
	var result=A.interact(game.world)
	if result=="landmark":message.text=say("The Sunstone remembers your kingdom. Arin will want to hear this.","Güneştaşı krallığını hatırlıyor. Arin bunu duymak isteyecek.");game.audio.chime(6);game.checkpoint("landmark")
	refresh_hud()
func go_home() -> void:
	var paused=game.world.kingdom.adventure.run.home_paused
	if not A.exit(game.world):return
	game.adventure_scene=null;game.paused=paused;game.show_world(true);game.ui.root.show();game.ui.close();game.ui.refresh();game.checkpoint("return-home");queue_free()
