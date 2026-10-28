extends Node2D
# Beta shared clearing: snapshots are presentation only; never call local Adventure.step.
var game
var character={}
var ticket=""
var socket=WebSocketPeer.new()
var authenticated=false
var received=false
var sequence=0
var send_clock=0.0
var last_packet=0
var snapshot={"players":[],"enemies":[]}
var actors={}
var sprites={}
var selected=1
var pending_action=""
var attack_held=false
var direction=Vector2.ZERO
var dragging=false
var stick_center=Vector2.ZERO
var frozen=false
var status:Label
var target_label:Label
var hud:Control
var camera:Camera2D
var joined_name=""
var exit_button:Button
var skill_button:Button
var attack_button:Button
var target_button:Button
var previous_xp=-1
var flash_until=0
var ground=preload("res://assets/adventure/wildwood-ground-premium.svg")
func say(en,tr):return tr if game.ui.language=="tr" else en
func _ready():
	game.shared_hunt_scene=self;game.in_menu=true;game.reset_gesture();game.ui.root.hide();game.show_world(false)
	camera=Camera2D.new();camera.position=Vector2(550,650);camera.zoom=Vector2.ONE*.9;add_child(camera);camera.make_current()
	build_hud();var endpoint=game.online.endpoint.replace("https://","wss://").replace("http://","ws://")
	if socket.connect_to_url(endpoint+"/play")!=OK:status.text=say("Connection failed. Return and try again.","Bağlantı kurulamadı. Dönüp yeniden dene.")
	queue_redraw()
func _draw():
	for x in range(-2,3):
		for y in range(-2,3):draw_texture_rect(ground,Rect2(x*1300,y*960,1300,960),false)
	draw_rect(Rect2(80,100,1140,780),Color(.9,.8,.5,.22),false,2)
	for enemy in snapshot.enemies:
		var point=Vector2(enemy.x,enemy.y)
		if int(enemy.id)==selected and enemy.hp>0:draw_arc(point,45,0,TAU,40,Color("f2d798"),3)
		if enemy.hp>0:draw_rect(Rect2(point+Vector2(-35,-115),Vector2(70,6)),Color("382a27"));draw_rect(Rect2(point+Vector2(-35,-115),Vector2(70*float(enemy.hp)/100,6)),Color("b9403c"))
		if int(snapshot.get("tick",0))-int(enemy.get("hit",-100))<3:draw_arc(point,48,0,TAU,28,Color("f1cf92"),4)
	for player in snapshot.players:
		var clock=int(snapshot.get("tick",0));var point=Vector2(player.x,player.y)
		if clock-int(player.get("cast",-100))<3:draw_arc(point,62,0,TAU,40,Color("91bbfa"),5)
		elif clock-int(player.get("attack",-100))<2:draw_arc(point,55,-PI*.8,PI*.3,24,Color("ffe1a1"),4)
func button(parent,title,rect,action,id):
	var b=game.ui.button(title,action,true);b.name=id;b.position=rect.position;b.size=rect.size;b.add_theme_font_size_override("font_size",16);parent.add_child(b);return b
func build_hud():
	var extent=get_viewport_rect().size;var layer=CanvasLayer.new();layer.layer=20;add_child(layer);hud=Control.new();hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(hud)
	var panel=PanelContainer.new();panel.position=Vector2(12,12);panel.size=Vector2(340,86);panel.add_theme_stylebox_override("panel",load("res://scripts/premium_theme.gd").box(Color(.035,.055,.07,.92),true));hud.add_child(panel);status=game.ui.label(say("Connecting to shared realm…","Ortak bölgeye bağlanılıyor…"),16);panel.add_child(status)
	target_label=game.ui.label("",18,Color("ecd598"));target_label.position=Vector2(370,15);target_label.size=Vector2(340,40);hud.add_child(target_label)
	exit_button=button(hud,say("Leave hunt","Avdan ayrıl"),Rect2(extent.x-164,12,152,48),leave,"LeaveSharedHunt")
	attack_button=button(hud,say("Attack","Saldır"),Rect2(extent.x-132,extent.y-128,116,100),func():pending_action="attack","SharedAttack")
	attack_button.button_down.connect(func():attack_held=true);attack_button.button_up.connect(func():attack_held=false)
	skill_button=button(hud,say("Skill · 8 MP","Beceri · 8 MP"),Rect2(extent.x-260,extent.y-90,116,62),func():pending_action="skill","SharedSkill")
	target_button=button(hud,say("Target","Hedef"),Rect2(extent.x-260,extent.y-160,116,62),cycle_target,"SharedTarget")
	button(hud,say("Dodge","Kaçın"),Rect2(extent.x-388,extent.y-90,116,62),func():pending_action="dodge","SharedDodge")
	stick_center=Vector2(95,extent.y-110);var stick=load("res://scripts/adventure_stick.gd").new();stick.position=stick_center;hud.add_child(stick)
	var instructions=game.ui.label(say("WASD / stick · Space attack · Q skill\nShared enemies · rewards kept on your account","WASD / çubuk · Boşluk saldır · Q beceri\nOrtak düşmanlar · ödüller hesabında saklanır"),14);instructions.position=Vector2(15,extent.y-56);instructions.size=Vector2(500,54);hud.add_child(instructions)
func cycle_target():
	var targets=snapshot.enemies.filter(func(e):return e.hp>0)
	if targets.is_empty():return
	var index=targets.find_custom(func(e):return int(e.id)==selected);selected=int(targets[(index+1)%targets.size()].id)
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE:pending_action="attack"
		if event.keycode==KEY_Q:pending_action="skill"
		if event.keycode==KEY_Z:cycle_target()
		if event.keycode==KEY_SHIFT:pending_action="dodge"
		if event.keycode==KEY_ESCAPE:leave()
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if not event.pressed:dragging=false;direction=Vector2.ZERO;return
		if event.position.distance_to(stick_center)<70:dragging=true;direction=((event.position-stick_center)/45).limit_length(1);return
		var point=get_canvas_transform().affine_inverse()*event.position
		for e in snapshot.enemies:
			if e.hp>0 and point.distance_to(Vector2(e.x,e.y))<65:selected=int(e.id);return
	if event is InputEventMouseMotion and dragging:direction=((event.position-stick_center)/45).limit_length(1)
func body(id,kind,enemy=false):
	if actors.has(id):return actors[id]
	var node=Node2D.new();node.y_sort_enabled=true;add_child(node);var sprite=Sprite2D.new();sprite.texture=load("res://assets/adventure/wolf-painted-v2.png") if enemy and ResourceLoader.exists("res://assets/adventure/wolf-painted-v2.png") else load("res://assets/adventure/wolf.svg") if enemy else load("res://assets/rpg/"+kind+".png");sprite.scale=Vector2.ONE*(115.0/sprite.texture.get_height());sprite.position.y=-48;node.add_child(sprite)
	var name=Label.new();name.name="Name";name.position=Vector2(-80,-138);name.size=Vector2(160,24);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name.add_theme_font_size_override("font_size",14);node.add_child(name);actors[id]=node;sprites[id]=sprite;return node
func _process(delta):
	if game.suspended:socket.close(1000,"Background");direction=Vector2.ZERO;return
	socket.poll();var state=socket.get_ready_state()
	if state==WebSocketPeer.STATE_OPEN:
		if not authenticated:socket.send_text(JSON.stringify({"ticket":ticket}));ticket="";authenticated=true
		while socket.get_available_packet_count()>0:
			var data=JSON.parse_string(socket.get_packet().get_string_from_utf8())
			if data is Dictionary and data.get("version")==1 and data.get("players") is Array and data.get("enemies") is Array:snapshot=data;received=true;last_packet=Time.get_ticks_msec()
		send_clock+=delta
		if send_clock>=.05:
			send_clock=0;var move=direction+Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)));move=move.limit_length(1)
			socket.send_text(JSON.stringify({"sequence":sequence,"x":move.x,"y":move.y,"action":pending_action if not pending_action.is_empty() else "attack" if attack_held else "","target":selected}));sequence+=1;pending_action=""
	elif state==WebSocketPeer.STATE_CLOSED:status.text=say("Disconnected. Your earned rewards are safe.\nLeave and reconnect.","Bağlantı kesildi. Kazanılan ödüller korundu.\nAyrılıp yeniden bağlan.")
	var present=[]
	for p in snapshot.players:
		var id="p_"+str(p.id);present.append(id);var actor=body(id,p.job);actor.position=actor.position.lerp(Vector2(p.x,p.y),minf(1,delta*15)) if actor.has_meta("placed") else Vector2(p.x,p.y);actor.set_meta("placed",true);actor.modulate.a=1 if p.hp>0 else .3;actor.get_node("Name").text=str(p.name)+" · "+str(int(p.hp))+" HP"
		if p.id==character.id:
			camera.position=camera.position.lerp(actor.position,delta*6);status.text=str(p.name)+" · "+str(int(p.hp))+" HP · "+str(int(p.mp))+" MP\n"+str(int(p.xp))+" XP · "+str(int(p.essence))+say(" essence · "," öz · ")+str(snapshot.players.size())+say(" players"," oyuncu")
			if previous_xp>=0 and p.xp>previous_xp:flash_until=Time.get_ticks_msec()+2000;game.audio.chime(6)
			previous_xp=int(p.xp);skill_button.disabled=p.mp<8 or p.hp<=0
	for e in snapshot.enemies:
		var id="e_"+str(e.id);present.append(id);var actor=body(id,"wolf",true);actor.position=Vector2(e.x,e.y);actor.visible=e.hp>0;actor.get_node("Name").text=say("Wild wolf","Yaban kurdu")
		if int(e.id)==selected:target_label.text=say("Wild wolf · ","Yaban kurdu · ")+str(int(e.hp))+" / 100 HP"
	for ally in snapshot.get("companions",[]):
		var id="a_"+str(ally.id);present.append(id);var actor=body(id,ally.job);actor.position=actor.position.lerp(Vector2(ally.x,ally.y),minf(1,delta*10)) if actor.has_meta("placed") else Vector2(ally.x,ally.y);actor.set_meta("placed",true);actor.modulate=Color(.75,.85,1,.8);actor.get_node("Name").text=ally.job+say(" · companion"," · yoldaş")
	if Time.get_ticks_msec()<flash_until:target_label.text=say("+20 XP · +1 essence · reward saved","+20 XP · +1 öz · ödül kaydedildi")
	for id in actors.keys():
		if not id in present:actors[id].queue_free();actors.erase(id);sprites.erase(id)
	queue_redraw()
func leave():
	socket.close(1000,"Leave");game.checkpoint("shared-city-progress");game.shared_hunt_scene=null;game.ui.root.show();game.in_menu=true;game.ui.entry_ui.characters();queue_free()
func _exit_tree():socket.close()
func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:direction=Vector2.ZERO;dragging=false;attack_held=false;pending_action=""
