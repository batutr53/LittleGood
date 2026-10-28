extends RefCounted
const J=preload("res://scripts/journey.gd")
const K=preload("res://scripts/kingdom.gd")
const H=preload("res://scripts/hero.gd")
var p
var game
func _init(owner):p=owner;game=p.game
func say(en,tr):return p.say(en,tr)
func label(v,value):p.playbook().label(v,value)
func button(v,value,action,primary=false):return p.playbook().button(v,value,action,primary)
func chapter():
	var w=game.world;var key=J.transition(w)
	if key.is_empty():p.route("quest",0,false);return
	if key=="found":p.playbook().intro();return
	var data=J.stages()[key];var v=p.surface(game.realm_ui.localized(data[0]));label(v,game.realm_ui.localized(data[1]))
	label(v,say("Completed objectives: ","Tamamlanan hedefler: ")+str(w.kingdom.claimed.size())+say(". Your progress and owned equipment are preserved.",". İlerlemen ve sahip olduğun donanım korunur."))
	button(v,say("Inspect regions","Diyarları incele") if key=="regions" else say("Begin next chapter","Sonraki bölüme başla"),func():
		if key=="regions":p.route("map");return
		if J.advance(w,key):game.realm_ui.changed();game.checkpoint("journey-"+key);p.route("quest",0,false)
		else:p.ui.toast(say("Requirements changed. Reopen your current objective.","Koşullar değişti. Güncel hedefini yeniden aç.")),true)
	button(v,say("Colony overview","Koloni özeti"),func():p.route("journey"))
func overview():
	if not game.world.has("kingdom"):p.playbook().intro();return
	load("res://scripts/advisor_dialogue.gd").new(p).open()
func recruit():
	var w=game.world;var v=p.surface(say("Arin · call your champion","Arin · şampiyonunu çağır"));label(v,say("The Hearthkin protect the home. Your champion explores the Wildwood and brings back equipment and rare materials.","Ocaklılar yuvayı korur. Şampiyonun Yabanorman'ı keşfeder; donanım ve nadir malzemelerle döner."))
	var field=LineEdit.new();field.name="HeroName";field.text="Lale";field.max_length=24;field.custom_minimum_size.y=p.px(48);v.add_child(field)
	label(v,say("Cost: 5 food + 3 gold. Equip a forged weapon before departure.","Bedel: 5 besin + 3 altın. Yola çıkmadan önce üretilmiş silah kuşan."))
	button(v,say("Recruit champion","Şampiyonu çağır"),func():
		if H.recruit(w,field.text.strip_edges()):load("res://scripts/rpg_progression.gd").ensure(w);game.realm_ui.changed();game.checkpoint("champion-called");p.route("hero",0,false)
		else:p.ui.toast(say("Needs a valid name, 5 food and 3 gold.","Geçerli ad, 5 besin ve 3 altın gerekiyor.")),true).disabled=K.home(w).food<5 or int(w.kingdom.stock.gold)<3000 or w.get("_read_only",false)
	button(v,say("Manage supplies","Erzağı yönet"),func():p.route("resources"))
func layout():
	var L=load("res://scripts/settlement_layout.gd");var w=game.world;var v=p.surface(say("Settlement layout preview","Yerleşim düzeni önizlemesi"))
	if not L.writable(w):label(v,say("Return home before reorganizing the colony.","Koloniyi düzenlemeden önce eve dön."));return
	if p.layout_plan.is_empty():p.layout_plan=L.propose(w)
	if p.layout_plan.is_empty():label(v,say("No complete arrangement fits. A travelling caravan may lock an obstructing market. Finish its trip, expand land or relocate buildings individually.","Tam düzen sığmadı. Yoldaki kervan, sıkışık pazarı sabitliyor olabilir. Kervanı teslim al, araziyi genişlet veya binaları tek tek taşı."));button(v,say("Expand land","Araziyi genişlet"),func():p.route("estate"));button(v,say("Caravans","Kervanlar"),func():p.route("trade"));return
	var moved=p.layout_plan.filter(func(entry):return entry.from!=entry.to);label(v,str(moved.size())+say(" buildings will move. No cost; levels, workers, stored output and IDs are preserved. Nothing changes before confirmation."," bina taşınacak. Ücretsiz; seviyeler, işçiler, ürünler ve kimlikler korunur. Onaydan önce hiçbir şey değişmez."))
	var start=p.playbook().page(v,"layout",moved.size(),3)
	for entry in moved.slice(start,start+3):
		var b=w.kingdom.buildings.filter(func(building):return int(building.id)==entry.id)[0];var from=w.cells[entry.from];var to=w.cells[entry.to];label(v,game.realm_ui.localized(K.buildings()[b.kind].name)+" #"+str(entry.id)+" · "+str(int(from.x))+","+str(int(from.y))+" → "+str(int(to.x))+","+str(int(to.y)))
	button(v,say("Confirm this arrangement","Bu düzeni onayla"),func():
		if L.apply(w,p.layout_plan):p.layout_plan=[];game.realm_ui.changed();game.checkpoint("settlement-layout");p.route("guide",0,false)
		else:p.layout_plan=[];p.ui.toast(say("The settlement changed. Review a fresh plan.","Yerleşim değişti. Yeni planı gözden geçir.")),true).disabled=moved.is_empty()
	button(v,say("Cancel · keep existing layout","Vazgeç · mevcut düzeni koru"),func():p.layout_plan=[];p.route("colony"))
