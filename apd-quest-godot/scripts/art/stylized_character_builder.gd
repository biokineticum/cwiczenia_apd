extends RefCounted
class_name StylizedCharacterBuilder
## Characters from Grab3D rigged CC0 GLBs (walk + run clips).
## Player: Child. Echo: Elf. Burza/Storm: Witch.
## Keep FaceFront marker +Z; gameplay/collision unchanged.
## Animation: CharacterAnimator on Visual (walk-frame idle rest + walk/run).

const CharacterAnimator = preload("res://scripts/art/character_animator.gd")

enum Style { GIRL, ECHO, STORM }

const PATH_GIRL := "res://assets/models/characters/player_girl.glb"
const PATH_ECHO := "res://assets/models/characters/npc_echo.glb"
const PATH_STORM := "res://assets/models/characters/npc_storm.glb"

## Child ~1.30 m → ~1.46 m after scale (collision capsule feel).
const SCALE_GIRL := 1.12
## Elf ~1.72 m → ~1.45 m
const SCALE_ECHO := 0.84
## Witch ~1.68 m → ~1.45 m
const SCALE_STORM := 0.86
## Tiny lift so soles clear terrain z-fight after AABB ground-align.
const FOOT_CLEARANCE := 0.01


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
			scale = SCALE_ECHO
		Style.STORM:
			path = PATH_STORM
			scale = SCALE_STORM

	var body := _load_glb(path)
	if body == null:
		push_error("[StylizedCharacterBuilder] missing GLB: %s" % path)
		return root

	body.name = "BodyMesh"
	body.scale = Vector3.ONE * scale
	# Grab3D: pivot at base, +Z face. Still AABB-align so any import with a
	# mid-body origin (or tiny sole bias) stands with feet on Y=0.
	_ground_align_feet(body)
	body.position.y += FOOT_CLEARANCE
	root.add_child(body)

	if style == Style.ECHO and accent != Color.WHITE:
		_tint_meshes(body, accent, 0.22)
	elif style == Style.STORM and accent != Color.WHITE:
		_tint_meshes(body, accent, 0.18)

	var face_mark := Node3D.new()
	face_mark.name = "FaceFront"
	face_mark.position = Vector3(0.0, 1.15 * scale + FOOT_CLEARANCE, 0.12 * scale)
	root.add_child(face_mark)

	var animator: Node = CharacterAnimator.new()
	animator.name = "CharacterAnimator"
	root.add_child(animator)
	# CharacterAnimator._ready → setup(parent Visual) after reparent into player/NPC.
	return root


## Shift body so the lowest mesh vertex lands at local Y=0 (feet on ground).
static func _ground_align_feet(body: Node3D) -> void:
	var min_y := _mesh_min_y(body, Transform3D.IDENTITY)
	if min_y < INF:
		body.position.y -= min_y


static func _mesh_min_y(n: Node, parent_xf: Transform3D) -> float:
	var xf := parent_xf
	if n is Node3D:
		xf = parent_xf * (n as Node3D).transform
	var min_y := INF
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			var aabb: AABB = mi.get_aabb()
			for i in 8:
				min_y = minf(min_y, (xf * aabb.get_endpoint(i)).y)
	for c in n.get_children():
		min_y = minf(min_y, _mesh_min_y(c, xf))
	return min_y


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
