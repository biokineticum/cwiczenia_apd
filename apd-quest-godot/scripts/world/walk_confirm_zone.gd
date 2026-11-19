extends Area3D
## Strefa potwierdzenia ruchem: wejdź postacią (bez klikania kursorem).
## One-shot: po wyzwoleniu monitoring wyłączany deferred.

signal walked_in(zone: Area3D)

const IconFactory = preload("res://scripts/art/icon_factory.gd")
const MeshFactory = preload("res://scripts/art/mesh_factory.gd")

const DWELL_SEC := 0.18

@export var icon_id: String = "play"
@export var accent: Color = Color(0.35, 0.75, 0.45)
@export var radius: float = 0.55

var choice_id: String = ""
var kind: String = "accept" # accept | dismiss | choice | replay | undo
var _dwell_body: Node3D = null
var _dwell_t: float = 0.0
var _armed: bool = true
var _fired: bool = false
var _icon: Sprite3D = null
const _ICON_BASE_Y := 1.05
const _ICON_CAM_BIAS := 0.45


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
	_icon = Sprite3D.new()
	_icon.texture = IconFactory.get_icon(icon_id)
	# Kanoniczny pixel_size: pad czytelny dla 5-latki, nie ~17 m z surowego 1024.
	_icon.pixel_size = IconFactory.sprite_pixel_size()
	_icon.position = Vector3(0, _ICON_BASE_Y, 0)
	_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icon.shaded = false
	_icon.double_sided = true
	# Zawsze przed meshami postaci: bez depth test + wysoki priorytet + offset do kamery.
	_icon.no_depth_test = true
	_icon.render_priority = 32
	_icon.sorting_offset = 32.0
	_icon.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	_icon.transparent = true
	_icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_icon.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_icon)
	set_process(true)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _process(_delta: float) -> void:
	if _icon == null or not is_instance_valid(_icon):
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		_icon.position = Vector3(0, _ICON_BASE_Y, 0)
		return
	var toward := cam.global_position - global_position
	if toward.length_squared() < 0.0001:
		_icon.position = Vector3(0, _ICON_BASE_Y, 0)
		return
	# Lokalny offset w stronę kamery — fizycznie bliżej oka niż NPC za pad'em.
	var local_bias := global_transform.basis.inverse() * (toward.normalized() * _ICON_CAM_BIAS)
	_icon.position = Vector3(0, _ICON_BASE_Y, 0) + local_bias


func set_armed(on: bool) -> void:
	_armed = on
	_fired = not on
	if on:
		_dwell_body = null
		_dwell_t = 0.0
	set_deferred("monitoring", on)


func _physics_process(delta: float) -> void:
	if not _armed or _fired or _dwell_body == null:
		_dwell_t = 0.0
		return
	_dwell_t += delta
	if _dwell_t >= DWELL_SEC:
		_dwell_t = 0.0
		_armed = false
		_fired = true
		set_deferred("monitoring", false)
		call_deferred("_emit_walked")


func _emit_walked() -> void:
	if not is_instance_valid(self):
		return
	walked_in.emit(self)


func _on_enter(body: Node3D) -> void:
	if _fired or not _armed:
		return
	if body.is_in_group("player"):
		_dwell_body = body
		_dwell_t = 0.0


func _on_exit(body: Node3D) -> void:
	if body == _dwell_body:
		_dwell_body = null
		_dwell_t = 0.0
