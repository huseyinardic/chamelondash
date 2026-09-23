class_name MenuRings
extends Node2D

# Başlangıç ekranındaki halkalar — ikondaki motifin hareketli hali. Renkler aktif
# temanın bariyer renkleri (dıştan içe); bukalemunun o anki rengine denk gelen
# halka öne çıkar, oyunun "rengi eşle" mekaniğini yazısız anlatır.

const RADII := [236.0, 204.0, 172.0, 140.0]
const WIDTH := 16.0

var colors: Array = []
var highlight := 0
var _emph: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _t := 0.0

func set_colors(c: Array) -> void:
	colors = c
	queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	for i in _emph.size():
		var target := 1.0 if i == highlight else 0.0
		_emph[i] = lerpf(_emph[i], target, minf(1.0, delta * 10.0))
	queue_redraw()

func _draw() -> void:
	for i in mini(colors.size(), RADII.size()):
		var e: float = _emph[i]
		var r: float = RADII[i] + sin(_t * 2.2 - i * 0.7) * 3.0 + e * 4.0
		var c: Color = colors[i]
		c.a = lerpf(0.5, 1.0, e)
		# kapalı çember (draw_arc'ın başlangıç/bitiş noktasında dikiş izi kalıyordu)
		draw_circle(Vector2.ZERO, r, c, false, WIDTH + e * 6.0, true)
