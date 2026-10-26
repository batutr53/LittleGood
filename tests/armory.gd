extends SceneTree
const F=preload("res://scripts/armory.gd")
const I=preload("res://scripts/industry.gd")
const R=preload("res://scripts/rpg_progression.gd")
const H=preload("res://scripts/hero.gd")
const A=preload("res://scripts/adventure.gd")
var checks={}
func _initialize():call_deferred("run")
func supply(w: Dictionary,mode: String):
	var recipe=F.scroll_recipe(mode)
	if F.scroll_item(w,mode)>0:return
	var id=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":id,"recipe":recipe})
func run():
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");R.ensure(w);F.ensure(w)
	var original=w.kingdom.industry.items.duplicate(true);var weapon=w.kingdom.industry.items.filter(func(item):return item.recipe=="iron_sword")[0];var id=int(weapon.id)
	checks.additive=Persistence.validate(w) and original==w.kingdom.industry.items
	checks.legacy_victories_credited=int(w.armory.kills.get("wolf",0))==1
	var once=JSON.stringify(w.armory);F.ensure(w);checks.idempotent=once==JSON.stringify(w.armory)
	for key in w.kingdom.stock:w.kingdom.stock[key]=50000
	checks.grade_middle=F.grade("rpg_mage_weapon")=="middle"
	checks.grade_high=F.grade("ancient_blade")=="high"
	checks.grade_unique=F.grade("legend_priest_weapon")=="unique"
	supply(w,"normal");var q=F.quote(w,id,"normal");checks.quote=q.chance_bp==10000 and q.after.normal==1 and q.before.normal==0
	var stock=w.kingdom.stock.duplicate();var result=F.attempt(w,id,"normal",int(q.serial))
	checks.upgrade_success=result.success and F.state(w,id).normal==1
	checks.costs=w.kingdom.stock.iron==stock.iron-1000 and w.kingdom.stock.gold==stock.gold-1000
	checks.stats=I.effects(w,weapon).attack==int(I.recipes()[weapon.recipe].effects.attack)+1
	checks.no_replay=F.attempt(w,id,"normal",int(q.serial)).is_empty() and F.state(w,id).normal==1
	checks.baseline_item_preserved=original==w.kingdom.industry.items
	R.lock_item(w,id);stock=w.kingdom.stock.duplicate();checks.lock_protected=F.quote(w,id,"normal").is_empty() and F.attempt(w,id,"normal",int(w.armory.serial)).is_empty() and stock==w.kingdom.stock;R.lock_item(w,id)
	supply(w,"normal");w.kingdom.stock.gold=0;var serial=int(w.armory.serial);checks.insufficient_atomic=F.attempt(w,id,"normal",serial).is_empty() and serial==int(w.armory.serial);w.kingdom.stock.gold=50000
	checks.no_middle_rebirth=F.quote(w,id,"reverse").is_empty()
	var next=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;var unique={"id":next,"recipe":"legend_warrior_weapon"};w.kingdom.industry.items.append(unique)
	w.armory.items[str(next)]={"normal":7,"rebirth":0,"element":"none"}
	var before=I.effects(w,unique).attack;q=F.quote(w,next,"reverse");checks.reverse_quote=q.chance_bp==10000 and q.after.rebirth==1
	supply(w,"reverse");result=F.attempt(w,next,"reverse",int(w.armory.serial));checks.reverse_stats_preserved=result.success and F.state(w,next).rebirth==1 and I.effects(w,unique).attack==before
	checks.no_second_reverse=F.quote(w,next,"reverse").is_empty()
	checks.no_normal_after_reverse=F.quote(w,next,"normal").is_empty()
	var failed=false;var success=false
	for attempt in range(30):
		for key in ["iron","gold"]:w.kingdom.stock[key]=50000
		supply(w,"rebirth");var previous=F.state(w,next).duplicate();result=F.attempt(w,next,"rebirth",int(w.armory.serial))
		if not result.success:failed=true;checks.failure_keeps_item=F.state(w,next)==previous and not I.item(w,next).is_empty();checks.failure_consumes_scroll=F.scroll_item(w,"rebirth")==0
		else:success=true
	checks.rebirth_success_and_failure=failed and success
	checks.rng_saved=F.validate(w)
	w.armory.items[str(next)]={"normal":8,"rebirth":5,"element":"none"};before=I.effects(w,unique).attack
	supply(w,"element");checks.element=F.attempt(w,next,"element",int(w.armory.serial),"fire").success and I.effects(w,unique).attack==before+2
	checks.glow=F.glow(w,next).strength==.55 and F.glow(w,next).color==Color("ff9251")
	w.armory.items[str(next)]={"normal":10,"rebirth":21,"element":"fire"};checks.cap=F.quote(w,next,"rebirth").is_empty() and F.glow(w,next).strength==1
	checks.invalid_element=F.quote(w,next,"element","invented").is_empty()
	checks.item_name=F.label(w,unique).contains("REB +21")
	checks.save=Persistence.save_world(w,"user://armory-test.json");var loaded=Persistence.load_world("user://armory-test.json");checks.load=not loaded.is_empty() and loaded.armory==w.armory and loaded.kingdom.industry.items==w.kingdom.industry.items
	var bad=w.duplicate(true);bad.armory.items["99999"]={"normal":1,"rebirth":0,"element":"none"};checks.reject_orphan=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.armory.items[str(next)].rebirth=22;checks.reject_overflow=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.armory.items[str(id)].rebirth=1;checks.reject_wrong_grade=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.armory.items[str(id)].normal=500;checks.reject_malformed_equipped=not Persistence.validate(bad)
	bad=w.duplicate(true);bad.armory.items[str(id)].element="unknown";checks.reject_element=not Persistence.validate(bad)
	var read_only=w.duplicate(true);read_only._read_only=true;checks.visitor_blocked=F.attempt(read_only,id,"normal",int(read_only.armory.serial)).is_empty()
	checks.adventure_entry=A.enter(w,false,"wildwood");checks.combat_blocked=F.quote(w,id,"normal").is_empty()
	var old_kills=int(w.armory.kills.get("wolf",0));var enemy=w.kingdom.adventure.run.enemies[0];enemy.state="idle";enemy.hp=0;A.defeat_enemy(w,enemy);var count=int(w.armory.kills.get("wolf",0));A.defeat_enemy(w,enemy);checks.kill_exactly_once=count==old_kills+1 and w.armory.kills.get("wolf",0)==count
	var boss=w.kingdom.adventure.run.enemies[3];boss.state="idle";boss.hp=0;A.defeat_enemy(w,boss);checks.unique_drop=w.kingdom.adventure.run.loot.any(func(l):return l.recipe=="legend_warrior_weapon")
	var loot=w.kingdom.adventure.run.loot.filter(func(l):return l.recipe=="legend_warrior_weapon")[0];w.kingdom.adventure.run.x=loot.x;w.kingdom.adventure.run.y=loot.y
	var item_count=w.kingdom.industry.items.size();checks.pickup=A.pickup(w,loot) and not A.pickup(w,loot) and w.kingdom.industry.items.size()==item_count+1
	checks.world_valid=Persistence.validate(w)
	w.kingdom.adventure.run.active=false;w.armory.kills.wolf=2
	for key in ["iron","gold"]:w.kingdom.stock[key]=0
	checks.contract=F.claim(w,"hunt") and w.kingdom.stock.gold==3000 and w.kingdom.stock.iron==2000
	checks.contract_no_duplicate=not F.claim(w,"hunt") and w.kingdom.stock.gold==3000
	checks.final_valid=Persistence.validate(w)
	DirAccess.make_dir_recursive_absolute("res://builds/armory");var data={"checks":checks,"count":checks.size(),"all_passed":not checks.values().has(false)};var f=FileAccess.open("res://builds/armory/tests.json",FileAccess.WRITE);f.store_string(JSON.stringify(data,"  "));print("ARMORY_CHECKS "+JSON.stringify(data));quit(0 if data.all_passed else 1)
