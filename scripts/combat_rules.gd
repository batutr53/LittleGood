extends RefCounted
const R=preload("res://scripts/rpg_progression.gd")
# Validate before attack_context consumes mana, changes buffs or starts cooldowns.
# Ground/area/self casts and untargeted melee retain their existing free-cast rules.
static func check(w: Dictionary,input: Dictionary) -> String:
	if not w.has("rpg"):return ""
	var id=int(input.get("target_id",0))
	if id<=0:return ""
	var skill=input.get("skill",false);var reach=R.basic_range(w)
	if skill:
		var p=R.selected(w);var index=int(p.bar[clampi(int(input.get("skill_slot",0)),0,2)])
		if int(p.skills[index])>0:
			var d=R.skill_definition(w.kingdom.adventure.hero.get("class","warrior"),index)
			if d.target!="enemy":return ""
			if int(d.range)>0:reach=int(d.range)
		reach=maxi(105,reach)
	var run=w.kingdom.adventure.run;var targets=run.enemies.filter(func(e):return int(e.id)==id and e.hp>0)
	if targets.is_empty():return "target"
	var from=Vector2(run.x,run.y);var to=Vector2(targets[0].x,targets[0].y)
	if from.distance_to(to)>reach:return "range"
	if not R.clear_shot(w,from,to):return "obstacle"
	if run.get("region","")=="sanctuary" and not load("res://scripts/sanctuary.gd").line_clear(from,to,run):return "obstacle"
	return ""
