extends RefCounted
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
const H=preload("res://scripts/hero.gd")
var game
var ui
var active=false
var mode=""
var kind=""
var cell=-1
var moving=0
var previous_pause=false
var panel
var notice
func _init(owner_game,interface) -> void:game=owner_game;ui=interface
func say(en: String,tr: String) -> String:return tr if ui.language=="tr" else en
func localized(pair: Array) -> String:return pair[1 if ui.language=="tr" else 0]
func add(parent,text: String,callback: Callable,primary: bool=false):
	var b=ui.button(text,callback,primary);b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(b);return b
func available() -> bool:return not game.visiting and not game.world.is_empty()
func changed() -> void:
	game.view.invalidate_cosmetics();game.schedule_save();ui.refresh();game.audio.chime(6)
func resources() -> String:
	var w=game.world;var s=w.kingdom.stock
	var text=say("Food","Besin")+" "+str(int(K.home(w).food))+"  ·  "+say("Wood","Odun")+" "+str(int(s.wood/K.SCALE))+"  ·  "+say("Stone","Taş")+" "+str(int(s.stone/K.SCALE))+"  ·  "+say("Gold","Altın")+" "+str(int(s.gold/K.SCALE))
	if I.enabled(w):text+="\n"+say("Ore","Cevher")+" "+str(snappedf(s.ore/float(K.SCALE),.1))+"  ·  "+say("Iron","Demir")+" "+str(snappedf(s.iron/float(K.SCALE),.1))
	return text
func open() -> void:
	if not available():return
	if active:finish()
	if not game.world.has("kingdom"):intro();return
	ui.page="kingdom"
	var w=game.world;var q=K.current(w)
	var v=ui.popup(say("The First Kingdom","İlk Krallık"));var list=ui.card_list(v,405)
	list.add_child(ui.label(say("Realm ","Diyar ")+str(K.level(w))+" · "+say("Development tier ","Gelişim aşaması ")+str(K.tier(w))+" · "+str(w.kingdom.claimed.size())+(" / 10" if I.enabled(w) else " / 5"),22,Color("ecd99f")))
	list.add_child(ui.label(resources(),18))
	if w.kingdom.advisor:
		var row=HBoxContainer.new();list.add_child(row)
		var portrait=TextureRect.new();portrait.texture=load("res://assets/kingdom/arin.png");portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(102,110);row.add_child(portrait)
		var words=ui.label(say("Elder Arin\n","Bilge Arin\n")+(localized(q.description) if not q.is_empty() else say("Our first village stands. Care for it while the next chapter is prepared.","İlk köyümüz kuruldu. Yeni bölüm hazırlanırken onu gözet.")),19);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(words)
	if not q.is_empty():
		list.add_child(ui.label(localized(q.title),25,Color("ecd99f")))
		for o in q.objectives:
			var value=minf(float(o.target),K.progress(w,o))
			add(list,("✓ " if value>=float(o.target) else "◇ ")+localized(o.text)+" · "+str(int(value))+" / "+str(int(o.target)),func():navigate(o.navigate))
		list.add_child(ui.label(say("Reward: ","Ödül: ")+cost(q.rewards),18))
		var claim=add(list,say("Claim verified reward","Doğrulanan ödülü al"),func():claim_reward(q.id),true);claim.disabled=not K.complete(w,q)
	elif not I.enabled(w):
		list.add_child(ui.label(say("Your village is ready for the Iron Age. Continue with five quests about mines, smelting and tools. Your existing citizens, resources and rewards stay yours.","Köyün Demir Çağı'na hazır. Maden, döküm ve aletlerle ilgili beş görevle devam et. Sakinlerin, kaynakların ve ödüllerin korunur."),20))
		add(list,say("Begin Chapter II · the Iron Age","Bölüm II'ye başla · Demir Çağı"),func():if I.enable(w):changed();game.checkpoint("iron-age");open(),true)
	elif not H.enabled(w):
		list.add_child(ui.label(say("Arin has found a trail beyond the border. Choose a champion for the Wild Lands; your kingdom and equipment remain intact.","Arin sınırın ötesinde bir iz buldu. Yaban Topraklar için şampiyon seç; krallığın ve donanımların korunur."),20))
		add(list,say("Begin Chapter III · The Wild Lands","Bölüm III'e başla · Yaban Topraklar"),func():if H.enable(w):changed();game.checkpoint("chapter3");game.hero_ui.profile(),true)
	else:list.add_child(ui.label(say("Your champion is ready. Continue caring for the kingdom.","Şampiyonun hazır. Krallığınla ilgilenmeye devam et."),20))
	if H.enabled(w):add(list,say("Hero Hall","Kahraman Salonu"),game.hero_ui.profile)
	if I.enabled(w):
		add(list,say("Workshop · craft with a smith","Atölye · demirciyle üret"),workshop)
		add(list,say("Inventory & citizen tools","Envanter ve sakin aletleri"),inventory)
	add(list,say("Gather timber / stone","Odun / taş topla"),gather_menu)
	add(list,say("Kingdom history","Krallık tarihi"),history)
	add(list,say("Hide advisor" if w.kingdom.advisor else "Replay advisor help","Danışmanı gizle" if w.kingdom.advisor else "Danışman yardımını göster"),func():w.kingdom.advisor=not w.kingdom.advisor;game.schedule_save();open())
	var row=HBoxContainer.new();v.add_child(row)
	for entry in [[say("Buildings","Binalar"),construction],[say("Workers","İşçiler"),workers]]:
		var button=add(row,entry[0],entry[1]);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add(v,say("Watch the village","Köyü izle"),ui.close,true)
func intro() -> void:
	ui.page="kingdom";var v=ui.popup(say("Elder Arin awaits","Bilge Arin seni bekliyor"))
	var portrait=TextureRect.new();portrait.texture=load("res://assets/kingdom/arin.png");portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(160,180);v.add_child(portrait)
	v.add_child(ui.label(say("Your settlers can build a home together. Begin the First Flame: five quests, real work and a growing village.","Yerleşimcilerin birlikte bir yuva kurabilir. İlk Alev'e başla: beş görev, gerçek işler ve büyüyen bir köy."),23))
	v.add_child(ui.label(say("One-time founding stores: 12 stone, 8 gold. Food and people remain your existing settlement's. Stardust stays cosmetic.","Bir defalık kuruluş erzağı: 12 taş, 8 altın. Besin ve insanlar mevcut yerleşiminden gelir. Yıldıztozu kozmetik içindir."),19))
	add(v,say("Awaken the First Kingdom","İlk Krallığı uyandır"),func():if K.enable(game.world):changed();open(),true)
	add(v,say("Keep exploring for now","Şimdilik keşfetmeye devam et"),ui.close)
func cost(data: Dictionary) -> String:
	var terms: Array[String]=[]
	for key in data:
		var title={"wood":say("wood","odun"),"stone":say("stone","taş"),"gold":say("gold","altın"),"ore":say("ore","cevher"),"iron":say("iron","demir"),"xp":say("Realm XP","Diyar XP")}.get(key,key)
		terms.append(str(int(data[key]))+" "+title)
	return " · ".join(terms)
func claim_reward(id: String) -> void:
	if not K.claim(game.world,id):ui.toast(say("Complete every objective first.","Önce tüm hedefleri tamamla."));return
	changed();ui.close()
	game.view.effects.append({"cell":int(K.home(game.world).cell),"age":0.0,"power":5})
	var message=ui.label(say("Realm ","Diyar ")+str(K.level(game.world))+" · "+say("A new beginning","Yeni bir başlangıç"),33,Color("f3dda8"))
	message.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.place(message,Rect2(40,390,640,70));message.modulate.a=0
	var tween=ui.create_tween();tween.tween_property(message,"modulate:a",1.0,.2);tween.tween_interval(1.0);tween.tween_property(message,"modulate:a",0.0,.4);tween.tween_callback(message.queue_free)
	ui.toast(say("Reward delivered once. Tap the quest for your next step.","Ödül bir kez verildi. Sonraki adım için göreve dokun."))
func construction() -> void:
	if not available() or not game.world.has("kingdom"):return
	ui.page="kingdom";var v=ui.popup(say("Build a living village","Yaşayan bir köy kur"));var list=ui.card_list(v,440)
	for id in K.buildings():
		var data=K.buildings()[id]
		if int(data.level)>5 and not I.enabled(game.world):continue
		var row=HBoxContainer.new();list.add_child(row)
		var image=TextureRect.new();image.texture=load("res://assets/kingdom/"+id+".svg");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(90,90);row.add_child(image)
		var button=add(row,localized(data.name)+" · "+say("Realm ","Diyar ")+str(int(data.level))+" · "+str(game.world.kingdom.buildings.filter(func(b):return b.kind==id).size())+"/"+str(int(data.limit))+"\n"+cost(data.cost),func():begin("build",id));button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.disabled=K.level(game.world)<int(data.level) or not K.afford(game.world,data.cost) or game.world.kingdom.buildings.size()>=K.MAX_BUILDINGS or game.world.kingdom.buildings.filter(func(b):return b.kind==id).size()>=int(data.limit)
	for b in game.world.kingdom.buildings:
		var id=int(b.id)
		add(list,localized(K.buildings()[b.kind].name)+" "+str(int(b.level))+" · "+(say("Inspect","İncele") if K.ready(b) else str(int(float(b.progress)/float(b.required)*100))+"%"),func():inspect_building(id))
	add(v,ui.t("back"),open)
func workers() -> void:
	if not available() or not game.world.has("kingdom"):return
	ui.page="kingdom";var w=game.world;var v=ui.popup(say("People & work","İnsanlar ve işler"));var list=ui.card_list(v,410)
	list.add_child(ui.label(say("Residents / housing: ","Sakin / konut: ")+str(int(K.home(w).population))+" / "+str(K.capacity(w))+"\n"+say("Idle builders: ","Boştaki inşaatçılar: ")+str(K.assigned(w,0).size())+" · "+say("Trust: ","Güven: ")+str(int(w.kingdom.stability/10))+"%",21))
	list.add_child(ui.label(say("Idle citizens build. Assigned workers produce only on suitable land with local resources. Panels pause time; return to watch work.","Boştakiler inşa eder. Atanan işçiler uygun arazi ve yerel kaynaklarla üretir. Paneller zamanı durdurur; çalışmayı izlemek için dön."),18))
	for c in w.kingdom.workers:
		var id=int(c.id);var job=say("Builder / free citizen","İnşaatçı / boşta")
		for b in w.kingdom.buildings:
			if int(b.id)==int(c.building):job=localized(K.buildings()[b.kind].role)
		var equipped=I.tool(w,id);var tool_text=" · "+localized(I.recipes()[equipped.recipe].name) if not equipped.is_empty() else ""
		add(list,c.name+" · "+job+" · "+str(snappedf(c.skill/float(K.SCALE),.01))+"×"+tool_text,func():assignments(id))
	var recruit=add(v,say("Recruit citizen · 2 food + 1 gold","Sakin işe al · 2 besin + 1 altın"),func():
		if K.recruit(w):changed();workers()
		else:ui.toast(say("Realm 4, food, gold, trust and a resident or housing space are required.","Diyar 4, besin, altın, güven ve bir sakin veya boş konut gerekli.")),true)
	recruit.disabled=K.level(w)<4 or w.kingdom.workers.size()>=K.MAX_WORKERS
	add(v,ui.t("back"),open)
func assignments(worker: int) -> void:
	ui.page="kingdom";var v=ui.popup(say("Choose a profession","Bir meslek seç"));var list=ui.card_list(v,400)
	if I.enabled(game.world):add(list,say("Choose or compare tool","Alet seç veya karşılaştır"),func():choose_tool(worker))
	add(list,say("Builder / unassign","İnşaatçı / atamayı kaldır"),func():if K.assign(game.world,worker,0):changed();ui.close())
	for b in game.world.kingdom.buildings:
		var data=K.buildings()[b.kind];var id=int(b.id)
		if not K.ready(b) or int(data.slots)==0:continue
		var button=add(list,localized(data.name)+" · "+str(K.assigned(game.world,id).size())+" / "+str(int(data.slots)),func():if K.assign(game.world,worker,id):changed();ui.close();ui.toast(say("Assigned · watch your worker at the building","Atandı · işçini binada izle")),true)
		button.disabled=K.assigned(game.world,id).size()>=int(data.slots)
	add(v,ui.t("back"),workers)
func inspect_building(id: int) -> void:
	for b in game.world.kingdom.buildings:
		if int(b.id)!=id:continue
		var data=K.buildings()[b.kind];ui.page="kingdom";var v=ui.popup(localized(data.name))
		v.add_child(ui.label(localized(data.description),22))
		var output=say("Forge labor / tick: ","Demirci emeği / tur: ") if b.kind=="forge" else say("Available output / tick: ","Kullanılabilir üretim / tur: ")
		v.add_child(ui.label(say("Level ","Seviye ")+str(int(b.level))+" · "+str(int(float(b.progress)/float(b.required)*100))+"%\n"+output+str(snappedf(K.activity_rate(game.world,b),.01))+"\n"+say("Storage per material: ","Malzeme başına depo: ")+str(int(K.storage(game.world))),21))
		v.add_child(ui.label(say("Requires assigned workers, moisture/forest and available local resources. Full storage stops production. Unassign one worker if construction is stalled.","Atanmış işçi, nem/orman ve yerel kaynak gerekir. Dolu depo üretimi durdurur. İnşaat durmuşsa bir işçiyi boşa çıkar."),19))
		if data.has("inputs"):v.add_child(ui.label(say("Consumes per iron: ","Demir başına tüketim: ")+cost(data.inputs),19))
		if b.kind=="forge":add(v,say("Open workshop","Atölyeyi aç"),func():workshop(id),true)
		var upgrade=add(v,say("Upgrade · ","Geliştir · ")+cost(K.upgrade_cost(b)),func():if K.upgrade(game.world,id):changed();ui.close(),true);upgrade.disabled=not K.ready(b) or int(b.level)>=3 or not K.afford(game.world,K.upgrade_cost(b))
		add(v,say("Relocate","Yerini değiştir"),func():begin("build",b.kind,id));add(v,say("Assign workers","İşçi ata"),workers);add(v,say("Watch work","Çalışmayı izle"),func():focus(int(b.cell)))
		return
func history() -> void:
	ui.page="kingdom";var v=ui.popup(say("The First Kingdom's history","İlk Krallığın tarihi"));var list=ui.card_list(v,450)
	for h in game.world.kingdom.history:
		var action={"founding":say("Founding","Kuruluş"),"construction":say("Construction started","İnşaat başladı"),"built":say("Completed","Tamamlandı"),"upgrade":say("Upgrade started","Geliştirme başladı"),"recruit":say("Citizen recruited","Sakin işe alındı"),"quest":say("Quest completed","Görev tamamlandı"),"craft":say("Tool completed","Alet tamamlandı")}.get(h.key,"")
		var title=str(h.subject)
		if K.buildings().has(title):title=localized(K.buildings()[title].name)
		if I.recipes().has(title):title=localized(I.recipes()[title].name)
		for q in K.quests():
			if q.id==title:title=localized(q.title)
		list.add_child(ui.label(say("Day ","Gün ")+str(1+int(h.tick)/30)+" · "+action+" · "+title,20))
	add(v,ui.t("back"),open)
func gather_menu() -> void:
	ui.page="kingdom";var v=ui.popup(say("Gather from your land","Arazinden kaynak topla"))
	v.add_child(ui.label(say("Gather up to three from an actual forest or mountain every four simulation ticks. Camps automate gathering; nothing is created by clicking.","Dört simülasyon turunda bir gerçek orman veya dağdan en çok üç kaynak topla. Kamplar toplama işini otomatikleştirir; tıklama kaynak yaratmaz."),22))
	add(v,say("Wood · forest","Odun · orman"),func():begin("gather","wood"),true);add(v,say("Stone · mountain","Taş · dağ"),func():begin("gather","stone"));add(v,ui.t("back"),open)
func navigate(action: String) -> void:
	if action=="settlers":focus(int(K.home(game.world).cell));ui.toast(say("Touch the settlers' camp to meet them.","Tanışmak için yerleşimcilerin kampına dokun."))
	elif action=="workers":workers()
	elif action=="workshop":workshop()
	elif action=="inventory":inventory()
	elif action=="hero":game.hero_ui.profile()
	elif action.begins_with("build_"):begin("build",action.trim_prefix("build_"))
	elif action.begins_with("gather_"):begin("gather",action.trim_prefix("gather_"))
	else:open()
func focus(index: int) -> void:
	ui.close();game.power=-1;game.view.pan=-game.view.project(game.world.cells[index])*game.view.zoom;game.view.selected=index
func workshop(forge_id: int=0) -> void:
	if not available() or not I.enabled(game.world):return
	ui.page="kingdom";var w=game.world;var v=ui.popup(say("The Hearthforge","Ocak Demircisi"));var list=ui.card_list(v,470)
	list.add_child(ui.label(resources(),18))
	list.add_child(ui.label(say("Assign a smith to a finished forge. Materials are reserved when queued; work continues after you close this menu. Tools are made once and can be moved between citizens.","Tamamlanmış demirciye bir işçi ata. Sıraya alınca malzeme ayrılır; menüyü kapatınca iş ilerler. Aletler bir kez üretilir ve sakinler arasında taşınabilir."),19))
	var forges=w.kingdom.buildings.filter(func(b):return b.kind=="forge" and K.ready(b))
	var selected=forge_id
	if not forges.any(func(b):return int(b.id)==selected):selected=0 if forges.is_empty() else int(forges[0].id)
	if forges.size()>1:
		for building in forges:
			var id=int(building.id);add(list,say("Forge #","Demirci #")+str(id)+(" ✓" if id==selected else ""),func():workshop(id))
	for id in I.recipes():
		var data=I.recipes()[id];var row=HBoxContainer.new();list.add_child(row)
		if data.get("category","tool")!="tool" and (not H.enabled(w) or int(data.level)>H.REALM_CAP):row.queue_free();continue
		var preview=TextureRect.new();preview.texture=load("res://assets/kingdom/"+id+".svg");preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;preview.custom_minimum_size=Vector2(82,88);row.add_child(preview)
		var button=add(row,localized(data.name)+"\n"+cost(data.cost)+"\n"+localized(data.description),func():
			if selected>0 and I.queue(w,id,selected):changed();workshop(selected);ui.toast(say("Materials reserved · close the menu and watch your smith.","Malzeme ayrıldı · menüyü kapat ve demircini izle."))
			else:ui.toast(say("Needs realm 9, a finished forge, materials and inventory space.","Diyar 9, tamamlanmış demirci, malzeme ve envanter alanı gerekli.")))
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.disabled=forges.is_empty() or K.level(w)<int(data.level) or not K.afford(w,data.cost) or w.kingdom.industry.items.size()+w.kingdom.industry.queue.size()>=I.MAX_ITEMS or w.kingdom.industry.queue.size()>=I.MAX_QUEUE
	for job in w.kingdom.industry.queue:
		var data=I.recipes()[job.recipe];list.add_child(ui.label(localized(data.name)+" · #"+str(int(job.building))+" · "+str(int(float(job.progress)/(int(data.ticks)*K.SCALE)*100))+"%",19))
	if selected>0:list.add_child(ui.label(say("Assigned smiths: ","Atanmış demirciler: ")+str(K.assigned(w,selected).size()),19))
	add(v,say("Assign workers","İşçi ata"),workers);add(v,say("Watch the village","Köyü izle"),ui.close,true);add(v,ui.t("back"),open)
func inventory() -> void:
	if not available() or not I.enabled(game.world):return
	ui.page="kingdom";var w=game.world;var v=ui.popup(say("Tools & citizens","Aletler ve sakinler"));var list=ui.card_list(v,450)
	list.add_child(ui.label(say("One tool per citizen. Compare its effect with the current tool; moving it frees its previous owner. Bonuses apply only to the listed jobs.","Sakin başına bir alet. Etkisini mevcut aletle karşılaştır; taşırsan önceki sahibinden çıkar. Bonuslar yalnızca belirtilen işlerde geçerlidir."),20))
	list.add_child(ui.label(say("Owned tools: ","Üretilen alet: ")+str(w.kingdom.industry.items.size())+" / "+str(I.MAX_ITEMS),19))
	for c in w.kingdom.workers:
		var owned=I.tool(w,int(c.id));var id=int(c.id)
		add(list,c.name+" · "+(localized(I.recipes()[owned.recipe].name) if not owned.is_empty() else say("No tool","Alet yok")),func():choose_tool(id))
	add(v,say("Craft another tool","Yeni alet üret"),workshop);add(v,ui.t("back"),open)
func choose_tool(worker: int) -> void:
	if not I.enabled(game.world):return
	var w=game.world;var citizens=w.kingdom.workers.filter(func(c):return int(c.id)==worker)
	if citizens.is_empty():return
	ui.page="kingdom";var v=ui.popup(citizens[0].name+say(" · choose tool"," · alet seç"));var list=ui.card_list(v,460)
	var equipped=I.tool(w,worker)
	list.add_child(ui.label(say("Current: ","Mevcut: ")+(localized(I.recipes()[equipped.recipe].name)+"\n"+localized(I.recipes()[equipped.recipe].description) if not equipped.is_empty() else say("No tool · base work rate","Alet yok · temel iş hızı")),21))
	for owned in w.kingdom.industry.items:
		var data=I.recipes()[owned.recipe];var id=int(owned.id)
		add(list,localized(data.name)+" #"+str(id)+"\n"+localized(data.description),func():if I.equip(w,worker,id):changed();inventory(),true)
	add(list,say("Unequip · return to inventory","Çıkar · envantere dönsün"),func():if I.equip(w,worker,0):changed();inventory())
	add(v,ui.t("back"),inventory)
func begin(new_mode: String,id: String,move_id: int=0) -> void:
	if not available() or not game.world.has("kingdom"):return
	if game.decorator.active:game.decorator.finish()
	if active:finish()
	mode=new_mode;kind=id;moving=move_id;cell=-1;previous_pause=game.paused;game.paused=true;game.power=-1;active=true;ui.close()
	panel=VBoxContainer.new();panel.name="KingdomPlacement";ui.place(panel,Rect2(28,1040,664,178))
	for child in ui.root.get_children():
		if child!=panel and child is Control and child.position.y>=1020+maxf(0,game.get_viewport_rect().size.y-1280):child.hide()
	notice=ui.label(say("Touch a suitable tile · drag / pinch to navigate","Uygun hücreye dokun · sürükle / sıkıştır"),18);panel.add_child(notice)
	var row=HBoxContainer.new();panel.add_child(row)
	for entry in [[say("Confirm","Onayla"),commit],[say("Cancel","İptal"),finish]]:
		var b=add(row,entry[0],entry[1],true);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for i in range(game.world.cells.size()):
		if valid(i):cell=i;game.view.pan=-game.view.project(game.world.cells[i])*game.view.zoom;break
func valid(index: int) -> bool:
	if index<0 or index>=game.world.cells.size():return false
	if mode=="build":return K.valid_site(game.world,kind,index,moving)
	return int(game.world.cells[index].biome)==1 if kind=="wood" else int(game.world.cells[index].biome) in [3,4]
func pick(pos: Vector2) -> void:
	cell=game.view.pick(pos)
	if cell<0:return
	notice.text=say("Ready · confirm when you like the place","Uygun · konumu beğendiğinde onayla") if valid(cell) else say("Needs clear suitable land; avoid buildings, water and decor.","Uygun boş arazi seç; bina, su ve dekordan uzak dur.")
func commit() -> void:
	if not valid(cell):return
	var success=false
	if mode=="build":success=K.move(game.world,moving,cell) if moving>0 else K.begin_build(game.world,kind,cell)>0
	else:success=K.gather(game.world,kind,cell)>0
	if not success:ui.toast(say("Check level, costs, plot limits, storage or gather cooldown. Return to the planet to let time pass.","Seviye, maliyet, bina sınırı, depo veya toplama süresini kontrol et. Zamanın geçmesi için gezegene dön."));return
	var target=cell;changed();finish();game.view.effects.append({"cell":target,"age":0.0,"power":5})
	ui.toast(say("The village is at work. Keep a free citizen for construction.","Köy iş başında. İnşaat için bir sakini boşta bırak."))
func finish() -> void:
	if not active:return
	active=false;game.paused=previous_pause
	if is_instance_valid(panel):panel.queue_free()
	ui.world_controls(true);changed();game.checkpoint("kingdom")
