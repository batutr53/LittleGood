extends RefCounted
# Presentation adapters only. All commands remain in Kingdom/Industry/Hero/Trade.
const K=preload("res://scripts/kingdom.gd")
const I=preload("res://scripts/industry.gd")
const H=preload("res://scripts/hero.gd")
const T=preload("res://scripts/premium_theme.gd")
var ui
var game
var current=""
var argument=0
var history: Array=[]
var routing=false
var nested=false
var resource_labels={}
var tray
var toast_label
var craft_filter="all"
var current_recipe=""
var forge_selected=0
var filter="all"
var gifts_open=false
var scroll: ScrollContainer
var current_title=""
func _init(u,g):ui=u;game=g
func say(en: String,tr: String) -> String:return tr if ui.language=="tr" else en
func size() -> Vector2:return ui.get_viewport().get_visible_rect().size
func scale_ui() -> float:return clampf(minf(size().x/1280.0,size().y/720.0),.68,1.15)
func px(n: float) -> float:return roundf(n*scale_ui())
func text(value: String,n: int=26,color: Color=T.CREAM) -> Label:
 var visible_color=Color.WHITE if ui.high_contrast and color==T.CREAM else Color("ffe6a5") if ui.high_contrast and color==T.GOLD else color
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_override("font",ui.ui_font());l.add_theme_font_size_override("font_size",int(px(n*ui.accessibility_scale)));l.add_theme_color_override("font_color",visible_color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return l
func heading(value: String,n: int=38) -> Label:
 var l=text(value,n);l.add_theme_font_override("font",load("res://assets/phase2/lora.ttf"));return l
func image(texture: Texture2D,extent: Vector2) -> TextureRect:
 var p=TextureRect.new();p.texture=texture;p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;p.custom_minimum_size=extent;p.mouse_filter=Control.MOUSE_FILTER_IGNORE;return p
func action(parent: Node,title: String,cb: Callable,primary=false,key="") -> Button:
 var b=ui.button(title,cb,primary);b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if not key.is_empty():b.icon=T.icon(key);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(px(48)));b.add_theme_constant_override("h_separation",int(px(18)));b.alignment=HORIZONTAL_ALIGNMENT_LEFT
 parent.add_child(b);return b
func route(destination: String,arg: int=0,remember=true):
 if remember and not current.is_empty() and current!=destination:history.append({"key":current,"arg":argument})
 if history.size()>16:history.pop_front()
 current=destination;argument=arg;nested=false;routing=true
 match destination:
  "quest":quest()
  "building":building(arg)
  "inventory":inventory()
  "item":item_detail(arg)
  "forge":forge(arg)
  "recipe":recipe_detail()
  "hero":hero()
  "map":world_map()
  "menu":menu()
  "workers":workers()
  "army":army()
  "unit":unit_detail(arg)
  "trade":trade()
  "construction":construction()
  "settings":ui.legacy_settings()
 routing=false
func back():
 if not game.has_player_world:ui.main_menu();return
 if nested:nested=false;route(current,argument,false);return
 if not history.is_empty():
  var previous=history.pop_back();route(previous.key,int(previous.arg),false)
 else:ui.close()
func surface(title: String,compact=false) -> VBoxContainer:
 ui.end_live_route();game.reset_gesture();game.in_menu=true;ui.world_controls(false)
 if not routing and not current.is_empty():nested=true
 if is_instance_valid(ui.modal):ui.root.remove_child(ui.modal);ui.modal.queue_free()
 if is_instance_valid(ui.veil):ui.root.remove_child(ui.veil);ui.veil.queue_free()
 var viewport=size();var margin=px(22);var top=px(26);var bottom=px(26)
 if OS.has_feature("mobile"):
  var safe=DisplayServer.get_display_safe_area();var physical=DisplayServer.screen_get_size()
  if physical.x>0:
   top=maxf(top,safe.position.y*viewport.x/physical.x+px(12));bottom=maxf(bottom,(physical.y-safe.end.y)*viewport.x/physical.x+px(12))
 ui.veil=ColorRect.new();ui.veil.color=Color(.015,.035,.055,.48 if not compact else .08);ui.veil.position=Vector2.ZERO;ui.veil.size=viewport;ui.root.add_child(ui.veil)
 ui.modal=PanelContainer.new();ui.modal.name="GameSurface";var box=T.box(T.INK);box.content_margin_left=px(28);box.content_margin_right=px(28);box.content_margin_top=px(24);box.content_margin_bottom=px(24);ui.modal.add_theme_stylebox_override("panel",box)
 var height=minf(viewport.y-top-bottom,px(580)) if compact else viewport.y-top-bottom
 ui.modal.position=Vector2(margin,viewport.y-bottom-height if compact else top);ui.modal.size=Vector2(viewport.x-margin*2,height);ui.modal_base_y=ui.modal.position.y;ui.root.add_child(ui.modal)
 var paint=preload("res://scripts/premium_surface.gd").new();paint.book=current=="quest";paint.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.modal.add_child(paint)
 var stack=VBoxContainer.new();stack.add_theme_constant_override("separation",int(px(20)));ui.modal.add_child(stack)
 var title_row=HBoxContainer.new();title_row.add_theme_constant_override("separation",int(px(12)));stack.add_child(title_row)
 title_row.add_child(image(T.icon("quest" if current=="quest" else "crown"),Vector2.ONE*px(56)))
 var title_label=heading(title,34);title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_row.add_child(title_label)
 var close=ui.button("×",back);close.name="SurfaceBack";close.tooltip_text=ui.t("back");close.custom_minimum_size=Vector2.ONE*px(72);title_row.add_child(close)
 var rule=HSeparator.new();rule.modulate=T.GOLD;stack.add_child(rule)
 scroll=ScrollContainer.new();scroll.name="SurfaceScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;stack.add_child(scroll)
 var v=VBoxContainer.new();v.name="SurfaceContent";v.size_flags_horizontal=Control.SIZE_EXPAND_FILL;v.add_theme_constant_override("separation",int(px(22)));scroll.add_child(v);current_title=title
 if compact:
  ui.veil.gui_input.connect(func(event):
   if event is InputEventMouseButton and not event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not ui.modal.get_global_rect().has_point(event.position):ui.close())
 ui.modal.modulate.a=1;return v
func banner(parent: Node,height=180):
 var path="res://assets/ui_rebirth/chapter-flame.png"
 if ResourceLoader.exists(path):
  var art=image(load(path),Vector2(0,px(height)));art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.clip_contents=true;parent.add_child(art)
func build_hud():
 if is_instance_valid(ui.root):ui.remove_child(ui.root);ui.root.queue_free()
 ui.modal=null;ui.veil=null;ui.root=Control.new();ui.root.name="WorldHUD";ui.root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.root.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(ui.root)
 var vw=size().x;var h=size().y;var m=px(16);var unit=px(62);var rail=unit+px(18);var side=px(320)
 # Landscape layout: the planet stays open in the middle while all frequent actions live on the two edges.
 var rail_bg=Panel.new();rail_bg.add_theme_stylebox_override("panel",T.box(Color("112631"),true));put(rail_bg,Rect2(m,m,unit,h-m*2))
 var emblem=quick_icon(rail_bg,"crown",func():route("quest"),ui.t("chronicle"),0)
 var nav_y=unit+px(22)
 quick_icon(rail_bg,"hammer",func():route("construction"),say("Build","Kur"),nav_y);nav_y+=unit+px(10)
 quick_icon(rail_bg,"workers",func():route("workers"),say("People","İnsanlar"),nav_y);nav_y+=unit+px(10)
 if game.world.has("kingdom") and I.enabled(game.world):quick_icon(rail_bg,"bag",func():route("inventory"),say("Inventory","Çanta"),nav_y);nav_y+=unit+px(10)
 if game.world.has("kingdom") and H.enabled(game.world):quick_icon(rail_bg,"hero",func():route("hero"),say("Champion","Şampiyon"),nav_y);nav_y+=unit+px(10)
 quick_icon(rail_bg,"map",func():route("map") if game.world.has("kingdom") else ui.journal(),say("World map","Dünya haritası"),nav_y)
 quick_icon(rail_bg,"menu",func():route("menu"),say("More","Diğer"),h-m*2-unit)
 ui.header=heading("",28);put(ui.header,Rect2(rail+px(12),m,vw-rail-side-px(28),px(38)))
 ui.header.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;ui.header.autowrap_mode=TextServer.AUTOWRAP_OFF
 ui.stats=text("",17,T.MUTED);put(ui.stats,Rect2(rail+px(12),m+px(39),vw-rail-side-px(28),px(28)))
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",int(px(18)));row.mouse_filter=Control.MOUSE_FILTER_IGNORE;put(row,Rect2(rail+px(12),m+px(75),vw-rail-side-px(28),px(38)));resource_labels.clear()
 for key in ["wood","stone","gold","food"]:
  var cell=HBoxContainer.new();cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(cell)
  var key_icon=key;cell.add_child(image(T.icon(key_icon),Vector2.ONE*px(34)));var l=text("0",22);cell.add_child(l);resource_labels[key]=l
 var side_bg=Panel.new();side_bg.add_theme_stylebox_override("panel",T.box(Color("112631"),true));put(side_bg,Rect2(vw-side-m,m,side,h-m*2))
 ui.spirit=text("",18,T.GOLD);put(ui.spirit,Rect2(vw-side+px(20),m+px(18),side-px(40),px(32)))
 ui.realm_bar=ui.button("",func():route("menu"));ui.realm_bar.hide();ui.root.add_child(ui.realm_bar)
 ui.chapter=ui.button("",func():route("quest") if game.world.has("kingdom") else ui.follow_chapter());ui.chapter.name="CurrentObjective";ui.chapter.icon=T.icon("quest");ui.chapter.expand_icon=true;ui.chapter.add_theme_constant_override("icon_max_width",int(px(48)));ui.chapter.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;ui.chapter.alignment=HORIZONTAL_ALIGNMENT_LEFT;put(ui.chapter,Rect2(vw-side+px(16),m+px(64),side-px(32),px(154)))
 ui.hint=text("",18,T.CREAM);put(ui.hint,Rect2(vw-side+px(20),m+px(232),side-px(40),px(72)))
 var side_height=h-m*2;var world_controls_y=side_height-unit*5-px(32)
 quick_icon(side_bg,"minus",func():game.view.zoom_at(game.view.origin,.88),say("Zoom out","Uzaklaş"),world_controls_y)
 quick_icon(side_bg,"plus",func():game.view.zoom_at(game.view.origin,1.12),say("Zoom in","Yakınlaş"),world_controls_y+unit+px(10))
 quick_icon(side_bg,"center",func():game.view.pan=Vector2.ZERO, say("Center world","Dünyayı ortala"),world_controls_y+(unit+px(10))*2)
 ui.speed_button=ui.button("1×",func():game.speed=3 if game.speed==1 else 1;ui.refresh());put(ui.speed_button,Rect2(vw-side+px(18),h-m-px(82),side-px(36),px(64)))
 var gifts=quick_icon(side_bg,"gift",func():gifts_open=not gifts_open;tray.visible=gifts_open,ui.t("gift"),h-m-unit*2-px(14));gifts.name="Gifts"
 tray=HBoxContainer.new();tray.name="GiftPalette";tray.visible=false;tray.add_theme_constant_override("separation",int(px(8)));put(tray,Rect2(rail+px(14),h-m-px(146),vw-rail-side-px(30),px(72)));ui.power_buttons.clear();ui.power_icons.clear()
 for i in range(6):
  var b=ui.button(ui.t(ui.POWER_KEYS[i]),func():ui.choose_power(i));b.custom_minimum_size=Vector2.ZERO;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",int(px(18)));tray.add_child(b);ui.power_buttons.append(b)
 var access=HBoxContainer.new();access.name="AccessibilityQuickAccess";access.add_theme_constant_override("separation",int(px(6)));put(access,Rect2(rail+px(12),h-m-px(62),vw-rail-side-px(30),px(50)))
 quick_access(access,"A","text",say("Text size","Metin boyutu"))
 quick_access(access,"C","contrast",say("High contrast","Yüksek kontrast"))
 quick_access(access,"S","sound",say("Sound","Ses"))
 quick_access(access,"V","haptics",say("Haptics","Titreşim"))
 quick_access(access,"30","quality",say("Battery saver","Pil tasarrufu"))
 quick_access(access,"TR" if ui.language=="en" else "EN","language",say("Language","Dil"))
 ui.refresh()
func quick_icon(parent: Control,key: String,cb: Callable,tip: String,y: float) -> Button:
 var b=ui.button("",cb);b.tooltip_text=tip;b.icon=T.icon(key) if ResourceLoader.exists("res://assets/ui_rebirth/"+key+".svg") else load("res://assets/phase2/icons/"+key+".svg");b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(px(34)));b.custom_minimum_size=Vector2(px(62),px(62));parent.add_child(b);b.position=Vector2(px(0),y);b.size=Vector2(px(62),px(62));return b
func quick_access(parent: Control,glyph: String,kind: String,tip: String):
 var b=ui.button(glyph,func():ui.accessibility_toggle(kind));b.name="Access"+kind.capitalize();b.tooltip_text=tip;b.custom_minimum_size=Vector2(px(52),px(50));b.add_theme_font_size_override("font_size",int(px(20)));b.alignment=HORIZONTAL_ALIGNMENT_CENTER
 for state in ["normal","hover","pressed","disabled","focus"]:
  var skin=T.box(Color("1c3440"),state=="focus");skin.content_margin_left=px(4);skin.content_margin_right=px(4);skin.content_margin_top=px(2);skin.content_margin_bottom=px(2);b.add_theme_stylebox_override(state,skin)
 parent.add_child(b)
func put(control: Control,rect: Rect2):ui.root.add_child(control);control.position=rect.position;control.size=rect.size
func refresh_hud():
 if not is_instance_valid(ui.header) or game.world.is_empty():return
 var w=game.world;ui.header.add_theme_font_size_override("font_size",int(px(30)));ui.stats.text=(say("DAY ","GÜN ")+str(1+int(w.tick)/30)+"   ·   "+say("REALM ","DİYAR ")+str(K.level(w))) if w.has("kingdom") else say("A world of your own","Sana ait bir dünya")
 ui.realm_bar.hide();tray.visible=gifts_open and not game.in_menu;ui.spirit.text=str(int(w.energy))+" · "+say("spirit","ruh")
 if w.has("kingdom"):
  for key in resource_labels:resource_labels[key].text=str(int(K.home(w).food)) if key=="food" else str(int(w.kingdom.stock[key])/1000)
  var q=K.current(w);ui.chapter.text=(game.realm_ui.localized(q.title)+"\n"+game.realm_ui.localized(q.objectives[0].text)) if not q.is_empty() else say("Beyond your kingdom\nOpen your journal and choose a new journey","Krallığının ötesinde\nGünlüğünü aç ve yeni yolculuğunu seç")
 else:
  for l in resource_labels.values():l.text="—"
 ui.chapter.text=ui.t(LivingStories.objective(w))
 if ui.toast_until==0:ui.hint.text=""
func quest():
 if not game.world.has("kingdom"):game.realm_ui.intro();return
 ui.page="kingdom";var w=game.world;var q=K.current(w);var v=surface(say("The Kingdom Chronicle","Krallık Günlüğü"));banner(v,190)
 var chapter_name=say("CHAPTER ","BÖLÜM ")+str(K.tier(w))+"    /    "+say("REALM ","DİYAR ")+str(K.level(w))
 v.add_child(text(chapter_name,19,T.GOLD))
 if q.is_empty():
  v.add_child(heading(say("A new horizon awaits","Yeni bir ufuk seni bekliyor")))
  v.add_child(text(say("Your completed chapters stay with your world. Prepare your next journey with Arin.","Tamamladığın bölümler dünyanda saklanıyor. Arin ile bir sonraki yolculuğunu hazırla.")))
  action(v,say("Continue your story","Hikâyeni sürdür"),game.realm_ui.legacy_open,true,"quest")
  if H.enabled(w):action(v,say("Beyond the kingdom","Krallığın ötesinde"),func():route("map"),false,"map")
 else:
  v.add_child(heading(game.realm_ui.localized(q.title),38));v.add_child(text(game.realm_ui.localized(q.description),27,T.MUTED))
  for objective in q.objectives:
   var o=objective;var value=minf(float(o.target),K.progress(w,o));var complete=value>=float(o.target)
   var row=HBoxContainer.new();row.add_theme_constant_override("separation",int(px(14)));v.add_child(row)
   var check=text("✓" if complete else "◇",30,T.GOLD);check.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;check.custom_minimum_size.x=px(32);row.add_child(check)
   var copy=text(game.realm_ui.localized(o.text),27);copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(copy)
   var progress=text(str(int(value))+" / "+str(int(o.target)),22,T.GOLD);progress.size_flags_horizontal=Control.SIZE_SHRINK_END;progress.custom_minimum_size.x=px(64);row.add_child(progress)
   if not complete:action(v,say("Go to objective","Hedefe git"),func():game.realm_ui.navigate(o.navigate),false,"map")
  v.add_child(text(say("YOUR REWARD","ÖDÜLÜN"),19,T.GOLD));v.add_child(text(game.realm_ui.cost(q.rewards),26))
  var claim=action(v,say("Claim verified reward","Doğrulanan ödülü al"),func():game.realm_ui.claim_reward(q.id),true,"chest");claim.disabled=not K.complete(w,q)
 v.add_child(text(say("YOUR JOURNEY SO FAR","ŞİMDİYE KADARKİ YOLCULUĞUN"),19,T.GOLD))
 var past=K.quests().filter(func(entry):return entry.id in w.kingdom.claimed);past.reverse()
 for entry in past:
  var e=entry;action(v,"✓  "+game.realm_ui.localized(e.title),func():completed_quest(e))
func completed_quest(q: Dictionary):
 var v=surface(say("Remembered chapter","Hatırlanan bölüm"));banner(v,150);v.add_child(heading(game.realm_ui.localized(q.title)));v.add_child(text(game.realm_ui.localized(q.description)));v.add_child(text(say("Completed · this reward has already been received.","Tamamlandı · bu ödül zaten alındı."),25,T.GOLD));action(v,say("Current chapter","Güncel bölüm"),func():route("quest",0,false))
func building(id: int):
 var found=game.world.kingdom.buildings.filter(func(b):return int(b.id)==id)
 if found.is_empty():ui.toast(say("This building is unavailable.","Bu bina kullanılamıyor."));return
 var b=found[0];var d=K.buildings()[b.kind];game.view.selected=int(b.cell);game.view.pan=-game.view.project(game.world.cells[int(b.cell)])*game.view.zoom
 ui.page="kingdom";var v=surface(game.realm_ui.localized(d.name),true);var row=HBoxContainer.new();v.add_child(row);row.add_child(image(game.view.kingdom_layer.texture(b.kind),Vector2.ONE*px(94)));var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info)
 info.add_child(text(say("LEVEL ","SEVİYE ")+str(int(b.level)),19,T.GOLD));info.add_child(text(game.realm_ui.localized(d.description),21))
 var rate=K.activity_rate(game.world,b);info.add_child(text(say("Working","Çalışıyor") if rate>0 else say("Construction","İnşa ediliyor") if not K.ready(b) else say("Resting · check workers and supplies","Dinleniyor · işçi ve malzemeyi kontrol et"),21,T.MUTED))
 var bar=ProgressBar.new();bar.max_value=b.required;bar.value=b.progress;bar.show_percentage=true;bar.custom_minimum_size.y=px(22);v.add_child(bar)
 v.add_child(text(say("Assigned workers: ","Atanmış işçiler: ")+str(K.occupied(game.world,id))+" / "+str(int(d.slots))+say("  ·  Output / tick: ","  ·  Üretim / tur: ")+str(snappedf(rate,.01)),22))
 var controls=HBoxContainer.new();v.add_child(controls)
 if b.kind=="forge":action(controls,say("Forge","Üret"),func():route("forge",id),true,"forge")
 elif b.kind=="marketplace" and preload("res://scripts/trade.gd").enabled(game.world):action(controls,say("Trade","Ticaret"),func():route("trade"),true,"caravan")
 elif b.kind=="barracks" and preload("res://scripts/military.gd").enabled(game.world):action(controls,say("Company","Birlik"),func():route("army"),true,"sword")
 action(controls,say("Workers","İşçiler"),func():route("workers"),false,"workers")
 action(v,say("Building details & upgrades","Bina ayrıntıları ve geliştirmeler"),func():game.realm_ui.legacy_inspect_building(id),false,"hammer")

func inventory():
 if not I.enabled(game.world):game.realm_ui.legacy_inventory();return
 ui.page="kingdom";var w=game.world;var v=surface(say("The Travelling Satchel","Yolcu Çantası"))
 var cap=HBoxContainer.new();v.add_child(cap);cap.add_child(image(T.icon("bag"),Vector2.ONE*px(80)));var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cap.add_child(words);words.add_child(heading(say("Your collected treasures","Topladığın hazineler"),30));words.add_child(text(str(w.kingdom.industry.items.size())+" / "+str(I.MAX_ITEMS)+say(" items · reserved gear stays protected"," eşya · ayrılmış donanımlar korunur"),21,T.MUTED))
 var tabs=HBoxContainer.new();tabs.add_theme_constant_override("separation",int(px(7)));v.add_child(tabs)
 for tab in [["all",say("All","Tümü")],["weapon",say("Gear","Donanım")],["tool",say("Tools","Alet")],["artifact",say("Relics","Yadigâr")]]:
  var key=tab[0];var b=action(tabs,tab[1],func():filter=key;route("inventory",0,false),filter==key);b.add_theme_font_size_override("font_size",int(px(22)))
 var grid=GridContainer.new();grid.columns=3 if size().x>=600 else 2;grid.add_theme_constant_override("h_separation",int(px(12)));grid.add_theme_constant_override("v_separation",int(px(12)));v.add_child(grid)
 var items=w.kingdom.industry.items.duplicate();items.sort_custom(func(a,b):return str(a.recipe)<str(b.recipe) if a.recipe!=b.recipe else int(a.id)<int(b.id))
 for owned in items:
  var d=I.recipes()[owned.recipe];var category=d.get("category","tool");var id=int(owned.id)
  if filter!="all" and (category!=filter if filter!="weapon" else not category in ["weapon","shield","armor"]):continue
  var cell=VBoxContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(cell)
  var b=action(cell,"",func():route("item",id));b.custom_minimum_size=Vector2(0,px(145));b.icon=load("res://assets/kingdom/"+owned.recipe+".svg");b.expand_icon=true;b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.add_theme_constant_override("icon_max_width",int(px(110)));b.tooltip_text=game.realm_ui.localized(d.name)
  var equipped=w.kingdom.industry.equipped.any(func(s):return int(s.item)==id) or w.kingdom.get("adventure",{}).get("hero",{}).get("equipment",{}).values().has(id)
  cell.add_child(text(game.realm_ui.localized(d.name),22));cell.add_child(text(say("Equipped","Kuşanıldı") if equipped else "#"+str(id),18,T.GOLD))
 if items.is_empty():v.add_child(text(say("Your satchel is waiting for its first crafted tool.","Çantan ilk ürettiğin aleti bekliyor."),26,T.MUTED))
 action(v,say("Citizen tools · compare and assign","Sakin aletleri · karşılaştır ve ata"),game.realm_ui.legacy_inventory,false,"workers")
 action(v,say("Craft something new","Yeni bir şey üret"),func():route("forge"),true,"forge")
 action(v,say("Salvage unused equipment","Kullanılmayan donanımı sök"),game.trade_ui.inventory,false,"hammer")
func item_detail(id: int):
 var w=game.world;var owned=I.item(w,id)
 if owned.is_empty():route("inventory",0,false);return
 var d=I.recipes()[owned.recipe];var slot=d.get("category","tool");var v=surface(game.realm_ui.localized(d.name));v.add_child(image(load("res://assets/kingdom/"+owned.recipe+".svg"),Vector2(0,px(230))));v.add_child(heading(game.realm_ui.localized(d.name)));v.add_child(text(game.realm_ui.localized(d.description),28,T.MUTED))
 if slot in H.SLOTS and H.enabled(w) and not w.kingdom.adventure.hero.is_empty():
  var stats=H.stats(w);var next=H.preview(w,slot,id)
  for pair in [["attack",say("Attack","Saldırı")],["defense",say("Defense","Savunma")],["health",say("Health","Can")]]:v.add_child(text(pair[1]+"    "+str(stats[pair[0]])+"  →  "+str(next[pair[0]]),28))
  var equipped=int(w.kingdom.adventure.hero.equipment[slot])==id
  var equip=action(v,say("Equipped","Kuşanıldı") if equipped else say("Equip this item","Bu eşyayı kuşan"),func():
   if H.equip(w,slot,id):game.realm_ui.changed();game.checkpoint("hero-gear");route("hero",0,false),true,"hero")
  equip.disabled=equipped or w.kingdom.adventure.run.get("active",false)
 elif slot=="tool":action(v,say("Choose a citizen","Bir sakin seç"),func():route("workers"),true,"workers")
 if slot=="artifact":v.add_child(text(say("Protected relic · cannot be sold or salvaged.","Korunan yadigâr · satılamaz veya sökülemez."),23,T.GOLD))
 action(v,say("Return to satchel","Çantaya dön"),func():route("inventory",0,false),false,"bag")
func hero():
 if not H.enabled(game.world):ui.toast(say("A champion joins your kingdom in chapter III.","Şampiyon, III. bölümde krallığına katılır."));route("quest",0,false);return
 if game.world.kingdom.adventure.hero.is_empty():game.hero_ui.legacy_profile();return
 ui.page="kingdom";var w=game.world;var h=w.kingdom.adventure.hero;var v=surface(say("Hall of the Champion","Şampiyonun Salonu"));var row=HBoxContainer.new();v.add_child(row)
 row.add_child(image(load("res://assets/adventure/warrior.png"),Vector2(px(190),px(280))))
 var identity=VBoxContainer.new();identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(identity);identity.add_child(text(say("WARRIOR · LEVEL ","SAVAŞÇI · SEVİYE ")+str(H.level(h)),19,T.GOLD));identity.add_child(heading(h.name,44));var stats=H.stats(w)
 identity.add_child(text(str(int(h.hp))+" / "+str(stats.health)+say(" health"," can"),27));var bar=ProgressBar.new();bar.max_value=stats.health;bar.value=h.hp;bar.show_percentage=false;bar.custom_minimum_size.y=px(14);identity.add_child(bar);identity.add_child(text(say("Attack ","Saldırı ")+str(stats.attack)+"\n"+say("Defense ","Savunma ")+str(stats.defense),27))
 v.add_child(text(say("EQUIPMENT","DONANIM"),20,T.GOLD));var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",int(px(12)));grid.add_theme_constant_override("v_separation",int(px(12)));v.add_child(grid)
 for slot in H.SLOTS:
  var key=slot;var owned=I.item(w,int(h.equipment[slot]));var name={"weapon":say("Weapon","Silah"),"shield":say("Shield","Kalkan"),"armor":say("Armor","Zırh"),"artifact":say("Artifact","Eser")}[slot]
  var b=action(grid,name+"\n"+(say("Empty slot","Boş yuva") if owned.is_empty() else game.realm_ui.localized(I.recipes()[owned.recipe].name)),func():game.hero_ui.equipment(key));b.custom_minimum_size.y=px(140)
  b.icon=load("res://assets/kingdom/"+owned.recipe+".svg") if not owned.is_empty() else T.icon("sword" if slot=="weapon" else "shield" if slot in ["shield","armor"] else "chest");b.expand_icon=true;b.add_theme_constant_override("icon_max_width",int(px(62)));b.add_theme_font_size_override("font_size",int(px(23)))
 action(v,say("Open your satchel","Çantanı aç"),func():route("inventory"),false,"bag");action(v,say("Prepare an expedition","Bir sefer hazırla"),func():route("map"),true,"map")
func world_map():
 if not H.enabled(game.world):route("quest",0,false);return
 ui.page="kingdom";var v=surface(say("Beyond the Kingdom","Krallığın Ötesinde"));v.add_child(text(say("Choose a real path. Your kingdom waits safely during the expedition.","Gerçek bir patika seç. Sefer boyunca krallığın güvenle bekler."),24,T.MUTED))
 var R=preload("res://scripts/regions.gd")
 for id in R.IDS:
  var key=id;var d=R.data(id);var unlocked=R.unlocked(game.world,id)
  var region=VBoxContainer.new();v.add_child(region);var picture=image(load("res://assets/adventure/"+d.preview+".svg"),Vector2(0,px(180)));picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;picture.clip_contents=true;region.add_child(picture)
  region.add_child(heading(game.realm_ui.localized(d.name),32));region.add_child(text(game.realm_ui.localized(d.resources),22,T.MUTED))
  region.add_child(text((say("Explored","Keşfedildi") if R.seen(game.world,id) else say("Unexplored","Keşfedilmedi"))+" · "+(say("Path open","Yol açık") if unlocked else say("Locked · inspect requirements","Kilitli · koşulları incele")),20,T.GOLD))
  action(region,say("Inspect destination","Bölgeyi incele"),func():game.hero_ui.destination(key),unlocked,"map")
 if preload("res://scripts/trade.gd").enabled(game.world):action(v,say("Caravan routes · a different journey","Kervan yolları · başka bir yolculuk"),func():route("trade"),false,"caravan")
func menu():
 ui.page="menu";game.checkpoint("menu");var v=surface(say("Your Living Kingdom","Yaşayan Krallığın"));banner(v,150)
 var entries=[["quest",say("The Chronicle","Görev Günlüğü"),"quest"],["construction",say("Build & grow","Kur ve büyüt"),"hammer"],["workers",say("People & work","İnsanlar ve işler"),"workers"]]
 if I.enabled(game.world):entries.append_array([["inventory",say("The Satchel","Çanta"),"bag"],["forge",say("The Hearthforge","Ocak Demircisi"),"forge"]])
 if H.enabled(game.world):entries.append_array([["hero",say("Champion","Şampiyon"),"hero"],["map",say("World paths","Dünya yolları"),"map"]])
 if preload("res://scripts/military.gd").enabled(game.world):entries.append(["army",say("The Company","Sınır Birliği"),"sword"])
 if preload("res://scripts/trade.gd").enabled(game.world):entries.append(["trade",say("Trade routes","Ticaret yolları"),"caravan"])
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",int(px(12)));grid.add_theme_constant_override("v_separation",int(px(12)));v.add_child(grid)
 for entry in entries:
  var key=entry[0];var b=action(grid,entry[1],func():route(key),false,entry[2]);b.custom_minimum_size.y=px(105);b.add_theme_font_size_override("font_size",int(px(24)))
 action(v,ui.t("chronicle"),ui.history,false,"quest");action(v,ui.t("journal"),ui.journal,false,"map");action(v,ui.t("neighbors"),ui.neighbors,false,"hero");action(v,ui.t("settings"),func():route("settings"),false,"menu")
 action(v,say("World gifts, collections & more","Dünya armağanları, koleksiyonlar ve diğerleri"),ui.legacy_menu)
 action(v,say("Return to your world","Dünyana dön"),ui.close,true)
func main_menu():
 current="";history.clear();ui.page="main";var v=surface("LittleGod");banner(v,310);v.add_child(heading(say("A little world.\nA story only you can tell.","Küçük bir dünya.\nYalnızca senin anlatacağın bir hikâye."),42));v.add_child(text(ui.t("welcome"),26,T.MUTED))
 if Persistence.has_save(game.save_path):action(v,ui.t("continue"),game.restore,true,"crown")
 action(v,ui.t("new"),ui.creation,false,"gift");action(v,"English / Türkçe",func():ui.toggle_language();main_menu())
 action(v,say("Online universe","Çevrimiçi evren"),ui.online_screen,false,"map");action(v,ui.t("local_universe"),ui.local_universe);action(v,ui.t("beta"),ui.beta_tools)
func forge(forge_id: int=0):
 if not I.enabled(game.world):game.realm_ui.legacy_workshop(forge_id);return
 ui.page="kingdom";var w=game.world;var v=surface(say("The Hearthforge","Ocak Demircisi"));var forges=w.kingdom.buildings.filter(func(b):return b.kind=="forge" and K.ready(b))
 if not forges.any(func(b):return int(b.id)==forge_id):forge_id=0 if forges.is_empty() else int(forges[0].id)
 forge_selected=forge_id
 var summary=HBoxContainer.new();v.add_child(summary);summary.add_child(image(T.icon("forge"),Vector2.ONE*px(90)));var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;summary.add_child(words);words.add_child(heading(say("From ore to legacy","Cevherden mirasa"),32));words.add_child(text(say("Iron ","Demir ")+str(snappedf(w.kingdom.stock.iron/1000.0,.1))+" · "+say("Smiths ","Demirciler ")+str(K.assigned(w,forge_id).size() if forge_id>0 else 0),24,T.GOLD))
 words.add_child(text(say("Materials are reserved once. Close the menu to let your smith work.","Malzeme bir kez ayrılır. Demircinin çalışması için menüyü kapat."),21,T.MUTED))
 if forges.size()>1:
  for f in forges:
   var id=int(f.id);action(v,say("Forge #","Demirci #")+str(id),func():route("forge",id,false),id==forge_selected)
 if not w.kingdom.industry.queue.is_empty():
  v.add_child(text(say("ON THE ANVIL","ÖRSÜN ÜZERİNDE"),19,T.GOLD))
  for job in w.kingdom.industry.queue:
   var d=I.recipes()[job.recipe];v.add_child(text(game.realm_ui.localized(d.name),24));var bar=ProgressBar.new();bar.max_value=int(d.ticks)*K.SCALE;bar.value=job.progress;bar.custom_minimum_size.y=px(23);v.add_child(bar)
 var tabs=HBoxContainer.new();v.add_child(tabs)
 for tab in [["all",say("All","Tümü")],["tool",say("Tools","Aletler")],["gear",say("Equipment","Donanım")]]:
  var key=tab[0];var button=action(tabs,tab[1],func():craft_filter=key;route("forge",forge_selected,false),craft_filter==key);button.add_theme_font_size_override("font_size",int(px(22)))
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",int(px(14)));grid.add_theme_constant_override("v_separation",int(px(20)));v.add_child(grid)
 for id in I.recipes():
  var d=I.recipes()[id];var category=d.get("category","tool")
  if id=="sun_relic":continue
  if id in preload("res://scripts/sanctuary.gd").GEAR and not preload("res://scripts/sanctuary.gd").enabled(w):continue
  if id=="crystal_tonic" and not preload("res://scripts/ashen_desert.gd").enabled(w):continue
  if category!="tool" and (not H.enabled(w) or (int(d.level)>H.REALM_CAP and not preload("res://scripts/military.gd").enabled(w))):continue
  if craft_filter=="tool" and category!="tool" or craft_filter=="gear" and category=="tool":continue
  var key=id;var tile=VBoxContainer.new();tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(tile)
  var b=action(tile,"",func():current_recipe=key;route("recipe"));b.icon=load("res://assets/kingdom/"+id+".svg");b.expand_icon=true;b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.add_theme_constant_override("icon_max_width",int(px(96)));b.custom_minimum_size.y=px(130)
  tile.add_child(text(game.realm_ui.localized(d.name),23));tile.add_child(text(game.realm_ui.cost(d.cost),20,T.MUTED));tile.add_child(text(say("Inspect recipe","Tarifi incele") if K.afford(w,d.cost) else say("Materials missing","Malzeme eksik"),19,T.GOLD))
 action(v,say("Assign a smith","Bir demirci ata"),func():route("workers"),false,"workers");action(v,say("Watch your village work","Köyünün çalışmasını izle"),ui.close,true)
func recipe_detail():
 var w=game.world
 if not I.recipes().has(current_recipe):route("forge",forge_selected,false);return
 var d=I.recipes()[current_recipe];var v=surface(game.realm_ui.localized(d.name));v.add_child(image(load("res://assets/kingdom/"+current_recipe+".svg"),Vector2(0,px(190))));v.add_child(heading(game.realm_ui.localized(d.name),34));v.add_child(text(game.realm_ui.localized(d.description),26,T.MUTED));v.add_child(text(say("MATERIALS · OWNED / REQUIRED","MALZEMELER · MEVCUT / GEREKLİ"),19,T.GOLD))
 var reasons=[]
 for key in d.cost:
  var owned=w.kingdom.stock.get(key,0)/1000.0;var required=int(d.cost[key]);var title=game.realm_ui.cost({key:required});v.add_child(text(title+"    ·    "+str(snappedf(owned,.1))+" / "+str(required),25,T.CREAM if owned>=required else Color("e0a583")))
  if owned<required:reasons.append(say("Not enough ","Yetersiz: ")+game.realm_ui.cost({key:required-ceili(owned)}))
 if forge_selected==0:reasons.append(say("Build and finish a forge first.","Önce bir demirci inşa edip tamamla."))
 if K.level(w)<int(d.level):reasons.append(say("Requires realm ","Gerekli diyar: ")+str(int(d.level)))
 if w.kingdom.industry.queue.size()>=I.MAX_QUEUE:reasons.append(say("The production queue is full.","Üretim sırası dolu."))
 if w.kingdom.industry.items.size()+w.kingdom.industry.queue.size()>=I.MAX_ITEMS:reasons.append(say("Your inventory is full.","Envanterin dolu."))
 if current_recipe in preload("res://scripts/sanctuary.gd").GEAR and not w.kingdom.adventure.regions.ancients.researched:reasons.append(say("Study the Sun Relic with Arin.","Güneş Yadigârı'nı Arin ile araştır."))
 if current_recipe=="crystal_tonic" and not preload("res://scripts/ashen_desert.gd").can_spend(w,2000):reasons.append(say("Register the crystal before spending it.","Kristali harcamadan önce kaydet."))
 for reason in reasons:v.add_child(text(reason,23,Color("e0a583")))
 var craft=action(v,say("Begin forging","Dövümü başlat"),func():
  if I.queue(w,current_recipe,forge_selected):game.realm_ui.changed();game.checkpoint("craft");route("forge",forge_selected,false);ui.toast(say("Materials reserved. Your smith is ready.","Malzeme ayrıldı. Demircin hazır."))
  else:ui.toast(say("Requirements changed. Inspect the recipe again.","Koşullar değişti. Tarifi yeniden incele.")),true,"forge")
 craft.disabled=not reasons.is_empty()
 if forge_selected>0 and K.assigned(w,forge_selected).is_empty():v.add_child(text(say("Assign a smith after queuing; work needs a real worker.","Sıraya aldıktan sonra demirci ata; üretim için gerçek işçi gerekir."),23,T.MUTED))
func army():
 var M=preload("res://scripts/military.gd");var w=game.world
 if not M.enabled(w):return
 ui.page="kingdom";var v=surface(say("The Border Company","Sınır Birliği"));var row=HBoxContainer.new();v.add_child(row);row.add_child(image(T.icon("sword"),Vector2.ONE*px(98)));var title=VBoxContainer.new();title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(title);title.add_child(heading(w.kingdom.adventure.hero.name,36));title.add_child(text(say("COMMANDER · ","KOMUTAN · ")+str(w.kingdom.military.units.size())+" / 6",21,T.GOLD))
 for u in w.kingdom.military.units:
  var id=int(u.id);var citizen=w.kingdom.workers.filter(func(c):return int(c.id)==int(u.worker))[0];var portrait=HBoxContainer.new();v.add_child(portrait);portrait.add_child(image(load("res://assets/kingdom/"+u.kind+".svg"),Vector2(px(90),px(120))));var detail=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;portrait.add_child(detail);detail.add_child(heading(citizen.name,30));detail.add_child(text(game.realm_ui.localized(I.recipes()[I.item(w,int(u.gear)).recipe].name),22,T.MUTED))
  var status={"training":say("Training","Eğitim"),"ready":say("Ready","Hazır"),"injured":say("Injured","Yaralı"),"recovering":say("Recovering","İyileşiyor"),"deployed":say("Deployed","Görevde")}.get(u.status,u.status)
  detail.add_child(text(status+"  ·  "+str(int(u.hp))+" / 100",21,T.GOLD));var hp=ProgressBar.new();hp.max_value=100;hp.value=u.hp;hp.show_percentage=false;hp.custom_minimum_size.y=px(12);detail.add_child(hp);action(detail,say("Manage soldier","Askeri yönet"),func():route("unit",id))
 v.add_child(text(say("FORMATION","DÜZEN"),20,T.GOLD));var formations=HBoxContainer.new();v.add_child(formations)
 for pair in [["balanced",say("Balanced","Dengeli")],["defensive",say("Defensive","Savunma")],["assault",say("Assault","Hücum")]]:
  var key=pair[0];var b=action(formations,pair[1],func():
   if M.formation(w,key):game.military_ui.changed();route("army",0,false),w.kingdom.military.formation==key);b.add_theme_font_size_override("font_size",int(px(21)))
 action(v,say("Train a free citizen","Boştaki sakini eğit"),game.military_ui.candidates,true,"workers")
 for key in ["raid","camp"]:
  var mission=key;var title_text=say("Defend the village","Köyü savun") if key=="raid" else say("March on the border camp","Sınır kampına yürü")
  var b=action(v,title_text+say(" · 3 food"," · 3 besin"),func():
   if not game.enter_army(mission):ui.toast(say("Needs ready soldiers, food and the preceding quest.","Hazır asker, besin ve önceki görev gerekli.")),false,"shield" if key=="raid" else "sword")
  b.disabled=w.kingdom.claimed.size()<(18 if key=="raid" else 19) or M.available(w).is_empty()
 action(v,say("Equipment and training details","Donanım ve eğitim ayrıntıları"),game.military_ui.legacy_open)
 action(v,say("Watch training / recovery","Eğitimi / iyileşmeyi izle"),ui.close,true)
func unit_detail(id: int):
 var M=preload("res://scripts/military.gd");var w=game.world;var u=M.unit(w,id)
 if u.is_empty():route("army",0,false);return
 var citizen=w.kingdom.workers.filter(func(c):return int(c.id)==int(u.worker))[0];var v=surface(citizen.name);v.add_child(image(load("res://assets/kingdom/"+u.kind+".svg"),Vector2(0,px(220))));v.add_child(text(game.realm_ui.localized(I.recipes()[I.item(w,int(u.gear)).recipe].name),28));v.add_child(text(str(int(u.hp))+" / 100 · XP "+str(int(u.xp)),26,T.GOLD))
 if u.status in ["ready","injured"]:
  if u.hp<100:action(v,say("Recover · 2 food + 1 gold","İyileştir · 2 besin + 1 altın"),func():
   if M.recover(w,id):game.military_ui.changed();route("army",0,false),true,"shield")
  action(v,say("Return citizen and kit to civilian duty","Sakini ve takımı sivil göreve döndür"),func():
   if M.retire(w,id):game.military_ui.changed();route("army",0,false)
   else:ui.toast(say("Deployed or reserved soldiers cannot leave duty.","Görevde veya ayrılmış asker görevden ayrılamaz.")),false,"workers")
 else:v.add_child(text(say("This soldier is busy. Return to your world to let training or recovery continue.","Bu asker meşgul. Eğitim veya iyileşmenin ilerlemesi için dünyana dön."),25,T.MUTED))
func trade():
 var TR=preload("res://scripts/trade.gd");var w=game.world
 if not TR.enabled(w):return
 ui.page="kingdom";var v=surface(say("The First Trade Road","İlk Ticaret Yolu"));var header=HBoxContainer.new();v.add_child(header);header.add_child(image(T.icon("caravan"),Vector2.ONE*px(112)));var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(words);words.add_child(heading(say("Across the old roads","Kadim yollar boyunca"),32));words.add_child(text(say("Real cargo. Real merchants. A world connected.","Gerçek yük. Gerçek tüccar. Birbirine bağlı bir dünya."),23,T.MUTED))
 var controls=HBoxContainer.new();v.add_child(controls);action(controls,say("Prepare a caravan","Kervan hazırla"),game.trade_ui.prepare,true,"caravan");action(controls,say("Prices","Fiyatlar"),game.trade_ui.prices,false,"gold")
 if w.kingdom.trade.caravans.is_empty():v.add_child(text(say("The road is quiet. Send your first caravan from a staffed marketplace.","Yol sessiz. İşçi atanmış pazardan ilk kervanını yola çıkar."),26,T.MUTED))
 for c in w.kingdom.trade.caravans:
  var id=int(c.id);var names={"outbound":say("Outbound","Gidiyor"),"blocked":say("Decision needed","Karar gerekli"),"returning":say("Returning","Dönüyor"),"ready":say("Collect at home","Evde teslim al"),"collected":say("Collected","Teslim alındı")}
  v.add_child(heading(game.realm_ui.localized(TR.routes()[c.route].name),30));var row=HBoxContainer.new();v.add_child(row);row.add_child(image(T.icon("caravan"),Vector2.ONE*px(78)));var details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(details);details.add_child(text(names[c.state]+"  ·  #"+str(id),23,T.GOLD));details.add_child(text(game.realm_ui.cost(c.cargo),22,T.MUTED));var bar=ProgressBar.new();bar.max_value=c.leg_ticks;bar.value=c.leg_ticks if c.state in ["ready","collected"] else c.progress;bar.custom_minimum_size.y=px(18);bar.show_percentage=false;details.add_child(bar)
  if c.state!="collected":action(v,say("Follow the caravan","Kervanı izle"),func():game.trade_ui.watch(id),false,"map")
 action(v,say("Assign merchants / recruit citizens","Tüccar ata / sakin işe al"),func():route("workers"),false,"workers");action(v,say("Trade rules & salvage","Ticaret kuralları ve söküm"),game.trade_ui.legacy_open)
func workers():
 if not game.world.has("kingdom"):return
 var w=game.world;var v=surface(say("People & Work","İnsanlar ve İşler"));var header=HBoxContainer.new();v.add_child(header);header.add_child(image(T.icon("workers"),Vector2.ONE*px(90)));var words=VBoxContainer.new();words.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(words);words.add_child(heading(say("Every pair of hands matters","Her elin bir hikâyesi var"),31));words.add_child(text(str(int(K.home(w).population))+" / "+str(K.capacity(w))+say(" residents · "," sakin · ")+str(K.assigned(w,0).size())+say(" free builders"," boşta inşaatçı"),23,T.GOLD))
 for c in w.kingdom.workers:
  var id=int(c.id);var job=say("Builder · free citizen","İnşaatçı · boşta sakin")
  for b in w.kingdom.buildings:
   if int(b.id)==int(c.building):job=game.realm_ui.localized(K.buildings()[b.kind].name)
  if preload("res://scripts/military.gd").worker_reserved(w,id):job=say("The Border Company","Sınır Birliği")
  if preload("res://scripts/trade.gd").worker_reserved(w,id):job=say("Caravan merchant · travelling","Kervan tüccarı · yolda")
  var row=HBoxContainer.new();v.add_child(row);row.add_child(image(T.icon("workers"),Vector2.ONE*px(66)));var detail=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(detail);detail.add_child(heading(c.name,29));detail.add_child(text(job,23,T.MUTED));var equipped=I.tool(w,id)
  if not equipped.is_empty():detail.add_child(text(game.realm_ui.localized(I.recipes()[equipped.recipe].name),20,T.GOLD))
  action(detail,say("Choose work & tools","İş ve alet seç"),func():game.realm_ui.assignments(id))
 var recruit=action(v,say("Recruit citizen · 2 food + 1 gold","Sakin işe al · 2 besin + 1 altın"),func():
  if K.recruit(w):game.realm_ui.changed();route("workers",0,false)
  else:ui.toast(say("Needs realm4, food, gold, trust and available housing.","Diyar4, besin, altın, güven ve boş konut gerekli.")),true,"workers")
 recruit.disabled=K.level(w)<4 or w.kingdom.workers.size()>=K.MAX_WORKERS
 v.add_child(text(say("Free citizens build. Give production buildings workers, then return to watch your village.","Boştaki sakinler inşa eder. Üretim binalarına işçi ata; sonra köyünü izlemek için dön."),23,T.MUTED))
func construction():
 if not game.world.has("kingdom"):return
 var w=game.world;var v=surface(say("Build a Living Village","Yaşayan Bir Köy Kur"));v.add_child(text(say("Choose a real building, then find its place in your world. Materials are spent only when you confirm.","Gerçek bir bina seç; sonra dünyanda yerini bul. Malzeme yalnızca onayladığında harcanır."),25,T.MUTED));var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",int(px(14)));grid.add_theme_constant_override("v_separation",int(px(18)));v.add_child(grid)
 for id in K.buildings():
  var d=K.buildings()[id];var key=id
  if int(d.level)>5 and not I.enabled(w):continue
  if int(d.level)>15 and not preload("res://scripts/military.gd").enabled(w):continue
  if int(d.level)>20 and not preload("res://scripts/trade.gd").enabled(w):continue
  var tile=VBoxContainer.new();tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(tile);tile.add_child(image(game.view.kingdom_layer.texture(id),Vector2(0,px(145))));tile.add_child(heading(game.realm_ui.localized(d.name),26));tile.add_child(text(game.realm_ui.cost(d.cost),21,T.MUTED));var count=w.kingdom.buildings.filter(func(b):return b.kind==key).size();var locked=K.level(w)<int(d.level) or count>=int(d.limit) or w.kingdom.buildings.size()>=K.MAX_BUILDINGS or not K.afford(w,d.cost)
  var hint=say("Realm ","Diyar ")+str(int(d.level)) if K.level(w)<int(d.level) else say("Building limit reached","Bina sınırına ulaşıldı") if count>=int(d.limit) else say("Materials missing","Malzeme eksik") if not K.afford(w,d.cost) else say("Choose a site","Yer seç")
  var b=action(tile,hint,func():game.realm_ui.begin("build",key),not locked,"hammer");b.disabled=locked;b.add_theme_font_size_override("font_size",int(px(22)))
 v.add_child(text(say("ALREADY PART OF YOUR KINGDOM","KRALLIĞININ BİR PARÇASI"),19,T.GOLD))
 for b in w.kingdom.buildings:
  var id=int(b.id);action(v,game.realm_ui.localized(K.buildings()[b.kind].name)+" · "+say("Level ","Seviye ")+str(int(b.level)),func():route("building",id))
