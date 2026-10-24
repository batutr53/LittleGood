extends RefCounted
const T=preload("res://scripts/trade.gd")
const K=preload("res://scripts/kingdom.gd")
const M=preload("res://scripts/military.gd")
const I=preload("res://scripts/industry.gd")
var game
var ui
var watching=false
var merchant=0
var route="river"
var cargo={"wood":4}
var guards=[]
func _init(g,u) -> void:game=g;ui=u
func say(en: String,tr: String) -> String:return game.realm_ui.say(en,tr)
func add(p,t: String,cb: Callable,primary: bool=false):return game.realm_ui.add(p,t,cb,primary)
func gold(value: int) -> String:return str(snappedf(value/1000.0,.01))+say(" gold"," altın")
func changed() -> void:game.realm_ui.changed();game.checkpoint("trade")
func open() -> void:
	if ui.premium!=null and ui.rebirth_enabled:ui.premium.route("trade");return
	legacy_open()

func legacy_open() -> void:
	if game.visiting or not T.enabled(game.world):return
	var w=game.world;ui.page="kingdom";var v=ui.popup(say("The First Trade Road","İlk Ticaret Yolu"));var list=ui.card_list(v,470)
	list.add_child(ui.label(game.realm_ui.resources(),19))
	list.add_child(ui.label(say("Assign a merchant to the completed marketplace. Goods and gold are real; no quest artifacts are sold. Prices include a spread. Menus pause work; Live Route Watch advances the home simulation.","Tamamlanmış pazara tüccar ata. Mal ve altın gerçektir; görev yadigârları satılmaz. Alış ve satış fiyatları farklıdır. Menüler işi durdurur; Canlı Yol İzleme ev simülasyonunu ilerletir."),19))
	add(list,say("Compare local and regional prices","Yerel ve bölgesel fiyatları karşılaştır"),prices,true)
	add(list,say("Prepare a caravan","Kervan hazırla"),prepare,true)
	add(list,say("Salvage unused equipment · free inventory space","Kullanılmayan donanımı sök · envanterde yer aç"),inventory)
	add(list,say("Assign merchants / recruit citizens","Tüccar ata / sakin işe al"),game.realm_ui.workers)
	for c in w.kingdom.trade.caravans:
		var id=int(c.id);var names={"outbound":say("Outbound","Gidiyor"),"blocked":say("Decision needed","Karar gerekli"),"returning":say("Returning","Dönüyor"),"ready":say("Collect at home","Evde teslim al"),"collected":say("Collected","Teslim alındı")}
		add(list,"#"+str(id)+" · "+game.realm_ui.localized(T.routes()[c.route].name)+" · "+names[c.state],func():watch(id))
	add(v,say("Watch the village","Köyü izle"),ui.close);add(v,ui.t("back"),game.realm_ui.open)
func prices() -> void:
	var w=game.world
	if T.inspect_prices(w):changed()
	ui.page="kingdom";var v=ui.popup(say("Prices · one unit","Fiyatlar · bir birim"));var list=ui.card_list(v,470)
	list.add_child(ui.label(say("Local buy / local sell / River export / Hills export. Exports pay after the round trip, less a 1-gold route fee and food. Imported goods cannot be flipped for profit.","Yerel alış / yerel satış / Nehir ihracatı / Tepe ihracatı. İhracat gidiş-dönüşten sonra ödenir; 1 altın yol ücreti ve besin gerekir. Alınan mal anında kârlı satılamaz."),19))
	for good in T.PRICES:
		var key=good;list.add_child(ui.label(game.realm_ui.cost({good:1})+" · "+str(snappedf(w.kingdom.stock[good]/1000.0,.1))+say(" stored"," depoda"),22,Color("ebd59d")))
		list.add_child(ui.label(" / ".join([gold(T.PRICES[good][0]),gold(T.PRICES[good][1]),gold(int(T.routes().river.sell[good])),gold(int(T.routes().hills.sell[good]))]),17))
		var row=HBoxContainer.new();list.add_child(row)
		for buy in [true,false]:
			var purchase=buy;var b=add(row,say("Buy 1","1 al") if buy else say("Sell 1","1 sat"),func():
				if T.transaction(w,key,1,purchase):changed();prices()
				else:ui.toast(say("Needs an available merchant, gold/stock and storage space.","Boştaki tüccar, altın/stok ve depo alanı gerekli.")))
			b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add(v,ui.t("back"),open)
func prepare() -> void:
	ui.page="kingdom";var v=ui.popup(say("Choose a merchant","Tüccar seç"));var list=ui.card_list(v,430)
	for c in T.merchants(game.world):
		var id=int(c.id);add(list,c.name,func():merchant=id;draft(),true)
	list.add_child(ui.label(say("A merchant must be assigned to the marketplace and free of another route. Soldiers and traveling merchants cannot work twice.","Tüccar pazara atanmış ve başka yola çıkmamış olmalı. Askerler ve yoldaki tüccarlar iki iş yapamaz."),20))
	add(v,ui.t("back"),open)
func draft() -> void:
	var w=game.world;ui.page="kingdom";var v=ui.popup(say("Load the wagon","Arabayı yükle"));var list=ui.card_list(v,340)
	guards=guards.filter(func(id):return M.available(w).any(func(u):return int(u.id)==id))
	for r in T.routes():
		var key=r;add(list,("✓ " if route==r else "◇ ")+game.realm_ui.localized(T.routes()[r].name)+" · "+str(int(T.routes()[r].ticks)*4)+say(" sec round trip"," sn gidiş-dönüş"),func():route=key;draft())
	for good in T.PRICES:
		var key=good;var row=HBoxContainer.new();list.add_child(row)
		var minus=add(row,"−",func():
			if cargo.has(key):
				cargo[key]-=1
				if cargo[key]<=0:cargo.erase(key)
			draft());minus.custom_minimum_size.x=60
		var text=ui.label(game.realm_ui.cost({good:int(cargo.get(good,0))})+" / "+str(int(w.kingdom.stock[good]/1000)),19);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text)
		var plus=add(row,"+",func():cargo[key]=int(cargo.get(key,0))+1;draft());plus.custom_minimum_size.x=60
	list.add_child(ui.label(say("Choose up to two escorts · health affects deterrence","En çok iki muhafız seç · can caydırıcılığı etkiler"),20))
	for u in M.available(w):
		var id=int(u.id);var c=w.kingdom.workers.filter(func(x):return x.id==u.worker)[0]
		add(list,("✓ " if guards.has(id) else "◇ ")+c.name+" · "+str(int(u.hp))+"/100",func():
			if guards.has(id):guards.erase(id)
			elif guards.size()<2:guards.append(id)
			draft())
	var q=T.quote(w,route,cargo)
	if not q.is_empty():v.add_child(ui.label(say("Cargo ","Yük ")+str(q.cargo_units)+" / 8 · "+say("Fee ","Ücret ")+gold(q.fee)+"\n"+say("Supplies ","Erzak ")+str(q.supplies/1000.0)+say(" food · returned sale "," besin · dönen satış ")+gold(q.payout)+"\n"+say("Escort strength / road danger: ","Muhafız gücü / yol tehlikesi: ")+str(T.strength(w,guards))+" / "+str(q.danger),20))
	else:v.add_child(ui.label(say("Load 1–8 whole units. Nothing is reserved until departure.","1–8 tam birim yükle. Ayrılışa kadar hiçbir şey ayrılmaz."),20))
	var confirm=add(v,say("Confirm departure · reserve cargo, fee & food","Ayrılışı onayla · yük, ücret ve besin ayır"),func():
		var id=T.dispatch(w,route,merchant,guards,cargo)
		if id>0:changed();watch(id)
		else:ui.toast(say("Check free merchant/escorts, stock, fee, food and the 2-caravan limit.","Boştaki tüccar/muhafız, stok, ücret, besin ve 2 kervan sınırını kontrol et.")),true)
	confirm.disabled=q.is_empty();add(v,ui.t("back"),prepare)
func watch(id: int) -> void:
	ui.page="kingdom";var v=ui.popup(say("Live Route Watch","Canlı Yol İzleme"));var board=preload("res://scripts/caravan_view.gd").new();board.game=game;board.caravan_id=id;v.add_child(board);watching=true
	# The strategic map covers the planet. Keep its simulation running, skip hidden rendering.
	game.show_world(false)
	var c=T.caravan(game.world,id)
	v.add_child(ui.label(say("This is a strategic route, not a playable region. Progress uses actual simulation ticks. Unsafe roads wait for you; no automatic losses happen while away.","Bu stratejik bir yol, oynanabilir bölge değil. İlerleme gerçek simülasyon turlarıyla olur. Güvensiz yollar seni bekler; uzaktayken otomatik kayıp olmaz."),18))
	v.add_child(ui.label(game.realm_ui.cost(c.cargo)+" · "+say("Contract ","Sözleşme ")+gold(int(c.payout)),20,Color("ebd59d")))
	add(v,say("Collect returned delivery","Dönen teslimatı al"),func():
		if T.collect(game.world,id):changed();open()
		else:ui.toast(say("The wagon must return first. A retreat also needs room for returned cargo.","Önce araba dönmeli. Geri çekilen yük için depoda yer de gerekli.")),true)
	add(v,say("Hazard: safe detour · 1.2 food","Tehlike: güvenli sapak · 1,2 besin"),func():
		if T.resolve(game.world,id,true):changed();watch(id)
		else:ui.toast(say("Only available when blocked, with 1.2 food.","Yalnızca yol kapalıyken, 1,2 besinle kullanılabilir.")))
	add(v,say("Hazard: return with unsold cargo","Tehlike: satılmamış yükle dön"),func():if T.resolve(game.world,id,false):changed();watch(id))
	add(v,ui.t("back"),open)
func inventory() -> void:
	ui.page="kingdom";var v=ui.popup(say("Make room in the warehouse","Depoda yer aç"));var list=ui.card_list(v,450)
	list.add_child(ui.label(say("Salvage destroys an unused item and returns up to half its ordinary materials, limited by storage space. Overflow is discarded. Artifacts, equipped gear and army kits are protected. Needs a merchant or working forge. Pending jobs stay intact.","Söküm kullanılmayan eşyayı yok eder; depo alanı ölçüsünde sıradan malzemelerinin yarısına kadarını döndürür. Sığmayan atılır. Yadigâr, kuşanılan ve asker takımları korunur. Tüccar veya çalışan demirci gerekir. Bekleyen işler korunur."),20))
	for owned in game.world.kingdom.industry.items:
		var id=int(owned.id);var data=I.recipes()[owned.recipe]
		if data.get("category")=="artifact" or M.item_reserved(game.world,id) or game.world.kingdom.get("adventure",{}).get("hero",{}).get("equipment",{}).values().has(id) or game.world.kingdom.industry.equipped.any(func(s):return int(s.item)==id):continue
		add(list,game.realm_ui.localized(data.name)+" #"+str(id),func():confirm_salvage(id))
	add(v,ui.t("back"),open if T.enabled(game.world) else game.realm_ui.inventory)
func confirm_salvage(id: int) -> void:
	var owned=I.item(game.world,id)
	if owned.is_empty():inventory();return
	ui.page="kingdom";var data=I.recipes()[owned.recipe];var v=ui.popup(game.realm_ui.localized(data.name));var refund={}
	for key in T.salvage_refund(game.world,id):refund[key]=T.salvage_refund(game.world,id)[key]/1000.0
	v.add_child(ui.label(say("Permanently remove this unused item? Actual return (overflow discarded): ","Kullanılmayan bu eşya kalıcı kaldırılsın mı? Gerçek iade (sığmayan atılır): ")+str(refund),23))
	add(v,say("Salvage this item","Bu eşyayı sök"),func():
		if T.salvage(game.world,id):changed();inventory()
		else:ui.toast(say("Needs a merchant or working forge; protected equipment cannot be salvaged.","Tüccar veya çalışan demirci gerekli; korunan donanım sökülemez.")),true)
	add(v,ui.t("back"),inventory)
