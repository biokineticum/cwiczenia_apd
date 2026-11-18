extends Control
## Child-first overlay: ikony / sloty / duże targety. Tekst i szum → parent overlay.

const QuestDefinition = preload("res://scripts/quest/quest_definition.gd")
const ListeningSession = preload("res://scripts/listening/listening_session.gd")
const IconFactory = preload("res://scripts/art/icon_factory.gd")

@onready var ear_flash: TextureRect = $Panel/VBox/EarFlash
@onready var slots_row: HBoxContainer = $Panel/VBox/Slots
@onready var choices_grid: GridContainer = $Panel/VBox/Choices
@onready var controls: HBoxContainer = $Panel/VBox/Controls
@onready var replay_btn: TextureButton = $Panel/VBox/Controls/Replay
@onready var undo_btn: TextureButton = $Panel/VBox/Controls/Undo
@onready var parent_btn: TextureButton = $Panel/VBox/Controls/Parent
@onready var warm_feedback: TextureRect = $Panel/VBox/WarmFeedback
@onready var parent_overlay: Control = $ParentOverlay

var _session: ListeningSession
var _building_ui: bool = false
var _parent_press_ms: int = 0
var _last_state: Dictionary = {}
var _quest: QuestDefinition = null


func _ready() -> void:
	visible = false
	QuestManager.quest_started.connect(_on_quest_started)
	replay_btn.texture_normal = IconFactory.get_icon("ear")
	undo_btn.texture_normal = IconFactory.get_icon("undo")
	parent_btn.texture_normal = IconFactory.get_icon("parent")
	for b in [replay_btn, undo_btn, parent_btn]:
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(72, 72)
	replay_btn.pressed.connect(func(): if _session: _session.replay())
	undo_btn.pressed.connect(func(): if _session: _session.undo_last())
	parent_btn.button_down.connect(func(): _parent_press_ms = Time.get_ticks_msec())
	parent_btn.button_up.connect(_on_parent_released)
	if parent_overlay.has_signal("noise_toggled"):
		parent_overlay.noise_toggled.connect(_on_parent_noise)
	ear_flash.texture = IconFactory.get_icon("ear")
	warm_feedback.visible = false


func _on_quest_started(quest: QuestDefinition) -> void:
	_quest = quest
	visible = true
	warm_feedback.visible = false
	_clear_choices()
	_clear_slots()
	_session = ListeningSession.new()
	add_child(_session)
	_session.ui_changed.connect(_on_ui_changed)
	_session.session_finished.connect(_on_session_finished)
	# 5-latka: szum startuje wyłączony (rodzic może włączyć).
	NoiseSettings.set_enabled(false)
	_session.start_from_quest(quest)


func _on_ui_changed(state: Dictionary) -> void:
	_last_state = state
	var phase := str(state.get("phase", ""))
	var flash_icon := str(state.get("flash_icon", ""))
	if flash_icon != "":
		ear_flash.texture = IconFactory.get_icon(flash_icon)
		ear_flash.visible = true
		ear_flash.modulate = Color(1, 1, 1, 1)
	else:
		ear_flash.visible = phase == "present" or phase == "demo"
		if ear_flash.visible:
			ear_flash.texture = IconFactory.get_icon("ear")

	_rebuild_slots(state.get("slots", []))
	if phase == "answer":
		_rebuild_choices(state.get("choices", []))
	elif phase in ["present", "demo", "retry", "result"]:
		if phase != "answer":
			_clear_choices()

	undo_btn.visible = bool(state.get("can_undo", false))
	replay_btn.visible = phase == "answer" or phase == "present" or phase == "retry"
	parent_btn.visible = true

	if phase == "retry" or (phase == "result" and not bool(state.get("success", true))):
		_show_warm_retry()
	elif phase == "result" and bool(state.get("success", false)):
		_show_warm_success()


func _rebuild_slots(slots: Array) -> void:
	_clear_slots()
	for s in slots:
		var holder := PanelContainer.new()
		holder.custom_minimum_size = Vector2(88, 88)
		var tex := TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(80, 80)
		if typeof(s) == TYPE_DICTIONARY:
			var icon := str(s.get("icon", ""))
			var empty := bool(s.get("empty", false))
			var ghost := bool(s.get("ghost", false))
			if icon != "" and not empty:
				tex.texture = IconFactory.get_icon(icon)
				tex.modulate = Color(1, 1, 1, 0.45) if ghost else Color.WHITE
			else:
				tex.modulate = Color(1, 1, 1, 0.15)
				tex.texture = IconFactory.get_icon("ear")
		holder.add_child(tex)
		slots_row.add_child(holder)


func _rebuild_choices(choices: Array) -> void:
	_building_ui = true
	_clear_choices()
	choices_grid.columns = 2 if choices.size() > 2 else maxi(1, choices.size())
	for c in choices:
		var id := ""
		var icon := "ear"
		var used := false
		if typeof(c) == TYPE_DICTIONARY:
			id = str(c.get("id", ""))
			icon = str(c.get("icon", "ear"))
			used = bool(c.get("used", false))
		else:
			id = str(c)
			icon = str(c)
		var btn := TextureButton.new()
		btn.texture_normal = IconFactory.get_icon(icon)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(132, 132)
		btn.disabled = used
		btn.modulate = Color(1, 1, 1, 0.35) if used else Color.WHITE
		var captured := id
		btn.pressed.connect(func(): _on_choice_pressed(captured))
		choices_grid.add_child(btn)
	_building_ui = false


func _clear_choices() -> void:
	for child in choices_grid.get_children():
		child.queue_free()


func _clear_slots() -> void:
	for child in slots_row.get_children():
		child.queue_free()


func _on_choice_pressed(id: String) -> void:
	if _session == null or _building_ui or id == "":
		return
	_session.submit_choice(id)


func _on_parent_released() -> void:
	var held := Time.get_ticks_msec() - _parent_press_ms
	if held < 1200:
		return
	var stimulus := str(_last_state.get("parent_text", ""))
	var blurb := ""
	if _quest:
		# parent_blurb opcjonalnie z JSON — QuestDefinition może nie mieć pola; czytamy z raw.
		blurb = _load_parent_blurb(_quest.id)
	parent_overlay.open_with(stimulus, blurb, NoiseSettings.enabled)


func _load_parent_blurb(quest_id: String) -> String:
	var path := "res://data/quests.json"
	if not FileAccess.file_exists(path):
		return ""
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	for q in data.get("quests", []):
		if str(q.get("id", "")) == quest_id:
			return str(q.get("parent_blurb", ""))
	return ""


func _on_parent_noise(enabled: bool) -> void:
	NoiseSettings.set_enabled(enabled)
	if _session:
		_session.set_noise_enabled(enabled)


func _show_warm_retry() -> void:
	warm_feedback.texture = IconFactory.get_icon("ear")
	warm_feedback.modulate = Color(1.0, 0.85, 0.55, 1)
	warm_feedback.visible = true


func _show_warm_success() -> void:
	warm_feedback.texture = IconFactory.get_icon("sun")
	warm_feedback.modulate = Color(1, 1, 1, 1)
	warm_feedback.visible = true


func _on_session_finished(success: bool, detail: Dictionary) -> void:
	print("[ListeningOverlay] wynik=%s detail=%s" % [success, detail])
	if success:
		_show_warm_success()
	else:
		_show_warm_retry()
	await get_tree().create_timer(0.7).timeout
	visible = false
	warm_feedback.visible = false
	_clear_choices()
	_clear_slots()
	if parent_overlay.visible:
		parent_overlay.visible = false
	if is_instance_valid(_session):
		_session.queue_free()
		_session = null
	QuestManager.complete_active_quest(success)
