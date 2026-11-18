extends Node
## Stub odtwarzacza szumu. MVP: cisza / placeholder; później sample loop lub AudioStreamGenerator.
class_name NoisePlayer

@export var bus_name: String = "Noise"

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = bus_name
	add_child(_player)


func start(noise_type: String = "pink", relative_level: float = 0.35) -> void:
	stop()
	# Placeholder: bez generowanego streamu w chmurze — log + gain na busie.
	if AudioBusSetup:
		AudioBusSetup.set_bus_linear_volume(bus_name, relative_level)
	print("[NoisePlayer] start type=%s level=%.2f (stub — dodaj sample na PC)" % [noise_type, relative_level])


func stop() -> void:
	if _player and _player.playing:
		_player.stop()
