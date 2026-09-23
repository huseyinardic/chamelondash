class_name CountdownRing
extends Control

# "Continue?" ekranındaki geri sayım halkası. progress 1 -> 0 azalır; halka
# saat yönünde tepeden boşalır.

const RING_COL := Color(0.949, 0.788, 0.298)   # ikondaki sarı
const TRACK_COL := Color(1, 1, 1, 0.12)
const WIDTH := 12.0

var progress := 1.0:
	set(v):
		progress = v
		queue_redraw()

func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - WIDTH
	draw_circle(c, r, TRACK_COL, false, WIDTH, true)
	if progress > 0.001:
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * progress, 72, RING_COL, WIDTH, true)
