extends RefCounted
# Versioned live-player migration; untouched legacy snapshots remain readable.
static func enabled(w: Dictionary) -> bool:
	return w.get("parallel_play",{}) is Dictionary and int(w.get("parallel_play",{}).get("version",0))==1
static func ensure(w: Dictionary) -> bool:
	if w.get("_read_only",false) or w.get("settlements",[]).is_empty():return false
	var K=load("res://scripts/kingdom.gd");var I=load("res://scripts/industry.gd");var H=load("res://scripts/hero.gd")
	if not w.has("kingdom") and not K.enable(w):return false
	if not w.has("parallel_play"):w.parallel_play={"version":1,"starter_granted":false}
	if not enabled(w):return false
	if not I.enabled(w) and not I.enable(w):return false
	if not H.enabled(w) and not H.enable(w):return false
	if w.kingdom.adventure.hero.is_empty():
		w.kingdom.adventure.hero={"id":1,"name":"Arden","class":"warrior","xp":0,"hp":100,"equipment":{"weapon":0,"shield":0,"armor":0,"artifact":0},"cooldowns":{"attack":0,"skill":0,"dodge":0,"heal":0},"defeated":false}
	var R=load("res://scripts/rpg_progression.gd");R.ensure(w)
	if not w.parallel_play.starter_granted:
		var hero=w.kingdom.adventure.hero
		if int(hero.equipment.weapon)==0:
			var recipe="rpg_"+str(hero.get("class","warrior"))+"_weapon";var owned=w.kingdom.industry.items.filter(func(item):return item.recipe==recipe)
			if owned.is_empty() and w.kingdom.industry.items.size()+w.kingdom.industry.queue.size()<I.MAX_ITEMS:
				var item={"id":int(w.kingdom.industry.next_item),"recipe":recipe};w.kingdom.industry.next_item+=1;w.kingdom.industry.items.append(item);owned=[item]
			if not owned.is_empty() and not R.reserved(w,int(owned[0].id)):H.equip(w,"weapon",int(owned[0].id))
		# A full bag must not permanently consume the one-time starter grant.
		w.parallel_play.starter_granted=int(hero.equipment.weapon)>0
	load("res://scripts/armory.gd").ensure(w)
	return true
static func validate(w: Dictionary) -> bool:
	if not w.has("parallel_play"):return true
	var state=w.parallel_play
	return state is Dictionary and state.size()==2 and state.get("version")==1 and state.get("starter_granted") is bool and w.has("kingdom") and int(w.kingdom.get("version",0))==3 and not w.kingdom.get("adventure",{}).get("hero",{}).is_empty()
static func boss_locked(w: Dictionary) -> bool:return not enabled(w) and w.kingdom.claimed.size()<14
