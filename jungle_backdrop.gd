class_name JungleBackdrop
extends Node2D

# Oyun alanının arkasındaki derinlik katmanları (düz renk geçişinin üstünde,
# bukalemun ve kapıların altında), arkadan öne:
#   1. bukalemunun arkasında yumuşak ışık halesi — göz kahramana gider
#   2. uzak yapraklar  — soluk, küçük, yavaş kayar
#   3. ateş böcekleri  — süzülür, göz kırpar
#   4. yakın yapraklar — koyu siluet, daha hızlı kayar
# Katmanların farklı hızda kayması (paralaks) derinlik ve hız hissi verir.
# Yapraklar sadece kenarlarda: orta şerit (kapı rengini okuma alanı) temiz kalır.
# Renkler kapılardan hep koyu ve soluk — hiçbir kapı rengi zeminde kaybolmasın.
# Her temanın kendi zemini var (THEMES); tema değişince renkler yumuşakça geçer.

const TILE := 1600.0                 # yaprak deseninin tekrar boyu (px)
const FAR_FACTOR := 0.22             # kapı hızına göre kayma oranı
const NEAR_FACTOR := 0.5
const FLY_FACTOR := 0.32
const GLOW_RADIUS := 430.0
const FLY_COUNT := 16
const FLY_EXTRA := 16                # yüksek skorda (energy) sırayla beliren ek ateş böcekleri
const THEME_FADE_SEC := 0.6

# Temaya göre zemin paleti — sıra main.gd'deki theme_palettes ile aynı.
# top/bottom: düz geçiş, glow: bukalemunun arkasındaki hale, far/near: yaprak
# katmanları, fly: ateş böcekleri, dim: menü/oyun sonu karartmalarının tonu.
const THEMES := [
	{	# Classic — orman
		"top": Color(0.10, 0.24, 0.20), "bottom": Color(0.05, 0.13, 0.10),
		"glow": Color(0.42, 0.85, 0.74),
		"far": Color(0.10, 0.25, 0.22, 0.55), "near": Color(0.015, 0.06, 0.05, 0.72),
		"fly": Color(0.85, 1.0, 0.62), "dim": Color(0.035, 0.10, 0.075),
		"edge": Color(0.42, 0.85, 0.74, 0.0),
	},
	{	# Sunset — akşam: erik moru zemin, turuncu ışık (mor kapıdan koyu ve soluk)
		"top": Color(0.27, 0.14, 0.22), "bottom": Color(0.10, 0.05, 0.10),
		"glow": Color(1.0, 0.58, 0.42),
		"far": Color(0.36, 0.17, 0.24, 0.5), "near": Color(0.06, 0.02, 0.05, 0.75),
		"fly": Color(1.0, 0.82, 0.52), "dim": Color(0.09, 0.04, 0.07),
		"edge": Color(1.0, 0.58, 0.42, 0.0),
	},
	{	# Neon — gece: lacivert zemin, mor-mavi ışık. Zemin zaten çok koyu olduğu
		# için yapraklar siyah değil morumsu; yakın yapraklarda ince neon kenar.
		"top": Color(0.08, 0.09, 0.22), "bottom": Color(0.03, 0.03, 0.09),
		"glow": Color(0.45, 0.45, 1.0),
		"far": Color(0.24, 0.20, 0.52, 0.5), "near": Color(0.13, 0.09, 0.32, 0.85),
		"fly": Color(0.55, 0.95, 1.0), "dim": Color(0.03, 0.03, 0.08),
		"edge": Color(0.45, 0.55, 1.0, 0.45),
	},
]

var speed := 0.0                     # main her karede verir (px/sn; 0 = durdu)
var glow_target := Vector2.ZERO      # halenin gideceği yer (menü / oyun)
var bg_gradient: Gradient            # BackgroundGradient'in geçişi (main bağlar)
var dim_rects: Array = []            # tema tonuyla boyanan karartmalar (alfaları korunur)
var energy_target := 0.0             # 0..1: skor kilometre taşlarında zemin canlanır (main verir)

var _energy := 0.0

var _glow_pos := Vector2.ZERO
var _glow_tex: GradientTexture2D
var _far_scroll := 0.0
var _near_scroll := 0.0
var _far: Array = []                 # [{side, y, len, wid, ang}] — tek karo içindeki yapraklar
var _near: Array = []
var _flies: Array = []               # [{p, vy, phase, sway}]
var _t := 0.0
var _cur := {}                       # şu an çizilen renkler (geçiş sırasında hedefe kayar)
var _target := {}
var _fade_left := 0.0

func _ready() -> void:
	var g := Gradient.new()
	g.set_offsets([0.0, 0.45, 1.0])
	_glow_tex = GradientTexture2D.new()
	_glow_tex.gradient = g
	_glow_tex.fill = GradientTexture2D.FILL_RADIAL
	_glow_tex.fill_from = Vector2(0.5, 0.5)
	_glow_tex.fill_to = Vector2(1.0, 0.5)
	_glow_tex.width = 128
	_glow_tex.height = 128

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260927   # sabit desen: her açılışta aynı orman
	_far = _make_leaves(rng, 20, 34.0, 64.0, 12.0, 20.0)
	_near = _make_leaves(rng, 14, 70.0, 130.0, 22.0, 36.0)
	var vs := get_viewport_rect().size
	for i in FLY_COUNT + FLY_EXTRA:
		_flies.append({
			"p": Vector2(rng.randf_range(0.0, vs.x), rng.randf_range(0.0, vs.y)),
			"vy": rng.randf_range(-28.0, -10.0),
			"phase": rng.randf_range(0.0, TAU),
			"sway": rng.randf_range(8.0, 22.0),
		})
	_glow_pos = glow_target
	set_theme(0, false)

func set_theme(index: int, animate: bool) -> void:
	_target = THEMES[clampi(index, 0, THEMES.size() - 1)]
	if animate and not _cur.is_empty():
		_fade_left = THEME_FADE_SEC
	else:
		_cur = _target.duplicate()
		_fade_left = 0.0
	_apply_colors()

func _apply_colors() -> void:
	var glow: Color = _cur["glow"]
	_glow_tex.gradient.colors = PackedColorArray([Color(glow, 0.26), Color(glow, 0.10), Color(glow, 0.0)])
	if bg_gradient:
		bg_gradient.colors = PackedColorArray([_cur["top"], _cur["bottom"]])
	for r in dim_rects:
		r.color = Color(_cur["dim"], r.color.a)

# Bir karo boyunca iki kenara dağılmış yapraklar. Açı kenardan içeri doğru;
# boyları kenara göre değişir ki desen tekrarı göze batmasın.
func _make_leaves(rng: RandomNumberGenerator, per_side: int, len_min: float, len_max: float,
		wid_min: float, wid_max: float) -> Array:
	var out: Array = []
	for side in [-1, 1]:
		for i in per_side:
			out.append({
				"side": side,
				"y": (i + rng.randf_range(0.0, 0.8)) * TILE / per_side,
				"len": rng.randf_range(len_min, len_max),
				"wid": rng.randf_range(wid_min, wid_max),
				"ang": rng.randf_range(-0.9, 0.5),   # 0 = tam yatay içeri, eksi = yukarı
				"inset": rng.randf_range(-20.0, 8.0),
			})
	return out

func _process(delta: float) -> void:
	_t += delta
	_energy = move_toward(_energy, energy_target, delta * 0.8)
	_far_scroll = fposmod(_far_scroll + speed * FAR_FACTOR * delta, TILE)
	_near_scroll = fposmod(_near_scroll + speed * NEAR_FACTOR * delta, TILE)
	_glow_pos = _glow_pos.lerp(glow_target, minf(1.0, delta * 4.0))
	if _fade_left > 0.0:
		_fade_left -= delta
		var w := 1.0 if _fade_left <= 0.0 else minf(1.0, delta / (_fade_left + delta))
		for k in _target:
			_cur[k] = (_cur[k] as Color).lerp(_target[k], w)
		_apply_colors()

	var vs := get_viewport_rect().size
	for f in _flies:
		var p: Vector2 = f["p"]
		p.y += (f["vy"] + speed * FLY_FACTOR) * delta
		p.x += sin(_t * 0.9 + f["phase"]) * f["sway"] * delta
		if p.y < -20.0:
			p.y += vs.y + 40.0
		elif p.y > vs.y + 20.0:
			p.y -= vs.y + 40.0
		f["p"] = p
	queue_redraw()

func _draw() -> void:
	var vs := get_viewport_rect().size
	# enerji arttıkça hale büyür ve biraz daha parlar
	var gs := Vector2(GLOW_RADIUS, GLOW_RADIUS) * 2.0 * (1.0 + 0.3 * _energy)
	draw_texture_rect(_glow_tex, Rect2(_glow_pos - gs / 2.0, gs), false)
	if _energy > 0.01:
		draw_texture_rect(_glow_tex, Rect2(_glow_pos - gs / 2.0, gs), false, Color(1, 1, 1, 0.5 * _energy))

	_draw_layer(_far, _far_scroll, _cur["far"], Color(0, 0, 0, 0), vs)

	var fly: Color = _cur["fly"]
	for i in _flies.size():
		# ek ateş böcekleri enerjiyle birer birer belirir
		var vis := 1.0 if i < FLY_COUNT else clampf(_energy * FLY_EXTRA - (i - FLY_COUNT), 0.0, 1.0)
		if vis <= 0.0:
			continue
		var f: Dictionary = _flies[i]
		var tw := 0.5 + 0.5 * sin(_t * 2.3 + f["phase"] * 3.0)
		draw_circle(f["p"], 10.0, Color(fly, 0.12 * tw * vis))
		draw_circle(f["p"], 3.0, Color(fly, (0.3 + 0.5 * tw) * vis))

	_draw_layer(_near, _near_scroll, _cur["near"], _cur["edge"], vs)

func _draw_layer(leaves: Array, scroll: float, col: Color, edge: Color, vs: Vector2) -> void:
	# karo ekranı dikeyde kaplayana kadar tekrar çizilir
	var start := scroll - TILE
	while start < vs.y + 200.0:
		for l in leaves:
			var y: float = start + l["y"]
			if y < -200.0 or y > vs.y + 200.0:
				continue
			var side: float = l["side"]
			var base := Vector2(vs.x if side > 0 else 0.0, y) + Vector2(-side * l["inset"], 0.0)
			var dir := Vector2(-side, 0.0).rotated(l["ang"] * -side)
			_draw_leaf(base, dir, l["len"], l["wid"], col, edge)
		start += TILE

# Sivri uçlu, ortası dolgun yaprak silueti.
func _draw_leaf(base: Vector2, dir: Vector2, length: float, width: float, col: Color, edge: Color) -> void:
	var n := dir.orthogonal()
	var pts := PackedVector2Array()
	const STEPS := 7
	for i in STEPS + 1:
		var t := float(i) / STEPS
		pts.append(base + dir * length * t + n * width * sin(PI * t) * (1.0 - 0.35 * t))
	for i in range(STEPS - 1, 0, -1):
		var t := float(i) / STEPS
		pts.append(base + dir * length * t - n * width * sin(PI * t) * (1.0 - 0.35 * t))
	draw_colored_polygon(pts, col)
	if edge.a > 0.01:
		pts.append(pts[0])
		draw_polyline(pts, edge, 1.5, true)
