extends Control
## Overlay mini-gry słuchowej z prawdziwym wyborem odpowiedzi + przełącznikiem szumu.

@onready var title_label: Label = $Panel/VBox/Title
@onready var status_label: Label = $Panel/VBox/Status
@onready var flash_label: Label = $Panel/VBox/Flash
@onready var noise_label: Label = $Panel/VBox/NoiseInfo
@onready var hint_label: Label = $Panel/VBox/Hint
@onready var choices_box: VBoxContainer = $Panel/VBox/Choices
@onready var selected_label: Label = $Panel/VBox/Selected
@onready var controls: HBoxContainer = $Panel/VBox/Controls
@onready var noise_toggle: CheckButton = $Panel/VBox/Controls/NoiseToggle
@onready var replay_btn: Button = $Panel/VBox/Controls/Replay
@onready var undo_btn: Button = $Panel/VBox/Controls/Undo

var _session: ListeningSession
var _building_ui: bool = false


func _ready() -> void:
	visible = false
	QuestManager.quest_started.connect(_on_quest_started)
	noise_toggle.toggled.connect(_on_noise_toggled)
	replay_btn.pressed.connect(func(): if _session: _session.replay())
	undo_btn.pressed.connect(func(): if _session: _session.undo_last())


func _on_quest_started(quest: QuestDefinition) -> void:
	visible = true
	title_label.text = quest.title
	status_label.text = "Przygotuj się…"
	flash_label.text = ""
	selected_label.text = ""
	_clear_choices()
	noise_toggle.set_pressed_no_signal(NoiseSettings.enabled)
	_refresh_noise_label()

	_session = ListeningSession.new()
	add_child(_session)
	_session.ui_changed.connect(_on_ui_changed)
	_session.session_finished.connect(_on_session_finished)
	_session.start_from_quest(quest)


func _on_ui_changed(state: Dictionary) -> void:
	title_label.text = str(state.get("title", title_label.text))
	status_label.text = str(state.get("prompt", ""))
	flash_label.text = str(state.get("flash", ""))
	hint_label.text = str(state.get("hint", ""))
	var selected: PackedStringArray = state.get("selected", PackedStringArray())
	if selected.size() > 0:
		selected_label.text = "Twoja kolejność: " + ", ".join(selected)
	else:
		selected_label.text = ""
	if state.has("noise_on"):
		noise_toggle.set_pressed_no_signal(bool(state["noise_on"]))
	_refresh_noise_label()
	var phase := str(state.get("phase", ""))
	undo_btn.visible = phase == "answer" and selected.size() > 0
	replay_btn.visible = phase == "answer" or phase == "present"
	noise_toggle.visible = true
	var choices: PackedStringArray = state.get("choices", PackedStringArray())
	if phase == "answer":
		_rebuild_choices(choices)
	elif phase != "answer":
		_clear_choices()


func _rebuild_choices(choices: PackedStringArray) -> void:
	_building_ui = true
	_clear_choices()
	for c in choices:
		var btn := Button.new()
		btn.text = str(c)
		btn.custom_minimum_size = Vector2(0, 48)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var captured := str(c)
		btn.pressed.connect(func(): _on_choice_pressed(captured))
		choices_box.add_child(btn)
	_building_ui = false


func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()


func _on_choice_pressed(text: String) -> void:
	if _session == null or _building_ui:
		return
	_session.submit_choice(text)


func _on_noise_toggled(pressed: bool) -> void:
	if _session:
		_session.set_noise_enabled(pressed)
	else:
		NoiseSettings.set_enabled(pressed)
	_refresh_noise_label()


func _refresh_noise_label() -> void:
	if NoiseSettings.enabled:
		noise_label.text = "Szum: %s · poziom względny %.0f%%\n(to nie jest kliniczny SNR)" % [
			NoiseSettings.noise_type, NoiseSettings.relative_level * 100.0
		]
	else:
		noise_label.text = "Szum: wyłączony\n(możesz włączyć dla trudniejszego treningu)"


func _on_session_finished(success: bool, detail: Dictionary) -> void:
	status_label.text = "Udało się! +punkty" if success else "Spróbuj jeszcze raz — bez kary."
	print("[ListeningOverlay] wynik=%s detail=%s" % [success, detail])
	await get_tree().create_timer(0.6).timeout
	visible = false
	_clear_choices()
	if is_instance_valid(_session):
		_session.queue_free()
		_session = null
	QuestManager.complete_active_quest(success)
