@tool
class_name SettingIconButton
extends Button

# Oyunun flat diline uygun, elle çizilen ayar ikonu.
# Açık: beyaz tek-çizgi ikon.  Kapalı: soluk gri + kırmızı çizik.

enum Kind { SOUND, VIBRATE, MUSIC }

@export var kind: Kind = Kind.SOUND:
	set(value):
		kind = value
		queue_redraw()

@export var is_on: bool = true:
	set(value):
		is_on = value
		queue_redraw()

const ON_COL := Color(0.95, 0.97, 0.97)
const OFF_COL := Color(0.56, 0.6, 0.6)
const SLASH_COL := Color(0.95, 0.42, 0.42)

func _ready() -> void:
	custom_minimum_size = Vector2(56, 48)
	focus_mode = Control.FOCUS_NONE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.15, 0.14)
	sb.set_corner_radius_all(13)
	var sb_hi := sb.duplicate()
	sb_hi.bg_color = Color(0.19, 0.22, 0.21)
	add_theme_stylebox_override("normal", sb)
	add_theme_stylebox_override("focus", sb)
	add_theme_stylebox_override("hover", sb_hi)
	add_theme_stylebox_override("pressed", sb_hi)

func _draw() -> void:
	var u := minf(size.x, size.y) * 0.5 / 24.0   # ikon, düğmenin ~yarısını kaplar
	var o := size * 0.5 - Vector2(12.0, 12.0) * u
	var col := ON_COL if is_on else OFF_COL
	var w := 2.4 * u

	match kind:
		Kind.SOUND:
			_speaker(o, u, w, col)
		Kind.VIBRATE:
			_phone(o, u, w, col)
		Kind.MUSIC:
			_note(o, u, w, col)

	if not is_on:
		var a := o + Vector2(2.5, 21.5) * u
		var b := o + Vector2(21.5, 2.5) * u
		draw_line(a, b, Color(0.09, 0.1, 0.1), w * 2.4, true)  # arkadaki "kesik"
		draw_line(a, b, SLASH_COL, w, true)

func _p(o: Vector2, u: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * u

func _speaker(o: Vector2, u: float, w: float, col: Color) -> void:
	draw_rect(Rect2(_p(o, u, 2.5, 9.5), Vector2(4.0, 5.0) * u), col)
	var cone := PackedVector2Array([
		_p(o, u, 5.5, 9.5), _p(o, u, 12, 3.5), _p(o, u, 12, 20.5), _p(o, u, 5.5, 14.5),
	])
	draw_colored_polygon(cone, col)
	if is_on:
		var c := _p(o, u, 12, 12)
		draw_arc(c, 4.2 * u, -0.8, 0.8, 20, col, w, true)
		draw_arc(c, 7.6 * u, -0.8, 0.8, 24, col, w, true)
	else:
		draw_line(_p(o, u, 15.5, 8.5), _p(o, u, 21.5, 15.0), col, w, true)
		draw_line(_p(o, u, 21.5, 8.5), _p(o, u, 15.5, 15.0), col, w, true)

func _phone(o: Vector2, u: float, w: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = col
	sb.set_border_width_all(maxi(1, int(round(w))))
	sb.set_corner_radius_all(int(round(2.5 * u)))
	draw_style_box(sb, Rect2(_p(o, u, 7.5, 3.0), Vector2(9.0, 18.0) * u))
	draw_line(_p(o, u, 10.0, 18.0), _p(o, u, 14.0, 18.0), col, w, true)  # ana tuş çizgisi
	if is_on:
		draw_line(_p(o, u, 4.0, 8.5), _p(o, u, 4.0, 15.5), col, w, true)
		draw_line(_p(o, u, 20.5, 8.5), _p(o, u, 20.5, 15.5), col, w, true)
		draw_line(_p(o, u, 1.5, 10.5), _p(o, u, 1.5, 13.5), col, w * 0.85, true)
		draw_line(_p(o, u, 23.0, 10.5), _p(o, u, 23.0, 13.5), col, w * 0.85, true)

func _note(o: Vector2, u: float, w: float, col: Color) -> void:
	draw_circle(_p(o, u, 8.0, 18.0), 3.7 * u, col)
	draw_line(_p(o, u, 11.5, 17.4), _p(o, u, 11.5, 4.0), col, w, true)
	draw_line(_p(o, u, 11.5, 4.0), _p(o, u, 17.0, 7.5), col, w, true)
	draw_line(_p(o, u, 11.5, 8.5), _p(o, u, 16.0, 11.5), col, w * 0.9, true)
