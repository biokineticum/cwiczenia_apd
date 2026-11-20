extends Node3D
## NPC: wejście → oferta (odnawialna). Badge nie gate'uje.
## PL-18 anty-spam + twardy kontrakt renew po quest_finished.

const QuestDefinition = preload("res://scripts/quest/quest_definition.gd")
const StylizedCharacterBuilder = preload("res://scripts/art/stylized_character_builder.gd")

const ENTER_DWELL_SEC := 0.28
const COOLDOWN_MS := 4000
const POST_QUEST_COOLDOWN_MS := 900

@export var npc_id: String = "npc_echo"
@export var display_name: String = "Echo"
@export var body_color: Color = Color(0.35, 0.55, 0.85, 1)
@export_enum("echo", "storm", "girl") var character_style: String = "echo"

var _player_near: bool = false
var _dwell_t: float = 0.0
var _cooldown_until: int = 0
var _talk_latched: bool = false
var _area_enabled: bool = true
var _area: Area3D = null


func _ready() -> void:
	add_to_group("npc")
	_area = $InteractionArea
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	if has_node("NameLabel"):
		$NameLabel.visible = false
	_rebuild_visual()
	# Defer: physics world + terrain HeightMap must exist before raycast.
	call_deferred("_snap_feet_to_ground")
	QuestManager.quest_finished.connect(_on_quest_finished)
	QuestManager.interact_available.connect(_on_interact_available)


func _physics_process(delta: float) -> void:
	_sync_area_enabled()
	if not _area_enabled or not _player_near or _talk_latched:
		_dwell_t = 0.0
		return
	if QuestManager.npc_interact_blocked():
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


func _sync_area_enabled() -> void:
	# Area wyłączona tylko podczas active/offer/dialog — nigdy „bo completed”.
	var want := not QuestManager.npc_interact_blocked()
	if want == _area_enabled:
		return
	var was := _area_enabled
	_area_enabled = want
	_area.set_deferred("monitoring", want)
	if not want:
		_player_near = false
		_dwell_t = 0.0
		get_tree().call_group("hud", "set_hint", "")
	elif not was:
		call_deferred("_refresh_overlap")


func _refresh_overlap() -> void:
	if _area == null or not is_instance_valid(_area):
		return
	if not _area.monitoring:
		return
	_player_near = false
	for body in _area.get_overlapping_bodies():
		if body is Node and (body as Node).is_in_group("player"):
			_player_near = true
			break
	_dwell_t = 0.0
	if _player_near and not QuestManager.npc_interact_blocked() and not _talk_latched:
		get_tree().call_group("hud", "set_hint", "porozmawiaj")


func on_quest_renew(for_npc_id: String) -> void:
	if for_npc_id != "" and for_npc_id != npc_id:
		return
	_talk_latched = false
	_cooldown_until = Time.get_ticks_msec() + POST_QUEST_COOLDOWN_MS
	# Wymuś Area ON jeśli manager już odblokował.
	if not QuestManager.npc_interact_blocked():
		_area_enabled = false # skłoń _sync do restore
		_sync_area_enabled()
	call_deferred("_refresh_overlap")


func _on_quest_finished(quest: Variant, _success: bool) -> void:
	if quest == null:
		return
	var q_npc := ""
	if typeof(quest) == TYPE_OBJECT and quest.get("npc_id") != null:
		q_npc = str(quest.npc_id)
	if q_npc != "" and q_npc != npc_id:
		return
	on_quest_renew(npc_id)


func _on_interact_available() -> void:
	_talk_latched = false
	_cooldown_until = maxi(_cooldown_until, Time.get_ticks_msec() + POST_QUEST_COOLDOWN_MS)
	call_deferred("_refresh_overlap")


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


## Place Node3D NPC origin on terrain (player uses CharacterBody3D floor snap).
func _snap_feet_to_ground() -> void:
	if not is_inside_tree():
		return
	var world := get_world_3d()
	if world == null:
		return
	var space := world.direct_space_state
	if space == null:
		return
	var from := global_position + Vector3(0.0, 12.0, 0.0)
	var to := global_position + Vector3(0.0, -40.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 # world / terrain
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		push_warning("[%s] ground snap missed — keep scene Y=%.3f" % [display_name, global_position.y])
		return
	var hit_y: float = hit.position.y
	global_position.y = hit_y
	print("[%s] feet snapped to ground Y=%.3f" % [display_name, hit_y])


func _try_talk() -> void:
	if _talk_latched or QuestManager.npc_interact_blocked():
		return
	var q: QuestDefinition = QuestManager.get_template_for_npc(npc_id)
	if q == null:
		print("[%s] Brak szablonu dla npc_id=%s" % [display_name, npc_id])
		get_tree().call_group("hud", "set_hint", "")
		return
	if not QuestManager.can_offer(q.id):
		# Soft rest — nie cisza / nie martwy NPC.
		QuestManager.offer_quest(q.id) # wywoła rest gdy daily_pool
		_talk_latched = true
		_cooldown_until = Time.get_ticks_msec() + COOLDOWN_MS
		return
	_talk_latched = true
	_cooldown_until = Time.get_ticks_msec() + COOLDOWN_MS
	ProgressStore.unlock_badge("met_%s" % npc_id)
	print("[%s] Wejście — start rozmowy (bez klikania)." % display_name)
	QuestManager.offer_quest(q.id)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_dwell_t = 0.0
		if not QuestManager.npc_interact_blocked() and not _talk_latched:
			get_tree().call_group("hud", "set_hint", "porozmawiaj")


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_dwell_t = 0.0
		_talk_latched = false
		get_tree().call_group("hud", "set_hint", "")
