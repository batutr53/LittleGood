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
	var b=ui.button(label,cb);b.icon=T.icon(key);b.expand_icon=true;b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.alignment=HORIZONTAL_ALIGNMENT_CENTER;b.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP;b.add_theme_constant_override("icon_max_width",int(p.px(30)));b.add_theme_font_size_override("font_size",int(p.px(16)));b.custom_minimum_size=Vector2(maxf(48,p.px(88)),maxf(48,p.px(66)));b.tooltip_text=label;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(b);return b
func hud():
	if is_instance_valid(ui.root):ui.remove_child(ui.root);ui.root.queue_free()
	ui.modal=null;ui.veil=null;ui.root=Control.new();ui.root.name="WorldHUD";ui.root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.root.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(ui.root)
	var s=p.size();var margin=p.px(14);var bar_h=p.px(72)
	var identity=card(Rect2(margin,margin,p.px(330),p.px(112)))
	ui.header=p.heading("",25);p.put(ui.header,Rect2(margin+p.px(72),margin+p.px(6),p.px(245),p.px(33)))
	ui.header.autowrap_mode=TextServer.AUTOWRAP_OFF;ui.header.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	ui.stats=p.text("",17);p.put(ui.stats,Rect2(margin+p.px(72),margin+p.px(44),p.px(245),p.px(56)))
	hud_portrait=TextureRect.new();hud_class="";hud_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;hud_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;hud_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.put(hud_portrait,Rect2(margin+p.px(4),margin+p.px(4),p.px(62),p.px(100)));refresh_portrait()
	ui.spirit=p.text("",18,T.GOLD);p.put(ui.spirit,Rect2(p.px(365),margin,p.px(140),p.px(32)))
	ui.realm_bar=ui.button("",func():p.route("menu"));ui.root.add_child(ui.realm_bar);ui.realm_bar.hide()
	ui.chapter=ui.button("",func():p.route("quest") if game.world.has("kingdom") else ui.follow_chapter());ui.chapter.name="CurrentObjective";ui.chapter.add_theme_font_size_override("font_size",int(p.px(19)));p.put(ui.chapter,Rect2(s.x-p.px(325),margin,p.px(310),p.px(100)))
	var mini=preload("res://scripts/rpg_minimap.gd").new();mini.game=game;p.put(mini,Rect2(s.x-p.px(150),p.px(128),p.px(135),p.px(110)))
	ui.hint=p.text("",18);p.put(ui.hint,Rect2(s.x-p.px(325),p.px(250),p.px(305),p.px(70)))
	var resource_row=HBoxContainer.new();resource_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;p.put(resource_row,Rect2(p.px(365),p.px(55),p.px(380),p.px(35)));p.resource_labels.clear()
	for key in ["wood","stone","gold","food"]:
		var cell=HBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;resource_row.add_child(cell);cell.add_child(p.image(T.icon(key),Vector2.ONE*p.px(25)));var label=p.text("0",17);cell.add_child(label);p.resource_labels[key]=label
	card(Rect2(0,s.y-bar_h,s.x,bar_h))
	var nav=HBoxContainer.new();nav.add_theme_constant_override("separation",int(p.px(5)));p.put(nav,Rect2(margin,s.y-bar_h+p.px(3),s.x-margin*2,bar_h-p.px(6)))
	for entry in [["hero","hero",say("Character","Karakter")],["inventory","bag",say("Inventory","Çanta")],["skills","sword",say("Skills","Beceriler")],["attributes","shield",say("Stats","Statlar")],["quest","quest",say("Quests","Görevler")],["map","map",say("Travel","Işınlan")],["construction","hammer",say("Build","İnşa")],["workers","workers",say("People","Sakinler")],["menu","menu",say("More","Diğer")]]:
		var key=entry[0];var b=icon_action(nav,entry[1],entry[2],func():p.route(key));b.name="WorldMenu" if key=="menu" else "Nav"+key.capitalize()
	var chat_height=p.px(104)+52
	chat_box=card(Rect2(margin,s.y-bar_h-chat_height-p.px(12),p.px(350),chat_height));chat_box.name="ChatPanel"
	var copy=p.text(say("SYSTEM  ·  GENERAL  ·  PRIVATE","SİSTEM  ·  GENEL  ·  ÖZEL"),15,T.GOLD);chat_box.add_child(copy);copy.position=Vector2(p.px(10),p.px(7));copy.size=Vector2(p.px(330),p.px(24))
	var log=p.text(say("Your world is ready.\nOpen chat to connect with friends.","Dünyan hazır.\nArkadaşlarınla konuşmak için sohbeti aç."),16);chat_box.add_child(log);log.position=Vector2(p.px(10),p.px(38));log.size=Vector2(p.px(330),p.px(65))
	var open=ui.button(say("Chat","Sohbet"),func():p.route("chat"));open.custom_minimum_size=Vector2(0,48);open.add_theme_font_size_override("font_size",int(p.px(16)));compact_button(open);chat_box.add_child(open);open.position=Vector2(p.px(10),p.px(104));open.size=Vector2(p.px(350)-78,48)
	chat_reopen=ui.button(say("Chat +","Sohbet +"),func():chat_collapsed=false;chat_box.show();chat_reopen.hide());chat_reopen.name="ReopenChat";chat_reopen.add_theme_font_size_override("font_size",int(p.px(16)));compact_button(chat_reopen);p.put(chat_reopen,Rect2(margin,s.y-bar_h-60,p.px(130),48));chat_reopen.hide()
	var collapse=ui.button("−",func():chat_collapsed=true;chat_box.hide();chat_reopen.show());collapse.name="CollapseChat";collapse.tooltip_text=say("Minimize chat","Sohbeti küçült");collapse.add_theme_font_size_override("font_size",18);collapse.custom_minimum_size=Vector2(48,48);compact_button(collapse);chat_box.add_child(collapse);collapse.position=Vector2(p.px(350)-58,p.px(104));collapse.size=Vector2(48,48)
	var controls=HBoxContainer.new();p.put(controls,Rect2(s.x-p.px(350),s.y-bar_h-p.px(76),p.px(335),p.px(62)))
	icon_action(controls,"gift",say("Gifts","Armağan"),func():p.gifts_open=not p.gifts_open;p.tray.visible=p.gifts_open)
	ui.speed_button=icon_action(controls,"crown","1×",func():game.speed=3 if game.speed==1 else 1;ui.refresh())
	icon_action(controls,"map",say("Center","Ortala"),func():game.view.pan=Vector2.ZERO)
	p.tray=HBoxContainer.new();p.tray.name="GiftPalette";p.tray.visible=false;p.put(p.tray,Rect2(p.px(390),s.y-bar_h-p.px(155),s.x-p.px(405),p.px(64)));ui.power_buttons.clear();ui.power_icons.clear()
	for i in range(6):
		var b=ui.button(ui.t(ui.POWER_KEYS[i]),func():ui.choose_power(i));b.custom_minimum_size=Vector2(0,p.px(58));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",int(p.px(17)));p.tray.add_child(b);ui.power_buttons.append(b)
	ui.refresh()
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
	R.ensure(game.world);var v=p.surface(say("Character & Inventory","Karakter ve Çanta"));p.nested=false;ui.page="kingdom"
	var layout=HBoxContainer.new();layout.add_theme_constant_override("separation",int(p.px(20)));v.add_child(layout)
	var left=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=1.8;layout.add_child(left)
	details=VBoxContainer.new();details.custom_minimum_size.x=p.px(300);details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layout.add_child(details)
	if R.available(game.world):
		var selector=HBoxContainer.new();left.add_child(selector)
		for key in R.CLASSES:
			var cls=key;var b=p.action(selector,R.NAMES[key],func():
				if R.switch(game.world,cls):game.realm_ui.changed();inventory(),game.world.rpg.active==key);b.name="SelectClass"+key;b.add_theme_font_size_override("font_size",int(p.px(17)));b.custom_minimum_size.y=maxf(48,p.px(44));b.disabled=not R.home(game.world);compact_button(b)
		var gear=HBoxContainer.new();left.add_child(gear);var slots_left=VBoxContainer.new();gear.add_child(slots_left)
		for slot in ["head","armor","hands","feet"]:equipment_slot(slots_left,slot)
		var hero=game.world.kingdom.adventure.hero;var path="res://assets/rpg/"+str(hero.get("class","warrior"))+".png"
		if not ResourceLoader.exists(path):path="res://assets/rpg/warrior.png"
		var portrait=p.image(load(path),Vector2(p.px(260),p.px(300)));portrait.set_script(preload("res://scripts/rpg_portrait.gd"));portrait.ui=ui;portrait.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gear.add_child(portrait)
		var slots_right=VBoxContainer.new();gear.add_child(slots_right)
		for slot in ["neck","ring_left","ring_right","belt"]:equipment_slot(slots_right,slot)
		var secondary=HBoxContainer.new();left.add_child(secondary)
		for slot in ["weapon","shield","legs","ear_left","ear_right","artifact"]:equipment_slot(secondary,slot)
		left.add_child(p.text(hero.name+" · "+R.NAMES[hero.get("class","warrior")]+" · Lv "+str(H.level(hero)),22,T.GOLD))
	var tabs=HBoxContainer.new();left.add_child(tabs)
	for tab in [["all",say("All","Tümü")],["weapon",say("Gear","Donanım")],["tool",say("Tools","Alet")],["consumable",say("Items","Eşya")]]:
		var key=tab[0];var button=p.action(tabs,tab[1],func():p.filter=key;inventory());button.custom_minimum_size.y=maxf(48,p.px(44));button.add_theme_font_size_override("font_size",int(p.px(17)));compact_button(button)
	var grid=GridContainer.new();grid.columns=8 if p.size().x>=1200 else 6;grid.add_theme_constant_override("h_separation",int(p.px(6)));grid.add_theme_constant_override("v_separation",int(p.px(6)));left.add_child(grid)
	for item in game.world.kingdom.industry.items:
		var id=int(item.id);var d=I.recipes()[item.recipe];var category=d.get("category","tool")
		if p.filter!="all" and (not category in H.SLOTS+R.EXTRA_SLOTS if p.filter=="weapon" else category!=p.filter):continue
		var b=ui.button("",func():selected_item=id;show_item(id));b.icon=load("res://assets/kingdom/"+item.recipe+".svg");b.expand_icon=true;b.tooltip_text=game.realm_ui.localized(d.name);b.custom_minimum_size=Vector2(p.px(64),p.px(64));b.add_theme_constant_override("icon_max_width",int(p.px(47)));grid.add_child(b)
		b.mouse_entered.connect(func():
			if selected_item==0:show_item(id))
	if selected_item>0 and not I.item(game.world,selected_item).is_empty():show_item(selected_item)
	else:show_summary()
func equipment_slot(parent: Control,slot: String):
	var id=0
	if slot in H.SLOTS:id=int(game.world.kingdom.adventure.hero.equipment[slot])
	else:id=int(game.world.rpg.loadouts[game.world.rpg.active].get(slot,0))
	var slot_names={"head":"Baş","armor":"Göğüs","legs":"Bacak","hands":"Eldiven","feet":"Çizme","neck":"Kolye","ring_left":"Yüzük I","ring_right":"Yüzük II","ear_left":"Küpe I","ear_right":"Küpe II","belt":"Kemer","weapon":"Ana el","shield":"Yan el","artifact":"Yadigâr"}
	var b=ui.button(slot_names.get(slot,slot) if ui.language=="tr" else slot.replace("_"," "),func():
		target_slot=slot
		if id>0:selected_item=id;show_item(id)
		else:ui.toast(say("Select equipment from your inventory.","Çantandan donanım seç.")));b.add_theme_font_size_override("font_size",int(p.px(13)));b.custom_minimum_size=Vector2(maxf(48,p.px(74)),maxf(48,p.px(48)));parent.add_child(b)
	compact_button(b)
	if id>0:
		var owned=I.item(game.world,id)
		if not owned.is_empty():b.text="";b.icon=load("res://assets/kingdom/"+owned.recipe+".svg");b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(p.px(38)))
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
		train.size_flags_horizontal=Control.SIZE_SHRINK_END;train.custom_minimum_size=Vector2(maxf(48,p.px(64)),maxf(48,p.px(58)));compact_button(train);train.tooltip_text=say("Spend one skill point","Bir beceri puanı harca")
		train.disabled=not R.home(game.world) or R.points(game.world,true)==0 or int(prog.skills[i])>=3 or H.level(game.world.kingdom.adventure.hero)<1+i*2
		for slot in range(3):
			var target=slot;var assign=p.action(row,str(slot+1),func():
				if R.home(game.world):prog.bar[target]=index;game.realm_ui.changed();skills(),int(prog.bar[slot])==i)
			assign.size_flags_horizontal=Control.SIZE_SHRINK_END;assign.custom_minimum_size=Vector2(maxf(48,p.px(64)),maxf(48,p.px(58)));compact_button(assign)
			assign.disabled=not R.home(game.world) or (i!=0 and int(prog.skills[i])==0);assign.tooltip_text=say("Assign to active slot ","Aktif yuvaya ata: ")+str(slot+1)
