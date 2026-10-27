extends RefCounted
const D=preload("res://scripts/drop_guide.gd")
var p
var game
func _init(owner):p=owner;game=p.game
func say(en,tr):return p.say(en,tr)
func label(v,value):p.playbook().label(v,value)
func button(v,value,action,primary=false):return p.playbook().button(v,value,action,primary)
func open():
	var w=game.world;var R=load("res://scripts/regions.gd");var v=p.surface(say("Where does it drop?","Nereden düşer?"));var row=HBoxContainer.new();v.add_child(row);var search=LineEdit.new();search.name="DropSearch";search.text=p.drop_query;search.placeholder_text=say("Item / monster / material","Eşya / yaratık / malzeme");search.custom_minimum_size.y=p.px(40);search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(search)
	var submit=func():p.drop_query=search.text;p.playbook_pages.drops=0;p.route("bestiary",0,false)
	search.text_submitted.connect(func(_value):submit.call());button(row,say("Search","Ara"),submit)
	var regions=OptionButton.new();regions.custom_minimum_size.y=p.px(40);regions.add_item(say("All regions","Tüm diyarlar"));regions.set_item_metadata(0,"all")
	for key in R.IDS:regions.add_item(game.realm_ui.localized(R.data(key).name));regions.set_item_metadata(regions.item_count-1,key)
	for i in range(regions.item_count):
		if regions.get_item_metadata(i)==p.drop_region:regions.select(i)
	regions.item_selected.connect(func(i):p.drop_region=regions.get_item_metadata(i);p.playbook_pages.drops=0;p.route("bestiary",0,false));v.add_child(regions)
	var rows=D.search(p.drop_query,p.drop_region,w.kingdom.adventure.hero.get("class","warrior"));var index=p.playbook().page(v,"drops",rows.size(),1)
	if rows.is_empty():label(v,say("No matching monster drop. Check forge recipes for crafted equipment.","Eşleşen yaratık ganimeti yok. Üretilen donanımlar için demirci tariflerini incele."));button(v,say("Forge recipes","Demirci tarifleri"),game.realm_ui.workshop);return
	var d=rows[index];label(v,game.realm_ui.localized(d.name)+" · "+game.realm_ui.localized(R.data(d.region).name));label(v,"HP "+str(int(d.health))+" · ATK "+str(int(d.attack))+" · DEF "+str(int(d.defense))+" · XP "+str(int(d.xp)))
	var rewards=[]
	for reward in d.rewards:rewards.append(p.rpg.resource_name(reward.resource)+" ×"+str(reward.quantity)+" · "+str(snappedf(reward.chance_bp/100.0,.01))+"%"+(say(" (first victory)"," (ilk zafer)") if reward.once else ""))
	label(v,"\n".join(rewards));label(v,say("Extra class weapon: ","Ek sınıf silahı: ")+d.weapon_grade.capitalize()+" · "+str(d.weapon_chance_bp/100.0)+"%")
	label(v,say("LittleGod rules. Bonus weapons require armory and loot space; shared random-drop rows are alternatives.","LittleGod kuralları. Ek silah için cephanelik ve ganimet alanı gerekir; rastgele ganimet satırları birbirine alternatiftir."))
	var actions=HBoxContainer.new();v.add_child(actions);var region=d.region;button(actions,say("Inspect destination","Bölgeyi incele"),func():p.playbook_region=region;p.route("destination"),true);button(actions,say("Hunt contracts","Av görevleri"),func():p.route("contracts"))
