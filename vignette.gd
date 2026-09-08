extends TextureRect

func _ready():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Merkez ve ekranın büyük kısmı tamamen şeffaf; sadece dış kenar bandı ve
	# köşeler hafifçe kararıyor. Maks. alpha 0.35 -> "koca yumurta" yerine ince çerçeve.
	var gradient := Gradient.new()
	gradient.set_offsets([0.0, 0.55, 1.0])
	gradient.set_colors([
		Color(0, 0, 0, 0.0),
		Color(0, 0, 0, 0.0),
		Color(0, 0, 0, 0.35),
	])

	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.85, 0.85)  # rampa köşeye yakın biter -> merkez geniş/açık kalır
	tex.width = 256
	tex.height = 256
	texture = tex

	_fit_to_viewport()
	get_viewport().size_changed.connect(_fit_to_viewport)

func _fit_to_viewport() -> void:
	# Tam ekran anchor'ı; boyut anchor'a bağlı olduğu için elle size vermiyoruz.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
