class_name CrossPromo
extends Button

# Juniva oyunları arası çapraz tanıtım kartı (oyun sonu ekranında, kartın altında).
# Kartın tamamı düğme: dokununca diğer oyunun Play sayfası açılır. Link kaynak etiketi
# taşır (utm_source = bu oyun): Play Console ve hedef oyunun Firebase'i kurulumu buraya yazar.
# Kurallar: ilk MIN_GAMES oyunda yok (yeni oyuncu önce bu oyunu sevsin), rekor anında yok
# (o an değerlendirme penceresinin), oturum başına en fazla 1 kez, tıklanan oyun
# CLICK_COOLDOWN_DAYS gün gösterilmez; birden çok aday varsa sırayla döner.
# Yalnız ikonu projede olan oyunlar aday (promo/ klasörü). (Juniva oyunlarında aynı dosya.)

const GAMES := [
	{"id": "istif", "name": "Istif", "tagline": "Stack the tower!", "pkg": "com.huseynardic.stacktower",
		"icon": "res://promo/istif_icon.png"},
	{"id": "chameleon", "name": "Chameleon Dash", "tagline": "Match the colors!", "pkg": "com.huseynardic.chameleondash",
		"icon": "res://promo/chameleon_icon.png"},
]
const MIN_GAMES := 5
const CLICK_COOLDOWN_DAYS := 7
const SAVE_PATH := "user://cross_promo.cfg"
const CARD_SIZE := Vector2(560, 116)

static var _shown_this_session := false

var game: Dictionary
var _source := ""

# Bu oyun sonunda gösterilecek oyun ({} = gösterme). Seçilirse oturum hakkı kullanılır.
static func pick(self_id: String, games_played: int, new_best: bool) -> Dictionary:
	if _shown_this_session or new_best or games_played <= MIN_GAMES:
		return {}
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var now := int(Time.get_unix_time_from_system())
	var options: Array = []
	for g: Dictionary in GAMES:
		if g["id"] == self_id or not ResourceLoader.exists(g["icon"]):
			continue
		if now - int(cfg.get_value("clicked", g["id"], 0)) < CLICK_COOLDOWN_DAYS * 86400:
			continue
		options.append(g)
	if options.is_empty():
		return {}
	var turn := int(cfg.get_value("rotate", "next", 0))
	cfg.set_value("rotate", "next", turn + 1)
	cfg.save(SAVE_PATH)
	_shown_this_session = true
	return options[turn % options.size()]

static func create(g: Dictionary, source: String, bold: Font, med: Font, accent: Color) -> CrossPromo:
	var c := CrossPromo.new()
	c.game = g
	c._source = source
	c._build(bold, med, accent)
	return c

func _build(bold: Font, med: Font, accent: Color) -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	for state in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 1, 1, 0.2 if state == "pressed" else 0.1)
		st.border_color = Color(1, 1, 1, 0.22)
		st.set_border_width_all(2)
		st.set_corner_radius_all(28)
		add_theme_stylebox_override(state, st)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_right = -20
	row.add_theme_constant_override("separation", 16)
	add_child(row)
	# ikon: yuvarlatılmış köşeli çerçeve içinde
	var frame := Panel.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = Vector2(84, 84)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color.WHITE
	fs.set_corner_radius_all(20)
	frame.add_theme_stylebox_override("panel", fs)
	frame.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(game["icon"])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(icon)
	row.add_child(frame)
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(_label("Try our other game", med, 21, Color(1, 1, 1, 0.66)))
	texts.add_child(_label(game["name"], bold, 32, Color.WHITE))
	texts.add_child(_label(game["tagline"], med, 21, Color(1, 1, 1, 0.8)))
	row.add_child(texts)
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ps := StyleBoxFlat.new()
	ps.bg_color = accent
	ps.set_corner_radius_all(24)
	ps.content_margin_left = 24
	ps.content_margin_right = 24
	ps.content_margin_top = 8
	ps.content_margin_bottom = 8
	pill.add_theme_stylebox_override("panel", ps)
	pill.add_child(_label("PLAY", bold, 26, Color.WHITE))
	row.add_child(pill)
	pressed.connect(_open)

func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	return l

# Oyun sonu ekranıyla birlikte, biraz gecikmeli belirir (önce skor okunsun).
func appear(delay: float) -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3).set_delay(delay)
	Analytics.log_event("cross_promo_show", {"target": game["id"]})

func _open() -> void:
	Analytics.log_event("cross_promo_click", {"target": game["id"]})
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("clicked", game["id"], int(Time.get_unix_time_from_system()))
	cfg.save(SAVE_PATH)
	var ref := "utm_source%3D" + _source + "%26utm_medium%3Dcross_promo%26utm_campaign%3Dgame_over"
	var market := "market://details?id=%s&referrer=%s" % [game["pkg"], ref]
	var web := "https://play.google.com/store/apps/details?id=%s&referrer=%s" % [game["pkg"], ref]
	if OS.get_name() != "Android" or OS.shell_open(market) != OK:
		OS.shell_open(web)
