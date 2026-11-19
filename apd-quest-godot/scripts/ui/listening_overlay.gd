extends Control
## Overlay: dla dziecka bez klików — Echo/Burza = świat 3D. Parent = long-press.

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
var _last_state: Dictionary = {}
var _quest: QuestDefinition = null
var _parent_press_ms: int = 0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Dim"):
		$Dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Panel"):
		$Panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	QuestManager.quest_started.connect(_on_quest_started)
	# Dziecko nie klika replay/undo/choices — tylko parent long-press.
	replay_btn.visible = false
	undo_btn.visible = false
	replay_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	undo_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_btn.texture_normal = IconFactory.get_icon("parent")
	parent_btn.ignore_texture_size = true
	parent_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	parent_btn.custom_minimum_size = Vector2(64, 64)
	parent_btn.button_down.connect(func(): _parent_press_ms = Time.get_ticks_msec())
	parent_btn.button_up.connect(_on_parent_released)
	if parent_overlay.has_signal("noise_toggled"):
		parent_overlay.noise_toggled.connect(_on_parent_noise)
	ear_flash.texture = IconFactory.get_icon("ear")
	warm_feedback.visible = false


func _on_quest_started(quest: QuestDefinition) -> void:
	_quest = quest
	visible = true
	if has_node("Dim"):
		$Dim.visible = false # do pierwszego _sync_dim — nie zasłaniaj świata
	warm_feedback.visible = false
	_clear_choices()
	_clear_slots()
	_session = ListeningSession.new()
	add_child(_session)
	_session.ui_changed.connect(_on_ui_changed)
	_session.session_finished.connect(_on_session_finished)
	NoiseSettings.set_enabled(false)
	_session.start_from_quest(quest)


func _on_ui_changed(state: Dictionary) -> void:
	_last_state = state
	var phase := str(state.get("phase", ""))
	var world_board := bool(state.get("world_board", false))
	var flash_icon := str(state.get("flash_icon", ""))
	# Zawsze tryb świata dla odpowiedzi — bez siatki klikanej.
	if world_board or phase == "answer":
		$Panel.visible = phase == "present" or phase == "demo" or phase == "retry" or phase == "result"
		if phase == "answer":
			$Panel.visible = false
			_clear_choices()
			_clear_slots()
	else:
		$Panel.visible = true
		_clear_choices() # nigdy nie buduj klikalnych choices

	# P0-2 / PL-27: Dim tylko przy panelu flash (present/demo/retry/result).
	# W answer / walk-board / Burza pady świat musi być jasny dla 5-latki.
	_sync_dim(phase, world_board)

	if flash_icon != "" and $Panel.visible:
		ear_flash.texture = IconFactory.get_icon(flash_icon)
		ear_flash.visible = true
	else:
		ear_flash.visible = $Panel.visible and (phase == "present" or phase == "demo")
		if ear_flash.visible:
			ear_flash.texture = IconFactory.get_icon("ear")

	replay_btn.visible = false
	undo_btn.visible = false
	_ensure_parent_corner(phase)

	if phase == "retry" or (phase == "result" and not bool(state.get("success", true))):
		_show_warm_retry()
	elif phase == "result" and bool(state.get("success", false)):
		_show_warm_success()


func _sync_dim(phase: String, world_board: bool) -> void:
	if not has_node("Dim"):
		return
	var dim: CanvasItem = $Dim
	# Walk / answer: zero dim. Flash panel phases may keep soft dim.
	# Explicit bool: Godot 4.7 cannot infer := from `$Panel.visible` (Variant).
	var walk_answer: bool = phase == "answer" or (world_board and not $Panel.visible)
	dim.visible = not walk_answer and $Panel.visible


func _ensure_parent_corner(phase: String) -> void:
	# Tylko long-press rodzica — bez CornerReplay.
	if not has_node("CornerControls"):
		var box := HBoxContainer.new()
		box.name = "CornerControls"
		box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		box.offset_left = -90
		box.offset_top = 12
		box.offset_right = -12
		box.offset_bottom = 90
		box.alignment = BoxContainer.ALIGNMENT_END
		add_child(box)
		var parent := TextureButton.new()
		parent.name = "CornerParent"
		parent.texture_normal = IconFactory.get_icon("parent")
		parent.ignore_texture_size = true
		parent.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		parent.custom_minimum_size = Vector2(64, 64)
		parent.button_down.connect(func(): _parent_press_ms = Time.get_ticks_msec())
		parent.button_up.connect(_on_parent_released)
		box.add_child(parent)
	$CornerControls.visible = phase == "answer" or phase == "retry" or phase == "present"


func _clear_choices() -> void:
	for child in choices_grid.get_children():
		child.queue_free()


func _clear_slots() -> void:
	for child in slots_row.get_children():
		child.queue_free()


func _on_parent_released() -> void:
	var held := Time.get_ticks_msec() - _parent_press_ms
	if held < 1200:
		return
	var stimulus := str(_last_state.get("parent_text", ""))
	var blurb := ""
	if _quest:
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
	if has_node("Dim"):
		$Dim.visible = false
	warm_feedback.visible = false
	_clear_choices()
	_clear_slots()
	if parent_overlay.visible:
		parent_overlay.visible = false
	if is_instance_valid(_session):
		_session.queue_free()
		_session = null
	QuestManager.complete_active_quest(success)
