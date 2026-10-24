extends SceneTree
const A=preload("res://scripts/adventure.gd")
const V=preload("res://scripts/warrior_visual.gd")
var checks={}
var v
var w
func _initialize():call_deferred("run")
func step(command={},mover=Callable()):
 var result=A.step(w,command,mover);var before=w.duplicate(true);v.sample(w,result);checks.visual_never_changes_model=checks.get("visual_never_changes_model",true) and w==before
 return result
func run():
 var p=preload("res://scripts/hero_progression_probe.gd").new();checks.legal_world=p.armed(7);w=p.world;checks.entry=A.enter(w)
 v=V.new();root.add_child(v);v.sample(w);var r=w.kingdom.adventure.run;var h=w.kingdom.adventure.hero
 checks.resources_cached=V.resources()==V.resources()
 var total=0
 for name in V.frames.get_animation_names():total+=V.frames.get_frame_count(name)
 checks.all_atlas_frames=total==144
 checks.weapon_ownership=v.sword_recipe=="iron_sword"
 checks.empty_shield_hidden=v.shield_recipe.is_empty()
 step({"move":Vector2.RIGHT});checks.walk=v.state=="walk"
 step({"move":Vector2.RIGHT},func(_id,pos,_delta):return pos);checks.blocked_motion_is_idle=v.state=="idle"
 var visual_before=[v.state,v.frame_index,v.state_age,v.gait_distance];v.sample(w);checks.same_clock_is_stable=visual_before==[v.state,v.frame_index,v.state_age,v.gait_distance]
 for row in [[Vector2.DOWN,0],[Vector2.RIGHT,1],[Vector2.UP,2],[Vector2.LEFT,3]]:
  step({"move":row[0]});checks["direction_"+str(row[1])]=v.view_direction==row[1]
 step({"attack":true,"aim":Vector2.RIGHT});checks.attack_contact_not_late_windup=v.state=="attack" and v.frame_index==2
 for i in range(10):step()
 checks.attack_end=v.state=="idle"
 step({"dodge":true,"move":Vector2.LEFT});checks.dodge_priority=v.state=="dodge" and r.invulnerable>0
 var hp=h.hp;checks.model_dodge_blocks_damage=not A.hurt(w,50) and h.hp==hp
 for i in range(8):step()
 A.hurt(w,20);step();checks.hit_reaction=v.state=="hit"
 var invulnerable=r.invulnerable
 for i in range(3):step()
 checks.reaction_does_not_extend_invulnerability=r.invulnerable==maxi(0,invulnerable-150)
 for i in range(4):step()
 checks.hit_ends=v.state=="idle"
 var ro=w.duplicate(true);ro._read_only=true;var before=ro.duplicate(true);v.sample(ro);checks.readonly_rendering=ro==before
 checks.compatible_save=Persistence.save_world(w,"user://v4-presentation-private.json") and Persistence.load_world("user://v4-presentation-private.json").kingdom==w.kingdom
 A.hurt(w,9999);step({"attack":true,"dodge":true});checks.death_overrides_input=v.state=="defeat" and h.defeated
 for i in range(20):step({"attack":true,"move":Vector2.RIGHT})
 checks.final_defeat_frame=v.frame_index==5 and v.state=="defeat"
 checks.model_still_valid=Persistence.validate(w)
 checks.exit=A.exit(w)
 var report={"checks":checks,"all_passed":not checks.values().has(false)}
 var f=FileAccess.open("res://builds/visual-v4/presentation.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close();print("V4_PRESENTATION ",report);v.queue_free();await process_frame;quit(0 if report.all_passed else 1)
