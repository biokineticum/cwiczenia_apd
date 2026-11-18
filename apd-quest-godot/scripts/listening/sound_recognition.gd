extends Node
## Rozpoznawanie dźwięków — stub. Start: onomatopeja/tekst; docelowo nagrania środowiskowe.
signal finished(success: bool, detail: Dictionary)


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	print("[SoundRecognition] stub (4 opcje) noise=%s %s @%.2f" % [noise_on, noise_type, relative_level])
	get_tree().create_timer(1.0).timeout.connect(
		func(): finished.emit(true, {"label": "pies"}),
		CONNECT_ONE_SHOT
	)
