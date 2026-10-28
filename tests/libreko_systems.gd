extends SceneTree
const R=preload("res://scripts/rpg_progression.gd")
const A=preload("res://scripts/adventure.gd")
const F=preload("res://scripts/armory.gd")
const Q=preload("res://scripts/quest_targets.gd")
const C=preload("res://scripts/combat_rules.gd")
var checks={}
func _initialize():call_deferred("run")
func world():
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");load("res://scripts/estate.gd").start(w);R.ensure(w);F.ensure(w);return w
func add_item(w,recipe):
	var i=w.kingdom.industry;var id=int(i.next_item);i.next_item+=1;i.items.append({"id":id,"recipe":recipe});return id
func run():
	var base=world();checks.old_fixture=Persistence.validate(base)
	for cls in R.CLASSES:
		for index in range(6):
			var w=base.duplicate(true);R.switch(w,cls);var h=w.kingdom.adventure.hero;h.xp=6000;A.enter(w);var p=R.selected(w);p.skills[index]=1;p.bar[0]=index;p.mana=100;p.cooldowns=[0,0,0,0,0,0];h.cooldowns.skill=0;h.hp=20
			var before=JSON.stringify(w);var spec=R.skill_definition(cls,index);checks[cls+str(index)+"_definition"]=spec.target in ["enemy","area","self"] and int(spec.mana)==12+index*3 and JSON.stringify(w)==before
			var ctx=R.attack_context(w,{"skill":true});checks[cls+str(index)+"_cost"]=p.mana==100-int(spec.mana) and p.cooldowns[index]==int(spec.cooldown_ms)
			checks[cls+str(index)+"_effects"]=ctx.area==spec.area and (not spec.guard or p.guard_ms==3500) and (not spec.dash or w.kingdom.adventure.run.dash==250) and (int(spec.heal_base)==0 or h.hp>20) and (not spec.pierce or ctx.get("pierce",false))
			before=JSON.stringify(w);checks[cls+str(index)+"_no_double_cast"]=not R.attack_context(w,{"skill":true}).cast and JSON.stringify(w)==before
	var w=base.duplicate(true);A.enter(w);var r=w.kingdom.adventure.run;var h=w.kingdom.adventure.hero;var p=R.selected(w);r.enemies=A.new_enemies();r.x=550;r.y=1120;var e=r.enemies[0];e.x=900;e.y=1120;p.skills[0]=0;p.bar[0]=0;p.mana=60;p.cooldowns=[0,0,0,0,0,0];h.cooldowns.skill=0;h.cooldowns.attack=0
	var before=JSON.stringify(w);checks.read_only_reach=C.check(w,{"target_id":1,"skill":true})=="range" and JSON.stringify(w)==before
	var rng=r.rng;var cues=A.step(w,{"target_id":1,"skill":true});checks.rejected_skill_no_cost=cues.has("reject_range") and not cues.has("swing") and p.mana>=60 and p.cooldowns[0]==0 and h.cooldowns.attack==0 and r.rng==rng
	checks.missing_target=C.check(w,{"target_id":999})=="target";e.hp=0;e.state="dead";checks.dead_target=C.check(w,{"target_id":1})=="target";e.hp=32;e.state="idle";e.x=605;checks.in_reach=C.check(w,{"target_id":1})==""
	var rect=load("res://scripts/wildwood_map.gd").solids(false)[0];r.x=roundi(rect.position.x-10);r.y=roundi(rect.get_center().y);e.x=roundi(rect.end.x+10);e.y=r.y
	R.selected(w).specialization="warrior";checks.obstacle_or_range=C.check(w,{"target_id":1}) in ["range","obstacle"]
	# Starter cooldown advances with simulation time even while the button is held.
	r.enemies=[];h.cooldowns.skill=0;p.cooldowns=[0,0,0,0,0,0];p.mana=100;var swings=0
	for tick in range(81):
		if A.step(w,{"skill":true}).has("swing"):swings+=1
	checks.held_starter_recovers=swings==2
	w=base.duplicate(true);var weapon=add_item(w,"iron_sword");var first_scroll=add_item(w,F.scroll_recipe("normal"));add_item(w,F.scroll_recipe("normal"));w.kingdom.stock.iron=50000;w.kingdom.stock.gold=50000;var quote=F.quote(w,weapon,"normal")
	checks.quote_available=not quote.is_empty();var forged=quote.duplicate(true);forged.cost.gold=0;before=JSON.stringify(w);checks.tampered_quote=F.attempt_quote(w,forged).is_empty() and JSON.stringify(w)==before
	R.discard(w,first_scroll);before=JSON.stringify(w);checks.replaced_scroll_rejected=F.attempt_quote(w,quote).is_empty() and JSON.stringify(w)==before
	quote=F.quote(w,weapon,"normal");var response=F.attempt_quote(w,quote);checks.review_commit=not response.is_empty() and response.success
	before=JSON.stringify(w);checks.review_no_replay=F.attempt_quote(w,quote).is_empty() and JSON.stringify(w)==before
	checks.review_save=Persistence.save_world(w,"user://systems-quote-private.json") and Persistence.load_world("user://systems-quote-private.json").armory==w.armory
	w=base.duplicate(true);w.armory.kills={};w.armory.claims=[];before=JSON.stringify(w);var goals=Q.for_enemy(w,"wolf");checks.kill_goal=goals.size()==1 and goals[0].key=="hunt" and goals[0].have==0 and goals[0].need==2;checks.goal_read_only=JSON.stringify(w)==before
	w.armory.kills.wolf=1;checks.progress_join=Q.for_enemy(w,"thorn")[0].have==1;checks.unrelated_enemy=Q.for_enemy(w,"spider").is_empty()
	w.armory.kills.thorn=1;checks.ready_once=Q.ready(w).has("hunt") and Q.for_enemy(w,"wolf").is_empty();w.armory.claims.append("hunt");checks.claimed_not_tracked=not Q.ready(w).has("hunt")
	w.armory.kills={};w.kingdom.stock.leather=0;goals=Q.for_enemy(w,"wolf","leather_armor");checks.missing_recipe_safe=Q.for_enemy(w,"wolf","not_a_recipe").is_empty()
	# Select a real recipe/resource pair from definitions rather than fabricated loot.
	var recipes=load("res://scripts/industry.gd").recipes();var material_case=false
	for recipe in recipes:
		for resource in recipes[recipe].cost:
			w.kingdom.stock[resource]=0
		for kind in A.enemies():
			var matches=Q.for_enemy(w,kind,recipe).filter(func(row):return not row.resource.is_empty())
			if matches.is_empty():continue
			var row=matches[0];checks.actual_material_drop=row.chance_bp>0 and row.need==int(recipes[recipe].cost[row.resource]);w.kingdom.adventure.run={"cargo":{row.resource:int(row.need)}};checks.cargo_counts=Q.for_enemy(w,kind,recipe).all(func(g):return g.resource!=row.resource);material_case=true;break
		if material_case:break
	checks.material_case_exists=material_case
	DirAccess.make_dir_recursive_absolute("res://builds/libreko-systems");var result={"count":checks.size(),"all_passed":not checks.values().has(false),"checks":checks};var file=FileAccess.open("res://builds/libreko-systems/model.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));print("LIBREKO_SYSTEMS "+JSON.stringify(result));quit(0 if result.all_passed else 1)
