extends Node
## Mowa w szumie — stub. Docelowo: clip mowy + NoisePlayer + wybór MC.
signal finished(success: bool, detail: Dictionary)

var target_sentence: String = ""


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	target_sentence = _pick_sentence()
	print("[SpeechInNoise] zdanie=\"%s\" noise=%s type=%s level=%.2f" % [
		target_sentence, noise_on, noise_type, relative_level
	])
	print("[SpeechInNoise] HINT: UI ma pokazać 3–4 opcje; nie ujawniać klucza dziecku.")
	# Auto-complete stub po krótkim delay — podmienić na realną odpowiedź gracza.
	get_tree().create_timer(1.0).timeout.connect(
		func(): finished.emit(true, {"sentence": target_sentence}),
		CONNECT_ONE_SHOT
	)


func _pick_sentence() -> String:
	var path := "res://data/sentences.json"
	if not FileAccess.file_exists(path):
		return "Mama gotuje obiad"
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var items: Array = data.get("items", []) if typeof(data) == TYPE_DICTIONARY else []
	if items.is_empty():
		return "Mama gotuje obiad"
	return str(items[randi() % items.size()])
