class_name Costumes

# Kostüm kataloğu ve çizimleri. Üç yuva var: "head" (başlık), "acc"
# (aksesuar) ve "aura" (sadece efsane); her yuvada aynı anda bir kostüm takılır.
# "legendary" kostümler uzun vadeli hedef: pahalı, Wardrobe'da altın çerçeveli. Kostümler ateş böceği
# (GameState.fireflies) ile açılır. Çizimler ChameleonBody'nin kendi
# koordinatlarında (onun _draw'ının sonunda, aynı dönüşümle) yapılır; renkler
# sabit — bukalemunun her renginde koyu konturla okunur.

const LIST := [
	{"id": "bowtie", "name": "Bow Tie", "slot": "acc", "price": 100},
	{"id": "cap", "name": "Cap", "slot": "head", "price": 200},
	{"id": "shades", "name": "Shades", "slot": "acc", "price": 300},
	{"id": "party", "name": "Party Hat", "slot": "head", "price": 400},
	{"id": "scarf", "name": "Scarf", "slot": "acc", "price": 550},
	{"id": "cowboy", "name": "Cowboy Hat", "slot": "head", "price": 700},
	{"id": "wizard", "name": "Wizard Hat", "slot": "head", "price": 900},
	# satın alınamaz: 7 günlük seri ödülü (GameState.claim_daily_reward)
	{"id": "crown", "name": "Crown", "slot": "head", "price": 0, "streak": true},
	{"id": "astro", "name": "Astronaut Helmet", "slot": "head", "price": 2000, "legendary": true},
	{"id": "cape", "name": "Rainbow Cape", "slot": "acc", "price": 3000, "legendary": true},
	{"id": "golden", "name": "Golden Sparkle", "slot": "aura", "price": 5000, "legendary": true},
]

const INK := Color(0.1, 0.08, 0.1)
const LINE_W := 2.4

static func get_item(id: String) -> Dictionary:
	for c in LIST:
		if c["id"] == id:
			return c
	return {}

static func is_legendary(c: Dictionary) -> bool:
	return c.get("legendary", false)

static func slot_key(c: Dictionary) -> String:
	match c["slot"]:
		"head": return "equipped_head"
		"aura": return "equipped_aura"
	return "equipped_acc"

static func is_streak_item(c: Dictionary) -> bool:
	return c.get("streak", false)

# Henüz alınmamış en ucuz kostüm (sonuç ekranındaki "sıradaki hedef" için); yoksa {}.
# Seri ödülü (Taç) satın alınamadığı için hedef sayılmaz.
static func next_goal() -> Dictionary:
	var best := {}
	for c in LIST:
		if c["id"] in GameState.owned_costumes or is_streak_item(c):
			continue
		if best.is_empty() or c["price"] < best["price"]:
			best = c
	return best

static func any_affordable() -> bool:
	for c in LIST:
		if c["id"] not in GameState.owned_costumes and not is_streak_item(c) 				and GameState.fireflies >= c["price"]:
			return true
	return false

static func draw_item(cv: CanvasItem, id: String) -> void:
	match id:
		"bowtie": _bowtie(cv)
		"cap": _cap(cv)
		"shades": _shades(cv)
		"party": _party(cv)
		"scarf": _scarf(cv)
		"cowboy": _cowboy(cv)
		"wizard": _wizard(cv)
		"crown": _crown(cv)
		"astro": _astro(cv)
		"golden": _golden(cv)

# Bukalemun gövdesinden ÖNCE çizilen parçalar (gövdenin arkasında kalır).
static func draw_behind(cv: CanvasItem, id: String) -> void:
	match id:
		"cape": _cape(cv)

static func _shape(cv: CanvasItem, pts: PackedVector2Array, fill: Color) -> void:
	cv.draw_colored_polygon(pts, fill)
	var closed := PackedVector2Array(pts)
	closed.append(pts[0])
	cv.draw_polyline(closed, INK, LINE_W, true)

static func _dot(cv: CanvasItem, c: Vector2, r: float, fill: Color) -> void:
	cv.draw_circle(c, r + LINE_W * 0.5, INK)
	cv.draw_circle(c, r, fill)

static func _arc_pts(c: Vector2, r: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		o.append(c + Vector2(cos(a), sin(a)) * r)
	return o

# Boyunda papyon: koyu lacivert kanatlar, açık düğüm.
static func _bowtie(cv: CanvasItem) -> void:
	var c := Vector2(12, 19)
	var main := Color(0.16, 0.15, 0.3)
	_shape(cv, PackedVector2Array([c + Vector2(-3, -3), c + Vector2(-13, -9), c + Vector2(-15, 0),
		c + Vector2(-13, 9), c + Vector2(-3, 3)]), main)
	_shape(cv, PackedVector2Array([c + Vector2(3, -3), c + Vector2(13, -9), c + Vector2(15, 0),
		c + Vector2(13, 9), c + Vector2(3, 3)]), main)
	cv.draw_line(c + Vector2(-11, -5), c + Vector2(-7, -3), Color(1, 1, 1, 0.35), 2.0, true)
	cv.draw_line(c + Vector2(7, -3), c + Vector2(11, -5), Color(1, 1, 1, 0.35), 2.0, true)
	_dot(cv, c, 4.2, Color(0.42, 0.4, 0.62))

# İleri bakan kep: beyaz kubbe, mavi siper ve tepe düğmesi.
static func _cap(cv: CanvasItem) -> void:
	var blue := Color(0.22, 0.4, 0.85)
	_shape(cv, PackedVector2Array([Vector2(42, -31), Vector2(63, -29), Vector2(65, -25), Vector2(44, -24)]), blue)
	var crown := _arc_pts(Vector2(30, -27), 17.0, PI, TAU, 16)
	_shape(cv, crown, Color(0.97, 0.97, 0.95))
	cv.draw_line(Vector2(30, -44), Vector2(30, -28), Color(INK, 0.3), 1.6, true)
	cv.draw_polyline(_arc_pts(Vector2(30, -27), 12.0, PI * 1.15, PI * 1.45, 6), Color(1, 1, 1, 0.9), 2.2, true)
	_dot(cv, Vector2(30, -44), 3.0, blue)

# Tek camlı (yandan) güneş gözlüğü; sap miğfere doğru uzanır.
static func _shades(cv: CanvasItem) -> void:
	var e := Vector2(29, -12)
	cv.draw_line(e + Vector2(-13, -4), Vector2(2, -20), INK, 3.2, true)
	var lens := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		lens.append(e + Vector2(cos(a) * 15.0, sin(a) * 11.0))
	_shape(cv, lens, Color(0.1, 0.1, 0.16))
	cv.draw_line(e + Vector2(15, -2), e + Vector2(20, -3), INK, 3.0, true)
	cv.draw_line(e + Vector2(-6, -5), e + Vector2(2, -8), Color(1, 1, 1, 0.75), 2.4, true)
	cv.draw_line(e + Vector2(5, 3), e + Vector2(9, 1), Color(1, 1, 1, 0.45), 2.0, true)

# Başta hafif geriye yatık, puantiyeli parti külahı ve ponpon.
static func _party(cv: CanvasItem) -> void:
	var pink := Color(1.0, 0.42, 0.62)
	var yellow := Color(1.0, 0.85, 0.3)
	_shape(cv, PackedVector2Array([Vector2(16, -29), Vector2(44, -27), Vector2(32, -68)]), pink)
	cv.draw_circle(Vector2(26, -36), 3.0, yellow)
	cv.draw_circle(Vector2(36, -38), 2.6, yellow)
	cv.draw_circle(Vector2(31, -50), 2.4, yellow)
	cv.draw_line(Vector2(17, -30), Vector2(43, -28), Color(1, 1, 1, 0.6), 3.0, true)
	_dot(cv, Vector2(32, -69), 5.5, yellow)

# Boyuna sarılı çizgili atkı; ucu geriye doğru sarkar.
static func _scarf(cv: CanvasItem) -> void:
	var red := Color(0.9, 0.26, 0.3)
	var cream := Color(1.0, 0.93, 0.8)
	_shape(cv, PackedVector2Array([Vector2(6, 14), Vector2(10, 16), Vector2(6, 34), Vector2(-4, 36),
		Vector2(-6, 32), Vector2(0, 16)]), red)
	cv.draw_line(Vector2(2, 22), Vector2(8, 23), cream, 3.0, true)
	cv.draw_line(Vector2(0, 29), Vector2(6, 30), cream, 3.0, true)
	var band := PackedVector2Array([Vector2(-2, 8), Vector2(10, 12), Vector2(24, 16), Vector2(30, 14),
		Vector2(30, 22), Vector2(22, 25), Vector2(8, 22), Vector2(-4, 17)])
	_shape(cv, band, red)
	cv.draw_line(Vector2(6, 11), Vector2(4, 19), cream, 3.0, true)
	cv.draw_line(Vector2(16, 14), Vector2(15, 23), cream, 3.0, true)
	cv.draw_line(Vector2(25, 15), Vector2(25, 24), cream, 3.0, true)

# Geniş kenarlı kovboy şapkası: kahverengi, ortası çukur tepe, koyu bant.
static func _cowboy(cv: CanvasItem) -> void:
	var brown := Color(0.62, 0.4, 0.2)
	var dark := Color(0.38, 0.22, 0.1)
	var crown := PackedVector2Array([Vector2(16, -31), Vector2(15, -46), Vector2(20, -54), Vector2(27, -50),
		Vector2(33, -54), Vector2(40, -49), Vector2(42, -31)])
	_shape(cv, crown, brown)
	cv.draw_line(Vector2(16, -35), Vector2(42, -35), dark, 5.0, true)
	var brim := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		brim.append(Vector2(29, -30) + Vector2(cos(a) * 30.0, sin(a) * 6.0))
	_shape(cv, brim, brown)
	cv.draw_line(Vector2(4, -31), Vector2(-2, -35), INK, LINE_W, true)   # kıvrık kenar ucu
	cv.draw_line(Vector2(54, -31), Vector2(60, -35), INK, LINE_W, true)

# Uzun, ucu geriye kıvrık, yıldızlı sihirbaz şapkası.
static func _wizard(cv: CanvasItem) -> void:
	var purple := Color(0.36, 0.28, 0.72)
	var yellow := Color(1.0, 0.86, 0.32)
	_shape(cv, PackedVector2Array([Vector2(14, -30), Vector2(44, -28), Vector2(34, -56), Vector2(24, -74),
		Vector2(10, -82), Vector2(4, -78), Vector2(16, -70), Vector2(22, -56)]), purple)
	_star(cv, Vector2(30, -44), 4.5, yellow)
	_star(cv, Vector2(24, -60), 3.2, yellow)
	cv.draw_circle(Vector2(36, -36), 1.8, yellow)
	var brim := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		brim.append(Vector2(29, -29) + Vector2(cos(a) * 21.0, sin(a) * 4.5))
	_shape(cv, brim, purple.darkened(0.15))

# Altın taç: üç sivri uç, kırmızı ve mavi taşlar.
static func _crown(cv: CanvasItem) -> void:
	var gold := Color(1.0, 0.8, 0.25)
	_shape(cv, PackedVector2Array([Vector2(16, -29), Vector2(44, -27), Vector2(46, -48), Vector2(38, -38),
		Vector2(31, -54), Vector2(24, -39), Vector2(15, -49)]), gold)
	cv.draw_line(Vector2(17, -33), Vector2(43, -31), Color(0.85, 0.6, 0.12), 3.0, true)
	_dot(cv, Vector2(31, -54), 2.6, gold)
	_dot(cv, Vector2(15, -49), 2.2, gold)
	_dot(cv, Vector2(46, -48), 2.2, gold)
	_dot(cv, Vector2(30, -36), 3.0, Color(0.9, 0.2, 0.3))
	_dot(cv, Vector2(21, -36), 2.0, Color(0.25, 0.55, 0.95))
	_dot(cv, Vector2(39, -35), 2.0, Color(0.25, 0.55, 0.95))

static func _star(cv: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + PI * i / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	cv.draw_colored_polygon(pts, col)

# Astronot kaskı: başı ve miğferi saran cam fanus, gri yaka, kırmızı uçlu anten.
static func _astro(cv: CanvasItem) -> void:
	var c := Vector2(19, -13)
	const R := 47.0   # miğferin ucu da fanusun içinde kalsın
	cv.draw_line(c + Vector2(8, -R + 1), c + Vector2(14, -R - 14), INK, 2.4, true)
	_dot(cv, c + Vector2(14, -R - 15), 4.0, Color(1.0, 0.3, 0.3))
	cv.draw_circle(c, R, Color(0.7, 0.88, 1.0, 0.16))
	cv.draw_arc(c, R, 0.0, TAU, 64, INK, LINE_W + 1.2, true)
	cv.draw_arc(c, R - 2.5, 0.0, TAU, 64, Color(0.85, 0.95, 1.0, 0.9), 2.0, true)
	cv.draw_arc(c, R - 9.0, PI * 1.08, PI * 1.42, 16, Color(1, 1, 1, 0.8), 4.0, true)
	cv.draw_arc(c, R - 9.0, PI * 1.5, PI * 1.56, 4, Color(1, 1, 1, 0.8), 4.0, true)
	cv.draw_arc(c, R + 1.0, PI * 0.28, PI * 0.8, 24, INK, 11.0, true)
	cv.draw_arc(c, R + 1.0, PI * 0.3, PI * 0.78, 24, Color(0.82, 0.84, 0.9), 7.0, true)

# Gökkuşağı pelerini: boyundan geriye uçuşan, ucu genişleyen dalgalı şerit.
# Gövdenin ARKASINDA çizilir (draw_behind) — oyunun renk okuması bozulmasın.
static func _cape(cv: CanvasItem) -> void:
	var cols := [Color(0.95, 0.3, 0.35), Color(1.0, 0.6, 0.2), Color(1.0, 0.86, 0.3),
		Color(0.35, 0.8, 0.45), Color(0.3, 0.55, 0.95)]
	const N := 14
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for i in N + 1:
		var t := float(i) / N
		var base := Vector2(6, -12).lerp(Vector2(-88, -16), t) + Vector2(0, sin(t * PI * 2.4) * 7.0 * t)
		var w := 7.0 + 14.0 * t
		top.append(base + Vector2(0, -w))
		bot.append(base + Vector2(0, w))
	var outline := PackedVector2Array(top)
	for i in range(N, -1, -1):
		outline.append(bot[i])
	cv.draw_colored_polygon(outline, INK)
	cv.draw_polyline(outline + PackedVector2Array([outline[0]]), INK, LINE_W * 2.0, true)
	for k in cols.size():
		var band := PackedVector2Array()
		for i in N + 1:
			band.append(top[i].lerp(bot[i], float(k) / cols.size()))
		for i in range(N, -1, -1):
			band.append(top[i].lerp(bot[i], float(k + 1) / cols.size()))
		cv.draw_colored_polygon(band, cols[k])

# Altın parıltı: gövde çevresinde yanıp sönen dört köşeli yıldızlar
# (benekleri altına çevirmek ChameleonBody'de). Rengi değiştirmez.
static func _golden(cv: CanvasItem) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var spots := [Vector2(-58, -14), Vector2(-20, -38), Vector2(62, -30), Vector2(-66, 30),
		Vector2(40, 34), Vector2(6, -46)]
	for i in spots.size():
		var tw := 0.5 + 0.5 * sin(t * 3.0 + i * 1.7)
		_sparkle(cv, spots[i], 4.0 + 4.0 * tw, Color(1.0, 0.88, 0.35, 0.35 + 0.65 * tw))

static func _sparkle(cv: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := PI / 4.0 * i
		var rr := r if i % 2 == 0 else r * 0.3
		pts.append(c + Vector2(cos(a - PI / 2.0), sin(a - PI / 2.0)) * rr)
	cv.draw_colored_polygon(pts, col)
	cv.draw_circle(c, r * 0.25, Color(1, 1, 1, col.a))
