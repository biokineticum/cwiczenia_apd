extends Control
## Dialog dla 5-latki: treść = TTS (głos), przyciski = duże ikony. Tekst tylko w parent overlay.

const QuestDefinition = preload("res://scripts/quest/quest_definition.gd")
const IconFactory = preload("res://scripts/art/icon_factory.gd")
const SpeechPlayer = preload("res://scripts/audio/speech_player.gd")

signal accepted(quest_id: String)
signal dismissed

@onready var title_label: Label = $Panel/VBox/Title
@onready var body_label: Label = $Panel/VBox/Body
@onready var npc_icon: TextureRect = $Panel/VBox/NpcIcon
@onready var accept_btn: TextureButton = $Panel/VBox/Buttons/Accept
@onready var close_btn: TextureButton = $Panel/VBox/Buttons/Close
@onready var parent_btn: TextureButton = $Panel/VBox/Buttons/ParentText

var _quest_id: String = ""
var _phase: String = ""
var _lines: PackedStringArray = PackedStringArray()
var _speech: Node = null
var _speaking: bool = false


func _ready() -> void:
	visible = false
	title_label.visible = false
	body_label.visible = false
	accept_btn.texture_normal = IconFactory.get_icon("play")
	close_btn.texture_normal = IconFactory.get_icon("close")
	parent_btn.texture_normal = IconFactory.get_icon("parent")
	for b in [accept_btn, close_btn, parent_btn]:
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(96, 96)
	accept_btn.pressed.connect(_on_accept)
	close_btn.pressed.connect(_on_close)
	parent_btn.pressed.connect(_toggle_parent_text)
	QuestManager.dialog_requested.connect(show_dialog)
	_speech = SpeechPlayer.new()
	add_child(_speech)


func show_dialog(lines: PackedStringArray, quest_id: String, phase: String) -> void:
	_quest_id = quest_id
	_phase = phase
	_lines = lines
	var q: QuestDefinition = QuestManager.get_quest(quest_id)
	# Zero tekstu dla dziecka — napisy tylko po ikonie rodzica.
	title_label.visible = false
	body_label.visible = false
	body_label.text = "\n".join(lines)
	title_label.text = q.title if q else ""
	npc_icon.texture = IconFactory.get_icon(_npc_icon_for(q))
	npc_icon.visible = true
	accept_btn.visible = phase == "offer"
	accept_btn.texture_normal = IconFactory.get_icon("play")
	close_btn.texture_normal = IconFactory.get_icon("check" if phase == "done" else "close")
	parent_btn.visible = true
	QuestManager.movement_locked = true
	visible = true
	_speak_lines(lines)


func _npc_icon_for(q: QuestDefinition) -> String:
	if q == null:
		return "ear"
	if q.npc_id == "npc_storm":
		return "rain"
	if q.npc_id == "npc_echo":
		return "ear"
	return "play"


func _speak_lines(lines: PackedStringArray) -> void:
	_speaking = true
	for line in lines:
		var t := str(line).strip_edges()
		if t == "":
			continue
		_speech.play_text(t)
		await _speech.finished
		await get_tree().create_timer(0.15).timeout
	_speaking = false


func _toggle_parent_text() -> void:
	# Pełny tekst dialogu tylko dla rodzica (ikona dorosłego).
	body_label.visible = not body_label.visible
	title_label.visible = body_label.visible


func _on_accept() -> void:
	if _speaking:
		_speech.stop()
		_speaking = false
	visible = false
	title_label.visible = false
	body_label.visible = false
	accepted.emit(_quest_id)
	QuestManager.start_quest(_quest_id)


func _on_close() -> void:
	if _speaking:
		_speech.stop()
		_speaking = false
	visible = false
	title_label.visible = false
	body_label.visible = false
	if _phase != "offer" or QuestManager.active_quest == null:
		QuestManager.movement_locked = false
	dismissed.emit()
