extends RefCounted
class_name StylizedCharacterBuilder
## Proper child silhouette via ArrayMesh kit (no PrimitiveMesh toy bricks).
## Soft skin/cloth/hair materials + clothing folds + strand hair.
## Face / shoes face +Z — keep +Z-forward yaw (PR #17).

const MeshFactory = preload("res://scripts/art/mesh_factory.gd")
const Kit = preload("res://scripts/art/character_mesh_kit.gd")

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


static func _add_hanging_arm(root: Node3D, skin: Material, side: float, shoulder_y: float) -> void:
	var sx := 0.2 * side
	# Shoulder joint blends into bodice
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.06, 0.052, 0.055, 14, 10), skin, Vector3(sx, shoulder_y, 0.01))
	# Limb grows +Y; flip so it hangs down
	MeshFactory.add_mesh(
		root,
		Kit.tapered_limb(0.34, 0.048, 0.036, 14, 0.02),
		skin,
		Vector3(sx, shoulder_y - 0.01, 0.02),
		Vector3.ONE,
		Vector3(175.0, 0.0, -18.0 * side)
	)
	var hand_x := sx + 0.12 * side
	var hand_y := shoulder_y - 0.32
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.04, 0.036, 0.045, 12, 8), skin, Vector3(hand_x, hand_y, 0.05))


static func _build_girl(root: Node3D) -> void:
	var skin := Kit.soft_skin_mat(Color(1.0, 0.84, 0.74))
	var dress := Kit.soft_cloth_mat(Color(0.92, 0.42, 0.62), 0.7)
	var apron := Kit.soft_cloth_mat(Color(1.0, 0.9, 0.93), 0.66)
	var hair := Kit.soft_hair_mat(Color(0.34, 0.17, 0.09))
	var shoe := Kit.soft_cloth_mat(Color(0.52, 0.24, 0.32), 0.8)
	var sock := Kit.soft_cloth_mat(Color(0.96, 0.93, 0.98), 0.66)
	var ribbon := Kit.soft_cloth_mat(Color(0.95, 0.55, 0.75), 0.48)
	var white := MeshFactory.mat(Color(0.99, 0.99, 1.0), 0.36)
	var iris := MeshFactory.mat(Color(0.28, 0.5, 0.82), 0.28)
	var blush := MeshFactory.mat(Color(1.0, 0.55, 0.58), 0.65, 0.0, Color(1.0, 0.45, 0.5), 0.15)

	# Legs into skirt
	MeshFactory.add_mesh(root, Kit.tapered_limb(0.36, 0.05, 0.056, 14, 0.006), sock, Vector3(-0.085, 0.05, 0.0))
	MeshFactory.add_mesh(root, Kit.tapered_limb(0.36, 0.05, 0.056, 14, 0.006), sock, Vector3(0.085, 0.05, 0.0))
	MeshFactory.add_mesh(root, Kit.shoe_mesh(0.2, 0.1, 0.07), shoe, Vector3(-0.085, 0.0, 0.025))
	MeshFactory.add_mesh(root, Kit.shoe_mesh(0.2, 0.1, 0.07), shoe, Vector3(0.085, 0.0, 0.025))

	# Folded pink dress — main silhouette
	var skirt := MeshFactory.add_mesh(
		root, Kit.folded_skirt(0.4, 0.145, 0.48, 40, 14, 0.075), dress, Vector3(0, 0.34, 0)
	)
	skirt.rotation_degrees = Vector3(0, 12, 0)

	# Continuous bodice → neck (child proportions)
	var bodice := PackedVector2Array([
		Vector2(0.145, 0.0),
		Vector2(0.17, 0.05),
		Vector2(0.19, 0.14),
		Vector2(0.18, 0.24),
		Vector2(0.15, 0.32),
		Vector2(0.11, 0.38),
		Vector2(0.075, 0.42),
		Vector2(0.07, 0.48),
		Vector2(0.078, 0.52),
	])
	MeshFactory.add_mesh(root, Kit.lathed_body(bodice, 26, 0.78), dress)
	# Skin neck ring peeking above collar
	var neck := PackedVector2Array([Vector2(0.065, 0.0), Vector2(0.072, 0.04), Vector2(0.08, 0.07)])
	MeshFactory.add_mesh(root, Kit.lathed_body(neck, 14, 1.26), skin)
	MeshFactory.add_mesh(
		root, Kit.folded_skirt(0.16, 0.09, 0.22, 20, 7, 0.03), apron,
		Vector3(0, 0.78, 0.065), Vector3(0.95, 0.8, 0.55)
	)

	_add_hanging_arm(root, skin, -1.0, 1.14)
	_add_hanging_arm(root, skin, 1.0, 1.14)

	var head_y := 1.34
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.195, 0.215, 0.185, 28, 20), skin, Vector3(0, head_y, 0))

	# Hair: layered soft cap + occiput fill + thin braids (not balloon spheres)
	MeshFactory.add_mesh(root, Kit.hair_cap(0.22, 0.19, 0.21, 28, 14), hair, Vector3(0, head_y + 0.02, -0.02))
	MeshFactory.add_mesh(root, Kit.hair_cap(0.19, 0.14, 0.17, 22, 10), hair, Vector3(0, head_y - 0.02, -0.1), Vector3(1.08, 0.95, 1.1))
	for i in 7:
		var a := -0.55 + float(i) * 0.18
		var strand := PackedVector3Array([
			Vector3(sin(a) * 0.11, head_y + 0.1, -0.06),
			Vector3(sin(a) * 0.13, head_y + 0.0, -0.15),
			Vector3(sin(a) * 0.12, head_y - 0.1, -0.13),
		])
		MeshFactory.add_mesh(root, Kit.tube_along(strand, 0.032, 0.018, 7), hair)

	# High bangs — stay above eyes
	for sx in [-0.9, -0.4, 0.0, 0.4, 0.9]:
		var bang := PackedVector3Array([
			Vector3(0.065 * sx, head_y + 0.16, 0.02),
			Vector3(0.085 * sx, head_y + 0.12, 0.12),
			Vector3(0.09 * sx, head_y + 0.08, 0.15),
		])
		MeshFactory.add_mesh(root, Kit.tube_along(bang, 0.02, 0.012, 6), hair)

	for side in [-1.0, 1.0]:
		for lane in 3:
			var ox := (float(lane) - 1.0) * 0.014
			var braid := PackedVector3Array([
				Vector3((0.14 + ox) * side, head_y + 0.0, -0.05),
				Vector3((0.18 + ox * 0.4) * side, head_y - 0.14, -0.01),
				Vector3((0.22) * side, head_y - 0.3, 0.01),
				Vector3((0.235) * side, head_y - 0.44, 0.02),
				Vector3((0.24) * side, head_y - 0.54, 0.03),
			])
			var r0 := 0.026 if lane == 1 else 0.018
			MeshFactory.add_mesh(root, Kit.tube_along(braid, r0, r0 * 0.5, 7), hair)
		MeshFactory.add_mesh(
			root, Kit.sculpted_head(0.03, 0.02, 0.03, 10, 6), ribbon,
			Vector3(0.24 * side, head_y - 0.56, 0.035)
		)

	MeshFactory.add_mesh(
		root, Kit.sculpted_head(0.05, 0.02, 0.032, 10, 6), ribbon,
		Vector3(0.0, head_y + 0.22, -0.02), Vector3(1.65, 1.0, 0.85)
	)

	_face(root, Vector3(0, head_y, 0.18), white, iris, blush, true)


static func _build_echo(root: Node3D, accent: Color) -> void:
	var robe_c := accent if accent != Color.WHITE else Color(0.4, 0.62, 0.95)
	var robe := Kit.soft_cloth_mat(robe_c, 0.68)
	var trim := Kit.soft_cloth_mat(Color(0.88, 0.95, 1.0), 0.4)
	trim.emission_enabled = true
	trim.emission = Color(0.55, 0.8, 1.0)
	trim.emission_energy_multiplier = 0.28
	var skin := Kit.soft_skin_mat(Color(0.97, 0.87, 0.8))
	var hair := Kit.soft_hair_mat(Color(0.68, 0.82, 0.95))
	var white := MeshFactory.mat(Color.WHITE, 0.36)
	var iris := MeshFactory.mat(Color(0.3, 0.72, 0.95), 0.26)
	var blush := MeshFactory.mat(Color(1.0, 0.7, 0.72), 0.65)

	MeshFactory.add_mesh(root, Kit.tapered_limb(0.38, 0.052, 0.058, 14, 0.006), skin, Vector3(-0.09, 0.05, 0))
	MeshFactory.add_mesh(root, Kit.tapered_limb(0.38, 0.052, 0.058, 14, 0.006), skin, Vector3(0.09, 0.05, 0))
	MeshFactory.add_mesh(root, Kit.folded_skirt(0.42, 0.16, 0.68, 40, 12, 0.065), robe, Vector3(0, 0.34, 0))
	var sash := PackedVector2Array([
		Vector2(0.17, 0.0), Vector2(0.22, 0.05), Vector2(0.2, 0.12), Vector2(0.14, 0.2), Vector2(0.08, 0.28),
	])
	MeshFactory.add_mesh(root, Kit.lathed_body(sash, 22, 0.98), trim)
	var neck := PackedVector2Array([Vector2(0.07, 0.0), Vector2(0.078, 0.05), Vector2(0.085, 0.08)])
	MeshFactory.add_mesh(root, Kit.lathed_body(neck, 14, 1.24), skin)
	_add_hanging_arm(root, skin, -1.0, 1.2)
	_add_hanging_arm(root, skin, 1.0, 1.2)

	var head_y := 1.42
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.2, 0.22, 0.19, 28, 20), skin, Vector3(0, head_y, 0))
	MeshFactory.add_mesh(root, Kit.hair_cap(0.23, 0.18, 0.22, 28, 14), hair, Vector3(0, head_y + 0.03, -0.025))
	MeshFactory.add_mesh(root, Kit.hair_cap(0.16, 0.12, 0.15, 18, 9), hair, Vector3(0, head_y - 0.02, -0.12))
	var wisp := PackedVector3Array([
		Vector3(0.0, head_y + 0.14, 0.0), Vector3(0.035, head_y + 0.24, 0.03), Vector3(0.0, head_y + 0.32, 0.01),
	])
	MeshFactory.add_mesh(root, Kit.tube_along(wisp, 0.032, 0.012, 6), hair)
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.045, 0.045, 0.045, 12, 8), trim, Vector3(0.34, head_y + 0.24, 0.08))
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.034, 0.034, 0.034, 10, 8), trim, Vector3(-0.32, head_y + 0.28, 0.05))
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.026, 0.026, 0.026, 8, 6), trim, Vector3(0.1, head_y + 0.36, -0.02))
	_face(root, Vector3(0, head_y, 0.18), white, iris, blush, false)


static func _build_storm(root: Node3D, accent: Color) -> void:
	var cloak_c := accent if accent != Color.WHITE else Color(0.5, 0.34, 0.78)
	var cloak := Kit.soft_cloth_mat(cloak_c, 0.7)
	var lining := Kit.soft_cloth_mat(Color(0.98, 0.78, 0.35), 0.5)
	lining.emission_enabled = true
	lining.emission = Color(1.0, 0.85, 0.4)
	lining.emission_energy_multiplier = 0.22
	var skin := Kit.soft_skin_mat(Color(0.94, 0.8, 0.72))
	var hair := Kit.soft_hair_mat(Color(0.16, 0.11, 0.24))
	var white := MeshFactory.mat(Color.WHITE, 0.36)
	var iris := MeshFactory.mat(Color(0.72, 0.48, 0.95), 0.26)
	var blush := MeshFactory.mat(Color(0.95, 0.55, 0.65), 0.65)

	MeshFactory.add_mesh(root, Kit.tapered_limb(0.38, 0.052, 0.058, 14, 0.006), skin, Vector3(-0.09, 0.05, 0))
	MeshFactory.add_mesh(root, Kit.tapered_limb(0.38, 0.052, 0.058, 14, 0.006), skin, Vector3(0.09, 0.05, 0))
	MeshFactory.add_mesh(root, Kit.folded_skirt(0.44, 0.17, 0.72, 40, 13, 0.07), cloak, Vector3(0, 0.32, 0))
	var collar := PackedVector2Array([Vector2(0.19, 0.0), Vector2(0.24, 0.04), Vector2(0.16, 0.1)])
	MeshFactory.add_mesh(root, Kit.lathed_body(collar, 20, 1.1), lining)
	var neck := PackedVector2Array([Vector2(0.07, 0.0), Vector2(0.078, 0.05), Vector2(0.085, 0.08)])
	MeshFactory.add_mesh(root, Kit.lathed_body(neck, 14, 1.26), skin)
	_add_hanging_arm(root, skin, -1.0, 1.22)
	_add_hanging_arm(root, skin, 1.0, 1.22)

	var head_y := 1.44
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.2, 0.22, 0.19, 28, 20), skin, Vector3(0, head_y, 0))
	MeshFactory.add_mesh(root, Kit.hair_cap(0.225, 0.2, 0.215, 28, 14), hair, Vector3(0, head_y + 0.04, -0.025))
	for i in 6:
		var ang := (float(i) / 6.0) * TAU
		var ox := cos(ang) * 0.1
		var oz := sin(ang) * 0.085 - 0.035
		var spike := PackedVector3Array([
			Vector3(ox * 0.45, head_y + 0.05, oz * 0.45),
			Vector3(ox, head_y + 0.18, oz),
			Vector3(ox * 1.05, head_y + 0.34 + float(i % 2) * 0.035, oz * 1.05),
		])
		MeshFactory.add_mesh(root, Kit.tube_along(spike, 0.038, 0.01, 7), hair)
	MeshFactory.add_mesh(root, Kit.sculpted_head(0.04, 0.04, 0.04, 10, 8), lining, Vector3(0.045, head_y + 0.38, 0.025))
	_face(root, Vector3(0, head_y, 0.18), white, iris, blush, false)


static func _face(root: Node3D, head_pos: Vector3, white: Material, iris: Material, blush: Material, freckles: bool) -> void:
	var face := Node3D.new()
	face.name = "FaceFront"
	face.position = head_pos
	root.add_child(face)
	var eye_y := 0.015
	var face_z := 0.014
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.033), white, Vector3(-0.06, eye_y, face_z))
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.033), white, Vector3(0.06, eye_y, face_z))
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.017), iris, Vector3(-0.06, eye_y, face_z + 0.004))
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.017), iris, Vector3(0.06, eye_y, face_z + 0.004))
	var pupil := MeshFactory.mat(Color(0.08, 0.08, 0.12), 0.24)
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.008), pupil, Vector3(-0.06, eye_y, face_z + 0.007))
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.008), pupil, Vector3(0.06, eye_y, face_z + 0.007))
	var hi := MeshFactory.mat(Color(1, 1, 1), 0.16, 0.0, Color(1, 1, 1), 0.45)
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.005), hi, Vector3(-0.053, eye_y + 0.007, face_z + 0.009))
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.005), hi, Vector3(0.067, eye_y + 0.007, face_z + 0.009))
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.025), blush, Vector3(-0.09, -0.028, face_z - 0.002), Vector3(1.25, 1.0, 1.0))
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.025), blush, Vector3(0.09, -0.028, face_z - 0.002), Vector3(1.25, 1.0, 1.0))
	var nose := MeshFactory.mat(Color(1.0, 0.78, 0.7), 0.6)
	MeshFactory.add_mesh(face, MeshFactory.face_disc(0.012), nose, Vector3(0.0, -0.014, face_z + 0.011))
	var smile := MeshFactory.mat(Color(0.78, 0.35, 0.42), 0.45)
	MeshFactory.add_mesh(face, MeshFactory.face_quad(Vector2(0.08, 0.012)), smile, Vector3(0, -0.07, face_z + 0.005))
	if freckles:
		var f := MeshFactory.mat(Color(0.85, 0.5, 0.4), 0.7)
		MeshFactory.add_mesh(face, MeshFactory.face_disc(0.007), f, Vector3(-0.082, -0.01, face_z + 0.006))
		MeshFactory.add_mesh(face, MeshFactory.face_disc(0.006), f, Vector3(0.082, -0.014, face_z + 0.006))
		MeshFactory.add_mesh(face, MeshFactory.face_disc(0.006), f, Vector3(0.0, -0.032, face_z + 0.008))
