extends Control
## Dialog 5-latki: TTS + potwierdzenie WEJŚCIEM w strefę 3D (bez klikania play/close).
## Long-press ikony rodzica zostaje (tekst dla dorosłego).

const QuestDefinition = preload("res://scripts/quest/quest_definition.gd")
const IconFactory = preload("res://scripts/art/icon_factory.gd")
const SpeechPlayer = preload("res://scripts/audio/speech_player.gd")
const WalkZone = preload("res://scripts/world/walk_confirm_zone.gd")

signal accepted(quest_id: String)
signal dismissed

@onready var title_label: Label = $Panel/VBox/Title
@onready var body_label: Label = $Panel/VBox/Body
@onready var npc_icon: TextureRect = $Panel/VBox/NpcIcon
@onready var accept_btn: TextureButton = $Panel/VBox/Buttons/Accept
@onready var close_btn: TextureButton = $Panel/VBox/Buttons/Close
@onready var parent_btn: TextureButton = $Panel/VBox/Buttons/ParentText
@onready var panel: PanelContainer = $Panel
@onready var dim: ColorRect = $Dim

var _quest_id: String = ""
var _phase: String = ""
var _lines: PackedStringArray = PackedStringArray()
var _speech: Node = null
var _speaking: bool = false
var _zones: Array = []
var _parent_press_ms: int = 0


func _ready() -> void:
	visible = false
	title_label.visible = false
	body_label.visible = false
	# Dziecko nie klika — usuń accept/close z drzewa; zostaw parent (long-press).
	accept_btn.visible = false
	close_btn.visible = false
	accept_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accept_btn.queue_free()
	close_btn.queue_free()
	parent_btn.texture_normal = IconFactory.get_icon("parent")
	parent_btn.ignore_texture_size = true
	parent_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	parent_btn.custom_minimum_size = Vector2(72, 72)
	parent_btn.button_down.connect(func(): _parent_press_ms = Time.get_ticks_msec())
	parent_btn.button_up.connect(_on_parent_released)
	# Bez przyciemnienia / centralnego „kliknij mnie” — widać kółka na ziemi.
	dim.visible = false
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_corner_chrome()
	QuestManager.dialog_requested.connect(show_dialog)
	_speech = SpeechPlayer.new()
	add_child(_speech)


func _layout_corner_chrome() -> void:
	# Mały pasek u góry — ikona rozmowy + parent; CTA = zielone kółko w świecie.
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.anchor_bottom = 0.0
	panel.offset_left = 12.0
	panel.offset_top = 12.0
	panel.offset_right = -12.0
	panel.offset_bottom = 120.0
	npc_icon.custom_minimum_size = Vector2(72, 72)


func show_dialog(lines: PackedStringArray, quest_id: String, phase: String) -> void:
	_clear_zones()
	_quest_id = quest_id
	_phase = phase
	_lines = lines
	var q: QuestDefinition = QuestManager.get_quest(quest_id)
	title_label.visible = false
	body_label.visible = false
	body_label.text = "\n".join(lines)
	title_label.text = q.title if q else ""
	npc_icon.texture = IconFactory.get_icon(_npc_icon_for(q))
	npc_icon.visible = true
	parent_btn.visible = true
	dim.visible = false
	visible = true
	# Najpierw głos przy zablokowanym ruchu, potem strefy + chodzenie.
	QuestManager.movement_locked = true
	await _speak_lines(lines)
	_spawn_walk_zones()
	QuestManager.movement_locked = false
	if _speech:
		if phase == "offer":
			_speech.play_text("Wejdź w zielone kółko, żeby zacząć.")
		else:
			_speech.play_text("Wejdź w zielone kółko.")


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
		await get_tree().create_timer(0.12).timeout
	_speaking = false


func _spawn_walk_zones() -> void:
	_clear_zones()
	var player := _find_player()
	var origin := Vector3(0, 0.05, 2.0)
	if player:
		origin = player.global_position
	var scene := get_tree().current_scene
	if scene == null:
		return
	# Zielone = akceptuj / OK (przed dziewczynką)
	var go: Area3D = WalkZone.new()
	scene.add_child(go)
	var go_pos := origin + Vector3(0.0, 0.0, -1.8)
	if _phase == "offer":
		go.setup("accept", "play", go_pos, Color(0.35, 0.78, 0.45))
	else:
		go.setup("accept", "check", go_pos, Color(0.35, 0.78, 0.45))
	go.walked_in.connect(_on_zone)
	_zones.append(go)
	# Szare/czerwone = nie teraz (tylko oferta) — na bok
	if _phase == "offer":
		var leave: Area3D = WalkZone.new()
		scene.add_child(leave)
		leave.setup("dismiss", "close", origin + Vector3(2.4, 0.0, -0.6), Color(0.75, 0.45, 0.4))
		leave.walked_in.connect(_on_zone)
		_zones.append(leave)


func _on_zone(zone: Area3D) -> void:
	var k := str(zone.get("kind"))
	_clear_zones()
	if k == "accept":
		_do_accept()
	else:
		_do_dismiss()


func _do_accept() -> void:
	if _speaking:
		_speech.stop()
		_speaking = false
	visible = false
	title_label.visible = false
	body_label.visible = false
	if _phase == "offer":
		accepted.emit(_quest_id)
		QuestManager.start_quest(_quest_id)
	else:
		QuestManager.movement_locked = false
		dismissed.emit()


func _do_dismiss() -> void:
	if _speaking:
		_speech.stop()
		_speaking = false
	visible = false
	title_label.visible = false
	body_label.visible = false
	QuestManager.movement_locked = false
	dismissed.emit()


func _on_parent_released() -> void:
	var held := Time.get_ticks_msec() - _parent_press_ms
	if held < 1200:
		return
	body_label.visible = not body_label.visible
	title_label.visible = body_label.visible


func _clear_zones() -> void:
	for z in _zones:
		if is_instance_valid(z):
			z.queue_free()
	_zones.clear()


func _find_player() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0] as Node3D


func _exit_tree() -> void:
	_clear_zones()
