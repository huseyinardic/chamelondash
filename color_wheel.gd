class_name ColorWheel
extends Node2D

# Oyun sırasında bukalemunun etrafındaki renk halkası. Şu anki renk hep tepede
# (kapıların geldiği yönde); bir dokunuşla gelecek renk sağda, iki dokunuşla
# altta, üç dokunuşla solda. Her dokunuşta halka bir dilim döner — oyuncu
# renk sırasını ezberlemek zorunda kalmaz, kapının rengini halkada arar.

const RADIUS := 90.0
const WIDTH := 8.0
const GAP_DEG := 16.0          # dilimler arası boşluk
const SPIN_SPEED := 16.0       # dönüş animasyonunun sönme hızı

var colors: Array = []
var current := 0
var _offset := 0.0             # derece; dokunuşta artar, 0'a doğru söner

func set_colors(c: Array) -> void:
	colors = c
	queue_redraw()

func set_current(index: int, animate: bool) -> void:
	if animate and colors.size() > 0:
		var steps := posmod(index - current, colors.size())
		_offset += steps * 360.0 / colors.size()
	else:
		_offset = 0.0
	current = index
	queue_redraw()

func _process(delta: float) -> void:
	if _offset == 0.0:
		return
	_offset = lerpf(_offset, 0.0, minf(1.0, delta * SPIN_SPEED))
	if absf(_offset) < 0.1:
		_offset = 0.0
	queue_redraw()

func _draw() -> void:
	var n := colors.size()
	if n == 0:
		return
	var step := 360.0 / n
	var half := (step - GAP_DEG) / 2.0
	for k in n:
		var slot := posmod(k - current, n)
		var center := -90.0 + slot * step + _offset
		var on_top := k == current
		var c: Color = colors[k]
		c.a = 1.0 if on_top else 0.75
		var r := RADIUS + (3.0 if on_top else 0.0)
		var w := WIDTH + (5.0 if on_top else 0.0)
		draw_arc(Vector2.ZERO, r, deg_to_rad(center - half), deg_to_rad(center + half), 24, c, w, true)
