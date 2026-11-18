extends Area3D
## Strefa potwierdzenia ruchem: wejdź postacią (bez klikania kursorem).

signal walked_in(zone: Area3D)

const IconFactory = preload("res://scripts/art/icon_factory.gd")
const MeshFactory = preload("res://scripts/art/mesh_factory.gd")

const DWELL_SEC := 0.18

@export var icon_id: String = "play"
@export var accent: Color = Color(0.35, 0.75, 0.45)
@export var radius: float = 0.55

var choice_id: String = ""
var kind: String = "accept" # accept | dismiss | choice | replay
var _dwell_body: Node3D = null
var _dwell_t: float = 0.0
var _armed: bool = true


func setup(p_kind: String, p_icon: String, pos: Vector3, p_accent: Color = Color(0.35, 0.75, 0.45), p_choice: String = "") -> void:
	kind = p_kind
	icon_id = p_icon
	accent = p_accent
	choice_id = p_choice
	position = pos
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius * 0.72 # Area < mesh
	cyl.height = 0.4
	shape.shape = cyl
	shape.position = Vector3(0, 0.2, 0)
	add_child(shape)
	var mat := MeshFactory.mat(accent, 0.65, 0.0, accent, 0.45)
	MeshFactory.add_mesh(self, MeshFactory.cylinder(radius * 0.9, radius, 0.1, 16), mat, Vector3(0, 0.05, 0))
	var spr := Sprite3D.new()
	spr.texture = IconFactory.get_icon(icon_id)
	spr.pixel_size = 0.016
	spr.position = Vector3(0, 0.75, 0)
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.shaded = false
	add_child(spr)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func set_armed(on: bool) -> void:
	_armed = on
	monitoring = on


func _physics_process(delta: float) -> void:
	if not _armed or _dwell_body == null:
		_dwell_t = 0.0
		return
	_dwell_t += delta
	if _dwell_t >= DWELL_SEC:
		_dwell_t = 0.0
		_armed = false
		monitoring = false
		walked_in.emit(self)


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		_dwell_body = body
		_dwell_t = 0.0


func _on_exit(body: Node3D) -> void:
	if body == _dwell_body:
		_dwell_body = null
		_dwell_t = 0.0
