extends RefCounted
const Model=preload("res://scripts/cosmetics.gd")
var ui
var game
var active=false
var item="flowers"
var cell=-1
var rotation=0
var moving=-1
var panel
var undo_stack: Array=[]
var redo_stack: Array=[]
var notice
var tab="all"
var creature_id=-1
var previous_pause=false
var context_world: Dictionary={}
func _init(interface,owner_game) -> void:ui=interface;game=owner_game
func say(en: String,tur: String) -> String:return tur if ui.language=="tr" else en
func name_of(id: String) -> String:return Model.items()[id].name[1 if ui.language=="tr" else 0]
func text_of(id: String) -> String:return Model.items()[id].description[1 if ui.language=="tr" else 0]
func add(v,text: String,callback: Callable,primary: bool=false):
	var b=ui.button(text,callback,primary);b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;v.add_child(b);return b
func image(v,id: String,size: Vector2=Vector2(110,95)) -> void:
	var art=TextureRect.new();art.texture=load("res://assets/cosmetics/"+id+".svg");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=size;v.add_child(art)
func ready_world() -> bool:
	if game.world.is_empty() or game.visiting:return false
	if not is_same(context_world,game.world):undo_stack.clear();redo_stack.clear();context_world=game.world
	var had=game.world.has("wardrobe")
	Model.ensure(game.world)
	if Model.reconcile(game.world)>0 or not had:game.schedule_save()
	return true
func collection(shop: bool=false) -> void:
	if not ready_world():ui.toast(say("Open your own planet first.","Önce kendi gezegenini aç."));return
	ui.page="customization"
	var v=ui.popup(say("Stardust atelier" if shop else "Your collection","Yıldıztozu atölyesi" if shop else "Koleksiyonun"))
	v.add_child(ui.label("✧ "+str(int(game.world.wardrobe.dust))+say(" Stardust · "," Yıldıztozu · ")+str(game.world.wardrobe.owned.size())+" / 23",20,Color("ecd99f")))
	v.add_child(ui.label(say("Earn through species, stories and thriving communities.","Türler, hikâyeler ve gelişen topluluklarla kazan."),17))
	var filter=OptionButton.new();filter.custom_minimum_size.y=48
	filter.add_theme_font_override("font",ui.ui_font());filter.add_theme_font_size_override("font_size",21)
	var keys=["all","featured","theme","decor","settlement","creature","sky","frame","favorites","premium"]
	var labels=[say("All","Tümü"),say("Featured","Öne çıkanlar"),say("Themes","Temalar"),say("Nature","Doğa"),say("Villages","Köyler"),say("Creatures","Canlılar"),say("Skies","Gökyüzü"),say("Frames","Çerçeveler"),say("Favorites","Favoriler"),say("Future premium","Gelecekteki premium")]
	for text in labels:filter.add_item(text)
	filter.selected=maxi(0,keys.find(tab));v.add_child(filter)
	filter.item_selected.connect(func(index):tab=keys[index];collection(shop))
	var list=ui.card_list(v,330)
	for id in Model.items():
		var data=Model.items()[id]
		if tab=="featured" and not id in ["crystal","willow","aurora","dreamer"]:continue
		if tab=="favorites" and not game.world.wardrobe.favorites.has(id):continue
		if not tab in ["all","favorites","featured"] and data.category!=tab:continue
		if not shop and not Model.owned(game.world,id):continue
		var row=HBoxContainer.new();list.add_child(row);image(row,id,Vector2(95,92))
		var owned=Model.owned(game.world,id)
		var b=add(row,name_of(id)+"\n"+(say("Owned","Sende var") if owned else say("Unavailable","Kullanılamaz") if data.premium else str(data.price)+" ✧"),func():detail(id,shop))
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add(v,say("My collection","Koleksiyonum") if shop else say("Browse atelier","Atölyeyi gez"),func():collection(not shop))
	add(v,say("Decorate planet","Gezegeni süsle"),palette,true)
	add(v,ui.t("back"),ui.menu)
func requirement(key: String) -> String:
	return {"none":say("Available now","Şimdi kullanılabilir"),"species2":say("Discover two species","İki tür keşfet"),"finding1":say("Discover a world story","Bir dünya hikâyesi keşfet"),"secret1":say("Discover a rare phenomenon","Nadir bir doğa olayı keşfet"),"village1":say("Welcome a community","Bir topluluk ağırlamayı başar")}.get(key,"")
func rarity(key: String) -> String:return {"common":say("Common","Yaygın"),"uncommon":say("Uncommon","Az bulunan"),"rare":say("Rare","Nadir"),"epic":say("Epic","Destansı"),"legendary":say("Legendary","Efsanevi")}.get(key,"")
func detail(id: String,shop: bool=true) -> void:
	ui.page="customization"
	var data=Model.items()[id];var v=ui.popup(name_of(id))
	image(v,id,Vector2(140,115));v.add_child(ui.label(rarity(data.rarity),17,Color("d9cba4")));v.add_child(ui.label(text_of(id),19))
	if Model.owned(game.world,id):
		if data.category in ["theme","sky","frame"]:
			add(v,say("Equip","Kullan"),func():if Model.equip(game.world,id):changed();detail(id,shop),true)
			add(v,say("Reset appearance","Görünümü sıfırla"),func():Model.unequip(game.world,data.category);changed();detail(id,shop))
		elif data.category=="creature":add(v,say("Choose a creature","Bir canlı seç"),func():choose_creature(id),true)
		else:add(v,say("Place on planet","Gezegene yerleştir"),func():begin(id),true)
	else:
		v.add_child(ui.label(say("Future store item. No price or payment is active.","Gelecekteki mağaza ürünü. Fiyat ve ödeme etkin değil.") if data.premium else requirement(data.gate)+" · "+str(data.price)+" ✧",19))
		var b=add(v,say("Not available · store integration disabled","Kullanılamaz · mağaza entegrasyonu kapalı") if data.premium else say("Unlock with Stardust","Yıldıztozuyla aç"),func():confirm(id),true)
		b.disabled=data.premium or not Model.gate(game.world,data.gate) or int(game.world.wardrobe.dust)<int(data.price)
		if data.premium:add(v,say("Restore purchases · unavailable","Satın alımları geri yükle · kullanılamaz"),func():ui.toast(say("Store verification is not connected. No purchase was restored.","Mağaza doğrulaması bağlı değil. Satın alım geri yüklenmedi.")))
	add(v,("★ " if game.world.wardrobe.favorites.has(id) else "☆ ")+say("Favorite","Favori"),func():Model.favorite(game.world,id);game.schedule_save();detail(id,shop))
	add(v,ui.t("back"),func():collection(shop))
func confirm(id: String) -> void:
	var v=ui.popup(say("Unlock this cosmetic?","Bu kozmetik açılsın mı?"));image(v,id)
	v.add_child(ui.label(name_of(id)+" · "+str(Model.items()[id].price)+" ✧\n"+say("Appearance only. No gameplay bonus.","Yalnızca görünüm. Oynanış bonusu yok."),22))
	add(v,say("Confirm unlock","Açmayı onayla"),func():
		if Model.buy(game.world,id):changed();ui.toast(say("Added to your collection","Koleksiyonuna eklendi"));detail(id)
		else:ui.toast(say("Already owned or requirements not met.","Zaten sende var veya koşullar karşılanmıyor.")),true)
	add(v,ui.t("back"),func():detail(id))
func changed() -> void:
	game.view.invalidate_cosmetics();game.schedule_save();game.audio.chime(6)
	if game.haptics and OS.has_feature("mobile"):Input.vibrate_handheld(18)
func choose_creature(id: String) -> void:
	var v=ui.popup(say("A little personality","Küçük bir kişilik"));var list=ui.card_list(v,410)
	for cr in game.world.creatures:
		var identity=int(cr.identity)
		add(list,cr.given_name+" · "+ui.species(int(cr.species)),func():Model.equip(game.world,id,identity);changed();game.view.focus_creature(game.world.creatures.find(cr));ui.close())
	add(v,ui.t("back"),func():detail(id))
func creature_looks(identity: int) -> void:
	if not ready_world():return
	creature_id=identity
	var v=ui.popup(say("Creature wardrobe","Canlı gardırobu"));ui.page="customization";var list=ui.card_list(v,380)
	for id in Model.items():
		if Model.items()[id].category=="creature" and Model.owned(game.world,id):
			add(list,name_of(id),func():Model.equip(game.world,id,identity);changed();ui.close())
	add(v,say("Natural appearance","Doğal görünüm"),func():Model.unequip(game.world,"creature",identity);changed();ui.close())
	add(v,say("Find more looks","Daha fazla görünüm bul"),func():tab="creature";collection(true))
	add(v,ui.t("back"),ui.close)
func palette() -> void:
	if not ready_world():return
	ui.page="customization";var v=ui.popup(say("Decorate your planet","Gezegenini süsle"));var list=ui.card_list(v,385)
	list.add_child(ui.label(say("Choose a piece, touch a tile, then confirm. Drag to pan; pinch to zoom. No terrain is removed.","Bir parça seç, bir hücreye dokun, sonra onayla. Sürükleyerek gez; sıkıştırarak yakınlaş. Arazi silinmez."),19))
	for id in game.world.wardrobe.owned:
		if Model.items()[id].category in ["decor","settlement"]:add(list,name_of(id),func():begin(id))
	for p in game.world.wardrobe.placements:
		var placed=p.duplicate()
		add(list,say("Move / store: ","Taşı / sakla: ")+name_of(p.item),func():begin(placed.item,int(placed.id)))
	add(v,say("Atelier","Atölye"),func():collection(true));add(v,ui.t("back"),ui.close)
func begin(id: String,move_id: int=-1) -> void:
	if not ready_world() or not Model.owned(game.world,id):return
	item=id;moving=move_id;cell=-1;rotation=0
	for p in game.world.wardrobe.placements:
		if int(p.id)==moving:cell=int(p.cell);rotation=int(p.rotation)
	previous_pause=game.paused;active=true;game.power=-1;game.paused=true
	ui.close();hud()
func hud() -> void:
	if is_instance_valid(panel):panel.queue_free()
	var cutoff=1020+maxf(0,game.get_viewport_rect().size.y-1280)
	for control in ui.root.get_children():
		if control is Control and control.position.y>=cutoff:control.hide()
	panel=VBoxContainer.new();panel.name="DecorationEditor";panel.add_theme_constant_override("separation",7)
	ui.place(panel,Rect2(28,1038,664,210))
	notice=ui.label(name_of(item)+" · "+say("Touch a tile to preview","Önizleme için bir hücreye dokun"),18);panel.add_child(notice)
	var row=HBoxContainer.new();panel.add_child(row)
	add(row,say("Rotate","Döndür"),func():rotation=(rotation+1)%4;game.view.queue_redraw())
	add(row,say("Place","Yerleştir"),commit,true)
	add(row,say("Store","Sakla"),store)
	var tools=HBoxContainer.new();panel.add_child(tools)
	add(tools,say("Undo","Geri al"),func():history(false))
	add(tools,say("Redo","Yinele"),func():history(true))
	add(tools,say("Pieces","Parçalar"),func():finish();palette())
	add(tools,say("Done","Tamam"),finish,true)
	for container in [row,tools]:
		for button in container.get_children():button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",18)
func pick(pos: Vector2) -> void:
	cell=game.view.pick(pos)
	if cell<0:return
	var good=Model.valid_place(game.world,item,cell,moving)
	var rule=say("Edge water only","Yalnızca kenar suyu") if item=="falls" else say("Choose an existing village","Var olan bir köy seç") if Model.items()[item].category=="settlement" else say("Choose clear land away from a village","Köyden uzakta boş kara seç")
	if moving<0 and game.world.wardrobe.placements.size()>=Model.MAX_PLACEMENTS:rule=say("32 pieces · store one to place another","32 parça · yenisi için birini sakla")
	notice.text=name_of(item)+" · "+(say("Ready to place","Yerleşim uygun") if good else rule)
func remember() -> void:
	undo_stack.append(game.world.wardrobe.placements.duplicate(true))
	if undo_stack.size()>20:undo_stack.pop_front()
	redo_stack.clear()
func commit() -> void:
	if cell<0 or not Model.valid_place(game.world,item,cell,moving):return
	remember()
	if Model.place(game.world,item,cell,rotation,moving)<0:undo_stack.pop_back();return
	game.view.effects.append({"cell":cell,"age":0.0,"power":5});moving=-1;cell=-1;changed()
	notice.text=say("Placed · choose another tile or piece","Yerleştirildi · başka hücre veya parça seç")
func store() -> void:
	if moving<0:return
	remember();Model.remove(game.world,moving);moving=-1;cell=-1;changed()
func history(redo: bool) -> void:
	var source=redo_stack if redo else undo_stack
	var target=undo_stack if redo else redo_stack
	if source.is_empty():return
	target.append(game.world.wardrobe.placements.duplicate(true));game.world.wardrobe.placements=source.pop_back();moving=-1;cell=-1;changed()
func finish() -> void:
	active=false
	if is_instance_valid(panel):panel.queue_free()
	game.paused=previous_pause;game.view.invalidate_cosmetics();game.checkpoint("decoration");ui.world_controls(true);ui.refresh()
