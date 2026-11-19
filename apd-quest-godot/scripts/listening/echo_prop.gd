extends Area3D
## Symbol — mesh większy niż Area (konsultacja §5: Area ≈ 0,55–0,75× footprint).

signal picked(prop: Area3D)

const IconFactory = preload("res://scripts/art/icon_factory.gd")
const MeshFactory = preload("res://scripts/art/mesh_factory.gd")

## Footprint wizualny ~1,0 m; Area ~0,7× → radius 0,35.
const MESH_RADIUS := 0.48
const PICK_RADIUS := 0.35

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
	collision_layer = 4 # echo_pickup
	collision_mask = 2 # player
	monitoring = true
	monitorable = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = PICK_RADIUS
	shape.shape = sphere
	shape.position = Vector3(0, 0.3, 0)
	add_child(shape)
	MeshFactory.add_mesh(
		self,
		MeshFactory.cylinder(MESH_RADIUS * 0.85, MESH_RADIUS, 0.12, 16),
		MeshFactory.mat(Color(0.92, 0.82, 0.55), 0.8),
		Vector3(0, 0.06, 0)
	)
	var spr := Sprite3D.new()
	spr.texture = IconFactory.get_icon(icon_id)
	# ~1,15 m wysokości (IconFactory.CANONICAL_SIZE × pixel_size) — nie surowy 1024 PNG.
	spr.pixel_size = IconFactory.sprite_pixel_size()
	spr.position = Vector3(0, 0.72, 0)
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.shaded = false
	spr.no_depth_test = false
	spr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spr)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if carried or placed or not monitoring:
		return
	if body.is_in_group("player"):
		picked.emit(self)


func reset_home() -> void:
	carried = false
	placed = false
	visible = true
	monitoring = true
	position = _home
