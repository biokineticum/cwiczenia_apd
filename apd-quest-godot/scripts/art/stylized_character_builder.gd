extends RefCounted
class_name StylizedCharacterBuilder
## Bajkowe postacie: falowana spódnica, fryzura z kępek, twarz, buty — nie sama capsule.

const MeshFactory = preload("res://scripts/art/mesh_factory.gd")

enum Style { GIRL, ECHO, STORM }


static func build(style: Style, accent: Color = Color.WHITE) -> Node3D:
	var root := Node3D.new()
	root.name = "Visual"
	match style:
		Style.GIRL:
			_build_girl(root)
		Style.ECHO:
			_build_echo(root, accent)
		Style.STORM:
			_build_storm(root, accent)
	return root


static func _build_girl(root: Node3D) -> void:
	var skin := MeshFactory.mat(Color(1.0, 0.84, 0.74), 0.65)
	var dress := MeshFactory.mat(Color(0.9, 0.4, 0.58), 0.72)
	var apron := MeshFactory.mat(Color(1.0, 0.88, 0.92), 0.7)
	var hair := MeshFactory.mat(Color(0.4, 0.22, 0.12), 0.88)
	var shoe := MeshFactory.mat(Color(0.58, 0.28, 0.36), 0.8)
	var sock := MeshFactory.mat(Color(0.95, 0.92, 0.98), 0.75)
	var white := MeshFactory.mat(Color(0.99, 0.99, 1.0), 0.45)
	var iris := MeshFactory.mat(Color(0.28, 0.5, 0.82), 0.35)
	var blush := MeshFactory.mat(Color(1.0, 0.55, 0.58), 0.75, 0.0, Color(1.0, 0.45, 0.5), 0.2)
	var ribbon := MeshFactory.mat(Color(0.95, 0.55, 0.75), 0.6, 0.0, Color(1.0, 0.6, 0.8), 0.15)

	MeshFactory.add_mesh(root, MeshFactory.cylinder(0.07, 0.08, 0.28), sock, Vector3(-0.11, 0.16, 0.0))
	MeshFactory.add_mesh(root, MeshFactory.cylinder(0.07, 0.08, 0.28), sock, Vector3(0.11, 0.16, 0.0))
	MeshFactory.add_mesh(root, MeshFactory.box(Vector3(0.17, 0.09, 0.26)), shoe, Vector3(-0.11, 0.04, 0.05))
	MeshFactory.add_mesh(root, MeshFactory.box(Vector3(0.17, 0.09, 0.26)), shoe, Vector3(0.11, 0.04, 0.05))

	# Falowana spódnica ArrayMesh
	var skirt := MeshFactory.add_mesh(root, MeshFactory.flared_skirt(0.48, 0.2, 0.55, 22), dress, Vector3(0, 0.28, 0))
	skirt.rotation_degrees = Vector3(0, 12, 0)
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.2), apron, Vector3(0, 0.88, 0.08), Vector3(1.15, 0.55, 0.85))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.23), dress, Vector3(0, 0.95, 0), Vector3(1.05, 0.75, 1.0))

	MeshFactory.add_mesh(root, MeshFactory.capsule(0.055, 0.4), skin, Vector3(-0.36, 0.95, 0.0), Vector3.ONE, Vector3(8, 0, 22))
	MeshFactory.add_mesh(root, MeshFactory.capsule(0.055, 0.4), skin, Vector3(0.36, 0.95, 0.0), Vector3.ONE, Vector3(8, 0, -22))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.05), skin, Vector3(-0.42, 0.72, 0.05))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.05), skin, Vector3(0.42, 0.72, 0.05))

	MeshFactory.add_mesh(root, MeshFactory.sphere(0.23), skin, Vector3(0, 1.28, 0))
	# Grzywka + czupryna
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.25), hair, Vector3(0, 1.38, -0.03), Vector3(1.2, 0.85, 1.15))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.1), hair, Vector3(-0.1, 1.28, 0.18), Vector3(1.4, 0.55, 0.7))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.1), hair, Vector3(0.1, 1.28, 0.18), Vector3(1.4, 0.55, 0.7))
	# Warkocze z koralikami
	for side in [-1.0, 1.0]:
		MeshFactory.add_mesh(root, MeshFactory.sphere(0.085), hair, Vector3(0.22 * side, 1.12, -0.02))
		MeshFactory.add_mesh(root, MeshFactory.sphere(0.075), hair, Vector3(0.26 * side, 0.98, 0.0))
		MeshFactory.add_mesh(root, MeshFactory.sphere(0.065), hair, Vector3(0.28 * side, 0.86, 0.02))
		MeshFactory.add_mesh(root, MeshFactory.sphere(0.04), ribbon, Vector3(0.28 * side, 0.78, 0.03))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.07), ribbon, Vector3(0.0, 1.55, 0.06), Vector3(1.8, 0.65, 0.7))

	_face(root, Vector3(0, 1.28, 0.2), white, iris, blush, true)


static func _build_echo(root: Node3D, accent: Color) -> void:
	var robe_c := accent if accent != Color.WHITE else Color(0.4, 0.62, 0.95)
	var robe := MeshFactory.mat(robe_c, 0.68)
	var trim := MeshFactory.mat(Color(0.88, 0.95, 1.0), 0.4, 0.12, Color(0.55, 0.8, 1.0), 0.35)
	var skin := MeshFactory.mat(Color(0.97, 0.87, 0.8), 0.65)
	var hair := MeshFactory.mat(Color(0.78, 0.9, 0.98), 0.5, 0.05, Color(0.55, 0.8, 1.0), 0.25)
	var white := MeshFactory.mat(Color.WHITE, 0.45)
	var iris := MeshFactory.mat(Color(0.3, 0.72, 0.95), 0.3)
	var blush := MeshFactory.mat(Color(1.0, 0.7, 0.72), 0.75)

	MeshFactory.add_mesh(root, MeshFactory.cylinder(0.075, 0.085, 0.35), skin, Vector3(-0.12, 0.18, 0))
	MeshFactory.add_mesh(root, MeshFactory.cylinder(0.075, 0.085, 0.35), skin, Vector3(0.12, 0.18, 0))
	MeshFactory.add_mesh(root, MeshFactory.flared_skirt(0.52, 0.22, 0.75, 24), robe, Vector3(0, 0.3, 0))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.28), trim, Vector3(0, 1.08, 0), Vector3(1.1, 0.5, 1.1))
	MeshFactory.add_mesh(root, MeshFactory.capsule(0.06, 0.48), skin, Vector3(-0.4, 1.0, 0), Vector3.ONE, Vector3(0, 0, 14))
	MeshFactory.add_mesh(root, MeshFactory.capsule(0.06, 0.48), skin, Vector3(0.4, 1.0, 0), Vector3.ONE, Vector3(0, 0, -14))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.24), skin, Vector3(0, 1.4, 0))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.27), hair, Vector3(0, 1.52, -0.04), Vector3(1.25, 0.8, 1.2))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.1), hair, Vector3(0, 1.62, 0.05), Vector3(1.3, 0.7, 1.0))
	# Orbity echa
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.07), trim, Vector3(0.4, 1.65, 0.12))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.05), trim, Vector3(-0.38, 1.7, 0.08))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.04), trim, Vector3(0.15, 1.85, -0.05))
	_face(root, Vector3(0, 1.4, 0.21), white, iris, blush, false)


static func _build_storm(root: Node3D, accent: Color) -> void:
	var cloak_c := accent if accent != Color.WHITE else Color(0.5, 0.34, 0.78)
	var cloak := MeshFactory.mat(cloak_c, 0.7)
	var lining := MeshFactory.mat(Color(0.98, 0.78, 0.35), 0.5, 0.08, Color(1.0, 0.85, 0.4), 0.3)
	var skin := MeshFactory.mat(Color(0.94, 0.8, 0.72), 0.65)
	var hair := MeshFactory.mat(Color(0.22, 0.15, 0.32), 0.82)
	var white := MeshFactory.mat(Color.WHITE, 0.45)
	var iris := MeshFactory.mat(Color(0.72, 0.48, 0.95), 0.3)
	var blush := MeshFactory.mat(Color(0.95, 0.55, 0.65), 0.75)

	MeshFactory.add_mesh(root, MeshFactory.cylinder(0.075, 0.085, 0.34), skin, Vector3(-0.12, 0.18, 0))
	MeshFactory.add_mesh(root, MeshFactory.cylinder(0.075, 0.085, 0.34), skin, Vector3(0.12, 0.18, 0))
	MeshFactory.add_mesh(root, MeshFactory.flared_skirt(0.55, 0.24, 0.82, 24), cloak, Vector3(0, 0.28, 0))
	MeshFactory.add_mesh(root, MeshFactory.box(Vector3(0.62, 0.1, 0.22)), lining, Vector3(0, 1.1, 0.18))
	MeshFactory.add_mesh(root, MeshFactory.capsule(0.06, 0.46), skin, Vector3(-0.42, 1.02, 0), Vector3.ONE, Vector3(0, 0, 16))
	MeshFactory.add_mesh(root, MeshFactory.capsule(0.06, 0.46), skin, Vector3(0.42, 1.02, 0), Vector3.ONE, Vector3(0, 0, -16))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.24), skin, Vector3(0, 1.42, 0))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.22), hair, Vector3(0, 1.55, -0.05), Vector3(1.35, 0.95, 1.25))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.14), hair, Vector3(-0.22, 1.62, 0.02))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.13), hair, Vector3(0.24, 1.64, -0.02))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.1), hair, Vector3(0.05, 1.78, 0.0))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.07), lining, Vector3(0.08, 1.86, 0.06))
	_face(root, Vector3(0, 1.42, 0.21), white, iris, blush, false)


static func _face(root: Node3D, head_pos: Vector3, white: Material, iris: Material, blush: Material, freckles: bool) -> void:
	var eye_y := head_pos.y + 0.03
	var eye_z := head_pos.z + 0.05
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.04), white, Vector3(-0.075, eye_y, eye_z))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.04), white, Vector3(0.075, eye_y, eye_z))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.022), iris, Vector3(-0.075, eye_y, eye_z + 0.028))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.022), iris, Vector3(0.075, eye_y, eye_z + 0.028))
	var pupil := MeshFactory.mat(Color(0.08, 0.08, 0.12), 0.3)
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.012), pupil, Vector3(-0.075, eye_y, eye_z + 0.04))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.012), pupil, Vector3(0.075, eye_y, eye_z + 0.04))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.035), blush, Vector3(-0.13, head_pos.y - 0.03, eye_z - 0.02), Vector3(1.3, 0.7, 0.7))
	MeshFactory.add_mesh(root, MeshFactory.sphere(0.035), blush, Vector3(0.13, head_pos.y - 0.03, eye_z - 0.02), Vector3(1.3, 0.7, 0.7))
	var smile := MeshFactory.mat(Color(0.78, 0.35, 0.42), 0.55)
	MeshFactory.add_mesh(root, MeshFactory.box(Vector3(0.11, 0.018, 0.02)), smile, Vector3(0, head_pos.y - 0.09, eye_z + 0.02))
	if freckles:
		var f := MeshFactory.mat(Color(0.85, 0.5, 0.4), 0.8)
		MeshFactory.add_mesh(root, MeshFactory.sphere(0.012), f, Vector3(-0.1, head_pos.y - 0.01, eye_z + 0.01))
		MeshFactory.add_mesh(root, MeshFactory.sphere(0.01), f, Vector3(0.1, head_pos.y - 0.015, eye_z + 0.01))
		MeshFactory.add_mesh(root, MeshFactory.sphere(0.01), f, Vector3(0.0, head_pos.y - 0.02, eye_z + 0.02))
