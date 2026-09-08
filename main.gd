extends Node2D

@onready var chameleon: Panel = $Chameleon
@onready var gates_container: Node2D = $Gates
@onready var score_label: Label = $UI/ScoreLabel
@onready var vignette: TextureRect = $UI/Vignette
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var pause_button: Button = $UI/PauseButton
@onready var pause_panel: Control = $UI/PausePanel
@onready var sound_button: Button = $UI/StartPanel/ContentBox/SettingsRow/SoundButton
@onready var vibe_button: Button = $UI/StartPanel/ContentBox/SettingsRow/VibeButton
@onready var music_button: Button = $UI/StartPanel/ContentBox/SettingsRow/MusicButton
@onready var dim_overlay: ColorRect = $UI/DimOverlay
@onready var game_over_panel: VBoxContainer = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/FinalScoreLabel
@onready var high_score_label: Label = $UI/GameOverPanel/HighScoreLabel
@onready var pass_sound: AudioStreamPlayer = $PassSound
@onready var game_over_sound: AudioStreamPlayer = $GameOverSound
@onready var share_node: Share = $Share
@onready var share_button: Button = $UI/GameOverPanel/ShareButton
@onready var streak_label: Label = $UI/GameOverPanel/StreakLabel
@onready var unlock_notice_label: Label = $UI/GameOverPanel/UnlockNoticeLabel
@onready var theme_button: Button = $UI/GameOverPanel/ThemeButton
@onready var revive_button: Button = $UI/GameOverPanel/ReviveButton
@onready var unlock_neon_button: Button = $UI/StartPanel/ContentBox/UnlockNeonButton
@onready var start_panel: Control = $UI/StartPanel
@onready var best_score_label: Label = $UI/StartPanel/ContentBox/BestScoreLabel
@onready var streak_display_label: Label = $UI/StartPanel/ContentBox/StreakDisplayLabel
@onready var play_button: Button = $UI/StartPanel/ContentBox/PlayButton
@onready var theme_swatches: Array[Button] = [
	$UI/StartPanel/ContentBox/ThemeRow/ThemeBox0/ThemeSwatch0,
	$UI/StartPanel/ContentBox/ThemeRow/ThemeBox1/ThemeSwatch1,
	$UI/StartPanel/ContentBox/ThemeRow/ThemeBox2/ThemeSwatch2
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

var _swatches_connected := false

# --- juice / oyun hissi ---
var _shake := 0.0
var _idle_t := 0.0
var _cham_home := Vector2.ZERO
var _death_flash: ColorRect = null

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
	revive_button.pressed.connect(_on_revive_pressed)
	unlock_neon_button.pressed.connect(_on_unlock_neon_pressed)
	_setup_ads()

	theme_button.pressed.connect(_on_theme_button_pressed)
	theme_button.text = "Theme: " + theme_names[GameState.active_theme]
	
	dim_overlay.visible = false
	game_over_panel.visible = false
	unlock_notice_label.visible = false
	game_over_panel.modulate.a = 0.0
	game_over_panel.scale = Vector2(0.7, 0.7)
	chameleon.position = Vector2(screen_size.x / 2 - chameleon.size.x / 2, screen_size.y * 0.75)
	chameleon_y_position = chameleon.position.y
	chameleon.pivot_offset = chameleon.size / 2
	_cham_home = chameleon.position
	update_chameleon_color(colors[current_color_index], false)

	_death_flash = ColorRect.new()
	_death_flash.name = "DeathFlash"
	_death_flash.color = Color(0.92, 0.12, 0.12, 0.0)
	_death_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_death_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(_death_flash)
	$UI.move_child(_death_flash, dim_overlay.get_index() + 1)

	play_button.pressed.connect(start_game)

	sound_button.pressed.connect(_on_sound_toggled)
	vibe_button.pressed.connect(_on_vibe_toggled)
	music_button.pressed.connect(_on_music_toggled)
	pause_button.pressed.connect(_on_pause_pressed)
	pause_panel.get_node("Box/ResumeButton").pressed.connect(_on_resume_pressed)
	pause_panel.get_node("Box/MenuButton").pressed.connect(_on_pause_menu_pressed)
	_refresh_settings_ui()
	_apply_music()

	setup_start_panel()

func spawn_gate(y_pos: float):
	var gate = ColorRect.new()
	var screen_width = get_viewport_rect().size.x
	gate.size = Vector2(screen_width, gate_thickness)
	gate.position = Vector2(0, y_pos)
	var gate_color_index = randi() % colors.size()
	gate.color = colors[gate_color_index]
	gate.set_meta("color_index", gate_color_index)
	gate.set_meta("passed", false)
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
	if not game_started or game_over:
		return

	_resolve_pending_gate()

	next_gate_y += scroll_speed * delta
	for gate in gates_container.get_children():
		gate.position.y += scroll_speed * delta

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

func _squash(node: Control, amount: Vector2) -> void:
	node.pivot_offset = node.size / 2
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
	chameleon.pivot_offset = chameleon.size / 2
	var ct := create_tween()
	ct.set_parallel(true)
	ct.tween_property(chameleon, "scale", Vector2(0.1, 0.1), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	ct.tween_property(chameleon, "rotation", chameleon.rotation + 1.3, 0.35)

func check_gate_collision(gate: ColorRect):
	if gate.get_meta("color_index") == current_color_index:
		_award_pass(gate)
	else:
		# yanlış renk: geç dokunuşa küçük tolerans tanı (senkron, _process'te çözülür)
		_pending_gate = gate
		_pending_deadline = Time.get_ticks_msec() + COYOTE_MS

func _resolve_pending_gate() -> void:
	if _pending_gate == null:
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

func update_chameleon_color(new_color: Color, animate: bool = true):
	_tint_chameleon(chameleon, new_color, animate)
	if animate:
		_squash(chameleon, Vector2(1.18, 0.82))

func _tint_chameleon(node: Node, new_color: Color, animate: bool) -> void:
	# "notint" grubundakiler (göz akı, göz bebeği, ağız) hariç tüm parçaları boya
	if node is CanvasItem and not node.is_in_group("notint"):
		if animate:
			var tween = create_tween()
			tween.tween_property(node, "self_modulate", new_color, 0.15)
		else:
			node.self_modulate = new_color
	for child in node.get_children():
		_tint_chameleon(child, new_color, animate)

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
	_play_death_juice()

	var newly_unlocked = -1
	if score >= 15 and 1 not in GameState.unlocked_themes:
		if GameState.unlock_theme(1):
			newly_unlocked = 1
	if GameState.daily_streak >= 3 and 2 not in GameState.unlocked_themes:
		if GameState.unlock_theme(2):
			newly_unlocked = 2

	if newly_unlocked >= 0:
		unlock_notice_label.text = "New theme unlocked: " + theme_names[newly_unlocked] + "!"
		unlock_notice_label.visible = true
	else:
		unlock_notice_label.visible = false

	streak_label.text = "🔥 " + str(GameState.daily_streak) + " day streak"

	# "reklam izle, devam et" — koşu başına bir kez, reklam hazırsa
	revive_button.visible = rewarded_ready() and not _used_revive_this_run

	if score > GameState.high_score:
		GameState.high_score = score
		GameState.save_data()

	final_score_label.text = str(score)
	high_score_label.text = "Best: " + str(GameState.high_score)

	dim_overlay.visible = true
	dim_overlay.modulate.a = 0.0
	var dim_tween = create_tween()
	dim_tween.tween_property(dim_overlay, "modulate:a", 1.0, 0.25)

	game_over_panel.visible = true
	game_over_panel.pivot_offset = game_over_panel.size / 2
	var panel_tween = create_tween()
	panel_tween.set_parallel(true)
	panel_tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.3)
	panel_tween.tween_property(game_over_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	GameState.game_over_count += 1
	GameState.games_since_ad += 1
	GameState.save_data()

	await get_tree().create_timer(0.4).timeout
	can_restart = true

# --- Reklam kurulumu: önce UMP consent, sonra MobileAds.initialize() ---

func _setup_ads() -> void:
	# Reklamlar sadece mobilde çalışır; editör/masaüstünde consent akışını atla.
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
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
	if _ads_initialized:
		return
	_ads_initialized = true
	MobileAds.initialize()
	var conf := RequestConfiguration.new()
	# Test cihazları (logcat'teki setTestDeviceIds değeri) — release build'de bile test reklamı gösterir:
	conf.test_device_ids = ["0A19F3B168FC5DE628D41FE1E5BB333B", "D5B8A059081C01DFD1A8E0E2401DBAC3"]
	MobileAds.set_request_configuration(conf)
	await get_tree().create_timer(1.5).timeout
	load_interstitial_ad()
	load_rewarded_ad()

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
	interstitial_ad.show()
	interstitial_ad = null
	load_interstitial_ad()   # bir sonraki reklamı hazırla (sahne yeniden yüklenmiyor)
	_start_ad_safety_timeout()

func _do_pending_restart() -> void:
	if not _pending_restart:
		return
	_pending_restart = false
	waiting_for_ad = false
	restart_run()

func _on_ad_shown() -> void:
	_ad_showing = true

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
	if start_panel.visible:
		_refresh_unlock_neon_button()

func _on_rewarded_failed(_error: LoadAdError) -> void:
	rewarded_ad = null

func rewarded_ready() -> bool:
	return rewarded_ad != null

func _show_rewarded(purpose: String) -> void:
	if rewarded_ad == null or waiting_for_ad:
		return
	_rewarded_purpose = purpose
	_rewarded_reward_earned = false
	waiting_for_ad = true
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item): _rewarded_reward_earned = true
	rewarded_ad.show(listener)
	rewarded_ad = null
	load_rewarded_ad()   # bir sonrakini hazırla

func _on_rewarded_dismissed() -> void:
	waiting_for_ad = false
	var purpose := _rewarded_purpose
	var earned := _rewarded_reward_earned
	_rewarded_purpose = ""
	_rewarded_reward_earned = false
	if earned:
		_grant_reward(purpose)

func _on_rewarded_failed_to_show(_error: AdError) -> void:
	waiting_for_ad = false
	_rewarded_purpose = ""
	_rewarded_reward_earned = false

func _grant_reward(purpose: String) -> void:
	match purpose:
		"revive":
			_revive()
		"unlock_neon":
			GameState.unlock_theme(2)
			setup_start_panel()

func _refresh_unlock_neon_button() -> void:
	var neon_locked: bool = 2 not in GameState.unlocked_themes
	unlock_neon_button.visible = neon_locked and rewarded_ready()

func _on_unlock_neon_pressed() -> void:
	if 2 in GameState.unlocked_themes:
		unlock_neon_button.visible = false
		return
	_show_rewarded("unlock_neon")

func _on_revive_pressed() -> void:
	if not game_over or _used_revive_this_run:
		return
	revive_button.visible = false
	_show_rewarded("revive")

func _revive() -> void:
	_used_revive_this_run = true
	_vibrate(15)
	_reset_field(true)
	can_restart = true

func _on_share_pressed():
	if share_node == null or not share_node.has_method("share_image"):
		return
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
	
func _on_theme_button_pressed():
	var next_index = GameState.active_theme
	for i in range(1, theme_palettes.size() + 1):
		var candidate = (GameState.active_theme + i) % theme_palettes.size()
		if candidate in GameState.unlocked_themes:
			next_index = candidate
			break
	GameState.active_theme = next_index
	GameState.save_data()
	colors = theme_palettes[next_index]
	update_chameleon_color(colors[current_color_index], false)
	theme_button.text = "Theme: " + theme_names[next_index]

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

	var theme_label_paths = [
		"ContentBox/ThemeRow/ThemeBox0/ThemeLabel0",
		"ContentBox/ThemeRow/ThemeBox1/ThemeLabel1",
		"ContentBox/ThemeRow/ThemeBox2/ThemeLabel2"
	]
	for i in range(theme_swatches.size()):
		var swatch = theme_swatches[i]
		if not _swatches_connected:
			swatch.pressed.connect(_on_swatch_pressed.bind(i))
		update_swatch_visual(swatch, i)
		var label = start_panel.get_node(theme_label_paths[i])
		label.text = theme_names[i]
	_swatches_connected = true
	_refresh_unlock_neon_button()

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
	colors = theme_palettes[index]
	for i in range(theme_swatches.size()):
		update_swatch_visual(theme_swatches[i], i)

func start_game():
	game_started = true
	_used_revive_this_run = false
	start_panel.visible = false
	pause_button.visible = true
	_apply_music()

	while not is_instance_valid(last_spawned_gate) or last_spawned_gate.position.y > -2600.0:
		spawn_gate(next_gate_y)
		next_gate_y -= get_next_spacing()

func restart_run():
	_used_revive_this_run = false
	_reset_field(false)

# keep_progress = true -> revive (skor/hız/renk korunur); false -> tam yeniden başlat
func _reset_field(keep_progress: bool) -> void:
	game_over = false
	_pending_gate = null
	if not keep_progress:
		score = 0
		current_color_index = 0
		scroll_speed = 220.0
		gate_spawn_count = 0
	next_gate_y = -300.0
	last_spawned_gate = null

	for gate in gates_container.get_children():
		gate.queue_free()

	var screen_size = get_viewport_rect().size
	chameleon.position = Vector2(screen_size.x / 2 - chameleon.size.x / 2, screen_size.y * 0.75)
	chameleon_y_position = chameleon.position.y
	chameleon.scale = Vector2.ONE
	chameleon.rotation = 0.0
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
	dim_overlay.visible = false
	game_over_panel.visible = false
	pause_button.visible = true

	while not is_instance_valid(last_spawned_gate) or last_spawned_gate.position.y > -2600.0:
		spawn_gate(next_gate_y)
		next_gate_y -= get_next_spacing()

func check_retroactive_unlocks():
	if GameState.high_score >= 15 and 1 not in GameState.unlocked_themes:
		GameState.unlock_theme(1)
	if GameState.daily_streak >= 3 and 2 not in GameState.unlocked_themes:
		GameState.unlock_theme(2)

# ------------------------------------------------------------------ ayarlar

func _vibrate(ms: int) -> void:
	if GameState.vibration_enabled:
		Input.vibrate_handheld(ms)

func _apply_music() -> void:
	if music_player.stream == null:
		return  # henüz müzik dosyası yok - sounds/ içine bir .ogg koyup MusicPlayer.stream'e ata
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
	chameleon.position = Vector2(screen_size.x / 2 - chameleon.size.x / 2, screen_size.y * 0.75)
	chameleon_y_position = chameleon.position.y
	chameleon.scale = Vector2.ONE
	chameleon.rotation = 0.0
	_cham_home = chameleon.position
	update_chameleon_color(colors[current_color_index], false)

	score_label.text = "0"
	score_label.scale = Vector2.ONE
	score_label.modulate = Color(1, 1, 1, 1)
	score_label.visible = true
	dim_overlay.visible = false
	game_over_panel.visible = false
	pause_button.visible = false
	start_panel.visible = true
	setup_start_panel()
