extends RefCounted
class_name StylizedCharacterBuilder
## Characters from imported CC0 GLB meshes (not PrimitiveMesh / ArrayMesh toys).
## Player: Grab3D Child (CC0). Echo/Storm: Quaternius Modular Women (CC0).
## Keep FaceFront marker +Z; gameplay/collision unchanged.

enum Style { GIRL, ECHO, STORM }

const PATH_GIRL := "res://assets/models/characters/player_girl.glb"
const PATH_ECHO := "res://assets/models/characters/npc_echo.glb"
const PATH_STORM := "res://assets/models/characters/npc_storm.glb"

## Child ~1.30 m → match prior ~1.5 collision capsule feel.
const SCALE_GIRL := 1.12
## Quaternius adults ~1.85–2.05 m → ~child height beside Grab3D child.
const SCALE_NPC := 0.68


static func build(style: Style, accent: Color = Color.WHITE) -> Node3D:
	var root := Node3D.new()
	root.name = "Visual"
	var path := PATH_GIRL
	var scale := SCALE_GIRL
	match style:
		Style.GIRL:
			path = PATH_GIRL
			scale = SCALE_GIRL
		Style.ECHO:
			path = PATH_ECHO
			scale = SCALE_NPC
		Style.STORM:
			path = PATH_STORM
			scale = SCALE_NPC

	var body := _load_glb(path)
	if body == null:
		push_error("[StylizedCharacterBuilder] missing GLB: %s" % path)
		return root

	body.name = "BodyMesh"
	body.scale = Vector3.ONE * scale
	# Imported meshes face +Z already (Grab3D child / Quaternius).
	root.add_child(body)

	if style == Style.ECHO and accent != Color.WHITE:
		_tint_meshes(body, accent, 0.35)
	elif style == Style.STORM and accent != Color.WHITE:
		_tint_meshes(body, accent, 0.25)

	# Explicit front marker for debug / yaw conventions (PR #17).
	var face_mark := Node3D.new()
	face_mark.name = "FaceFront"
	face_mark.position = Vector3(0.0, 1.15 * scale, 0.12 * scale)
	root.add_child(face_mark)
	return root


static func _load_glb(res_path: String) -> Node3D:
	var path := res_path
	if not FileAccess.file_exists(path):
		path = ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(path, state)
	if err != OK:
		push_warning("[StylizedCharacterBuilder] GLTF err=%s path=%s" % [err, path])
		return null
	var scene := doc.generate_scene(state)
	if scene is Node3D:
		_enable_shadows(scene)
		return scene as Node3D
	var wrap := Node3D.new()
	wrap.add_child(scene)
	_enable_shadows(wrap)
	return wrap


static func _enable_shadows(n: Node) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for c in n.get_children():
		_enable_shadows(c)


static func _tint_meshes(n: Node, accent: Color, amount: float) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mat := mi.get_active_material(0)
		if mat == null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
			mat = mi.mesh.surface_get_material(0)
		if mat is StandardMaterial3D:
			var sm := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			sm.albedo_color = sm.albedo_color.lerp(accent, amount)
			mi.material_override = sm
	for c in n.get_children():
		_tint_meshes(c, accent, amount)
