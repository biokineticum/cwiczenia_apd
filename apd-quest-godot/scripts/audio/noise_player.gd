extends Node
class_name NoisePlayer
## Proceduralny szum (white/pink/brown/babble) na busie Noise — pętla WAV (nie Generator).
## Poziom jest względny — to nie jest kliniczny SNR.
## TTS idzie przez system (DisplayServer), więc szum musi być wyraźnie głośny w silniku.

@export var bus_name: String = "Noise"

const SAMPLE_RATE := 22050
const LOOP_SECONDS := 2.0
## Dolny próg głośności gracza — przy włączonym szumie dziecko ma go wyraźnie słyszeć obok TTS.
const MIN_AUDIBLE_LINEAR := 0.45

var _player: AudioStreamPlayer
var _noise_type: String = "pink"
var _relative_level: float = 0.45
var _active: bool = false


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = bus_name
	_player.volume_db = 0.0
	add_child(_player)


func start(noise_type: String = "pink", relative_level: float = 0.45) -> void:
	if not is_node_ready():
		await ready
	stop()
	_noise_type = noise_type
	_relative_level = clampf(relative_level, 0.05, 1.0)
	_ensure_player()
	_player.stream = _build_loop_stream(_noise_type)
	# Bus ≈ pełny; głośność na playerze (jedna ścieżka atenuacji, nie bus×sample).
	if AudioBusSetup:
		AudioBusSetup.set_bus_linear_volume(bus_name, 1.0)
	_player.volume_linear = maxf(_relative_level, MIN_AUDIBLE_LINEAR)
	_player.play()
	_active = _player.playing
	if not _active:
		# WASAPI / late ready — spróbuj w kolejnej klatce.
		await get_tree().process_frame
		_player.play()
		_active = _player.playing
	print(
		"[NoisePlayer] start type=%s level=%.2f vol_linear=%.2f playing=%s (wav-loop)"
		% [_noise_type, _relative_level, _player.volume_linear, _active]
	)


func stop() -> void:
	_active = false
	if _player and is_instance_valid(_player) and _player.playing:
		_player.stop()


func is_playing() -> bool:
	return _active and _player != null and _player.playing


func _ensure_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	_player = AudioStreamPlayer.new()
	_player.bus = bus_name
	add_child(_player)


func _build_loop_stream(noise_type: String) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * LOOP_SECONDS)
	var data := PackedByteArray()
	data.resize(frames * 2) # mono PCM16
	_reset_filters()
	for i in frames:
		var sample := clampf(_next_sample(noise_type, i), -1.0, 1.0)
		var s16 := int(round(sample * 32767.0))
		s16 = clampi(s16, -32768, 32767)
		if s16 < 0:
			s16 += 65536
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


var _pink_b0 := 0.0
var _pink_b1 := 0.0
var _pink_b2 := 0.0
var _brown := 0.0


func _reset_filters() -> void:
	_pink_b0 = 0.0
	_pink_b1 = 0.0
	_pink_b2 = 0.0
	_brown = 0.0


func _next_sample(noise_type: String, frame_i: int = 0) -> float:
	match noise_type:
		"brown":
			_brown += (randf() * 2.0 - 1.0) * 0.02
			_brown = clampf(_brown, -1.0, 1.0)
			return _brown * 0.85
		"babble":
			# Kilka sinusów + szum — czytelniejszy „gwar” niż sam pink.
			var t := float(frame_i) / float(SAMPLE_RATE)
			var a := sin(t * 220.0 * TAU) * 0.22
			var b := sin(t * 440.0 * TAU + 0.7) * 0.18
			var c := sin(t * 660.0 * TAU + 1.3) * 0.12
			return a + b + c + (randf() * 2.0 - 1.0) * 0.12
		"white":
			return (randf() * 2.0 - 1.0) * 0.55
		_:
			# pink (default)
			var white := randf() * 2.0 - 1.0
			_pink_b0 = 0.99765 * _pink_b0 + white * 0.0990460
			_pink_b1 = 0.96300 * _pink_b1 + white * 0.2965164
			_pink_b2 = 0.57000 * _pink_b2 + white * 1.0526913
			return (_pink_b0 + _pink_b1 + _pink_b2 + white * 0.1848) * 0.28
