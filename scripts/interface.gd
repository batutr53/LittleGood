extends CanvasLayer

var game: Node
var root: Control
var header: Label
var stats: Label
var hint: Label
var power_buttons: Array = []
var modal: PanelContainer
var language = "en"

const TEXT = {
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
"load_failed": ["No valid save found.", "Geçerli kayıt bulunamadı."], "spirit": ["SPIRIT", "RUH GÜCÜ"]
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
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func label(text: String, size: int = 22, color: Color = Color("e5efdc")) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
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
	b.add_theme_color_override("font_color", Color("102d33") if primary else Color("e1ead7"))
	b.add_theme_stylebox_override("normal", style(Color("bbd8aa") if primary else Color("203d46")))
	b.add_theme_stylebox_override("hover", style(Color("d3e5bd") if primary else Color("325653")))
	b.add_theme_stylebox_override("pressed", style(Color("e5c88d")))
	b.pressed.connect(func(): game.audio.chime(); action.call())
	return b

func place(control: Control, rect: Rect2) -> void:
	root.add_child(control)
	control.position = rect.position
	control.size = rect.size

func build() -> void:
	if root: root.queue_free()
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var safe_top = 0.0
	if OS.has_feature("mobile"):
		var safe = DisplayServer.get_display_safe_area()
		var screen = DisplayServer.screen_get_size()
		if screen.y > 0: safe_top = clampf(safe.position.y * 1280.0 / screen.y, 0, 55)
	var brand = label("L I T T L E G O D", 21, Color("b7d4c2"))
	place(brand, Rect2(120, 35 + safe_top, 480, 40))
	header = label("", 44)
	place(header, Rect2(80, 88 + safe_top, 560, 65))
	stats = label("", 19, Color("abc4bc"))
	place(stats, Rect2(60, 160 + safe_top, 600, 75))
	place(button("☰", menu), Rect2(28, 40 + safe_top, 64, 60))
	place(button("−", func(): game.view.zoom = clampf(game.view.zoom - 0.15, 0.5, 2)), Rect2(28, 825, 62, 64))
	place(button("+", func(): game.view.zoom = clampf(game.view.zoom + 0.15, 0.5, 2)), Rect2(98, 825, 62, 64))
	place(button("◎", func(): game.view.pan = Vector2.ZERO; game.view.zoom = 0.88), Rect2(168, 825, 62, 64))
	place(button("1× / 3×", func(): game.speed = 3 if game.speed == 1 else 1), Rect2(534, 825, 158, 64))
	hint = label(t("hint"), 20, Color("b9cfc3"))
	place(hint, Rect2(42, 900, 636, 83))
	place(label(t("gift"), 17, Color("c2cda8")), Rect2(40, 1000, 640, 25))
	power_buttons.clear()
	for i in range(6):
		var b = button(SYMBOLS[i] + "  " + t(POWER_KEYS[i]) + "  · " + str(Powers.COSTS[i]), func(): choose_power(i))
		b.add_theme_font_size_override("font_size", 18)
		place(b, Rect2(28 + (i % 3) * 232, 1043 + (i / 3) * 85, 220, 75))
		power_buttons.append(b)
	place(label(t("universe"), 13, Color("6d938b")), Rect2(50, 1224, 620, 26))
	refresh()

func choose_power(i: int) -> void:
	game.power = -1 if game.power == i else i
	hint.text = t("hint") if game.power == -1 else t("select") % t(POWER_KEYS[i])
	for n in range(6):
		power_buttons[n].add_theme_stylebox_override("normal", style(Color("556a4d") if n == game.power else Color("203d46")))

func refresh() -> void:
	if not header or game.world.is_empty(): return
	var w = game.world
	header.text = w.name
	var people = 0
	for s in w.settlements: people += int(s.population)
	stats.text = (t("day") % (1 + int(w.tick) / 30)) + "  ·  " + seasons()[(int(w.tick) / 120) % 4] + "  ·  " + (t("level") % (1 + int(w.xp) / 40)) + "\n" + t("population") % [w.creatures.size(), people] + "   ✧ " + str(int(w.energy))

func popup(title: String) -> VBoxContainer:
	if modal: modal.queue_free()
	modal = PanelContainer.new()
	modal.add_theme_stylebox_override("panel", style(Color("152f3a"), 28))
	place(modal, Rect2(34, 240, 652, 700))
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	modal.add_child(v)
	v.add_child(label(title, 32, Color("ecdfb8")))
	return v

func close() -> void:
	if modal: modal.queue_free(); modal = null
	game.in_menu = false

func add_close(v: VBoxContainer) -> void:
	v.add_child(button(t("close"), close, true))

func main_menu() -> void:
	game.in_menu = true
	var v = popup("LittleGod")
	v.add_child(label(t("universe"), 16, Color("a1c9b2")))
	v.add_child(label(t("welcome"), 26))
	v.add_child(label("✧   ♧   ≈", 64, Color("d8d9a9")))
	if FileAccess.file_exists(Persistence.PATH): v.add_child(button(t("continue"), game.restore, true))
	v.add_child(button(t("new"), creation, true))
	v.add_child(button("English / Türkçe", func(): toggle_language(); main_menu()))

func creation() -> void:
	var v = popup(t("new"))
	v.add_child(label(t("name")))
	var name_input = LineEdit.new()
	name_input.text = "Lumi"
	name_input.max_length = 32
	name_input.custom_minimum_size.y = 64
	name_input.add_theme_font_size_override("font_size", 28)
	v.add_child(name_input)
	v.add_child(label(t("seed")))
	var seed_input = LineEdit.new()
	seed_input.custom_minimum_size.y = 64
	seed_input.placeholder_text = "2026"
	seed_input.add_theme_font_size_override("font_size", 24)
	v.add_child(seed_input)
	v.add_child(label(t("replace"), 18))
	v.add_child(button(t("create"), func():
		var chosen_seed = int(seed_input.text) if seed_input.text.is_valid_int() else int(Time.get_unix_time_from_system())
		game.new_planet(chosen_seed, name_input.text.strip_edges() if not name_input.text.strip_edges().is_empty() else "Lumi")
		close(), true))
	v.add_child(button(t("back"), main_menu))

func menu() -> void:
	game.in_menu = true
	var v = popup(t("menu"))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	v.add_child(grid)
	for entry in [["journal", journal], ["history", history], ["achievements", achievements], ["settings", settings], ["save", game.manual_save], ["load", game.restore], ["new", creation], ["pause", func(): game.paused = not game.paused; close()]]:
		var b = button(t(entry[0]), entry[1])
		b.custom_minimum_size.x = 294
		grid.add_child(b)
	add_close(v)

func toggle_language() -> void:
	language = "tr" if language == "en" else "en"
	game.save_settings()
	build()

func settings() -> void:
	var v = popup(t("settings"))
	v.add_child(button("English / Türkçe", func(): toggle_language(); settings()))
	v.add_child(button(t("sound"), func(): game.audio.set_enabled(not game.audio.enabled); game.save_settings()))
	v.add_child(button(t("theme"), func():
		if game.world.xp >= 40: game.world.theme = 1 - int(game.world.theme)))
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
	var v = popup(t("journal") + "  " + str(game.world.discoveries.size()) + "/6")
	var text = ""
	for i in range(6):
		text += ("◇ " + species(i) + "\n" + t("habitat") % Biomes.title(i, language) if game.world.discoveries.has(i) else "?  " + t("unknown")) + "\n\n"
	scroll_text(v, text)
	add_close(v)

func event_text(e: Dictionary) -> String:
	var key = str(e.get("key", "quiet"))
	var text = t(key)
	var amount = int(e.get("amount", 0))
	if key in ["discovery", "birth"]: text = text % species(clampi(amount, 0, 5))
	elif key == "settlement": text = text % stages()[clampi(amount, 0, 2)]
	elif key == "power": text = text % t(POWER_KEYS[clampi(amount, 0, 5)])
	return text

func history() -> void:
	var v = popup(t("history"))
	var text = ""
	var events = game.world.events.duplicate()
	events.reverse()
	for e in events: text += "· " + (t("day") % (1 + int(e.tick) / 30)) + " — " + event_text(e) + "\n\n"
	scroll_text(v, text if not text.is_empty() else t("quiet"))
	add_close(v)

func achievements() -> void:
	var v = popup(t("achievements"))
	for key in ["sanctuary", "season"]:
		v.add_child(label(("✧ " if game.world.achievements.has(key) else "◇ ") + t(key), 24))
	v.add_child(label(t("theme"), 22))
	v.add_child(label(t("locked"), 20, Color("a3b6a8")))
	add_close(v)

func away(report: Dictionary) -> void:
	var v = popup(t("away"))
	v.add_child(label(t("away_body") % report.minutes, 22))
	var text = ""
	for e in report.events.slice(maxi(0, report.events.size() - 9)):
		text += "✧ " + event_text(e) + "\n\n"
	scroll_text(v, text if not text.is_empty() else t("quiet"))
	add_close(v)

func inspect(cell: int) -> void:
	var c = game.world.cells[cell]
	hint.text = t("inspect") % [Biomes.title(int(c.biome), language), int(c.moisture * 100), int(c.plants * 100)]
	for cr in game.world.creatures:
		if int(cr.cell) == cell:
			hint.text = t("creature_info") % [species(int(cr.species)), int(cr.hunger * 100), Biomes.title(int(cr.species), language)]
			return
	for s in game.world.settlements:
		if int(s.cell) == cell:
			hint.text = t("settlement_info") % [stages()[int(s.stage)], int(s.population), int(s.food), s.tech]

func toast(text: String) -> void:
	hint.text = text
