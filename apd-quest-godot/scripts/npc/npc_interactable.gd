extends Node3D
## NPC: wejdź postacią w strefę → start rozmowy (bez E / bez klikania).

const QuestDefinition = preload("res://scripts/quest/quest_definition.gd")
const StylizedCharacterBuilder = preload("res://scripts/art/stylized_character_builder.gd")

const ENTER_DWELL_SEC := 0.22
const COOLDOWN_MS := 2500

@export var npc_id: String = "npc_echo"
@export var display_name: String = "Echo"
@export var body_color: Color = Color(0.35, 0.55, 0.85, 1)
@export_enum("echo", "storm", "girl") var character_style: String = "echo"

var _player_near: bool = false
var _dwell_t: float = 0.0
var _cooldown_until: int = 0


func _ready() -> void:
	var area: Area3D = $InteractionArea
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	if has_node("NameLabel"):
		$NameLabel.visible = false
	_rebuild_visual()


func _physics_process(delta: float) -> void:
	if not _player_near:
		_dwell_t = 0.0
		return
	if QuestManager.movement_locked:
		_dwell_t = 0.0
		return
	if Time.get_ticks_msec() < _cooldown_until:
		return
	_dwell_t += delta
	if _dwell_t >= ENTER_DWELL_SEC:
		_dwell_t = 0.0
		_try_talk()


func _rebuild_visual() -> void:
	var visual: Node3D = get_node_or_null("Visual")
	if visual == null:
		visual = Node3D.new()
		visual.name = "Visual"
		add_child(visual)
	for c in visual.get_children():
		c.queue_free()
	if has_node("MeshInstance3D"):
		$MeshInstance3D.hide()
	var style := StylizedCharacterBuilder.Style.ECHO
	match character_style:
		"storm":
			style = StylizedCharacterBuilder.Style.STORM
		"girl":
			style = StylizedCharacterBuilder.Style.GIRL
		_:
			style = StylizedCharacterBuilder.Style.ECHO
	var built := StylizedCharacterBuilder.build(style, body_color)
	while built.get_child_count() > 0:
		var child := built.get_child(0)
		built.remove_child(child)
		visual.add_child(child)
	built.free()


func _try_talk() -> void:
	var q: QuestDefinition = QuestManager.get_quest_for_npc(npc_id)
	if q == null:
		print("[%s] Brak questu dla npc_id=%s" % [display_name, npc_id])
		get_tree().call_group("hud", "set_hint", "")
		return
	_cooldown_until = Time.get_ticks_msec() + COOLDOWN_MS
	ProgressStore.unlock_badge("met_%s" % npc_id)
	print("[%s] Wejście — start rozmowy (bez klikania)." % display_name)
	QuestManager.offer_quest(q.id)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_dwell_t = 0.0
		get_tree().call_group("hud", "set_hint", "porozmawiaj")


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_dwell_t = 0.0
		get_tree().call_group("hud", "set_hint", "")
