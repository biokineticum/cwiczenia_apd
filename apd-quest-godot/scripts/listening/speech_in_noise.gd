extends Node
## Mowa w szumie: TTS/flash zdania + wybór MC (3–4 opcje). Klucz nie jest pokazywany wcześniej.
signal finished(success: bool, detail: Dictionary)
signal ui_changed(state: Dictionary)

var target_sentence: String = ""
var _choices: PackedStringArray = PackedStringArray()
var _noise: NoisePlayer
var _speech: SpeechPlayer
var _noise_on: bool = false
var _relative_level: float = 0.35
var _noise_type: String = "pink"
var _answered: bool = false


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	_noise_on = noise_on
	_relative_level = relative_level
	_noise_type = noise_type
	_answered = false
	target_sentence = _pick_sentence()
	_choices = _build_choices(target_sentence)
	_noise = NoisePlayer.new()
	_speech = SpeechPlayer.new()
	add_child(_noise)
	add_child(_speech)
	if _noise_on:
		_noise.start(_noise_type, _relative_level)
	print("[SpeechInNoise] zdanie=\"%s\" noise=%s type=%s level=%.2f" % [
		target_sentence, _noise_on, _noise_type, _relative_level
	])
	_present_then_ask()


func submit_choice(choice: String) -> void:
	if _answered:
		return
	_answered = true
	var ok := choice.strip_edges().to_lower() == target_sentence.strip_edges().to_lower()
	ui_changed.emit({
		"phase": "result",
		"title": "Wiadomość w burzy",
		"prompt": "Udało się — usłyszałaś wiadomość!" if ok else "Spróbuj jeszcze — posłuchaj uważniej.",
		"flash": "",
		"choices": PackedStringArray(),
		"selected": PackedStringArray([choice]),
		"noise_on": _noise_on,
		"hint": ("Poprawna wiadomość: %s" % target_sentence) if not ok else "Świetny słuch w szumie!",
		"success": ok,
	})
	if _noise:
		_noise.stop()
	await get_tree().create_timer(1.1).timeout
	finished.emit(ok, {"sentence": target_sentence, "choice": choice})


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
	ui_changed.emit({
		"phase": "answer",
		"title": "Wiadomość w burzy",
		"prompt": "Co usłyszałaś?",
		"flash": "",
		"choices": _choices,
		"selected": PackedStringArray(),
		"noise_on": _noise_on,
		"hint": "Szum to względny poziom trudności — nie kliniczny SNR.",
	})


func _present_then_ask() -> void:
	var show_flash := not _speech.has_tts()
	ui_changed.emit({
		"phase": "present",
		"title": "Wiadomość w burzy",
		"prompt": "Słuchaj uważnie…",
		"flash": target_sentence if show_flash else "…",
		"choices": PackedStringArray(),
		"selected": PackedStringArray(),
		"noise_on": _noise_on,
		"hint": "Potem wybierz, co usłyszałaś." if not show_flash else "Brak TTS — krótki podgląd wiadomości na ekranie.",
	})
	_speech.play_text(target_sentence)
	await _speech.finished
	await get_tree().create_timer(0.2).timeout
	ui_changed.emit({
		"phase": "answer",
		"title": "Wiadomość w burzy",
		"prompt": "Co usłyszałaś?",
		"flash": "",
		"choices": _choices,
		"selected": PackedStringArray(),
		"noise_on": _noise_on,
		"hint": "Szum to względny poziom trudności — nie kliniczny SNR.",
	})


func _pick_sentence() -> String:
	var path := "res://data/sentences.json"
	if not FileAccess.file_exists(path):
		return "Mama gotuje obiad"
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var items: Array = data.get("items", []) if typeof(data) == TYPE_DICTIONARY else []
	if items.is_empty():
		return "Mama gotuje obiad"
	return str(items[randi() % items.size()])


func _build_choices(correct: String) -> PackedStringArray:
	var path := "res://data/sentences.json"
	var items: Array = []
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) == TYPE_DICTIONARY:
			items = data.get("items", [])
	var pool: Array = []
	for s in items:
		if str(s) != correct:
			pool.append(str(s))
	pool.shuffle()
	var out: Array = [correct]
	for i in mini(3, pool.size()):
		out.append(pool[i])
	out.shuffle()
	var packed := PackedStringArray()
	for s in out:
		packed.append(str(s))
	return packed
