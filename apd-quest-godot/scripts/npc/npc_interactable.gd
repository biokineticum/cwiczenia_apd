extends Node3D
## NPC z Area3D — E startuje ofertę questu; aktualizuje hint HUD.

@export var npc_id: String = "npc_echo"
@export var display_name: String = "Echo"
@export var body_color: Color = Color(0.35, 0.55, 0.85, 1)

var _player_near: bool = false


func _ready() -> void:
	var area: Area3D = $InteractionArea
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	if has_node("NameLabel"):
		$NameLabel.text = display_name
	if has_node("MeshInstance3D"):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = body_color
		$MeshInstance3D.material_override = mat


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near:
		return
	if QuestManager.movement_locked:
		return
	if event.is_action_pressed("interact"):
		_try_talk()
		get_viewport().set_input_as_handled()


func _try_talk() -> void:
	var q: QuestDefinition = QuestManager.get_quest_for_npc(npc_id)
	if q == null:
		print("[%s] Brak questu dla npc_id=%s" % [display_name, npc_id])
		get_tree().call_group("hud", "set_hint", "%s nie ma teraz zadania." % display_name)
		return
	ProgressStore.unlock_badge("met_%s" % npc_id)
	QuestManager.offer_quest(q.id)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		get_tree().call_group(
			"hud",
			"set_hint",
			"E — porozmawiaj z %s" % display_name
		)
		print("[%s] Podchodzisz — naciśnij E, by porozmawiać." % display_name)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		get_tree().call_group(
			"hud",
			"set_hint",
			"WASD — ruch · PPM+mysz — kamera · E — rozmowa"
		)
