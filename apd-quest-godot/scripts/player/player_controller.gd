extends CharacterBody3D
## Third-person ruch względem kamery. Blokowany gdy QuestManager.movement_locked.

@export var speed: float = 4.5
@export var acceleration: float = 14.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.0035
@export var pitch_min: float = -0.55
@export var pitch_max: float = 0.35

@onready var pivot: Node3D = $CameraPivot
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _yaw: float = 0.0
var _pitch: float = -0.25
var _look_enabled: bool = false


func _ready() -> void:
	_yaw = rotation.y
	_apply_camera()


func _unhandled_input(event: InputEvent) -> void:
	if QuestManager.movement_locked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		_look_enabled = event.pressed
		if _look_enabled:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and _look_enabled:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, pitch_min, pitch_max)
		_apply_camera()
	elif event.is_action_pressed("ui_cancel"):
		_look_enabled = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Vector2.ZERO
	if not QuestManager.movement_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var cam_yaw_basis := Basis(Vector3.UP, _yaw)
	var direction := (cam_yaw_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		var look := Vector3(direction.x, 0.0, direction.z)
		if look.length_squared() > 0.001 and mesh:
			var target_yaw := atan2(-look.x, -look.z)
			mesh.rotation.y = lerp_angle(mesh.rotation.y, target_yaw, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	move_and_slide()


func _apply_camera() -> void:
	rotation.y = 0.0
	pivot.rotation = Vector3(_pitch, _yaw, 0.0)
