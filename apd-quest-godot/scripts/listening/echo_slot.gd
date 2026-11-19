extends Area3D
## Slot 1–4 — Area ściśle na platformie, mniejsze od mesha (konsultacja §5).

signal place_requested(slot: Area3D)

const MeshFactory = preload("res://scripts/art/mesh_factory.gd")

const PAD_RADIUS := 0.55
const PLACE_RADIUS := 0.38 # ~0,7× pad
const DWELL_SEC := 0.15

var slot_index: int = 0
var digit: int = 1
var filled_word_id: String = ""
var _pad: MeshInstance3D
var _glow: StandardMaterial3D
var _digit_label: Label3D
var _dwell_body: Node3D = null
var _dwell_time: float = 0.0


func setup(index: int, pos: Vector3) -> void:
	slot_index = index
	digit = index + 1
	position = pos
	collision_layer = 8 # echo_slot
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = PLACE_RADIUS
	cyl.height = 0.35
	shape.shape = cyl
	shape.position = Vector3(0, 0.18, 0)
	add_child(shape)
	_glow = MeshFactory.mat(Color(0.55, 0.75, 0.95), 0.7, 0.0, Color(0.4, 0.7, 1.0), 0.15)
	_pad = MeshFactory.add_mesh(
		self,
		MeshFactory.cylinder(PAD_RADIUS * 0.92, PAD_RADIUS, 0.1, 18),
		_glow,
		Vector3(0, 0.05, 0)
	)
	MeshFactory.add_mesh(
		self,
		MeshFactory.cylinder(0.08, 0.1, 0.55, 10),
		MeshFactory.mat(Color(0.95, 0.9, 0.7)),
		Vector3(0, 0.35, 0)
	)
	_digit_label = Label3D.new()
	_digit_label.text = str(digit)
	_digit_label.font_size = 110
	_digit_label.pixel_size = 0.02
	_digit_label.position = Vector3(0, 0.9, 0)
	_digit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_digit_label.modulate = Color(0.1, 0.2, 0.45)
	_digit_label.outline_modulate = Color(1, 1, 1, 1)
	_digit_label.outline_size = 14
	_digit_label.no_depth_test = true
	_digit_label.render_priority = 16
	add_child(_digit_label)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if _dwell_body == null or not is_empty() or not monitoring:
		_dwell_time = 0.0
		return
	_dwell_time += delta
	if _dwell_time >= DWELL_SEC:
		_dwell_time = 0.0
		place_requested.emit(self)


func is_empty() -> bool:
	return filled_word_id == ""


func set_highlight(on: bool) -> void:
	if _glow == null:
		return
	if on:
		_glow.emission_energy_multiplier = 1.35
		_glow.albedo_color = Color(0.75, 0.95, 0.55)
	else:
		_glow.emission_energy_multiplier = 0.12
		_glow.albedo_color = Color(0.55, 0.75, 0.95)


func place_prop(prop: Area3D) -> void:
	filled_word_id = str(prop.get("word_id"))
	prop.placed = true
	prop.carried = false
	prop.set_deferred("monitoring", false)
	var parent: Node = prop.get_parent()
	if parent:
		parent.remove_child(prop)
	add_child(prop)
	prop.position = Vector3(0, 0.4, 0)
	prop.scale = Vector3(0.8, 0.8, 0.8)
	_digit_label.modulate = Color(0.2, 0.55, 0.3)
	set_highlight(false)
	_dwell_body = null
	_dwell_time = 0.0
	set_deferred("monitoring", false)


func clear_fill() -> void:
	filled_word_id = ""
	_dwell_body = null
	_dwell_time = 0.0
	set_highlight(false)
	if _digit_label:
		_digit_label.modulate = Color(0.1, 0.2, 0.45)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and is_empty():
		_dwell_body = body
		_dwell_time = 0.0


func _on_body_exited(body: Node3D) -> void:
	if body == _dwell_body:
		_dwell_body = null
		_dwell_time = 0.0
