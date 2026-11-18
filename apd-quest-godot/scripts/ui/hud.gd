extends CanvasLayer
## HUD: punkty, hint interakcji, disclaimer treningowy.

@onready var points_label: Label = $Margin/VBox/PointsLabel
@onready var hint_label: Label = $Margin/VBox/HintLabel
@onready var disclaimer: Label = $Margin/VBox/Disclaimer
@onready var reward_toast: Label = $Margin/VBox/RewardToast


func _ready() -> void:
	add_to_group("hud")
	ProgressStore.progress_changed.connect(_refresh)
	QuestManager.quest_finished.connect(_on_quest_finished)
	disclaimer.text = "Trening wspomagający — nie diagnostyka. Poziom szumu jest względny."
	hint_label.text = "WASD — ruch · PPM+mysz — kamera · E — rozmowa"
	if reward_toast:
		reward_toast.text = ""
	_refresh()


func _refresh() -> void:
	points_label.text = "Punkty: %d  ·  Seria: %d dni" % [ProgressStore.points, ProgressStore.streak_days]


func set_hint(text: String) -> void:
	hint_label.text = text


func _on_quest_finished(quest: QuestDefinition, success: bool) -> void:
	if reward_toast == null:
		return
	if success:
		reward_toast.text = "Nagroda: +%d pkt · misja „%s” ukończona!" % [quest.reward_points, quest.title]
	else:
		reward_toast.text = "Możesz spróbować ponownie u %s — bez kary." % quest.title
	await get_tree().create_timer(3.5).timeout
	if is_instance_valid(reward_toast):
		reward_toast.text = ""
