extends Control
## Overlay mini-gry słuchowej. Podpina ListeningSession do aktywnego questu.

@onready var title_label: Label = $Panel/VBox/Title
@onready var status_label: Label = $Panel/VBox/Status
@onready var noise_label: Label = $Panel/VBox/NoiseInfo

var _session: ListeningSession


func _ready() -> void:
	visible = false
	QuestManager.quest_started.connect(_on_quest_started)


func _on_quest_started(quest: QuestDefinition) -> void:
	visible = true
	title_label.text = quest.title
	status_label.text = "Słuchaj uważnie…"
	var noise_txt := "Szum: wyłączony"
	if NoiseSettings.enabled:
		noise_txt = "Szum: %s · poziom względny %.0f%%" % [
			NoiseSettings.noise_type, NoiseSettings.relative_level * 100.0
		]
	noise_label.text = noise_txt + "\n(to nie jest kliniczny SNR)"

	_session = ListeningSession.new()
	add_child(_session)
	_session.session_finished.connect(_on_session_finished)
	_session.start_from_quest(quest)


func _on_session_finished(success: bool, detail: Dictionary) -> void:
	status_label.text = "Udało się!" if success else "Spróbuj jeszcze raz."
	print("[ListeningOverlay] wynik=%s detail=%s" % [success, detail])
	await get_tree().create_timer(0.8).timeout
	visible = false
	if is_instance_valid(_session):
		_session.queue_free()
		_session = null
	QuestManager.complete_active_quest(success)
