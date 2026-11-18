extends Node
## Globalne / per-quest ustawienia szumu.
## UI powinno mówić o „względnym poziomie”, nie o klinicznym SNR w dB.

signal changed

var enabled: bool = false
var noise_type: String = "pink"
## 0.0–1.0 względna głośność szumu względem mowy (heurystyka, nie SNR).
var relative_level: float = 0.35


func _ready() -> void:
	_load_defaults_from_json()


func _load_defaults_from_json() -> void:
	var path := "res://data/noise_presets.json"
	if not FileAccess.file_exists(path):
		return
	var raw := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		return
	enabled = bool(data.get("default_enabled", false))
	noise_type = str(data.get("default_type", "pink"))
	relative_level = float(data.get("default_relative_level", 0.35))


func set_enabled(value: bool) -> void:
	enabled = value
	changed.emit()


func set_type(type_id: String) -> void:
	noise_type = type_id
	changed.emit()


func set_relative_level(level: float) -> void:
	relative_level = clampf(level, 0.0, 1.0)
	changed.emit()
