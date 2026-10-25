extends SceneTree
const R=preload("res://scripts/rpg_progression.gd")
const A=preload("res://scripts/adventure.gd")
var checks={}
func _initialize():call_deferred("run")
func run():
	var probe=preload("res://scripts/hero_progression_probe.gd").new();checks.legal_hero=probe.armed()
	var original=probe.world
	for key in R.CLASSES:
		var w=original.duplicate(true);R.ensure(w);R.switch(w,key);checks[key+"_entry"]=A.enter(w)
		var h=w.kingdom.adventure.hero;var run=w.kingdom.adventure.run;var enemy=run.enemies[0]
		run.x=240;run.y=1260;enemy.x=240;enemy.y=1080;var before=enemy.hp
		A.step(w,{"attack":true});checks[key+"_range"]=(enemy.hp<before if key!="warrior" else enemy.hp==before)
		checks[key+"_valid"]=Persistence.validate(w)
		var old=w.kingdom.duplicate(true);checks[key+"_no_switch"]=not R.switch(w,"warrior") and w.kingdom==old
		var untrained_mana=R.selected(w).mana;checks[key+"_untrained_skill_locked"]=not R.skill_ready(w,{"skill_slot":1});A.step(w,{"skill":true,"skill_slot":1});checks[key+"_untrained_does_not_spend_mana"]=R.selected(w).mana>=untrained_mana
		A.exit(w);h.xp=400;R.selected(w).skills[0]=1;checks[key+"_enter_skill"]=A.enter(w)
		run.x=240;run.y=1260;enemy.x=240;enemy.y=1200;var mana=R.selected(w).mana
		A.step(w,{"skill":true});checks[key+"_mana_spent"]=R.selected(w).mana<mana
		var after=R.selected(w).mana;A.step(w,{"skill":true});checks[key+"_cooldown_prevents_repeat"]=R.selected(w).mana>=after
		A.exit(w);checks[key+"_save"]=Persistence.save_world(w,"user://rpg-class-"+key+".json") and not Persistence.load_world("user://rpg-class-"+key+".json").is_empty()
	print("RPG_COMBAT_CHECKS ",JSON.stringify(checks));quit(1 if checks.values().has(false) else 0)
