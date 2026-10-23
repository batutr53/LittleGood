extends RefCounted
const H=preload("res://scripts/hero.gd")
const I=preload("res://scripts/industry.gd")
var game
var ui
func _init(g,u):game=g;ui=u
func say(en: String,tr: String) -> String:return tr if ui.language=="tr" else en
func add(v,text: String,cb: Callable,primary: bool=false):return game.realm_ui.add(v,text,cb,primary)
func profile() -> void:
	if not H.writable(game.world):return
	ui.page="kingdom";var a=game.world.kingdom.adventure;var v=ui.popup(say("Champion of the Wild Lands","Yaban Toprakların Şampiyonu"))
	var row=HBoxContainer.new();v.add_child(row)
	var portrait=TextureRect.new();portrait.texture=load("res://assets/adventure/warrior.png");portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(140,170);row.add_child(portrait)
	var words=ui.label(say("WARRIOR\nA steady blade, a brave heart.\nYour citizens’ craftsmanship will protect this champion.","SAVAŞÇI\nSağlam bir kılıç, cesur bir kalp.\nYurttaşlarının ustalığı bu şampiyonu koruyacak."),22);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
	if a.hero.is_empty():
		var name=LineEdit.new();name.name="HeroName";name.text="Lale";name.max_length=24;name.custom_minimum_size.y=62;v.add_child(name)
		add(v,say("Recruit Warrior · 5 food + 3 gold","Savaşçı çağır · 5 besin + 3 altın"),func():if H.recruit(game.world,name.text.strip_edges()):game.realm_ui.changed();game.checkpoint("hero");profile(),true)
	else:
		var h=a.hero;var s=H.stats(game.world);var list=ui.card_list(v,350)
		list.add_child(ui.label(h.name+" · "+say("Hero level ","Kahraman seviyesi ")+str(H.level(h))+" · XP "+str(int(h.xp)),24,Color("ecd99f")))
		list.add_child(ui.label(say("Health ","Can ")+str(int(h.hp))+" / "+str(s.health)+"\n"+say("Attack ","Saldırı ")+str(s.attack)+" · "+say("Defense ","Savunma ")+str(s.defense)+"\n"+say("Speed ","Hız ")+str(s.speed)+" · "+say("Critical ","Kritik ")+str(s.crit/10)+"%",21))
		list.add_child(ui.label(say("Compare gear below. In Wildwood, hold Attack; dodge warning zones and strike during recovery.","Aşağıda donanımı karşılaştır. Yabanorman'da Saldır'ı basılı tut; uyarı alanından kaç, dinlenme aralığında vur."),19))
		for slot in H.SLOTS:
			var owned=I.item(game.world,int(h.equipment[slot]));var title={"weapon":say("Weapon","Silah"),"shield":say("Shield","Kalkan"),"armor":say("Armor","Zırh"),"artifact":say("Artifact","Eser")}[slot]
			add(list,title+" · "+(game.realm_ui.localized(I.recipes()[owned.recipe].name) if not owned.is_empty() else say("Empty","Boş")),func():equipment(slot))
		add(v,say("Forge equipment","Donanım döv"),game.realm_ui.workshop)
		if game.world.kingdom.claimed.size()>=11:add(v,say("World map · Wildwood","Dünya haritası · Yabanorman"),world_map,true)
	add(v,ui.t("back"),game.realm_ui.open)
func legacy_world_map() -> void:
	ui.page="kingdom";var v=ui.popup(say("Beyond the Border","Sınırın Ötesinde"))
	var map=TextureRect.new();map.texture=load("res://assets/adventure/wildwood-ground.svg");map.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;map.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;map.custom_minimum_size=Vector2(300,250);v.add_child(map)
	v.add_child(ui.label(say("WILDWOOD · North ↑\nCamp → Sunstone → Ruined chest → Guardian\nHome restores health and banks collected loot. Kingdom work pauses while exploring. Northern roots open after quest 14.","YABANORMAN · Kuzey ↑\nKamp → Güneştaşı → Harabe sandığı → Muhafız\nDön canı yeniler, ganimeti depolar. Keşifte krallık işleri durur. Kuzey kökleri 14. görevden sonra açılır."),20))
	add(v,say("Enter Wildwood","Yabanorman'a gir"),func():game.enter_adventure(),true)
	var r=game.world.kingdom.adventure.run
	if not r.is_empty() and not r.active and not r.enemies.any(func(e):return e.hp>0) and not r.loot.any(func(l):return not l.taken):
		add(v,say("New expedition · refresh cleared trail","Yeni sefer · temizlenen patikayı yenile"),func():if load("res://scripts/adventure.gd").revisit(game.world):game.checkpoint("new-expedition");world_map())
	add(v,ui.t("back"),profile)
func world_map() -> void:
	ui.page="kingdom";var v=ui.popup(say("Beyond the Kingdom","Krallığın Ötesinde"));var list=ui.card_list(v,480)
	list.add_child(ui.label(say("ADVENTURE · Walk, fight and gather with your hero.\nHome work and caravan travel pause during expeditions.","MACERA · Kahramanınla yürü, savaş ve topla.\nSeferde ev işleri ve kervan yolculuğu durur."),19))
	var R=preload("res://scripts/regions.gd")
	for id in R.IDS:
		var key=id;var d=R.data(id)
		var image=TextureRect.new();image.texture=load("res://assets/adventure/"+d.preview+".svg");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(300,125);list.add_child(image)
		var status=say("Explored","Keşfedildi") if R.seen(game.world,id) else say("Unexplored","Keşfedilmedi")
		add(list,game.realm_ui.localized(d.name)+" · "+status+"\n"+(say("Inspect destination","Bölgeyi incele") if d.playable else say("E2C · In development","E2C · Geliştiriliyor")),func():destination(key),R.unlocked(game.world,id))
	if preload("res://scripts/trade.gd").enabled(game.world):
		list.add_child(ui.label(say("TRADE POSTS · Strategic caravan routes, separate from hero exploration.","TİCARET KARAKOLLARI · Kahramanın keşfinden ayrı stratejik kervan yolları."),19))
		add(list,say("River Guild / Iron Hills trade post","Nehir Loncası / Demir Tepeler ticaret karakolu"),game.trade_ui.open)
	add(v,ui.t("back"),profile)
func destination(id: String) -> void:
	var R=preload("res://scripts/regions.gd");var d=R.data(id);ui.page="kingdom";var v=ui.popup(game.realm_ui.localized(d.name));var list=ui.card_list(v,440)
	list.add_child(ui.label(say("ADVENTURE DESTINATION · Hero level ","MACERA BÖLGESİ · Kahraman seviyesi ")+str(d.level)+"\n"+game.realm_ui.localized(d.risk)+"\n\n"+game.realm_ui.localized(d.resources)+"\n"+game.realm_ui.localized(d.enemies)+"\n"+game.realm_ui.localized(d.landmark),21))
	if id=="iron_hills":list.add_child(ui.label(say("Two finite mineral deposits. They do not refresh when you leave or reload. Ore feeds your existing furnace; stone can build your kingdom. No travel fee.","İki sınırlı maden damarı. Ayrılınca veya kayıt yükleyince yenilenmez. Cevher mevcut fırınında eritilir; taş krallığında kullanılır. Yol ücreti yok."),19))
	if R.unlocked(game.world,id):add(v,say("Enter ","Gir: ")+game.realm_ui.localized(d.name),func():game.enter_adventure(id),true)
	else:list.add_child(ui.label(say("Requires quest 21 completed and an armed Warrior.","21. görev tamamlanmalı ve Savaşçı silahlı olmalı.") if d.playable and id=="iron_hills" else say("Requires an armed Warrior and quest 11.","Silahlı Savaşçı ve 11. görev gerekli.") if d.playable else say("Playable desert is not included yet. Your trade route remains available.","Oynanabilir çöl henüz bu sürümde yok. Ticaret yolun kullanılabilir."),20))
	if id=="wildwood":
		var r=game.world.kingdom.adventure.run
		if not r.is_empty() and not r.active and r.get("region","wildwood")=="wildwood" and not r.enemies.any(func(e):return e.hp>0) and not r.loot.any(func(l):return not l.taken):add(v,say("Refresh cleared trail","Temizlenen patikayı yenile"),func():if load("res://scripts/adventure.gd").revisit(game.world):game.checkpoint("new-expedition");destination(id))
	add(v,say("Prepare equipment / potions","Donanım / iksir hazırla"),profile)
	add(v,ui.t("back"),world_map)
func equipment(slot: String) -> void:
	ui.page="kingdom";var v=ui.popup(say("Compare equipment","Donanımı karşılaştır"));var list=ui.card_list(v,430)
	var s=H.stats(game.world);list.add_child(ui.label(say("Current attack / defense: ","Mevcut saldırı / savunma: ")+str(s.attack)+" / "+str(s.defense),21))
	for owned in game.world.kingdom.industry.items:
		var data=I.recipes()[owned.recipe];var id=int(owned.id)
		if data.get("category","tool")!=slot:continue
		var next=H.preview(game.world,slot,id)
		add(list,game.realm_ui.localized(data.name)+" #"+str(id)+"\n"+game.realm_ui.localized(data.description)+"\n"+say("Attack ","Saldırı ")+str(s.attack)+" → "+str(next.attack)+say(" · Defense "," · Savunma ")+str(s.defense)+" → "+str(next.defense)+say(" · Health "," · Can ")+str(s.health)+" → "+str(next.health),func():if H.equip(game.world,slot,id):game.realm_ui.changed();game.checkpoint("hero-gear");profile(),true)
	add(list,say("Unequip","Çıkar"),func():if H.equip(game.world,slot,0):game.realm_ui.changed();profile())
	add(v,ui.t("back"),profile)
