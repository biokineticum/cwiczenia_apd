extends Node
## Lekka grywalizacja: punkty, streak, odznaki. Persistencja user://progress.json.

signal progress_changed

const SAVE_PATH := "user://progress.json"

var points: int = 0
var streak_days: int = 0
var last_play_day: String = ""
var badges: Array[String] = []


func _ready() -> void:
	load_progress()


func add_points(amount: int) -> void:
	points += max(amount, 0)
	_touch_streak()
	save_progress()
	progress_changed.emit()


func unlock_badge(badge_id: String) -> void:
	if badge_id in badges:
		return
	badges.append(badge_id)
	save_progress()
	progress_changed.emit()


func _touch_streak() -> void:
	var today := Time.get_date_string_from_system()
	if last_play_day == today:
		return
	if last_play_day == "":
		streak_days = 1
	else:
		# Uproszczenie: każdy nowy dzień gry +1 (pełna logika dat później).
		streak_days += 1
	last_play_day = today


func save_progress() -> void:
	var data := {
		"points": points,
		"streak_days": streak_days,
		"last_play_day": last_play_day,
		"badges": badges,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var raw := FileAccess.get_file_as_string(SAVE_PATH)
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return
	points = int(data.get("points", 0))
	streak_days = int(data.get("streak_days", 0))
	last_play_day = str(data.get("last_play_day", ""))
	badges.clear()
	for b in data.get("badges", []):
		badges.append(str(b))
