extends Node
## Echo 5-latka: odsłuch TTS → układanie symboli w 3D (chodzenie w obiekty / sloty 1–4).
## Bez klikania siatki UI. Cyfry 1–10 jako etykiety slotów OK.

const NoisePlayer = preload("res://scripts/audio/noise_player.gd")
const SpeechPlayer = preload("res://scripts/audio/speech_player.gd")
const EchoBoardScript = preload("res://scripts/listening/echo_board.gd")

signal finished(success: bool, detail: Dictionary)
signal ui_changed(state: Dictionary)

## Sekwencja id słów (nie labeli).
var sequence: PackedStringArray = PackedStringArray()
var sequence_icons: PackedStringArray = PackedStringArray()
var sequence_labels: PackedStringArray = PackedStringArray()
var _selected: PackedStringArray = PackedStringArray()
var _noise: NoisePlayer
var _speech: SpeechPlayer
var _noise_on: bool = false
var _relative_level: float = 0.35
var _noise_type: String = "pink"
var _presenting: bool = false
var _fail_count: int = 0
var _word_meta: Dictionary = {} # id -> {label, icon}
var _board: Node3D = null
var _finished: bool = false


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	_noise_on = noise_on
	_relative_level = relative_level
	_noise_type = noise_type
	_fail_count = 0
	_finished = false
	_load_pool()
	_build_sequence()
	_selected = PackedStringArray()
	_noise = NoisePlayer.new()
	_speech = SpeechPlayer.new()
	add_child(_noise)
	add_child(_speech)
	if _noise_on:
		_noise.start(_noise_type, _relative_level)
	print("[WordSequence] ids=%s labels=%s (3D board)" % [", ".join(sequence), ", ".join(sequence_labels)])
	await _demo_then_present()


func submit_word(word_id: String) -> void:
	# Kompatybilność playtestów — przekieruj na force arrange jeśli board żyje.
	if _board and _board.has_method("force_arrange"):
		return
	if _presenting or _finished:
		return
	_selected.append(word_id)
	if _selected.size() >= sequence.size():
		_evaluate_selected()


func undo_last() -> void:
	if _presenting or _finished:
		return
	if _board and _board.has_method("reset_board"):
		_board.reset_board()
		_selected = PackedStringArray()
		_emit_world_answer_ui()


func replay() -> void:
	if _presenting or _finished:
		return
	if _board and _board.has_method("reset_board"):
		_board.reset_board()
	_selected = PackedStringArray()
	_present_sequence(false)


func set_noise_enabled(enabled: bool) -> void:
	_noise_on = enabled
	if _noise == null:
		return
	if enabled:
		_noise.start(_noise_type, _relative_level)
	else:
		_noise.stop()
	_emit_world_answer_ui()


func get_parent_stimulus_text() -> String:
	return " → ".join(sequence_labels)


## Playtest: ułóż poprawną sekwencję na planszy 3D.
func force_complete_board() -> void:
	if _board and _board.has_method("force_arrange"):
		_board.force_arrange(sequence)


func _demo_then_present() -> void:
	# Podczas odsłuchu ruch zablokowany (dialog/quest).
	QuestManager.movement_locked = true
	ui_changed.emit({
		"phase": "demo",
		"mode": "word_sequence",
		"world_board": true,
		"title_icon": "ear",
		"prompt_audio": true,
		"flash_icon": "ear",
		"choices": [],
		"slots": [],
		"noise_on": _noise_on,
		"parent_text": get_parent_stimulus_text(),
		"child_text_hidden": true,
	})
	_speech.play_text("Ułóż zaklęcie tak, jak usłyszysz.")
	await _speech.finished
	await get_tree().create_timer(0.25).timeout
	_speech.play_text("Potem przejdziesz do przedmiotów i włożysz je do kółek z cyframi.")
	await _speech.finished
	await get_tree().create_timer(0.2).timeout
	_present_sequence(true)


func _present_sequence(_first: bool) -> void:
	_presenting = true
	_selected = PackedStringArray()
	QuestManager.movement_locked = true
	ui_changed.emit({
		"phase": "present",
		"mode": "word_sequence",
		"world_board": true,
		"title_icon": "ear",
		"flash_icon": "ear",
		"choices": [],
		"slots": [],
		"noise_on": _noise_on,
		"parent_text": get_parent_stimulus_text(),
		"child_text_hidden": true,
	})
	for i in sequence.size():
		var label := sequence_labels[i]
		ui_changed.emit({
			"phase": "present",
			"mode": "word_sequence",
			"world_board": true,
			"title_icon": "ear",
			"flash_icon": "ear",
			"choices": [],
			"slots": [],
			"noise_on": _noise_on,
			"parent_text": get_parent_stimulus_text(),
			"parent_current": label,
			"child_text_hidden": true,
		})
		_speech.play_text(label)
		await _speech.finished
		await get_tree().create_timer(0.7).timeout
	_presenting = false
	_speech.play_text("Twoja kolej. Wejdź w przedmiot, potem do kółka z cyfrą.")
	await _speech.finished
	_spawn_board_and_unlock()


func _spawn_board_and_unlock() -> void:
	_teardown_board()
	_board = EchoBoardScript.new()
	_board.name = "EchoBoard"
	# Blisko Echo / startu gracza
	var origin := Vector3(-1.2, 0.0, -0.4)
	var echo_npc := _find_node_named("NpcEcho")
	if echo_npc is Node3D:
		origin = (echo_npc as Node3D).global_position + Vector3(0.0, 0.0, 2.6)
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(_board)
	else:
		add_child(_board)
	_board.setup(sequence, sequence_icons, origin, _speech)
	_board.arrangement_changed.connect(_on_board_changed)
	_board.arrangement_complete.connect(_on_board_complete)
	# Dziewczynka MUSI chodzić — odblokuj ruch.
	QuestManager.movement_locked = false
	_emit_world_answer_ui()


func _emit_world_answer_ui() -> void:
	ui_changed.emit({
		"phase": "answer",
		"mode": "word_sequence",
		"world_board": true,
		"title_icon": "ear",
		"flash_icon": "",
		"choices": [],
		"slots": [],
		"noise_on": _noise_on,
		"parent_text": get_parent_stimulus_text(),
		"child_text_hidden": true,
		"can_undo": true,
		"hint_voice_only": true,
	})


func _on_board_changed(ids: PackedStringArray) -> void:
	_selected = ids


func _on_board_complete(ids: PackedStringArray) -> void:
	_selected = ids
	_evaluate_selected()


func _evaluate_selected() -> void:
	if _finished:
		return
	var ok := _selected.size() == sequence.size()
	if ok:
		for i in sequence.size():
			if str(_selected[i]) != str(sequence[i]):
				ok = false
				break
	if ok:
		_finished = true
		QuestManager.movement_locked = true
		ui_changed.emit({
			"phase": "result",
			"mode": "word_sequence",
			"world_board": true,
			"success": true,
			"warm": true,
			"choices": [],
			"slots": [],
			"parent_text": get_parent_stimulus_text(),
			"child_text_hidden": true,
		})
		if _noise:
			_noise.stop()
		_speech.play_text("Udało się!")
		await _speech.finished
		await get_tree().create_timer(0.4).timeout
		_teardown_board()
		finished.emit(true, {"sequence": sequence, "answer": _selected, "labels": sequence_labels, "world_board": true})
		return

	_fail_count += 1
	ui_changed.emit({
		"phase": "retry",
		"mode": "word_sequence",
		"world_board": true,
		"success": false,
		"warm": true,
		"choices": [],
		"slots": [],
		"parent_text": get_parent_stimulus_text(),
		"child_text_hidden": true,
		"fail_count": _fail_count,
	})
	_speech.play_text("Spróbujmy jeszcze raz. Posłuchaj.")
	await _speech.finished
	await get_tree().create_timer(0.35).timeout
	if _fail_count >= 3:
		_finished = true
		if _noise:
			_noise.stop()
		_teardown_board()
		QuestManager.movement_locked = true
		finished.emit(true, {"sequence": sequence, "answer": _selected, "scaffolded": true, "world_board": true})
		return
	if _board and _board.has_method("reset_board"):
		_board.reset_board()
	_selected = PackedStringArray()
	_present_sequence(false)


func _teardown_board() -> void:
	if _board and is_instance_valid(_board):
		_board.teardown()
	_board = null


func _find_node_named(n: String) -> Node:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.find_child(n, true, false)


func _load_pool() -> void:
	_word_meta.clear()
	var path := "res://data/word_pool.json"
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return
	for w in data.get("words", []):
		if typeof(w) == TYPE_DICTIONARY:
			var wid := str(w.get("id", ""))
			_word_meta[wid] = {
				"label": str(w.get("label_pl", wid)),
				"icon": str(w.get("icon", "ear")),
			}


func _build_sequence() -> void:
	var path := "res://data/word_pool.json"
	var length_min := 4
	var length_max := 4
	var ids: Array = _word_meta.keys()
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) == TYPE_DICTIONARY:
			length_min = int(data.get("default_length_min", 4))
			length_max = int(data.get("default_length_max", 4))
	ids.shuffle()
	var n := randi_range(mini(length_min, length_max), maxi(length_min, length_max))
	sequence = PackedStringArray()
	sequence_icons = PackedStringArray()
	sequence_labels = PackedStringArray()
	for i in mini(n, ids.size()):
		var wid := str(ids[i])
		sequence.append(wid)
		sequence_icons.append(str(_word_meta[wid]["icon"]))
		sequence_labels.append(str(_word_meta[wid]["label"]))


func _exit_tree() -> void:
	_teardown_board()
