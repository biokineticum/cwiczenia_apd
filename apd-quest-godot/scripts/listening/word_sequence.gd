extends Node
## Sekwencje słów 3–5 z puli PL (~200 w web; tu stub).
signal finished(success: bool, detail: Dictionary)

var sequence: PackedStringArray = PackedStringArray()


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	sequence = _build_sequence()
	print("[WordSequence] %s | noise=%s %s @%.2f" % [
		", ".join(sequence), noise_on, noise_type, relative_level
	])
	get_tree().create_timer(1.0).timeout.connect(
		func(): finished.emit(true, {"sequence": sequence}),
		CONNECT_ONE_SHOT
	)


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
	var out := PackedStringArray()
	for i in n:
		out.append(str(words[randi() % words.size()]))
	return out
