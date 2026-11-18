extends CharacterBody3D
## Prosty third-person ruch. Blokowany gdy QuestManager.movement_locked.

@export var speed: float = 4.5
@export var acceleration: float = 12.0
@export var gravity: float = 20.0

@onready var pivot: Node3D = $CameraPivot


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Vector2.ZERO
	if not QuestManager.movement_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		# Lekki obrót w stronę ruchu
		var look := Vector3(direction.x, 0.0, direction.z)
		if look.length_squared() > 0.001:
			var target := Basis.looking_at(look, Vector3.UP)
			transform.basis = transform.basis.slerp(target, 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	move_and_slide()
