extends RefCounted
var e
var ui
var canvas
var scale=1.0
const T=preload("res://scripts/premium_theme.gd")
func _init(entry):e=entry;ui=e.ui
func panel(rect,title):
	var p=PanelContainer.new();p.position=rect.position*scale;p.size=rect.size*scale;p.add_theme_stylebox_override("panel",T.skin());canvas.add_child(p)
	var v=VBoxContainer.new();v.add_theme_constant_override("separation",6*scale);p.add_child(v)
	if not title.is_empty():e.text(v,title,22,T.GOLD)
	return v
func begin(title):
	e.base(title);canvas=e.canvas;scale=e.s
	var old=canvas.get_node_or_null("EntryForm")
	if old:canvas.remove_child(old);old.queue_free()
	for key in ["EntryLanguage","ExistingLocalSave"]:
		var footer=canvas.get_node_or_null(key)
		if footer:footer.hide()
	var extent=ui.get_viewport().get_visible_rect().size/scale
	return extent
func race():
	e.stage="race";var extent=begin(e.say("Choose your people","Halkını seç"));var width=minf(900,extent.x-80);var left=(extent.x-width)*.5
	for i in range(2):
		var key="human" if i==0 else "stoneborn";var v=panel(Rect2(left+i*(width*.5+8),160,width*.5-12,extent.y-275),"")
		var art=TextureRect.new();art.texture=load("res://assets/ui_kingdom/"+key+".svg");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size.y=140*scale;v.add_child(art)
		e.text(v,e.say("DAWNKIN","ŞAFAK HALKI") if i==0 else e.say("STONEBORN","TAŞSOY"),26,T.GOLD)
		e.text(v,e.say("Builders of river cities. Their oath is to shelter every traveler.","Nehir kentlerinin kurucuları. Yeminleri her yolcuya sığınak sunmak.") if i==0 else e.say("Keepers of mountain sanctuaries. They rebuild what the ancient wars broke.","Dağ tapınaklarının koruyucuları. Kadim savaşların yıktıklarını yeniden kurarlar."),17)
		e.text(v,e.say("All four classes · equal starting power","Dört sınıf · eşit başlangıç gücü"),15,T.MUTED)
		e.button(v,e.say("Choose","Seç"),func():e.selected_race=key;e.create_page(),true,"Race_"+key)
func create():
	e.stage="create";var extent=begin(e.say("Forge your legend","Efsaneni oluştur"));var width=extent.x-70;var left=35.0;var top=155.0;var height=extent.y-top-105;var side=width*.25;var middle=width*.44
	var classes=panel(Rect2(left,top,side,height),e.say("CLASS","SINIF"));e.text(classes,e.say("Dawnkin","Şafak Halkı") if e.selected_race=="human" else e.say("Stoneborn","Taşsoy"),18,T.MUTED)
	for key in e.R.CLASSES:
		var cls=key;var b=e.button(classes,e.R.NAMES[key],func():e.pending_name=e.hero_name.text;e.selected_class=cls;e.create_page(),e.selected_class==key,"FirstClass_"+key);b.tooltip_text={"warrior":e.say("Heavy armor · melee and defense","Ağır zırh · yakın saldırı ve savunma"),"priest":e.say("Sacred attacks · healing and protection","Kutsal saldırı · iyileştirme ve koruma"),"mage":e.say("Elemental magic · ranged area damage","Element büyüsü · uzaktan alan hasarı"),"rogue":e.say("Bow or daggers · speed and precision","Yay veya hançer · hız ve isabet")}[key];b.custom_minimum_size.y=42*scale
	e.button(classes,e.say("← People","← Halk seçimi"),func():e.pending_name=e.hero_name.text;race())
	var hero=panel(Rect2(left+side+12,top,middle,height),"")
	var preview=TextureRect.new();preview.texture=load("res://assets/rpg/"+e.selected_class+".png");preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;preview.custom_minimum_size.y=maxf(125,(height-105)*scale);hero.add_child(preview)
	e.hero_name=e.field(hero,e.say("Hero name · 3–24 characters","Kahraman adı · 3–24 karakter"),"HeroName");e.hero_name.max_length=24;e.hero_name.text=e.pending_name
	var stats=panel(Rect2(left+side+middle+24,top,width-side-middle-24,height),e.say("BONUS POINTS","BAŞLANGIÇ PUANI"))
	e.stat_remaining=e.text(stats,"",18,T.GOLD);e.stat_remaining.name="StartingPoints"
	for attr in e.R.ATTRIBUTES:
		var key=attr;var row=HBoxContainer.new();row.add_theme_constant_override("separation",3);stats.add_child(row)
		var label=e.text(row,{"strength":"STR","dexterity":"DEX","intelligence":"INT","magic":"MP","vitality":"HP"}[key],15);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var minus=e.button(row,"−",func():e.change_stat(key,-1),false,"StartMinus_"+key);minus.custom_minimum_size=Vector2(32,36)*scale;minus.size_flags_horizontal=Control.SIZE_SHRINK_END
		var value=e.text(row,str(e.starting_stats[key]),17,T.CREAM);value.name="StartValue_"+key;value.custom_minimum_size.x=24*scale;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;value.size_flags_horizontal=Control.SIZE_SHRINK_END
		var plus=e.button(row,"+",func():e.change_stat(key,1),false,"StartPlus_"+key);plus.custom_minimum_size=Vector2(32,36)*scale;plus.size_flags_horizontal=Control.SIZE_SHRINK_END
	e.create_button=e.button(stats,e.say("CREATE HERO","KAHRAMANI OLUŞTUR"),e.create_character,true,"CreateRealmHero");e.update_stats()
	e.status=e.text(stats,"",14,Color("df9f77"));e.status.name="EntryStatus";e.status.hide()
func daily():
	e.stage="daily";var extent=begin(e.say("Traveler's calendar","Yolcu takvimi"));var width=minf(1060,extent.x-60);var v=panel(Rect2((extent.x-width)*.5,145,width,extent.y-240),e.say("28 VISITS · NO MISSED-DAY PENALTY","28 ZİYARET · KAÇIRILAN GÜN CEZASI YOK"))
	e.text(v,e.say("A visit gift: one company essence. The calendar advances only when you claim; no streak reset.","Ziyaret hediyesi: bir birlik özü. Takvim yalnızca aldığında ilerler; ara verince sıfırlanmaz."),15,T.MUTED)
	var grid=GridContainer.new();grid.columns=7;grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;v.add_child(grid)
	canvas.get_node("EntryTips").hide()
	var claimed=int(e.daily_state.get("claimed",0))%28;var ready=bool(e.daily_state.get("ready",false))
	for day in range(28):
		var cell=PanelContainer.new();cell.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cell.add_theme_stylebox_override("panel",T.skin("pressed" if day==claimed and ready else "disabled" if day>claimed else "button"));grid.add_child(cell)
		var stack=VBoxContainer.new();cell.add_child(stack);var title=e.text(stack,e.say("DAY ","GÜN ")+str(day+1),14,T.GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var icon=TextureRect.new();icon.texture=T.icon("gift");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(0,25)*scale;stack.add_child(icon)
		var caption=e.text(stack,"✓" if day<claimed else e.say("Ready","Hazır") if day==claimed and ready else "1 "+e.say("essence","öz"),13);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	e.button(v,e.say("CLAIM GIFT","HEDİYEYİ AL") if ready else e.say("Next gift after 00:00 UTC","Sonraki hediye 00:00 UTC sonrası"),e.claim_daily,true,"ClaimDaily").disabled=not ready
	var back=Button.new();back.name="CalendarBack";back.text=e.say("← Company","← Birlik");back.position=Vector2(extent.x-230,55)*scale;back.size=Vector2(190,44)*scale;canvas.add_child(back);back.pressed.connect(e.show_character)
