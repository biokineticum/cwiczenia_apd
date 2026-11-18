extends Area3D
## Fizyczny kafelek-symbol na polanie. Wejście postacia = podnieś (bez klikania UI).

signal picked(prop: Area3D)

const IconFactory = preload("res://scripts/art/icon_factory.gd")
const MeshFactory = preload("res://scripts/art/mesh_factory.gd")

var word_id: String = ""
var icon_id: String = ""
var carried: bool = false
var placed: bool = false
var _home: Vector3 = Vector3.ZERO


func setup(p_word_id: String, p_icon_id: String, pos: Vector3) -> void:
	word_id = p_word_id
	icon_id = p_icon_id
	position = pos
	_home = pos
	collision_layer = 4
	collision_mask = 2 # player
	monitoring = true
	monitorable = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.7
	shape.shape = sphere
	shape.position = Vector3(0, 0.4, 0)
	add_child(shape)
	# Podstawka
	MeshFactory.add_mesh(self, MeshFactory.cylinder(0.35, 0.4, 0.12, 16), MeshFactory.mat(Color(0.92, 0.82, 0.55), 0.8), Vector3(0, 0.06, 0))
	# Ikona jako billboard
	var spr := Sprite3D.new()
	spr.texture = IconFactory.get_icon(icon_id)
	spr.pixel_size = 0.018
	spr.position = Vector3(0, 0.75, 0)
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.shaded = false
	add_child(spr)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if carried or placed:
		return
	if body.is_in_group("player"):
		picked.emit(self)


func reset_home() -> void:
	carried = false
	placed = false
	visible = true
	monitoring = true
	if get_parent():
		# Zostanie przeniesione przez board
		pass
	global_position = _home
