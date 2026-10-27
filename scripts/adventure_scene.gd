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
var spell_fx
var props
var floats: Array=[]
var stone_distance=0.0
var last_effects_clock=-1
var presentation_cpu_us=0
var presentation_steps=0
var effect_draw_cpu_us=0
var effect_draws=0
var effect_textures: Dictionary={}
var attack_held=false
var mouse_aim=Vector2.ZERO
var button_titles: Dictionary={}
var action_counts: Dictionary={}
var death_ages: Dictionary={}
var effects_were_dynamic=true
var guide_point=Vector2.ZERO
var pack_panel
var pack_was_frozen=false
var warrior_visual
var presentation_feedback: Array=[]
var ranged_trails: Array=[]
var rpg_overlay=false
var overlay_was_frozen=false
var rpg_health_bar: ProgressBar
var rpg_mana_bar: ProgressBar
var targeting
var action_captions={}
var battle_feedback
var rpg_experience_bar: ProgressBar
var experience_label: Label
var mana_label: Label
func enemy_texture(kind: String) -> Texture2D:
	var painted="res://assets/adventure/"+kind+"-painted-v2.png"
	return load(painted) if ResourceLoader.exists(painted) else load("res://assets/adventure/"+kind+".svg")
func say(en: String,tr: String) -> String:return tr if game.ui.language=="tr" else en
func _ready() -> void:
	var started=Time.get_ticks_usec();game.show_world(false);game.ui.root.hide()
	region=preload("res://scripts/regions.gd").current(game.world);region_map=preload("res://scripts/regions.gd").map(region)
	for key in ["chest","herb"]:effect_textures[key]=load("res://assets/adventure/"+key+".svg")
	var ground=load("res://scripts/sanctuary_ground.gd").new() if region=="sanctuary" else load("res://scripts/ashen_desert_ground.gd").new() if region=="ashen_desert" else load("res://scripts/iron_hills_ground.gd").new() if region=="iron_hills" else preload("res://scripts/wildwood_ground.gd").new();add_child(ground)
	actors=Node2D.new();actors.y_sort_enabled=true;add_child(actors)
	for p in region_map.trees():
		var tree=Sprite2D.new() if region!="wildwood" else GameArt.sprite(7 if int(p.x)%2==0 else 12,100);tree.position=p
		if region!="wildwood":tree.texture=load("res://assets/adventure/desert-palm.svg" if region=="ashen_desert" else "res://assets/adventure/mountain-pine.svg");tree.scale=Vector2.ONE*.7;tree.position.y-=55
		elif not game.view.low_quality:tree.material=GameArt.foliage()
		actors.add_child(tree)
	for rect in region_map.solids(game.world.kingdom.claimed.size()<14):
		var wall=StaticBody2D.new();wall.position=rect.get_center();var shape=CollisionShape2D.new();var box=RectangleShape2D.new();box.size=rect.size;shape.shape=box;wall.add_child(shape);add_child(wall)
		if region!="wildwood" and rect.size.x>60 and rect.size.y>60:
			# Art follows the physical obstacle footprint, rather than blocking invisible ground.
			var art=Sprite2D.new();art.texture=load("res://assets/adventure/sanctuary-wall.svg" if region=="sanctuary" else "res://assets/adventure/desert-rock.svg" if region=="ashen_desert" else "res://assets/adventure/mountain-rock.svg");art.position=rect.get_center();art.scale=rect.size/Vector2(180,160);art.position.y-=rect.size.y*.15;actors.add_child(art)
	if region=="sanctuary":
		for key in ["sun-relic-pedestal","sunforged-tablet","chest"]:regional_textures[key]=load("res://assets/adventure/"+key+".svg")
		regional_prop("sun-relic-pedestal",region_map.RELIC,130,.42);regional_prop("sunforged-tablet",region_map.INSCRIPTION,100,.42);regional_prop("sunforged-tablet",region_map.LORE,90,.42);regional_prop("chest",region_map.TREASURE,90,.42)
		var doors=preload("res://scripts/sanctuary_view.gd").new();add_child(doors)
	if region=="ashen_desert":
		for key in ["desert_crystal","ancient-road"]:regional_textures[key]=load("res://assets/adventure/"+key+".svg")
		regional_prop("desert_crystal",region_map.CRYSTAL,110,.42)
		regional_prop("ancient-road",region_map.ROAD,100,.15)
	if region=="iron_hills":
		for key in ["ore-vein","mountain-rock","forgotten-mine","mine-cart"]:regional_textures[key]=load("res://assets/adventure/"+key+".svg")
		regional_prop("forgotten-mine",Vector2(480,310),250,.5)
		regional_prop("mine-cart",Vector2(560,370),100,.5)
		for key in region_map.NODES:regional_prop("ore-vein" if key=="ore" else "mountain-rock",region_map.NODES[key].point,110,.42,.4 if game.world.kingdom.adventure.run.nodes[key] else 1.0)
	var hero_texture="res://assets/rpg/"+str(game.world.kingdom.adventure.hero.get("class","warrior"))+".png"
	make_body(0,Vector2(game.world.kingdom.adventure.run.x,game.world.kingdom.adventure.run.y),load(hero_texture) if ResourceLoader.exists(hero_texture) else load("res://assets/adventure/warrior.png"),110)
	if game.v4_preview:
		bodies[0].get_node("Art").hide();warrior_visual=preload("res://scripts/warrior_visual.gd").new();bodies[0].add_child(warrior_visual);warrior_visual.sample(game.world)
	for e in game.world.kingdom.adventure.run.enemies:make_body(int(e.id),Vector2(e.x,e.y),enemy_texture(e.kind),180 if e.kind=="thornheart" else 100)
	props=preload("res://scripts/adventure_props.gd").new();add_child(props)
	effects=preload("res://scripts/adventure_effects.gd").new();add_child(effects)
	spell_fx=preload("res://scripts/class_spell_fx.gd").new();spell_fx.reduce_motion=game.ui.reduce_motion;add_child(spell_fx)
	camera=Camera2D.new();camera.zoom=Vector2.ONE*1.15;camera.position=camera_target();camera.position_smoothing_enabled=false;add_child(camera);camera.make_current()
	build_hud();targeting=preload("res://scripts/combat_targeting.gd").new();targeting.name="CombatTargeting";add_child(targeting);battle_feedback=preload("res://scripts/combat_feedback.gd").new();battle_feedback.name="CombatFeedback";add_child(battle_feedback);startup_ms=(Time.get_ticks_usec()-started)/1000.0
func regional_prop(key: String,point: Vector2,size: float,anchor: float,alpha: float=1.0) -> void:
	var base=Node2D.new();base.position=point;actors.add_child(base)
	var sprite=Sprite2D.new();sprite.texture=regional_textures[key];sprite.position.y=-size*anchor;sprite.scale=Vector2.ONE*size/sprite.texture.get_width();sprite.modulate.a=alpha;base.add_child(sprite)
	if key in ["ore-vein","mountain-rock","desert_crystal"]:base.name="deposit_crystal" if key=="desert_crystal" else "deposit_ore" if key=="ore-vein" else "deposit_stone"
	if key=="chest":base.name="sanctuary_chest"
func camera_target() -> Vector2:
	var half=get_viewport_rect().size/(camera.zoom*2);var p=bodies[0].position
	return Vector2(clampf(p.x,half.x,region_map.SIZE.x-half.x),clampf(p.y+100/camera.zoom.y,half.y-165/camera.zoom.y,region_map.SIZE.y-half.y+350/camera.zoom.y))
func make_body(id: int,p: Vector2,texture: Texture2D,size: float) -> void:
	var body=CharacterBody2D.new();body.position=p;body.collision_layer=2;body.collision_mask=1;actors.add_child(body)
	var collision=CollisionShape2D.new();var circle=CircleShape2D.new();circle.radius=14;collision.shape=circle;body.add_child(collision)
	var sprite=Sprite2D.new();sprite.name="Art";sprite.texture=texture;sprite.scale=Vector2.ONE*size/texture.get_width();sprite.position.y=-size*.42;body.add_child(sprite);bodies[id]=body
	body.set_meta("art_rest",sprite.position)
func move_body(id: int,p: Vector2,delta: Vector2) -> Vector2:
	if not bodies.has(id):return region_map.move(p,delta,game.world.kingdom.claimed.size()<14)
	var body=bodies[id];body.position=p;body.move_and_collide(delta);return body.position.round()
func place(node: Control,rect: Rect2) -> void:
	hud.add_child(node);node.position=rect.position;node.size=rect.size
func add_button(id: String,text: String,rect: Rect2,cb: Callable) -> void:
	var b=game.ui.button(text,cb,true);b.add_theme_font_size_override("font_size",18);place(b,rect);buttons[id]=b;button_titles[id]=text
func build_hud() -> void:
	if not game.v4_preview:rpg_hud();return
	legacy_hud()
func rpg_hud():
	preload("res://scripts/classic_combat_hud.gd").new(self).build()
func open_rpg_panel(key: String):
	if key=="map":
		if not A.can_travel(game.world):message.text=say("Leave combat before traveling.","Işınlanmak için önce savaştan uzaklaş.");return
		go_home();game.ui.premium.call_deferred("route","map");return
	clear_combat_input()
	if not rpg_overlay:overlay_was_frozen=frozen
	frozen=true;rpg_overlay=true;game.ui.layer=20;game.ui.root.show();game.ui.premium.route(key)
func legacy_hud() -> void:
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
	if region in ["ashen_desert","sanctuary"]:add_button("guide",say("Guide","İz"),Rect2(25,145,110,42),guide)
	if region=="sanctuary":add_button("pack",say("Pack","Çanta"),Rect2(150,145,110,42),toggle_pack)
	stick=preload("res://scripts/adventure_stick.gd").new();stick.position=Vector2(125,height-145);layer.add_child(stick)
	refresh_hud()
func refresh_hud() -> void:
	var h=game.world.kingdom.adventure.hero;var r=game.world.kingdom.adventure.run
	if is_instance_valid(rpg_health_bar):
		rpg_health_bar.max_value=H.stats(game.world).health;rpg_health_bar.value=h.hp;rpg_mana_bar.max_value=preload("res://scripts/rpg_progression.gd").modifiers(game.world).mana;rpg_mana_bar.value=game.world.rpg.progression[game.world.rpg.active].mana if game.world.has("rpg") else 100
	if is_instance_valid(mana_label):mana_label.text="MP "+str(int(rpg_mana_bar.value))+" / "+str(int(rpg_mana_bar.max_value))
	if is_instance_valid(rpg_experience_bar):
		var level=H.level(h);rpg_experience_bar.max_value=40*(2*level-1);rpg_experience_bar.value=int(h.xp)-40*(level-1)*(level-1)
		experience_label.text="Lv "+str(level)+" · EXP "+str(int(rpg_experience_bar.value))+" / "+str(int(rpg_experience_bar.max_value))
		if level>=15:rpg_experience_bar.value=rpg_experience_bar.max_value;experience_label.text="Lv 15 · MAX"
	health.text=h.name+" · "+str(int(h.hp))+" / "+str(H.stats(game.world).health)+say(" HP"," Can")
	if region=="ashen_desert" and preload("res://scripts/ashen_desert.gd").poisoned(r):health.text+=say(" · POISON "," · ZEHİR ")+str(ceili((r.poison_until-r.clock)/1000.0))+"s"
	for key in ["attack","skill","dodge","heal"]:
		var cd=int(h.cooldowns[key]);buttons[key].text=button_titles[key]+("\n"+str(snappedf(cd/1000.0,.1))+"s" if cd>0 else "")
		var badge=buttons[key].get_node_or_null("ActionBadge")
		if badge:badge.sample(cd,500 if key=="attack" else 1200 if key=="dodge" else 4000 if key=="skill" else 6000)
	if game.world.has("rpg") and not game.v4_preview:
		var R=preload("res://scripts/rpg_progression.gd");var p=R.selected(game.world)
		for i in range(3):
			var key="skill" if i==0 else "rpg_skill"+str(i);var index=int(p.bar[i]);var rank=int(p.skills[index]);var cd=int(p.get("cooldowns",[0,0,0,0,0,0])[index]) if rank>0 else int(h.cooldowns.skill)
			buttons[key].text=str(snappedf(cd/1000.0,.1))+"s" if cd>0 else ""
			buttons[key].disabled=not R.skill_ready(game.world,{"skill_slot":i})
			if action_captions.has(key):action_captions[key].text=say("Locked","Kilitli") if rank==0 and index!=0 else say("Low mana","Mana az") if float(p.mana)<(12+index*3 if rank>0 else 8) else say("Skill ","Beceri ")+["I","II","III"][i]
			var badge=buttons[key].get_node_or_null("ActionBadge")
			if badge:badge.sample(cd,4000+index*500,rank==0 and index!=0)
			buttons[key].tooltip_text=R.skill_name(h.get("class","warrior"),index,game.ui.language=="tr")+" · "+((str(12+index*3)+say(" mana"," mana")) if rank>0 else say("Starter ability · 8 MP","Başlangıç becerisi · 8 MP") if index==0 else say("Learn this ability first","Önce bu beceriyi öğren"))
	var near_loot=r.loot.any(func(l):return not l.taken and Vector2(r.x,r.y).distance_to(Vector2(l.x,l.y))<=90)
	if action_captions.has("interact"):action_captions.interact.text=say("Collect","Topla") if near_loot else say("Inspect","İncele")
	var q=preload("res://scripts/kingdom.gd").current(game.world)
	objective.text=say("IRON HILLS · Find the mine to the north.\nInspect ore veins; take materials home.","DEMİR TEPELER · Kuzeydeki madeni bul.\nCevheri incele; malzemeyi eve taşı.") if region=="iron_hills" else say("WILDWOOD · ","YABANORMAN · ")+(game.realm_ui.localized(q.title) if not q.is_empty() else say("Explore and return safely","Keşfet ve güvenle dön"))
	if region=="iron_hills" and r.landmark:objective.text=say("IRON HILLS · Forgotten Mine discovered\nOre and stone are finite · Home banks cargo.","DEMİR TEPELER · Unutulmuş Maden keşfedildi\nCevher ve taş sınırlı · Dön ganimeti depolar.")
	if region=="ashen_desert":objective.text=say("ASHEN DESERT · Find the oasis.\nDodge stings and glowing impact circles.","KÜL ÇÖLÜ · Vahayı bul.\nİğneden ve parlayan hedeflerden kaçın.") if not r.landmark else say("Oasis discovered · Hunt, collect a crystal, return.\nHeal at the oasis once · Home clears poison.","Vaha keşfedildi · Avla, kristal topla, dön.\nVahada bir kez iyileş · Dön zehri temizler.")
	if region=="sanctuary":objective.text=sanctuary_hint();actors.get_node("sanctuary_chest").visible=r.mechanisms.secret
	for e in r.enemies:
		if e.kind=="thornheart" and e.hp>0 and Vector2(r.x,r.y).distance_to(Vector2(e.x,e.y))<320:objective.text+="\nThornheart · "+str(int(e.hp))+" / 220 · "+say("Phase ","Evre ")+("II" if e.hp<=110 else "I")
	if h.defeated:message.text=say("Your champion fell. Home restores health and keeps your collected loot.","Şampiyonun düştü. Dön canı yeniler; toplanmış ganimetin korunur.")
func _input(event: InputEvent) -> void:
	if rpg_overlay:return
	if event is InputEventScreenTouch:
		if event.canceled:clear_combat_input();return
		if event.pressed and not game.v4_preview and game.ui.visible_ui_hit(hud,event.position):return
		action_counts.touch=int(action_counts.get("touch",0))+1
		if event.pressed and event.position.distance_to(stick.position)<stick.radius*1.4 and stick_index<0:stick_index=event.index
		elif not event.pressed and event.index==stick_index:stick_index=-1;movement=Vector2.ZERO;stick.vector=Vector2.ZERO;stick.queue_redraw()
		elif event.pressed and is_instance_valid(targeting):
			if not targeting.select_at(event.position) and is_instance_valid(battle_feedback):battle_feedback.pick_at(event.position)
	if event is InputEventScreenDrag and event.index==stick_index:
		movement=((event.position-stick.position)/maxf(30,stick.radius*.9)).limit_length(1);action_counts.drag=int(action_counts.get("drag",0))+1
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_Z,KEY_TAB] and is_instance_valid(targeting):targeting.cycle()
		if event.keycode==KEY_F8 and OS.is_debug_build() and is_instance_valid(warrior_visual):warrior_visual.debug_enabled=not warrior_visual.debug_enabled;warrior_visual.queue_redraw()
		if event.keycode==KEY_E:interact()
		if event.keycode==KEY_SPACE:actions.attack=true
		if event.keycode==KEY_Q:actions.skill=true
		if event.keycode in [KEY_1,KEY_2,KEY_3]:actions.skill=true;actions.skill_slot=int(event.keycode-KEY_1)
		if event.keycode==KEY_SHIFT:actions.dodge=true
		if event.keycode==KEY_F:actions.heal=true
		if event.keycode==KEY_ESCAPE:toggle_pause()
func clear_combat_input() -> void:
	attack_held=false;actions.clear();movement=Vector2.ZERO;mouse_aim=Vector2.ZERO;stick_index=-1
	if is_instance_valid(stick):stick.vector=Vector2.ZERO;stick.queue_redraw()
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:clear_combat_input()
func toggle_pause() -> void:
	if is_instance_valid(pack_panel):toggle_pack()
	frozen=not frozen;clear_combat_input()
	buttons.pause.text=say("Resume","Sürdür") if frozen else button_titles.pause
	message.text=say("Paused · Resume to continue; Home keeps collected loot.","Duraklatıldı · Sürdür ile devam et; Dön ganimeti korur.") if frozen else say("Watch the warning, then dodge. Attack during recovery.","Uyarıyı izle, sonra kaçın. Dinlenme aralığında saldır.")
func _unhandled_input(event: InputEvent) -> void:
	if not OS.has_feature("mobile") and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		if frozen or rpg_overlay:return
		var previous=targeting.selected_id if is_instance_valid(targeting) else 0
		if is_instance_valid(targeting) and targeting.select_at(event.position):
			if previous==targeting.selected_id or event.double_click:actions.attack=true
		elif is_instance_valid(battle_feedback):battle_feedback.pick_at(event.position)
func _physics_process(delta: float) -> void:
	if rpg_overlay:
		if not is_instance_valid(game.ui.modal):rpg_overlay=false;game.ui.root.hide();game.ui.layer=1;frozen=overlay_was_frozen;clear_combat_input()
		return
	if game.suspended:clear_combat_input();return
	if frozen:return
	var frame_started=Time.get_ticks_usec()
	presentation_feedback.clear()
	var direction=movement
	if not controlled:
		direction+=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	stick.vector=direction.limit_length(1);stick.queue_redraw();accumulator+=minf(delta,.2)
	while accumulator>=.05:
		accumulator-=.05;var started=Time.get_ticks_usec();var command=actions.duplicate();command.move=direction
		if attack_held or (not controlled and Input.is_physical_key_pressed(KEY_SPACE)):command.attack=true
		if mouse_aim.length()>.1:command.aim=mouse_aim;mouse_aim=Vector2.ZERO
		if is_instance_valid(targeting) and not targeting.target().is_empty():
			command.target_id=targeting.selected_id
			if command.get("attack",false) and not targeting.in_range():command.erase("attack");message.text=say("Target out of range or behind an obstacle. Move closer.","Hedef menzil dışında veya engelin arkasında. Yaklaş.")
		for key in ["attack","skill","dodge","heal"]:
			if command.get(key,false):action_counts[key]=int(action_counts.get(key,0))+1
		var before_position=Vector2(game.world.kingdom.adventure.run.x,game.world.kingdom.adventure.run.y)
		var can_cast=command.get("skill",false) and load("res://scripts/rpg_progression.gd").skill_ready(game.world,command)
		if command.get("skill",false) and not can_cast and is_instance_valid(battle_feedback):
			var prog=load("res://scripts/rpg_progression.gd").selected(game.world);var slot=clampi(int(command.get("skill_slot",0)),0,2);var index=int(prog.bar[slot]);var rank=int(prog.skills[index])
			battle_feedback.announce(say("Learn this skill first","Önce bu beceriyi öğren") if rank==0 and index!=0 else say("Not enough mana","Yeterli mana yok") if float(prog.mana)<(12+index*3 if rank>0 else 8) else say("Skill is cooling down","Beceri bekleme süresinde"))
		var before_feedback=battle_feedback.snapshot() if is_instance_valid(battle_feedback) else {}
		var feedback=A.step(game.world,command,move_body);presentation_feedback.append_array(feedback);actions.clear();combat_cpu_us+=Time.get_ticks_usec()-started;physics_steps+=1
		if is_instance_valid(battle_feedback):battle_feedback.resolve(before_feedback,feedback,command)
		if can_cast and feedback.has("swing"):
			var cls=game.world.kingdom.adventure.hero.get("class","warrior");var prog=load("res://scripts/rpg_progression.gd").selected(game.world);var index=int(prog.get("bar",[0,1,2])[clampi(int(command.get("skill_slot",0)),0,2)])
			var run=game.world.kingdom.adventure.run;spell_fx.cast(Vector2(run.x,run.y),cls,index,Vector2(run.facing[0],run.facing[1]))
		if region=="sanctuary":
			stone_distance+=before_position.distance_to(Vector2(game.world.kingdom.adventure.run.x,game.world.kingdom.adventure.run.y))
			if stone_distance>=65:stone_distance=fmod(stone_distance,65);game.audio.sanctuary("step")
		for cue in feedback:
			if cue is Dictionary:
				if cue.get("ranged",false):ranged_trails.append({"from":Vector2(cue.fromx,cue.fromy-35),"to":Vector2(cue.x,cue.y-35),"age":0.0})
			elif cue in ["swing","kill","boss","heal","plate","mechanism"]:game.audio.chime(6 if cue in ["kill","boss","plate","mechanism"] else 0 if cue=="swing" else 5)
			elif cue=="hurt":game.audio.chime(2)
			if region=="sanctuary":
				if cue is Dictionary or cue=="hurt":game.audio.sanctuary("impact")
				elif cue=="swing":game.audio.sanctuary("swing")
				elif cue in ["plate","mechanism"]:game.audio.sanctuary("switch")
			if cue is String and cue=="boss":message.text=say("Thornheart falls! Inspect the living heart, then return to Arin.","Dikenyürek düştü! Yaşayan kalbi İncele ile al; Arin'e dön.")
		if feedback.has("kill") or feedback.has("boss"):game.checkpoint("combat-victory")
	var r=game.world.kingdom.adventure.run;bodies[0].position=Vector2(r.x,r.y)
	spell_fx.aura_position=Vector2(r.x,r.y);spell_fx.aura_direction=Vector2(r.facing[0],r.facing[1]).normalized();spell_fx.aura=load("res://scripts/armory.gd").glow(game.world,int(game.world.kingdom.adventure.hero.equipment.weapon))
	if is_instance_valid(warrior_visual):warrior_visual.sample(game.world,presentation_feedback)
	bodies[0].get_node("Art").rotation=sin(r.clock*.012)*.025*direction.length()
	bodies[0].get_node("Art").position.y=-46.2-absf(sin(r.clock*.015))*3*direction.length()
	if r.swing>0:bodies[0].get_node("Art").rotation+=sin(r.swing/200.0*PI)*.2
	var facing=Vector2(r.facing[0],r.facing[1]).normalized();bodies[0].get_node("Art").position.x=sin(r.swing/200.0*PI)*8*facing.x
	if absf(facing.x)>.15:bodies[0].get_node("Art").flip_h=facing.x>0
	for e in r.enemies:
		var body=bodies[int(e.id)];body.position=Vector2(e.x,e.y);var sprite=body.get_node("Art");sprite.rotation=sin(r.clock*.012+int(e.id))*(.12 if e.state=="windup" else .035);sprite.modulate.a=.22 if e.hp==0 else 1.0
		var rest=Vector2(body.get_meta("art_rest"));var to_hero=(Vector2(r.x,r.y)-Vector2(e.x,e.y)).normalized();var data=A.enemies()[e.kind]
		if absf(to_hero.x)>.15 and Vector2(e.x,e.y).distance_to(Vector2(r.x,r.y))<270:sprite.flip_h=to_hero.x>0
		sprite.position=rest-to_hero*7*clampf(1-float(e.timer)/maxf(1,data.warning),0,1) if e.state=="windup" else rest+to_hero*10*clampf((float(e.timer)-float(data.cooldown)+180)/180.0,0,1) if e.state=="recover" else rest
		if e.kind=="thornheart" and e.hp>0 and bodies[0].position.y<e.y and bodies[0].position.distance_to(body.position)<110:sprite.modulate.a=.48
		if e.hp==0:
			death_ages[e.id]=minf(1.0,float(death_ages.get(e.id,0))+delta);sprite.modulate.a=lerpf(1,.16,death_ages[e.id]);sprite.rotation=death_ages[e.id]*.22
	bodies[0].get_node("Art").modulate=Color(1,.7,.6) if r.invulnerable>0 and r.dash==0 else Color(1,1,1,.6) if r.dash>0 else Color.WHITE
	for f in floats:f.age+=delta;f.point.y-=delta*30
	for trail in ranged_trails:trail.age+=delta
	ranged_trails=ranged_trails.filter(func(trail):return trail.age<.22)
	floats=floats.filter(func(f):return f.age<.8)
	camera.position=camera.position.lerp(camera_target(),1-exp(-delta*7))
	if is_instance_valid(battle_feedback) and battle_feedback.hurt_flash>0 and not game.ui.reduce_motion and not game.view.low_quality:camera.position+=Vector2(sin(r.clock*.071),cos(r.clock*.053))*battle_feedback.hurt_flash*6
	hud_clock+=delta;save_clock+=delta
	if hud_clock>.2:hud_clock=0;refresh_hud()
	if save_clock>5:save_clock=0;game.checkpoint("adventure")
	var visible_world=Rect2(camera.position-get_viewport_rect().size/camera.zoom/2,get_viewport_rect().size/camera.zoom).grow(180)
	var dynamic=region=="ashen_desert" or r.enemies.any(func(e):return e.hp>0 and visible_world.has_point(Vector2(e.x,e.y))) or r.swing>0 or r.dash>0 or not floats.is_empty() or death_ages.values().any(func(age):return age<1)
	if (dynamic or effects_were_dynamic) and (region!="sanctuary" or last_effects_clock!=r.clock):effects.queue_redraw();last_effects_clock=int(r.clock)
	effects_were_dynamic=dynamic
	presentation_cpu_us+=Time.get_ticks_usec()-frame_started;presentation_steps+=1
func draw_effects(canvas: Node2D) -> void:
	for trail in ranged_trails:
		var head=trail.from.lerp(trail.to,clampf(trail.age/.16,0,1));var direction=(trail.to-trail.from).normalized();var color=Color(.6,.8,1,1-trail.age/.22);canvas.draw_line(head-direction*minf(36,head.distance_to(trail.from)),head,color,3,true);canvas.draw_circle(head,4,color)
	if not game:return
	var draw_started=Time.get_ticks_usec()
	var r=game.world.kingdom.adventure.run
	if region=="ashen_desert":
		for i in range(6):
			var p=Vector2(fmod(r.clock*.035+i*173,960),fmod(i*277+r.clock*.009,1440));canvas.draw_line(p,p+Vector2(18,3),Color(1,.88,.67,.28),2,true)
		canvas.draw_arc(Vector2(685,856),46+sin(r.clock*.002)*6,0,PI,24,Color(.8,1,.9,.6),2,true)
	if guide_point!=Vector2.ZERO:
		canvas.draw_arc(guide_point,50+sin(r.clock*.005)*5,0,TAU,32,Color("ffebac"),3,true)
		var direction=(guide_point-Vector2(r.x,r.y)).normalized();var p=Vector2(r.x,r.y)+direction*85;canvas.draw_line(p,p+direction*35,Color("ffe5a6"),5,true)
	for e in r.enemies:
		if e.hp<=0:continue
		var p=Vector2(e.x,e.y);var data=A.enemies()[e.kind]
		canvas.draw_rect(Rect2(p-Vector2(30,95),Vector2(60,6)),Color("203e3e"));canvas.draw_rect(Rect2(p-Vector2(30,95),Vector2(60*e.hp/float(data.health),6)),Color("d3d09c"))
		if e.state=="windup":
			if region=="sanctuary" and (e.kind=="sunward_warden" and e.pattern==1 or e.kind=="sun_shade" and e.pattern==0):
				var axis=(Vector2(e.aimx,e.aimy)-p).normalized();var width=36 if e.kind=="sunward_warden" else 24;var end=p+axis*(260 if e.kind=="sunward_warden" else 250)
				canvas.draw_line(p,end,Color(.95,.4,.25,.3),width*2,true);canvas.draw_line(p,end,Color("ead79b"),3,true);continue
			if e.kind=="thornheart" and e.pattern==0:
				var angle=(Vector2(e.aimx,e.aimy)-p).angle();var points=PackedVector2Array([p])
				for i in range(25):points.append(p+Vector2.from_angle(angle-1.21+i*2.42/24)*140)
				canvas.draw_colored_polygon(points,Color(.95,.38,.24,.3));canvas.draw_arc(p,140,angle-1.21,angle+1.21,32,Color("f3bb7b"),3,true);continue
			var root=e.kind=="thornheart" and e.pattern==1
			var warning=Vector2(e.aimx,e.aimy) if e.kind in ["spider","cave_stalker","ruin_sentinel","sun_shade"] or root else p;var radius=70 if e.kind=="sun_shade" else 65 if e.kind=="ruin_sentinel" else 55 if e.kind=="cave_stalker" else 60 if e.kind=="spider" else 85 if root else 145 if e.kind=="thornheart" else int(data.range)+12
			canvas.draw_circle(warning,radius,Color(.95,.38,.24,.25));canvas.draw_arc(warning,radius,0,TAU,40,Color("f3bb7b"),3,true)
	if r.swing>0:
		var p=Vector2(r.x,r.y);var angle=Vector2(r.facing[0],r.facing[1]).angle();canvas.draw_arc(p,65,angle-.9,angle+.9,20,Color("f8e3a7"),9,true)
	if r.dash>0:
		var heading=Vector2(r.facing[0],r.facing[1]).normalized()
		for i in range(1,4):canvas.draw_circle(Vector2(r.x,r.y)-heading*i*16,15-i*3,Color(.75,.9,.8,.5-i*.1))
	var closest_loot=0;var loot_distance=110.0
	for candidate in r.loot:
		if candidate.taken:continue
		var distance=Vector2(candidate.x,candidate.y).distance_to(Vector2(r.x,r.y))
		if distance<loot_distance:closest_loot=int(candidate.id);loot_distance=distance
	for l in r.loot:
		if not l.taken:
			var p=battle_feedback.loot_point(l) if is_instance_valid(battle_feedback) else Vector2(l.x,l.y);var color=Color("f3cf7f") if l.resource=="heart" else Color("9ed9d5") if not l.recipe.is_empty() else Color("c5d39c");canvas.draw_circle(p,11,color);canvas.draw_arc(p,18,0,TAU,24,color,2,true)
			canvas.draw_line(p,p-Vector2(0,48),Color(color,.18),9,true);canvas.draw_line(p,p-Vector2(0,48),Color(color,.7),2,true)
			canvas.draw_texture_rect(effect_textures.chest,Rect2(p-Vector2(12,20),Vector2(24,24)),false)
			if is_instance_valid(battle_feedback) and (battle_feedback.selected_loot==int(l.id) or battle_feedback.selected_loot==0 and closest_loot==int(l.id)):
				var title=battle_feedback.loot_name(l);canvas.draw_string_outline(game.ui.ui_font(),p-Vector2(75,53),title,HORIZONTAL_ALIGNMENT_CENTER,150,15,4,Color("10141c"));canvas.draw_string(game.ui.ui_font(),p-Vector2(75,53),title,HORIZONTAL_ALIGNMENT_CENTER,150,15,color)
			if l.resource=="heart":
				for i in range(6):canvas.draw_line(p+Vector2.from_angle(i*TAU/6)*23,p+Vector2.from_angle(i*TAU/6)*30,color,3,true)
	for f in floats:
		var color=Color(f.get("color",Color("ffe4a7")),clampf((.8-f.age)*3,0,1));var size=int(f.get("size",24));canvas.draw_string_outline(game.ui.ui_font(),f.point-Vector2(90,0),f.text,HORIZONTAL_ALIGNMENT_CENTER,180,size,4,Color(0,0,0,color.a));canvas.draw_string(game.ui.ui_font(),f.point-Vector2(90,0),f.text,HORIZONTAL_ALIGNMENT_CENTER,180,size,color)
	effect_draw_cpu_us+=Time.get_ticks_usec()-draw_started;effect_draws+=1
func draw_props(canvas: Node2D) -> void:
	var r=game.world.kingdom.adventure.run
	if region=="sanctuary":return
	if region=="ashen_desert":
		actors.get_node("deposit_crystal").get_child(0).modulate.a=.35 if r.nodes.crystal else 1.0
		for row in [[region_map.LANDMARK,say("Oasis · Inspect","Vaha · İncele")],[region_map.CRYSTAL,say("Crystal · Inspect","Kristal · İncele")],[region_map.ROAD,say("Ancient road","Kadim yol")]]:
			canvas.draw_arc(row[0],52,0,TAU,32,Color("b5e2c0"),2,true);canvas.draw_string(game.ui.ui_font(),row[0]+Vector2(-85,70),row[1],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff1c6"))
		return
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
	var before_feedback=battle_feedback.snapshot() if is_instance_valid(battle_feedback) else {}
	var result=A.interact(game.world,battle_feedback.selected_loot if is_instance_valid(battle_feedback) else 0)
	if is_instance_valid(battle_feedback):battle_feedback.resolve(before_feedback)
	if is_instance_valid(battle_feedback) and result in ["far","full"]:battle_feedback.announce(say("Approach the selected loot","Seçili ganimete yaklaş") if result=="far" else say("Bag / storage full · loot stays here","Çanta / depo dolu · ganimet burada kalır"))
	props.queue_redraw();effects.queue_redraw()
	if region=="sanctuary" and not result.is_empty() and result!="loot" and result!="full":
		var words={"inscription":say("Sunforged Dynasty: walk Sun then Moon. Inspect Sun → Moon → Star. The doors remember.","Güneşdövme Hanedanı: Güneş sonra Ay üzerine yürü. Güneş → Ay → Yıldız'ı incele. Kapılar hatırlar."),"lore":say("A broken forge: light once tempered metal. The dynasty vanished, its guardians stayed.","Kırık bir demirci: ışık bir zamanlar metali tavlardı. Hanedan kayboldu, muhafızları kaldı."),"secret":say("A hidden passage opens! The treasury is optional; your main route stays safe.","Gizli geçit açıldı! Hazine isteğe bağlı; ana yolun güvende."),"treasury":say("Ancient alloy revealed. Inspect the real loot to carry it home.","Kadim alaşım açığa çıktı. Eve taşımak için gerçek ganimeti İncele."),"switch":say("The symbol glows. Follow Sun → Moon → Star.","Simge parlıyor. Güneş → Ay → Yıldız sırasını izle."),"wrong_switch":say("The sequence resets safely. Sun → Moon → Star; try again.","Sıra güvenle sıfırlandı. Güneş → Ay → Yıldız; yeniden dene."),"runes_open":say("The rune door opens permanently. Beyond waits the Warden.","Rün kapısı kalıcı olarak açıldı. Ötede Muhafız bekliyor."),"relic":say("Ancient Sun Relic recovered! Return home, inspect it and unlock ancient forging.","Kadim Güneş Yadigârı alındı! Eve dön, incele ve kadim dövümü aç.")}
		message.text=words.get(result,result);game.audio.sanctuary("relic" if result in ["relic","treasury","secret"] else "switch");game.checkpoint("sanctuary");refresh_hud();return
	if result=="landmark":message.text=say("The Sunstone remembers your kingdom. Arin will want to hear this.","Güneştaşı krallığını hatırlıyor. Arin bunu duymak isteyecek.");game.audio.chime(6);game.checkpoint("landmark")
	elif result in ["oasis","oasis_heal","road","crystal"]:
		message.text={"oasis":say("Oasis found! Inspect again when hurt: one recovery, saved permanently.","Vaha bulundu! Yaralıyken yeniden İncele: kayıtlı, tek iyileşme."),"oasis_heal":say("The oasis restores 35 health and clears poison. Its blessing is spent.","Vaha 35 can yeniler ve zehri temizler. Kutsaması tükendi."),"road":say("The ancient road once carried glass and metal. Recorded in the chronicle.","Kadim yol bir zamanlar cam ve metal taşıyordu. Tarihçeye kaydedildi."),"crystal":say("+6 Desert Crystal. Return home and register one with Arin; the rest can make purifying tonics.","+6 Çöl Kristali. Eve dön, birini Arin'e kaydet; kalanıyla arındırıcı iksir üret.")}[result];game.audio.chime(6);game.checkpoint("desert-discovery")
	elif result=="mine":message.text=say("Forgotten Mine discovered. Its last miners left rails pointing home. Recorded in the chronicle.","Unutulmuş Maden keşfedildi. Son madenciler eve uzanan raylar bıraktı. Tarihçeye kaydedildi.");game.audio.chime(6);game.checkpoint("forgotten-mine")
	elif result=="mineral":message.text=say("Mineral gathered · finite vein. Return home to smelt ore or build with stone.","Maden toplandı · damar sınırlı. Cevheri eritmek veya taşla inşa etmek için eve dön.");game.audio.chime(5);game.checkpoint("mineral")
	elif result=="full":message.text=say("Storage is full. Loot stays here; return home to use materials or equipment.","Depo dolu. Ganimet burada kalır; malzeme veya donanımı kullanmak için eve dön.")
	elif result=="far":message.text=say("Move closer to the selected loot.","Seçili ganimete yaklaş.")
	elif not result.is_empty():message.text=say("Collected · loot stays yours when you return. Herbs can heal (F).","Toplandı · döndüğünde ganimet senin. Bitkiler iyileştirir (F).");game.audio.chime(5);game.checkpoint("loot")
	if result=="loot":
		for l in game.world.kingdom.adventure.run.loot:
			if l.taken and not before.has(l.id):message.text="+ "+(game.realm_ui.cost({l.resource:l.amount}) if l.recipe.is_empty() else game.realm_ui.localized(preload("res://scripts/industry.gd").recipes()[l.recipe].name))+say(" · Safe when you return home."," · Eve döndüğünde depolanır.")
	refresh_hud()
func guide() -> void:
	var r=game.world.kingdom.adventure.run
	if region=="sanctuary":
		guide_point=region_map.INSCRIPTION if not r.landmark else region_map.PLATES[mini(1,int(r.mechanisms.plates))] if r.mechanisms.plates<2 else region_map.SWITCHES[mini(2,int(r.mechanisms.switches))] if r.mechanisms.switches<3 else Vector2(570,270) if preload("res://scripts/sanctuary.gd").progress(game.world,"warden")==0 else region_map.RELIC if preload("res://scripts/sanctuary.gd").progress(game.world,"relic")==0 else region_map.START
		message.text=sanctuary_hint();return
	if not r.landmark:guide_point=region_map.LANDMARK;message.text=say("Follow the gold arrow to the oasis.","Altın oku izleyerek vahaya ulaş.")
	elif not game.world.kingdom.adventure.regions.quest.kill:
		for e in r.enemies:
			if e.hp>0:guide_point=Vector2(e.x,e.y);break
		message.text=say("Read the warning and dodge. Strike while the enemy recovers.","Uyarıyı izle ve kaçın. Düşman dinlenirken vur.")
	elif not game.world.kingdom.adventure.regions.quest.picked:guide_point=region_map.CRYSTAL;message.text=say("Inspect the crystal vein; keep space in your warehouse.","Kristal damarını incele; depoda yer bırak.")
	else:guide_point=region_map.START;message.text=say("Use Home to bank loot, then register one crystal with Arin.","Dön ile ganimeti depola; sonra Arin'e bir kristal kaydet.")
func sanctuary_hint() -> String:
	var r=game.world.kingdom.adventure.run
	if not r.landmark:return say("SUNKEN SANCTUARY · Inspect the inscription.\nWarnings mean danger; Home is always safe.","BATIK TAPINAK · Yazıtı incele.\nUyarı tehlikedir; Dön her zaman güvenli.")
	if r.mechanisms.plates<2:return say("Trial of Stone · Walk on Sun, then Moon.\nRead the floor's trap warnings before crossing.","Taş Sınavı · Güneş, sonra Ay üzerine yürü.\nGeçmeden önce zemindeki tuzak uyarısını izle.")
	if r.mechanisms.switches<3:return say("Guardians' Hall · Inspect Sun → Moon → Star.\nDodge attacks, strike in recovery windows.","Muhafızlar Salonu · Güneş → Ay → Yıldız'ı incele.\nSaldırıdan kaç, dinlenme aralığında vur.")
	if preload("res://scripts/sanctuary.gd").progress(game.world,"relic")==1:return say("Sun Relic recovered · Return home.\nInspect the relic to unlock ancient forging.","Güneş Yadigârı alındı · Eve dön.\nKadim dövümü açmak için yadigârı incele.")
	if preload("res://scripts/sanctuary.gd").progress(game.world,"warden")==1:return say("The relic chamber is open · Inspect its pedestal.","Yadigâr odası açıldı · Kaideyi incele.")
	return say("Sun Relic Chamber · Defeat the Warden.\nRecover the relic, return and inspect it at home.","Güneş Yadigârı Odası · Muhafız'ı yen.\nYadigârı al, dön ve evde incele.")
func toggle_pack() -> void:
	if is_instance_valid(pack_panel):pack_panel.queue_free();pack_panel=null;frozen=pack_was_frozen;clear_combat_input();return
	pack_was_frozen=frozen;frozen=true;clear_combat_input()
	pack_panel=PanelContainer.new();pack_panel.add_theme_stylebox_override("panel",ruin_style());place(pack_panel,Rect2(100,250,520,410));var list=VBoxContainer.new();pack_panel.add_child(list)
	var stats=H.stats(game.world);var r=game.world.kingdom.adventure.run
	list.add_child(game.ui.label(say("Expedition pack · paused","Sefer çantası · duraklatıldı"),24))
	list.add_child(game.ui.label(game.realm_ui.cost(r.cargo)+"\n"+say("Attack / defense / trap resistance: ","Saldırı / savunma / tuzak direnci: ")+str(stats.attack)+" / "+str(stats.defense)+" / "+str(stats.hazard_resist)+"\n"+str(game.world.kingdom.industry.items.size())+" / 32",20))
	var close=game.ui.button(say("Close pack","Çantayı kapat"),toggle_pack,true);list.add_child(close)
func go_home() -> void:
	var paused=game.world.kingdom.adventure.run.home_paused
	if not A.exit(game.world):return
	clear_combat_input()
	game.adventure_scene=null;game.paused=paused;game.show_world(true);game.ui.layer=1;game.ui.root.show();game.ui.close();game.ui.refresh();game.checkpoint("return-home");queue_free()
