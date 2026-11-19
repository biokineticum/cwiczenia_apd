extends Node
## Tworzy busy audio przy starcie. Mowa i szum na osobnych busach → wspólny Master.
## Bez kalibracji RMS nie twierdzimy o klinicznym SNR.
## Duck Noise podczas systemowego TTS (SpeechPlayer), żeby szum nie maskował bodźca.

const BUS_SPEECH := "Speech"
const BUS_NOISE := "Noise"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const BUS_UI := "UI"

## Podczas TTS bus Noise × ten współczynnik (szum dalej słyszalny, mowa czytelna).
const NOISE_DUCK_LINEAR := 0.32

var _noise_base_linear: float = 1.0
var _noise_ducked: bool = false


func _ready() -> void:
	_ensure_bus(BUS_SPEECH)
	_ensure_bus(BUS_NOISE)
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_UI)
	print("[AudioBusSetup] Busy gotowe: Speech, Noise, SFX, Music, UI")


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var idx := AudioServer.bus_count
	AudioServer.add_bus(idx)
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func set_bus_linear_volume(bus_name: String, linear: float) -> void:
	var clamped := clampf(linear, 0.0001, 1.0)
	if bus_name == BUS_NOISE:
		_noise_base_linear = clamped
		clamped = _effective_noise_linear()
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamped))


func duck_noise(active: bool) -> void:
	_noise_ducked = active
	var idx := AudioServer.get_bus_index(BUS_NOISE)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(_effective_noise_linear()))


func is_noise_ducked() -> bool:
	return _noise_ducked


func _effective_noise_linear() -> float:
	var base := clampf(_noise_base_linear, 0.0001, 1.0)
	if _noise_ducked:
		return clampf(base * NOISE_DUCK_LINEAR, 0.0001, 1.0)
	return base
