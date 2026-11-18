extends Node
class_name ListeningSession
## Fasada sesji słuchowej: wybór typu ćwiczenia + opcjonalny szum + most UI.

signal session_finished(success: bool, detail: Dictionary)
signal ui_changed(state: Dictionary)

enum ExerciseType {
	SPEECH_IN_NOISE,
	WORD_SEQUENCE,
	SOUND_RECOGNITION,
	LATERALIZATION,
	AUDIO_MOTOR,
}

var exercise_type: ExerciseType = ExerciseType.WORD_SEQUENCE
var _module: Node = null


func start_from_quest(quest: QuestDefinition) -> void:
	match quest.exercise_type:
		"speech_in_noise":
			exercise_type = ExerciseType.SPEECH_IN_NOISE
			_module = preload("res://scripts/listening/speech_in_noise.gd").new()
		"word_sequence":
			exercise_type = ExerciseType.WORD_SEQUENCE
			_module = preload("res://scripts/listening/word_sequence.gd").new()
		"sound_recognition":
			exercise_type = ExerciseType.SOUND_RECOGNITION
			_module = preload("res://scripts/listening/sound_recognition.gd").new()
		"lateralization":
			exercise_type = ExerciseType.LATERALIZATION
			_module = preload("res://scripts/listening/lateralization.gd").new()
		"audio_motor":
			exercise_type = ExerciseType.AUDIO_MOTOR
			_module = preload("res://scripts/listening/audio_motor.gd").new()
		_:
			push_warning("Nieznany exercise_type: %s — fallback word_sequence" % quest.exercise_type)
			exercise_type = ExerciseType.WORD_SEQUENCE
			_module = preload("res://scripts/listening/word_sequence.gd").new()
	add_child(_module)
	if _module.has_signal("finished"):
		_module.finished.connect(_on_module_finished)
	if _module.has_signal("ui_changed"):
		_module.ui_changed.connect(func(state: Dictionary): ui_changed.emit(state))
	if _module.has_method("begin"):
		_module.begin(NoiseSettings.enabled, NoiseSettings.relative_level, NoiseSettings.noise_type)


func submit_choice(text: String) -> void:
	if _module == null:
		return
	if _module.has_method("submit_choice"):
		_module.submit_choice(text)
	elif _module.has_method("submit_word"):
		_module.submit_word(text)


func undo_last() -> void:
	if _module and _module.has_method("undo_last"):
		_module.undo_last()


func replay() -> void:
	if _module and _module.has_method("replay"):
		_module.replay()


func set_noise_enabled(enabled: bool) -> void:
	NoiseSettings.set_enabled(enabled)
	if _module and _module.has_method("set_noise_enabled"):
		_module.set_noise_enabled(enabled)


func _on_module_finished(success: bool, detail: Dictionary = {}) -> void:
	session_finished.emit(success, detail)
	if is_instance_valid(_module):
		_module.queue_free()
		_module = null
