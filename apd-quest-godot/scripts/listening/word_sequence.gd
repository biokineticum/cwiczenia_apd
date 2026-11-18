extends Node
## Echo 5-latka: odsłuch → tap ikon w kolejności (bez napisów dla dziecka).

const NoisePlayer = preload("res://scripts/audio/noise_player.gd")
const SpeechPlayer = preload("res://scripts/audio/speech_player.gd")

signal finished(success: bool, detail: Dictionary)
signal ui_changed(state: Dictionary)

## Sekwencja id słów (nie labeli).
var sequence: PackedStringArray = PackedStringArray()
var sequence_icons: PackedStringArray = PackedStringArray()
var sequence_labels: PackedStringArray = PackedStringArray()
var _selected: PackedStringArray = PackedStringArray()
var _choice_ids: PackedStringArray = PackedStringArray()
var _choice_icons: PackedStringArray = PackedStringArray()
var _noise: NoisePlayer
var _speech: SpeechPlayer
var _noise_on: bool = false
var _relative_level: float = 0.35
var _noise_type: String = "pink"
var _presenting: bool = false
var _fail_count: int = 0
var _word_meta: Dictionary = {} # id -> {label, icon}


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	_noise_on = noise_on
	_relative_level = relative_level
	_noise_type = noise_type
	_fail_count = 0
	_load_pool()
	_build_sequence()
	_selected = PackedStringArray()
	_build_choices(0)
	_noise = NoisePlayer.new()
	_speech = SpeechPlayer.new()
	add_child(_noise)
	add_child(_speech)
	if _noise_on:
		_noise.start(_noise_type, _relative_level)
	print("[WordSequence] ids=%s labels=%s" % [", ".join(sequence), ", ".join(sequence_labels)])
	await _demo_then_present()


func submit_word(word_id: String) -> void:
	if _presenting:
		return
	_selected.append(word_id)
	_emit_answer_ui()
	if _selected.size() >= sequence.size():
		_evaluate()


func undo_last() -> void:
	if _presenting or _selected.is_empty():
		return
	var trimmed := PackedStringArray()
	for i in _selected.size() - 1:
		trimmed.append(_selected[i])
	_selected = trimmed
	_emit_answer_ui()


func replay() -> void:
	if _presenting:
		return
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
	_emit_answer_ui()


func get_parent_stimulus_text() -> String:
	return " → ".join(sequence_labels)


func _demo_then_present() -> void:
	ui_changed.emit({
		"phase": "demo",
		"mode": "word_sequence",
		"title_icon": "ear",
		"prompt_audio": true,
		"flash_icon": "",
		"choices": [],
		"slots": [],
		"selected_icons": [],
		"noise_on": _noise_on,
		"parent_text": get_parent_stimulus_text(),
		"child_text_hidden": true,
	})
	_speech.play_text("Ułóż zaklęcie tak, jak usłyszysz.")
	await _speech.finished
	await get_tree().create_timer(0.35).timeout
	# Krótka demo: pokaż 2 pierwsze ikony wjeżdżające na sloty (ghost).
	if sequence_icons.size() >= 2:
		ui_changed.emit({
			"phase": "demo",
			"mode": "word_sequence",
			"title_icon": "ear",
			"flash_icon": "",
			"choices": [],
			"slots": [
				{"icon": sequence_icons[0], "ghost": true},
				{"icon": sequence_icons[1], "ghost": true},
			],
			"selected_icons": [],
			"noise_on": _noise_on,
			"parent_text": get_parent_stimulus_text(),
			"child_text_hidden": true,
		})
		await get_tree().create_timer(1.0).timeout
	_present_sequence(true)


func _present_sequence(_first: bool) -> void:
	_presenting = true
	_selected = PackedStringArray()
	ui_changed.emit({
		"phase": "present",
		"mode": "word_sequence",
		"title_icon": "ear",
		"flash_icon": "ear",
		"choices": [],
		"slots": [],
		"selected_icons": [],
		"noise_on": _noise_on,
		"parent_text": get_parent_stimulus_text(),
		"child_text_hidden": true,
	})
	for i in sequence.size():
		var label := sequence_labels[i]
		# Nigdy nie flashujemy liter dziecku — tylko ikona ucha + TTS.
		ui_changed.emit({
			"phase": "present",
			"mode": "word_sequence",
			"title_icon": "ear",
			"flash_icon": "ear",
			"choices": [],
			"slots": [],
			"selected_icons": [],
			"noise_on": _noise_on,
			"parent_text": get_parent_stimulus_text(),
			"parent_current": label,
			"child_text_hidden": true,
		})
		_speech.play_text(label)
		await _speech.finished
		await get_tree().create_timer(0.75).timeout
	_presenting = false
	_emit_answer_ui()


func _emit_answer_ui() -> void:
	var choice_dicts: Array = []
	for i in _choice_ids.size():
		choice_dicts.append({
			"id": _choice_ids[i],
			"icon": _choice_icons[i],
			"used": _choice_ids[i] in _selected,
		})
	var selected_icons := PackedStringArray()
	for sid in _selected:
		selected_icons.append(str(_word_meta.get(sid, {}).get("icon", "ear")))
	var slots: Array = []
	for i in sequence.size():
		if i < _selected.size():
			slots.append({"icon": selected_icons[i], "ghost": false})
		else:
			slots.append({"icon": "", "ghost": false, "empty": true})
	ui_changed.emit({
		"phase": "answer",
		"mode": "word_sequence",
		"title_icon": "ear",
		"flash_icon": "",
		"choices": choice_dicts,
		"slots": slots,
		"selected_icons": selected_icons,
		"noise_on": _noise_on,
		"parent_text": get_parent_stimulus_text(),
		"child_text_hidden": true,
		"can_undo": _selected.size() > 0,
	})


func _evaluate() -> void:
	var ok := _selected.size() == sequence.size()
	if ok:
		for i in sequence.size():
			if str(_selected[i]) != str(sequence[i]):
				ok = false
				break
	if ok:
		ui_changed.emit({
			"phase": "result",
			"mode": "word_sequence",
			"title_icon": "ear",
			"flash_icon": "",
			"choices": [],
			"slots": [],
			"selected_icons": [],
			"success": true,
			"warm": true,
			"parent_text": get_parent_stimulus_text(),
			"child_text_hidden": true,
		})
		if _noise:
			_noise.stop()
		await get_tree().create_timer(0.9).timeout
		finished.emit(true, {"sequence": sequence, "answer": _selected, "labels": sequence_labels})
		return

	_fail_count += 1
	ui_changed.emit({
		"phase": "retry",
		"mode": "word_sequence",
		"title_icon": "ear",
		"flash_icon": "ear",
		"choices": [],
		"slots": [],
		"selected_icons": [],
		"success": false,
		"warm": true,
		"parent_text": get_parent_stimulus_text(),
		"child_text_hidden": true,
		"fail_count": _fail_count,
	})
	await get_tree().create_timer(0.6).timeout
	if _fail_count >= 3:
		# Uznaj za ćwiczenie i idź dalej (bez kary).
		if _noise:
			_noise.stop()
		finished.emit(true, {"sequence": sequence, "answer": _selected, "scaffolded": true})
		return
	if _fail_count >= 2:
		# Podpowiedź: pierwszy kafelek na miejscu.
		_selected = PackedStringArray([sequence[0]])
		_emit_answer_ui()
		await get_tree().create_timer(0.5).timeout
	_selected = PackedStringArray()
	_present_sequence(false)


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
	var length_min := 2
	var length_max := 3
	var ids: Array = _word_meta.keys()
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) == TYPE_DICTIONARY:
			length_min = int(data.get("default_length_min", 2))
			length_max = int(data.get("default_length_max", 3))
	ids.shuffle()
	var n := randi_range(length_min, length_max)
	sequence = PackedStringArray()
	sequence_icons = PackedStringArray()
	sequence_labels = PackedStringArray()
	for i in mini(n, ids.size()):
		var wid := str(ids[i])
		sequence.append(wid)
		sequence_icons.append(str(_word_meta[wid]["icon"]))
		sequence_labels.append(str(_word_meta[wid]["label"]))


func _build_choices(distractors: int) -> void:
	_choice_ids = sequence.duplicate()
	_choice_icons = sequence_icons.duplicate()
	var extras: Array = []
	for wid in _word_meta.keys():
		if wid in sequence:
			continue
		extras.append(wid)
	extras.shuffle()
	for i in mini(distractors, extras.size()):
		var wid := str(extras[i])
		_choice_ids.append(wid)
		_choice_icons.append(str(_word_meta[wid]["icon"]))
	# Shuffle together
	var order: Array = range(_choice_ids.size())
	order.shuffle()
	var new_ids := PackedStringArray()
	var new_icons := PackedStringArray()
	for i in order:
		new_ids.append(_choice_ids[i])
		new_icons.append(_choice_icons[i])
	_choice_ids = new_ids
	_choice_icons = new_icons
