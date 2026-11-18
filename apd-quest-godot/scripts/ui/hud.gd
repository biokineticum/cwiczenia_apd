extends CanvasLayer
## HUD dziecka: bez paragrafów do czytania. Tekst/disclaimer → warstwa rodzica.
## Punkty = rząd ikon-słońc (nie „Punkty: N”).

const QuestDefinition = preload("res://scripts/quest/quest_definition.gd")
const IconFactory = preload("res://scripts/art/icon_factory.gd")
const SpeechPlayer = preload("res://scripts/audio/speech_player.gd")

@onready var points_label: Label = $Margin/VBox/PointsLabel
@onready var hint_label: Label = $Margin/VBox/HintLabel
@onready var disclaimer: Label = $Margin/VBox/Disclaimer
@onready var reward_toast: Label = $Margin/VBox/RewardToast
@onready var points_row: HBoxContainer = $Margin/VBox/PointsRow
@onready var interact_icon: TextureRect = $Margin/VBox/InteractIcon

var _speech: Node = null


func _ready() -> void:
	add_to_group("hud")
	ProgressStore.progress_changed.connect(_refresh)
	QuestManager.quest_finished.connect(_on_quest_finished)
	# Ukryj tekstowe etykiety — dziecko nie czyta.
	points_label.visible = false
	hint_label.visible = false
	disclaimer.visible = false
	if reward_toast:
		reward_toast.visible = false
		reward_toast.text = ""
	interact_icon.visible = false
	interact_icon.texture = IconFactory.get_icon("talk")
	_speech = SpeechPlayer.new()
	add_child(_speech)
	_refresh()


func _refresh() -> void:
	# Wizualne żetony zamiast napisu „Punkty: …”.
	for c in points_row.get_children():
		c.queue_free()
	var n := mini(12, maxi(0, ProgressStore.points / 10))
	if ProgressStore.points > 0 and n == 0:
		n = 1
	for i in n:
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(28, 28)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture = IconFactory.get_icon("sun")
		points_row.add_child(tex)


func set_hint(text: String) -> void:
	# Nie pokazuj tekstu dziecku — tylko ikona „porozmawiaj” gdy niepusty sygnał interakcji.
	var show_icon := text.strip_edges() != "" and ("porozmawiaj" in text.to_lower() or text.begins_with("E") or "rozmow" in text.to_lower())
	interact_icon.visible = show_icon
	hint_label.visible = false
	hint_label.text = ""


func _on_quest_finished(quest: QuestDefinition, success: bool) -> void:
	_refresh()
	if success:
		_speech.play_text("Brawo!")
	else:
		_speech.play_text("Spróbujmy jeszcze raz później.")
	# Bez toastu tekstowego na ekranie dziecka.
	if reward_toast:
		reward_toast.visible = false
		reward_toast.text = ""
