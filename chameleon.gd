@tool
class_name ChameleonBody
extends Node2D

# Tek _draw() ile çizilen, sevimli (gerçekçi olmayan) bukalemun — sağa bakar.
# Bukalemun olduğunu belli eden üç işaret korunur ama yumuşatılır:
#   taret göz (ten rengi kabarık göz, içinde iri göz bebeği — göz akı yok),
#   geriye doğru kıvrılan miğfer, spiral kuyruk.
# Sevimlilik oranlardan gelir: iri baş, tombul gövde, kısa bacaklar, yuvarlak
# hatlar, sırtta sivri diken yerine yumuşak tümsekler.
# Tüm parçalar önce koyu kontur rengiyle biraz büyük çizilir, sonra dolgu —
# böylece tek parça "çıkartma" silueti oluşur. Koordinatlar oyun pikseli, merkez (0,0).
# skin -> gövdenin tüm tonları ondan türetilir (tema/renk değişimi).

const OUTLINE := 2.6   # çizim ölçeğiyle (1.08) birlikte büyür

@export var skin: Color = Color(0.184, 0.72, 0.545):
	set(value):
		skin = value
		queue_redraw()

func set_skin(c: Color) -> void:
	skin = c

func _ellipse(c: Vector2, rx: float, ry: float, n: int = 32) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		o.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return o

func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var o := PackedVector2Array(p)
	o.append(p[0])
	return o

# Kuyruk: gövdenin arkasından çıkıp geriye ve alta kıvrılan, uca doğru incelen spiral.
func _tail_points() -> Array:
	var pts: Array = []
	var center := Vector2(-52.0, 30.0)
	const STEPS := 56
	for i in STEPS + 1:
		var t := float(i) / STEPS
		var ang := -1.35 - t * TAU * 1.55      # yukarıdan başla, geriye -> alta -> öne kıvrıl
		var r := lerpf(21.0, 3.5, pow(t, 0.85))
		var w := lerpf(6.0, 1.8, t)            # kalınlık (yarıçap)
		pts.append([center + Vector2(cos(ang), sin(ang)) * r, w])
	return pts

func _draw() -> void:
	var line := skin.darkened(0.48)
	var dark := skin.darkened(0.16)
	var belly := skin.lightened(0.34)
	var spot := skin.lightened(0.24)
	var ink := Color(0.13, 0.11, 0.12)
	var blush := Color(1.0, 0.55, 0.62, 0.45)
	# kuyruk solda ağırlık yaptığı için çizimi biraz sağa kaydır, halkayı dolduracak kadar büyüt
	draw_set_transform(Vector2(6, 1), 0.0, Vector2.ONE * 1.08)

	var tail := _tail_points()
	var body := _ellipse(Vector2(-12, 12), 40.0, 27.0, 40)
	var casque := PackedVector2Array([
		Vector2(40, -24), Vector2(37, -36), Vector2(29, -46), Vector2(17, -53),
		Vector2(5, -55), Vector2(-3, -52), Vector2(-4, -44), Vector2(2, -34), Vector2(10, -26)])
	var head_c := Vector2(24, -6)
	const HEAD_R := 27.0
	var snout_c := Vector2(44, 3)
	const SNOUT_R := 15.0
	var bumps: Array = []   # sırttaki yumuşak tümsekler (gövdenin üst hattı boyunca)
	for x in [-44.0, -34.0, -24.0, -14.0, -4.0]:
		var k: float = (x + 12.0) / 40.0
		bumps.append(Vector2(x, 12.0 - 27.0 * sqrt(maxf(0.0, 1.0 - k * k)) + 2.0))
	var back_leg := [Vector2(-30, 28), Vector2(-32, 45)]
	var front_leg := [Vector2(14, 26), Vector2(17, 45)]

	# --- 1) ana siluet konturu (kuyruk, arka bacak, tümsekler, gövde, miğfer, baş) ---
	for p in tail:
		draw_circle(p[0], p[1] + OUTLINE, line)
	_leg(back_leg, line, OUTLINE)
	for b in bumps:
		draw_circle(b, 5.5 + OUTLINE, line)
	draw_polyline(_closed(body), line, OUTLINE * 2.0, true)
	draw_colored_polygon(body, line)
	draw_polyline(_closed(casque), line, OUTLINE * 2.0, true)
	draw_circle(head_c, HEAD_R + OUTLINE, line)
	draw_circle(snout_c, SNOUT_R + OUTLINE, line)

	# --- 2) dolgular (aynı sıra -> iç sınırlarda çizgi kalmaz, tek parça görünür) ---
	for p in tail:
		draw_circle(p[0], p[1], skin)
	_leg(back_leg, dark, 0.0)
	for b in bumps:
		draw_circle(b, 5.5, skin)
	draw_colored_polygon(body, skin)
	draw_colored_polygon(casque, dark)
	draw_circle(head_c, HEAD_R, skin)
	draw_circle(snout_c, SNOUT_R, skin)

	# --- 3) gövde detayları: karın, benekler, boyun kıvrımı, miğfer çizgisi ---
	var belly_poly := PackedVector2Array()
	for i in 17:
		var a := PI * i / 16.0
		belly_poly.append(Vector2(-12 + cos(a) * 34.0, 18 + sin(a) * 15.0))
	draw_colored_polygon(belly_poly, Color(belly, 0.75))
	draw_circle(Vector2(-30, 0), 5.5, Color(spot, 0.8))
	draw_circle(Vector2(-16, -6), 4.5, Color(spot, 0.8))
	draw_circle(Vector2(-38, 12), 3.5, Color(spot, 0.8))
	draw_circle(Vector2(-22, 10), 3.0, Color(spot, 0.8))
	draw_arc(head_c, HEAD_R - 1.0, PI * 0.82, PI * 1.12, 12, Color(line, 0.35), 1.8, true)
	draw_polyline(PackedVector2Array([Vector2(8, -30), Vector2(12, -40), Vector2(22, -48)]), Color(line, 0.3), 1.6, true)

	# --- 4) ön bacak (gövdenin önünde, kendi konturuyla) ---
	_leg(front_leg, line, OUTLINE)
	_leg(front_leg, skin, 0.0)

	# --- 5) yüz: ağız, yanak, burun deliği ---
	draw_polyline(PackedVector2Array([
		Vector2(58, 5), Vector2(52, 10), Vector2(44, 12), Vector2(37, 11), Vector2(33, 8)]),
		ink, 2.4, true)
	draw_circle(Vector2(20, 8), 5.5, blush)
	draw_circle(Vector2(54, -4), 1.4, line)

	# --- 6) taret göz: ten rengi kabarık top, iri göz bebeği ---
	# İç halka yok (gözlük/monokl gibi duruyordu); kabarıklığı alt-sağdaki
	# gölge hilali verir.
	var eye_c := Vector2(28, -12)
	draw_circle(eye_c, 14.0 + 1.8, line)
	draw_circle(eye_c, 14.0, skin.darkened(0.12))
	draw_circle(eye_c + Vector2(-1.6, -1.6), 12.2, skin.lightened(0.1))
	var pupil := eye_c + Vector2(3.0, 0.5)
	draw_circle(pupil, 7.5, ink)
	draw_circle(pupil + Vector2(-2.4, -2.6), 2.6, Color.WHITE)
	draw_circle(pupil + Vector2(2.2, 2.4), 1.1, Color(1, 1, 1, 0.85))

# Tombul bacak + iki parmaklı "eldiven" ayak (bukalemunun kavrayan ayağı).
# grow > 0 -> kontur katmanı (her parça o kadar büyük çizilir).
func _leg(seg: Array, col: Color, grow: float) -> void:
	var a: Vector2 = seg[0]
	var b: Vector2 = seg[1]
	draw_line(a, b, col, 9.0 + grow * 2.0, true)
	draw_circle(a, 4.5 + grow, col)
	draw_circle(b + Vector2(-4.5, 2.0), 4.2 + grow, col)
	draw_circle(b + Vector2(4.5, 2.0), 4.2 + grow, col)
