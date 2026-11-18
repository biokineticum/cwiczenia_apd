extends Control
## Prosty panel dialogu PL. Przy ofercie questu: „Zaczynam!” startuje mini-grę.

signal accepted(quest_id: String)
signal dismissed

@onready var title_label: Label = $Panel/VBox/Title
@onready var body_label: Label = $Panel/VBox/Body
@onready var accept_btn: Button = $Panel/VBox/Buttons/Accept
@onready var close_btn: Button = $Panel/VBox/Buttons/Close

var _quest_id: String = ""
var _phase: String = ""


func _ready() -> void:
	visible = false
	accept_btn.pressed.connect(_on_accept)
	close_btn.pressed.connect(_on_close)
	QuestManager.dialog_requested.connect(show_dialog)


func show_dialog(lines: PackedStringArray, quest_id: String, phase: String) -> void:
	_quest_id = quest_id
	_phase = phase
	var q: QuestDefinition = QuestManager.get_quest(quest_id)
	title_label.text = q.title if q else "Rozmowa"
	body_label.text = "\n".join(lines)
	accept_btn.visible = phase == "offer"
	accept_btn.text = "Zaczynam!"
	close_btn.text = "OK" if phase == "done" else "Nie teraz"
	QuestManager.movement_locked = true
	visible = true


func _on_accept() -> void:
	visible = false
	accepted.emit(_quest_id)
	QuestManager.start_quest(_quest_id)


func _on_close() -> void:
	visible = false
	if _phase != "offer" or QuestManager.active_quest == null:
		QuestManager.movement_locked = false
	dismissed.emit()
