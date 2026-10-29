extends Node2D
const M=preload("res://scripts/military.gd")
var game
var hud: Control
var title: Label
var status: Label
var buttons={}
var textures={}
var frozen=false
var accumulator=0.0
var clock=0.0
var save_clock=0.0
var cpu_us=0
var steps=0
var startup_ms=0.0
var hits=[]
var arena: Node2D
func say(en: String,tr: String) -> String:return game.realm_ui.say(en,tr)
func _ready() -> void:
	var started=Time.get_ticks_usec();game.show_world(false);game.ui.root.hide()
	for key in ["militia","spearman","archer","raider","bow","captain","watchtower","wall","barracks"]:textures[key]=load("res://assets/kingdom/"+key+".svg")
	arena=Node2D.new();arena.draw.connect(draw_arena);arena.scale=Vector2.ONE*.75;arena.position=Vector2(0,get_viewport_rect().size.y*.48-337.5);add_child(arena)
	load("res://scripts/simple_army_hud.gd").new(self).build()
	var extent=get_viewport_rect().size;var fit=minf((extent.x-32)/960,(extent.y-150)/900);arena.scale=Vector2.ONE*fit;arena.position=Vector2((extent.x-960*fit)*.5,(extent.y-900*fit)*.5)
	startup_ms=(Time.get_ticks_usec()-started)/1000.0;refresh()
func place(n: Control,r: Rect2) -> void:hud.add_child(n);n.position=r.position;n.size=r.size
func button(key: String,t: String,r: Rect2,cb: Callable) -> void:
	var b=game.ui.button(t,cb,false);b.add_theme_font_size_override("font_size",19);place(b,r);buttons[key]=b
func refresh() -> void:
	var b=game.world.kingdom.military.battle;var m=game.world.kingdom.military
	title.text=say("HOLD THE HEARTH","OCAĞI SAVUN") if b.mission=="raid" else say("THE BORDER CAPTAIN","SINIR KOMUTANI")
	var order_text={"advance":say("Advancing","İlerliyor"),"hold":say("Holding position","Konumu tutuyor"),"retreat":say("Retreating","Geri çekiliyor")}
	var result={"won":say("Victory · survivors gain experience","Zafer · sağ kalanlar deneyim kazanır"),"lost":say("Company injured · recover at the barracks","Birlik yaralandı · kışlada iyileştir"),"retreat":say("Retreated · survivors and equipment preserved","Çekildi · sağ kalanlar ve donanım korunur")}
	status.text=game.world.kingdom.adventure.hero.name+" · "+order_text[b.order]+"\n"+(result.get(b.result,say("Watch the attack windups. Change formation to protect your company.","Saldırı hazırlığını izle. Birliğini korumak için düzen değiştir.")))
	buttons.home.disabled=b.result.is_empty()
	for key in ["advance","hold","retreat"]:buttons[key].disabled=not b.result.is_empty()
	for key in M.FORMATIONS:buttons[key].set_pressed_no_signal(m.formation==key)
	for key in ["advance","hold","retreat"]:buttons[key].set_pressed_no_signal(b.order==key)
func toggle_pause() -> void:
	frozen=not frozen;buttons.pause.text=say("Resume","Sürdür") if frozen else say("Pause","Dur")
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:toggle_pause()
func _process(delta: float) -> void:
	if game.suspended:return
	clock+=delta
	for hit in hits:hit.age+=delta
	hits=hits.filter(func(hit):return hit.age<.65)
	if not frozen:
		accumulator+=minf(delta,.15)
		while accumulator>=.05:
			accumulator-=.05;var started=Time.get_ticks_usec();var cues=M.step(game.world);cpu_us+=Time.get_ticks_usec()-started;steps+=1
			for cue in cues:cue.age=0.0;hits.append(cue)
			if not cues.is_empty():game.audio.button_sound()
		save_clock+=delta
		if save_clock>=3:save_clock=0;game.checkpoint("army-battle")
	refresh();arena.queue_redraw()
func draw_arena() -> void:
	var b=game.world.kingdom.military.battle;var camp=b.mission=="camp"
	arena.draw_rect(Rect2(-4000,-4000,9000,9000),Color("688b73") if camp else Color("789c7c"))
	arena.draw_colored_polygon(PackedVector2Array([Vector2(0,0),Vector2(960,0),Vector2(960,250),Vector2(600,170),Vector2(300,225),Vector2(0,180)]),Color("507768"))
	arena.draw_polyline(PackedVector2Array([Vector2(30,590),Vector2(280,510),Vector2(570,520),Vector2(960,650)]),Color("b7b18a"),100,true)
	arena.draw_polyline(PackedVector2Array([Vector2(30,590),Vector2(280,510),Vector2(570,520),Vector2(960,650)]),Color("c4bd96"),72,true)
	for i in range(95):
		var p=Vector2((i*131+19)%960,100+(i*79)%730)
		arena.draw_line(p,p+Vector2(-3,-7),Color("88a580"),2,true);arena.draw_line(p+Vector2(4,2),p+Vector2(6,-5),Color("a2b28b"),2,true)
	if camp:
		arena.draw_texture_rect(textures.barracks,Rect2(680,40,220,220),false,Color("d2bb9a"))
		arena.draw_rect(Rect2(430,350,90,120),Color("665b48"));arena.draw_rect(Rect2(436,355,78,110),Color("b19a74"))
		for y in range(360,465,19):arena.draw_line(Vector2(430,y),Vector2(520,y),Color("776c53"),5,true)
	else:
		arena.draw_texture_rect(textures.watchtower,Rect2(10,60,180,180),false)
		arena.draw_texture_rect(textures.wall,Rect2(8,620,210,210),false)
	for friendly in [false,true]:
		var actors=b.friends if friendly else b.enemies
		for a in actors:
			var u=M.unit(game.world,int(a.id)) if friendly else a
			var p=Vector2(a.x,a.y);var kind=u.kind
			if u.hp<=0:
				arena.draw_circle(p,16,Color(.15,.25,.26,.4));continue
			var walk=sin(clock*8+a.id)*3 if a.state=="move" else sin(clock*2+a.id)
			arena.draw_circle(p+Vector2(0,5),25,Color(.1,.2,.22,.25))
			arena.draw_arc(p,32,-PI,PI,20,Color("97d8c7") if friendly else Color("d39a7b"),2,true)
			arena.draw_texture_rect(textures[kind],Rect2(p+Vector2(-52,-91+walk),Vector2(104,104)),false)
			arena.draw_rect(Rect2(p+Vector2(-30,-105),Vector2(60,7)),Color("2b4546"))
			arena.draw_rect(Rect2(p+Vector2(-30,-105),Vector2(60*u.hp/(100.0 if friendly else 150.0 if kind=="captain" else 48.0),7)),Color("a7dbc3") if friendly else Color("e3ae80"))
			if a.state=="windup":
				arena.draw_arc(p,40,-PI/2,-PI/2+TAU*(1-float(a.timer)/(450 if friendly else 650)),24,Color("ffe2a1"),4,true)
				var targets=b.enemies if friendly else b.friends;var locked=targets.filter(func(t):return t.id==a.target)
				if not locked.is_empty() and kind in ["archer","bow"]:arena.draw_line(p+Vector2(0,-38),Vector2(locked[0].x,locked[0].y-35),Color(1,.88,.6,.35),2,true)
	for hit in hits:
		var p=Vector2(hit.x,hit.y-70-hit.age*40);arena.draw_arc(Vector2(hit.x,hit.y-40),15+hit.age*25,0,TAU,18,Color(1,.86,.6,1-hit.age/.65),3,true)
		arena.draw_string(game.ui.ui_font(),p,str(hit.damage),HORIZONTAL_ALIGNMENT_CENTER,-1,26,Color("fff0b8") if hit.friendly else Color("ffc4a8"))
func go_home() -> void:
	if not M.return_home(game.world):return
	game.army_scene=null;game.show_world(true);game.ui.root.show();game.ui.close();game.ui.refresh();game.checkpoint("company-return");queue_free();game.military_ui.open()
