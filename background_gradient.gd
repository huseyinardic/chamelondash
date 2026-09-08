extends TextureRect

func _ready():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.15, 0.35, 0.28, 1.0))
	gradient.add_point(1.0, Color(0.04, 0.1, 0.08, 1.0))

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
	# Tam ekran anchor'ı; boyut anchor'a bağlı olduğu için elle size vermiyoruz.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
