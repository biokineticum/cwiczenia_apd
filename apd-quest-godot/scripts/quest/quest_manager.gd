extends Node
## Centralna pętla: start questu → mini-gra słuchowa → nagroda / dialog zakończenia.

signal quest_started(quest: QuestDefinition)
signal quest_finished(quest: QuestDefinition, success: bool)
signal dialog_requested(lines: PackedStringArray, quest_id: String, phase: String)

var _quests: Dictionary = {} # id -> QuestDefinition
var active_quest: QuestDefinition = null
var movement_locked: bool = false


func _ready() -> void:
	_load_quests()


func _load_quests() -> void:
	var path := "res://data/quests.json"
	if not FileAccess.file_exists(path):
		push_warning("Brak data/quests.json")
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return
	for item in data.get("quests", []):
		var q := QuestDefinition.from_dict(item)
		_quests[q.id] = q
	print("[QuestManager] Załadowano questów: %d" % _quests.size())


func get_quest(quest_id: String) -> QuestDefinition:
	return _quests.get(quest_id, null)


func get_quest_for_npc(npc_id: String) -> QuestDefinition:
	for q in _quests.values():
		if q.npc_id == npc_id:
			return q
	return null


func offer_quest(quest_id: String) -> void:
	var q: QuestDefinition = get_quest(quest_id)
	if q == null:
		push_warning("Nieznany quest: %s" % quest_id)
		return
	dialog_requested.emit(q.dialog_offer, q.id, "offer")


func start_quest(quest_id: String) -> void:
	var q: QuestDefinition = get_quest(quest_id)
	if q == null:
		return
	active_quest = q
	movement_locked = true
	quest_started.emit(q)
	print("[QuestManager] Start: %s (%s)" % [q.title, q.exercise_type])


func complete_active_quest(success: bool) -> void:
	if active_quest == null:
		return
	var q := active_quest
	if success:
		ProgressStore.add_points(q.reward_points)
		ProgressStore.unlock_badge("quest_%s" % q.id)
		dialog_requested.emit(q.dialog_done, q.id, "done")
	active_quest = null
	movement_locked = false
	quest_finished.emit(q, success)
