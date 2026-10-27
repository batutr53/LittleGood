extends RefCounted
# Read-only advice. Commands still go through the existing authoritative systems.
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
const H=preload("res://scripts/hero.gd")
const M=preload("res://scripts/military.gd")
const T=preload("res://scripts/trade.gd")
static func transition(w):
	if not w.has("kingdom"):return "found"
	if not K.current(w).is_empty():return ""
	var count=w.kingdom.claimed.size()
	if count==5 and not I.enabled(w):return "industry"
	if count==10 and not H.enabled(w):return "hero"
	if count==15 and not M.enabled(w):return "army"
	if count==20 and not T.enabled(w):return "trade"
	return "regions"
static func advance(w,key):
	if w.get("_read_only",false) or key!=transition(w):return false
	match key:
		"industry":return I.enable(w)
		"hero":return H.enable(w)
		"army":return M.enable(w)
		"trade":return T.enable(w)
	return false
static func stages():
	return {"found":[["A home in the wilderness","Yabanın ortasında bir yuva"],["Meet Arin and found the Hearthbound colony.","Arin ile tanış ve Ocakbağı kolonisini kur."]],"industry":[["The Iron Age","Demir Çağı"],["Your first village stands. Mines, smelting and a staffed forge will prepare your hero's equipment.","İlk köyün kuruldu. Maden, döküm ve çalışan bir demirci kahramanının donanımını hazırlayacak."]],"hero":[["Beyond the border","Sınırın ötesinde"],["Arin has discovered the Wildwood trail. Recruit a hero, equip a weapon and return with real expedition loot.","Arin Yabanorman patikasını buldu. Kahraman çağır, silah kuşan ve sefer ganimetiyle eve dön."]],"army":[["The Border Company","Sınır Birliği"],["The growing settlement needs defenders. Build barracks, assign an instructor and train equipped workers.","Büyüyen yerleşime savunucu gerekiyor. Kışla kur, eğitmen ata ve donanımlı işçileri eğit."]],"trade":[["The first trade road","İlk ticaret yolu"],["Open the marketplace and protect caravans. Your existing soldiers, hero and stores stay with you.","Pazarı aç ve kervanları koru. Askerlerin, kahramanın ve depoların korunur."]],"regions":[["The roads beyond","Uzak diyarların yolları"],["Follow discoveries into the hills, desert and ancient sanctuary. Destination requirements remain in force.","Keşiflerin izinden tepelere, çöle ve kadim tapınağa ilerle. Bölge giriş koşulları geçerlidir."]]}
static func report(w):
	if not w.has("kingdom"):return {"route":"colony","argument":0,"message":["Found your colony with Arin.","Arin ile kolonini kur."]}
	var a=w.kingdom.get("adventure",{})
	if a.get("run",{}).get("active",false):return {"route":"hunts","argument":0,"message":["Finish your expedition and return home to bank cargo.","Seferini tamamla; yükü teslim etmek için eve dön."]}
	var E=load("res://scripts/estate.gd")
	if E.enabled(w):
		for b in w.kingdom.buildings:
			if E.status(w,b)!="":return {"route":"building","argument":int(b.id),"message":["Collect finished work before starting another order.","Yeni siparişten önce tamamlanan işi veya ürünü teslim al."]}
	if w.has("colony"):
		for id in w.colony.jobs:
			if int(w.colony.jobs[id].buffer)>0:return {"route":"worker","argument":int(id),"message":["A worker is carrying materials. Deliver their cargo.","İşçin malzeme taşıyor. Yükünü teslim al."]}
	for b in w.kingdom.buildings:
		if not K.ready(b):return {"route":"staffing" if K.assigned(w,0).is_empty() else "building","argument":int(b.id),"message":["Construction needs a free builder and running world time.","İnşaat için boştaki inşaatçı ve ilerleyen dünya zamanı gerekiyor."]}
	if I.enabled(w):
		for job in w.kingdom.industry.queue:
			if w.get("estate",{}).get("craft_ready",[]).has(int(job.id)):continue
			if K.assigned(w,int(job.building)).is_empty():return {"route":"staffing","argument":int(job.building),"message":["Your forge order is waiting for a smith. Assign an available worker.","Demirci siparişin işçi bekliyor. Uygun bir işçiyi ata."]}
	if H.enabled(w) and a.hero.is_empty():return {"route":"hero","argument":0,"message":["Recruit your first hero: 5 food and 3 gold.","İlk kahramanını çağır: 5 besin ve 3 altın."]}
	var q=K.current(w)
	if not q.is_empty():return {"route":"quest","argument":0,"message":["Follow Arin's current objective; claim its reward when complete.","Arin'in güncel hedefini izle; tamamlanınca ödülünü al."]}
	return {"route":"quest","argument":0,"message":["Continue to the next chapter or inspect unlocked regions.","Sonraki bölüme geç veya açılmış diyarları incele."]}
