extends RefCounted
const K=preload("res://scripts/kingdom.gd")
const C=preload("res://scripts/colony.gd")
var p
var game
func _init(owner):p=owner;game=p.game
func say(en,tr):return p.say(en,tr)
func label(v,value):p.playbook().label(v,value)
func button(v,value,action,primary=false):return p.playbook().button(v,value,action,primary)
func upgrade(id):
	var w=game.world;var found=w.get("kingdom",{}).get("buildings",[]).filter(func(b):return int(b.id)==id)
	if found.is_empty():p.route("guide");return
	var b=found[0];game.view.select_cell(int(b.cell));var level=int(b.level);var v=p.surface(game.realm_ui.localized(K.buildings()[b.kind].name)+say(" · upgrade"," · geliştirme"));label(v,say("Level ","Seviye ")+str(level)+" → "+str(level+1) if level<3 else say("Maximum level · 3","Son seviye · 3"))
	if level>=3:label(v,say("This building has reached its current limit.","Bu bina mevcut geliştirme sınırına ulaştı."));button(v,say("Building","Bina"),func():p.route("building",id));return
	var cost=K.upgrade_cost(b)
	for key in cost:
		var resource=key;var owned=int(w.kingdom.stock.get(key,0))/1000.0;var title=p.rpg.resource_name(key)+" · "+str(snappedf(owned,.01))+" / "+str(cost[key])
		button(v,("✓ " if owned>=float(cost[key]) else "◇ ")+title,func():
			if p.I.enabled(w):p.material_target=resource;p.material_return="building_upgrade";p.material_return_arg=id;p.route("material")
			else:p.route("gathering",C.RESOURCES.find(resource)))
	var reason=say("Materials are spent once. Production pauses during the upgrade; free builders finish the work.","Malzeme bir kez harcanır. Geliştirme sırasında üretim durur; boştaki inşaatçılar yapıyı tamamlar.")
	var reserved=load("res://scripts/trade.gd").building_reserved(w,id)
	if not K.ready(b):reason=say("Construction already in progress. Assign builders first.","İnşaat zaten sürüyor. Önce inşaatçı ayır.")
	elif reserved:reason=say("A caravan reserves this building. Collect its return first.","Bu bina kervana ayrılmış. Önce dönen kervanı teslim al.")
	elif not K.afford(w,cost):reason=say("Missing materials. Tap a material above to find its source.","Malzeme eksik. Kaynağını bulmak için yukarıdaki malzemeye dokun.")
	label(v,reason)
	button(v,say("Confirm upgrade","Geliştirmeyi onayla"),func():
		var current=w.kingdom.buildings.filter(func(item):return int(item.id)==id)
		if current.size()==1 and int(current[0].level)==level and K.upgrade(w,id):game.realm_ui.changed();game.checkpoint("building-upgrade");p.route("building",id,false)
		else:p.ui.toast(say("Building or supplies changed. Review again.","Bina veya erzak değişti. Yeniden incele.")),true).disabled=not K.ready(b) or reserved or not K.afford(w,cost) or w.get("_read_only",false)
	var row=HBoxContainer.new();v.add_child(row);button(row,say("Builders","İnşaatçılar"),func():p.route("staffing",id));button(row,say("Back","Geri"),func():p.route("building",id))
func terrain(cell):
	var w=game.world
	if cell<0 or cell>=w.cells.size():p.ui.close();return
	game.view.select_cell(cell);var c=w.cells[cell];var v=p.surface(Biomes.title(int(c.biome),p.ui.language)+" · "+str(int(c.x))+","+str(int(c.y)));label(v,say("Deposit: ","Rezerv: ")+str(snappedf(c.resources,.1))+say(" · moisture "," · nem ")+str(roundi(c.moisture*100))+"%")
	var resources=["wood"] if int(c.biome)==1 else ["stone","gold","copper","silver"] if int(c.biome) in [3,4] else ["water","fish"] if int(c.biome)==6 else ["clay"] if int(c.biome) in [0,5] else []
	if not C.enabled(w):label(v,say("Found your colony to assign gatherers.","Toplayıcı atamak için kolonini kur."));button(v,say("Found colony","Kolonini kur"),func():p.route("colony"));return
	var free=K.assigned(w,0);var selector=OptionButton.new();selector.custom_minimum_size.y=p.px(40);selector.name="ResourceWorker";v.add_child(selector)
	for worker in free:selector.add_item(worker.name);selector.set_item_metadata(selector.item_count-1,int(worker.id))
	if free.is_empty():selector.add_item(say("No available worker","Uygun işçi yok"));selector.disabled=true
	var start=p.playbook().page(v,"terrain_resources",resources.size(),3)
	for key in resources.slice(start,start+3):
		var resource=key;var b=button(v,say("Assign to ","Toplamaya ata: ")+C.NAMES[key][1 if p.ui.language=="tr" else 0],func():
			var id=int(selector.get_item_metadata(selector.selected))
			if C.start(w,id,resource,cell):game.view.select_worker(id);game.realm_ui.changed();p.route("worker",id,false)
			else:p.ui.toast(say("Worker or source unavailable. Review the assignment.","İşçi veya kaynak uygun değil. Atamayı yeniden incele.")),true);b.disabled=free.is_empty() or not C.accepts_source(w,key,cell) or w.get("_read_only",false)
	if resources.is_empty():label(v,say("No field resource here. Inspect suitable building sites.","Burada toplama kaynağı yok. Uygun inşaat yerlerini incele."))
	var row=HBoxContainer.new();v.add_child(row);button(row,say("Choose building","Bina seç"),func():p.route("construction")).disabled=int(c.biome)==6;button(row,say("Worker duties","İşçi görevleri"),func():p.route("workers"))
func settlement(cell):
	var w=game.world;var found=w.settlements.filter(func(home):return int(home.cell)==cell)
	if found.is_empty():p.ui.close();return
	game.view.select_cell(cell);var home=found[0];var v=p.surface(str(home.given_name));label(v,say("Settlement stage ","Yerleşim aşaması ")+str(int(home.stage)+1)+" · "+str(int(home.population))+say(" residents"," sakin"));label(v,say("Food: ","Besin: ")+str(snappedf(home.food,.1))+" / 100")
	label(v,say("This is your original settlement. Grow it through food, trust and the current chapter; it is not a separate paid upgrade.","Bu, ilk yerleşimin. Besin, güven ve güncel bölümle geliştir; ayrı bir ücretli yükseltmesi yok."));button(v,say("Current objective","Güncel hedef"),func():p.route("quest"),true);button(v,say("Workers and housing","İşçiler ve konut"),func():p.route("guide"));button(v,say("Food and resources","Besin ve kaynak"),func():p.route("resources"));button(v,say("Settlement defense","Yerleşim savunması"),func():p.route("defense"))
func enemy(id):
	var run=game.world.get("kingdom",{}).get("adventure",{}).get("run",{});var found=run.get("enemies",[]).filter(func(e):return int(e.id)==id and e.hp>0)
	if found.is_empty():p.ui.toast(say("Target is no longer available.","Hedef artık mevcut değil."));p.ui.close();return
	var e=found[0];var d=load("res://scripts/adventure.gd").enemies()[e.kind];var v=p.surface(game.realm_ui.localized(d.name));label(v,say("Health: ","Can: ")+str(int(e.hp))+" / "+str(int(d.health))+" · XP "+str(int(d.xp)));label(v,say("Attack: ","Saldırı: ")+str(int(d.attack))+say(" · armor: "," · zırh: ")+str(int(d.defense)))
	for goal in load("res://scripts/quest_targets.gd").for_enemy(game.world,str(e.kind),p.tracked_recipe):label(v,(game.realm_ui.localized(goal.title) if goal.resource.is_empty() else p.rpg.resource_name(goal.resource))+" · "+str(goal.have)+" / "+str(goal.need))
	label(v,say("Watch the attack warning, dodge its strike, then attack during recovery. Move closer if range or terrain blocks a hit.","Saldırı uyarısını izle, darbeden kaçın ve dinlenme aralığında vur. Menzil veya arazi engelliyorsa yaklaş."));label(v,say("Inspecting pauses combat. Closing restores the previous pause state.","İnceleme savaşı duraklatır. Kapatınca önceki duraklama durumuna döner."));button(v,say("View actual drops","Gerçek ganimetleri gör"),func():p.drop_query=e.kind;p.drop_region="all";p.route("bestiary"));button(v,say("Return to target","Hedefe dön"),p.ui.close,true)
