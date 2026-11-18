extends Area3D
## Slot na planszy z cyfrą 1–10 (dziecko zna cyfry). Wejście z przedmiotem = włóż.

signal place_requested(slot: Area3D)

const MeshFactory = preload("res://scripts/art/mesh_factory.gd")

var slot_index: int = 0 # 0-based
var digit: int = 1
var filled_word_id: String = ""
var _pad: MeshInstance3D
var _glow: StandardMaterial3D
var _digit_label: Label3D
var _placed_visual: Node3D = null


func setup(index: int, pos: Vector3) -> void:
	slot_index = index
	digit = index + 1
	position = pos
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.55
	cyl.height = 0.4
	shape.shape = cyl
	shape.position = Vector3(0, 0.2, 0)
	add_child(shape)
	_glow = MeshFactory.mat(Color(0.55, 0.75, 0.95), 0.7, 0.0, Color(0.4, 0.7, 1.0), 0.15)
	_pad = MeshFactory.add_mesh(self, MeshFactory.cylinder(0.5, 0.55, 0.1, 20), _glow, Vector3(0, 0.05, 0))
	_digit_label = Label3D.new()
	_digit_label.text = str(digit)
	_digit_label.font_size = 96
	_digit_label.pixel_size = 0.018
	_digit_label.position = Vector3(0, 0.85, 0)
	_digit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_digit_label.modulate = Color(0.1, 0.2, 0.45)
	_digit_label.outline_modulate = Color(1, 1, 1, 1)
	_digit_label.outline_size = 12
	add_child(_digit_label)
	# Słupek z cyfrą — czytelniejszy z dystansu
	MeshFactory.add_mesh(self, MeshFactory.cylinder(0.08, 0.1, 0.55, 10), MeshFactory.mat(Color(0.95, 0.9, 0.7)), Vector3(0, 0.35, 0))
	body_entered.connect(_on_body_entered)


func is_empty() -> bool:
	return filled_word_id == ""


func set_highlight(on: bool) -> void:
	if _glow == null:
		return
	if on:
		_glow.emission_energy_multiplier = 1.1
		_glow.albedo_color = Color(0.75, 0.95, 0.55)
	else:
		_glow.emission_energy_multiplier = 0.15
		_glow.albedo_color = Color(0.55, 0.75, 0.95)


func place_prop(prop: Area3D) -> void:
	filled_word_id = str(prop.get("word_id"))
	prop.placed = true
	prop.carried = false
	prop.monitoring = false
	# Przypnij wizualnie do slotu
	var parent := prop.get_parent()
	if parent:
		parent.remove_child(prop)
	add_child(prop)
	prop.position = Vector3(0, 0.35, 0)
	prop.scale = Vector3(0.85, 0.85, 0.85)
	_digit_label.modulate = Color(0.2, 0.55, 0.3)
	set_highlight(false)


func clear_slot() -> void:
	filled_word_id = ""
	for c in get_children():
		if c is Area3D and c.has_method("setup"):
			# prop zostanie wrócony przez board
			pass
	_digit_label.modulate = Color(0.15, 0.25, 0.45)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and is_empty():
		place_requested.emit(self)
