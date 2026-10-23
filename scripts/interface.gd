extends CanvasLayer

var game: Node
var root: Control
var header: Label
var stats: Label
var hint: Label
var power_buttons: Array = []
var power_icons: Array = []
var modal: PanelContainer
var language = "en"
var spirit: Label
var veil: ColorRect
var body_font: FontVariation
var chapter: Button
var speed_button: Button
var page = "main"
var loading_bar: ProgressBar
var realm_bar: Button
var toast_until = 0
var modal_base_y = 254.0

func ui_font() -> Font:
	if body_font == null:
		body_font = FontVariation.new()
		body_font.base_font = load("res://assets/phase2/nunito.ttf")
		body_font.variation_opentype = {"wght": 550.0}
	return body_font

const TEXT = {
"guardian_victory": ["Thornheart's roots release the Wildwood. Your champion brought its living heart home.", "Thornheart'ın kökleri Yabanorman'ı serbest bıraktı. Şampiyonun onun yaşayan kalbini eve getirdi."],
"local_universe": ["Local universe", "Yerel evren"],
"universe_body": ["Visit shared snapshots on this device. No accounts or live connection.", "Bu cihazdaki paylaşılan görüntüleri ziyaret et. Hesap veya canlı bağlantı yok."],
"my_profile": ["Planet profile", "Gezegen profili"],
"import_planet": ["Import a shared planet", "Paylaşılan gezegeni içe aktar"],
"export_planet": ["Export planet data", "Gezegen verisini aktar"],
"share_notice": ["Includes visible planet, creature and community names. Review them before sharing. Saves, seed, device data and private paths are excluded.", "Görünen gezegen, canlı ve topluluk isimlerini içerir. Paylaşmadan önce kontrol et. Kayıt, tohum, cihaz verisi ve özel yollar içermez."],
"snapshot_notice": ["A read-only snapshot · the original planet is never changed", "Salt okunur bir görüntü · asıl gezegen değişmez"],
"visit_planet": ["Visit this planet", "Bu gezegeni ziyaret et"],
"leave_visit": ["Return to my world", "Kendi dünyama dön"],
"visiting": ["Visiting · read only", "Ziyaret · salt okunur"],
"readonly_tag": ["Read only", "Salt okunur"],
"remove_copy": ["Remove local copy", "Yerel kopyayı kaldır"],
"landmarks_count": ["%d community landmarks", "%d topluluk simgesi"],
"visit_profile": ["Planet profile & local reaction", "Gezegen profili ve yerel tepki"],
"visit_menu": ["A little visit", "Küçük bir ziyaret"],
"profile_stats": ["Day %d · %d creatures · %d people\n%d communities · %d environments", "Gün %d · %d canlı · %d insan\n%d topluluk · %d yaşam alanı"],
"profile_discoveries": ["%d / 6 species · %d / 3 rare discoveries", "%d / 6 tür · %d / 3 nadir keşif"],
"local_reaction": ["My reaction (only on this device): %s", "Tepkim (yalnızca bu cihazda): %s"],
"reactions": ["None · Wonder · Cozy · Inspiring", "Yok · Büyüleyici · Huzurlu · İlham verici"],
"compare": ["%d species shared with my world · %d new to me", "Dünyamla ortak %d tür · benim için yeni %d tür"],
"copy_summary": ["Copy this planet summary", "Gezegen özetini kopyala"],
"import_failed": ["This planet could not be imported. Use a supported LittleGod showcase, up to 512 KB. Your world is unchanged.", "Gezegen içe aktarılamadı. En çok 512 KB olan desteklenen LittleGod paylaşımını kullan. Dünyan değişmedi."],
"export_ok": ["Showcase saved. Share the file only if you choose.", "Gezegen paylaşımı kaydedildi. Dosyayı yalnızca istersen paylaş."],
"file_failed": ["The file could not be saved. Choose another location.", "Dosya kaydedilemedi. Başka bir konum seç."],
"library_full": ["This device keeps up to eight shared planets.", "Bu cihaz en çok sekiz paylaşılan gezegen saklar."],
"wonders": ["Wonders to look for", "Aranacak harikalar"],
"wonders_body": ["Whenever you return, look for a living story. There is no deadline or missed-day penalty.", "Her dönüşünde yaşayan bir hikâye ara. Son tarih veya kaçırılan gün cezası yok."],
"seek_migrant": ["Nourish a wetland · birds may arrive when it thrives", "Sulak alanı besle · geliştiğinde kuşlar gelebilir"],
"seek_canopy": ["Follow a gardener · lush, wet forest can form a canopy arch", "Bahçıvanı izle · gür ve nemli ormanda yaprak kemeri oluşabilir"],
"seek_trade": ["Care for communities · allies share food when one needs it", "Toplulukları gözet · dostlar ihtiyaç halinde besin paylaşır"],
"canopy_arch": ["%s nurtured a canopy arch. Its shelter conserves forest moisture.", "%s yaprak kemerini büyüttü. Gölgesi ormanın nemini koruyor."],
"reed_shelter": ["%s made reed shelter. Mossbuns forage safely beside wetland birds.", "%s saz sığınağı oluşturdu. Yosunponlar sulak alan kuşlarıyla güvenle besleniyor."],
"migration": ["%s arrived in a thriving wetland. A new neighbor to meet!", "%s gelişen sulak alana geldi. Tanışılacak yeni bir komşu!"],
"trade": ["%s shared a harvest. Surplus food reached the community that needed it.", "%s hasat paylaştı. Artan besin ihtiyacı olan topluluğa ulaştı."],
"boundary": ["%s compete over depleted land. Restoring resources can ease the tension.", "%s tükenen toprak için yarışıyor. Kaynakları yenilemek gerilimi azaltabilir."],
"cooperation": ["%s found common ground after resources recovered.", "%s kaynaklar yenilenince uzlaştı."],
"favorite_creature": ["Favorite / unfavorite this creature", "Canlıyı favorilere ekle / çıkar"],
"collection": ["Creature collection", "Canlı koleksiyonu"],
"biography": ["First recorded on day %d · family group %d\nOrigin: %s · %s", "İlk kayıt günü %d · aile grubu %d\nKöken: %s · %s"],
"founder": ["An early resident", "İlk sakinlerden"],
"child_of": ["Child of %s", "%s adlı canlının yavrusu"],
"migrant_bio": ["Arrived from beyond your shores", "Kıyılarının ötesinden geldi"],
"departed": ["Remembered neighbor · %s", "Hatırlanan komşu · %s"],
"remove_favorite": ["Unfavorite %s", "%s favoriden çıkar"],
"places_found": ["Places discovered: %d", "Keşfedilen yer: %d"],
"closer": ["Look closer", "Yakından bak"],
"chronicle": ["Planet Chronicle", "Gezegen Günlüğü"],
"memory_body": ["Recorded moments · tap to revisit their place", "Kaydedilen anlar · yerini görmek için dokun"],
"first_birth": ["%s was the first new life recorded here.", "%s burada kaydedilen ilk yeni yaşam oldu."],
"companions": ["%s forage together. Companionship eases hunger.", "%s birlikte besin arıyor. Dostluk açlığı azaltıyor."],
"rivalry": ["%s crossed paths. The hungry mossbun now avoids its rival.", "%s karşılaştı. Aç yosunpon artık rakibinden kaçınıyor."],
"explored": ["%s explored eight places. A little trailblazer!", "%s sekiz yer keşfetti. Küçük bir öncü!"],
"elder": ["%s has lived through 450 recorded world ticks.", "%s kaydedilen 450 dünya adımını yaşadı."],
"landmark": ["%s raised a cultural landmark. Its tradition now helps the land.", "%s kültür anıtını kurdu. Geleneği artık toprağa yardım ediyor."],
"alliance": ["%s formed a learning alliance.", "%s öğrenme birliği kurdu."],
"rescue": ["%s recovered after a long dry spell. Its harvest is renewed.", "%s uzun kuraklıktan kurtuldu. Hasadı yenilendi."],
"mountain_spring": ["A raised mountain and a wet forest awakened a spring. Nearby forest stays moist.", "Yükseltilen dağ ve nemli orman bir pınar uyandırdı. Yakın orman nemli kalıyor."],
"silver_fox": ["%s became a silver guardian after thriving in its forest. Its grove grows greener.", "%s ormanında gelişip gümüş koruyucu oldu. Korusu yeşeriyor."],
"rainbow_choir": ["%s sang after the rain cleared. The wetland bloomed beneath a rainbow.", "%s yağmur dindikten sonra şarkı söyledi. Sulak alan gökkuşağının altında çiçeklendi."],
"secrets_hint": ["Secrets to seek: raise a mountain beside a wet forest; nurture a patient fox through several lantern nights; watch a wetland bird after rain clears.", "Sırlar: nemli orman yanında dağ yükselt; sabırlı tilkiyi birkaç ışıklı gece boyunca besle; yağmur sonrası sulak alan kuşunu izle."],
"rename": ["Give a name", "Bir isim ver"],
"favorite": ["Mark / unmark this place · up to 5", "Burayı işaretle / kaldır · en çok 5"],
"favorites": ["Favorite places", "Sevilen yerler"],
"personal_story": ["Recorded %d ticks · %d places explored\nPreferred habitat: %s", "%d adım kaydedildi · %d yer keşfedildi\nSevdiği yaşam alanı: %s"],
"bonds": ["Companion: %s · rival: %s", "Dost: %s · rakip: %s"],
"showcase": ["Create a planet postcard", "Gezegen kartpostalı oluştur"],
"postcard": ["Your planet postcard", "Gezegen kartpostalın"],
"export_png": ["Save PNG to a chosen location", "PNG dosyasını seçtiğin yere kaydet"],
"postcard_body": ["Only this picture is exported. No save files or diagnostics. Sharing is your choice.", "Yalnızca bu resim aktarılır. Kayıt veya tanılama içermez. Paylaşmak senin seçimin."],
"image_saved": ["Picture saved.", "Resim kaydedildi."],
"image_failed": ["Could not save the picture. Choose another location.", "Resim kaydedilemedi. Başka bir konum seç."],
"memories_count": ["%d memories", "%d anı"],
"one_memory": ["1 memory", "1 anı"],
"recent_activity": ["Recent world activity", "Son dünya hareketleri"],
"community_story": ["%d recorded ticks · %d allied communities", "%d kayıtlı adım · %d dost topluluk"],
"away_minutes": ["%d minutes away · your world grew gently", "%d dakika sonra · dünyan sakince büyüdü"],
"away_hours": ["%d hours away · your world grew gently", "%d saat sonra · dünyan sakince büyüdü"],
"away_days": ["%d days away · welcome back to your world", "%d gün sonra · dünyana yeniden hoş geldin"],
"loading": ["Your world is waking", "Dünyan uyanıyor"],
"loading_body": ["Remembering the changes in your world…", "Dünyandaki değişimler hatırlanıyor…"],
"recovered": ["Your planet was recovered from a safe local copy.", "Gezegenin güvenli bir yerel kopyadan kurtarıldı."],
"beta": ["Beta tools & privacy", "Beta araçları ve gizlilik"],
"privacy": ["Diagnostics stay on this device. No names or identifiers. Nothing is uploaded.", "Tanılama bu cihazda kalır. İsim veya kimlik bilgisi içermez. Hiçbir şey yüklenmez."],
"diagnostics": ["Local diagnostics: %s", "Yerel tanılama: %s"],
"export": ["Preview optional feedback export", "İsteğe bağlı geri bildirim dışa aktarımını gör"],
"clear_data": ["Clear diagnostic data", "Tanılama verilerini temizle"],
"cleared": ["Diagnostic data cleared. Your planet is unchanged.", "Tanılama temizlendi. Gezegenin değişmedi."],
"copy": ["Copy anonymized feedback", "Anonim geri bildirimi kopyala"],
"copied": ["Feedback copied. Share it only if you choose.", "Geri bildirim kopyalandı. Yalnızca istersen paylaş."],
"pulse": ["Explore your world", "Dünyanı keşfet"],
"visit": ["Visit %s · %d people", "%s yerleşimini ziyaret et · %d kişi"],
"care": ["Care for dry land · %d%% moisture", "Kuru toprağı besle · %d%% nem"],
"grow_habitat": ["Grow a forest · shape a habitat", "Orman büyüt · bir yaşam alanı oluştur"],
"watch": ["Meet %s · watch its habits", "%s ile tanış · davranışlarını izle"],
"pulse_body": ["A little observation. A thoughtful gift. A new story.", "Biraz gözlem. Düşünceli bir armağan. Yeni bir hikâye."],
"habitat_full": ["Wildlife habitat is full. Meet your existing neighbors.", "Canlıların yaşam alanı dolu. Mevcut komşularınla tanış."],
"return_growth": ["%d new chapters · %+d creatures · %+d people\n%d new communities", "%d yeni bölüm · %+d canlı · %+d insan\n%d yeni topluluk"],
"guide_world": ["Your world has stories → explore", "Dünyanın hikâyeleri var → keşfet"],
"neighbors": ["My neighbors", "Komşularım"],
"orchard": ["Orchard keepers · cultivate the home meadow", "Bahçeciler · yuvalarındaki çayırı büyütür"],
"riverfolk": ["Riverfolk · gather more food in the rain", "Nehir halkı · yağmurda daha çok besin toplar"],
"stargazers": ["Stargazers · learn faster under clear skies", "Yıldız gözlemcileri · açık gökte daha hızlı öğrenir"],
"guide_rain": ["Wake the meadow · tap to begin", "Çayırı uyandır · başlamak için dokun"],
"guide_creature": ["2 · Meet a little neighbor → tap to find one", "2 · Küçük bir komşuyla tanış → bulmak için dokun"],
"guide_bloom": ["Follow the rain → discover a desert bloom", "Yağmuru izle → çöldeki çiçeklenmeyi keşfet"],
"guide_friend": ["A friendship → bring wildlife beside the camp", "Bir dostluk → obanın yanına canlı getir"],
"guide_village": ["Help a village grow → bless its home", "Köyü büyüt → yuvasını kutsa"],
"guide_grove": ["Seek lanterns → a happy fox in a lush forest", "Işıkları ara → gür ormanda mutlu bir tilki"],
"rain_bloom": ["Rain awakened a desert meadow. New grazing land!", "Yağmur çölde bir çayır uyandırdı. Yeni otlak!"],
"friendship": ["%s became friends. Shared foraging feeds the community.", "%s dost oldu. Birlikte besin toplayıp obayı besliyorlar."],
"lantern_grove": ["%s lit a lantern grove. The forest gained resources.", "%s ışıklı koruyu aydınlattı. Orman kaynak kazandı."],
"first_village": ["%s grew into a village, with more homes and walkers.", "%s köye dönüştü; evler ve gezinen insanlar çoğaldı."],
"gardener": ["Gardener · restores plants wherever it wanders", "Bahçıvan · gezdiği yerde bitkileri büyütür"],
"friendly": ["Friendly · shares food when visiting communities", "Dost canlısı · yerleşimleri ziyaret edip besin paylaşır"],
"explorer": ["Explorer · wanders beyond its native biome", "Kâşif · doğal yaşam alanının dışını keşfeder"],
"patient": ["Patient · needs less food to stay content", "Sabırlı · mutlu kalmak için daha az besin gerekir"],
"chapters": ["Living chapters", "Yaşayan bölümler"],
"chapter_progress": ["%d / 4 living chapters · %d neighbors met", "%d / 4 yaşayan bölüm · %d komşuyla tanışıldı"],
"universe": ["YOUR LIVING UNIVERSE", "SENİN YAŞAYAN EVRENİN"],
"welcome": ["A small world. Endless wonder.", "Küçük bir dünya. Sonsuz merak."],
"new": ["Create a planet", "Gezegen yarat"], "continue": ["Return to my world", "Dünyama dön"],
"name": ["Name your planet", "Gezegenine isim ver"], "seed": ["World seed (optional)", "Dünya tohumu (isteğe bağlı)"],
"create": ["Let there be life", "Hayat başlasın"], "close": ["Back to the planet", "Gezegene dön"],
"water": ["Water", "Su"], "forest": ["Forest", "Orman"], "mountain": ["Mountain", "Dağ"],
"wildlife": ["Wildlife", "Canlılar"], "rain_power": ["Rain", "Yağmur"], "bless": ["Bless", "Kutsa"],
"journal": ["Discoveries", "Keşifler"], "history": ["World history", "Dünya tarihi"],
"achievements": ["Milestones", "Dönüm noktaları"], "settings": ["Settings", "Ayarlar"],
"save": ["Save planet", "Gezegeni kaydet"], "load": ["Restore saved planet", "Kaydı yükle"],
"saved": ["Your world is safely saved.", "Dünyan güvenle kaydedildi."], "save_failed": ["Save failed. Your previous save is preserved.", "Kayıt başarısız. Önceki kaydın korundu."],
"hint": ["Drag to explore · Pinch or scroll to zoom\nChoose a gift, then touch your world", "Sürükle ve keşfet · Yakınlaşmak için kıstır\nBir armağan seç ve dünyana dokun"],
"gift": ["GIFTS OF THE GUARDIAN", "KORUYUCUNUN ARMAĞANLARI"],
"select": ["Touch a tile to use %s", "%s kullanmak için bir alana dokun"],
"failed": ["Need more spirit, or touch a settlement to bless it.", "Ruh gücü yetersiz veya kutsamak için bir yerleşime dokun."],
"away": ["While you were away", "Sen yokken"], "away_body": ["%d minutes passed. Your world grew gently.", "%d dakika geçti. Dünyan sakince büyüdü."],
"quiet": ["A peaceful chapter. Life is finding its rhythm.", "Huzurlu bir dönem. Hayat ritmini buluyor."],
"rain": ["Soft rain nourished the land.", "Yumuşak yağmur toprağı besledi."],
"drought": ["A dry wind reduced soil moisture.", "Kuru rüzgâr toprağın nemini azalttı."],
"discovery": ["A new species was discovered: %s", "Yeni bir tür keşfedildi: %s"],
"birth": ["A new %s joined the world.", "Dünyaya yeni bir %s katıldı."],
"cycle": ["A life returned to the earth.", "Bir yaşam toprağa döndü."],
"aurora": ["An aurora danced above your planet.", "Gezegenin üzerinde kutup ışıkları dans etti."],
"founded": ["A new community made a home here.", "Yeni bir topluluk burayı yuva edindi."],
"settlement": ["A community reached a new stage: %s", "Bir topluluk yeni bir aşamaya ulaştı: %s"],
"power": ["Your gift changed the world: %s", "Armağanın dünyayı değiştirdi: %s"],
"sanctuary": ["Living sanctuary · nurture 24 creatures", "Yaşayan sığınak · 24 canlıyı yaşat"],
"season": ["A turning world · witness a new season", "Dönen dünya · yeni bir mevsim gör"],
"locked": ["Keep nurturing life to reveal this chapter.", "Bu bölümü keşfetmek için hayatı destekle."],
"sound": ["Toggle sound", "Sesi aç / kapat"], "theme": ["Aurora sky · unlock at level 2", "Kutup ışığı göğü · 2. seviyede açılır"],
"menu": ["Planet menu", "Gezegen menüsü"], "pause": ["Pause / resume", "Duraklat / sürdür"],
"speed": ["Time: %s", "Zaman: %s"], "level": ["LEVEL %d", "SEVİYE %d"],
"day": ["Day %d", "Gün %d"], "population": ["%d creatures · %d people", "%d canlı · %d insan"],
"inspect": ["%s\nMoisture %d%% · Plants %d%%", "%s\nNem %d%% · Bitkiler %d%%"],
"creature_info": ["%s · hunger %d%%\nHabitat: %s", "%s · açlık %d%%\nYaşam alanı: %s"],
"settlement_info": ["%s · %d people\nFood %d · Technology %.1f", "%s · %d kişi\nBesin %d · Teknoloji %.1f"],
"unknown": ["Undiscovered", "Keşfedilmedi"], "habitat": ["Habitat: %s · feeds on local resources", "Yaşam alanı: %s · yerel kaynaklarla beslenir"],
"back": ["Back", "Geri"], "reset": ["Center planet", "Gezegeni ortala"], "replace": ["A new world replaces your current save.", "Yeni dünya mevcut kaydının yerini alır."],
"load_failed": ["No valid save found.", "Geçerli kayıt bulunamadı."], "spirit": ["SPIRIT", "RUH GÜCÜ"],
"quality": ["Performance: %s", "Performans: %s"], "smooth": ["Smooth · 60 FPS", "Akıcı · 60 FPS"], "economy": ["Battery saver · 30 FPS", "Pil tasarrufu · 30 FPS"],
"haptics": ["Toggle touch vibration", "Dokunma titreşimini aç / kapat"],
"hint_short": ["A little care changes everything.", "Biraz özen her şeyi değiştirir."],
"audio": ["Sound", "Ses"], "vibration": ["Touch vibration", "Dokunma titreşimi"], "on": ["On", "Açık"], "off": ["Off", "Kapalı"], "paused": ["Paused", "Duraklatıldı"]
}
const POWER_KEYS = ["water", "forest", "mountain", "wildlife", "rain_power", "bless"]
const SYMBOLS = ["≈", "♧", "△", "◇", "☂", "✧"]

func t(key: String) -> String:
	return TEXT.get(key, [key, key])[1 if language == "tr" else 0]

func species(s: int) -> String:
	return Ecosystem.SPECIES_TR[s] if language == "tr" else Ecosystem.SPECIES[s]

func stages() -> Array:
	return ["Oba", "Köy", "Kasaba"] if language == "tr" else ["Camp", "Village", "Town"]

func seasons() -> Array:
	return ["İlkbahar", "Yaz", "Sonbahar", "Kış"] if language == "tr" else ["Spring", "Summer", "Autumn", "Winter"]

func style(color: Color, radius: int = 20) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.66, 0.83, 0.72, 0.15)
	s.shadow_color = Color(0, .04, .05, .18)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func label(text: String, size: int = 22, color: Color = Color("e5efdc")) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_font_override("font", ui_font())
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func button(text: String, action: Callable, primary: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 66)
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_font_override("font", ui_font())
	b.add_theme_color_override("font_color", Color("102d33") if primary else Color("e1ead7"))
	b.add_theme_stylebox_override("normal", style(Color("bbd8aa") if primary else Color("203d46")))
	b.add_theme_stylebox_override("hover", style(Color("d3e5bd") if primary else Color("325653")))
	b.add_theme_stylebox_override("pressed", style(Color("e5c88d")))
	b.pressed.connect(func(): game.audio.button_sound(); action.call())
	return b

func place(control: Control, rect: Rect2) -> void:
	root.add_child(control)
	var extra = maxf(0, get_viewport().get_visible_rect().size.y - 1280)
	if rect.position.y >= 800: rect.position.y += extra
	control.position = rect.position
	control.size = rect.size

func build() -> void:
	if root:
		remove_child(root)
		root.queue_free()
	modal = null
	veil = null
	root = Control.new()
	root.name = "HUD"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var safe_top = 0.0
	if OS.has_feature("mobile"):
		var safe = DisplayServer.get_display_safe_area()
		var screen = DisplayServer.screen_get_size()
		if screen.x > 0: safe_top = clampf(safe.position.y * 720.0 / screen.x, 0, 55)
	var brand = label("L I T T L E G O D", 17, Color("a9c9b7"))
	place(brand, Rect2(120, 36 + safe_top, 480, 30))
	header = label("", 47, Color("f0e7cd"))
	header.add_theme_font_override("font", load("res://assets/phase2/lora.ttf"))
	place(header, Rect2(100, 76 + safe_top, 520, 75))
	stats = label("", 18, Color("a9c5b9"))
	place(stats, Rect2(80, 156 + safe_top, 560, 60))
	place(icon_button("menu", menu), Rect2(30, 60 + safe_top, 58, 58))
	spirit = label("", 19, Color("eddb9e"))
	place(spirit, Rect2(520, 232 + safe_top, 170, 40))
	chapter = button("", follow_chapter)
	chapter.name = "Chapter"
	chapter.add_theme_font_size_override("font_size", 18)
	chapter.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	place(chapter, Rect2(30, 235 + safe_top, 475, 76))
	realm_bar=button("",func():game.realm_ui.open());realm_bar.name="Kingdom";realm_bar.add_theme_font_size_override("font_size",17)
	place(realm_bar,Rect2(30,324+safe_top,660,64))
	place(icon_button("minus", func(): game.view.zoom_at(game.view.origin, .88)), Rect2(30, 838, 58, 58))
	place(icon_button("plus", func(): game.view.zoom_at(game.view.origin, 1.12)), Rect2(98, 838, 58, 58))
	place(icon_button("center", func(): game.view.pan = Vector2.ZERO; game.view.zoom = .88), Rect2(166, 838, 58, 58))
	var details = button(t("closer"), inspect_selected)
	details.name = "Details"
	place(details, Rect2(238, 838, 299, 58))
	speed_button = button("1×", func(): game.speed = 3 if game.speed == 1 else 1; refresh())
	speed_button.name = "Speed"
	place(speed_button, Rect2(553, 838, 137, 58))
	hint = label(t("hint_short"), 21, Color("cad9c4"))
	place(hint, Rect2(44, 930, 632, 78))
	place(label(t("gift"), 15, Color("a9bda8")), Rect2(40, 1046, 640, 25))
	power_buttons.clear()
	power_icons.clear()
	for i in range(6):
		var b = button(t(POWER_KEYS[i]), func(): choose_power(i))
		b.name = "Power" + str(i)
		b.add_theme_font_size_override("font_size", 16)
		var normal = style(Color("1b353b"), 22)
		normal.content_margin_top = 57
		normal.content_margin_left = 2
		normal.content_margin_right = 2
		normal.content_margin_bottom = 8
		b.add_theme_stylebox_override("normal", normal)
		place(b, Rect2(27 + i * 112, 1092, 105, 104))
		var icon = TextureRect.new()
		icon.texture = load("res://assets/phase2/icons/" + POWER_KEYS[i] + ".svg")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# A sibling stays above the button's redraw when selection changes its style.
		place(icon, Rect2(62 + i * 112, 1106, 35, 35))
		power_icons.append(icon)
		var cost = label(str(Powers.COSTS[i]), 12, Color("a6bd9e"))
		cost.position = Vector2(73, 8)
		cost.size = Vector2(23, 20)
		b.add_child(cost)
		power_buttons.append(b)
	place(label(t("universe"), 12, Color("6d938b")), Rect2(50, 1225, 620, 25))
	refresh()
	root.modulate.a = 0
	create_tween().tween_property(root, "modulate:a", 1.0, .25)

func icon_button(key: String, action: Callable) -> Button:
	var b = button("", action)
	b.tooltip_text = t(key) if TEXT.has(key) else key
	b.name = key.capitalize()
	b.icon = load("res://assets/phase2/icons/" + key + ".svg")
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_constant_override("icon_max_width", 28)
	for state in ["normal", "hover", "pressed"]:
		var box = b.get_theme_stylebox(state).duplicate()
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		b.add_theme_stylebox_override(state, box)
	return b

func choose_power(i: int) -> void:
	if game.visiting: game.power = -1; toast(t("snapshot_notice")); return
	toast_until = 0
	game.power = -1 if game.power == i or i < 0 else i
	hint.text = t("hint_short") if game.power == -1 else t("select") % t(POWER_KEYS[i])
	for n in range(6):
		var s = power_buttons[n].get_theme_stylebox("normal").duplicate()
		s.bg_color = Color("4d6550") if n == game.power else Color("1b353b")
		s.border_color = Color("c9d6a0") if n == game.power else Color(.66, .83, .72, .15)
		power_buttons[n].add_theme_stylebox_override("normal", s)

func refresh() -> void:
	if not header or game.world.is_empty(): return
	var w = game.world
	header.text = w.name
	var title_width=header.get_theme_font("font").get_string_size(w.name,HORIZONTAL_ALIGNMENT_LEFT,-1,47).x
	header.add_theme_font_size_override("font_size",clampi(int(47*minf(1,header.size.x/maxf(1,title_width))),14,47))
	var people = 0
	for s in w.settlements: people += int(s.population)
	stats.text = (t("day") % (1 + int(w.tick) / 30)) + "  ·  " + seasons()[(int(w.tick) / 120) % 4] + "  ·  " + (t("level") % (1 + int(w.xp) / 40)) + "\n" + t("population") % [w.creatures.size(), people]
	if game.paused: stats.text += "  ·  " + t("paused")
	spirit.text = "✧  " + str(int(w.energy)) + "  " + t("spirit")
	if chapter: chapter.text = t(LivingStories.objective(w))
	if realm_bar:
		realm_bar.visible=not game.in_menu and not game.visiting and game.has_player_world
		realm_bar.text=game.realm_ui.resources() if w.has("kingdom") else ("İlk Krallık · Bilge Arin ile tanış" if language=="tr" else "First Kingdom · meet Elder Arin")
	if w.has("kingdom") and not game.visiting:
		var K=preload("res://scripts/kingdom.gd");var quest=K.current(w)
		chapter.text=("Diyar " if language=="tr" else "Realm ")+str(K.level(w))+" · "+(game.realm_ui.localized(quest.title) if not quest.is_empty() else ("İlk Alev tamamlandı" if language=="tr" else "First Flame complete"))
		stats.text=(t("day")%(1+int(w.tick)/30))+" · "+("Diyar " if language=="tr" else "Realm ")+str(K.level(w))+" · "+t("population")%[w.creatures.size(),people]
	if speed_button: speed_button.text = str(game.speed) + "×"
	if game.visiting:
		stats.text = t("visiting") + "\n" + t("population") % [w.creatures.size(), people]
		spirit.text = "◇ " + t("readonly_tag")
		chapter.text = t("visit_profile")
		if game.visited_id.begins_with("online:"): chapter.text="Paylaşılan görüntü ve tepkiler" if language=="tr" else "Published snapshot & reactions"
		speed_button.visible = false
		var extra = maxf(0,get_viewport().get_visible_rect().size.y-1280)
		for child in root.get_children():
			if child is Control and child.position.y >= 1046+extra: child.visible = false
	# Repaint retained SVG commands after power styles and modal visibility change.
	for icon in power_icons:
		if icon.visible: icon.queue_redraw()

func popup(title: String) -> VBoxContainer:
	end_live_route()
	game.reset_gesture()
	game.in_menu = true
	world_controls(false)
	if modal: modal.queue_free()
	if not is_instance_valid(veil):
		veil = ColorRect.new()
		veil.color = Color(.01, .04, .05, .35)
		place(veil, Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size))
	modal = PanelContainer.new()
	modal.add_theme_stylebox_override("panel", style(Color("173239"), 28))
	place(modal, Rect2(34, 254 + maxf(0, get_viewport().get_visible_rect().size.y - 1280) * .5, 652, 710))
	modal_base_y = modal.position.y
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	modal.add_child(v)
	var heading = label(title, 31, Color("ecdfb8"))
	heading.add_theme_font_override("font", load("res://assets/phase2/lora.ttf"))
	v.add_child(heading)
	modal.modulate.a = 0
	create_tween().tween_property(modal, "modulate:a", 1.0, .18)
	return v

func end_live_route() -> void:
	if game.trade_ui!=null and game.trade_ui.watching:
		game.trade_ui.watching=false
		game.show_world(true)

func close() -> void:
	end_live_route()
	if modal: modal.queue_free(); modal = null
	if is_instance_valid(veil): veil.queue_free(); veil = null
	game.in_menu = false
	world_controls(true)
	refresh()

func add_close(v: VBoxContainer) -> void:
	v.add_child(button(t("close"), close, true))

func main_menu() -> void:
	page = "main"
	world_controls(false)
	game.in_menu = true
	var v = popup("LittleGod")
	v.add_child(label(t("universe"), 16, Color("a1c9b2")))
	v.add_child(label(t("welcome"), 26))
	var artwork = HBoxContainer.new()
	artwork.alignment = BoxContainer.ALIGNMENT_CENTER
	artwork.add_theme_constant_override("separation", 18)
	v.add_child(artwork)
	for frame in [0, 12, 1]:
		var picture = TextureRect.new()
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(105, 118)
		var atlas = AtlasTexture.new()
		atlas.atlas = GameArt.ATLAS
		atlas.region = Rect2((frame % 4) * 256, (frame / 4) * 256, 256, 256)
		picture.texture = atlas
		artwork.add_child(picture)
	if Persistence.has_save(game.save_path): v.add_child(button(t("continue"), game.restore, true))
	v.add_child(button(t("new"), creation, true))
	v.add_child(button("English / Türkçe", func(): toggle_language(); main_menu()))
	var row = HBoxContainer.new()
	for entry in [["local_universe", local_universe], ["beta", beta_tools]]:
		var b = button(t(entry[0]),entry[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",18)
		row.add_child(b)
	v.add_child(row)
	v.add_child(button("Çevrimiçi evren" if language=="tr" else "Online universe",online_screen))

func creation() -> void:
	page = "creation"
	var v = popup(t("new"))
	v.add_child(label(t("name")))
	var name_input = LineEdit.new()
	name_input.name = "PlanetName"
	name_input.add_theme_font_override("font", ui_font())
	name_input.text = "Lumi"
	name_input.max_length = 32
	name_input.custom_minimum_size.y = 64
	name_input.add_theme_font_size_override("font_size", 28)
	v.add_child(name_input)
	v.add_child(label(t("seed")))
	var seed_input = LineEdit.new()
	seed_input.name = "WorldSeed"
	seed_input.add_theme_font_override("font", ui_font())
	seed_input.custom_minimum_size.y = 64
	seed_input.placeholder_text = "2026"
	seed_input.add_theme_font_size_override("font_size", 24)
	v.add_child(seed_input)
	if Persistence.has_save(game.save_path): v.add_child(label(t("replace"), 18))
	v.add_child(button(t("create"), func():
		var chosen_seed = int(seed_input.text) if seed_input.text.is_valid_int() else int(Time.get_unix_time_from_system())
		game.new_planet(chosen_seed, name_input.text.strip_edges() if not name_input.text.strip_edges().is_empty() else "Lumi")
		close(), true))
	v.add_child(button(t("back"), main_menu))

func menu() -> void:
	if game.realm_ui!=null and game.realm_ui.active:game.realm_ui.finish()
	if game.decorator!=null and game.decorator.active:game.decorator.finish()
	if game.visiting: visit_menu(); return
	page = "menu"
	game.checkpoint("menu")
	game.in_menu = true
	var v = popup(t("menu"))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 470
	v.add_child(scroll)
	scroll.add_child(grid)
	var realm_button=button("İlk Krallık" if language=="tr" else "First Kingdom",game.realm_ui.open);realm_button.custom_minimum_size.x=294;grid.add_child(realm_button)
	var wardrobe_button=button("Atölye ve koleksiyon" if language=="tr" else "Atelier & collection",func():game.decorator.collection())
	wardrobe_button.custom_minimum_size.x=294;grid.add_child(wardrobe_button)
	var online_button = button("Çevrimiçi evren" if language=="tr" else "Online universe",online_screen)
	online_button.custom_minimum_size.x=294
	grid.add_child(online_button)
	for entry in [["local_universe", local_universe], ["wonders", wonders], ["journal", journal], ["neighbors", neighbors], ["chronicle", history], ["achievements", achievements], ["settings", settings], ["save", game.manual_save], ["load", game.restore], ["favorites", favorite_places], ["showcase", capture_postcard], ["new", creation], ["pause", func(): game.paused = not game.paused; close()]]:
		var b = button(t(entry[0]), entry[1])
		b.custom_minimum_size.x = 294
		grid.add_child(b)
	add_close(v)

func toggle_language() -> void:
	language = "tr" if language == "en" else "en"
	game.save_settings()
	build()

func settings() -> void:
	page = "settings"
	var v = popup(t("settings"))
	v.add_child(button("English / Türkçe", func(): toggle_language(); settings()))
	v.add_child(button(t("audio") + "  ·  " + t("on" if game.audio.enabled else "off"), func(): game.audio.set_enabled(not game.audio.enabled); game.save_settings(); settings()))
	v.add_child(button(t("quality") % t("economy" if game.view.low_quality else "smooth"), func(): game.view.set_quality(not game.view.low_quality); game.save_settings(); settings()))
	v.add_child(button(t("vibration") + "  ·  " + t("on" if game.haptics else "off"), func(): game.haptics = not game.haptics; game.save_settings(); settings()))
	v.add_child(button(t("theme"), func():
		if not game.visiting and not game.world.is_empty() and game.world.xp >= 40:
			game.world.theme = 1 - int(game.world.theme)
			game.schedule_save()))
	v.add_child(button(t("beta"), beta_tools))
	add_close(v)

func scroll_text(v: VBoxContainer, text: String) -> void:
	var sc = ScrollContainer.new()
	sc.custom_minimum_size.y = 430
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	var l = label(text, 21)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(l)

func journal() -> void:
	page = "journal"
	var v = popup(t("journal") + "  " + str(game.world.discoveries.size()) + "/6")
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 470
	v.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	list.add_child(label(t("chapter_progress") % [game.world.living.findings.size(), game.world.living.observed.size()], 19))
	for key in LivingStories.FINDINGS:
		list.add_child(label(("✧ " + event_text(game.world.living.records.get(key, {"key": key}))) if game.world.living.findings.has(key) else "◇ " + t({"rain_bloom": "guide_bloom", "friendship": "guide_friend", "lantern_grove": "guide_grove", "first_village": "guide_village"}[key]), 18))
	for i in range(6):
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", style(Color("203e42"), 14))
		list.add_child(card)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var portrait = TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(84, 86)
		var texture = AtlasTexture.new()
		texture.atlas = GameArt.ATLAS
		texture.region = Rect2((i % 4) * 256, (i / 4) * 256, 256, 256)
		portrait.texture = texture
		row.add_child(portrait)
		var known = game.world.discoveries.has(i)
		if not known: portrait.modulate = Color(.18, .35, .34)
		var text = label((species(i) + "\n" + t("habitat") % Biomes.title(i, language)) if known else t("unknown"), 20)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
	add_close(v)

func event_text(e: Dictionary) -> String:
	var key = str(e.get("key", "quiet"))
	var text = t(key)
	var amount = int(e.get("amount", 0))
	if key in ["discovery", "birth"]: text = text % species(clampi(amount, 0, 5))
	elif key == "settlement": text = text % stages()[clampi(amount, 0, 2)]
	elif key == "power": text = text % t(POWER_KEYS[clampi(amount, 0, 5)])
	elif key in ["friendship", "lantern_grove", "first_village", "first_birth", "companions", "rivalry", "explored", "elder", "landmark", "alliance", "rescue", "silver_fox", "rainbow_choir", "canopy_arch", "reed_shelter", "migration", "trade", "boundary", "cooperation"]: text = text % str(e.get("subject", game.world.name))
	return text

func history() -> void:
	page = "history"
	var v = popup(t("chronicle"))
	v.add_child(label(t("memory_body"), 18))
	var list = card_list(v, 410)
	var memories = game.world.living.memories.duplicate()
	memories.reverse()
	for e in memories: memory_card(list, e)
	if memories.is_empty(): list.add_child(label(t("quiet"), 21))
	list.add_child(button(t("recent_activity"), recent_history))
	list.add_child(label(t("secrets_hint"), 20))
	add_close(v)

func recent_history() -> void:
	page = "history"
	var v = popup(t("recent_activity"))
	var text = ""
	var events = game.world.events.duplicate()
	events.reverse()
	for e in events: text += "· " + (t("day") % (1 + int(e.tick) / 30)) + " — " + event_text(e) + "\n\n"
	scroll_text(v, text if not text.is_empty() else t("quiet"))
	add_close(v)

func achievements() -> void:
	page = "achievements"
	var v = popup(t("achievements"))
	v.add_child(label(t("chapter_progress") % [game.world.living.findings.size(), game.world.living.observed.size()], 22))
	v.add_child(button(t(LivingStories.objective(game.world)), func(): close(); follow_chapter()))
	for key in ["sanctuary", "season"]:
		v.add_child(label(("✧ " if game.world.achievements.has(key) else "◇ ") + t(key), 24))
	v.add_child(label(t("theme"), 22))
	v.add_child(label(t("locked"), 20, Color("a3b6a8")))
	add_close(v)

func away(report: Dictionary) -> void:
	page = "away"
	var v = popup(t("away"))
	var duration_key = "away_days" if int(report.minutes) >= 1440 else "away_hours" if int(report.minutes) >= 60 else "away_minutes"
	var duration_value = int(report.minutes) / (1440 if int(report.minutes) >= 1440 else 60 if int(report.minutes) >= 60 else 1)
	v.add_child(label(t(duration_key) % duration_value, 22))
	if report.has("new_chapters"):
		v.add_child(label(t("return_growth") % [report.new_chapters, report.creature_change, report.people_change, report.new_settlements], 19))
	var list = card_list(v, 360)
	var highlights = report.get("memories", []).duplicate()
	highlights.sort_custom(func(a,b):
		var priority = {"mountain_spring": 5, "silver_fox": 5, "rainbow_choir": 5, "alliance": 4, "landmark": 4, "first_birth": 3, "first_village": 3, "rescue": 3}
		var pa = int(priority.get(a.key, 1))
		var pb = int(priority.get(b.key, 1))
		return pa > pb if pa != pb else int(a.tick) > int(b.tick))
	for e in highlights.slice(0, 9): memory_card(list, e)
	if highlights.size() > 9: list.add_child(button(t("chronicle"), history))
	if report.get("memories", []).is_empty():
		for e in report.events.slice(maxi(0, report.events.size() - 6)): list.add_child(label(event_text(e), 20))
	if report.events.is_empty() and report.get("memories", []).is_empty(): list.add_child(label(t("quiet"), 20))
	add_close(v)

func inspect(cell: int) -> void:
	var c = game.world.cells[cell]
	hint.text = t("inspect") % [Biomes.title(int(c.biome), language), int(c.moisture * 100), int(c.plants * 100)]
	for s in game.world.settlements:
		if int(s.cell) == cell:
			inspect_settlement(s)
			return
	for cr in game.world.creatures:
		if int(cr.cell) == cell:
			LivingStories.observe(game.world, cr)
			show_creature(cr)
			refresh()
			return
	for s in game.world.settlements:
		if int(s.cell) == cell:
			hint.text = s.given_name + " · " + str(int(s.population)) + " · " + stages()[int(s.stage)] + "\n" + t(s.custom)

func show_creature(cr: Dictionary) -> void:
	toast_until = 0
	game.note("first_creature", int(cr.species), true)
	game.schedule_save()
	hint.text = cr.given_name + " · " + species(int(cr.species)) + "\n" + t(cr.trait)

func inspect_settlement(s: Dictionary) -> void:
	preload("res://scripts/kingdom.gd").observe_settlers(game.world,int(s.cell))
	toast_until = 0
	game.note("first_settlement", int(s.stage), true)
	game.schedule_save()
	hint.text = s.given_name + " · " + str(int(s.population)) + " · " + stages()[int(s.stage)] + "\n" + t(s.custom)

func neighbors() -> void:
	page = "neighbors"
	var v = popup(t("collection"))
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 470
	v.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i in range(game.world.creatures.size()):
		var cr = game.world.creatures[i]
		var known = game.world.living.observed.has(int(cr.identity))
		var b = button(("✧ " if known else "◇ ") + cr.given_name + " · " + species(int(cr.species)), func():
			close()
			game.power = -1
			game.view.focus_creature(i)
			game.view.selected = int(cr.cell)
			game.view.zoom = 1.15
			game.view.pan = -game.view.project(game.world.cells[int(cr.cell)]) * 1.15
			LivingStories.observe(game.world, cr)
			show_creature(cr)
			refresh())
		b.custom_minimum_size.y = 94
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var art = AtlasTexture.new()
		art.atlas = GameArt.ATLAS
		art.region = Rect2((int(cr.species)%4)*256,(int(cr.species)/4)*256,256,256)
		b.icon = art
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("icon_max_width",70)
		list.add_child(b)
		list.add_child(label(t(cr.trait), 17))
		if not game.visiting:
			var star = button("",func(): preload("res://scripts/world_connections.gd").favorite_creature(game.world,cr); game.schedule_save(); neighbors())
			star.icon = load("res://assets/phase2/icons/favorite.svg")
			star.expand_icon = true
			star.add_theme_constant_override("icon_max_width",26)
			star.custom_minimum_size = Vector2(54,54)
			star.size = Vector2(54,54)
			star.modulate = Color("f4dfa3") if preload("res://scripts/world_connections.gd").is_favorite(game.world,int(cr.identity)) else Color("829f96")
			b.add_child(star)
			b.resized.connect(func(): star.position = Vector2(b.size.x-60,8))
	if not game.visiting:
		for favorite in game.world.living.favorite_creatures:
			if not game.world.creatures.any(func(cr): return int(cr.identity)==int(favorite.id)):
				list.add_child(label(t("departed") % favorite.name,20))
				list.add_child(button(t("remove_favorite") % favorite.name,func(): game.world.living.favorite_creatures.erase(favorite); game.schedule_save(); neighbors()))
	add_close(v)

func follow_chapter() -> void:
	if game.visiting: planet_profile(); return
	if game.world.has("kingdom"):game.realm_ui.open();return
	var w = game.world
	var goal = LivingStories.objective(w)
	if goal == "guide_world":
		world_pulse()
		return
	var cell = 0
	if goal == "guide_creature":
		var cr = w.creatures[0]
		cell = int(cr.cell)
		game.power = -1
		game.view.focus_creature(0)
		LivingStories.observe(w, cr)
		show_creature(cr)
	elif goal in ["guide_friend", "guide_village"] and not w.settlements.is_empty():
		cell = int(w.settlements[0].cell)
		if goal == "guide_village" and int(w.settlements[0].blessing) > 0:
			game.power = -1
			toast(w.settlements[0].given_name + " · " + str(int(w.settlements[0].population)) + "/12 · " + t("speed") % "1× / 3×")
		else: choose_power(3 if goal == "guide_friend" else 5)
		if goal == "guide_friend": toast(t("guide_friend"))
	else:
		choose_power(4 if goal in ["guide_rain", "guide_bloom"] else 1)
		for i in range(w.cells.size()):
			if int(w.cells[i].biome) == (2 if goal != "guide_grove" else 1):
				cell = i
				break
		if goal == "guide_grove":
			for cr in w.creatures:
				if int(cr.species) == 1:
					cell = int(cr.cell)
					break
	game.view.selected = cell
	game.view.zoom = 1.15
	game.view.pan = -game.view.project(w.cells[cell]) * game.view.zoom
	if goal in ["guide_rain", "guide_bloom"]:
		game.view.zoom = .88
		game.view.pan = Vector2.ZERO
	game.view.effects.append({"cell": cell, "age": 0.0, "power": 3})
	refresh()

func toast(text: String) -> void:
	hint.text = text
	toast_until = Time.get_ticks_msec() + 8000

func _process(_delta: float) -> void:
	# Six small SVG controls need a fresh command after bulk story/style updates.
	# Keep the HUD current even while the simulation is paused between ticks.
	if not game.in_menu and not game.visiting and is_instance_valid(root):
		for icon in power_icons:
			if icon.visible: icon.queue_redraw()
	if toast_until > 0 and Time.get_ticks_msec() > toast_until and not game.in_menu:
		toast_until = 0
		hint.text = t("hint_short")
	if is_instance_valid(modal):
		var keyboard = DisplayServer.virtual_keyboard_get_height() if OS.has_feature("mobile") else 0
		var scale_factor = get_viewport().get_visible_rect().size.x / maxf(1, DisplayServer.window_get_size().x)
		modal.position.y = minf(modal_base_y, maxf(24, get_viewport().get_visible_rect().size.y - keyboard * scale_factor - modal.size.y - 24)) if keyboard > 0 else modal_base_y

func blocks_world(pos: Vector2) -> bool:
	if game.in_menu or game.loading: return true
	if not is_instance_valid(root): return false
	for control in root.get_children():
		if control is Control and control.visible and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(pos): return true
	return false

func world_controls(value: bool) -> void:
	if not is_instance_valid(root): return
	for child in root.get_children():
		if child is Control and child != modal and child != veil: child.visible = value

func loading_screen() -> void:
	page = "loading"
	var v = popup(t("loading"))
	v.add_child(label(t("loading_body"), 23))
	loading_bar = ProgressBar.new()
	loading_bar.custom_minimum_size = Vector2(0, 22)
	loading_bar.show_percentage = false
	v.add_child(loading_bar)

func loading_progress(value: float) -> void:
	if is_instance_valid(loading_bar): loading_bar.value = value * 100

func beta_tools() -> void:
	page = "beta"
	var v = popup(t("beta"))
	v.add_child(label(t("privacy"), 20))
	v.add_child(button(t("diagnostics") % t("on" if game.diagnostics.enabled else "off"), func():
		game.diagnostics.finish()
		game.diagnostics.enabled = not game.diagnostics.enabled
		game.save_settings()
		beta_tools()))
	v.add_child(button(t("export"), feedback_preview, true))
	v.add_child(button(t("clear_data"), func(): game.diagnostics.clear(); toast(t("cleared")); beta_tools()))
	v.add_child(button(t("back"), func():
		if game.has_player_world: settings()
		else: main_menu()))

func feedback_preview() -> void:
	page = "beta"
	var v = popup(t("export"))
	var text = game.diagnostics.export_feedback()
	var field = TextEdit.new()
	field.text = text
	field.editable = false
	field.custom_minimum_size.y = 380
	field.add_theme_font_override("font", ui_font())
	field.add_theme_font_size_override("font_size", 17)
	v.add_child(field)
	v.add_child(button(t("copy"), func(): DisplayServer.clipboard_set(text); toast(t("copied"))))
	v.add_child(button(t("back"), beta_tools))

func world_pulse() -> void:
	if game.visiting: planet_profile(); return
	page = "pulse"
	var w = game.world
	var v = popup(t("pulse"))
	v.add_child(label(t("pulse_body"), 21))
	var driest = -1
	for i in range(w.cells.size()):
		if w.cells[i].biome != 6 and (driest < 0 or w.cells[i].moisture < w.cells[driest].moisture): driest = i
	if driest >= 0:
		var gift = 4 if w.cells[driest].moisture < .55 else 1
		if gift == 1:
			for i in range(w.cells.size()):
				if w.cells[i].biome == 0 and not w.settlements.any(func(s): return int(s.cell) == i): driest = i; break
		var title = t("care") % int(w.cells[driest].moisture * 100) if gift == 4 else t("grow_habitat")
		v.add_child(button(title, func():
			close()
			choose_power(gift)
			game.view.selected = driest
			game.view.zoom = .88
			game.view.pan = Vector2.ZERO))
	if not w.creatures.is_empty():
		var index = 0
		for i in range(w.creatures.size()):
			if not w.living.observed.has(int(w.creatures[i].identity)): index = i; break
		var cr = w.creatures[index]
		v.add_child(button(t("watch") % cr.given_name, func():
			close()
			game.power = -1
			game.view.focus_creature(index)
			game.view.zoom = 1.15
			game.view.pan = -game.view.project(w.cells[int(cr.cell)]) * 1.15
			LivingStories.observe(w, cr)
			show_creature(cr)
			refresh()))
	if not w.settlements.is_empty():
		var home = w.settlements[0]
		v.add_child(button(t("visit") % [home.given_name, int(home.population)], func():
			close()
			game.power = -1
			game.view.selected = int(home.cell)
			game.view.selected_creature = -1
			game.view.selected_identity = -1
			game.view.zoom = 1.15
			game.view.pan = -game.view.project(w.cells[int(home.cell)]) * 1.15
			inspect_settlement(home)))
	v.add_child(button(t("neighbors"), neighbors))
	add_close(v)

func card_list(v: VBoxContainer, height: float) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = height
	v.add_child(scroll)
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	return list

func memory_card(list: VBoxContainer, e: Dictionary) -> void:
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", style(Color("203e42"), 16))
	list.add_child(card)
	var row = HBoxContainer.new()
	card.add_child(row)
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(76, 100)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var frame = int(e.get("species", -1))
	if frame < 0:
		frame = 1 if e.key in ["silver_fox", "lantern_grove"] else 5 if e.key == "rainbow_choir" else 13 if e.key == "friendship" else 8 if e.key in ["landmark", "alliance", "first_village", "rescue"] else 6 if e.key == "mountain_spring" else 12
	var texture = AtlasTexture.new()
	texture.atlas = GameArt.ATLAS
	texture.region = Rect2((frame % 4) * 256, (frame / 4) * 256, 256, 256)
	portrait.texture = texture
	if e.key == "silver_fox": portrait.material = GameArt.silver()
	row.add_child(portrait)
	var text = event_text(e)
	var b = button((t("day") % (1 + int(e.tick) / 30)) + " · " + text, func(): focus_place(int(e.cell)))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 105
	b.add_theme_font_size_override("font_size", 19)
	row.add_child(b)

func focus_place(cell: int) -> void:
	if cell < 0 or cell >= game.world.cells.size(): return
	close()
	game.power = -1
	game.view.selected = cell
	game.view.selected_creature = -1
	game.view.selected_identity = -1
	game.view.zoom = 1.1
	game.view.pan = -game.view.project(game.world.cells[cell]) * 1.1
	game.view.effects.append({"cell": cell, "age": 0.0, "power": 5})
	inspect(cell)

func inspect_selected() -> void:
	var cell = int(game.view.selected)
	if cell < 0: world_pulse(); return
	var cr: Dictionary = {}
	var home: Dictionary = {}
	if game.view.selected_creature >= 0 and game.view.selected_creature < game.world.creatures.size(): cr = game.world.creatures[game.view.selected_creature]
	for s in game.world.settlements:
		if int(s.cell) == cell and cr.is_empty(): home = s
	var subject = cr if not cr.is_empty() else home
	page = "detail"
	var v = popup(subject.get("given_name", Biomes.title(game.world.cells[cell].biome, language)))
	var list = card_list(v, 220 if not subject.is_empty() else 350)
	if not cr.is_empty():
		var origin = Biomes.title(int(game.world.cells[int(cr.origin_cell)].biome),language)
		var family = t("migrant_bio") if cr.get("migrant",false) else t("child_of") % cr.parent_name if not cr.parent_name.is_empty() else t("founder")
		list.add_child(label(t("biography") % [1+int(cr.recorded_at)/30,1+int(cr.lineage),origin,family],19))
		list.add_child(label(t("personal_story") % [int(game.world.tick) - int(cr.recorded_at), cr.trail.size(), Biomes.title(cr.preferred, language)], 21))
		list.add_child(label(t("bonds") % [creature_name(int(cr.companion)), creature_name(int(cr.rival))], 19))
		list.add_child(label(t(cr.trait), 19))
	elif not home.is_empty():
		list.add_child(label(t(home.custom) + "\n" + str(int(home.population)) + " · " + stages()[int(home.stage)], 21))
		list.add_child(label(t("community_story") % [int(game.world.tick) - int(home.recorded_at), home.allies.size()], 19))
	for e in game.world.living.memories:
		if (not cr.is_empty() and int(e.identity) == int(cr.identity)) or (not home.is_empty() and int(e.cell) == cell): memory_card(list, e)
	if not subject.is_empty() and not game.visiting:
		if not cr.is_empty():list.add_child(button("Canlı gardırobu" if language=="tr" else "Creature wardrobe",func():game.decorator.creature_looks(int(cr.identity))))
		var input = LineEdit.new()
		input.name = "PersonalName"
		input.text = subject.given_name
		input.max_length = 24
		input.add_theme_font_override("font", ui_font())
		input.add_theme_font_size_override("font_size", 25)
		input.custom_minimum_size.y = 60
		v.add_child(input)
		v.add_child(button(t("rename"), func():
			if LivingStories.rename_subject(subject, input.text): game.schedule_save(); inspect_selected()))
	if not game.visiting:
		if not cr.is_empty(): list.add_child(button(t("favorite_creature"),func(): preload("res://scripts/world_connections.gd").favorite_creature(game.world,cr); game.schedule_save(); inspect_selected()))
		v.add_child(button(t("favorite"), func(): LivingStories.favorite(game.world, cell); game.schedule_save(); close()))
	add_close(v)

func creature_name(identity: int) -> String:
	for cr in game.world.creatures:
		if int(cr.identity) == identity: return cr.given_name
	return "—"

func favorite_places() -> void:
	page = "favorites"
	var v = popup(t("favorites"))
	var list = card_list(v, 400)
	for cell in game.world.living.favorites:
		list.add_child(button("✧ " + Biomes.title(game.world.cells[int(cell)].biome, language) + " · " + str(int(cell) + 1), func(): focus_place(int(cell))))
	list.add_child(label(t("favorite"), 20))
	add_close(v)

var postcard_image: Image

func capture_postcard() -> void:
	if DisplayServer.get_name() == "headless": return
	close()
	world_controls(false)
	game.in_menu = true
	var title = label(game.showcases.public_text(game.world.name,32,"Little planet"), 44, Color("f0e7cd"))
	title.add_theme_font_override("font", load("res://assets/phase2/lora.ttf"))
	place(title, Rect2(40, 82, 640, 80))
	var caption = label("L I T T L E G O D\n" + profile_summary(game.showcases.project(game.world)).split("\n",true,1)[1], 21)
	place(caption, Rect2(50, 990 + maxf(0,game.get_viewport_rect().size.y-1280), 620, 185))
	await RenderingServer.frame_post_draw
	postcard_image = get_viewport().get_texture().get_image()
	title.queue_free()
	caption.queue_free()
	postcard_preview()

func postcard_preview(message: String = "") -> void:
	page = "postcard"
	var v = popup(t("postcard"))
	var preview = TextureRect.new()
	preview.texture = ImageTexture.create_from_image(postcard_image)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size.y = 320
	v.add_child(preview)
	v.add_child(label(t("postcard_body") if message.is_empty() else message, 19))
	v.add_child(button(t("export_png"), export_postcard, true))
	add_close(v)

func save_postcard(path: String) -> bool:
	return postcard_image != null and postcard_image.save_png(path) == OK

func export_postcard() -> void:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray(["*.png ; PNG"])
	dialog.current_file = "LittleGod-postcard.png"
	add_child(dialog)
	dialog.file_selected.connect(func(path):
		var ok = save_postcard(path)
		postcard_preview(t("image_saved" if ok else "image_failed"))
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered_ratio(.8)

func local_universe() -> void:
	page = "universe"
	var v = popup(t("local_universe"))
	v.add_child(label(t("universe_body"),20))
	var list = card_list(v,330)
	if not game.world.is_empty(): list.add_child(button(t("my_profile"),planet_profile,true))
	for id in game.showcases.entries():
		var data = game.showcases.get_planet(id)
		list.add_child(button(data.planet.name + " · " + (t("day") % (1+int(data.planet.tick)/30)),func(): planet_profile(data,id)))
		var remove_copy = button(t("remove_copy"),func(): game.showcases.remove(id); local_universe())
		remove_copy.add_theme_font_size_override("font_size",17)
		list.add_child(remove_copy)
	v.add_child(button(t("import_planet"),import_planet_dialog))
	v.add_child(label(t("library_full"),17))
	if game.world.is_empty(): v.add_child(button(t("back"),main_menu))
	else: add_close(v)

var online_ui
func online_screen() -> void:
	if online_ui==null: online_ui=preload("res://scripts/online_interface.gd").new(self,game,game.online)
	online_ui.home()

func import_planet_text(text: String) -> String:
	return game.showcases.import_text(text)

func import_planet_dialog() -> void:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray(["*.lgplanet ; LittleGod planet", "*.json ; JSON"])
	add_child(dialog)
	dialog.file_selected.connect(func(path):
		var data = game.showcases.read_file(path)
		var id = "" if data.is_empty() else import_planet_text(JSON.stringify(data))
		if id.is_empty(): social_message(t("import_failed"))
		else: planet_profile(game.showcases.get_planet(id),id)
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered_ratio(.8)

func social_message(text: String) -> void:
	page = "universe"
	var v = popup(t("local_universe"))
	v.add_child(label(text,22))
	v.add_child(button(t("back"),func(): planet_profile() if game.visiting else local_universe()))

func profile_summary(data: Dictionary) -> String:
	var people = 0
	var biomes: Dictionary = {}
	for s in data.settlements: people += int(s.population)
	for c in data.cells: biomes[int(c.biome)] = true
	var monuments = data.settlements.filter(func(s): return s.landmark).size()
	var summary=data.planet.name + "\n" + t("profile_stats") % [1+int(data.planet.tick)/30,data.creatures.size(),people,data.settlements.size(),biomes.size()] + "\n" + t("profile_discoveries") % [data.discoveries.size(),data.secrets.size()] + " · " + t("landmarks_count") % monuments
	if data.has("appearance"):
		var look=preload("res://scripts/cosmetics.gd").items()[data.appearance.theme]
		summary+="\n"+str(look.name[1 if language=="tr" else 0])+" · "+str(data.appearance.placements.size())+(" dekor" if language=="tr" else " decorations")
	return summary

func portrait(frame: int, size_value: Vector2) -> TextureRect:
	var picture = TextureRect.new()
	picture.custom_minimum_size = size_value
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture = AtlasTexture.new()
	texture.atlas = GameArt.ATLAS
	texture.region = Rect2((frame%4)*256,(frame/4)*256,256,256)
	picture.texture = texture
	return picture

func planet_profile(data: Dictionary = {}, id: String = "") -> void:
	if game.visiting and game.visited_id.begins_with("online:"):
		if online_ui==null: online_ui=preload("res://scripts/online_interface.gd").new(self,game,game.online)
		online_ui.snapshot_profile(game.visited_id.trim_prefix("online:"))
		return
	if data.is_empty():
		if game.world.is_empty(): local_universe(); return
		data = game.showcases.project(game.world)
		id = game.visited_id if game.visiting else ""
	if not game.showcases.validate(data): social_message(t("import_failed")); return
	page = "profile"
	var v = popup(data.planet.name)
	var list = card_list(v,380)
	list.add_child(label(t("snapshot_notice") if not id.is_empty() else t("share_notice"),18))
	list.add_child(label(profile_summary(data),22,Color("e7d8a9")))
	var artwork = HBoxContainer.new()
	artwork.alignment = BoxContainer.ALIGNMENT_CENTER
	list.add_child(artwork)
	var featured: Array = []
	var represented: Array = []
	for cr in data.creatures:
		if not represented.has(int(cr.species)) and featured.size()<3:
			featured.append(cr); represented.append(int(cr.species))
	for cr in featured:
		var column = VBoxContainer.new()
		column.add_child(portrait(int(cr.species),Vector2(140,105)))
		column.add_child(label(cr.name,17))
		artwork.add_child(column)
	if not id.is_empty():
		var mine = game.visit_origin.get("world",{}) if game.visiting else game.world
		if not mine.is_empty():
			var common = data.discoveries.filter(func(s): return mine.discoveries.has(int(s))).size()
			list.add_child(label(t("compare") % [common,data.discoveries.size()-common],19))
	for key in data.secrets:
		list.add_child(label("✧ " + event_text({"key":key,"subject":data.planet.name}),19))
	for m in data.memories.slice(maxi(0,data.memories.size()-2)):
		list.add_child(label(event_text(m),18))
	list.add_child(button(t("copy_summary"),func(): DisplayServer.clipboard_set(profile_summary(data))))
	var actions = HBoxContainer.new()
	v.add_child(actions)
	if not id.is_empty() and not game.visiting:
		var visit = button(t("visit_planet"),func(): game.visit_planet(data,id),true)
		visit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(visit)
	else:
		var file = button(t("export_planet"),func(): export_planet_dialog(data))
		file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(file)
		var card = button(t("showcase"),capture_postcard)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_font_size_override("font_size",18)
		actions.add_child(card)
	if not id.is_empty():
		var reaction = game.showcases.reaction(id)
		v.add_child(button(t("local_reaction") % t("reactions").split(" · ")[reaction],func(): game.showcases.react(id,(reaction+1)%4); planet_profile(data,id)))
	add_close(v)

func export_planet_dialog(data: Dictionary, filename: String = "LittleGod-planet.lgplanet") -> void:
	if not game.showcases.validate(data): social_message(t("import_failed")); return
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray(["*.lgplanet ; LittleGod planet"])
	dialog.current_file = filename
	add_child(dialog)
	dialog.file_selected.connect(func(path):
		var f = FileAccess.open(path,FileAccess.WRITE)
		var ok = f != null
		if ok: f.store_string(JSON.stringify(data)); f.flush(); ok = f.get_error()==OK; f.close()
		social_message(t("export_ok" if ok else "file_failed"))
		dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered_ratio(.8)

func visit_menu() -> void:
	page = "visit_menu"
	var v = popup(t("visit_menu"))
	v.add_child(label(t("snapshot_notice"),21))
	var list = card_list(v,350)
	if game.visited_id.begins_with("online:"):
		list.add_child(button("Çevrimiçi profil" if language=="tr" else "Online profile",func():
			if online_ui==null: online_ui=preload("res://scripts/online_interface.gd").new(self,game,game.online)
			online_ui.snapshot_profile(game.visited_id.trim_prefix("online:"))))
	for entry in [["my_profile",planet_profile],["collection",neighbors],["chronicle",history],["showcase",capture_postcard],["settings",settings]]:
		list.add_child(button(t(entry[0]),entry[1]))
	v.add_child(button(t("leave_visit"),game.stop_visit,true))
	add_close(v)

func wonders() -> void:
	page = "wonders"
	var v = popup(t("wonders"))
	v.add_child(label(t("wonders_body"),20))
	var list = card_list(v,380)
	for opportunity in preload("res://scripts/world_connections.gd").opportunities(game.world):
		var action = button(t(opportunity.key),func():
			focus_place(int(opportunity.cell))
			choose_power(int(opportunity.power)))
		action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(action)
	list.add_child(label(t("places_found") % game.world.living.places.size(),21))
	for place in game.world.living.places:
		var action = button(event_text({"key":place.kind,"subject":game.world.name}),func(): focus_place(int(place.cell)))
		action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(action)
	add_close(v)
