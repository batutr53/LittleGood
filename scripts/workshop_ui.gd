extends RefCounted
const I=preload("res://scripts/industry.gd")
const K=preload("res://scripts/kingdom.gd")
var p
var game
func _init(owner):p=owner;game=p.game
func say(en,tr):return p.say(en,tr)
func label(v,value):p.playbook().label(v,value)
func button(v,value,action,primary=false):return p.playbook().button(v,value,action,primary)
func open(forge_id):
	var w=game.world;var v=p.surface(say("Hearthforge · craft","Ocak Demircisi · üretim"));var forges=w.kingdom.buildings.filter(func(b):return b.kind=="forge" and K.ready(b));p.forge_selected=int(forges[0].id) if not forges.is_empty() and not forges.any(func(b):return int(b.id)==forge_id) else forge_id
	label(v,say("Iron: ","Demir: ")+str(w.kingdom.stock.iron/1000.0)+say(" · smiths: "," · demirci: ")+str(K.assigned(w,p.forge_selected).size() if p.forge_selected>0 else 0))
	var actions=HBoxContainer.new();v.add_child(actions);button(actions,say("Staff / locate forge","Demirci personeli / konumu"),func():p.route("staffing",p.forge_selected) if p.forge_selected>0 else p.playbook().go_objective("build_forge"))
	if not w.kingdom.industry.queue.is_empty():button(actions,say("Orders: ","Sipariş: ")+str(w.kingdom.industry.queue.size()),func():p.route("forge_queue"))
	var search_row=HBoxContainer.new();v.add_child(search_row);var input=LineEdit.new();input.text=p.forge_query;input.placeholder_text=say("Recipe name","Tarif adı");input.custom_minimum_size.y=p.px(40);input.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search_row.add_child(input)
	var submit=func():p.forge_query=input.text;p.playbook_pages.forge=0;p.route("forge",p.forge_selected,false)
	input.text_submitted.connect(func(_text):submit.call());button(search_row,say("Find","Bul"),submit)
	var filter=OptionButton.new();filter.custom_minimum_size.y=p.px(40)
	for pair in [["all",say("All","Tümü")],["tool",say("Tools","Alet")],["gear",say("Gear","Donanım")],["scroll",say("Scrolls","Parşömen")]]:
		filter.add_item(pair[1]);filter.set_item_metadata(filter.item_count-1,pair[0])
		if p.craft_filter==pair[0]:filter.select(filter.item_count-1)
	filter.item_selected.connect(func(i):p.craft_filter=filter.get_item_metadata(i);p.playbook_pages.forge=0;p.route("forge",p.forge_selected,false));search_row.add_child(filter)
	var choices=[]
	for key in I.recipes():
		var d=I.recipes()[key];var category=d.get("category","tool")
		if key=="sun_relic":continue
		if p.craft_filter=="tool" and category!="tool" or p.craft_filter=="gear" and category in ["tool","upgrade_scroll"] or p.craft_filter=="scroll" and category!="upgrade_scroll":continue
		if category!="tool" and not p.H.enabled(w):continue
		if not p.forge_query.is_empty() and not (key+" "+game.realm_ui.localized(d.name)).to_lower().contains(p.forge_query.to_lower().strip_edges()):continue
		choices.append(key)
	var start=p.playbook().page(v,"forge",choices.size(),2);var row=HBoxContainer.new();v.add_child(row)
	for key in choices.slice(start,start+2):
		var recipe=key;var d=I.recipes()[key];var tile=VBoxContainer.new();tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(tile);tile.add_child(p.image(load("res://scripts/armory.gd").icon(key),Vector2(0,p.px(42))));var text=game.realm_ui.localized(d.name)+"\n"+game.realm_ui.cost(d.cost);label(tile,text)
		button(tile,say("Inspect · realm ","İncele · diyar ")+str(int(d.level)),func():p.current_recipe=recipe;p.route("recipe"),K.afford(w,d.cost))
	if choices.is_empty():label(v,say("No matching recipe.","Eşleşen tarif yok."))
	button(v,say("Close & let the smith work","Kapat ve demircinin çalışmasını izle"),p.ui.close)
func queue():
	var w=game.world;var v=p.surface(say("Forge orders","Demirci siparişleri"));var jobs=w.kingdom.industry.queue;var start=p.playbook().page(v,"forge_queue",jobs.size(),2)
	for job in jobs.slice(start,start+2):
		var id=int(job.building);var ready=w.get("estate",{}).get("craft_ready",[]).has(int(job.id));label(v,game.realm_ui.localized(I.recipes()[job.recipe].name)+" · "+(say("Ready · collect","Hazır · teslim al") if ready else str(int(job.progress*100/(int(I.recipes()[job.recipe].ticks)*1000)))+"%"));button(v,say("Inspect forge #","Demirciyi incele #")+str(id),func():p.route("building",id),ready)
	if jobs.is_empty():label(v,say("No orders. Choose a recipe.","Sipariş yok. Tarif seç."))
	button(v,say("Recipes","Tarifler"),func():p.route("forge",p.forge_selected))
func recipe():
	var w=game.world
	if not I.recipes().has(p.current_recipe):p.route("forge",p.forge_selected,false);return
	var d=I.recipes()[p.current_recipe];var v=p.surface(game.realm_ui.localized(d.name));var header=HBoxContainer.new();v.add_child(header);header.add_child(p.image(load("res://scripts/armory.gd").icon(p.current_recipe),Vector2.ONE*p.px(54)));label(header,game.realm_ui.localized(d.description))
	var forges=w.kingdom.buildings.filter(func(b):return b.kind=="forge" and K.ready(b))
	if not forges.any(func(b):return int(b.id)==p.forge_selected):p.forge_selected=0 if forges.is_empty() else int(forges[0].id)
	var keys=d.cost.keys();var start=p.playbook().page(v,"ingredients_"+p.current_recipe,keys.size(),3)
	for key in keys.slice(start,start+3):
		var resource=key;var owned=int(w.kingdom.stock.get(key,0))/1000.0;var amount=int(d.cost[key]);button(v,p.rpg.resource_name(key)+" · "+str(owned)+" / "+str(amount)+(say(" · find"," · bul") if owned<amount else " ✓"),func():p.material_target=resource;p.route("material"))
	# Probe the real command on a private clone; requirements cannot drift from the model.
	var draft=w.duplicate(true);var can_queue=I.queue(draft,p.current_recipe,p.forge_selected)
	var reason=say("Materials reserved once; collect the completed order above the forge.","Malzeme bir kez ayrılır; biten siparişi demirci üstünden teslim al.")
	if not can_queue:
		if forges.is_empty():reason=say("Finish a forge first.","Önce demirciyi tamamla.")
		elif K.level(w)<int(d.level):reason=say("Requires realm ","Gerekli diyar: ")+str(int(d.level))
		elif not K.afford(w,d.cost):reason=say("Missing materials · tap an ingredient above.","Malzeme eksik · yukarıdaki malzemeye dokun.")
		elif w.kingdom.industry.items.size()+w.kingdom.industry.queue.size()>=I.MAX_ITEMS:reason=say("Inventory full.","Çanta dolu.")
		elif w.kingdom.industry.queue.size()>=I.MAX_QUEUE:reason=say("Order queue full.","Sipariş sırası dolu.")
		else:reason=say("Requires the related story discovery or military chapter.","İlgili hikâye keşfi veya askeri bölüm gerekiyor.")
	if can_queue and K.assigned(w,p.forge_selected).is_empty():reason=say("No smith assigned. You can reserve the order now; assign a worker below to produce it.","Demirci atanmadı. Siparişi şimdi ayırabilirsin; üretim için aşağıdan işçi ata.")
	label(v,reason)
	button(v,say("Begin forging","Dövümü başlat"),func():
		if I.queue(w,p.current_recipe,p.forge_selected):game.realm_ui.changed();game.checkpoint("craft");p.route("forge_queue",0,false)
		else:p.ui.toast(say("Requirements changed. Review the recipe.","Koşullar değişti. Tarifi gözden geçir.")),true).disabled=not can_queue
	var row=HBoxContainer.new();v.add_child(row);button(row,say("Assign smith","Demirci ata"),func():p.route("staffing",p.forge_selected) if p.forge_selected>0 else p.playbook().go_objective("build_forge"));button(row,say("Recipes","Tarifler"),func():p.route("forge",p.forge_selected))
func material():
	var w=game.world;var key=p.material_target;var v=p.surface(p.rpg.resource_name(key)+say(" · sources"," · kaynaklar"));var C=load("res://scripts/colony.gd")
	label(v,say("Owned: ","Mevcut: ")+str(w.kingdom.stock.get(key,w.get("colony",{}).get("stock",{}).get(key,0))/1000.0))
	if key in C.RESOURCES:
		label(v,say("Assign an available Hearthkin to a suitable terrain node, then collect the cargo bubble.","Uygun arazi noktasına boştaki Ocaklıyı ata; ardından yük ikonundan teslim al."));button(v,say("Assign gatherer","Toplayıcı ata"),func():p.route("gathering",C.RESOURCES.find(key)),true)
	if key in ["ore","iron"]:
		label(v,say("Mine workers produce ore. A staffed furnace consumes ore and wood to make iron. Collect above the building.","Maden işçisi cevher üretir. Personelli fırın, cevher ve odun tüketerek demir üretir. Bina üstünden teslim al."))
		var kind="mine" if key=="ore" else "furnace";var found=w.kingdom.buildings.filter(func(b):return b.kind==kind)
		if found.is_empty():button(v,say("Build required building","Gerekli binayı kur"),func():p.playbook().go_objective("build_"+kind),true)
		else:button(v,say("Manage production building","Üretim binasını yönet"),func():p.route("building",int(found[0].id)),true)
	if not load("res://scripts/drop_guide.gd").search(key).is_empty():button(v,say("Find monster drops","Yaratık ganimetlerini bul"),func():p.drop_query=key;p.drop_region="all";p.route("bestiary"))
	button(v,say("Return to recipe","Tarife dön"),func():p.route("recipe"))
