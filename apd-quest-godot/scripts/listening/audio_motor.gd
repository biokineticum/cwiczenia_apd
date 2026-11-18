extends Node
## Audio–motor: polecenie ruchowe; ocenę potwierdza rodzic/terapeuta (parent gate).
signal finished(success: bool, detail: Dictionary)

var command: String = ""


func begin(noise_on: bool, relative_level: float, noise_type: String) -> void:
	command = _pick_command()
	print("[AudioMotor] \"%s\" | tryb bez tekstu na ekranie zalecany | noise=%s %s" % [
		command, noise_on, noise_type
	])
	# Stub: sukces po delay — UI ma mieć przyciski opiekuna OK / jeszcze raz.
	get_tree().create_timer(1.0).timeout.connect(
		func(): finished.emit(true, {"command": command, "level": relative_level}),
		CONNECT_ONE_SHOT
	)


func _pick_command() -> String:
	var path := "res://data/audio_motor.json"
	if not FileAccess.file_exists(path):
		return "Klaśnij jeden raz"
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var cmds: Array = data.get("commands", []) if typeof(data) == TYPE_DICTIONARY else []
	if cmds.is_empty():
		return "Klaśnij jeden raz"
	return str(cmds[randi() % cmds.size()])
