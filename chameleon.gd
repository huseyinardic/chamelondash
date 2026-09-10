@tool
class_name ChameleonBody
extends Node2D

# Tek _draw() ile çizilen bukalemun. Eski ~30 Panel + _tint_chameleon yerine geçer.
# Koordinatlar tasarım uzayında; PIV merkeze alır, K oyuna ölçekler.
# skin -> gövde/kafa/casque/kuyruk/bacaklar. Göz akı/bebek/ağız sabit.

const PIV := Vector2(214.0, 197.0)
const K := 0.44

@export var skin: Color = Color(0.184, 0.72, 0.545):
	set(value):
		skin = value
		queue_redraw()

func set_skin(c: Color) -> void:
	skin = c

func _pt(x: float, y: float) -> Vector2:
	return (Vector2(x, y) - PIV) * K

func _pv(a: Array) -> PackedVector2Array:
	var o := PackedVector2Array()
	var i := 0
	while i < a.size():
		o.push_back(_pt(a[i], a[i + 1]))
		i += 2
	return o

func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var o := PackedVector2Array(p)
	o.push_back(p[0])
	return o

func _draw() -> void:
	var belly := skin.lightened(0.34)
	var dark := skin.darkened(0.26)
	var line := skin.darkened(0.42)
	var pad := skin.darkened(0.46)
	var sclera := Color(0.99, 0.953, 0.882)
	var ink := Color(0.149, 0.133, 0.121)

	# --- kuyruk kıvrımı (gövdenin arka ucundan, geriye/aşağıya) ---
	var tail := _pv([88,248, 72,262, 60,286, 62,312, 80,330, 106,336, 128,324, 134,300, 122,282, 102,280, 90,292, 92,310, 104,316])
	draw_polyline(tail, skin, 10.0, true)
	draw_circle(tail[0], 5.0, skin)
	draw_circle(tail[tail.size() - 1], 3.0, skin)
	draw_polyline(tail, line, 2.0, true)

	# --- arka ayak (belin altında, kuyruktan ayrı; ucu gövdenin altından görünür) ---
	var hind := _pv([156,252, 164,276, 158,296, 152,302, 161,306, 168,299, 172,278, 170,254])
	draw_colored_polygon(hind, skin)
	draw_polyline(_closed(hind), line, 2.0, true)
	draw_polyline(_pv([161,298, 163,307]), line, 2.0, true)

	# --- gövde ---
	var body := _pv([
		92,250, 96,205, 108,168, 132,142, 162,128, 196,120, 226,112, 256,108,
		286,116, 312,134, 332,150, 350,168, 356,186, 350,200, 334,208, 318,212,
		306,222, 296,240, 270,258, 210,274, 150,278, 108,268, 92,258])
	draw_colored_polygon(body, skin)

	# --- karın (skin'in açık tonu, ince) ---
	draw_colored_polygon(_pv([132,252, 190,262, 246,258, 268,246, 250,264, 192,270, 144,262]), Color(belly.r, belly.g, belly.b, 0.7))

	# --- gövde konturu ---
	draw_polyline(_closed(body), line, 2.5, true)

	# --- casque (miğfer) ---
	var casq := _pv([228,122, 232,90, 248,66, 270,56, 292,62, 310,82, 320,112, 322,134, 300,128, 264,118])
	draw_colored_polygon(casq, dark)
	draw_polyline(_closed(casq), line, 1.6, true)

	# --- ön ayak (kavrayan mitten) ---
	var foot := _pv([228,244, 236,268, 231,292, 224,308, 219,315, 232,318, 243,311, 246,289, 247,264, 245,246])
	draw_colored_polygon(foot, skin)
	draw_polyline(_closed(foot), line, 2.2, true)
	draw_polyline(_pv([229,308, 231,318]), line, 2.2, true)

	# --- yanak + ağız (sabit) ---
	draw_circle(_pt(318, 190), 4.0, Color(0.95, 0.63, 0.70, 0.38))
	draw_polyline(_pv([330,201, 342,207, 352,204, 359,197]), ink, 2.6, true)

	# --- göz turret'i ---
	var ec := _pt(300, 150)
	draw_circle(ec, 13.2, skin)
	draw_arc(ec, 13.2, 0.0, TAU, 40, line, 2.2, true)
	draw_polyline(_pv([284,161, 296,171, 312,171, 320,160]), line, 2.2, true)
	# göz akı / bebek / parıltı — sabit
	draw_circle(ec, 7.0, sclera)
	draw_circle(_pt(305, 149), 3.1, ink)
	draw_circle(_pt(300, 144), 1.4, Color.WHITE)
