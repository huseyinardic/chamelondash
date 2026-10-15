class_name Reminders
extends Node

# Yerel bildirim: günlük ödül hatırlatması (NotificationScheduler eklentisi, yalnız Android).
# Kurallar:
#   - Hep en fazla TEK bekleyen hatırlatma var. Oyun her açıldığında / ödül alındığında /
#     arka plana geçtiğinde iptal edilip yeniden kurulur: bugünün ödülü alınmadıysa ve
#     saat 18'den önceyse bugün 19:00, değilse yarın 19:00 (oyuncunun yerel saati).
#   - Oyuncu açmazsa başka bildirim gelmez: günde en fazla 1, görmezden gelinince susar.
#   - İzin (Android 13+): ilk günlük ödül alınınca kendi kartımızda sorulur ("Remind me"),
#     evet derse sistem penceresi açılır. En fazla MAX_ASKS kez, aralarında ASK_GAP_DAYS gün.
#   - Yalnız oyunun kendisiyle ilgili mesajlar (Play: bildirimde başka uygulama reklamı yok).
# Analitik: notif_prompt {answer}, notif_permission {result}, notif_open.

const REMIND_ID := 7101
const CHANNEL_ID := "daily_reward"
const HOUR := 19
const SAVE_PATH := "user://reminders.cfg"
const MAX_ASKS := 2
const ASK_GAP_DAYS := 3

var _ns: NotificationScheduler = null
var _ready_ok := false

func _ready() -> void:
	if OS.get_name() != "Android" or not Engine.has_singleton(NotificationScheduler.PLUGIN_SINGLETON_NAME):
		return
	_ns = NotificationScheduler.new()
	add_child(_ns)
	_ns.initialization_completed.connect(_on_initialized)
	_ns.notification_opened.connect(func(_d): Analytics.log_event("notif_open", {"kind": "daily"}))
	_ns.post_notifications_permission_granted.connect(func(_p):
		Analytics.log_event("notif_permission", {"result": "granted"})
		refresh())
	_ns.post_notifications_permission_denied.connect(func(_p):
		Analytics.log_event("notif_permission", {"result": "denied"}))
	_ns.initialize()

func _on_initialized() -> void:
	_ready_ok = true
	_ns.create_notification_channel(NotificationChannel.new()
		.set_id(CHANNEL_ID)
		.set_name("Daily reward")
		.set_description("Lets you know when your daily reward is ready")
		.set_importance(NotificationChannel.Importance.DEFAULT))
	refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		refresh()

# Bekleyen hatırlatmayı iptal edip duruma göre yenisini kurar.
func refresh() -> void:
	if not _ready_ok:
		return
	_ns.cancel(REMIND_ID)
	if GameState.game_over_count == 0 or not _ns.has_post_notifications_permission():
		return
	var plan := _plan()
	if OS.is_debug_build():           # telefonda hızlı deneme: 30 sn sonra gelen örnek (release'de yok)
		_ns.schedule(NotificationData.new().set_id(REMIND_ID + 1).set_channel_id(CHANNEL_ID)
			.set_title("[debug] " + plan["title"]).set_content(plan["text"] + " (in %d s)" % plan["delay"])
			.set_large_icon_name("notif_large").set_delay(30))
	_ns.schedule(NotificationData.new()
		.set_id(REMIND_ID)
		.set_channel_id(CHANNEL_ID)
		.set_title(plan["title"])
		.set_content(plan["text"])
		.set_large_icon_name("notif_large")
		.set_delay(plan["delay"]))

# Ne zaman ve ne yazacağı. Yarının ödülü GameState.daily_reward_preview'ın bir gün sonrası.
func _plan() -> Dictionary:
	var now := Time.get_datetime_dict_from_system()        # yerel saat
	var secs: int = int(now["hour"]) * 3600 + int(now["minute"]) * 60 + int(now["second"])
	if GameState.daily_reward_available() and secs < (HOUR - 1) * 3600:
		var r := GameState.daily_reward_preview()
		return {"delay": HOUR * 3600 - secs, "title": "Your daily reward is waiting ✨",
			"text": "Claim +%d fireflies before the day ends!" % r["amount"] if not r["crown"]
				else "The Crown is ready for your chameleon! 👑"}
	var played_today: bool = GameState.last_played_date == GameState.today_string()
	var day: int = GameState.daily_streak + 1 if played_today else 1
	var delay: int = 86400 - secs + HOUR * 3600
	if day >= GameState.STREAK_CROWN_DAY and "crown" not in GameState.owned_costumes:
		return {"delay": delay, "title": "Day %d: the Crown is waiting! 👑" % day,
			"text": "Come back today and claim it for your chameleon."}
	var amount: int = GameState.STREAK_REWARDS[day - 1] if day <= GameState.STREAK_REWARDS.size() else GameState.STREAK_AFTER
	if day >= 3:
		return {"delay": delay, "title": "Don't lose your %d-day streak! 🔥" % (day - 1),
			"text": "Day %d reward: +%d fireflies ✨" % [day, amount]}
	return {"delay": delay, "title": "Your daily fireflies are ready ✨",
		"text": "Claim +%d fireflies and beat your best!" % amount}

# Kendi kartımızda sorulsun mu: izin yoksa, sorma hakkı kaldıysa ve son sorudan beri yeterli gün geçtiyse.
func should_ask() -> bool:
	if not _ready_ok or _ns.has_post_notifications_permission():
		return false
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var asks := int(cfg.get_value("ask", "count", 0))
	var last := int(cfg.get_value("ask", "last_unix", 0))
	return asks < MAX_ASKS and int(Time.get_unix_time_from_system()) - last >= ASK_GAP_DAYS * 86400

# Kartın cevabı. Evet: sistem izin penceresi (sonucu sinyalle gelir, verilirse refresh).
func answer(yes: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("ask", "count", int(cfg.get_value("ask", "count", 0)) + 1)
	cfg.set_value("ask", "last_unix", int(Time.get_unix_time_from_system()))
	cfg.save(SAVE_PATH)
	Analytics.log_event("notif_prompt", {"answer": "yes" if yes else "no"})
	if yes and _ns:
		_ns.request_post_notifications_permission()
