extends Node
## Tworzy busy audio przy starcie. Mowa i szum na osobnych busach → wspólny Master.
## Bez kalibracji RMS nie twierdzimy o klinicznym SNR.

const BUS_SPEECH := "Speech"
const BUS_NOISE := "Noise"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const BUS_UI := "UI"


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
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
