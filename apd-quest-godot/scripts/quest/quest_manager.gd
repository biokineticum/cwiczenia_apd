extends Node
## Template ≠ run. Echo/Burza odnawialne w nieskończoność (trening).
## Badge first-clear = kosmetyka — NIGDY nie gate'uje can_offer.
## preload: class_name niedostępne przy cold `--path` bez importu.

const QuestDefinition = preload("res://scripts/quest/quest_definition.gd")

signal quest_started(quest: QuestDefinition)
signal quest_finished(quest: QuestDefinition, success: bool)
signal dialog_requested(lines: PackedStringArray, quest_id: String, phase: String)
signal interact_available
signal rest_requested(quest_id: String, lines: PackedStringArray)

## Szablony (wieczne).
var templates: Dictionary = {} # id -> QuestDefinition
var active_quest: QuestDefinition = null
var movement_locked: bool = false
## Anty-spam oferty; ZAWSZE clear po done/cancel / complete.
var offering_quest_id: String = ""
## Dialog done/rest — krótka blokada, nie „completed forever”.
var dialog_busy: bool = false
## quest_id -> ostatnie bodźce (do anti-repeat).
var last_roll: Dictionary = {}
var runs_today: Dictionary = {}
var runs_lifetime: Dictionary = {}
var completion_counts: Dictionary = {}


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
		templates[q.id] = q
	print("[QuestManager] Szablonów: %d (renew infinite/daily_pool)" % templates.size())


func get_quest(quest_id: String) -> QuestDefinition:
	return templates.get(quest_id, null)


func get_template_for_npc(npc_id: String) -> QuestDefinition:
	for q in templates.values():
		if q.npc_id == npc_id:
			return q
	return null


func get_quest_for_npc(npc_id: String) -> QuestDefinition:
	return get_template_for_npc(npc_id)


func npc_interact_blocked() -> bool:
	# Nigdy „bo kiedyś completed / badge”.
	return active_quest != null or offering_quest_id != "" or dialog_busy


func can_offer(quest_id: String) -> bool:
	var q: QuestDefinition = get_quest(quest_id)
	if q == null:
		return false
	if active_quest != null:
		return false
	if offering_quest_id != "" or dialog_busy:
		return false
	# Badge NIGDY nie blokuje oferty.
	if q.renewal == "daily_pool":
		var n := int(runs_today.get(quest_id, 0))
		if n >= maxi(1, q.daily_soft_cap):
			return false
	return true


func offer_quest(quest_id: String) -> void:
	var q: QuestDefinition = get_quest(quest_id)
	if q == null:
		push_warning("Nieznany quest: %s" % quest_id)
		return
	if active_quest != null:
		return
	if offering_quest_id != "" or dialog_busy:
		return
	if not can_offer(quest_id):
		if q.renewal == "daily_pool" and int(runs_today.get(quest_id, 0)) >= q.daily_soft_cap:
			_offer_rest(q)
		return
	offering_quest_id = quest_id
	var lines: PackedStringArray = q.dialog_offer
	var lifetime := int(runs_lifetime.get(quest_id, 0))
	if lifetime > 0 and q.dialog_offer_again.size() > 0:
		lines = q.dialog_offer_again
	dialog_requested.emit(lines, q.id, "offer")
	print("[QuestManager] Oferta: %s lifetime_runs=%d" % [quest_id, lifetime])


func _offer_rest(q: QuestDefinition) -> void:
	dialog_busy = true
	var lines := PackedStringArray(["Odpocznijmy. Wróć później."])
	rest_requested.emit(q.id, lines)
	dialog_requested.emit(lines, q.id, "rest")
	print("[QuestManager] Soft rest: %s (runs_today=%d)" % [q.id, int(runs_today.get(q.id, 0))])


func clear_offer() -> void:
	var had := offering_quest_id != "" or dialog_busy
	offering_quest_id = ""
	dialog_busy = false
	if had:
		interact_available.emit()


func end_dialog() -> void:
	clear_offer()


func start_quest(quest_id: String) -> void:
	var q: QuestDefinition = get_quest(quest_id)
	if q == null:
		return
	offering_quest_id = ""
	dialog_busy = false
	active_quest = q
	movement_locked = true
	quest_started.emit(q)
	print("[QuestManager] Start run: %s (%s)" % [q.title, q.exercise_type])


func complete_active_quest(success: bool) -> void:
	if active_quest == null:
		return
	var q := active_quest
	active_quest = null
	movement_locked = false
	# Kontrakt renew: clear offer-block natychmiast (template żyje).
	offering_quest_id = ""

	var prior := int(runs_lifetime.get(q.id, 0))
	runs_lifetime[q.id] = prior + 1
	runs_today[q.id] = int(runs_today.get(q.id, 0)) + 1
	completion_counts[q.id] = int(completion_counts.get(q.id, 0)) + 1

	if success:
		var pts := q.reward_points if prior == 0 else q.reward_points_repeat
		ProgressStore.add_points(pts)
		# Badge tylko first clear — kosmetyka, nie gate.
		if prior == 0:
			ProgressStore.unlock_badge("quest_%s" % q.id)
		dialog_busy = true
		dialog_requested.emit(q.dialog_done, q.id, "done")
	else:
		dialog_busy = false

	renew_npc(q.npc_id)
	interact_available.emit()
	quest_finished.emit(q, success)
	print("[QuestManager] Koniec run: %s success=%s lifetime=%d" % [
		q.id, success, int(runs_lifetime.get(q.id, 0))
	])


## Mid-run wyjście (czerwone X): bez punktów / badge / licznika runs — dziecko może iść do drugiego NPC.
func cancel_active_quest() -> void:
	if active_quest == null:
		return
	var q := active_quest
	active_quest = null
	movement_locked = false
	offering_quest_id = ""
	dialog_busy = false
	renew_npc(q.npc_id)
	interact_available.emit()
	quest_finished.emit(q, false)
	print("[QuestManager] Cancel run: %s (no run count)" % q.id)


func renew_npc(npc_id: String) -> void:
	get_tree().call_group("npc", "on_quest_renew", npc_id)


func remember_roll(quest_id: String, roll: Variant) -> void:
	last_roll[quest_id] = roll


func get_last_roll(quest_id: String) -> Variant:
	return last_roll.get(quest_id, null)


func active_quest_id() -> String:
	if active_quest == null:
		return ""
	return str(active_quest.id)
