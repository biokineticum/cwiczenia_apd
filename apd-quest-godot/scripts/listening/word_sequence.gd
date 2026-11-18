extends Node
## Sekwencje słów 3–5: odsłuch (TTS / flash) → tap kart w kolejności.
signal finished(success: bool, detail: Dictionary)
signal ui_changed(state: Dictionary)

var sequence: PackedStringArray = PackedStringArray()
var _selected: PackedStringArray = PackedStringArray()
var _shuffled: PackedStringArray = PackedStringArray()
var _noise: NoisePlayer
var _speech: SpeechPlayer
var _noise_on: bool = false
var _relative_level: float = 0.35
var _noise_type: String = "pink"
var _presenting: bool = false


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	_noise_on = noise_on
	_relative_level = relative_level
	_noise_type = noise_type
	sequence = _build_sequence()
	_selected = PackedStringArray()
	_shuffled = _shuffle_unique(sequence)
	_noise = NoisePlayer.new()
	_speech = SpeechPlayer.new()
	add_child(_noise)
	add_child(_speech)
	_speech.spoken_stub.connect(_on_spoken_stub)
	if _noise_on:
		_noise.start(_noise_type, _relative_level)
	print("[WordSequence] %s | noise=%s %s @%.2f" % [
		", ".join(sequence), _noise_on, _noise_type, _relative_level
	])
	_present_sequence()


func submit_word(word: String) -> void:
	if _presenting:
		return
	_selected.append(word)
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
	_present_sequence()


func set_noise_enabled(enabled: bool) -> void:
	_noise_on = enabled
	if _noise == null:
		return
	if enabled:
		_noise.start(_noise_type, _relative_level)
	else:
		_noise.stop()
	_emit_answer_ui()


func _present_sequence() -> void:
	_presenting = true
	_selected = PackedStringArray()
	ui_changed.emit({
		"phase": "present",
		"title": "Zapamiętaj kolejność",
		"prompt": "Słuchaj uważnie…",
		"flash": "",
		"choices": PackedStringArray(),
		"selected": PackedStringArray(),
		"noise_on": _noise_on,
		"hint": "Potem ułóż słowa w tej samej kolejności.",
	})
	var show_flash := not _speech.has_tts()
	for word in sequence:
		ui_changed.emit({
			"phase": "present",
			"title": "Zapamiętaj kolejność",
			"prompt": "Słuchaj…",
			"flash": str(word) if show_flash else "•",
			"choices": PackedStringArray(),
			"selected": PackedStringArray(),
			"noise_on": _noise_on,
			"hint": "Powtórzysz za chwilę." if not show_flash else "Brak TTS — pokazuję słowa na ekranie.",
		})
		_speech.play_text(str(word))
		await _speech.finished
		await get_tree().create_timer(0.25).timeout
	_presenting = false
	_emit_answer_ui()


func _emit_answer_ui() -> void:
	ui_changed.emit({
		"phase": "answer",
		"title": "Ułóż zaklęcie",
		"prompt": "Dotknij słów w kolejności, w jakiej je usłyszałaś.",
		"flash": "",
		"choices": _shuffled,
		"selected": _selected.duplicate(),
		"noise_on": _noise_on,
		"hint": "Możesz cofnąć ostatnie słowo albo odsłuchać ponownie.",
	})


func _evaluate() -> void:
	var ok := _selected.size() == sequence.size()
	if ok:
		for i in sequence.size():
			if str(_selected[i]).to_lower() != str(sequence[i]).to_lower():
				ok = false
				break
	ui_changed.emit({
		"phase": "result",
		"title": "Zaklęcie Echo",
		"prompt": "Udało się!" if ok else "Prawie — spróbuj jeszcze raz.",
		"flash": "",
		"choices": PackedStringArray(),
		"selected": _selected.duplicate(),
		"noise_on": _noise_on,
		"hint": "Poprawna kolejność: %s" % ", ".join(sequence) if not ok else "Świetna pamięć słuchowa!",
		"success": ok,
	})
	if _noise:
		_noise.stop()
	await get_tree().create_timer(1.1).timeout
	finished.emit(ok, {"sequence": sequence, "answer": _selected})


func _on_spoken_stub(text: String) -> void:
	# Flash już ustawiony przed play_text; tu ewentualny log.
	print("[WordSequence] flash/TTS: %s" % text)


func _build_sequence() -> PackedStringArray:
	var path := "res://data/word_pool.json"
	var words: Array = ["dom", "las", "rzeka"]
	var length_min := 3
	var length_max := 5
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) == TYPE_DICTIONARY:
			words = data.get("words", words)
			length_min = int(data.get("default_length_min", 3))
			length_max = int(data.get("default_length_max", 5))
	var n := randi_range(length_min, length_max)
	var pool := words.duplicate()
	pool.shuffle()
	var out := PackedStringArray()
	for i in mini(n, pool.size()):
		out.append(str(pool[i]))
	while out.size() < n:
		out.append(str(words[randi() % words.size()]))
	return out


func _shuffle_unique(src: PackedStringArray) -> PackedStringArray:
	var arr: Array = []
	for w in src:
		arr.append(str(w))
	# Dodaj 1–2 dystraktory z puli, jeśli dostępne.
	var path := "res://data/word_pool.json"
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) == TYPE_DICTIONARY:
			var extras: Array = data.get("words", [])
			extras.shuffle()
			for w in extras:
				if arr.has(str(w)):
					continue
				arr.append(str(w))
				if arr.size() >= src.size() + 2:
					break
	arr.shuffle()
	var out := PackedStringArray()
	for w in arr:
		out.append(str(w))
	return out
