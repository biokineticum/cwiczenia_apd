extends Node
## Lateralizacja L/P — wymaga słuchawek stereo. Stub panowania.
signal finished(success: bool, detail: Dictionary)


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	var side := "L" if randf() < 0.5 else "R"
	print("[Lateralization] target=%s | przypomnij o słuchawkach | noise=%s" % [side, noise_on])
	get_tree().create_timer(1.0).timeout.connect(
		func(): finished.emit(true, {"side": side, "relative_noise": relative_level, "type": noise_type}),
		CONNECT_ONE_SHOT
	)
