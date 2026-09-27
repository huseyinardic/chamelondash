class_name DailyRewardPanel
extends Control

# Günün ilk menü açılışında çıkan seri ödülü kartı: 7 günlük şerit (geçmiş
# günler işaretli, bugün altın çerçeveli, 7. gün Taç), tek "Claim" düğmesi.
# 7. günü şeritte baştan göstermek oyuncuya "bir hafta gel" hedefini verir.
# Ödülün kendisi GameState.claim_daily_reward'da; bu sadece arayüz.

signal claimed(result: Dictionary)

const CELL := Vector2(64, 100)
const GOLD := Color(1.0, 0.82, 0.25)

var _cells: Array = []        # [{panel, amount, icon_holder}]
var _subtitle: Label
var _extra: Label
var _claim: Button
var _busy := false
var dim: ColorRect            # main temaya göre renklendirir (JungleBackdrop.dim_rects)

# Taç simgesi: Costumes'ın bukalemun koordinatlı çizimini kutuya sığdırır.
class CrownIcon extends Control:
	func _draw() -> void:
		var k := size.x / 40.0
		draw_set_transform(size / 2.0 - Vector2(30.5, -41.5) * k, 0.0, Vector2(k, k))
		Costumes.draw_item(self, "crown")

func build(title_t: Label, label_t: Label, button_t: Button) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.09, 0.06, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	add_child(box)

	var title: Label = title_t.duplicate(0)
	title.text = "Daily Reward"
	box.add_child(title)
	_subtitle = label_t.duplicate(0)
	_subtitle.add_theme_font_size_override("font_size", 26)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle)

	var strip := HBoxContainer.new()
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 8)
	for d in 7:
		strip.add_child(_make_cell(d + 1, label_t))
	box.add_child(strip)

	_extra = label_t.duplicate(0)
	_extra.add_theme_font_size_override("font_size", 24)
	_extra.add_theme_color_override("font_color", GOLD)
	_extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_extra)

	_claim = button_t.duplicate(0)
	_claim.custom_minimum_size = Vector2(320, 68)
	_claim.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_claim.add_theme_font_size_override("font_size", 30)
	_claim.disabled = false
	_claim.visible = true
	_claim.pressed.connect(_on_claim)
	box.add_child(_claim)

func _make_cell(day: int, label_t: Label) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = CELL
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 6.0
	v.offset_bottom = -6.0
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	var dl: Label = label_t.duplicate(0)
	dl.text = "Day %d" % day
	dl.add_theme_font_size_override("font_size", 16)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dl)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(0, 40)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(holder)
	var amount: Label = label_t.duplicate(0)
	amount.add_theme_font_size_override("font_size", 17)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(amount)
	_cells.append({"panel": p, "amount": amount, "holder": holder})
	return p

# preview = GameState.daily_reward_preview()
func show_for(preview: Dictionary) -> void:
	var day: int = preview["day"]
	var today_i: int = mini(day, 7)
	var crown_pending: bool = "crown" not in GameState.owned_costumes
	for i in 7:
		var d := i + 1
		var c: Dictionary = _cells[i]
		for ch in c["holder"].get_children():
			ch.queue_free()
		var icon: Control
		if d == 7 and crown_pending:
			icon = CrownIcon.new()
			c["amount"].text = "Crown"
		else:
			icon = FireflyIcon.new()
			icon.glow = d == today_i
			var amt: int = GameState.STREAK_REWARDS[i] if d <= GameState.STREAK_REWARDS.size() else GameState.STREAK_AFTER
			c["amount"].text = str(amt)
		icon.custom_minimum_size = Vector2(38, 38)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c["holder"].add_child(icon)
		if d < today_i:
			c["amount"].text = "✓"
		var st := StyleBoxFlat.new()
		st.set_corner_radius_all(14)
		if d == today_i:
			st.bg_color = Color(1, 1, 1, 0.14)
			st.set_border_width_all(3)
			st.border_color = GOLD
		elif d < today_i:
			st.bg_color = Color(0.3, 0.8, 0.45, 0.18)
		else:
			st.bg_color = Color(0, 0, 0, 0.3)
		c["panel"].add_theme_stylebox_override("panel", st)
		c["panel"].modulate.a = 0.55 if d < today_i else 1.0
		c["panel"].scale = Vector2.ONE

	_subtitle.text = "🔥 %d day streak" % day
	var extras: Array[String] = []
	if day >= GameState.NEON_STREAK_DAY and 2 not in GameState.unlocked_themes:
		extras.append("+ Neon theme unlocked!")
	if crown_pending and day < 7:
		extras.append("Come back %d more days for the Crown!" % (7 - day))
	_extra.text = "\n".join(extras)
	_extra.visible = not extras.is_empty()
	_claim.disabled = false
	_claim.text = "Claim the Crown!" if preview["crown"] else "Claim +%d" % preview["amount"]
	_busy = false
	modulate.a = 0.0
	visible = true
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)

func _on_claim() -> void:
	if _busy:
		return
	_busy = true
	var r := GameState.claim_daily_reward()
	var cell: Panel = _cells[mini(int(r["day"]), 7) - 1]["panel"]
	cell.pivot_offset = cell.size / 2.0
	cell.scale = Vector2(1.3, 1.3)
	create_tween().tween_property(cell, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if GameState.vibration_enabled:
		Input.vibrate_handheld(40)
	_claim.text = "See you tomorrow!"
	_claim.disabled = true
	claimed.emit(r)
	var t := create_tween()
	t.tween_interval(0.9)
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func(): visible = false)
