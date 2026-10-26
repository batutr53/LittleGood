extends SceneTree
const F=preload("res://scripts/armory.gd")
const I=preload("res://scripts/industry.gd")
const K=preload("res://scripts/kingdom.gd")
const R=preload("res://scripts/rpg_progression.gd")
const H=preload("res://scripts/hero.gd")
const E=preload("res://scripts/estate.gd")
const S=preload("res://scripts/equipment_sets.gd")
var checks={}
func _initialize():call_deferred("run")
func owned(w: Dictionary,recipe: String) -> int:
	var id=int(w.kingdom.industry.next_item);w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append({"id":id,"recipe":recipe});return id
func run():
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");R.ensure(w);F.ensure(w);E.start(w)
	for key in w.kingdom.stock:w.kingdom.stock[key]=50000
	var weapon=w.kingdom.industry.items.filter(func(i):return i.recipe=="iron_sword")[0];var id=int(weapon.id);var stock=w.kingdom.stock.duplicate()
	checks.missing_scroll_quote=F.quote(w,id,"normal").scroll_id==0
	checks.no_scroll_no_spend=F.attempt(w,id,"normal",int(w.armory.serial)).is_empty() and stock==w.kingdom.stock and w.armory.serial==0
	var wrong=owned(w,F.scroll_recipe("element"));checks.wrong_type_blocked=F.attempt(w,id,"normal",0).is_empty() and not I.item(w,wrong).is_empty()
	var sid=owned(w,F.scroll_recipe("normal"));R.lock_item(w,sid);checks.locked_scroll_blocked=F.attempt(w,id,"normal",0).is_empty();R.lock_item(w,sid)
	var result=F.attempt(w,id,"normal",0);checks.success_consumes_one=result.success and I.item(w,sid).is_empty() and not I.item(w,wrong).is_empty()
	checks.repeat_does_not_consume=F.attempt(w,id,"normal",0).is_empty() and not I.item(w,wrong).is_empty()
	checks.scroll_state_valid=Persistence.validate(w)
	var locked_scroll=owned(w,F.scroll_recipe("normal"));R.lock_item(w,locked_scroll);var spare_scroll=owned(w,F.scroll_recipe("normal"));checks.unlocked_scroll_selected=F.quote(w,id,"normal").scroll_id==spare_scroll
	F.attempt(w,id,"normal",int(w.armory.serial));checks.locked_scroll_retained=not I.item(w,locked_scroll).is_empty() and I.item(w,spare_scroll).is_empty()
	var forge=w.kingdom.buildings.filter(func(b):return b.kind=="forge")[0];w.kingdom.industry.queue.clear();w.kingdom.workers[0].building=int(forge.id)
	for mode in ["normal","reverse","rebirth","element"]:checks["craft_"+mode]=I.queue(w,F.scroll_recipe(mode),int(forge.id))
	for n in range(40):w.tick+=1;K.tick(w)
	checks.finished_scrolls_wait=w.estate.craft_ready.size()==4 and w.kingdom.industry.queue.size()==4
	var ready=w.kingdom.industry.queue.map(func(job):return int(job.id));var collected=E.collect(w,int(forge.id));checks.collect_four=collected.get("crafted",0)==4 and ready.all(func(item):return not I.item(w,item).is_empty())
	checks.craft_once=not E.collect(w,int(forge.id)).has("crafted")
	checks.ready_scrollback_saved=Persistence.save_world(w,"user://scrolls-test.json") and Persistence.load_world("user://scrolls-test.json").kingdom.industry.items==w.kingdom.industry.items
	for cls in R.CLASSES:
		var sample=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");R.ensure(sample);R.switch(sample,cls)
		checks[cls+"_empty_set"]=S.count(sample)==0 and S.bonuses(sample).is_empty()
		var pieces=S.definitions()[cls].pieces;var ids=[]
		for recipe in pieces:ids.append(owned(sample,recipe))
		checks[cls+"_bag_not_equipped"]=S.count(sample)==0
		R.extra_equip(sample,"head",ids[0]);H.equip(sample,"armor",ids[1]);var expected=S.definitions()[cls].bonuses["2"];var actual=S.bonuses(sample);checks[cls+"_two_pieces"]=S.count(sample)==2 and actual.size()==expected.size() and expected.keys().all(func(key):return actual.get(key)==int(expected[key]))
		var preview=H.preview(sample,"armor",0);var before=H.stats(sample);H.equip(sample,"armor",0);checks[cls+"_preview_exact"]=preview==H.stats(sample) and S.count(sample)==1;H.equip(sample,"armor",ids[1])
		R.extra_equip(sample,"legs",ids[2]);R.extra_equip(sample,"hands",ids[3]);R.extra_equip(sample,"feet",ids[4]);checks[cls+"_full_set"]=S.count(sample)==5 and int(S.bonuses(sample).attack)==3
		checks[cls+"_actual_stats"]=int(H.stats(sample).attack)>=int(before.attack)+3
		checks[cls+"_valid_save"]=Persistence.validate(sample)
	var mage=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");R.ensure(mage);R.switch(mage,"mage");R.extra_equip(mage,"head",owned(mage,"rpg_mage_head"));H.equip(mage,"armor",owned(mage,"rpg_mage_armor"));checks.mage_mana_bonus=R.modifiers(mage).mana==108
	checks.final_valid=Persistence.validate(w)
	R.extra_equip(mage,"legs",owned(mage,"rpg_mage_legs"));mage.kingdom.adventure.hero.hp=int(H.stats(mage).health);R.extra_equip(mage,"legs",0);checks.removal_clamps_hp=mage.kingdom.adventure.hero.hp<=H.stats(mage).health and Persistence.validate(mage)
	DirAccess.make_dir_recursive_absolute("res://builds/scrolls");var data={"checks":checks,"count":checks.size(),"all_passed":not checks.values().has(false)};var f=FileAccess.open("res://builds/scrolls/tests.json",FileAccess.WRITE);f.store_string(JSON.stringify(data,"  "));print("SCROLL_SET_CHECKS "+JSON.stringify(data));quit(0 if data.all_passed else 1)
