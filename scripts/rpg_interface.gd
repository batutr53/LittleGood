extends RefCounted
const R=preload("res://scripts/rpg_progression.gd")
const H=preload("res://scripts/hero.gd")
const I=preload("res://scripts/industry.gd")
const T=preload("res://scripts/premium_theme.gd")
const F=preload("res://scripts/armory.gd")
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
	var panel=Panel.new();panel.add_theme_stylebox_override("panel",T.box(Color(.045,.075,.105,.94),true));p.put(panel,rect);return panel
func icon_action(parent: Control,key: String,label: String,cb: Callable) -> Button:
	var b=ui.button(label,cb);b.icon=T.icon(key);b.expand_icon=true;b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.alignment=HORIZONTAL_ALIGNMENT_CENTER;b.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP;b.add_theme_constant_override("icon_max_width",int(p.px(24)));b.add_theme_constant_override("h_separation",0);b.add_theme_font_size_override("font_size",int(p.px(9)));b.custom_minimum_size=Vector2(p.px(48),p.px(43));b.tooltip_text=label;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;compact_button(b)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var skin=b.get_theme_stylebox(state);skin.content_margin_top=0;skin.content_margin_bottom=0
	parent.add_child(b);return b
func highlight_navigation():
	if not is_instance_valid(ui.root):return
	for b in ui.root.find_children("*","Button",true,false):
		if not b.has_meta("nav_key"):continue
		var active=game.in_menu and p.current==str(b.get_meta("nav_key"));b.toggle_mode=true;b.set_pressed_no_signal(active)
		var skin=T.box(Color("354859") if active else Color("151f29"),active);skin.content_margin_top=0;skin.content_margin_bottom=0
		if active:skin.set_border_width_all(2)
		b.add_theme_stylebox_override("normal",skin);b.add_theme_stylebox_override("pressed",skin);b.add_theme_color_override("font_color",T.GOLD if active else T.CREAM)
func highlight_item():
	if not is_instance_valid(ui.modal):return
	for b in ui.modal.find_children("*","Button",true,false):
		if not b.has_meta("item_id"):continue
		var active=(int(b.get_meta("item_id"))==selected_item and selected_item>0) or (selected_item==0 and b.has_meta("equipment_slot") and str(b.get_meta("equipment_slot"))==target_slot);var skin=T.box(Color("314658") if active else Color("0b141d"),active)
		var recipe=str(b.get_meta("item_recipe"));skin.border_color=Color("ffe5a9") if active else F.color(recipe) if not recipe.is_empty() else T.MUTED;skin.set_border_width_all(3 if active else 1);b.add_theme_stylebox_override("normal",skin)
		var marker=b.get_node_or_null("SelectedMark")
		if active and marker==null:
			marker=p.text("✓",18,Color("fff4bd"));marker.name="SelectedMark";b.add_child(marker);marker.position=Vector2(2,0)*p.scale_ui()
		if is_instance_valid(marker):marker.visible=active
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
	R.ensure(game.world);F.ensure(game.world);var v=p.surface(say("Inventory","Çanta"));p.nested=false;ui.page="kingdom";v.add_theme_constant_override("separation",int(p.px(4)))
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
		var sets=load("res://scripts/equipment_sets.gd");var set_name=game.realm_ui.localized(sets.definitions()[game.world.rpg.active].name);var set_button=p.action(v,set_name+" · "+str(sets.count(game.world))+" / 5",func():p.route("sets"));set_button.name="EquipmentSet";set_button.custom_minimum_size.y=p.px(27);compact_button(set_button)
	var tabs=HBoxContainer.new();v.add_child(tabs)
	var codex=p.action(v,say("Drops & bestiary · Contracts","Drop rehberi · Görev panosu"),func():p.route("bestiary"));codex.name="OpenBestiary";codex.custom_minimum_size.y=p.px(28);compact_button(codex)
	for tab in [["all",say("All","Tümü")],["weapon",say("Gear","Donanım")],["tool",say("Tools","Alet")],["consumable",say("Items","Eşya")]]:
		var key=tab[0];var button=p.action(tabs,tab[1],func():p.filter=key;inventory());button.custom_minimum_size.y=p.px(27);button.add_theme_font_size_override("font_size",int(p.px(11)));compact_button(button)
	var grid=GridContainer.new();grid.name="InventoryGrid";grid.columns=7;grid.add_theme_constant_override("h_separation",int(p.px(3)));grid.add_theme_constant_override("v_separation",int(p.px(3)));v.add_child(grid)
	var visible_items=[]
	for item in game.world.kingdom.industry.items:
		var category=I.recipes()[item.recipe].get("category","tool")
		if p.filter!="all" and (not category in H.SLOTS+R.EXTRA_SLOTS if p.filter=="weapon" else not category in ["consumable","upgrade_scroll"] if p.filter=="consumable" else category!=p.filter):continue
		visible_items.append(item)
	for i in range(maxi(28,visible_items.size())):
		var id=int(visible_items[i].id) if i<visible_items.size() else 0
		var b=ui.button("",func():
			if id>0:selected_item=id;show_item(id));b.custom_minimum_size=Vector2(p.px(45),p.px(45));compact_button(b);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(p.px(36)));grid.add_child(b)
		b.add_theme_stylebox_override("normal",T.box(Color("090c09"),false))
		if id>0:
			var item=I.item(game.world,id);b.icon=F.icon(item.recipe);b.tooltip_text=F.label(game.world,item,ui.language=="tr")
			b.set_meta("item_id",id);b.set_meta("item_recipe",str(item.recipe))
			var box=T.box(Color("090c09"),false);box.border_color=F.color(item.recipe);box.set_border_width_all(1);b.add_theme_stylebox_override("normal",box)
			var s=F.state(game.world,id)
			add_glow(b,id)
			if int(s.normal)>0 or int(s.rebirth)>0:
				var tag=p.text(("R+"+str(int(s.rebirth))) if int(s.rebirth)>0 else "+"+str(int(s.normal)),16,F.color(item.recipe));tag.position=Vector2(p.px(2),p.px(26));b.add_child(tag)
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
		else:
			selected_item=0
			if is_instance_valid(details_window):details_window.hide()
			highlight_item();ui.toast(say("Select equipment from your inventory.","Çantandan donanım seç.")));b.add_theme_font_size_override("font_size",int(p.px(9)));b.custom_minimum_size=Vector2(p.px(43),p.px(40));parent.add_child(b)
	b.set_meta("equipment_slot",slot);b.set_meta("item_id",id);b.set_meta("item_recipe",str(I.item(game.world,id).get("recipe","")))
	compact_button(b)
	b.tooltip_text=slot_names.get(slot,slot);b.text="";b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(p.px(31)))
	var empty="rpg_"+game.world.rpg.active+"_"+slot if slot in ["head","armor","legs","hands","feet"] else "rpg_"+slot.replace("_right","_left")
	b.icon=load("res://assets/kingdom/"+empty+".svg") if ResourceLoader.exists("res://assets/kingdom/"+empty+".svg") else T.icon("sword" if slot=="weapon" else "shield" if slot=="shield" else "quest")
	b.add_theme_color_override("icon_normal_color",Color(.5,.55,.45,.45))
	if id>0:
		var owned=I.item(game.world,id)
		if not owned.is_empty():b.icon=F.icon(owned.recipe);b.add_theme_color_override("icon_normal_color",Color.WHITE);b.tooltip_text+=" · "+F.label(game.world,owned,ui.language=="tr");add_glow(b,id)
func add_glow(button: Control,id: int):
	if F.glow(game.world,id).strength<=0:return
	var glow=preload("res://scripts/equipment_glow.gd").new();glow.world=game.world;glow.item_id=id;glow.reduce_motion=ui.reduce_motion;button.add_child(glow);glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	highlight_item()
	clear_details();var d=I.recipes()[owned.recipe];var slot=d.get("category","tool")
	details.add_child(p.image(F.icon(owned.recipe),Vector2(0,p.px(90))));details.add_child(p.heading(F.label(game.world,owned,ui.language=="tr"),27));details.add_child(p.text(F.grade(owned.recipe).to_upper()+" · "+str(F.state(game.world,id).element),20,F.color(owned.recipe)));details.add_child(p.text(game.realm_ui.localized(d.description),21,T.MUTED))
	if F.eligible(game.world,id):
		var enhance=p.action(details,say("Upgrade / Rebirth","Yükselt / Rebirth"),func():p.route("enhance",id),true,"forge");enhance.name="EnhanceItem";enhance.disabled=not R.home(game.world)
	var allowed=d.get("classes",["warrior"] if slot in H.SLOTS and slot!="artifact" else R.CLASSES)
	if slot in H.SLOTS+R.EXTRA_SLOTS:details.add_child(p.text(say("Classes: ","Sınıflar: ")+", ".join(allowed)+"\n"+say("Slot: ","Yuva: ")+slot.replace("_"," "),17,T.MUTED))
	var bonuses=I.effects(game.world,owned)
	for effect in bonuses:details.add_child(p.text(stat_name(effect)+"  +"+str(bonuses[effect]),18,T.GOLD))
	if game.world.has("rpg") and owned.recipe in load("res://scripts/equipment_sets.gd").definitions().get(game.world.rpg.active,{}).get("pieces",[]):set_details(details)
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
	details.add_child(p.text(say("Sale · rules pending","Satış · kurallar belirlenecek"),18,T.MUTED))
func confirm_discard(id: int):
	var owned=I.item(game.world,id)
	if owned.is_empty():return
	var dialog=ConfirmationDialog.new();dialog.title=say("Discard item","Eşyayı çöpe at");dialog.dialog_text=game.realm_ui.localized(I.recipes()[owned.recipe].name)+" ×1\n"+say("This permanently removes the item.","Bu işlem eşyayı kalıcı olarak kaldırır.");ui.root.add_child(dialog);dialog.confirmed.connect(func():
		if R.discard(game.world,id):selected_item=0;game.realm_ui.changed();inventory()
		else:ui.toast(say("Protected, equipped or reserved item.","Korunan, kuşanılmış veya ayrılmış eşya."))
		dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered()
func enhance(id: int):
	R.ensure(game.world);F.ensure(game.world);var owned=I.item(game.world,id)
	if owned.is_empty():p.route("inventory");return
	var v=p.surface(say("The Magic Anvil","Büyülü Örs"));p.nested=false;ui.page="kingdom"
	var header=HBoxContainer.new();v.add_child(header);header.add_child(p.image(F.icon(owned.recipe),Vector2.ONE*p.px(100)))
	var words=VBoxContainer.new();header.add_child(words);words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;words.add_child(p.heading(F.label(game.world,owned,ui.language=="tr"),25));words.add_child(p.text(F.grade(owned.recipe).to_upper(),21,F.color(owned.recipe)))
	v.add_child(p.text(say("Your item stays at its current level on failure. Materials are consumed. Rates are LittleGod balance.","Başarısızlıkta eşyan ve seviyesi korunur; malzeme harcanır. Oranlar LittleGod dengesidir."),19,T.MUTED))
	if K_count_forge()==0:v.add_child(p.text(say("A completed forge is required.","Tamamlanmış bir demirci gerekli."),21,T.GOLD))
	var s=F.state(game.world,id)
	for mode in ["normal","reverse","rebirth"]:
		var q=F.quote(game.world,id,mode)
		if q.is_empty():continue
		var title={"normal":say("Upgrade +","Yükselt +")+str(int(q.after.normal)),"reverse":say("Reverse → REB +","Rebirth dönüşümü → +")+str(int(q.after.rebirth)),"rebirth":"REB +"+str(int(q.after.rebirth))}[mode]
		var box=VBoxContainer.new();v.add_child(box);box.add_child(p.text(title+" · "+str(q.chance_bp/100.0)+"%",22,T.GOLD));box.add_child(p.text(game.realm_ui.cost(q.cost),18,T.MUTED))
		var copy=game.world.duplicate(true);copy.armory.items[str(id)]=q.after;var before=I.effects(game.world,owned);var after=I.effects(copy,owned)
		for key in after:
			if after[key]!=before[key]:box.add_child(p.text(stat_name(key)+" "+str(before[key])+" → "+str(after[key]),20))
		box.add_child(p.text(F.label(game.world,{"id":0,"recipe":q.scroll_recipe},ui.language=="tr")+" ×1 · "+(say("Owned","Mevcut") if q.scroll_id>0 else say("Missing","Eksik")),19,T.GOLD if q.scroll_id>0 else T.MUTED))
		var quote=q.duplicate(true);var button=p.action(box,say("Review & confirm","İncele ve onayla"),func():confirm_upgrade(quote),true,"forge");button.name="Confirm"+mode.capitalize();button.disabled=q.scroll_id==0 or K_count_forge()==0 or not load("res://scripts/kingdom.gd").afford(game.world,q.cost)
	v.add_child(p.text(say("Weapon element","Silah elementi"),22,T.GOLD));var row=GridContainer.new();row.columns=2;v.add_child(row)
	for entry in [["fire","Ateş"],["frost","Buz"],["lightning","Yıldırım"],["poison","Zehir"]]:
		var q=F.quote(game.world,id,"element",entry[0]);var quote=q.duplicate(true);var b=p.action(row,entry[1] if ui.language=="tr" else entry[0].capitalize(),func():confirm_upgrade(quote));b.disabled=q.is_empty() or int(q.get("scroll_id",0))==0 or K_count_forge()==0 or not load("res://scripts/kingdom.gd").afford(game.world,q.get("cost",{}))
	v.add_child(p.text(say("Each operation consumes its matching scroll, even on failure. Craft missing scrolls at the forge and collect them above the building.","Her işlem kendi parşömenini tüketir; başarısızlıkta da. Eksik parşömenleri demircide üret, bina üstünden topla."),19,T.MUTED))
	p.action(v,say("Craft upgrade scrolls","Yükseltme parşömeni üret"),func():p.craft_filter="scroll";p.route("forge"),false,"forge")
	if F.quote(game.world,id,"normal").is_empty() and F.quote(game.world,id,"rebirth").is_empty():v.add_child(p.text(say("Locked, reserved, or maximum level. Only active-hero equipment can be changed at home.","Kilitli, ayrılmış veya son seviyede. Yalnızca aktif kahramanın donanımı evde değiştirilebilir."),19,T.MUTED))
	p.action(v,say("Your satchel","Çantana dön"),func():p.route("inventory"),false,"bag")
func K_count_forge() -> int:return load("res://scripts/kingdom.gd").count(game.world,"forge")
func set_details(target: Node):
	if not R.available(game.world):return
	var sets=load("res://scripts/equipment_sets.gd");var d=sets.definitions()[game.world.rpg.active];var count=sets.count(game.world)
	target.add_child(p.heading(game.realm_ui.localized(d.name)+" · "+str(count)+" / 5",24))
	for needed in d.bonuses:
		var parts=[]
		for key in d.bonuses[needed]:parts.append("+"+str(int(d.bonuses[needed][key]))+" "+stat_name(key))
		target.add_child(p.text(("✓ " if count>=int(needed) else "◇ ")+str(needed)+say(" pieces: "," parça: ")+" · ".join(parts),20,T.GOLD if count>=int(needed) else T.MUTED))
func set_screen():
	var v=p.surface(say("Equipment set","Donanım seti"));p.nested=false;ui.page="kingdom";set_details(v)
	if not R.available(game.world):return
	var sets=load("res://scripts/equipment_sets.gd");var I=load("res://scripts/industry.gd");var w=game.world;var ids=w.kingdom.adventure.hero.equipment.values()+w.rpg.loadouts[w.rpg.active].values()
	v.add_child(p.text(say("Bonuses require distinct equipped pieces. Items in the bag do not count. These are LittleGod set values.","Bonuslar farklı kuşanılmış parçaları gerektirir. Çantadaki eşya sayılmaz. Değerler LittleGod dengesidir."),20,T.MUTED))
	for recipe in sets.definitions()[w.rpg.active].pieces:
		var row=HBoxContainer.new();v.add_child(row);row.add_child(p.image(F.icon(recipe),Vector2.ONE*p.px(42)))
		var worn=ids.any(func(id):return I.item(w,int(id)).get("recipe","")==recipe);row.add_child(p.text(("✓ " if worn else "◇ ")+game.realm_ui.localized(I.recipes()[recipe].name),20,T.GOLD if worn else T.MUTED))
	p.action(v,say("Back to inventory","Çantaya dön"),func():p.route("inventory"),false,"bag")
func resource_name(key: String) -> String:
	return {"gold":"Altın","iron":"Demir","wood":"Odun","stone":"Taş","herb":"Şifalı bitki","leather":"Deri","thornhide":"Dikenderi","heart":"Yaşayan kalp","ore":"Cevher","desert_crystal":"Çöl kristali","ancient_alloy":"Kadim alaşım"}.get(key,key) if ui.language=="tr" else key.replace("_"," ").capitalize()
func confirm_upgrade(q: Dictionary):
	if q.is_empty():return
	var v=p.surface(say("Confirm enhancement","Yükseltmeyi onayla"));v.name="EnhanceConfirmation"
	var owned=I.item(game.world,int(q.id))
	if owned.is_empty():enhance(int(q.id));return
	v.add_child(p.image(F.icon(owned.recipe),Vector2(0,p.px(110))))
	v.add_child(p.heading(F.label(game.world,owned,ui.language=="tr"),25))
	v.add_child(p.text(game.realm_ui.cost(q.cost),23,T.GOLD));v.add_child(p.text(str(q.chance_bp/100.0)+"% "+say("success chance","başarı şansı"),24,T.GOLD))
	v.add_child(p.text(F.label(game.world,{"id":0,"recipe":q.scroll_recipe},ui.language=="tr")+" ×1",21,T.GOLD))
	v.add_child(p.text(say("On failure: item and level stay; materials spent.","Başarısızlık: eşya ve seviye korunur, malzeme harcanır."),22,T.MUTED))
	var confirm=p.action(v,say("Confirm enhancement","Yükseltmeyi onayla"),func():
		var result=F.attempt(game.world,int(q.id),q.mode,int(q.serial),q.element)
		if result.is_empty():ui.toast(say("State changed. Check resources and item protection.","Durum değişti. Kaynakları ve eşya korumasını kontrol et."))
		else:
			game.realm_ui.changed();game.audio.chime(6 if result.success else 2);ui.toast(say("Enhancement succeeded!","Yükseltme başarılı!") if result.success else say("Unchanged · materials spent","Seviye korundu · malzeme harcandı"))
		enhance(int(q.id)),true,"forge")
	confirm.name="ConfirmEnhancement";confirm.custom_minimum_size.y=p.px(48)
	p.action(v,say("Cancel","Vazgeç"),func():enhance(int(q.id)))
func bestiary():
	var v=p.surface(say("Drops & Bestiary","Drop ve Canavar Rehberi"));ui.page="kingdom";p.nested=false
	v.add_child(p.text(say("LittleGod drop tables · original rewards, not unverified reference odds.","LittleGod drop tabloları · özgün ödüller, doğrulanmamış referans oranları değil."),19,T.MUTED))
	p.action(v,say("Contracts & rewards","Görevler ve ödüller"),func():p.route("contracts"),true,"quest")
	var search=LineEdit.new();search.placeholder_text=say("Search monsters…","Canavar ara…");search.custom_minimum_size.y=p.px(40);v.add_child(search);var sections=[]
	for kind in load("res://scripts/adventure.gd").enemies():
		var group=VBoxContainer.new();v.add_child(group);var container=group
		var d=load("res://scripts/adventure.gd").enemies()[kind];var monster_name=d.name.get("tr" if ui.language=="tr" else "en",kind) if d.name is Dictionary else game.realm_ui.localized(d.name);container.add_child(p.heading(monster_name,25));container.add_child(p.text("HP "+str(int(d.health))+" · ATK "+str(int(d.attack))+" · DEF "+str(int(d.defense)),19));sections.append({"node":group,"name":(monster_name+" "+kind).to_lower()})
		if kind=="thornheart":
			container.add_child(p.text(say("First victory only: 1 living heart, 5 gold. Extra class weapon: Unique · 100%.","İlk zafer: 1 yaşayan kalp, 5 altın. Ek sınıf silahı: Unique · %100."),19,T.GOLD));continue
		container.add_child(p.text(say("Guaranteed: ","Kesin: ")+str(int(d.quantity))+" "+resource_name(d.material),18,T.MUTED))
		var total=0
		for entry in d.weights:total+=int(entry[1])
		for entry in d.weights:container.add_child(p.text(resource_name(entry[0])+" · "+str(snappedf(int(entry[1])*100.0/maxi(1,total),.01))+"%",18))
		container.add_child(p.text(say("Extra class weapon: ","Ek sınıf silahı: ")+("Unique · 100%" if kind in ["thornheart","ruin_sentinel","sunward_warden"] else "High · 25%"),19,T.GOLD))
	search.text_changed.connect(func(query):
		for section in sections:section.node.visible=query.strip_edges().is_empty() or section.name.contains(query.to_lower().strip_edges()))
	p.action(v,say("Back to inventory","Çantaya dön"),func():p.route("inventory"),false,"bag")
func contracts():
	F.ensure(game.world);var v=p.surface(say("The Adventurer's Board","Maceracı Panosu"));ui.page="kingdom";p.nested=false
	v.add_child(p.text(say("One-time objectives. No absence penalty. Rewards are delivered once at home when storage has room.","Tek seferlik hedefler. Yokluk cezası yok. Ödüller evde, depoda yer varsa bir kez verilir."),20,T.MUTED))
	for key in F.contracts():
		var id=key;var d=F.contracts()[key];var value=F.progress(game.world,key);var claimed=key in game.world.get("armory",{}).get("claims",[])
		v.add_child(p.heading(game.realm_ui.localized(d.title),24));v.add_child(p.text(str(mini(value,int(d.target)))+" / "+str(d.target),20,T.GOLD));v.add_child(p.text({"hunt":say("Defeat two forest threats (wolf or thorn).","2 orman tehdidini yen (kurt veya dikenli)."),"guardian":say("Defeat a guardian boss.","Bir muhafız boss yen."),"craft":say("Forge an Iron Sword and collect it.","Demir Kılıç üret ve topla."),"refine":say("Successfully enhance one item.","Bir eşyayı başarıyla yükselt.")}[key],19));v.add_child(p.text(game.realm_ui.cost(d.rewards),19,T.MUTED))
		var button=p.action(v,say("Claimed","Alındı") if claimed else say("Claim reward","Ödülü al"),func():
			if F.claim(game.world,id):game.realm_ui.changed();contracts()
			else:ui.toast(say("Return home and make room in storage.","Eve dön ve depoda yer aç.")),true,"quest");button.disabled=claimed or value<int(d.target) or not R.home(game.world)
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
