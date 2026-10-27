extends RefCounted
const A=preload("res://scripts/adventure.gd")
static func catalogue():
	var R=load("res://scripts/regions.gd");var rows=[]
	for region in R.IDS:
		var actors=A.new_enemies() if region=="wildwood" else R.create(1,false,42).enemies if region=="iron_hills" else load("res://scripts/ashen_desert.gd").create(1,false,42).enemies if region=="ashen_desert" else load("res://scripts/sanctuary.gd").create(1,false,42).enemies
		if region=="wildwood":actors=actors.duplicate();actors.append({"kind":"thornheart"})
		var seen={}
		for actor in actors:
			var kind=str(actor.kind)
			if seen.has(kind):continue
			seen[kind]=true;var d=A.enemies()[kind];var rewards=[]
			if kind=="thornheart":rewards=[{"resource":"heart","quantity":1,"chance_bp":10000,"once":true},{"resource":"gold","quantity":5,"chance_bp":10000,"once":true}]
			else:
				rewards.append({"resource":d.material,"quantity":int(d.quantity),"chance_bp":10000,"once":false});var total=0
				for weight in d.weights:total+=int(weight[1])
				for weight in d.weights:rewards.append({"resource":weight[0],"quantity":1,"chance_bp":roundi(float(weight[1])*10000/maxi(1,total)),"once":false})
			if region=="sanctuary":rewards.append({"resource":"sentinel_core" if kind=="ancient_sentinel" else "sunstone_fragment","quantity":1 if kind=="ancient_sentinel" else 2,"chance_bp":10000,"once":false})
			rows.append({"region":region,"kind":kind,"name":d.name,"health":d.health,"attack":d.attack,"defense":d.defense,"xp":d.xp,"rewards":rewards,"weapon_grade":"unique" if kind in ["thornheart","ruin_sentinel","sunward_warden"] else "high","weapon_chance_bp":10000 if kind in ["thornheart","ruin_sentinel","sunward_warden"] else 2500})
	return rows
static func search(query="",region="all",class_key="warrior"):
	var result=[];var I=load("res://scripts/industry.gd");var R=load("res://scripts/regions.gd");var q=query.strip_edges().to_lower()
	for row in catalogue():
		if region!="all" and row.region!=region:continue
		var recipe=("legend_" if row.weapon_grade=="unique" else "high_")+class_key+"_weapon";var words=row.kind+" "+JSON.stringify(row.name)+" "+JSON.stringify(R.data(row.region).name)+" "+recipe+" "+JSON.stringify(I.recipes().get(recipe,{}).get("name",[]))
		words+=" "+{"wolf":"kurt","thorn":"diken","spider":"örümcek"}.get(row.kind,"")
		for reward in row.rewards:
			words+=" "+reward.resource+" "+{"gold":"altın","iron":"demir","ore":"cevher","leather":"deri","thornhide":"dikenderi","herb":"şifalı bitki","heart":"yaşayan kalp","ancient_alloy":"kadim alaşım","desert_crystal":"çöl kristali","sentinel_core":"nöbetçi çekirdeği","sunstone_fragment":"güneştaşı parçası"}.get(reward.resource,"")
		if q.is_empty() or words.to_lower().contains(q):result.append(row)
	return result
