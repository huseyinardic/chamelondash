extends TextureRect

var gradient: Gradient

func _ready():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Renkleri tema belirler (JungleBackdrop.THEMES); bu başlangıç = Classic.
	gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(0.10, 0.24, 0.20), Color(0.05, 0.13, 0.10)])

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 256
	texture = tex

	# Node2D altındaki bir Control anchor'ı bazen çözülmüyor; boyutu elle veriyoruz
	# ve döndürme/yeniden boyutlanmada güncel tutuyoruz.
	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)

func _fit_to_viewport() -> void:
	# Node2D altındaki bir Control'ün anchor'ı çözülmüyor (ebeveyn Control yok) —
	# anchor ile bırakınca boyut 0 kalıyor ve geçiş hiç görünmüyordu. Boyutu elle ver.
	set_anchors_preset(Control.PRESET_TOP_LEFT)   # tam ekran anchor'ı boyutu ezmesin
	position = Vector2.ZERO
	size = get_viewport_rect().size
