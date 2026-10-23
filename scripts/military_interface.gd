extends RefCounted
const M=preload("res://scripts/military.gd")
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
var game
var ui
func _init(g,u) -> void:game=g;ui=u
func say(en: String,tr: String) -> String:return game.realm_ui.say(en,tr)
func add(p,t: String,cb: Callable,primary: bool=false):return game.realm_ui.add(p,t,cb,primary)
func changed() -> void:game.realm_ui.changed();game.checkpoint("company")
func open() -> void:
	if game.visiting or not M.enabled(game.world):return
	var w=game.world;var m=w.kingdom.military;ui.page="kingdom"
	var v=ui.popup(say("The Border Company","Sınır Birliği"));var list=ui.card_list(v,470)
	list.add_child(ui.label(game.realm_ui.resources(),18))
	list.add_child(ui.label(say("Commander: ","Komutan: ")+w.kingdom.adventure.hero.name+" · "+str(m.units.size())+" / 6",25,Color("ecd99f")))
	list.add_child(ui.label(say("Training: free citizen + forged kit + instructor, 3 food / 2 gold. Six instructor ticks per soldier. Soldiers leave civilian work; kits remain owned. Upkeep: 0.01 food per soldier / tick.","Eğitim: boşta sakin + dövülmüş takım + eğitmen, 3 besin / 2 altın. Asker başına altı eğitmen turu. Asker sivil işten ayrılır; takım sende kalır. Bakım: asker başına turda 0,01 besin."),18))
	for u in m.units:
		var soldier=u;var citizen=w.kingdom.workers.filter(func(c):return c.id==soldier.worker)[0]
		var names={"training":say("Training","Eğitim"),"ready":say("Ready","Hazır"),"injured":say("Injured","Yaralı"),"recovering":say("Recovering","İyileşiyor"),"deployed":say("Deployed","Görevde")}
		list.add_child(ui.label(citizen.name+" · "+game.realm_ui.localized(I.recipes()[I.item(w,int(u.gear)).recipe].name)+"\n"+names[u.status]+" · "+str(int(u.hp))+" / 100 · XP "+str(int(u.xp))+(" · "+str(int(u.progress/60))+"%" if u.status in ["training","recovering"] else ""),20))
		if u.status in ["ready","injured"]:
			if u.hp<100:add(list,say("Recover · 2 food + 1 gold","İyileştir · 2 besin + 1 altın"),func():if M.recover(w,int(soldier.id)):changed();open())
			add(list,say("Return citizen and kit to civilian duty","Sakini ve takımı sivil göreve döndür"),func():if M.retire(w,int(soldier.id)):changed();open())
	for key in M.FORMATIONS:
		var value=key;var terms={"balanced":say("Balanced · steady attack & armor","Dengeli · normal saldırı ve zırh"),"defensive":say("Defensive · 80% attack / 140% armor","Savunma · %80 saldırı / %140 zırh"),"assault":say("Assault · 130% attack / 75% armor","Hücum · %130 saldırı / %75 zırh")}
		add(list,("✓ " if m.formed and m.formation==key else "◇ ")+terms[key],func():M.formation(w,value);changed();open())
	add(list,say("Train a free citizen","Boştaki sakini eğit"),candidates,true)
	add(list,say("Forge military equipment","Askeri donanım döv"),game.realm_ui.workshop)
	add(list,say("Assign instructor / recruit citizens","Eğitmen ata / sakin işe al"),game.realm_ui.workers)
	for key in ["raid","camp"]:
		var mission=key;var title=say("Defend the village","Köyü savun") if key=="raid" else say("March on the border camp","Sınır kampına yürü")
		var b=add(list,title+say(" · 3 food"," · 3 besin"),func():
			if not game.enter_army(mission):ui.toast(say("Needs ready soldiers, food, and the preceding quest.","Hazır asker, besin ve önceki görev gerekli.")),true)
		b.disabled=w.kingdom.claimed.size()<(18 if key=="raid" else 19) or M.available(w).is_empty()
	list.add_child(ui.label(say("Village defense: +2 attack from watchtower, +3 armor from palisade. Camp: no home bonus. Retreat preserves survivors; no offline battles occur.","Köy savunması: kuleden +2 saldırı, çitten +3 zırh. Kampta ev bonusu yok. Geri çekilme sağ kalanları korur; çevrimdışı savaş olmaz."),18))
	add(v,say("Watch training / recovery","Eğitimi / iyileşmeyi izle"),ui.close,true);add(v,ui.t("back"),game.realm_ui.open)
func candidates() -> void:
	var w=game.world;ui.page="kingdom";var v=ui.popup(say("Choose a citizen","Bir sakin seç"));var list=ui.card_list(v,440)
	for c in K.assigned(w,0):
		var id=int(c.id);add(list,c.name,func():kits(id),true)
	list.add_child(ui.label(say("Only free citizens appear. Unassign or recruit someone in People & Work. Keep an instructor and food producer working.","Yalnızca boştakiler görünür. İnsanlar ve İşler'de birini boşa çıkar veya işe al. Eğitmen ve besin üreticisi çalışmaya devam etsin."),20))
	add(v,ui.t("back"),open)
func kits(worker: int) -> void:
	var w=game.world;ui.page="kingdom";var v=ui.popup(say("Assign a real kit","Gerçek bir takım ata"));var list=ui.card_list(v,440)
	var barracks=w.kingdom.buildings.filter(func(b):return b.kind=="barracks" and K.ready(b))
	for item in w.kingdom.industry.items:
		var owned=item
		if I.recipes()[item.recipe].get("category")!="military" or M.item_reserved(w,int(item.id)):continue
		var b=add(list,game.realm_ui.localized(I.recipes()[item.recipe].name)+" #"+str(int(item.id))+" · 3 food / 2 gold",func():
			if not barracks.is_empty() and M.train(w,worker,owned.recipe.trim_suffix("_kit"),int(owned.id),int(barracks[0].id)):changed();open()
			else:ui.toast(say("Needs a finished barracks, assigned instructor, 3 food and 2 gold.","Tamamlanmış kışla, atanmış eğitmen, 3 besin ve 2 altın gerekli.")),true)
		b.disabled=barracks.is_empty()
	add(v,ui.t("back"),candidates)
