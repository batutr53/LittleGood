extends RefCounted
const R=preload("res://scripts/rpg_progression.gd")
static func allowed(w:Dictionary,key:String)->bool:
	return not w.has("realm_entry") or key in w.realm_entry.get("classes",[])
static func valid_code(value)->bool:
	if not value is String or value.length()!=32:return false
	for ch in value:
		if not ch in "0123456789abcdef":return false
	return true
static func validate(w:Dictionary)->bool:
	if not w.has("realm_entry"):return true
	var state=w.realm_entry
	if not state is Dictionary or state.get("version")!=1 or not valid_code(state.get("character")) or state.get("realm")!="hearth" or not state.get("classes") is Array or state.classes.is_empty() or state.classes.size()>4:return false
	if state.has("race") and not state.race in ["human","stoneborn"]:return false
	var seen=[]
	if state.has("starting_stats"):
		if not state.starting_stats is Dictionary:return false
		var total=0
		for key in state.starting_stats:
			if not key in R.ATTRIBUTES or not state.starting_stats[key] is float and not state.starting_stats[key] is int or not is_finite(float(state.starting_stats[key])) or state.starting_stats[key]<0 or state.starting_stats[key]>10 or state.starting_stats[key]!=int(state.starting_stats[key]):return false
			total+=int(state.starting_stats[key])
		if total not in [0,10]:return false
	for key in state.classes:
		if not key in R.CLASSES or key in seen:return false
		seen.append(key)
	return w.has("rpg") and w.rpg.active in seen
static func apply(w:Dictionary,character:Dictionary)->bool:
	if not valid_code(character.get("id")) or character.get("realm")!="hearth" or not character.get("unlocked") is Array:return false
	var classes=character.unlocked
	if classes.is_empty() or classes.size()>4 or not character.get("primaryClass") in classes:return false
	for key in classes:
		if not key in R.CLASSES:return false
	w.realm_entry={"version":1,"character":character.id,"realm":character.realm,"classes":classes.duplicate()}
	w.realm_entry.race=character.get("race","human");w.realm_entry.starting_stats=character.get("startingStats",{}).duplicate()
	return true
