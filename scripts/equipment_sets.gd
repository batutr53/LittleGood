extends RefCounted
static var data={}
static func definitions() -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/rpg/class-sets.json"))
	return data.classes
static func count(w: Dictionary) -> int:
	if not w.has("rpg") or not load("res://scripts/rpg_progression.gd").available(w):return 0
	var cls=w.rpg.active;var allowed=definitions()[cls].pieces;var seen={};var I=load("res://scripts/industry.gd")
	var ids=w.kingdom.adventure.hero.equipment.values()+w.rpg.loadouts[cls].values()
	for id in ids:
		var item=I.item(w,int(id))
		if item.is_empty() or not item.recipe in allowed:continue
		seen[item.recipe]=true
	return seen.size()
static func bonuses(w: Dictionary) -> Dictionary:
	var result={};var pieces=count(w)
	if pieces==0:return result
	for needed in definitions()[w.rpg.active].bonuses:
		if pieces<int(needed):continue
		for key in definitions()[w.rpg.active].bonuses[needed]:result[key]=int(result.get(key,0))+int(definitions()[w.rpg.active].bonuses[needed][key])
	return result
