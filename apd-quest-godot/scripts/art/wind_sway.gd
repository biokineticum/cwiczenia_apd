extends Node3D
class_name WindSway
## Subtle wind sway for trees / bushes / flowers (fairy clearing ambience).

@export var amp_deg: float = 2.8
@export var speed: float = 0.85
@export var secondary_amp_deg: float = 1.2
@export var secondary_speed: float = 1.35

var _phase: float = 0.0
var _base_rot: Vector3 = Vector3.ZERO


func _ready() -> void:
	_base_rot = rotation
	_phase = randf() * TAU
	# Slight per-instance variation
	speed *= randf_range(0.85, 1.2)
	amp_deg *= randf_range(0.75, 1.25)


func _process(delta: float) -> void:
	_phase += delta * speed
	var a := deg_to_rad(amp_deg)
	var b := deg_to_rad(secondary_amp_deg)
	rotation = _base_rot + Vector3(
		sin(_phase) * a * 0.35,
		0.0,
		sin(_phase * secondary_speed + 0.7) * a + cos(_phase * 0.55) * b
	)
