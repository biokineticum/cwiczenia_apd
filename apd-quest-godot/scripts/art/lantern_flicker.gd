extends Node
class_name LanternFlicker
## Soft energy flicker for OmniLight3D lanterns.

@export var speed_a: float = 3.1
@export var speed_b: float = 7.4

var _phase: float = 0.0
var _base: float = 1.4


func _ready() -> void:
	_phase = randf() * TAU
	var p := get_parent()
	if p is OmniLight3D:
		_base = (p as OmniLight3D).light_energy


func _process(delta: float) -> void:
	_phase += delta
	var p := get_parent()
	if p is OmniLight3D:
		(p as OmniLight3D).light_energy = _base * (
			0.88 + 0.12 * sin(_phase * speed_a) + 0.05 * sin(_phase * speed_b)
		)
