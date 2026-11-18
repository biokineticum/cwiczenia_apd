extends Node3D
## NPC z Area3D — E / touch startuje ofertę questu.

@export var npc_id: String = "npc_echo"
@export var display_name: String = "Echo"

var _player_near: bool = false


func _ready() -> void:
	var area: Area3D = $InteractionArea
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near:
		return
	if event.is_action_pressed("interact"):
		_try_talk()


func _try_talk() -> void:
	var q: QuestDefinition = QuestManager.get_quest_for_npc(npc_id)
	if q == null:
		print("[%s] Brak questu dla npc_id=%s" % [display_name, npc_id])
		return
	QuestManager.offer_quest(q.id)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		print("[%s] Podchodzisz — naciśnij E, by porozmawiać." % display_name)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
