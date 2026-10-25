extends RefCounted
const R=preload("res://scripts/rpg_progression.gd")
const H=preload("res://scripts/hero.gd")
const I=preload("res://scripts/industry.gd")
const T=preload("res://scripts/premium_theme.gd")
var p
var ui
var game
var selected_item=0
var details: VBoxContainer
var draft={}
var chat_box: Panel
var chat_reopen: Button
var chat_collapsed=false
var hud_portrait: TextureRect
var hud_class=""
var target_slot=""
var classic
var details_window: PanelContainer
func compact_button(b: Button):
	for state in ["normal","hover","pressed","disabled","focus"]:
		var skin=b.get_theme_stylebox(state).duplicate();skin.content_margin_left=p.px(6);skin.content_margin_right=p.px(6);skin.content_margin_top=p.px(4);skin.content_margin_bottom=p.px(4);b.add_theme_stylebox_override(state,skin)
func _init(presentation):p=presentation;ui=p.ui;game=p.game
func say(en,tr):return p.say(en,tr)
func stat_name(key: String) -> String:
	return {"health":"Can","attack":"Saldırı","defense":"Savunma","speed":"Hız","crit":"Kritik","strength":"Güç","dexterity":"Çeviklik","intelligence":"Zekâ","magic":"Büyü Gücü","vitality":"Dayanıklılık"}.get(key,key.capitalize()) if ui.language=="tr" else key.capitalize()
func card(rect: Rect2) -> Panel:
	var panel=Panel.new();panel.add_theme_stylebox_override("panel",T.box(Color(.065,.064,.055,.88),true));p.put(panel,rect);return panel
func icon_action(parent: Control,key: String,label: String,cb: Callable) -> Button:
	var b=ui.button(label,cb);b.icon=T.icon(key);b.expand_icon=true;b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.alignment=HORIZONTAL_ALIGNMENT_CENTER;b.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP;b.add_theme_constant_override("icon_max_width",int(p.px(24)));b.add_theme_constant_override("h_separation",0);b.add_theme_font_size_override("font_size",int(p.px(9)));b.custom_minimum_size=Vector2(p.px(48),p.px(43));b.tooltip_text=label;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;compact_button(b)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var skin=b.get_theme_stylebox(state);skin.content_margin_top=0;skin.content_margin_bottom=0
	parent.add_child(b);return b
func hud():
	classic=preload("res://scripts/classic_layout.gd").new(self);classic.build()
func refresh_portrait():
	if is_instance_valid(chat_box) and is_instance_valid(chat_reopen) and not game.in_menu:chat_box.visible=not chat_collapsed;chat_reopen.visible=chat_collapsed
	if not is_instance_valid(hud_portrait):return
	var cls=str(game.world.kingdom.adventure.hero.get("class","warrior")) if R.available(game.world) else "warrior"
	if cls==hud_class:return
	hud_class=cls
	var path="res://assets/rpg/"+cls+".png"
	hud_portrait.texture=load(path) if ResourceLoader.exists(path) else load("res://assets/adventure/warrior.png")
func inventory():
	if not I.enabled(game.world):game.realm_ui.legacy_inventory();return
	R.ensure(game.world);var v=p.surface(say("Inventory","Çanta"));p.nested=false;ui.page="kingdom";v.add_theme_constant_override("separation",int(p.px(4)))
	if R.available(game.world):
		var selector=HBoxContainer.new();v.add_child(selector)
		for key in R.CLASSES:
			var cls=key;var b=p.action(selector,R.NAMES[key],func():
				if R.switch(game.world,cls):selected_item=0;game.realm_ui.changed();inventory(),game.world.rpg.active==key);b.name="SelectClass"+key;b.add_theme_font_size_override("font_size",int(p.px(11)));b.custom_minimum_size.y=p.px(27);b.disabled=not R.home(game.world);compact_button(b)
		var gear=HBoxContainer.new();v.add_child(gear);gear.add_theme_constant_override("separation",int(p.px(6)))
		var hero=game.world.kingdom.adventure.hero;var path="res://assets/rpg/"+str(hero.get("class","warrior"))+".png"
		if not ResourceLoader.exists(path):path="res://assets/rpg/warrior.png"
		var portrait=p.image(load(path),Vector2(p.px(158),p.px(213)));portrait.set_script(preload("res://scripts/rpg_portrait.gd"));portrait.ui=ui;gear.add_child(portrait)
		var equipment=GridContainer.new();equipment.columns=3;equipment.add_theme_constant_override("h_separation",int(p.px(3)));equipment.add_theme_constant_override("v_separation",int(p.px(3)));gear.add_child(equipment)
		for slot in ["ear_left","head","ear_right","neck","armor","belt","weapon","hands","shield","ring_left","legs","ring_right","feet","artifact"]:equipment_slot(equipment,slot)
		v.add_child(p.text(hero.name+" · "+R.NAMES[hero.get("class","warrior")]+" · Lv "+str(H.level(hero)),19,T.GOLD))
	var tabs=HBoxContainer.new();v.add_child(tabs)
	for tab in [["all",say("All","Tümü")],["weapon",say("Gear","Donanım")],["tool",say("Tools","Alet")],["consumable",say("Items","Eşya")]]:
		var key=tab[0];var button=p.action(tabs,tab[1],func():p.filter=key;inventory());button.custom_minimum_size.y=p.px(27);button.add_theme_font_size_override("font_size",int(p.px(11)));compact_button(button)
	var grid=GridContainer.new();grid.name="InventoryGrid";grid.columns=7;grid.add_theme_constant_override("h_separation",int(p.px(3)));grid.add_theme_constant_override("v_separation",int(p.px(3)));v.add_child(grid)
	var visible_items=[]
	for item in game.world.kingdom.industry.items:
		var category=I.recipes()[item.recipe].get("category","tool")
		if p.filter!="all" and (not category in H.SLOTS+R.EXTRA_SLOTS if p.filter=="weapon" else category!=p.filter):continue
		visible_items.append(item)
	for i in range(maxi(28,visible_items.size())):
		var id=int(visible_items[i].id) if i<visible_items.size() else 0
		var b=ui.button("",func():
			if id>0:selected_item=id;show_item(id));b.custom_minimum_size=Vector2(p.px(45),p.px(45));compact_button(b);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(p.px(36)));grid.add_child(b)
		b.add_theme_stylebox_override("normal",T.box(Color("090c09"),false))
		if id>0:
			var item=I.item(game.world,id);b.icon=load("res://assets/kingdom/"+item.recipe+".svg");b.tooltip_text=game.realm_ui.localized(I.recipes()[item.recipe].name)
			b.mouse_entered.connect(func():
				if selected_item==0:show_item(id))
		else:b.disabled=true;b.add_theme_stylebox_override("disabled",T.box(Color("090c09"),false))
	details_window=PanelContainer.new();details_window.name="ItemComparison";details_window.add_theme_stylebox_override("panel",T.box(Color("10160e"),true));ui.veil.add_child(details_window);details_window.position=Vector2(ui.modal.position.x-p.px(277),ui.modal.position.y+p.px(35));details_window.size=Vector2(p.px(265),p.px(420))
	var detail_scroll=ScrollContainer.new();detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;detail_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;details_window.add_child(detail_scroll)
	details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",int(p.px(5)));detail_scroll.add_child(details)
	if selected_item>0 and not I.item(game.world,selected_item).is_empty():show_item(selected_item)
	else:details_window.hide()
func equipment_slot(parent: Control,slot: String):
	var id=0
	if slot in H.SLOTS:id=int(game.world.kingdom.adventure.hero.equipment[slot])
	else:id=int(game.world.rpg.loadouts[game.world.rpg.active].get(slot,0))
	var slot_names={"head":"Baş","armor":"Göğüs","legs":"Bacak","hands":"Eldiven","feet":"Çizme","neck":"Kolye","ring_left":"Yüzük I","ring_right":"Yüzük II","ear_left":"Küpe I","ear_right":"Küpe II","belt":"Kemer","weapon":"Ana el","shield":"Yan el","artifact":"Yadigâr"}
	var b=ui.button(slot_names.get(slot,slot) if ui.language=="tr" else slot.replace("_"," "),func():
		target_slot=slot
		if id>0:selected_item=id;show_item(id)
		else:ui.toast(say("Select equipment from your inventory.","Çantandan donanım seç.")));b.add_theme_font_size_override("font_size",int(p.px(9)));b.custom_minimum_size=Vector2(p.px(43),p.px(40));parent.add_child(b)
	compact_button(b)
	b.tooltip_text=slot_names.get(slot,slot);b.text="";b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(p.px(31)))
	var empty="rpg_"+game.world.rpg.active+"_"+slot if slot in ["head","armor","legs","hands","feet"] else "rpg_"+slot.replace("_right","_left")
	b.icon=load("res://assets/kingdom/"+empty+".svg") if ResourceLoader.exists("res://assets/kingdom/"+empty+".svg") else T.icon("sword" if slot=="weapon" else "shield" if slot=="shield" else "quest")
	b.add_theme_color_override("icon_normal_color",Color(.5,.55,.45,.45))
	if id>0:
		var owned=I.item(game.world,id)
		if not owned.is_empty():b.icon=load("res://assets/kingdom/"+owned.recipe+".svg");b.add_theme_color_override("icon_normal_color",Color.WHITE);b.tooltip_text+=" · "+game.realm_ui.localized(I.recipes()[owned.recipe].name)
func clear_details():
	for child in details.get_children():details.remove_child(child);child.queue_free()
func show_summary():
	clear_details();details.add_child(p.heading(say("Your champion","Şampiyonun"),28))
	if R.available(game.world):
		var stats=H.stats(game.world)
		for key in ["health","attack","defense","speed","crit"]:details.add_child(p.text(stat_name(key)+"    "+str(stats[key]),22))
	details.add_child(p.text(say("Select an item to compare and manage it.","Karşılaştırmak ve yönetmek için eşya seç."),21,T.MUTED))
func show_item(id: int):
	if not is_instance_valid(details):return
	if is_instance_valid(details_window):details_window.show()
	var owned=I.item(game.world,id)
	if owned.is_empty():return
	clear_details();var d=I.recipes()[owned.recipe];var slot=d.get("category","tool")
	details.add_child(p.image(load("res://assets/kingdom/"+owned.recipe+".svg"),Vector2(0,p.px(90))));details.add_child(p.heading(game.realm_ui.localized(d.name),27));details.add_child(p.text(game.realm_ui.localized(d.description),21,T.MUTED))
	var allowed=d.get("classes",["warrior"] if slot in H.SLOTS and slot!="artifact" else R.CLASSES)
	if slot in H.SLOTS+R.EXTRA_SLOTS:details.add_child(p.text(say("Classes: ","Sınıflar: ")+", ".join(allowed)+"\n"+say("Slot: ","Yuva: ")+slot.replace("_"," "),17,T.MUTED))
	for effect in d.get("effects",{}):details.add_child(p.text(stat_name(effect)+"  +"+str(d.effects[effect]),18,T.GOLD))
	if R.available(game.world) and slot in H.SLOTS:
		var before=H.stats(game.world);var after=H.preview(game.world,slot,id)
		for key in ["attack","defense","health"]:details.add_child(p.text(stat_name(key)+"   "+str(before[key])+" → "+str(after[key]),21,T.GOLD))
		var equipped=int(game.world.kingdom.adventure.hero.equipment[slot])==id
		var equip=p.action(details,say("Unequip","Çıkar") if equipped else say("Equip this item","Bu eşyayı kuşan"),func():
			if H.equip(game.world,slot,0 if equipped else id):game.realm_ui.changed();inventory(),true,"hero");equip.disabled=not R.home(game.world) or not game.world.rpg.active in allowed
	elif R.available(game.world) and slot in R.EXTRA_SLOTS:
		var destination=target_slot if target_slot.replace("_right","_left")==slot else slot
		var equipped=int(game.world.rpg.loadouts[game.world.rpg.active][destination])==id
		var equip=p.action(details,say("Unequip","Çıkar") if equipped else say("Equip this item","Bu eşyayı kuşan"),func():
			if R.extra_equip(game.world,destination,0 if equipped else id):game.realm_ui.changed();inventory(),true,"hero")
		equip.disabled=not R.home(game.world) or not game.world.rpg.active in allowed
	if owned.recipe in ["healing_potion","crystal_tonic"] and game.world.get("kingdom",{}).get("adventure",{}).get("run",{}).get("active",false):
		p.action(details,say("Use healing item","İyileştirici kullan"),func():
			if preload("res://scripts/adventure.gd").heal(game.world):game.realm_ui.changed();inventory(),true,"gift")
	if R.available(game.world):
		p.action(details,say("Unlock","Kilidi kaldır") if id in game.world.rpg.locked else say("Lock item","Eşyayı kilitle"),func():R.lock_item(game.world,id);game.realm_ui.changed();show_item(id),false,"shield")
		p.action(details,say("Discard…","Çöpe at…"),func():confirm_discard(id),false,"hammer")
	details.add_child(p.text(say("Upgrade · not enabled yet\nSale · rules pending","Yükseltme · henüz etkin değil\nSatış · kurallar belirlenecek"),18,T.MUTED))
func confirm_discard(id: int):
	var owned=I.item(game.world,id)
	if owned.is_empty():return
	var dialog=ConfirmationDialog.new();dialog.title=say("Discard item","Eşyayı çöpe at");dialog.dialog_text=game.realm_ui.localized(I.recipes()[owned.recipe].name)+" ×1\n"+say("This permanently removes the item.","Bu işlem eşyayı kalıcı olarak kaldırır.");ui.root.add_child(dialog);dialog.confirmed.connect(func():
		if R.discard(game.world,id):selected_item=0;game.realm_ui.changed();inventory()
		else:ui.toast(say("Protected, equipped or reserved item.","Korunan, kuşanılmış veya ayrılmış eşya."))
		dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered()
func attributes():
	if not R.available(game.world):p.route("hero");return
	R.ensure(game.world);draft=R.selected(game.world).attributes.duplicate();var v=p.surface(say("Attributes","Statlar"));p.nested=false;v.add_child(p.text(say("Available points: ","Kullanılabilir puan: ")+str(R.points(game.world)),24,T.GOLD))
	var preview=p.text("",23,T.GOLD);v.add_child(preview)
	for key in R.ATTRIBUTES:
		var attr=key;var row=HBoxContainer.new();v.add_child(row);var value=p.text(stat_name(attr)+"   "+str(draft[attr]),24);row.add_child(value)
		p.action(row,"+",func():
			var delta=0
			for a in R.ATTRIBUTES:delta+=int(draft[a])-int(R.selected(game.world).attributes[a])
			if delta<R.points(game.world):
				draft[attr]+=1;value.text=stat_name(attr)+"   "+str(draft[attr]);var copy=game.world.duplicate(true);R.ensure(copy);R.allocate(copy,draft);var before=H.stats(game.world);var after=H.stats(copy);preview.text=say("Preview · ","Önizleme · ")+"HP "+str(before.health)+" → "+str(after.health)+" · ATK "+str(before.attack)+" → "+str(after.attack)+" · DEF "+str(before.defense)+" → "+str(after.defense))
	p.action(v,say("Confirm allocation","Dağılımı onayla"),func():
		if R.allocate(game.world,draft):game.realm_ui.changed();attributes(),true)
	p.action(v,say("Reset stats and skills · free at home","Stat ve becerileri sıfırla · evde ücretsiz"),func():
		if R.reset(game.world):game.realm_ui.changed();attributes())
func skills():
	if not R.available(game.world):p.route("hero");return
	var prog=R.selected(game.world);var v=p.surface(say("Skills","Beceriler"));p.nested=false;v.add_child(p.text(say("Skill points: ","Beceri puanı: ")+str(R.points(game.world,true)),24,T.GOLD))
	v.add_child(p.text(say("1 / 2 / 3 assigns an ability to your combat bar. The untrained starter costs no mana.","1 / 2 / 3 beceriyi savaş çubuğuna atar. Başlangıç becerisi geliştirilmeden mana tüketmez."),17,T.MUTED))
	if game.world.rpg.active=="rogue":
		for key in ["archer","assassin"]:
			var spec=key;p.action(v,key.capitalize(),func():
				if R.specialize(game.world,spec):game.realm_ui.changed();skills(),prog.specialization==key)
	for i in range(6):
		var index=i;var row=HBoxContainer.new();row.add_theme_constant_override("separation",int(p.px(8)));v.add_child(row)
		var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info)
		info.add_child(p.text(R.skill_name(game.world.rpg.active,i,ui.language=="tr")+" · "+str(int(prog.skills[i]))+" / 3 · Lv "+str(1+i*2),21))
		info.add_child(p.text(str(12+i*3)+" mana · "+str(4+i*.5)+say("s cooldown"," sn bekleme"),16,T.MUTED))
		var train=p.action(row,"+",func():
			if R.train(game.world,index):game.realm_ui.changed();skills())
		train.size_flags_horizontal=Control.SIZE_SHRINK_END;train.custom_minimum_size=Vector2(p.px(32),p.px(30));compact_button(train);train.tooltip_text=say("Spend one skill point","Bir beceri puanı harca")
		train.disabled=not R.home(game.world) or R.points(game.world,true)==0 or int(prog.skills[i])>=3 or H.level(game.world.kingdom.adventure.hero)<1+i*2
		for slot in range(3):
			var target=slot;var assign=p.action(row,str(slot+1),func():
				if R.home(game.world):prog.bar[target]=index;game.realm_ui.changed();skills(),int(prog.bar[slot])==i)
			assign.size_flags_horizontal=Control.SIZE_SHRINK_END;assign.custom_minimum_size=Vector2(p.px(32),p.px(30));compact_button(assign)
			assign.disabled=not R.home(game.world) or (i!=0 and int(prog.skills[i])==0);assign.tooltip_text=say("Assign to active slot ","Aktif yuvaya ata: ")+str(slot+1)
