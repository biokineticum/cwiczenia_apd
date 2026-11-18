extends Node
class_name NoisePlayer
## Proceduralny szum (white/pink/brown) na busie Noise.
## Poziom jest względny — to nie jest kliniczny SNR.

@export var bus_name: String = "Noise"

var _player: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _noise_type: String = "pink"
var _active: bool = false
var _pink_b0 := 0.0
var _pink_b1 := 0.0
var _pink_b2 := 0.0
var _brown := 0.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = bus_name
	add_child(_player)
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = 22050.0
	_generator.buffer_length = 0.5
	_player.stream = _generator


func _process(_delta: float) -> void:
	if not _active:
		return
	if _playback == null:
		return
	_fill_buffer()


func start(noise_type: String = "pink", relative_level: float = 0.35) -> void:
	stop()
	_noise_type = noise_type
	if AudioBusSetup:
		AudioBusSetup.set_bus_linear_volume(bus_name, clampf(relative_level, 0.05, 1.0))
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	_active = _playback != null
	if _active:
		_fill_buffer()
	print("[NoisePlayer] start type=%s level=%.2f (procedural)" % [noise_type, relative_level])


func stop() -> void:
	_active = false
	_playback = null
	if _player and _player.playing:
		_player.stop()


func _fill_buffer() -> void:
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	for i in frames:
		var sample := _next_sample()
		_playback.push_frame(Vector2(sample, sample))


func _next_sample() -> float:
	match _noise_type:
		"brown":
			_brown += (randf() * 2.0 - 1.0) * 0.02
			_brown = clampf(_brown, -1.0, 1.0)
			return _brown * 0.55
		"babble", "pink":
			# Przybliżenie różowego / „gwaru” — lekko wygładzony biały.
			var white := randf() * 2.0 - 1.0
			_pink_b0 = 0.99765 * _pink_b0 + white * 0.0990460
			_pink_b1 = 0.96300 * _pink_b1 + white * 0.2965164
			_pink_b2 = 0.57000 * _pink_b2 + white * 1.0526913
			return (_pink_b0 + _pink_b1 + _pink_b2 + white * 0.1848) * 0.11
		_:
			return (randf() * 2.0 - 1.0) * 0.22
