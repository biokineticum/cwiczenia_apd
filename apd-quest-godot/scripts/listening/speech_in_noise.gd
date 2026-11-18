extends Node
## Burza 5-latka: odsłuch zdania → wybór obrazka (2–4), bez tekstu MC na ekranie dziecka.
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


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	# Domyślnie szum OFF dla 5-latki — rodzic włącza w overlay.
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
	print("[SpeechInNoise] \"%s\" illust=%s" % [target_sentence, target_illustration])
	_present_then_ask()


func submit_choice(illustration_id: String) -> void:
	if _answered:
		return
	var ok := illustration_id == target_illustration
	if ok:
		_answered = true
		ui_changed.emit({
			"phase": "result",
			"mode": "speech_in_noise",
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
		await get_tree().create_timer(0.9).timeout
		finished.emit(true, {"sentence": target_sentence, "illustration": target_illustration, "choice": illustration_id})
		return

	_fail_count += 1
	ui_changed.emit({
		"phase": "retry",
		"mode": "speech_in_noise",
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
	await get_tree().create_timer(0.55).timeout
	if _fail_count >= 3:
		_answered = true
		if _noise:
			_noise.stop()
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
	_emit_answer_ui()


func get_parent_stimulus_text() -> String:
	return target_sentence


func _present_then_ask() -> void:
	ui_changed.emit({
		"phase": "present",
		"mode": "speech_in_noise",
		"title_icon": "ear",
		"flash_icon": "ear",
		"choices": [],
		"slots": [],
		"noise_on": _noise_on,
		"parent_text": target_sentence,
		"child_text_hidden": true,
	})
	# Nigdy nie pokazujemy zdania dziecku — tylko TTS + ikona ucha.
	_speech.play_text(target_sentence)
	await _speech.finished
	await get_tree().create_timer(0.25).timeout
	_emit_answer_ui()


func _emit_answer_ui() -> void:
	var choice_dicts: Array = []
	for ic in _choice_icons:
		choice_dicts.append({"id": str(ic), "icon": str(ic), "used": false})
	ui_changed.emit({
		"phase": "answer",
		"mode": "speech_in_noise",
		"title_icon": "ear",
		"flash_icon": "",
		"choices": choice_dicts,
		"slots": [],
		"noise_on": _noise_on,
		"parent_text": target_sentence,
		"child_text_hidden": true,
		"can_undo": false,
	})


func _pick_item() -> void:
	var path := "res://data/sentences.json"
	var fallback_text := "Pies biegnie po parku"
	var fallback_ill := "park"
	var distractors: Array = ["sleep", "house", "car"]
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) == TYPE_DICTIONARY:
			var items: Array = data.get("items", [])
			if not items.is_empty():
				var item = items[randi() % items.size()]
				if typeof(item) == TYPE_DICTIONARY:
					target_sentence = str(item.get("text_pl", fallback_text))
					target_illustration = str(item.get("illustration", fallback_ill))
					distractors = item.get("distractors", distractors)
				else:
					# Legacy string items
					target_sentence = str(item)
					target_illustration = fallback_ill
				_build_choices(distractors)
				return
	target_sentence = fallback_text
	target_illustration = fallback_ill
	_build_choices(distractors)


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
	# 2–4 obrazki
	var n := mini(4, maxi(2, pool.size()))
	_choice_icons = PackedStringArray()
	for i in n:
		_choice_icons.append(str(pool[i]))
