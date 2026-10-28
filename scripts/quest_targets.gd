extends RefCounted
# A read-only join of active goals and the actual enemy reward definitions.
const F=preload("res://scripts/armory.gd")
static func ready(w: Dictionary) -> Array:
	var result=[]
	if not w.has("armory"):return result
	for key in F.contracts():
		if not key in w.armory.claims and F.progress(w,key)>=int(F.contracts()[key].target):result.append(key)
	return result
static func for_enemy(w: Dictionary,kind: String,recipe: String="") -> Array:
	var result=[];var defs=load("res://scripts/adventure.gd").enemies()
	if not defs.has(kind):return result
	if w.has("armory"):
		for key in ["hunt","guardian"]:
			var matches=kind in ["wolf","thorn"] if key=="hunt" else kind in ["thornheart","ruin_sentinel","sunward_warden"]
			var d=F.contracts()[key];var have=F.progress(w,key)
			if matches and not key in w.armory.claims and have<int(d.target):result.append({"key":key,"title":d.title,"have":have,"need":int(d.target),"resource":"","chance_bp":10000})
	var recipes=load("res://scripts/industry.gd").recipes()
	if recipe.is_empty() or not recipes.has(recipe):return result
	var d=defs[kind];var drops={};var cargo=w.get("kingdom",{}).get("adventure",{}).get("run",{}).get("cargo",{})
	if kind=="thornheart":drops={"heart":10000,"gold":10000}
	else:
		drops[str(d.material)]=10000;var total=0
		for row in d.weights:total+=int(row[1])
		for row in d.weights:drops[str(row[0])]=maxi(int(drops.get(str(row[0]),0)),roundi(float(row[1])*10000/maxi(1,total)))
	if kind in load("res://scripts/sanctuary.gd").KINDS:drops["sentinel_core" if kind=="ancient_sentinel" else "sunstone_fragment"]=10000
	for resource in recipes[recipe].cost:
		if result.size()>=3:break
		var need=int(recipes[recipe].cost[resource]);var have=int(w.kingdom.stock.get(resource,0))/1000+int(cargo.get(resource,0))
		if have<need and drops.get(resource,0)>0:result.append({"key":recipe+":"+resource,"title":recipes[recipe].name,"have":have,"need":need,"resource":resource,"chance_bp":int(drops[resource])})
	return result
