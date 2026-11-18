extends Node3D
## NPC z Area3D — E startuje ofertę questu; bajkowy wygląd z StylizedCharacterBuilder.

const QuestDefinition = preload("res://scripts/quest/quest_definition.gd")
const StylizedCharacterBuilder = preload("res://scripts/art/stylized_character_builder.gd")

@export var npc_id: String = "npc_echo"
@export var display_name: String = "Echo"
@export var body_color: Color = Color(0.35, 0.55, 0.85, 1)
@export_enum("echo", "storm", "girl") var character_style: String = "echo"

var _player_near: bool = false


func _ready() -> void:
	var area: Area3D = $InteractionArea
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	# Bez napisów imion nad NPC — dziecko nie czyta; rodzic wie kto jest kto z wyglądu.
	if has_node("NameLabel"):
		$NameLabel.visible = false
	_rebuild_visual()


func _rebuild_visual() -> void:
	var visual: Node3D = get_node_or_null("Visual")
	if visual == null:
		visual = Node3D.new()
		visual.name = "Visual"
		add_child(visual)
	for c in visual.get_children():
		c.queue_free()
	# Usuń stary pojedynczy mesh jeśli został w scenie
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
		get_tree().call_group("hud", "set_hint", "")
		return
	ProgressStore.unlock_badge("met_%s" % npc_id)
	QuestManager.offer_quest(q.id)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		# Ikona rozmowy (bez tekstu do czytania).
		get_tree().call_group("hud", "set_hint", "porozmawiaj")
		print("[%s] Podchodzisz — naciśnij E, by porozmawiać." % display_name)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		get_tree().call_group("hud", "set_hint", "")
