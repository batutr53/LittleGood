extends SceneTree
const R=preload("res://scripts/rpg_progression.gd")
const H=preload("res://scripts/hero.gd")
var checks={}
func _initialize():call_deferred("run")
func run():
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");var original=w.kingdom.adventure.hero.duplicate(true);var items=w.kingdom.industry.items.duplicate(true)
	R.ensure(w);checks.legacy_hero_preserved=w.kingdom.adventure.hero==original;checks.items_preserved=w.kingdom.industry.items==items;checks.four_heroes=w.rpg.roster.size()==4
	var initial=w.duplicate(true);R.ensure(w);checks.idempotent=initial==w
	checks.switch_priest=R.switch(w,"priest") and w.kingdom.adventure.hero.get("class")=="priest"
	checks.old_equipment_not_duplicated=not w.kingdom.adventure.hero.equipment.values().has(int(original.equipment.weapon)) and w.kingdom.adventure.hero.equipment.weapon>0
	checks.priest_does_not_take_warrior_weapon=not H.equip(w,"weapon",int(original.equipment.weapon))
	checks.switch_warrior=R.switch(w,"warrior") and w.kingdom.adventure.hero==original
	checks.valid_migration=Persistence.validate(w)
	var draft=R.selected(w).attributes.duplicate();var before=H.stats(w);draft.strength=mini(5,R.points(w));checks.allocate=R.allocate(w,draft);checks.stats_affect_combat=H.stats(w).attack==before.attack+int(draft.strength)
	draft.strength=999;checks.overspend_rejected=not R.allocate(w,draft)
	checks.reset=R.reset(w) and H.stats(w)==before
	R.switch(w,"rogue");checks.assassin=R.specialize(w,"assassin") and R.selected(w).specialization=="assassin"
	w.kingdom.adventure.run.active=true;checks.no_switch_in_run=not R.switch(w,"mage");checks.no_reset_in_run=not R.reset(w);w.kingdom.adventure.run.active=false
	R.switch(w,"warrior");var protected=int(original.equipment.weapon);checks.cannot_discard_equipped=not R.discard(w,protected)
	checks.lock=R.lock_item(w,protected) and protected in w.rpg.locked;checks.cannot_discard_locked=not R.discard(w,protected)
	checks.roundtrip=Persistence.save_world(w,"user://rpg-regression-private.json") and not Persistence.load_world("user://rpg-regression-private.json").is_empty()
	var bad=w.duplicate(true);bad.rpg.progression.warrior.attributes.strength=-1;checks.reject_negative=not Persistence.validate(bad)
	print("RPG_CHECKS ",JSON.stringify(checks));quit(1 if checks.values().has(false) else 0)
