class_name CostumeShop
extends VBoxContainer

# Wardrobe'un "Costumes" sekmesi: ateş böceği bakiyesi, kostümlü bukalemun
# önizlemesi, kostüm kartları ve tek bir eylem düğmesi (Buy / Wear / Take off).
# Karta dokunmak önce önizler (bukalemun onu takmış görünür); satın alma ancak
# eylem düğmesiyle olur — yanlışlıkla harcama olmasın. Stil ve fontlar sahnedeki
# mevcut düğme/etiketten kopyalanır ki Themes sekmesiyle aynı görünsün.

signal equipment_changed

const CARD_SIZE := Vector2(116, 136)
const PREVIEW_SCALE := 1.45
const COLOR_INTERVAL := 1.3

var button_template: Button
var label_template: Label
var palette: Array = []

var _preview: ChameleonBody
var _balance: Label
var _cards := {}          # id -> {btn, cham, price, icon}
var _selected := ""
var _action: Button
var _color_i := 0
var _color_t := 0.0
var _t := 0.0

func build() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_constant_override("separation", 14)

	var bal_row := HBoxContainer.new()
	bal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bal_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bal_row.add_theme_constant_override("separation", 6)
	var icon := FireflyIcon.new()
	icon.custom_minimum_size = Vector2(36, 36)
	bal_row.add_child(icon)
	_balance = label_template.duplicate(0)
	_balance.add_theme_font_size_override("font_size", 32)
	bal_row.add_child(_balance)
	add_child(bal_row)

	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 170)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview = ChameleonBody.new()
	_preview.scale = Vector2.ONE * PREVIEW_SCALE
	holder.add_child(_preview)
	holder.resized.connect(func(): _preview.position = holder.size / 2.0 + Vector2(-6, 14))
	add_child(holder)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for item in Costumes.LIST:
		grid.add_child(_make_card(item))
	add_child(grid)

	_action = button_template.duplicate(0)
	_action.custom_minimum_size = Vector2(300, 64)
	_action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_action.pressed.connect(_on_action)
	add_child(_action)

func _make_card(item: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	var cham := ChameleonBody.new()
	cham.scale = Vector2.ONE * 0.62
	cham.position = Vector2(CARD_SIZE.x / 2.0 - 4.0, 60.0)
	if item["slot"] == "head":
		cham.head_item = item["id"]
	else:
		cham.acc_item = item["id"]
	b.add_child(cham)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -36.0
	row.offset_bottom = -6.0
	var icon := FireflyIcon.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.glow = false
	row.add_child(icon)
	var price: Label = label_template.duplicate(0)
	price.add_theme_font_size_override("font_size", 22)
	row.add_child(price)
	b.add_child(row)

	b.pressed.connect(_select.bind(item["id"]))
	_cards[item["id"]] = {"btn": b, "cham": cham, "price": price, "icon": icon}
	return b

# Wardrobe her açıldığında: temanın renkleri, varsayılan seçim = sıradaki hedef.
func open(p: Array) -> void:
	palette = p
	var i := 0
	for id in _cards:
		_cards[id]["cham"].skin = palette[i % palette.size()]
		i += 1
	_color_i = 0
	_preview.skin = palette[0]
	var goal := Costumes.next_goal()
	_selected = goal.get("id", "")
	_refresh()

func _select(id: String) -> void:
	_selected = id
	_refresh()

func _slot_key(item: Dictionary) -> String:
	return "equipped_head" if item["slot"] == "head" else "equipped_acc"

func _refresh() -> void:
	_balance.text = str(GameState.fireflies)
	for id in _cards:
		var it := Costumes.get_item(id)
		var c: Dictionary = _cards[id]
		var owned: bool = id in GameState.owned_costumes
		var wearing: bool = GameState.get(_slot_key(it)) == id
		var streak := Costumes.is_streak_item(it)
		c["icon"].visible = not owned and not streak
		if owned:
			c["price"].text = "Wearing" if wearing else "Owned"
		else:
			c["price"].text = "Day 7" if streak else str(it["price"])
		c["price"].modulate.a = 1.0 if owned or streak or GameState.fireflies >= it["price"] else 0.45
		_style_card(c["btn"], id == _selected, wearing)

	_preview.head_item = GameState.equipped_head
	_preview.acc_item = GameState.equipped_acc
	if _selected != "":
		var sel := Costumes.get_item(_selected)
		if sel["slot"] == "head":
			_preview.head_item = _selected
		else:
			_preview.acc_item = _selected

	_action.visible = _selected != ""
	if _selected == "":
		return
	var item := Costumes.get_item(_selected)
	var owned: bool = _selected in GameState.owned_costumes
	_action.disabled = false
	if owned:
		_action.text = "Take off" if GameState.get(_slot_key(item)) == _selected else "Wear"
	elif Costumes.is_streak_item(item):
		_action.text = "7-day streak reward"
		_action.disabled = true
	elif GameState.fireflies >= item["price"]:
		_action.text = "Buy for %d" % item["price"]
	else:
		_action.text = "%d more to go" % (item["price"] - GameState.fireflies)
		_action.disabled = true

func _style_card(b: Button, selected: bool, wearing: bool) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1, 1, 1, 0.1) if wearing else Color(0, 0, 0, 0.28)
	st.set_corner_radius_all(18)
	if selected:
		st.set_border_width_all(3)
		st.border_color = Color(1, 1, 1, 0.95)
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, st)

func _on_action() -> void:
	if _selected == "":
		return
	var item := Costumes.get_item(_selected)
	var key := _slot_key(item)
	if _selected in GameState.owned_costumes:
		GameState.set(key, "" if GameState.get(key) == _selected else _selected)
	else:
		if Costumes.is_streak_item(item) or GameState.fireflies < item["price"]:
			return
		GameState.fireflies -= item["price"]
		GameState.owned_costumes.append(_selected)
		GameState.set(key, _selected)
		Analytics.log_event("costume_purchased", {"item": _selected, "price": item["price"]})
		_celebrate()
	GameState.save_data()
	_refresh()
	equipment_changed.emit()

func _celebrate() -> void:
	_preview.scale = Vector2(1.25, 0.8) * PREVIEW_SCALE
	create_tween().tween_property(_preview, "scale", Vector2.ONE * PREVIEW_SCALE, 0.45) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if GameState.vibration_enabled:
		Input.vibrate_handheld(40)

# Önizleme hafifçe süzülür ve temanın renklerinde dolaşır — kostüm her renkte görülsün.
func _process(delta: float) -> void:
	if not is_visible_in_tree() or palette.is_empty():
		return
	_t += delta
	_preview.position.y = _preview.get_parent().size.y / 2.0 + 14.0 + sin(_t * 2.4) * 4.0
	_color_t += delta
	if _color_t >= COLOR_INTERVAL:
		_color_t = 0.0
		_color_i = (_color_i + 1) % palette.size()
		create_tween().tween_property(_preview, "skin", palette[_color_i], 0.2)
