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
		var h=a.hero;var s=H.stats(game.world);var list=ui.card_list(v,280)
		list.add_child(ui.label(h.name+" · "+say("Hero level ","Kahraman seviyesi ")+str(H.level(h))+" · XP "+str(int(h.xp)),24,Color("ecd99f")))
		list.add_child(ui.label(say("Health ","Can ")+str(int(h.hp))+" / "+str(s.health)+"\n"+say("Attack ","Saldırı ")+str(s.attack)+" · "+say("Defense ","Savunma ")+str(s.defense)+"\n"+say("Speed ","Hız ")+str(s.speed)+" · "+say("Critical ","Kritik ")+str(s.crit/10)+"%",21))
		list.add_child(ui.label(say("Sword arc · heavy strike · dodge\nCooldowns: attack 0.5s, strike 4s, dodge 1.2s.\nForge a sword, then choose the weapon slot.","Kılıç yayı · ağır darbe · kaçınma\nBekleme: saldırı 0,5 sn, darbe 4 sn, kaçınma 1,2 sn.\nKılıç döv; sonra silah yuvasından seç."),19))
		for slot in H.SLOTS:
			var owned=I.item(game.world,int(h.equipment[slot]));var title={"weapon":say("Weapon","Silah"),"shield":say("Shield","Kalkan"),"armor":say("Armor","Zırh"),"artifact":say("Artifact","Eser")}[slot]
			add(list,title+" · "+(game.realm_ui.localized(I.recipes()[owned.recipe].name) if not owned.is_empty() else say("Empty","Boş")),func():equipment(slot))
		add(v,say("Forge equipment","Donanım döv"),game.realm_ui.workshop)
		if game.world.kingdom.claimed.size()>=11:add(v,say("World map · Wildwood","Dünya haritası · Yabanorman"),world_map,true)
	add(v,ui.t("back"),game.realm_ui.open)
func world_map() -> void:
	ui.page="kingdom";var v=ui.popup(say("Beyond the Border","Sınırın Ötesinde"))
	v.add_child(ui.label(say("WILDWOOD\nThe northern trail leads to the Sunstone, an ancient landmark. Explore at your own pace; Home always brings you back safely. Kingdom work pauses while you explore.","YABANORMAN\nKuzey patikası eski Güneştaşı anıtına ulaşır. Kendi hızında keşfet; Dön seni güvenle eve getirir. Keşfederken krallık işleri durur."),24))
	add(v,say("Enter Wildwood","Yabanorman'a gir"),func():game.enter_adventure(),true)
	add(v,ui.t("back"),profile)
func equipment(slot: String) -> void:
	ui.page="kingdom";var v=ui.popup(say("Compare equipment","Donanımı karşılaştır"));var list=ui.card_list(v,430)
	var s=H.stats(game.world);list.add_child(ui.label(say("Current attack / defense: ","Mevcut saldırı / savunma: ")+str(s.attack)+" / "+str(s.defense),21))
	for owned in game.world.kingdom.industry.items:
		var data=I.recipes()[owned.recipe];var id=int(owned.id)
		if data.get("category","tool")!=slot:continue
		add(list,game.realm_ui.localized(data.name)+" #"+str(id)+"\n"+game.realm_ui.localized(data.description),func():if H.equip(game.world,slot,id):game.realm_ui.changed();game.checkpoint("hero-gear");profile(),true)
	add(list,say("Unequip","Çıkar"),func():if H.equip(game.world,slot,0):game.realm_ui.changed();profile())
	add(v,ui.t("back"),profile)
