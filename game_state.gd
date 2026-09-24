extends Node

var high_score = 0
var daily_streak = 0
var last_played_date = ""
var unlocked_themes = [0]  # index 0 (Classic) her zaman açık
var active_theme = 0
var game_over_count = 0
var tutorial_done = false

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

func update_daily_streak():
	# "bugün" ve "dün" aynı temele (yerel takvim günü) göre hesaplanır;
	# eskiden biri yerel biri UTC idi -> gece yarısı civarı streak yanlış kırılıyordu.
	var tz_bias: int = int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var local_now: int = int(Time.get_unix_time_from_system()) + tz_bias
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
				sound_enabled = data.get("sound_enabled", true)
				vibration_enabled = data.get("vibration_enabled", true)
				music_enabled = data.get("music_enabled", true)
