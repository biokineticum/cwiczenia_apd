extends Node
## Odtwarzanie bodźców mowy z plików. Godot nie ma wbudowanego PL TTS jak przeglądarka —
## docelowo WAV/OGG w assets/audio/. Stub loguje tekst do odtworzenia.
class_name SpeechPlayer

signal finished

@export var bus_name: String = "Speech"

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = bus_name
	_player.finished.connect(func(): finished.emit())
	add_child(_player)


func play_text_stub(text: String) -> void:
	stop()
	print("[SpeechPlayer] stub play: \"%s\" (podmień na AudioStream na PC)" % text)
	# Symulacja krótkiego „odtworzenia” bez audio — sygnał po delay.
	get_tree().create_timer(0.6).timeout.connect(func(): finished.emit(), CONNECT_ONE_SHOT)


func play_stream(stream: AudioStream) -> void:
	stop()
	_player.stream = stream
	_player.play()


func stop() -> void:
	if _player and _player.playing:
		_player.stop()
