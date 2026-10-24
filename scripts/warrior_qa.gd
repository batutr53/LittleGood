extends Node
var game
var host
var scene
var observed={}
var frames_seen={}
func _process(_delta):
 if is_instance_valid(scene) and is_instance_valid(scene.warrior_visual):
  observed[scene.warrior_visual.state]=true
  if scene.warrior_visual.state=="walk":frames_seen[scene.warrior_visual.frame_index]=true
func marker(name):
 while not FileAccess.file_exists("user://"+name):await get_tree().process_frame
func stage(name,id=""):
 var extra={}
 if not id.is_empty():extra.touch=host.point(scene.buttons[id])
 host.publish(name,extra);await marker(name)
func run():
 game.save_path="user://v4-qa-private.json";game.is_test_session=true;game.ui.language="tr";game.view.set_quality(int(host.options.get("fps",60))==30)
 if host.options.phase in ["warrior_v4","warrior_v4_profile"]:
  var p=preload("res://scripts/hero_progression_probe.gd").new();host.checks.legal_armed=p.armed(42);game.world=p.world
 else:
  game.world=Persistence.load_world(game.save_path)
  host.checks.restored=not game.world.is_empty() and Persistence.validate(game.world)
  var expected=Persistence.load_world("user://v4-qa-expected-world.json")
  host.checks.exact_state=not expected.is_empty() and game.world.kingdom==expected.kingdom
 game.view.world=game.world;game.has_player_world=true;game.paused=true;game.in_menu=false
 game.v4_preview=bool(host.options.get("preview",true))
 host.checks.entry=game.enter_adventure("wildwood");scene=game.adventure_scene;scene.controlled=true
 host.checks.preview=is_instance_valid(scene.warrior_visual)
 if host.options.phase=="warrior_v4_profile":
  await get_tree().create_timer(2).timeout
  var samples=[];var deadline=Time.get_ticks_msec()+10000
  while Time.get_ticks_msec()<deadline and samples.size()<180:
   var t=Time.get_ticks_usec();await get_tree().process_frame;samples.append((Time.get_ticks_usec()-t)/1000.0)
  var metrics={"fps":1000.0/(samples.reduce(func(a,b):return a+b,0.0)/samples.size()),"frames":samples.size(),"static_memory_bytes":OS.get_static_memory_usage(),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"combat_cpu_us_per_tick":scene.combat_cpu_us/maxi(1,scene.physics_steps),"presentation_cpu_us_per_frame":scene.presentation_cpu_us/maxi(1,scene.presentation_steps)};samples.sort();metrics.p95_ms=samples[int(samples.size()*.95)]
  host.publish("v4_profile",{"preview":game.v4_preview,"metrics":metrics});return
 if host.options.phase=="warrior_v4_reopen":
  host.checks.weapon_restored=not scene.warrior_visual.sword_recipe.is_empty()
  await get_tree().create_timer(.3).timeout;await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://v4-restored.png")
  host.publish("v4_reopened",{"all_passed":not host.checks.values().has(false)});return
 await get_tree().create_timer(2).timeout
 var r=game.world.kingdom.adventure.run;var x=r.x
 host.publish("v4_move",{"stick":[scene.stick.position.x,scene.stick.position.y]});await marker("v4_move")
 host.checks.native_move=r.x>x+15 and scene.action_counts.get("drag",0)>0
 host.checks.walk_cycle=observed.has("walk") and frames_seen.size()>=3
 host.checks.no_touchthrough=scene.action_counts.get("attack",0)==0
 # QA fixture positioning only: actual movement test above; real enemy/damage rules below.
 scene.frozen=true;var e=r.enemies[0];r.x=e.x-60;r.y=e.y;scene.bodies[0].position=Vector2(r.x,r.y);scene.camera.position=scene.camera_target();var hp=e.hp
 await stage("v4_attack","attack");scene.frozen=false;await get_tree().create_timer(.4).timeout
 host.checks.native_attack=scene.action_counts.get("attack",0)>0 and e.hp<hp and observed.has("attack")
 await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://v4-combat.png")
 await stage("v4_dodge","dodge");await get_tree().create_timer(.35).timeout
 host.checks.native_dodge=scene.action_counts.get("dodge",0)>0 and observed.has("dodge")
 await stage("v4_pause","pause");await get_tree().create_timer(.1).timeout
 host.checks.pause_clears=scene.frozen and not scene.attack_held and scene.actions.is_empty() and scene.movement==Vector2.ZERO and scene.stick.vector==Vector2.ZERO and scene.stick_index==-1
 await stage("v4_resume","pause");await get_tree().create_timer(.15).timeout
 host.checks.resumed=not scene.frozen
 # Bounded idle/walk sampling, not a boss-combat performance claim.
 r.x=240;r.y=1260;scene.bodies[0].position=Vector2(r.x,r.y);var samples=[]
 for i in range(120):
  scene.movement=Vector2.RIGHT if i%60<30 else Vector2.LEFT
  var t=Time.get_ticks_usec();await get_tree().process_frame;samples.append((Time.get_ticks_usec()-t)/1000.0)
 scene.movement=Vector2.ZERO;scene.frozen=true
 var metrics={"fps":1000.0/(samples.reduce(func(a,b):return a+b,0.0)/samples.size()),"static_memory_bytes":OS.get_static_memory_usage(),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"combat_cpu_us_per_tick":scene.combat_cpu_us/maxi(1,scene.physics_steps),"presentation_cpu_us_per_frame":scene.presentation_cpu_us/maxi(1,scene.presentation_steps)};samples.sort();metrics.p95_ms=samples[int(samples.size()*.95)]
 host.checks.saved=Persistence.save_world(game.world,game.save_path)
 host.checks.expected_saved=Persistence.save_world(game.world,"user://v4-qa-expected-world.json")
 var f=FileAccess.open("user://v4-qa-expected.json",FileAccess.WRITE);f.store_string(JSON.stringify(game.world.kingdom));f.close()
 await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png("user://v4-walk.png")
 host.publish("v4_saved",{"all_passed":not host.checks.values().has(false),"metrics":metrics,"scope":"V4B warrior; native ADB input; fixture positioning for contact; idle/walk metrics"})
