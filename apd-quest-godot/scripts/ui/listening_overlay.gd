extends Control
## Overlay: dla dziecka bez klików — Echo/Burza = świat 3D + TTS.
## Present/demo: tylko TTS (+ lekki dim) — bez abstrakcyjnej ikony ucha / EarFlash.
## Parent = tylko long-press w rogu. Reset sekwencji = pomarańczowe kółko 3D (walk).

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
	# Dziecko nie klika replay/undo/choices — parent tylko w rogu (CornerControls).
	replay_btn.visible = false
	undo_btn.visible = false
	parent_btn.visible = false
	controls.visible = false
	replay_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	undo_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip_panel_chrome()
	if parent_overlay.has_signal("noise_toggled"):
		parent_overlay.noise_toggled.connect(_on_parent_noise)
	# EarFlash usunięty z UX — node zostaje w scenie, zawsze ukryty.
	ear_flash.visible = false
	ear_flash.texture = null
	warm_feedback.visible = false


func _strip_panel_chrome() -> void:
	# Bez kremowej karty PanelContainer.
	var empty := StyleBoxEmpty.new()
	$Panel.add_theme_stylebox_override("panel", empty)
	$Panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Panel/VBox"):
		$Panel/VBox.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _layout_feedback_cue() -> void:
	var panel: Control = $Panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -90.0
	panel.offset_right = 90.0
	panel.offset_top = -90.0
	panel.offset_bottom = 90.0


func _on_quest_started(quest: QuestDefinition) -> void:
	_quest = quest
	visible = true
	if has_node("Dim"):
		$Dim.visible = false # do pierwszego _sync_dim — nie zasłaniaj świata
	warm_feedback.visible = false
	ear_flash.visible = false
	_clear_choices()
	_clear_slots()
	_session = ListeningSession.new()
	add_child(_session)
	_session.ui_changed.connect(_on_ui_changed)
	_session.session_finished.connect(_on_session_finished)
	# Echo: szum opcjonalny — zostaw wybór rodzica z sesji (domyślnie OFF z JSON).
	# Burza = „mowa w szumie” — włącz szum na starcie (rodzic może wyłączyć w overlay).
	if str(quest.exercise_type) == "speech_in_noise":
		NoiseSettings.set_enabled(true)
	_session.start_from_quest(quest)


func _on_ui_changed(state: Dictionary) -> void:
	_last_state = state
	var phase := str(state.get("phase", ""))
	var world_board := bool(state.get("world_board", false))
	# Center Controls zawsze ukryte — zero stacku ikon.
	controls.visible = false
	replay_btn.visible = false
	undo_btn.visible = false
	parent_btn.visible = false
	# Nigdy nie pokazuj abstrakcyjnego ucha / flash_icon — TTS wystarczy.
	ear_flash.visible = false

	if phase == "answer" or (world_board and phase != "present" and phase != "demo" and phase != "retry" and phase != "result"):
		$Panel.visible = false
		_clear_choices()
		_clear_slots()
	elif phase == "present" or phase == "demo":
		# Tylko TTS (+ lekki dim) — bez ikony „słuchaj” / EarFlash.
		$Panel.visible = false
		_clear_choices()
		_clear_slots()
		warm_feedback.visible = false
	elif phase == "retry" or phase == "result":
		_layout_feedback_cue()
		$Panel.visible = true
		_clear_choices()
		_clear_slots()
	else:
		$Panel.visible = true
		_clear_choices()

	_sync_dim(phase, world_board)
	_ensure_parent_corner(phase)

	if phase == "retry" or (phase == "result" and not bool(state.get("success", true))):
		_show_warm_retry()
	elif phase == "result" and bool(state.get("success", false)):
		_show_warm_success()


func _sync_dim(phase: String, world_board: bool) -> void:
	if not has_node("Dim"):
		return
	var dim: ColorRect = $Dim
	# Walk / answer: zero dim. Present/demo: lekki cień (nie modalna karta).
	var walk_answer: bool = phase == "answer" or (world_board and not $Panel.visible and phase != "present" and phase != "demo")
	if walk_answer:
		dim.visible = false
		return
	if phase == "present" or phase == "demo":
		dim.visible = true
		dim.color = Color(0.08, 0.16, 0.14, 0.22)
		return
	if phase == "retry" or phase == "result":
		dim.visible = true
		dim.color = Color(0.08, 0.16, 0.14, 0.35)
		return
	dim.visible = $Panel.visible
	dim.color = Color(0.08, 0.16, 0.14, 0.28)


func _ensure_parent_corner(phase: String) -> void:
	# Tylko long-press rodzica — w rogu.
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
		parent.custom_minimum_size = Vector2(56, 56)
		parent.modulate = Color(1, 1, 1, 0.85)
		parent.button_down.connect(func(): _parent_press_ms = Time.get_ticks_msec())
		parent.button_up.connect(_on_parent_released)
		box.add_child(parent)
	$CornerControls.visible = phase == "answer" or phase == "retry" or phase == "present" or phase == "demo"


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
	ear_flash.visible = false
	# Bez abstrakcyjnego ucha — „spróbuj jeszcze” = undo, nie concentric ear.
	warm_feedback.texture = IconFactory.get_icon("undo")
	warm_feedback.modulate = Color(1.0, 0.85, 0.55, 1)
	warm_feedback.visible = true


func _show_warm_success() -> void:
	ear_flash.visible = false
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
	ear_flash.visible = false
	_clear_choices()
	_clear_slots()
	if parent_overlay.visible:
		parent_overlay.visible = false
	if is_instance_valid(_session):
		_session.queue_free()
		_session = null
	QuestManager.complete_active_quest(success)
