extends Node2D

@onready var chameleon: ChameleonBody = $Chameleon
@onready var gates_container: Node2D = $Gates
@onready var score_label: Label = $UI/ScoreLabel
@onready var tutorial_label: Label = $UI/TutorialLabel
@onready var vignette: TextureRect = $UI/Vignette
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var pause_button: Button = $UI/PauseButton
@onready var pause_panel: Control = $UI/PausePanel
@onready var sound_button: Button = $UI/StartPanel/SettingsRow/SoundButton
@onready var vibe_button: Button = $UI/StartPanel/SettingsRow/VibeButton
@onready var music_button: Button = $UI/StartPanel/SettingsRow/MusicButton
@onready var settings_row: HBoxContainer = $UI/StartPanel/SettingsRow
@onready var dim_overlay: ColorRect = $UI/DimOverlay
@onready var final_score_label: Label = $UI/ResultsPanel/Top/FinalScoreLabel
@onready var high_score_label: Label = $UI/ResultsPanel/Top/HighScoreLabel
@onready var pass_sound: AudioStreamPlayer = $PassSound
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound
@onready var share_node: Share = $Share
@onready var share_button: Button = $UI/ResultsPanel/IconRow/ShareButton
@onready var streak_label: Label = $UI/ResultsPanel/Middle/StreakLabel
# oyun sonu — 1. aşama: devam teklifi
@onready var continue_panel: Control = $UI/ContinuePanel
@onready var continue_score_label: Label = $UI/ContinuePanel/Box/ContinueScoreLabel
@onready var countdown_ring: CountdownRing = $UI/ContinuePanel/Box/Countdown
@onready var countdown_number: Label = $UI/ContinuePanel/Box/Countdown/Number
@onready var continue_button: Button = $UI/ContinuePanel/Box/ContinueButton
@onready var no_thanks_button: Button = $UI/ContinuePanel/Box/NoThanksButton
# oyun sonu — 2. aşama: sonuç
@onready var results_panel: Control = $UI/ResultsPanel
@onready var results_top: VBoxContainer = $UI/ResultsPanel/Top
@onready var results_middle: VBoxContainer = $UI/ResultsPanel/Middle
@onready var best_badge: PanelContainer = $UI/ResultsPanel/Top/BestBadge
@onready var unlock_card: PanelContainer = $UI/ResultsPanel/Middle/UnlockCard
@onready var unlock_label: Label = $UI/ResultsPanel/Middle/UnlockCard/Row/UnlockLabel
@onready var unlock_swatch: Control = $UI/ResultsPanel/Middle/UnlockCard/Row/UnlockSwatch
@onready var retry_label: Label = $UI/ResultsPanel/RetryLabel
@onready var icon_row: HBoxContainer = $UI/ResultsPanel/IconRow
@onready var home_button: Button = $UI/ResultsPanel/IconRow/HomeButton
@onready var results_themes_button: Button = $UI/ResultsPanel/IconRow/ThemesButton
@onready var unlock_neon_button: Button = $UI/ThemesPanel/Box/UnlockNeonButton
@onready var start_panel: Control = $UI/StartPanel
@onready var header: VBoxContainer = $UI/StartPanel/Header
@onready var best_score_label: Label = $UI/StartPanel/Header/BestScoreLabel
@onready var streak_display_label: Label = $UI/StartPanel/Header/StreakDisplayLabel
@onready var tap_label: Label = $UI/StartPanel/TapLabel
@onready var themes_button: Button = $UI/StartPanel/ThemesButton
@onready var menu_rings: MenuRings = $UI/StartPanel/Rings
@onready var menu_chameleon: ChameleonBody = $UI/MenuChameleon
@onready var themes_panel: Control = $UI/ThemesPanel
@onready var themes_done_button: Button = $UI/ThemesPanel/Box/DoneButton
@onready var theme_swatches: Array[Button] = [
	$UI/ThemesPanel/Box/ThemeRow/ThemeBox0/ThemeSwatch0,
	$UI/ThemesPanel/Box/ThemeRow/ThemeBox1/ThemeSwatch1,
	$UI/ThemesPanel/Box/ThemeRow/ThemeBox2/ThemeSwatch2
]

var game_started = false

var theme_palettes = [
	# Classic - kirmizi / kehribar / mavi / zumrut
	[Color(0.910, 0.267, 0.263), Color(0.878, 0.659, 0.118), Color(0.235, 0.596, 0.925), Color(0.196, 0.804, 0.505)],
	# Sunset - koz kirmizisi / gun batimi turuncusu / camgobegi / menekse
	[Color(0.925, 0.259, 0.298), Color(0.980, 0.545, 0.145), Color(0.149, 0.776, 0.706), Color(0.639, 0.373, 0.816)],
	# Neon - magenta / camgobegi / lime / elektrik moru
	[Color(0.965, 0.157, 0.573), Color(0.133, 0.780, 0.780), Color(0.541, 0.831, 0.149), Color(0.612, 0.353, 0.988)],
]
var theme_names = ["Classic", "Sunset", "Neon"]

var colors: Array
var current_color_index = 0

var scroll_speed = 220.0
var min_gate_spacing = 380.0
var max_gate_spacing = 650.0
var gate_spawn_count = 0
var big_breath_interval = 10
var gate_thickness = 30.0
var chameleon_y_position = 0.0
var next_gate_y = -300.0

var score = 0
var game_over = false

# --- AdMob reklam birimi ID'leri ---
const INTERSTITIAL_ID_ANDROID := "ca-app-pub-4752797500144210/7742107229"      # gerçek (production)
const INTERSTITIAL_ID_ANDROID_TEST := "ca-app-pub-3940256099942544/1033173712"  # Google resmi test
const INTERSTITIAL_ID_IOS_TEST := "ca-app-pub-3940256099942544/4411468910"
const REWARDED_ID_ANDROID := "ca-app-pub-4752797500144210/9834321044"          # gerçek (production)
const REWARDED_ID_ANDROID_TEST := "ca-app-pub-3940256099942544/5224354917"      # Google resmi test
const REWARDED_ID_IOS_TEST := "ca-app-pub-3940256099942544/1712485313"

# --- geçiş reklamı sıklık kuralları ---
const AD_FREE_GAMES := 3          # ilk 3 oyun reklamsız
const AD_MIN_GAMES_GAP := 3       # en az bu kadar ölümde bir reklam
const AD_MIN_MSEC_GAP := 60000    # ve son reklamdan en az 60 sn sonra

var interstitial_ad: InterstitialAd
var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
var full_screen_callback := FullScreenContentCallback.new()
var rewarded_ad: RewardedAd
var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
var _rewarded_purpose := ""          # "revive" | "unlock_neon"
var _rewarded_reward_earned := false
var _rewarded_dismissed := false
var _reward_deadline := 0            # dismiss sonrası ödülü bekleme son anı (ms)
var _rewarded_active := false        # ödüllü reklam gösteriliyor / çözülmeyi bekliyor
var _rewarded_shown_msec := 0       # reklamın ekrana geldiği an
const REWARD_ASSUME_MS := 15000    # bu kadar süre izlendiyse callback gelmese de ödül ver
var _used_revive_this_run := false
var waiting_for_ad = false
var _ads_initialized := false
var _pending_restart := false
var _ad_showing := false
var last_spawned_gate: ColorRect = null
var can_restart = false

# yanlış renkli bariyer için senkron "coyote" bekleme penceresi (await yok)
var _pending_gate: ColorRect = null
var _pending_deadline := 0
const COYOTE_MS := 90

# revive sonrası kısa dokunulmazlık
var _revive_grace_until := 0

var _swatches_connected := false

# --- juice / oyun hissi ---
var _shake := 0.0
var _idle_t := 0.0
var _cham_home := Vector2.ZERO
var _death_flash: ColorRect = null

# --- başlangıç ekranı (menü) ---
const MENU_CHAM_SCALE := 1.5
const MENU_COLOR_INTERVAL := 1.2   # menüdeki bukalemunun renk değiştirme aralığı (sn)
var _menu_center := Vector2.ZERO
var _menu_t := 0.0
var _menu_color_t := 0.0
var _menu_color_index := 0
var _starting := false             # menüden oyuna geçiş animasyonu sürüyor

# --- oyun sonu ekranı ---
const CONTINUE_SECONDS := 5.0
var _go_stage := ""                 # "" | "continue" | "results"
var _continue_left := 0.0
var _continue_ad_pending := false   # "Continue"a basıldı, ödüllü reklamın çözülmesi bekleniyor
var _run_start_best := 0            # bu koşu başlarken kayıtlı en iyi skor ("New best" karşılaştırması)
var _newly_unlocked := -1
var _results_gen := 0
var _run_start_msec := 0            # analitik: koşu süresi (revive dahil)

# --- ilk oyun öğreticisi ---
const TUTORIAL_GATES := [0, 1, 2]     # 1. kapı bukalemunla aynı renk, sonrakiler birer dokunuş
const TUTORIAL_FREEZE_GAP := 240.0     # renk tutmazsa kapı bukalemunun bu kadar üstünde bekler
var _tutorial_active := false
var _tutorial_spawned := 0
var _tutorial_passed := 0
var _tutorial_msg_until := 0           # "Nice! Keep going" mesajının kalkacağı an (ms)

func _ready():
	colors = theme_palettes[GameState.active_theme]
	var screen_size = get_viewport_rect().size
	share_button.pressed.connect(_on_share_pressed)
	interstitial_ad_load_callback.on_ad_failed_to_load = _on_interstitial_failed
	interstitial_ad_load_callback.on_ad_loaded = _on_interstitial_loaded
	full_screen_callback.on_ad_dismissed_full_screen_content = _on_ad_dismissed
	full_screen_callback.on_ad_showed_full_screen_content = _on_ad_shown
	full_screen_callback.on_ad_failed_to_show_full_screen_content = _on_ad_failed_to_show
	rewarded_ad_load_callback.on_ad_loaded = _on_rewarded_loaded
	rewarded_ad_load_callback.on_ad_failed_to_load = _on_rewarded_failed
	continue_button.pressed.connect(_on_continue_pressed)
	no_thanks_button.pressed.connect(_show_results)
	home_button.pressed.connect(_on_home_pressed)
	results_themes_button.pressed.connect(_open_themes)
	unlock_neon_button.pressed.connect(_on_unlock_neon_pressed)
	_setup_ads()

	_apply_safe_area()

	dim_overlay.visible = false
	continue_panel.visible = false
	results_panel.visible = false
	chameleon.position = Vector2(screen_size.x / 2.0, screen_size.y * 0.75)
	chameleon_y_position = chameleon.position.y
	_cham_home = chameleon.position
	update_chameleon_color(colors[current_color_index], false)

	_death_flash = ColorRect.new()
	_death_flash.name = "DeathFlash"
	_death_flash.color = Color(0.92, 0.12, 0.12, 0.0)
	_death_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_death_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(_death_flash)
	$UI.move_child(_death_flash, dim_overlay.get_index() + 1)

	start_panel.gui_input.connect(_on_start_panel_input)
	themes_button.pressed.connect(_open_themes)
	themes_done_button.pressed.connect(_close_themes)
	themes_panel.gui_input.connect(_on_themes_panel_input)
	get_viewport().size_changed.connect(_layout_menu)
	_start_tap_pulse(tap_label)
	_start_tap_pulse(retry_label)
	_start_tap_pulse(tutorial_label)

	sound_button.pressed.connect(_on_sound_toggled)
	vibe_button.pressed.connect(_on_vibe_toggled)
	music_button.pressed.connect(_on_music_toggled)
	pause_button.pressed.connect(_on_pause_pressed)
	pause_panel.get_node("Box/ResumeButton").pressed.connect(_on_resume_pressed)
	pause_panel.get_node("Box/MenuButton").pressed.connect(_on_pause_menu_pressed)
	_refresh_settings_ui()
	if music_player.stream:
		music_player.stream.loop = true
	_apply_music()

	_show_menu()

func spawn_gate(y_pos: float):
	var gate = ColorRect.new()
	var screen_width = get_viewport_rect().size.x
	gate.size = Vector2(screen_width, gate_thickness)
	gate.position = Vector2(0, y_pos)
	var gate_color_index = randi() % colors.size()
	var is_tutorial_gate := _tutorial_active and _tutorial_spawned < TUTORIAL_GATES.size()
	if is_tutorial_gate:
		gate_color_index = TUTORIAL_GATES[_tutorial_spawned] % colors.size()
		_tutorial_spawned += 1
	gate.color = colors[gate_color_index]
	gate.set_meta("color_index", gate_color_index)
	gate.set_meta("passed", false)
	gate.set_meta("tutorial", is_tutorial_gate)
	gates_container.add_child(gate)

	var highlight = ColorRect.new()
	highlight.size = Vector2(gate.size.x, 6)
	highlight.position = Vector2(0, 0)
	highlight.color = Color(1, 1, 1, 0.3)
	gate.add_child(highlight)

	# alt kenara ince koyu şerit -> parlak renkli bar'lar arka planda daha net durur
	var shade = ColorRect.new()
	shade.size = Vector2(gate.size.x, 4)
	shade.position = Vector2(0, gate_thickness - 4)
	shade.color = Color(0, 0, 0, 0.25)
	gate.add_child(shade)

	last_spawned_gate = gate
	
func _process(delta):
	_update_juice(delta)
	_update_menu(delta)
	_update_continue(delta)
	if _rewarded_active:
		_try_resolve_rewarded()   # dismiss sonrası ödül bekleme süresini kontrol et
	if not game_started or game_over:
		return

	_resolve_pending_gate()

	# öğretici kapısı yaklaştı ama renk tutmuyorsa kapılar bekler (ilk oyunda ölmek imkânsız)
	_update_tutorial_label()
	var move: float = 0.0 if _tutorial_gate_blocked() else scroll_speed * delta
	next_gate_y += move
	for gate in gates_container.get_children():
		gate.position.y += move

		if not gate.get_meta("passed") and gate.position.y + gate_thickness >= chameleon_y_position:
			gate.set_meta("passed", true)
			check_gate_collision(gate)

		if gate.position.y > get_viewport_rect().size.y + 100:
			gate.queue_free()
	
	if not is_instance_valid(last_spawned_gate) or last_spawned_gate.position.y > -1400.0:
		spawn_gate(next_gate_y)
		next_gate_y -= get_next_spacing()
	
	

func _update_juice(delta):
	var shake_off := Vector2.ZERO
	if _shake > 0.01:
		_shake = max(0.0, _shake - delta * 45.0)
		shake_off = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	gates_container.position = shake_off

	var bob := 0.0
	if game_started and not game_over:
		_idle_t += delta
		bob = sin(_idle_t * 3.2) * 2.0
		var sr: float = clamp((scroll_speed - 220.0) / 260.0, 0.0, 1.0)
		vignette.self_modulate.a = 1.0 + sr * 0.5
	chameleon.position = _cham_home + shake_off + Vector2(0.0, bob)

	# revive sonrası dokunulmazlık: bukalemun yanıp söner ("geri döndün, kısa süre güvendesin")
	if Time.get_ticks_msec() < _revive_grace_until:
		chameleon.modulate.a = 0.35 + 0.65 * abs(sin(Time.get_ticks_msec() * 0.018))
	elif chameleon.modulate.a != 1.0:
		chameleon.modulate.a = 1.0

func _squash(node: Node2D, amount: Vector2) -> void:
	node.scale = amount
	create_tween().tween_property(node, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _pop_label(lbl: Label, s: float) -> void:
	lbl.pivot_offset = lbl.size / 2
	lbl.scale = Vector2(s, s)
	create_tween().tween_property(lbl, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _flash_gate(gate: ColorRect) -> void:
	if not is_instance_valid(gate):
		return
	gate.modulate = Color(1.9, 1.9, 1.9, 1.0)
	create_tween().tween_property(gate, "modulate", Color(1, 1, 1, 1), 0.25)

func _play_death_juice() -> void:
	_shake = 17.0
	if _death_flash:
		_death_flash.color.a = 0.0
		var ft := create_tween()
		ft.tween_property(_death_flash, "color:a", 0.2, 0.04)
		ft.tween_property(_death_flash, "color:a", 0.0, 0.26)
	var ct := create_tween()
	ct.set_parallel(true)
	ct.tween_property(chameleon, "scale", Vector2(0.1, 0.1), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	ct.tween_property(chameleon, "rotation", chameleon.rotation + 1.3, 0.35)
	# küçülen bukalemun ekranın ortasında leke gibi kalmasın
	ct.chain().tween_callback(func(): if game_over: chameleon.visible = false)

func check_gate_collision(gate: ColorRect):
	if Time.get_ticks_msec() < _revive_grace_until:
		return   # revive sonrası kısa dokunulmazlık: bariyer zararsız geçer
	if gate.get_meta("color_index") == current_color_index:
		_award_pass(gate)
	else:
		# yanlış renk: geç dokunuşa küçük tolerans tanı (senkron, _process'te çözülür)
		_pending_gate = gate
		_pending_deadline = Time.get_ticks_msec() + COYOTE_MS

func _resolve_pending_gate() -> void:
	if _pending_gate == null:
		return
	if Time.get_ticks_msec() < _revive_grace_until:
		_pending_gate = null
		return
	if not is_instance_valid(_pending_gate):
		_pending_gate = null
		return
	if _pending_gate.get_meta("color_index") == current_color_index:
		# oyuncu zamanında rengi düzeltti
		var g := _pending_gate
		_pending_gate = null
		_award_pass(g)
	elif Time.get_ticks_msec() >= _pending_deadline:
		_pending_gate = null
		end_game()

func _award_pass(gate: ColorRect):
	score += 1
	score_label.text = str(score)
	scroll_speed = 220.0 + min(score * 6.0, 260.0)
	pass_sound.pitch_scale = 1.0 + min(score * 0.02, 0.5)
	if GameState.sound_enabled:
		pass_sound.play()
	_vibrate(20)
	var milestone: bool = score % 10 == 0
	_pop_label(score_label, 1.5 if milestone else 1.22)
	_flash_gate(gate)
	if milestone:
		_shake = 6.0
		score_label.modulate = Color(1.5, 1.25, 0.35)
		create_tween().tween_property(score_label, "modulate", Color(1, 1, 1, 1), 0.45)
	if gate.get_meta("tutorial", false):
		_tutorial_passed += 1
		if _tutorial_passed >= TUTORIAL_GATES.size():
			_finish_tutorial()

func update_chameleon_color(new_color: Color, animate: bool = true):
	if animate:
		create_tween().tween_property(chameleon, "skin", new_color, 0.15)
		_squash(chameleon, Vector2(1.18, 0.82))
	else:
		chameleon.skin = new_color

func _unhandled_input(event):
	if not game_started:
		return
	var touched = false
	if event is InputEventScreenTouch and event.pressed:
		touched = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		touched = true

	if not touched:
		return

	if game_over:
		if waiting_for_ad or not can_restart:
			return
		if _should_show_interstitial():
			_show_interstitial_then_restart()
		else:
			restart_run()
	else:
		current_color_index = (current_color_index + 1) % colors.size()
		update_chameleon_color(colors[current_color_index])

func end_game():
	game_over = true
	can_restart = false
	if GameState.sound_enabled:
		game_over_sound.play()
	_vibrate(70)
	score_label.visible = false
	pause_button.visible = false
	_hide_tutorial()
	_play_death_juice()

	# revive sonrası ikinci ölümde de gösterilebilsin diye koşu boyunca birikir
	if score >= 15 and 1 not in GameState.unlocked_themes:
		if GameState.unlock_theme(1):
			_newly_unlocked = 1
			Analytics.log_event("theme_unlocked", {"theme": theme_names[1], "source": "score"})
	if GameState.daily_streak >= 3 and 2 not in GameState.unlocked_themes:
		if GameState.unlock_theme(2):
			_newly_unlocked = 2
			Analytics.log_event("theme_unlocked", {"theme": theme_names[2], "source": "streak"})

	Analytics.log_event("game_over", {
		"score": score,
		"duration_sec": int(float(Time.get_ticks_msec() - _run_start_msec) / 1000.0),
		"revived": 1 if _used_revive_this_run else 0,
	})

	if score > GameState.high_score:
		GameState.high_score = score
		GameState.save_data()

	GameState.game_over_count += 1
	GameState.games_since_ad += 1
	GameState.save_data()

	dim_overlay.visible = true
	dim_overlay.modulate.a = 0.0
	create_tween().tween_property(dim_overlay, "modulate:a", 1.0, 0.25)

	# 1. aşama: "reklam izle, devam et" — koşu başına bir kez, reklam hazırsa.
	# Yoksa doğrudan sonuç ekranı.
	if rewarded_ready() and not _used_revive_this_run:
		_show_continue()
	else:
		_show_results()

# ------------------------------------------------------------------ oyun sonu ekranı

func _show_continue() -> void:
	_go_stage = "continue"
	can_restart = false
	_continue_left = CONTINUE_SECONDS
	_continue_ad_pending = false
	continue_score_label.text = str(score)
	continue_button.disabled = false
	countdown_ring.progress = 1.0
	countdown_number.text = str(int(CONTINUE_SECONDS))
	results_panel.visible = false
	continue_panel.visible = true
	continue_panel.modulate.a = 0.0
	Analytics.log_event("revive_offered", {"score": score})
	# ölüm animasyonu okunabilsin diye kısa bir gecikmeyle belirir
	create_tween().tween_property(continue_panel, "modulate:a", 1.0, 0.2).set_delay(0.2)

# Geri sayım; "Continue"a basıldıysa reklamın çözülmesini bekler. Reklam ödülsüz
# kapandıysa ya da hiç açılamadıysa (_rewarded_active düşer ama oyun hâlâ bitik)
# sonuç ekranına geçer. Ödül verildiyse _revive() zaten aşamayı temizlemiştir.
func _update_continue(delta: float) -> void:
	if _go_stage != "continue":
		return
	if _continue_ad_pending:
		if not _rewarded_active:
			_continue_ad_pending = false
			if game_over:
				_show_results()
		return
	_continue_left -= delta
	countdown_ring.progress = maxf(0.0, _continue_left / CONTINUE_SECONDS)
	countdown_number.text = str(maxi(1, ceili(_continue_left)))
	if _continue_left <= 0.0:
		_show_results()

func _on_continue_pressed() -> void:
	if not game_over or _used_revive_this_run or _go_stage != "continue" or _continue_ad_pending:
		return
	_continue_ad_pending = true
	continue_button.disabled = true
	Analytics.log_event("revive_accepted", {"score": score})
	_show_rewarded("revive")

func _show_results() -> void:
	if not game_over or _go_stage == "results":
		return
	_go_stage = "results"
	can_restart = false
	continue_panel.visible = false

	var is_new_best: bool = score > _run_start_best and score > 0
	var gap: int = _run_start_best - score
	if is_new_best:
		Analytics.log_event("new_best", {"score": score, "previous_best": _run_start_best})
	best_badge.visible = is_new_best
	high_score_label.visible = not is_new_best and GameState.high_score > 0
	if gap == 0:
		high_score_label.text = "Tied your best!"
	elif gap > 0 and gap <= 5:
		high_score_label.text = "%d away from your best" % gap
	else:
		high_score_label.text = "Best: " + str(GameState.high_score)

	unlock_card.visible = _newly_unlocked >= 0
	if _newly_unlocked >= 0:
		unlock_label.text = theme_names[_newly_unlocked] + " unlocked!"
		_fill_mini_swatch(unlock_swatch, theme_palettes[_newly_unlocked])
	streak_label.text = "🔥 " + str(GameState.daily_streak) + " day streak"
	streak_label.visible = GameState.daily_streak >= 2

	results_panel.visible = true
	results_panel.modulate.a = 0.0
	create_tween().tween_property(results_panel, "modulate:a", 1.0, 0.25)

	# skor sayarak yükselir; yeni rekorsa rozet sonra zıplayarak gelir
	final_score_label.text = "0"
	if score > 0:
		create_tween().tween_method(
			func(v: float): final_score_label.text = str(int(round(v))),
			0.0, float(score), clampf(0.25 + score * 0.02, 0.35, 0.8)
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_new_best:
		best_badge.scale = Vector2.ZERO
		var bt := create_tween()
		bt.tween_interval(0.55)
		bt.tween_callback(func():
			best_badge.pivot_offset = best_badge.size / 2.0
			_vibrate(30))
		bt.tween_property(best_badge, "scale", Vector2.ONE, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# yanlışlıkla anında yeniden başlamayı önle
	_results_gen += 1
	var gen := _results_gen
	await get_tree().create_timer(0.45).timeout
	if gen == _results_gen and _go_stage == "results":
		can_restart = true

func _fill_mini_swatch(holder: Control, palette: Array) -> void:
	if holder.get_child_count() == 0:
		for i in 4:
			var cell := ColorRect.new()
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.anchor_left = (i % 2) * 0.5
			cell.anchor_top = int(i / 2) * 0.5
			cell.anchor_right = cell.anchor_left + 0.5
			cell.anchor_bottom = cell.anchor_top + 0.5
			holder.add_child(cell)
	for i in 4:
		(holder.get_child(i) as ColorRect).color = palette[i]

func _hide_game_over_ui() -> void:
	_go_stage = ""
	_continue_ad_pending = false
	_results_gen += 1
	dim_overlay.visible = false
	continue_panel.visible = false
	results_panel.visible = false
	themes_panel.visible = false

func _on_home_pressed() -> void:
	if waiting_for_ad or _rewarded_active:
		return
	_return_to_menu()

# --- Reklam kurulumu: önce UMP consent, sonra MobileAds.initialize() ---

func _setup_ads() -> void:
	# Mobil dışında (editör/masaüstü) consent akışı yok; mock reklamlarla test için
	# doğrudan başlat. Editörde addon mock plugin'leri devreye girer, cihaz dışı
	# release'de _get_plugin null döner ve yükleyiciler sessizce no-op olur.
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		_initialize_ads()
		return
	_request_consent()

func _request_consent() -> void:
	var request := ConsentRequestParameters.new()
	# Debug build'de AEA bölgesini taklit ederek consent formunu test cihazında görebilirsin.
	if OS.is_debug_build():
		var debug_settings := ConsentDebugSettings.new()
		debug_settings.debug_geography = DebugGeography.Values.EEA
		# Test cihazları (logcat'teki addTestDeviceHashedId değeri):
		debug_settings.test_device_hashed_ids.append("0A19F3B168FC5DE628D41FE1E5BB333B")
		debug_settings.test_device_hashed_ids.append("D5B8A059081C01DFD1A8E0E2401DBAC3")
		request.consent_debug_settings = debug_settings
	UserMessagingPlatform.consent_information.update(
		request, _on_consent_info_updated, _on_consent_info_failed
	)

func _on_consent_info_updated() -> void:
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_consent_form_loaded, _on_consent_form_failed)
	else:
		_initialize_ads()

func _on_consent_info_failed(_error: FormError) -> void:
	# İzin bilgisi alınamadı: yine de başlat, Google mevcut duruma göre reklam sunar.
	_initialize_ads()

func _on_consent_form_loaded(form: ConsentForm) -> void:
	if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		form.show(_on_consent_form_dismissed)
	else:
		_initialize_ads()

func _on_consent_form_failed(_error: FormError) -> void:
	_initialize_ads()

func _on_consent_form_dismissed(_error: FormError) -> void:
	_initialize_ads()

func _initialize_ads() -> void:
	_apply_analytics_consent()
	if _ads_initialized:
		return
	_ads_initialized = true
	MobileAds.initialize()
	var conf := RequestConfiguration.new()
	# Test cihazları (logcat'teki setTestDeviceIds değeri) — release build'de bile test reklamı gösterir:
	conf.test_device_ids = ["0A19F3B168FC5DE628D41FE1E5BB333B", "D5B8A059081C01DFD1A8E0E2401DBAC3"]
	MobileAds.set_request_configuration(conf)
	await get_tree().create_timer(0.1).timeout
	load_interstitial_ad()
	load_rewarded_ad()

# UMP akışı her yoldan _initialize_ads()'e çıkar; analitik onayını da burada
# netleştiriyoruz. UMP kullanıcının hangi amaçlara izin verdiğini Godot'a ayrıntılı
# vermediği için onay gerektiren bölgelerde (AB/İngiltere) analitik kapalı kalır.
func _apply_analytics_consent() -> void:
	if OS.get_name() != "Android":
		return
	if OS.is_debug_build():
		# test cihazlarında AB simülasyonu açık; DebugView ile test edilebilsin diye
		Analytics.set_consent(true)
		return
	match UserMessagingPlatform.consent_information.get_consent_status():
		ConsentInformation.ConsentStatus.NOT_REQUIRED:
			Analytics.set_consent(true)
		ConsentInformation.ConsentStatus.REQUIRED, ConsentInformation.ConsentStatus.OBTAINED:
			Analytics.set_consent(false)
		_:
			pass   # UNKNOWN (ör. çevrimdışı): önceki açılıştaki kalıcı tercih geçerli kalsın

func _get_interstitial_unit_id() -> String:
	if OS.get_name() == "Android":
		return INTERSTITIAL_ID_ANDROID_TEST if OS.is_debug_build() else INTERSTITIAL_ID_ANDROID
	# iOS şu an kapalı; gerçek iOS ID alınca burada da debug/release ayrımı yap.
	return INTERSTITIAL_ID_IOS_TEST

func load_interstitial_ad():
	InterstitialAdLoader.new().load(_get_interstitial_unit_id(), AdRequest.new(), interstitial_ad_load_callback)

func _on_interstitial_failed(ad_error: LoadAdError):
	pass

func _on_interstitial_loaded(ad: InterstitialAd):
	interstitial_ad = ad
	interstitial_ad.full_screen_content_callback = full_screen_callback

# --- geçiş reklamı: yalnızca "tekrar dene" dokunuşunda ---

func _should_show_interstitial() -> bool:
	if interstitial_ad == null:
		return false
	if GameState.game_over_count <= AD_FREE_GAMES:
		return false
	if GameState.games_since_ad < AD_MIN_GAMES_GAP:
		return false
	if Time.get_ticks_msec() - GameState.last_ad_msec < AD_MIN_MSEC_GAP:
		return false
	return true

func _show_interstitial_then_restart() -> void:
	waiting_for_ad = true
	_pending_restart = true
	_ad_showing = false
	GameState.last_ad_msec = Time.get_ticks_msec()
	GameState.games_since_ad = 0
	interstitial_ad.show()   # referansı burada null'lama — callback'ler için canlı tut
	_start_ad_safety_timeout()

func _do_pending_restart() -> void:
	if not _pending_restart:
		return
	_pending_restart = false
	waiting_for_ad = false
	music_player.stream_paused = false
	interstitial_ad = null
	load_interstitial_ad()   # bir sonrakini hazırla (sahne yeniden yüklenmiyor)
	restart_run()

func _on_ad_shown() -> void:
	_ad_showing = true
	music_player.stream_paused = true

func _on_ad_dismissed() -> void:
	waiting_for_ad = false
	_do_pending_restart()

func _on_ad_failed_to_show(_error: AdError) -> void:
	_ad_showing = false
	_do_pending_restart()

func _start_ad_safety_timeout() -> void:
	# Reklam birkaç saniyede açılmadıysa bir şey ters gitti; oyuncuyu bekletme.
	await get_tree().create_timer(4.0).timeout
	if waiting_for_ad and not _ad_showing:
		_do_pending_restart()

# --- ödüllü reklam (revive + Neon teması açma) ---

func _apply_safe_area() -> void:
	# Çentikli / delik kameralı telefonlarda üst UI'yi status bar'ın altına it.
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if win.y <= 0:
		return
	var scale_y: float = get_viewport_rect().size.y / float(win.y)
	var top_inset: float = float(safe.position.y) * scale_y
	var bottom_inset: float = maxf(0.0, float(win.y - safe.end.y) * scale_y)
	if top_inset > 0.0:
		for c: Control in [score_label, pause_button, header, settings_row, results_top, results_middle]:
			c.offset_top += top_inset
			c.offset_bottom += top_inset
	if bottom_inset > 0.0:
		for c: Control in [tap_label, themes_button, retry_label, icon_row]:
			c.offset_top -= bottom_inset
			c.offset_bottom -= bottom_inset

func _get_rewarded_unit_id() -> String:
	if OS.get_name() == "Android":
		return REWARDED_ID_ANDROID_TEST if OS.is_debug_build() else REWARDED_ID_ANDROID
	return REWARDED_ID_IOS_TEST

func load_rewarded_ad() -> void:
	RewardedAdLoader.new().load(_get_rewarded_unit_id(), AdRequest.new(), rewarded_ad_load_callback)

func _on_rewarded_loaded(ad: RewardedAd) -> void:
	rewarded_ad = ad
	rewarded_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = _on_rewarded_dismissed
	rewarded_ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = _on_rewarded_failed_to_show
	rewarded_ad.full_screen_content_callback.on_ad_showed_full_screen_content = _on_rewarded_shown
	if start_panel.visible:
		_refresh_unlock_neon_button()

func _on_rewarded_shown() -> void:
	_rewarded_shown_msec = Time.get_ticks_msec()
	music_player.stream_paused = true

func _on_rewarded_failed(_error: LoadAdError) -> void:
	rewarded_ad = null

func rewarded_ready() -> bool:
	return rewarded_ad != null

func _show_rewarded(purpose: String) -> void:
	if rewarded_ad == null or _rewarded_active or waiting_for_ad:
		return
	_rewarded_purpose = purpose
	_rewarded_reward_earned = false
	_rewarded_dismissed = false
	_reward_deadline = 0
	_rewarded_shown_msec = 0
	_rewarded_active = true
	waiting_for_ad = true
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = _on_reward_earned
	rewarded_ad.show(listener)   # referansı burada null'lama — callback'ler için canlı tut
	_start_rewarded_safety_timeout()

# onUserEarnedReward, onAdDismissed'dan ÖNCE ya da SONRA gelebilir (AdMob dokümanı).
# Sıraya/kareye güvenme: her iki sinyali de kaydet, kararı _try_resolve_rewarded ver.
func _on_reward_earned(_item) -> void:
	_rewarded_reward_earned = true
	_try_resolve_rewarded()

func _on_rewarded_dismissed() -> void:
	_rewarded_dismissed = true
	# ödül callback'i dismiss'ten birkaç saniye sonra gelebilir (özellikle release'de).
	# O yüzden hemen "ödülsüz" kapatma; kısa bir süre bekle.
	if _reward_deadline == 0:
		_reward_deadline = Time.get_ticks_msec() + 2500
	_try_resolve_rewarded()

func _on_rewarded_failed_to_show(_error: AdError) -> void:
	_rewarded_dismissed = true
	_reward_deadline = Time.get_ticks_msec()   # hemen çöz (ödülsüz)
	_try_resolve_rewarded()

func _notification(what: int) -> void:
	# Uygulama arka plana alınır alınmaz (tam ekran reklam da bunu tetikler) müziği
	# duraklat; reklam kapanıp öne dönünce kaldığı yerden devam ettir.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		music_player.stream_paused = true
		return

	# Tam ekran reklam kapandığında uygulama tekrar öne gelir (pencere fokusu döner).
	# Bu, plugin'in dismiss callback'i gelmese bile güvenilir "reklam bitti" sinyali;
	# ve reklam AÇIKKEN asla tetiklenmez (o sırada fokus bizde değil).
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		music_player.stream_paused = false
		if _rewarded_active:
			_rewarded_dismissed = true
			if _reward_deadline == 0:
				_reward_deadline = Time.get_ticks_msec() + 2500
			_try_resolve_rewarded()

func _start_rewarded_safety_timeout() -> void:
	# Son çare: reklam kapandı ama hiçbir sinyal gelmediyse UI'yi kilitli bırakma.
	# Yalnızca pencere fokusu bizdeyken (yani reklam artık EKRANDA DEĞİLKEN) çöz —
	# uzun playable reklam sürerken erken tetiklenmesin.
	await get_tree().create_timer(120.0).timeout
	if _rewarded_active and get_window().has_focus():
		_rewarded_dismissed = true
		_reward_deadline = Time.get_ticks_msec()
		_try_resolve_rewarded()

# Çözülme koşulu: ödül geldi, VEYA reklam kapandı ve bekleme süresi doldu.
# _process her karede çağırır (bekleme süresini kontrol etmek için).
func _try_resolve_rewarded() -> void:
	if not _rewarded_active:
		return
	# Reklam ekrandan GİTMEDEN oyunu devam ettirme. onUserEarnedReward reklam
	# sürerken gelebilir; o an çözersek oyun reklamın arkasında akmaya başlar.
	if not _rewarded_dismissed:
		return
	# dismiss geldi: ödül geldiyse hemen çöz; gelmediyse kısa süre bekle, sonra ödülsüz çöz.
	var deadline_passed: bool = _reward_deadline > 0 and Time.get_ticks_msec() >= _reward_deadline
	if not _rewarded_reward_earned and not deadline_passed:
		return
	# Yedek: bazı kreatifler onUserEarnedReward tetiklemiyor. Reklam yeterince
	# uzun süre ekranda kaldıysa (izlendiyse) callback gelmese de ödülü ver.
	var watched_long_enough: bool = _rewarded_shown_msec > 0 \
		and Time.get_ticks_msec() - _rewarded_shown_msec >= REWARD_ASSUME_MS
	_rewarded_active = false
	waiting_for_ad = false
	music_player.stream_paused = false
	var purpose := _rewarded_purpose
	var earned: bool = _rewarded_reward_earned or watched_long_enough
	_rewarded_purpose = ""
	_rewarded_reward_earned = false
	_rewarded_dismissed = false
	_reward_deadline = 0
	rewarded_ad = null
	load_rewarded_ad()   # bir sonrakini hazırla
	if earned:
		_grant_reward(purpose)

func _grant_reward(purpose: String) -> void:
	match purpose:
		"revive":
			_revive()
		"unlock_neon":
			if GameState.unlock_theme(2):
				Analytics.log_event("theme_unlocked", {"theme": theme_names[2], "source": "ad"})
			setup_start_panel()

func _refresh_unlock_neon_button() -> void:
	var neon_locked: bool = 2 not in GameState.unlocked_themes
	unlock_neon_button.visible = neon_locked and rewarded_ready()

func _on_unlock_neon_pressed() -> void:
	if 2 in GameState.unlocked_themes:
		unlock_neon_button.visible = false
		return
	_show_rewarded("unlock_neon")

func _revive() -> void:
	Analytics.log_event("revive_granted", {"score": score})
	_used_revive_this_run = true
	_vibrate(15)
	_reset_field(true)
	can_restart = true
	_revive_grace_until = Time.get_ticks_msec() + 1800   # ~1.8 sn dokunulmazlık
	# "geri döndün" geri bildirimi
	_pop_label(score_label, 1.4)
	_shake = 5.0

func _on_share_pressed():
	if share_node == null or not share_node.has_method("share_image"):
		return
	Analytics.log_event("share", {"content_type": "score", "score": score})
	await get_tree().process_frame
	var img = get_viewport().get_texture().get_image()
	var save_path = OS.get_user_data_dir() + "/share_score.png"
	img.save_png(save_path)
	share_node.share_image(
		save_path,
		"My Chameleon Dash Score",
		"Chameleon Dash",
		"I scored " + str(score) + " in Chameleon Dash! Can you beat me?"
	)
	
func get_next_spacing() -> float:
	gate_spawn_count += 1
	if gate_spawn_count % big_breath_interval == 0:
		return randf_range(900.0, 1100.0)
	else:
		return randf_range(min_gate_spacing, max_gate_spacing)
		
func setup_start_panel():
	
	check_retroactive_unlocks()
	best_score_label.text = "Best: " + str(GameState.high_score)
	streak_display_label.text = "🔥 " + str(GameState.daily_streak) + " day streak"
	# yeni oyuncuya "Best: 0" / "1 day streak" gibi boş bilgileri gösterme
	best_score_label.visible = GameState.high_score > 0
	streak_display_label.visible = GameState.daily_streak >= 2
	# temalar ilk oyundan sonra (ya da ikinci tema açıldıysa) görünür
	themes_button.visible = GameState.game_over_count > 0 or GameState.unlocked_themes.size() > 1

	var theme_label_paths = [
		"Box/ThemeRow/ThemeBox0/ThemeLabel0",
		"Box/ThemeRow/ThemeBox1/ThemeLabel1",
		"Box/ThemeRow/ThemeBox2/ThemeLabel2"
	]
	for i in range(theme_swatches.size()):
		var swatch = theme_swatches[i]
		if not _swatches_connected:
			swatch.pressed.connect(_on_swatch_pressed.bind(i))
		update_swatch_visual(swatch, i)
		var label = themes_panel.get_node(theme_label_paths[i])
		label.text = theme_names[i]
	_swatches_connected = true
	_refresh_unlock_neon_button()
	_refresh_menu_hero()

func update_swatch_visual(swatch: Button, index: int):
	var is_unlocked = index in GameState.unlocked_themes
	var palette = theme_palettes[index]

	# yuvarlatılmış koyu zemin (renk ızgarasının altında, sadece köşelerde görünür)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	for s in ["normal", "hover", "pressed", "focus"]:
		swatch.add_theme_stylebox_override(s, style)
	swatch.clip_contents = true
	swatch.text = ""

	# temanın 4 rengini 2x2 önizleme olarak göster; dış köşeler halkayla uyumlu yuvarlak
	var cell_radius := 12
	var grid := swatch.get_node_or_null("Swatch4") as Control
	if grid == null:
		grid = Control.new()
		grid.name = "Swatch4"
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		grid.offset_left = 3.0
		grid.offset_top = 3.0
		grid.offset_right = -3.0
		grid.offset_bottom = -3.0
		swatch.add_child(grid)
		for i in 4:
			var cell := Panel.new()
			cell.name = "C%d" % i
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var col := i % 2
			var row := int(i / 2)
			cell.anchor_left = col * 0.5
			cell.anchor_top = row * 0.5
			cell.anchor_right = col * 0.5 + 0.5
			cell.anchor_bottom = row * 0.5 + 0.5
			cell.offset_left = 0.0
			cell.offset_top = 0.0
			cell.offset_right = 0.0
			cell.offset_bottom = 0.0
			grid.add_child(cell)
	for i in 4:
		var cell := grid.get_node("C%d" % i) as Panel
		var c: Color = palette[i]
		var cs := StyleBoxFlat.new()
		cs.bg_color = c if is_unlocked else c.darkened(0.55)
		cs.corner_radius_top_left = cell_radius if i == 0 else 0
		cs.corner_radius_top_right = cell_radius if i == 1 else 0
		cs.corner_radius_bottom_left = cell_radius if i == 2 else 0
		cs.corner_radius_bottom_right = cell_radius if i == 3 else 0
		cell.add_theme_stylebox_override("panel", cs)

	# kilitliyse üstte kilit simgesi
	var lock := swatch.get_node_or_null("LockLabel") as Label
	if lock == null:
		lock = Label.new()
		lock.name = "LockLabel"
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		swatch.add_child(lock)
	lock.text = "🔒" if not is_unlocked else ""

	# seçili temada beyaz halka — renk ızgarasının ÜSTÜNDE çizilir ki kapanmasın
	var ring := swatch.get_node_or_null("SelRing") as Panel
	if ring == null:
		ring = Panel.new()
		ring.name = "SelRing"
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		swatch.add_child(ring)
	swatch.move_child(ring, swatch.get_child_count() - 1)
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0, 0, 0, 0)
	ring_style.border_width_left = 4
	ring_style.border_width_right = 4
	ring_style.border_width_top = 4
	ring_style.border_width_bottom = 4
	ring_style.border_color = Color(1, 1, 1, 1)
	ring_style.corner_radius_top_left = 16
	ring_style.corner_radius_top_right = 16
	ring_style.corner_radius_bottom_left = 16
	ring_style.corner_radius_bottom_right = 16
	ring.add_theme_stylebox_override("panel", ring_style)
	ring.visible = (index == GameState.active_theme)

func _on_swatch_pressed(index: int):
	if index not in GameState.unlocked_themes:
		# kilitli Neon'a dokunulduysa ve ödüllü reklam hazırsa: aç teklifini göster
		if index == 2 and rewarded_ready():
			_show_rewarded("unlock_neon")
		return
	GameState.active_theme = index
	GameState.save_data()
	Analytics.log_event("theme_selected", {"theme": theme_names[index]})
	colors = theme_palettes[index]
	for i in range(theme_swatches.size()):
		update_swatch_visual(theme_swatches[i], i)
	_refresh_menu_hero()
	update_chameleon_color(colors[current_color_index], false)

func start_game():
	game_started = true
	_used_revive_this_run = false
	_run_start_best = GameState.high_score
	_newly_unlocked = -1
	_run_start_msec = Time.get_ticks_msec()
	start_panel.visible = false
	pause_button.visible = true
	score_label.text = str(score)
	score_label.visible = true
	_apply_music()
	_begin_tutorial()

	while not is_instance_valid(last_spawned_gate) or last_spawned_gate.position.y > -2600.0:
		spawn_gate(next_gate_y)
		next_gate_y -= get_next_spacing()

func restart_run():
	_used_revive_this_run = false
	_run_start_best = GameState.high_score
	_newly_unlocked = -1
	_run_start_msec = Time.get_ticks_msec()
	_begin_tutorial()
	_reset_field(false)

# ------------------------------------------------------------------ ilk oyun öğreticisi

func _begin_tutorial() -> void:
	_tutorial_active = not GameState.tutorial_done
	_tutorial_spawned = 0
	_tutorial_passed = 0
	_tutorial_msg_until = 0
	# yazı, bekleyen kapı ile bukalemunun arasında dursun
	tutorial_label.offset_top = chameleon_y_position - 205.0
	tutorial_label.offset_bottom = chameleon_y_position - 145.0
	tutorial_label.visible = _tutorial_active

# Sıradaki (henüz geçilmemiş, bukalemuna en yakın) öğretici kapısı.
func _next_tutorial_gate() -> ColorRect:
	var best: ColorRect = null
	for gate in gates_container.get_children():
		if gate.get_meta("passed") or not gate.get_meta("tutorial", false):
			continue
		if best == null or gate.position.y > best.position.y:
			best = gate
	return best

func _tutorial_gate_blocked() -> bool:
	if not _tutorial_active:
		return false
	var gate := _next_tutorial_gate()
	if gate == null:
		return false
	var gap: float = chameleon_y_position - (gate.position.y + gate_thickness)
	return gap <= TUTORIAL_FREEZE_GAP and gate.get_meta("color_index") != current_color_index

func _update_tutorial_label() -> void:
	if _tutorial_active:
		var gate := _next_tutorial_gate()
		var needs_tap: bool = gate != null and gate.get_meta("color_index") != current_color_index
		tutorial_label.text = "Tap to change color" if needs_tap else "Match the gate's color"
		tutorial_label.visible = true
	elif _tutorial_msg_until > 0 and Time.get_ticks_msec() >= _tutorial_msg_until:
		_tutorial_msg_until = 0
		tutorial_label.visible = false

func _finish_tutorial() -> void:
	_tutorial_active = false
	GameState.tutorial_done = true
	GameState.save_data()
	Analytics.log_event("tutorial_complete")
	tutorial_label.text = "Nice! Keep going"
	tutorial_label.visible = true
	_tutorial_msg_until = Time.get_ticks_msec() + 1400

func _hide_tutorial() -> void:
	_tutorial_active = false
	_tutorial_msg_until = 0
	tutorial_label.visible = false

# keep_progress = true -> revive (skor/hız/renk korunur); false -> tam yeniden başlat
func _reset_field(keep_progress: bool) -> void:
	game_over = false
	_pending_gate = null
	if not keep_progress:
		_revive_grace_until = 0
		score = 0
		current_color_index = 0
		scroll_speed = 220.0
		gate_spawn_count = 0
	next_gate_y = -300.0
	last_spawned_gate = null

	for gate in gates_container.get_children():
		gate.queue_free()

	var screen_size = get_viewport_rect().size
	chameleon.position = Vector2(screen_size.x / 2.0, screen_size.y * 0.75)
	chameleon_y_position = chameleon.position.y
	chameleon.scale = Vector2.ONE
	chameleon.rotation = 0.0
	chameleon.modulate.a = 1.0
	chameleon.visible = true
	_cham_home = chameleon.position
	_shake = 0.0
	_idle_t = 0.0
	gates_container.position = Vector2.ZERO
	vignette.self_modulate = Color(1, 1, 1, 1)
	if _death_flash:
		_death_flash.color.a = 0.0
	update_chameleon_color(colors[current_color_index], false)

	score_label.text = str(score)
	score_label.scale = Vector2.ONE
	score_label.modulate = Color(1, 1, 1, 1)
	score_label.visible = true
	_hide_game_over_ui()
	pause_button.visible = true

	while not is_instance_valid(last_spawned_gate) or last_spawned_gate.position.y > -2600.0:
		spawn_gate(next_gate_y)
		next_gate_y -= get_next_spacing()

func check_retroactive_unlocks():
	if GameState.high_score >= 15 and 1 not in GameState.unlocked_themes:
		GameState.unlock_theme(1)
	if GameState.daily_streak >= 3 and 2 not in GameState.unlocked_themes:
		GameState.unlock_theme(2)

# ------------------------------------------------------------------ başlangıç ekranı

var _menu_skin_tween: Tween
var _menu_squash_tween: Tween

func _show_menu() -> void:
	_starting = false
	_kill_menu_tweens()
	chameleon.visible = false
	score_label.visible = false
	_hide_tutorial()
	themes_panel.visible = false
	start_panel.modulate.a = 1.0
	start_panel.visible = true
	menu_chameleon.visible = true
	menu_chameleon.scale = Vector2.ONE * MENU_CHAM_SCALE
	_menu_color_index = 0
	_menu_color_t = 0.0
	_layout_menu()
	setup_start_panel()

func _layout_menu() -> void:
	var vs := get_viewport_rect().size
	_menu_center = Vector2(vs.x / 2.0, vs.y * 0.47)
	menu_rings.position = _menu_center
	if not _starting:
		menu_chameleon.position = _menu_center

func _refresh_menu_hero() -> void:
	menu_rings.set_colors(colors)
	_menu_color_index = _menu_color_index % colors.size()
	_set_menu_color(_menu_color_index, false)

func _update_menu(delta: float) -> void:
	if not start_panel.visible or _starting:
		return
	_menu_t += delta
	menu_chameleon.position = _menu_center + Vector2(0.0, sin(_menu_t * 2.4) * 6.0)
	_menu_color_t += delta
	if _menu_color_t >= MENU_COLOR_INTERVAL:
		_menu_color_t = 0.0
		_menu_color_index = (_menu_color_index + 1) % colors.size()
		_set_menu_color(_menu_color_index, true)

# Menüdeki bukalemun sırayla temanın renklerine bürünür; aynı renkteki halka öne çıkar.
func _set_menu_color(index: int, animate: bool) -> void:
	menu_rings.highlight = index
	var c: Color = colors[index]
	if not animate:
		menu_chameleon.skin = c
		return
	_kill_menu_tweens()
	_menu_skin_tween = create_tween()
	_menu_skin_tween.tween_property(menu_chameleon, "skin", c, 0.15)
	menu_chameleon.scale = Vector2(1.12, 0.88) * MENU_CHAM_SCALE
	_menu_squash_tween = create_tween()
	_menu_squash_tween.tween_property(menu_chameleon, "scale", Vector2.ONE * MENU_CHAM_SCALE, 0.22) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _kill_menu_tweens() -> void:
	for t in [_menu_skin_tween, _menu_squash_tween]:
		if t and t.is_valid():
			t.kill()

func _start_tap_pulse(lbl: Label) -> void:
	var t := create_tween().set_loops()
	t.tween_property(lbl, "modulate:a", 0.45, 0.75).set_trans(Tween.TRANS_SINE)
	t.tween_property(lbl, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE)

func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false

# Ekranın boş herhangi bir yerine dokunmak oyunu başlatır (ayar/tema butonları kendi
# dokunuşlarını yutar, buraya ulaşmaz).
func _on_start_panel_input(event: InputEvent) -> void:
	if _is_tap(event):
		start_panel.accept_event()
		_begin_start()

# Menü bukalemunu, oyundaki bukalemunun yerine küçülerek iner; menü aynı anda solar.
func _begin_start() -> void:
	if _starting or game_started or waiting_for_ad or _rewarded_active:
		return
	_starting = true
	_kill_menu_tweens()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(start_panel, "modulate:a", 0.0, 0.25)
	tw.tween_property(menu_chameleon, "position", _cham_home, 0.38) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(menu_chameleon, "scale", Vector2.ONE, 0.38) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(menu_chameleon, "skin", colors[current_color_index], 0.2)
	tw.chain().tween_callback(_finish_start)

func _finish_start() -> void:
	menu_chameleon.visible = false
	chameleon.visible = true
	_starting = false
	start_game()
	start_panel.modulate.a = 1.0

func _open_themes() -> void:
	setup_start_panel()
	themes_panel.modulate.a = 0.0
	themes_panel.visible = true
	create_tween().tween_property(themes_panel, "modulate:a", 1.0, 0.18)

func _close_themes() -> void:
	themes_panel.visible = false

func _on_themes_panel_input(event: InputEvent) -> void:
	if _is_tap(event):
		themes_panel.accept_event()
		_close_themes()

# ------------------------------------------------------------------ ayarlar

func _vibrate(ms: int) -> void:
	if GameState.vibration_enabled:
		Input.vibrate_handheld(ms)

func _apply_music() -> void:
	if music_player.stream == null:
		return
	if GameState.music_enabled:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()

func _refresh_settings_ui() -> void:
	sound_button.set("is_on", GameState.sound_enabled)
	vibe_button.set("is_on", GameState.vibration_enabled)
	music_button.set("is_on", GameState.music_enabled)

func _on_sound_toggled() -> void:
	GameState.sound_enabled = not GameState.sound_enabled
	GameState.save_data()
	_refresh_settings_ui()

func _on_vibe_toggled() -> void:
	GameState.vibration_enabled = not GameState.vibration_enabled
	GameState.save_data()
	_refresh_settings_ui()
	if GameState.vibration_enabled:
		Input.vibrate_handheld(15)

func _on_music_toggled() -> void:
	GameState.music_enabled = not GameState.music_enabled
	GameState.save_data()
	_refresh_settings_ui()
	_apply_music()

# ------------------------------------------------------------------ duraklatma

func _on_pause_pressed() -> void:
	if not game_started or game_over:
		return
	get_tree().paused = true
	pause_panel.visible = true
	pause_button.visible = false

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	pause_button.visible = true

func _on_pause_menu_pressed() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	_return_to_menu()

func _return_to_menu() -> void:
	game_started = false
	game_over = false
	can_restart = false
	_pending_gate = null
	_revive_grace_until = 0
	score = 0
	current_color_index = 0
	scroll_speed = 220.0
	gate_spawn_count = 0
	next_gate_y = -300.0
	last_spawned_gate = null
	_shake = 0.0
	_idle_t = 0.0

	for gate in gates_container.get_children():
		gate.queue_free()
	gates_container.position = Vector2.ZERO
	vignette.self_modulate = Color(1, 1, 1, 1)

	var screen_size = get_viewport_rect().size
	chameleon.position = Vector2(screen_size.x / 2.0, screen_size.y * 0.75)
	chameleon_y_position = chameleon.position.y
	chameleon.scale = Vector2.ONE
	chameleon.rotation = 0.0
	chameleon.modulate.a = 1.0
	_cham_home = chameleon.position
	update_chameleon_color(colors[current_color_index], false)

	score_label.text = "0"
	score_label.scale = Vector2.ONE
	score_label.modulate = Color(1, 1, 1, 1)
	score_label.visible = true
	_hide_game_over_ui()
	pause_button.visible = false
	_show_menu()
