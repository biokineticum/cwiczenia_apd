extends Node
class_name SpeechPlayer
## Bodźce mowy: systemowy TTS gdy dostępny; inaczej sygnał spoken_stub dla flash UI.

signal finished
signal spoken_stub(text: String)

@export var bus_name: String = "Speech"

var _player: AudioStreamPlayer
var _waiting: bool = false


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = bus_name
	_player.finished.connect(func(): finished.emit())
	add_child(_player)


func has_tts() -> bool:
	return not DisplayServer.tts_get_voices().is_empty()


func play_text(text: String, interrupt: bool = true) -> void:
	stop()
	spoken_stub.emit(text)
	if interrupt and DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()

	var voice_id := _pick_voice_id()
	if voice_id != "":
		_waiting = true
		_duck_noise(true)
		DisplayServer.tts_speak(text, voice_id, 85, 1.0, 0.95, 0, interrupt)
		var approx := maxf(0.75, float(text.length()) * 0.08)
		get_tree().create_timer(approx).timeout.connect(_finish_wait, CONNECT_ONE_SHOT)
		print("[SpeechPlayer] TTS: \"%s\" voice=%s (noise ducked)" % [text, voice_id])
		return

	print("[SpeechPlayer] brak TTS — stub tekstowy: \"%s\"" % text)
	_waiting = true
	_duck_noise(true)
	get_tree().create_timer(0.9).timeout.connect(_finish_wait, CONNECT_ONE_SHOT)


func play_text_stub(text: String) -> void:
	play_text(text)


func play_stream(stream: AudioStream) -> void:
	stop()
	_player.stream = stream
	_player.play()


func stop() -> void:
	# Jeśli ktoś `await finished` (np. cancel mid-run) — odblokuj await.
	var was_waiting := _waiting
	_waiting = false
	_duck_noise(false)
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	if _player and _player.playing:
		_player.stop()
	if was_waiting:
		finished.emit()


func _duck_noise(active: bool) -> void:
	if AudioBusSetup:
		AudioBusSetup.duck_noise(active)


func _pick_voice_id() -> String:
	var pl := DisplayServer.tts_get_voices_for_language("pl")
	if pl.size() > 0:
		return str(pl[0])
	var all := DisplayServer.tts_get_voices()
	if all.is_empty():
		return ""
	var first = all[0]
	if typeof(first) == TYPE_DICTIONARY:
		return str(first.get("id", ""))
	return str(first)


func _finish_wait() -> void:
	if _waiting:
		_waiting = false
		_duck_noise(false)
		finished.emit()
