extends SceneTree
const A=preload("res://scripts/adventure.gd")
const V=preload("res://scripts/warrior_visual.gd")
var game
var scene
var visual
var checks={}
var samples=[]
var evidence=[]
func _initialize():call_deferred("run")
func shot(name):
 scene.camera.position=scene.camera_target();scene.refresh_hud();scene.effects.queue_redraw()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/screenshots/visual-v4/"+name+".png")
 var r=game.world.kingdom.adventure.run
 evidence.append({"image":name+".png","clock_ms":r.clock,"state":visual.state,"frame":visual.frame_index,"direction":visual.view_direction,"hero_hp":game.world.kingdom.adventure.hero.hp,"sword_socket":[visual.socket("sword").x,visual.socket("sword").y]})
func advance(command={}):
 var feedback=A.step(game.world,command,scene.move_body)
 var r=game.world.kingdom.adventure.run;scene.bodies[0].position=Vector2(r.x,r.y)
 visual.sample(game.world,feedback)
 for e in r.enemies:scene.bodies[int(e.id)].position=Vector2(e.x,e.y)
 scene.effects.queue_redraw()
 return feedback
func run():
 game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.v4_preview=true;game.save_path="user://v4-rendered-private.json";root.add_child(game);current_scene=game
 var p=preload("res://scripts/hero_progression_probe.gd").new();checks.legal_armed_world=p.armed();game.world=p.world
 var forge=p.world.kingdom.buildings.filter(func(b):return b.kind=="forge")[0]
 checks.shield_materials=p.base.wait_stock("iron",2) and p.base.wait_stock("wood",2)
 checks.shield_crafted=preload("res://scripts/industry.gd").queue(p.world,"reinforced_shield",int(forge.id))
 for i in range(20):p.base.driver.step()
 var shields=p.world.kingdom.industry.items.filter(func(item):return item.recipe=="reinforced_shield")
 checks.shield_equipped=not shields.is_empty() and preload("res://scripts/hero.gd").equip(p.world,"shield",int(shields[0].id))
 game.view.world=game.world;game.has_player_world=true;game.paused=true;game.ui.language="tr";checks.entry=game.enter_adventure()
 scene=game.adventure_scene;scene.controlled=true;scene.frozen=true;visual=scene.warrior_visual
 var w=game.world;var r=w.kingdom.adventure.run;var h=w.kingdom.adventure.hero
 checks.preview_only=visual!=null and not scene.bodies[0].get_node("Art").visible
 var before=w.duplicate(true);visual.sample(w);checks.no_authority=w==before
 checks.all_144_frames=V.frames.get_animation_names().size()==24 and V.poses.states.size()==6
 checks.real_equipment=not visual.sword_recipe.is_empty() and not visual.shield_recipe.is_empty()
 advance({"move":Vector2.DOWN});advance();checks.idle=visual.state=="idle"
 await shot("after-idle")
 var frames_seen=[]
 for i in range(8):
  advance({"move":Vector2.RIGHT});frames_seen.append(visual.frame_index)
  await shot("walk-cycle-"+str(i))
  if i==3:await shot("walk-east")
 checks.foot_cycle=frames_seen.size()==8 and frames_seen.min()!=frames_seen.max()
 for pair in [[Vector2.LEFT,3,"walk-west"],[Vector2.UP,2,"walk-north"],[Vector2.DOWN,0,"walk-south"]]:
  advance({"move":pair[0]});checks[pair[2]]=visual.state=="walk" and visual.view_direction==pair[1];await shot(pair[2])
 var held=visual.frame_index;visual.sample(w);checks.same_clock_stable=visual.frame_index==held
 for i in range(4):advance({"move":Vector2.ZERO})
 checks.blocked_idle=visual.state=="idle"
 # Real model miss at spawn: only swing cue, no damage cue or reward.
 var kills=w.kingdom.adventure.events.get("kills",0);var feedback=advance({"attack":true,"aim":Vector2.RIGHT})
 checks.miss=feedback.has("swing") and not feedback.any(func(c):return c is Dictionary) and w.kingdom.adventure.events.get("kills",0)==kills
 checks.contact_pose_at_model_contact=visual.state=="attack" and visual.frame_index==2
 visual.debug_enabled=true;visual.queue_redraw();await shot("attack-contact-debug")
 for i in range(3):advance();await shot("attack-follow-"+str(i))
 for i in range(7):advance()
 checks.attack_recovers=visual.state=="idle"
 # Diagnostic fixture placement, not campaign progression. Existing real hit rules.
 var enemy=r.enemies[0];r.x=enemy.x-60;r.y=enemy.y;scene.bodies[0].position=Vector2(r.x,r.y)
 var enemy_hp=enemy.hp;feedback=advance({"attack":true,"aim":Vector2.RIGHT})
 checks.real_hit=enemy.hp<enemy_hp and feedback.any(func(c):return c is Dictionary) and visual.damage_contacts.size()==1
 await shot("actual-hit-debug")
 for i in range(12):advance()
 r.x=240;r.y=1260;scene.bodies[0].position=Vector2(r.x,r.y)
 advance({"dodge":true,"move":Vector2.LEFT});checks.dodge=visual.state=="dodge" and r.invulnerable>0
 await shot("dodge")
 for i in range(8):advance()
 var hp=h.hp;A.hurt(w,20);advance();checks.hit_reaction=h.hp<hp and visual.state=="hit"
 await shot("hit-reaction")
 for i in range(6):advance()
 checks.hit_recovers=visual.state=="idle"
 checks.exact_save=Persistence.save_world(w,game.save_path) and Persistence.load_world(game.save_path).kingdom==w.kingdom
 var restored=V.new();scene.bodies[0].add_child(restored);restored.hide();restored.sample(Persistence.load_world(game.save_path));checks.equipment_restore=restored.sword_recipe==visual.sword_recipe and restored.shield_recipe==visual.shield_recipe;restored.queue_free()
 # Actual scene scheduler and CharacterBody2D movement, with regular input path.
 scene.frozen=false;scene.movement=Vector2.UP
 var start_y=r.y;var start_clock=r.clock
 for i in range(30):await physics_frame
 checks.actual_scheduler=r.clock>start_clock and r.y<start_y and visual.state=="walk"
 scene.movement=Vector2.ZERO
 await create_timer(.15).timeout
 for i in range(120):
  var started=Time.get_ticks_usec();await process_frame;samples.append((Time.get_ticks_usec()-started)/1000.0)
 checks.idle_after_release=visual.state=="idle"
 scene.movement=Vector2.RIGHT;scene.attack_held=true;scene.actions.attack=true;scene.stick.vector=Vector2.RIGHT;scene.stick_index=4;scene.toggle_pause()
 checks.pause_releases_visual_stick=scene.frozen and scene.stick.vector==Vector2.ZERO and scene.stick_index==-1 and not scene.attack_held and scene.actions.is_empty()
 scene.toggle_pause()
 scene.attack_held=true;scene.movement=Vector2.RIGHT;scene.actions.attack=true;scene.stick_index=3
 var cancel=InputEventScreenTouch.new();cancel.index=3;cancel.canceled=true;scene._input(cancel)
 checks.cancel_releases_input=not scene.attack_held and scene.actions.is_empty() and scene.movement==Vector2.ZERO and scene.stick_index==-1
 scene.attack_held=true;scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 checks.focus_loss_releases_input=not scene.attack_held
 scene.attack_held=true;game.suspended=true;scene._physics_process(.016);game.suspended=false
 checks.suspend_releases_input=not scene.attack_held
 scene.frozen=true
 var stats={"fps":1000.0/(samples.reduce(func(a,b):return a+b,0.0)/samples.size()),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory_bytes":OS.get_static_memory_usage(),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)};samples.sort();stats.p95_ms=samples[int(samples.size()*.95)]
 # Fixture-only lethal damage checks priority and final stable defeat pose.
 for i in range(6):advance()
 A.hurt(w,9999);advance({"attack":true});checks.defeat_priority=visual.state=="defeat" and h.defeated
 for i in range(12):advance({"attack":true})
 checks.defeat_stable=visual.state=="defeat" and visual.frame_index==5
 await shot("defeat")
 checks.valid_world=Persistence.validate(w)
 scene.go_home();await process_frame;checks.clean_exit=not is_instance_valid(game.adventure_scene)
 var report={"checks":checks,"all_passed":not checks.values().has(false),"desktop":stats,"frame_evidence":evidence,"scope":"V4B opt-in warrior; deterministic helper shots plus actual scene scheduler; no Android verification"}
 var f=FileAccess.open("res://builds/visual-v4/rendered.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("V4_RENDERED ",report)
 quit(0 if report.all_passed else 1)
