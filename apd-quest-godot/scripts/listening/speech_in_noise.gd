extends Node
## Burza: odsłuch → wejdź w obrazek na polanie (bez klikania UI).

const NoisePlayer = preload("res://scripts/audio/noise_player.gd")
const SpeechPlayer = preload("res://scripts/audio/speech_player.gd")
const WalkZone = preload("res://scripts/world/walk_confirm_zone.gd")

signal finished(success: bool, detail: Dictionary)
signal ui_changed(state: Dictionary)

var target_sentence: String = ""
var target_illustration: String = ""
var _choice_icons: PackedStringArray = PackedStringArray()
var _noise: NoisePlayer
var _speech: SpeechPlayer
var _noise_on: bool = false
var _relative_level: float = 0.35
var _noise_type: String = "pink"
var _answered: bool = false
var _fail_count: int = 0
var _zones: Array = []


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	_noise_on = noise_on
	_relative_level = relative_level
	_noise_type = noise_type
	_answered = false
	_fail_count = 0
	_pick_item()
	_noise = NoisePlayer.new()
	_speech = SpeechPlayer.new()
	add_child(_noise)
	add_child(_speech)
	if _noise_on:
		_noise.start(_noise_type, _relative_level)
	print("[SpeechInNoise] \"%s\" illust=%s (walk pads)" % [target_sentence, target_illustration])
	_present_then_ask()


func submit_choice(illustration_id: String) -> void:
	if _answered:
		return
	var ok := illustration_id == target_illustration
	_clear_zones()
	if ok:
		_answered = true
		QuestManager.movement_locked = true
		ui_changed.emit({
			"phase": "result",
			"mode": "speech_in_noise",
			"world_board": true,
			"title_icon": "ear",
			"flash_icon": target_illustration,
			"choices": [],
			"slots": [],
			"success": true,
			"warm": true,
			"noise_on": _noise_on,
			"parent_text": target_sentence,
			"child_text_hidden": true,
		})
		if _noise:
			_noise.stop()
		_speech.play_text("Brawo!")
		await _speech.finished
		finished.emit(true, {"sentence": target_sentence, "illustration": target_illustration, "choice": illustration_id})
		return

	_fail_count += 1
	ui_changed.emit({
		"phase": "retry",
		"mode": "speech_in_noise",
		"world_board": true,
		"title_icon": "ear",
		"flash_icon": "ear",
		"choices": [],
		"slots": [],
		"success": false,
		"warm": true,
		"noise_on": _noise_on,
		"parent_text": target_sentence,
		"child_text_hidden": true,
		"fail_count": _fail_count,
	})
	_speech.play_text("Spróbujmy jeszcze raz.")
	await _speech.finished
	await get_tree().create_timer(0.35).timeout
	if _fail_count >= 3:
		_answered = true
		if _noise:
			_noise.stop()
		QuestManager.movement_locked = true
		finished.emit(true, {"sentence": target_sentence, "scaffolded": true})
		return
	_present_then_ask()


func replay() -> void:
	if _answered:
		return
	_present_then_ask()


func set_noise_enabled(enabled: bool) -> void:
	_noise_on = enabled
	if _noise == null:
		return
	if enabled:
		_noise.start(_noise_type, _relative_level)
	else:
		_noise.stop()


func get_parent_stimulus_text() -> String:
	return target_sentence


func _present_then_ask() -> void:
	_clear_zones()
	QuestManager.movement_locked = true
	ui_changed.emit({
		"phase": "present",
		"mode": "speech_in_noise",
		"world_board": true,
		"title_icon": "ear",
		"flash_icon": "ear",
		"choices": [],
		"slots": [],
		"noise_on": _noise_on,
		"parent_text": target_sentence,
		"child_text_hidden": true,
	})
	_speech.play_text("Posłuchaj. Potem wejdź w obrazek.")
	await _speech.finished
	await get_tree().create_timer(0.15).timeout
	_speech.play_text(target_sentence)
	await _speech.finished
	await get_tree().create_timer(0.15).timeout
	_speech.play_text("Wejdź w obrazek.")
	await _speech.finished
	_spawn_choice_pads()
	QuestManager.movement_locked = false
	ui_changed.emit({
		"phase": "answer",
		"mode": "speech_in_noise",
		"world_board": true,
		"title_icon": "ear",
		"flash_icon": "",
		"choices": [],
		"slots": [],
		"noise_on": _noise_on,
		"parent_text": target_sentence,
		"child_text_hidden": true,
		"can_undo": false,
	})


func _spawn_choice_pads() -> void:
	_clear_zones()
	var scene := get_tree().current_scene
	if scene == null:
		return
	var player := _find_player()
	var origin := Vector3(0, 0.05, 0)
	if player:
		origin = player.global_position
	var n := _choice_icons.size()
	var spacing := 2.8
	var start_x := -0.5 * spacing * float(maxi(n - 1, 1))
	for i in n:
		var z := WalkZone.new()
		scene.add_child(z)
		var pos := origin + Vector3(start_x + float(i) * spacing, 0.0, -2.4)
		z.setup("choice", str(_choice_icons[i]), pos, Color(0.95, 0.88, 0.55), str(_choice_icons[i]))
		z.walked_in.connect(_on_choice_zone)
		_zones.append(z)


func _on_choice_zone(zone: Area3D) -> void:
	var cid := str(zone.get("choice_id"))
	if cid == "":
		return
	submit_choice(cid)


func _clear_zones() -> void:
	for z in _zones:
		if is_instance_valid(z):
			z.set_deferred("monitoring", false)
			z.call_deferred("queue_free")
	_zones.clear()


func _find_player() -> Node3D:
	var nodes := get_tree().get_nodes_in_group("player")
	if nodes.is_empty():
		return null
	return nodes[0] as Node3D


func _pick_item() -> void:
	var path := "res://data/sentences.json"
	var fallback_text := "Pies biegnie po parku"
	var fallback_ill := "park"
	var distractors: Array = ["sleep", "house", "car"]
	var qid := QuestManager.active_quest_id()
	var last = QuestManager.get_last_roll(qid) if qid != "" else null
	var last_ill := ""
	if typeof(last) == TYPE_DICTIONARY:
		last_ill = str(last.get("illustration", ""))
	elif typeof(last) == TYPE_STRING:
		last_ill = str(last)

	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) == TYPE_DICTIONARY:
			var items: Array = data.get("items", [])
			if not items.is_empty():
				var pick = null
				for _attempt in 8:
					var item = items[randi() % items.size()]
					var ill := fallback_ill
					if typeof(item) == TYPE_DICTIONARY:
						ill = str(item.get("illustration", fallback_ill))
					if last_ill == "" or ill != last_ill or items.size() <= 1:
						pick = item
						break
					pick = item
				if typeof(pick) == TYPE_DICTIONARY:
					target_sentence = str(pick.get("text_pl", fallback_text))
					target_illustration = str(pick.get("illustration", fallback_ill))
					distractors = pick.get("distractors", distractors)
				else:
					target_sentence = str(pick)
					target_illustration = fallback_ill
				_build_choices(distractors)
				if qid != "":
					QuestManager.remember_roll(qid, {
						"illustration": target_illustration,
						"sentence": target_sentence,
					})
				return
	target_sentence = fallback_text
	target_illustration = fallback_ill
	_build_choices(distractors)
	if qid != "":
		QuestManager.remember_roll(qid, {
			"illustration": target_illustration,
			"sentence": target_sentence,
		})


func _build_choices(distractors: Array) -> void:
	var pool: Array = [target_illustration]
	for d in distractors:
		if str(d) != target_illustration and not pool.has(str(d)):
			pool.append(str(d))
		if pool.size() >= 4:
			break
	while pool.size() < 2:
		pool.append("house")
	pool.shuffle()
	var n := mini(4, maxi(2, pool.size()))
	_choice_icons = PackedStringArray()
	for i in n:
		_choice_icons.append(str(pool[i]))


func _exit_tree() -> void:
	_clear_zones()
