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
		return "talk"
	if q.npc_id == "npc_storm":
		return "rain"
	if q.npc_id == "npc_echo":
		return "talk"
	return "play"


func _speak_lines(lines: PackedStringArray) -> void:
	_speaking = true
	for line in lines:
		if not _speaking or not visible:
			break
		var t := str(line).strip_edges()
		if t == "":
			continue
		_speech.play_text(t)
		await _speech.finished
		if not _speaking or not visible:
			break
		await get_tree().create_timer(0.12).timeout
	_speaking = false


func _spawn_walk_zones() -> void:
	_clear_zones()
	var q: QuestDefinition = QuestManager.get_quest(_quest_id)
	var npc := _find_quest_npc(q)
	var scene := get_tree().current_scene
	if scene == null:
		return
	# Kotwica = NPC; padd'y na polanie od strony środka mapy (nie w drzewa / nie przez mesh).
	var anchor := Vector3(0, 0.05, 2.0)
	if npc:
		anchor = npc.global_position
	var npc_id := ""
	if npc:
		npc_id = str(npc.get("npc_id"))
	elif q:
		npc_id = str(q.npc_id)
	# Echo na zachodzie → padd'y na wschód (+X) ku środkowi; Burza → na zachód (−X).
	var inward := Vector3.RIGHT
	if npc_id == "npc_storm":
		inward = Vector3.LEFT
	elif npc_id == "npc_echo":
		inward = Vector3.RIGHT
	elif anchor.x > 0.0:
		inward = Vector3.LEFT
	# 2–4 m czysto z boku (ten sam Z co NPC dla play) + close dalej wzdłuż Z.
	# Keep pads on the flat NPC stand pad (fairy_clearing NPC_PAD_HALF_XZ ≈ 4.5).
	const INWARD := 3.2
	const ALONG_GO := 0.0
	const ALONG_LEAVE := -2.8
	var go_pos := anchor + inward * INWARD + Vector3(0.0, 0.0, ALONG_GO)
	var leave_pos := anchor + inward * INWARD + Vector3(0.0, 0.0, ALONG_LEAVE)
	go_pos.y = _ground_y_at(go_pos, anchor.y)
	leave_pos.y = _ground_y_at(leave_pos, anchor.y)
	var go: Area3D = WalkZone.new()
	scene.add_child(go)
	if _phase == "offer":
		go.setup("accept", "play", go_pos, Color(0.35, 0.78, 0.45))
	else:
		go.setup("accept", "check", go_pos, Color(0.35, 0.78, 0.45))
	go.walked_in.connect(_on_zone)
	_zones.append(go)
	if _phase == "offer":
		var leave: Area3D = WalkZone.new()
		scene.add_child(leave)
		leave.setup("dismiss", "close", leave_pos, Color(0.75, 0.45, 0.4))
		leave.walked_in.connect(_on_zone)
		_zones.append(leave)


func _find_quest_npc(q: QuestDefinition) -> Node3D:
	if q == null:
		return null
	var want := str(q.npc_id)
	for n in get_tree().get_nodes_in_group("npc"):
		if n is Node3D and str(n.get("npc_id")) == want:
			return n as Node3D
	# Fallback po nazwie sceny.
	var scene := get_tree().current_scene
	if scene == null:
		return null
	if want == "npc_echo":
		return scene.get_node_or_null("NpcEcho") as Node3D
	if want == "npc_storm":
		return scene.get_node_or_null("NpcStorm") as Node3D
	return null


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
		# done / rest — odblokuj renew
		QuestManager.end_dialog()
		QuestManager.movement_locked = false
		dismissed.emit()


func _do_dismiss() -> void:
	if _speaking:
		_speech.stop()
		_speaking = false
	visible = false
	title_label.visible = false
	body_label.visible = false
	QuestManager.end_dialog()
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
			# Nie usuwaj CollisionObject w środku fizyki / sygnału Area.
			z.set_deferred("monitoring", false)
			z.call_deferred("queue_free")
	_zones.clear()


func _find_player() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0] as Node3D


## Snap pad Y to terrain so Burza/Echo confirm circles stay enterable on rim hills.
func _ground_y_at(at: Vector3, fallback_y: float) -> float:
	var world := get_viewport().world_3d if get_viewport() else null
	if world == null:
		return fallback_y + 0.02
	var space := world.direct_space_state
	if space == null:
		return fallback_y + 0.02
	var query := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, 20.0, at.z), Vector3(at.x, -40.0, at.z)
	)
	query.collision_mask = 1
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return fallback_y + 0.02
	return float(hit.position.y) + 0.02


func _exit_tree() -> void:
	_clear_zones()
