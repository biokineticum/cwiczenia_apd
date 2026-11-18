extends CanvasLayer
## HUD: punkty, hint interakcji, disclaimer treningowy.

@onready var points_label: Label = $Margin/VBox/PointsLabel
@onready var hint_label: Label = $Margin/VBox/HintLabel
@onready var disclaimer: Label = $Margin/VBox/Disclaimer


func _ready() -> void:
	ProgressStore.progress_changed.connect(_refresh)
	disclaimer.text = "Trening wspomagający — nie diagnostyka. Poziom szumu jest względny."
	_refresh()


func _refresh() -> void:
	points_label.text = "Punkty: %d  ·  Seria: %d dni" % [ProgressStore.points, ProgressStore.streak_days]


func set_hint(text: String) -> void:
	hint_label.text = text
