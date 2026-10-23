extends RefCounted
var ui
var game
var net
var generation = 0
var current_code = ""
func _init(interface, owner_game, client) -> void:
	ui=interface; game=owner_game; net=client
func say(en: String, tur: String) -> String: return tur if ui.language=="tr" else en
func screen(title: String):
	generation+=1
	ui.page="online"
	return ui.popup(title)
func still_here(epoch: int) -> bool:
	return epoch==generation and ui.page=="online"
func field(parent, hint: String, value: String = "", secret: bool = false):
	var f=LineEdit.new()
	f.placeholder_text=hint; f.text=value; f.secret=secret
	f.custom_minimum_size=Vector2(0,58); f.max_length=128 if secret else 256
	f.add_theme_font_override("font",ui.ui_font()); f.add_theme_font_size_override("font_size",21)
	parent.add_child(f)
	return f
func action(parent,text: String,callback: Callable,primary: bool = false):
	var b=ui.button(text,callback,primary)
	b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(b)
	return b
func options(parent, names: Array):
	var o=OptionButton.new()
	o.custom_minimum_size.y=56
	o.add_theme_font_override("font",ui.ui_font())
	o.add_theme_font_size_override("font_size",21)
	for name in names:o.add_item(name)
	parent.add_child(o)
	return o
func back(parent): action(parent,ui.t("back"),home)
func message(text: String) -> void:
	var v=screen(say("Online universe","Çevrimiçi evren")); v.add_child(ui.label(text,22)); back(v)
func error(r: Dictionary) -> void:
	message(say("Connection unavailable. Your own planet is safe. Try again when ready.","Bağlantı kurulamıyor. Kendi gezegenin güvende. Hazır olduğunda yeniden dene.") if r.status==0 else say("Not available. Check your login, permissions or wait a moment.","Kullanılamıyor. Girişini, izinlerini kontrol et veya biraz bekle."))
func home() -> void:
	var v=screen(say("Online universe","Çevrimiçi evren"))
	var list=ui.card_list(v,440)
	var emblem=TextureRect.new()
	emblem.texture=load("res://assets/phase2/icons/online.svg")
	emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.custom_minimum_size=Vector2(80,80)
	list.add_child(emblem)
	list.add_child(ui.label(say("Optional worlds, real friendships. Your planet stays offline until you choose to share.","İsteğe bağlı dünyalar, gerçek dostluklar. Paylaşmayı seçene kadar gezegenin cihazında kalır."),21))
	list.add_child(ui.label(say("Connected","Bağlı") if net.connected else say("Offline · local play is ready","Çevrimdışı · yerel oyun hazır"),18,Color("bbd8aa")))
	if net.access.is_empty():
		action(list,say("Sign in / Create identity","Giriş / Kimlik oluştur"),account,true)
	else:
		list.add_child(ui.portrait(int(net.profile.get("avatar",0)),Vector2(120,86)))
		action(list,str(net.profile.get("name","")),profile)
		for entry in [[say("Friends & invitations","Arkadaşlar ve davetler"),friends],[say("Share my planet","Gezegenimi paylaş"),sharing],[say("Discover planets","Gezegenleri keşfet"),discovery],[say("Activity inbox","Etkinlik kutusu"),inbox],[say("Blocked players","Engellenen oyuncular"),blocks]]: action(list,entry[0],entry[1])
	action(list,say("Connection settings","Bağlantı ayarları"),connection)
	action(v,ui.t("back"),func(): ui.menu() if not game.world.is_empty() else ui.main_menu())
func connection() -> void:
	var v=screen(say("Connection settings","Bağlantı ayarları"))
	v.add_child(ui.label(say("Local beta server only. Desktop: 127.0.0.1 · Android emulator: 10.0.2.2. No public hosting is configured.","Yerel beta sunucusu. Masaüstü: 127.0.0.1 · Android emülatör: 10.0.2.2. Genel sunucu yapılandırılmadı."),20))
	var url=field(v,"https://…",net.endpoint)
	action(v,say("Save connection (signs out)","Bağlantıyı kaydet (çıkış yapar)"),func():
		if net.configure(url.text): home()
		else: message(say("HTTPS required; local debug addresses allow HTTP.","HTTPS gerekli; yerel hata ayıklama adresleri HTTP kullanabilir.")),true)
	back(v)
func account() -> void:
	var v=screen(say("Your online identity","Çevrimiçi kimliğin"))
	v.add_child(ui.label(say("Private account name (4–64 letters/numbers). Password: 12–128 characters. Session stays in memory; sign in after restarting. No email recovery in local beta.","Özel hesap adı (4–64 harf/rakam). Parola: 12–128 karakter. Oturum bellekte tutulur; yeniden açınca giriş yap. Yerel betada e-posta kurtarma yok."),19))
	var name=field(v,say("Private account name","Özel hesap adı"))
	var password=field(v,say("Password","Parola"),"",true)
	action(v,say("Sign in","Giriş yap"),func():
		var a=name.text; var p=password.text; password.clear()
		message(say("Connecting…","Bağlanıyor…"))
		var r=await net.login(a,p)
		if r.ok: home()
		else: error(r),true)
	action(v,say("Create identity","Kimlik oluştur"),func():
		var a=name.text;var p=password.text;password.clear()
		message(say("Creating…","Oluşturuluyor…"))
		var r=await net.call_api(HTTPClient.METHOD_POST,"/auth/register",{"account":a,"password":p})
		if r.ok: message(say("Registration processed. Sign in with your private account name.","Kayıt işlendi. Özel hesap adınla giriş yap."))
		else: error(r))
	back(v)
func profile() -> void:
	var v=screen(say("Guardian profile","Koruyucu profili"))
	var list=ui.card_list(v,440)
	list.add_child(ui.portrait(int(net.profile.get("avatar",0)),Vector2(130,90)))
	var name=field(list,say("Public display name","Görünen ad"),net.profile.get("name",""));name.max_length=32
	var species_names: Array=[]
	for i in range(6):species_names.append(ui.species(i))
	var avatar=options(list,species_names)
	avatar.selected=int(net.profile.get("avatar",0))
	var visibility=visibility_field(list,net.profile.get("visibility","private"))
	action(list,say("Save profile","Profili kaydet"),func():
		var data={"name":name.text,"avatar":avatar.selected,"visibility":["private","friends","public"][visibility.selected]}
		var r=await net.call_api(HTTPClient.METHOD_PUT,"/me/profile",data)
		if r.ok: net.profile=r.data;home()
		else:error(r),true)
	list.add_child(ui.label(say("Invitation code: ","Davet kodu: ")+net.profile.get("code",""),17))
	action(list,say("Copy my invitation","Davetimi kopyala"),func(): DisplayServer.clipboard_set(net.profile.get("code","")))
	action(list,say("Log out","Çıkış yap"),func():
		var r=await net.call_api(HTTPClient.METHOD_POST,"/auth/logout")
		net.forget();home())
	action(list,say("Delete account…","Hesabı sil…"),delete_account)
	back(v)
func visibility_field(v,value: String):
	var o=options(v,[say("Private","Özel"),say("Friends only","Yalnızca arkadaşlar"),say("Public discovery","Herkese açık keşif")])
	o.selected=maxi(0,["private","friends","public"].find(value))
	return o
func delete_account() -> void:
	var v=screen(say("Delete online account?","Çevrimiçi hesap silinsin mi?"))
	v.add_child(ui.label(say("Removes the online profile, showcases, friendships and activity. Your local planet is preserved.","Çevrimiçi profil, paylaşımlar, arkadaşlıklar ve etkinlik silinir. Yerel gezegenin korunur."),22))
	action(v,say("Delete my online account","Çevrimiçi hesabımı sil"),func():
		var r=await net.call_api(HTTPClient.METHOD_DELETE,"/me")
		if r.ok: net.forget();home()
		else:error(r))
	back(v)
func sharing() -> void:
	if game.world.is_empty() or game.visiting:message(say("Return to your own planet before sharing.","Paylaşmadan önce kendi gezegenine dön."));return
	var data=game.showcases.project(game.world)
	var v=screen(say("Share a snapshot","Bir görüntü paylaş"))
	var list=ui.card_list(v,360)
	list.add_child(ui.label(ui.profile_summary(data),22))
	list.add_child(ui.label(say("Review visible creature and community names. Only this public snapshot is uploaded; your save stays here. Profile visibility must also allow visitors.","Görünen canlı ve topluluk adlarını gözden geçir. Yalnızca bu görüntü yüklenir; kaydın burada kalır. Profil görünürlüğün de ziyaretçilere izin vermeli."),19))
	var visibility=visibility_field(list,"friends")
	action(v,say("Publish this snapshot","Bu görüntüyü yayımla"),func():
		var r=await net.call_api(HTTPClient.METHOD_PUT,"/planets/showcase",{"snapshot":data,"visibility":["private","friends","public"][visibility.selected]})
		if r.ok:message(say("Snapshot published. Your local simulation continues independently.","Görüntü yayımlandı. Yerel simülasyonun bağımsız sürer."))
		else:error(r),true)
	action(v,say("Unpublish","Yayından kaldır"),func():
		var r=await net.call_api(HTTPClient.METHOD_DELETE,"/planets/showcase")
		if r.ok:message(say("Showcase removed from server.","Gezegen görüntüsü sunucudan kaldırıldı."))
		else:error(r))
	back(v)
func friends(offset: int = 0) -> void:
	var v=screen(say("Friends & invitations","Arkadaşlar ve davetler"));var epoch=generation
	var code=field(v,say("Exact invitation code","Tam davet kodu"));code.max_length=32
	action(v,say("Send friend request","Arkadaşlık isteği gönder"),func():
		if not net.valid_code(code.text):message(say("Use the full invitation code.","Tam davet kodunu kullan."));return
		var r=await net.call_api(HTTPClient.METHOD_POST,"/friends/"+code.text)
		if r.ok:friends()
		else:error(r))
	var list=ui.card_list(v,300);back(v)
	var r=await net.call_api(HTTPClient.METHOD_GET,"/friends?offset="+str(offset))
	if not still_here(epoch) or not is_instance_valid(list):return
	if not r.ok:error(r);return
	if r.data.items.is_empty():list.add_child(ui.label(say("Share your code to meet a friend.","Bir arkadaşla tanışmak için kodunu paylaş."),20))
	for row in r.data.items:
		var p=row.profile;var target=str(p.code)
		list.add_child(ui.portrait(int(p.avatar),Vector2(100,65)))
		action(list,str(p.name)+(" · "+say("Pending","Bekliyor") if row.state=="pending" else ""),func():player(target))
		if row.state=="pending" and row.incoming:action(list,say("Accept invitation","Daveti kabul et"),func():
			var answer=await net.call_api(HTTPClient.METHOD_PUT,"/friends/"+target+"/accept")
			if answer.ok:friends()
			else:error(answer))
		action(list,say("Reject / remove","Reddet / kaldır"),func():await net.call_api(HTTPClient.METHOD_DELETE,"/friends/"+target);friends())
	if r.data.get("next")!=null:action(list,say("More","Diğerleri"),func():friends(int(r.data.next)))
func player(code: String) -> void:
	message(say("Loading profile…","Profil yükleniyor…"))
	var epoch=generation
	var r=await net.call_api(HTTPClient.METHOD_GET,"/players/"+code)
	if not still_here(epoch):return
	if not r.ok:error(r);return
	var p=r.data
	var v=screen(str(p.name));v.add_child(ui.portrait(int(p.avatar),Vector2(140,110)))
	action(v,say("View published planet","Paylaşılan gezegeni gör"),func():snapshot_profile(code),true)
	action(v,say("Block player","Oyuncuyu engelle"),func():
		var result=await net.call_api(HTTPClient.METHOD_PUT,"/blocks/"+code)
		if result.ok:home()
		else:error(result))
	back(v)
func snapshot_profile(code: String) -> void:
	message(say("Loading planet…","Gezegen yükleniyor…"))
	var epoch=generation
	var r=await net.fetch_snapshot(code)
	if not still_here(epoch):return
	if not r.ok:message(say("No accessible published planet. It may be private, removed or unavailable.","Erişilebilir paylaşılan gezegen yok. Özel, kaldırılmış veya ulaşılamıyor olabilir."));return
	var data=r.data.snapshot
	current_code=code
	var v=screen(data.planet.name)
	var list=ui.card_list(v,360)
	list.add_child(ui.label(say("Published snapshot · ","Paylaşılan görüntü · ")+str(r.data.updated).left(19),17))
	list.add_child(ui.label(ui.profile_summary(data),21))
	var art=HBoxContainer.new();art.alignment=BoxContainer.ALIGNMENT_CENTER;list.add_child(art)
	var represented: Array=[]
	for cr in data.creatures:
		if represented.size()<3 and not represented.has(int(cr.species)):
			represented.append(int(cr.species))
			art.add_child(ui.portrait(int(cr.species),Vector2(130,100)))
	action(v,say("Visit planet","Gezegeni ziyaret et"),func():
		if game.visiting:message(say("Return home before another visit.","Başka bir ziyaretten önce evine dön."));return
		# Fetch again at entry so revocations take effect; use the same strict reconstruction path.
		var entry_epoch=generation
		var fresh=await net.fetch_snapshot(code)
		if not still_here(entry_epoch):return
		if fresh.ok and game.visit_planet(fresh.data.snapshot,"online:"+code):await net.call_api(HTTPClient.METHOD_POST,"/visits/"+code)
		else:error(fresh),true)
	var reactions=options(v,[say("Beautiful world","Güzel dünya"),say("Amazing discovery","Harika keşif"),say("Lovely creatures","Sevimli canlılar"),say("Wonderful civilization","Büyüleyici uygarlık")])
	action(v,say("Send friendly reaction","Dostça tepki gönder"),func():
		var result=await net.call_api(HTTPClient.METHOD_PUT,"/reactions/"+code,{"kind":reactions.selected})
		if result.ok:ui.toast(say("Reaction delivered","Tepki iletildi"))
		else:error(result))
	back(v)
func discovery(offset: int = 0) -> void:
	var v=screen(say("Discover planets","Gezegenleri keşfet"));var epoch=generation
	v.add_child(ui.label(say("Sorted by biome variety, rare discoveries and monuments. Only opted-in public planets.","Biyom çeşitliliği, nadir keşif ve anıtlara göre sıralanır. Yalnızca herkese açık paylaşımı seçen gezegenler."),18))
	var list=ui.card_list(v,410);back(v)
	var r=await net.call_api(HTTPClient.METHOD_GET,"/discovery?offset="+str(offset))
	if not still_here(epoch) or not is_instance_valid(list):return
	if not r.ok:error(r);return
	if r.data.items.is_empty():list.add_child(ui.label(say("No public planets yet.","Henüz herkese açık gezegen yok."),22))
	for p in r.data.items:
		var code=str(p.code)
		list.add_child(preload("res://scripts/showcase_preview.gd").new(p.get("preview",[])))
		action(list,str(p.planet)+" · "+str(p.name),func():snapshot_profile(code))
	if r.data.get("next")!=null:action(list,say("More","Diğerleri"),func():discovery(int(r.data.next)))
func inbox(before: int = 9223372036854775807) -> void:
	var v=screen(say("Activity inbox","Etkinlik kutusu"));var epoch=generation
	var list=ui.card_list(v,440);back(v)
	var r=await net.call_api(HTTPClient.METHOD_GET,"/notifications?before="+str(before))
	if not still_here(epoch) or not is_instance_valid(list):return
	if not r.ok:error(r);return
	var names={"friend_request":say("sent an invitation","davet gönderdi"),"friend_accepted":say("accepted your invitation","davetini kabul etti"),"planet_updated":say("shared a planet update","gezegen güncellemesi paylaştı"),"planet_reaction":say("admired your planet","gezegenini beğendi")}
	if r.data.items.is_empty():list.add_child(ui.label(say("A quiet universe. New activity appears here when you open the inbox.","Sakin bir evren. Yeni etkinlikler kutuyu açtığında burada görünür."),22))
	for row in r.data.items:list.add_child(ui.label(str(row.actor)+" · "+names.get(row.kind,"")+"\n"+str(row.created).left(19),19))
	if r.data.get("next")!=null:action(list,say("Older activity","Eski etkinlikler"),func():inbox(int(r.data.next)))
	action(list,say("Mark read","Okundu işaretle"),func():await net.call_api(HTTPClient.METHOD_PUT,"/notifications/read");home())
func blocks() -> void:
	var v=screen(say("Blocked players","Engellenen oyuncular"));var epoch=generation
	var list=ui.card_list(v,420);back(v)
	var r=await net.call_api(HTTPClient.METHOD_GET,"/blocks")
	if not still_here(epoch) or not is_instance_valid(list):return
	if not r.ok:error(r);return
	for p in r.data.items:
		var code=str(p.code)
		action(list,str(p.name)+" · "+say("Unblock","Engeli kaldır"),func():await net.call_api(HTTPClient.METHOD_DELETE,"/blocks/"+code);blocks())
