class_name FireflyIcon
extends Control

# Ateş böceği simgesi (para birimi): parlak sarı gövde, yumuşak hale, iki kanat.
# Arka planda süzülen ateş böcekleriyle aynı dil.

@export var glow := true

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(30, 30)

func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size / 2.0 + Vector2(0, s * 0.06)
	var r := s * 0.2
	if glow:
		draw_circle(c, s * 0.5, Color(1.0, 0.9, 0.4, 0.14))
		draw_circle(c, s * 0.34, Color(1.0, 0.9, 0.4, 0.22))
	# kanatlar (arkada, yukarı açık)
	var wing := Color(1, 1, 1, 0.75)
	_ellipse(c + Vector2(-r * 0.9, -r * 1.05), r * 0.75, r * 0.5, -0.5, wing)
	_ellipse(c + Vector2(r * 0.9, -r * 1.05), r * 0.75, r * 0.5, 0.5, wing)
	draw_circle(c, r * 1.15, Color(0.55, 0.42, 0.08))
	draw_circle(c, r, Color(1.0, 0.88, 0.32))
	draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.35, Color(1, 1, 0.85, 0.9))

func _ellipse(c: Vector2, rx: float, ry: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	draw_colored_polygon(pts, col)
