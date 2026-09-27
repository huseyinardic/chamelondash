extends Node

var high_score = 0
var daily_streak = 0
var last_played_date = ""
var unlocked_themes = [0]  # index 0 (Classic) her zaman açık
var active_theme = 0
var game_over_count = 0
var tutorial_done = false
# ateş böceği ekonomisi ve kostümler (Costumes.LIST)
var fireflies := 0
var owned_costumes: Array = []
var equipped_head := ""
var equipped_acc := ""
var last_reward_date := ""   # günlük seri ödülünün en son alındığı yerel gün

# 7 günlük seri ödülü (ateş böceği). 3. gün Neon teması da açılır, 7. gün Taç
# (satın alınamaz). 7. günden sonra (ya da Taç zaten varsa) her gün STREAK_AFTER.
const STREAK_REWARDS := [10, 20, 30, 40, 50, 60]
const STREAK_AFTER := 60
const STREAK_CROWN_DAY := 7
const NEON_STREAK_DAY := 3

# oturum içi reklam frekans sınırı (diske yazılmaz, uygulama kapanınca sıfırlanır)
var games_since_ad := 0
var last_ad_msec := -100000

# ayarlar
var sound_enabled = true
var vibration_enabled = true
var music_enabled = true

const SAVE_PATH = "user://savegame.dat"

func _ready():
	load_data()
	update_daily_streak()

# "bugün" ve "dün" aynı temele (yerel takvim günü) göre hesaplanır;
# eskiden biri yerel biri UTC idi -> gece yarısı civarı streak yanlış kırılıyordu.
func _local_now() -> int:
	var tz_bias: int = int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return int(Time.get_unix_time_from_system()) + tz_bias

func today_string() -> String:
	return Time.get_date_string_from_unix_time(_local_now())

func update_daily_streak():
	var local_now: int = _local_now()
	var today: String = Time.get_date_string_from_unix_time(local_now)
	if last_played_date == today:
		return

	var yesterday: String = Time.get_date_string_from_unix_time(local_now - 86400)

	if last_played_date == yesterday:
		daily_streak += 1
	else:
		daily_streak = 1

	last_played_date = today
	save_data()

func daily_reward_available() -> bool:
	return daily_streak > 0 and last_reward_date != today_string()

# Bugünün seri ödülü (henüz almadan): {day, amount, crown}
func daily_reward_preview() -> Dictionary:
	var day: int = daily_streak
	var crown: bool = day >= STREAK_CROWN_DAY and "crown" not in owned_costumes
	var amount: int = 0
	if crown:
		amount = 0
	elif day <= STREAK_REWARDS.size():
		amount = STREAK_REWARDS[day - 1]
	else:
		amount = STREAK_AFTER
	return {"day": day, "amount": amount, "crown": crown}

# Ödülü uygular ve kaydeder. Döner: {day, amount, crown, neon}
func claim_daily_reward() -> Dictionary:
	var r := daily_reward_preview()
	fireflies += r["amount"]
	if r["crown"]:
		owned_costumes.append("crown")
		equipped_head = "crown"   # hemen taksın — ödül menüde görünsün
	r["neon"] = r["day"] >= NEON_STREAK_DAY and 2 not in unlocked_themes
	if r["neon"]:
		unlocked_themes.append(2)
	last_reward_date = today_string()
	save_data()
	return r

func unlock_theme(theme_index: int) -> bool:
	if theme_index not in unlocked_themes:
		unlocked_themes.append(theme_index)
		save_data()
		return true
	return false

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"high_score": high_score,
			"daily_streak": daily_streak,
			"last_played_date": last_played_date,
			"unlocked_themes": unlocked_themes,
			"active_theme": active_theme,
			"game_over_count": game_over_count,
			"tutorial_done": tutorial_done,
			"fireflies": fireflies,
			"owned_costumes": owned_costumes,
			"equipped_head": equipped_head,
			"equipped_acc": equipped_acc,
			"last_reward_date": last_reward_date,
			"sound_enabled": sound_enabled,
			"vibration_enabled": vibration_enabled,
			"music_enabled": music_enabled
		}
		file.store_var(data)
		file.close()

func load_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			if data is Dictionary:
				high_score = data.get("high_score", 0)
				daily_streak = data.get("daily_streak", 0)
				last_played_date = data.get("last_played_date", "")
				unlocked_themes = data.get("unlocked_themes", [0])
				active_theme = data.get("active_theme", 0)
				game_over_count = data.get("game_over_count", 0)
				# güncellemeyle gelen eski oyuncular (en az bir oyun bitirmiş) öğreticiyi görmesin
				tutorial_done = data.get("tutorial_done", game_over_count > 0)
				fireflies = int(data.get("fireflies", 0))
				owned_costumes = data.get("owned_costumes", [])
				equipped_head = data.get("equipped_head", "")
				equipped_acc = data.get("equipped_acc", "")
				last_reward_date = data.get("last_reward_date", "")
				sound_enabled = data.get("sound_enabled", true)
				vibration_enabled = data.get("vibration_enabled", true)
				music_enabled = data.get("music_enabled", true)
