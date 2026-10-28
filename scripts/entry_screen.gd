extends RefCounted
const ART=preload("res://assets/lobby/kingdom-dawn-v1.png")
const R=preload("res://scripts/rpg_progression.gd")
const T=preload("res://scripts/premium_theme.gd")
var ui
var game
var net
var generation=0
var stage="login"
var realm="hearth"
var selected_class="warrior"
var character={}
var message=""
var form:VBoxContainer
var canvas:Control
var status:Label
var account:LineEdit
var password:LineEdit
var hero_name:LineEdit
var s=1.0
func _init(interface):ui=interface;game=ui.game;net=game.online
func say(en,tr):return tr if ui.language=="tr" else en
func text(parent,value,size=18,color=Color("d3cec1")):
	var l=ui.label(value,maxi(14,roundi(size*s)),color);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(l);return l
func button(parent,title,callback,primary=false,id=""):
	var b=ui.button(title,callback,primary);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size=Vector2(0,maxf(44,46*s));b.add_theme_font_size_override("font_size",maxi(14,roundi(17*s)));b.name=id if not id.is_empty() else title;parent.add_child(b);return b
func field(parent,hint,id,secret=false):
	var f=LineEdit.new();f.placeholder_text=hint;f.name=id;f.secret=secret;f.custom_minimum_size.y=maxf(44,46*s);f.max_length=128 if secret else 64;f.add_theme_font_override("font",ui.ui_font());f.add_theme_font_size_override("font_size",maxi(14,roundi(18*s)));parent.add_child(f);return f
func base(title):
	generation+=1;game.in_menu=true;game.reset_gesture();game.show_world(false);ui.world_controls(false);ui.page="entry";ui.premium.current="entry"
	if is_instance_valid(ui.modal):ui.root.remove_child(ui.modal);ui.modal.queue_free()
	if is_instance_valid(ui.veil):ui.root.remove_child(ui.veil);ui.veil.queue_free();ui.veil=null
	var extent=ui.get_viewport().get_visible_rect().size;s=minf(extent.x/1280.0,extent.y/720.0)
	ui.modal=PanelContainer.new();ui.modal.name="RealmEntry";ui.modal.position=Vector2.ZERO;ui.modal.size=extent;ui.modal.add_theme_stylebox_override("panel",StyleBoxEmpty.new());ui.root.add_child(ui.modal)
	ui.modal_base_y=0
	canvas=Control.new();canvas.custom_minimum_size=extent;ui.modal.add_child(canvas)
	var bg=TextureRect.new();bg.texture=ART;bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;bg.size=extent;bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(bg)
	var title_box=VBoxContainer.new();title_box.position=Vector2(45*s,35*s);title_box.size=Vector2(extent.x*.5,110*s);canvas.add_child(title_box)
	var logo=text(title_box,"LITTLE GOD",47,Color("f5dfae"));logo.add_theme_font_override("font",load("res://assets/phase2/lora.ttf"));logo.add_theme_color_override("font_shadow_color",Color.BLACK);logo.add_theme_constant_override("shadow_offset_y",3)
	text(title_box,"A G E   O F   K I N G D O M S",16,Color("dac5a0"))
	var panel=PanelContainer.new();panel.name="EntryForm";panel.position=Vector2(extent.x-415*s,105*s);panel.size=Vector2(370*s,extent.y-205*s);var box=T.box(Color(.025,.038,.065,.93),true);box.content_margin_left=18*s;box.content_margin_right=18*s;box.content_margin_top=16*s;box.content_margin_bottom=14*s;panel.add_theme_stylebox_override("panel",box);canvas.add_child(panel)
	form=VBoxContainer.new();form.add_theme_constant_override("separation",maxi(5,roundi(10*s)));panel.add_child(form)
	text(form,say("ACCOUNT  ›  REALM  ›  HERO","HESAP  ›  SUNUCU  ›  KAHRAMAN"),12,Color("b9a16e"));text(form,title,27,Color("f1dbac"))
	status=text(form,message,15,Color("deb77c"));status.name="EntryStatus";status.visible=not message.is_empty()
	var tip_panel=PanelContainer.new();tip_panel.position=Vector2(35*s,extent.y-83*s);tip_panel.size=Vector2(extent.x-70*s,58*s);tip_panel.add_theme_stylebox_override("panel",T.box(Color(.025,.035,.055,.88)));canvas.add_child(tip_panel)
	var tips=[say("Your workers keep gathering while you adventure. Collect their cargo when you return.","Sen maceradayken işçilerin çalışır. Döndüğünde yüklerini toplamayı unutma."),say("Watch an enemy's warning, dodge, then strike during its recovery.","Düşmanın uyarısını izle, kaçın ve toparlanırken saldır."),say("In the shared hunting ground, the server calculates damage and earned essence.","Ortak av alanında hasarı ve kazanılan özü sunucu hesaplar.")]
	var tip=text(tip_panel,say("FIELD NOTES  ·  ","YOLCULUK NOTLARI  ·  ")+tips[int(Time.get_unix_time_from_system()/12)%tips.size()],16);tip.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	var language=Button.new();language.text="TR / EN";language.position=Vector2(35*s,extent.y-132*s);language.size=Vector2(100*s,40*s);canvas.add_child(language);language.pressed.connect(func():ui.toggle_language();open())
	if Persistence.has_save(game.save_path) and not game.save_path.begins_with("user://realms/"):
		var legacy=Button.new();legacy.name="ExistingLocalSave";legacy.text=say("Continue device save","Cihazdaki kayda devam");legacy.position=Vector2(150*s,extent.y-132*s);legacy.size=Vector2(220*s,40*s);canvas.add_child(legacy);legacy.pressed.connect(game.restore)
func open():
	stage="login";message="";login_page()
func note(value):
	message=value
	if is_instance_valid(status):status.text=value;status.show()
func login_page():
	stage="login";base(say("Welcome back","Krallığına hoş geldin"))
	account=field(form,say("Account name","Hesap adı"),"AccountName");password=field(form,say("Password","Parola"),"AccountPassword",true)
	button(form,say("SIGN IN","GİRİŞ YAP"),authenticate,true,"EntryLogin")
	button(form,say("Create account","Hesap oluştur"),register_account,false,"EntryRegister")
	button(form,say("Connection","Sunucu bağlantısı"),connection,false,"EntryConnection")
	text(form,say("Your password is never saved on this device.","Parolan bu cihazda saklanmaz."),14)
func authenticate():
	if net.busy:return
	if net.endpoint.is_empty():note(say("Set the server connection first.","Önce sunucu bağlantısını ayarla."));return
	var a=account.text;var p=password.text;password.clear();var epoch=generation;note(say("Signing in…","Giriş yapılıyor…"))
	var result=await net.login(a,p)
	if epoch!=generation:return
	if result.ok:await servers()
	else:note(say("Sign-in failed. Check your account or connection.","Giriş yapılamadı. Hesabını veya bağlantını kontrol et."))
func register_account():
	if net.busy:return
	if net.endpoint.is_empty():note(say("Set the server connection first.","Önce sunucu bağlantısını ayarla."));return
	var a=account.text;var p=password.text;password.clear();var epoch=generation;note(say("Creating account…","Hesap oluşturuluyor…"))
	var result=await net.call_api(HTTPClient.METHOD_POST,"/auth/register",{"account":a,"password":p})
	if epoch!=generation:return
	note(say("Registration processed. Sign in to continue.","Kayıt işlendi. Devam etmek için giriş yap.") if result.ok else say("Use 4–64 account characters and a 12–128 character password.","Hesap adı 4–64, parola 12–128 karakter olmalı."))
func connection():
	base(say("Server connection","Sunucu bağlantısı"));var url=field(form,"https://…","RealmEndpoint");url.text=net.endpoint
	text(form,say("Use the address supplied by the realm operator.","Oyun sunucusu için verilen bağlantı adresini kullan."),16)
	button(form,say("Save address","Adresi kaydet"),func():
		if net.configure(url.text):message="";login_page()
		else:note(say("A valid HTTPS address is required.","Geçerli bir HTTPS adresi gerekli.")),true)
	button(form,say("Back","Geri"),login_page)
func servers():
	stage="servers";message="";base(say("Choose your realm","Sunucunu seç"));var epoch=generation;note(say("Loading realms…","Sunucular alınıyor…"))
	var response=await net.call_api(HTTPClient.METHOD_GET,"/realms")
	if epoch!=generation:return
	if not response.ok:note(say("Realm list unavailable. Try again.","Sunucu listesi alınamadı. Yeniden dene."));button(form,say("Retry","Yeniden dene"),servers);return
	note(say("Choose a realm to see your character.","Karakterini görmek için bir sunucu seç."))
	for row in response.data.get("items",[]):
		var id=str(row.id);var b=button(form,str(row.name)+"\n"+str(int(row.players))+" / "+str(int(row.capacity))+" · "+str(row.status),func():realm=id;await characters(),true,"Realm_"+id);b.disabled=row.status!="online"
	button(form,say("Sign out","Çıkış yap"),func():net.forget();open())
func characters():
	stage="characters";message="";base(say("Your company","Kahraman birliğin"));var epoch=generation;note(say("Loading character…","Karakter alınıyor…"))
	var response=await net.call_api(HTTPClient.METHOD_GET,"/realms/"+realm+"/characters")
	if epoch!=generation:return
	if not response.ok:note(say("Character list unavailable.","Karakter listesi alınamadı."));button(form,say("Back","Geri"),servers);return
	var items=response.data.get("items",[])
	if items.is_empty():create_page();return
	character=items[0];selected_class=character.primaryClass;show_character()
func portrait(key):
	var p=TextureRect.new();p.texture=load("res://assets/rpg/"+key+".png");p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;p.position=Vector2(200*s,190*s);p.size=Vector2(330*s,390*s);p.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(p)
func realm_back():
	var b=Button.new();b.text=say("← Realms","← Sunucular");b.position=Vector2(ui.get_viewport().get_visible_rect().size.x-415*s,55*s);b.size=Vector2(150*s,36);canvas.add_child(b);b.pressed.connect(servers)
func create_page():
	stage="create";message="";base(say("Create your first hero","İlk kahramanını oluştur"));portrait(selected_class)
	hero_name=field(form,say("Hero name · 3–24 characters","Kahraman adı · 3–24 karakter"),"HeroName");hero_name.max_length=24
	var grid=GridContainer.new();grid.columns=2;form.add_child(grid)
	for key in R.CLASSES:
		var cls=key;button(grid,R.NAMES[key],func():var name=hero_name.text;selected_class=cls;create_page();hero_name.text=name,selected_class==key,"FirstClass_"+key)
	text(form,{"warrior":say("Heavy armor · melee and defense","Ağır zırh · yakın saldırı ve savunma"),"priest":say("Sacred magic · healing and protection","Kutsal güç · iyileştirme ve koruma"),"mage":say("Elemental magic · ranged damage","Element büyüsü · menzilli hasar"),"rogue":say("Bow and daggers · speed and precision","Yay ve hançer · hız ve isabet")}[selected_class],16)
	button(form,say("CREATE HERO","KAHRAMANI OLUŞTUR"),create_character,true,"CreateRealmHero");realm_back()
func create_character():
	if net.busy:return
	var name=hero_name.text.strip_edges();var epoch=generation;note(say("Creating hero…","Kahraman oluşturuluyor…"))
	var response=await net.call_api(HTTPClient.METHOD_POST,"/realms/"+realm+"/characters",{"name":name,"class":selected_class})
	if epoch!=generation:return
	if response.ok:character=response.data;show_character()
	else:note(say("Name unavailable or invalid. Use 3–24 letters/numbers.","Ad kullanımda veya geçersiz. 3–24 harf/rakam kullan."))
func show_character():
	stage="characters";message="";base(str(character.name));portrait(character.primaryClass)
	text(form,R.NAMES[character.primaryClass]+" · "+str(int(character.experience))+" XP",22,Color("f1dbac"));text(form,say("Company essence: ","Birlik özü: ")+str(int(character.essence))+say(" · Hunts: "," · Av: ")+str(int(character.hunts)),16)
	button(form,say("ENTER SHARED HUNT","ORTAK AVA KATIL"),join_shared,true,"JoinSharedHunt")
	button(form,say("My city","Şehrime git"),enter_city,false,"EnterRealmCity")
	var company=GridContainer.new();company.columns=2;form.add_child(company)
	for key in R.CLASSES:
		if key==character.primaryClass:continue
		var cls=key;var unlocked=key in character.unlocked;var b=button(company,R.NAMES[key]+(" · "+say("Choose","Seç") if unlocked else " · 3 av / 3 öz"),func():await recruit_or_select(cls,unlocked),false,"Company_"+key);b.disabled=not unlocked and (character.hunts<3 or character.essence<3)
	realm_back()
func recruit_or_select(key,unlocked):
	var path="select-class" if unlocked else "recruit";var epoch=generation
	var response=await net.call_api(HTTPClient.METHOD_POST,"/realms/"+realm+"/characters/"+character.id+"/"+path,{"class":key})
	if epoch!=generation:return
	if response.ok:character=response.data;show_character()
	else:note(say("Cannot change company now. Leave combat or check your essence.","Birlik şu anda değiştirilemez. Savaştan ayrıl veya özünü kontrol et."))
func prepare_city()->bool:
	var code=str(net.profile.get("code",""))
	if not load("res://scripts/realm_roster.gd").valid_code(code):note(say("Sign in again.","Yeniden giriş yap."));return false
	DirAccess.make_dir_recursive_absolute("user://realms");game.save_path="user://realms/"+code+"-"+str(character.id)+".json"
	if Persistence.has_save(game.save_path):
		var existing=Persistence.load_world(game.save_path)
		if existing.is_empty():note(say("City save could not be read. Your file was preserved.","Şehir kaydı okunamadı. Dosyan korundu."));return false
		await game.restore()
		if is_instance_valid(game.adventure_scene):game.adventure_scene.go_home()
		if is_instance_valid(game.army_scene):note(say("Finish your current army mission before joining a shared hunt.","Ortak ava katılmadan önce mevcut birlik görevini bitir."));return false
	else:
		game.new_planet(int(character.seed),str(character.name),true);R.switch(game.world,character.primaryClass);game.world.kingdom.adventure.hero.name=character.name
	if not load("res://scripts/realm_roster.gd").apply(game.world,character):return false
	R.switch(game.world,character.primaryClass);game.world.kingdom.adventure.hero.name=character.name;game.checkpoint("realm-city-entry");return true
func enter_city():
	if await prepare_city():ui.close();game.show_world(true)
func join_shared():
	if not await prepare_city():return
	base(say("Joining shared hunt","Ortak ava katıl"));var epoch=generation;note(say("Joining shared hunting ground…","Ortak av alanına bağlanılıyor…"))
	var response=await net.call_api(HTTPClient.METHOD_POST,"/realms/"+realm+"/characters/"+character.id+"/enter")
	if epoch!=generation:return
	if not response.ok:note(say("The realm is unavailable or full. Try again.","Sunucu kullanılamıyor veya dolu. Yeniden dene."));return
	ui.close();game.show_world(false);var scene=load("res://scripts/shared_hunt.gd").new();scene.game=game;scene.character=character;scene.ticket=response.data.ticket;game.add_child(scene)
