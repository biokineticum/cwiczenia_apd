extends Node3D
## Bajkowa polana: pagórki, teksturowana trawa, drzewa z korą, chatka, płotek, lampiony, atmosfera.

const MeshFactory = preload("res://scripts/art/mesh_factory.gd")

@export var world_size: float = 56.0
@export var terrain_res: int = 52

## Flat stand pads under Echo (−17,0) and Burza (17,0) — matches main.tscn spawns.
## Without these, rim hills bury Node3D NPCs while the CharacterBody3D player rides the heightmap.
const NPC_PAD_HALF_XZ := 2.5
const NPC_PAD_Y := 0.03
const NPC_ECHO_XZ := Vector2(-17.0, 0.0)
const NPC_STORM_XZ := Vector2(17.0, 0.0)

var _bark_tex: Texture2D
var _grass_tex: Texture2D
var _roof_tex: Texture2D


func _ready() -> void:
	_bark_tex = MeshFactory.make_bark_texture(64)
	_grass_tex = MeshFactory.make_grass_texture(160)
	_roof_tex = MeshFactory.make_roof_texture(64)
	_build_atmosphere()
	_build_terrain()
	_build_path()
	_build_trees()
	_build_bushes()
	_build_flowers()
	_build_mushrooms()
	_build_rocks()
	_build_cottage()
	_build_fence()
	_build_lanterns()
	_build_sign()
	_build_sparkles()
	print("[FairyClearing] Bajkowa polana gotowa.")


func _build_atmosphere() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.42, 0.55, 0.92)
	sky_mat.sky_horizon_color = Color(1.0, 0.78, 0.68)
	sky_mat.ground_bottom_color = Color(0.3, 0.45, 0.28)
	sky_mat.ground_horizon_color = Color(0.75, 0.7, 0.55)
	sky_mat.sky_curve = 0.12
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.9, 0.85, 1.0)
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.08
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.22
	env.fog_enabled = true
	env.fog_light_color = Color(0.88, 0.78, 0.98)
	env.fog_density = 0.0075
	env.fog_aerial_perspective = 0.55
	env.fog_sky_affect = 0.35
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.8
	env.volumetric_fog_enabled = false

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.9, 0.72)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.shadow_blur = 1.4
	sun.directional_shadow_max_distance = 80.0
	sun.rotation_degrees = Vector3(-48, -40, 0)
	add_child(sun)

	var fill := OmniLight3D.new()
	fill.light_color = Color(1.0, 0.7, 0.92)
	fill.light_energy = 2.2
	fill.omni_range = 20.0
	fill.position = Vector3(1.5, 4.2, -1.5)
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.light_color = Color(0.5, 0.72, 1.0)
	rim.light_energy = 1.6
	rim.omni_range = 16.0
	rim.position = Vector3(-5, 3.8, 4)
	add_child(rim)


func _build_terrain() -> void:
	var half := world_size * 0.5
	var step := world_size / float(terrain_res - 1)
	var noise := FastNoiseLite.new()
	noise.seed = 42
	noise.frequency = 0.045
	noise.fractal_octaves = 4

	var heights: PackedFloat32Array = PackedFloat32Array()
	heights.resize(terrain_res * terrain_res)
	for z in terrain_res:
		for x in terrain_res:
			var wx := -half + x * step
			var wz := -half + z * step
			var dist := Vector2(wx, wz).length() / half
			var rim := smoothstep(0.32, 1.0, dist)
			var h := noise.get_noise_2d(wx, wz) * 2.4 * rim
			h += rim * rim * 1.6
			if absf(wx) < 1.7 and wz < 3.5 and wz > -11.0:
				h *= 0.12
			# Level pads so Grab3D NPCs (fixed Y) are not sunk into rim hills.
			if _on_npc_pad(wx, wz):
				h = NPC_PAD_Y
			heights[z * terrain_res + x] = h

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in terrain_res - 1:
		for x in terrain_res - 1:
			var i00 := z * terrain_res + x
			var i10 := z * terrain_res + x + 1
			var i01 := (z + 1) * terrain_res + x
			var i11 := (z + 1) * terrain_res + x + 1
			var p00 := Vector3(-half + x * step, heights[i00], -half + z * step)
			var p10 := Vector3(-half + (x + 1) * step, heights[i10], -half + z * step)
			var p01 := Vector3(-half + x * step, heights[i01], -half + (z + 1) * step)
			var p11 := Vector3(-half + (x + 1) * step, heights[i11], -half + (z + 1) * step)
			var uv_s := 0.18
			_add_tri(st, p00, p10, p11, uv_s)
			_add_tri(st, p00, p11, p01, uv_s)
	st.generate_normals()
	var mesh := st.commit()

	var ground_mat := MeshFactory.mat_textured(_grass_tex, Color(1, 1, 1), 0.93)
	ground_mat.uv1_scale = Vector3(10, 10, 10)

	var body := StaticBody3D.new()
	body.name = "Terrain"
	body.collision_layer = 1
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = ground_mat
	body.add_child(mi)

	var shape := HeightMapShape3D.new()
	shape.map_width = terrain_res
	shape.map_depth = terrain_res
	shape.map_data = heights
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.scale = Vector3(step, 1.0, step)
	body.add_child(cs)
	add_child(body)


func _on_npc_pad(wx: float, wz: float) -> bool:
	var p := Vector2(wx, wz)
	return (
		p.distance_to(NPC_ECHO_XZ) <= NPC_PAD_HALF_XZ
		or p.distance_to(NPC_STORM_XZ) <= NPC_PAD_HALF_XZ
	)


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv_scale: float) -> void:
	st.set_uv(Vector2(a.x, a.z) * uv_scale)
	st.add_vertex(a)
	st.set_uv(Vector2(b.x, b.z) * uv_scale)
	st.add_vertex(b)
	st.set_uv(Vector2(c.x, c.z) * uv_scale)
	st.add_vertex(c)


func _build_path() -> void:
	var dirt_tex := MeshFactory.make_noise_texture(96, Color(0.5, 0.36, 0.22), Color(0.72, 0.55, 0.34), 10.0, 3)
	var mat := MeshFactory.mat_textured(dirt_tex, Color(1, 1, 1), 0.96)
	var path := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.6, 0.07, 15.0)
	path.mesh = box
	path.material_override = mat
	path.position = Vector3(0.35, 0.05, -3.0)
	add_child(path)
	var spur := MeshInstance3D.new()
	var box2 := BoxMesh.new()
	box2.size = Vector3(6.0, 0.06, 1.7)
	spur.mesh = box2
	spur.material_override = mat
	spur.position = Vector3(1.6, 0.048, -3.9)
	spur.rotation_degrees = Vector3(0, -18, 0)
	add_child(spur)


func _build_trees() -> void:
	# Trzymaj drzewa z dala od polanek questów: Echo (−17,0) i Burza (+17,0).
	var spots := [
		Vector3(-8, 0, -9), Vector3(8, 0, -9), Vector3(-5, 0, 11), Vector3(5, 0, 11),
		Vector3(-11, 0, 10), Vector3(11, 0, 10), Vector3(-3, 0, -13), Vector3(4, 0, -13),
		Vector3(-14, 0, -10), Vector3(14, 0, -10), Vector3(-9, 0, -13), Vector3(9, 0, -13),
		Vector3(0, 0, 14), Vector3(0, 0, -15),
	]
	var i := 0
	for p in spots:
		add_child(_make_tree(p, 0.9 + (i % 4) * 0.12, i))
		i += 1


func _make_tree(pos: Vector3, scale: float, seed: int) -> Node3D:
	var t := Node3D.new()
	t.position = pos
	t.scale = Vector3.ONE * scale
	var bark := MeshFactory.mat_textured(_bark_tex, Color(1, 1, 1), 0.95)
	var leaf_a := Color(0.2, 0.52, 0.26)
	var leaf_b := Color(0.42, 0.7, 0.3)
	var leaf := leaf_a.lerp(leaf_b, float(seed % 5) / 5.0)
	MeshFactory.add_mesh(t, MeshFactory.cylinder(0.14, 0.26, 1.7, 10), bark, Vector3(0, 0.85, 0))
	# Korona z kilku nieregularnych kul
	var offsets := [
		Vector3(0, 2.25, 0), Vector3(0.45, 2.4, 0.2), Vector3(-0.4, 2.35, -0.15),
		Vector3(0.15, 2.7, -0.25), Vector3(-0.2, 2.55, 0.35), Vector3(0.35, 2.15, -0.35),
	]
	var si := 0
	for off in offsets:
		var s := 0.55 + (si % 3) * 0.12
		var col := leaf.lightened(0.04 * (si % 3)).darkened(0.03 * ((si + 1) % 2))
		MeshFactory.add_mesh(t, MeshFactory.sphere(s, 14), MeshFactory.mat(col, 0.86), off)
		si += 1
	if seed % 2 == 0:
		var glow := MeshFactory.mat(Color(1.0, 0.55, 0.7), 0.45, 0.0, Color(1.0, 0.4, 0.6), 0.55)
		MeshFactory.add_mesh(t, MeshFactory.sphere(0.08), glow, Vector3(0.5, 2.1, 0.35))
		MeshFactory.add_mesh(t, MeshFactory.sphere(0.07), glow, Vector3(-0.4, 2.3, 0.3))
		MeshFactory.add_mesh(t, MeshFactory.sphere(0.06), glow, Vector3(0.1, 2.55, 0.4))
	return t


func _build_bushes() -> void:
	var spots := [Vector3(-4.5, 0, -6), Vector3(5.2, 0, -5.5), Vector3(-2.2, 0, 5.5), Vector3(3.5, 0, 4.8), Vector3(-7.5, 0, 1)]
	var i := 0
	for p in spots:
		var b := Node3D.new()
		b.position = p
		var col := Color(0.28, 0.55, 0.3).lightened(0.05 * (i % 3))
		MeshFactory.add_mesh(b, MeshFactory.sphere(0.45), MeshFactory.mat(col, 0.9), Vector3(0, 0.35, 0), Vector3(1.3, 0.85, 1.2))
		MeshFactory.add_mesh(b, MeshFactory.sphere(0.32), MeshFactory.mat(col.lightened(0.08), 0.88), Vector3(0.25, 0.4, 0.1))
		add_child(b)
		i += 1


func _build_flowers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var colors := [
		Color(1.0, 0.45, 0.65), Color(1.0, 0.85, 0.35), Color(0.65, 0.55, 1.0),
		Color(1.0, 0.6, 0.35), Color(0.95, 0.95, 1.0), Color(0.55, 0.85, 1.0),
	]
	for i in 64:
		var p := Vector3(rng.randf_range(-10, 10), 0.0, rng.randf_range(-10, 8))
		if Vector2(p.x, p.z).length() < 1.3:
			continue
		add_child(_make_flower(p, colors[i % colors.size()], rng.randf_range(0.75, 1.25)))


func _make_flower(pos: Vector3, col: Color, scale: float) -> Node3D:
	var f := Node3D.new()
	f.position = pos
	f.scale = Vector3.ONE * scale
	MeshFactory.add_mesh(f, MeshFactory.cylinder(0.015, 0.02, 0.24), MeshFactory.mat(Color(0.28, 0.55, 0.22)), Vector3(0, 0.12, 0))
	var petal := MeshFactory.mat(col, 0.65, 0.0, col, 0.18)
	for a in 6:
		var ang := a * TAU / 6.0
		var off := Vector3(cos(ang) * 0.07, 0.26, sin(ang) * 0.07)
		MeshFactory.add_mesh(f, MeshFactory.sphere(0.05), petal, off, Vector3(1.4, 0.55, 1.0))
	MeshFactory.add_mesh(f, MeshFactory.sphere(0.04), MeshFactory.mat(Color(1.0, 0.88, 0.25), 0.45), Vector3(0, 0.26, 0))
	return f


func _build_mushrooms() -> void:
	var spots := [Vector3(2.8, 0, -1.2), Vector3(-5.5, 0, -4.5), Vector3(6.2, 0, -8), Vector3(-1.8, 0, 3.2)]
	for p in spots:
		var m := Node3D.new()
		m.position = p
		MeshFactory.add_mesh(m, MeshFactory.cylinder(0.05, 0.07, 0.22), MeshFactory.mat(Color(0.95, 0.9, 0.82)), Vector3(0, 0.11, 0))
		MeshFactory.add_mesh(m, MeshFactory.sphere(0.16), MeshFactory.mat(Color(0.85, 0.25, 0.3), 0.7, 0.0, Color(1.0, 0.3, 0.35), 0.15), Vector3(0, 0.28, 0), Vector3(1.3, 0.65, 1.3))
		MeshFactory.add_mesh(m, MeshFactory.sphere(0.03), MeshFactory.mat(Color(1, 1, 1)), Vector3(0.06, 0.3, 0.05))
		add_child(m)


func _build_rocks() -> void:
	var spots := [Vector3(4.2, 0, -2.8), Vector3(-3.8, 0, -2.2), Vector3(6.5, 0, 1.5), Vector3(-7, 0, -5)]
	var mat := MeshFactory.mat(Color(0.58, 0.55, 0.5), 0.95)
	var moss := MeshFactory.mat(Color(0.38, 0.55, 0.32), 0.88)
	var i := 0
	for p in spots:
		var r := Node3D.new()
		r.position = p
		MeshFactory.add_mesh(r, MeshFactory.bumpy_rock(0.55 + i * 0.08, 10 + i), mat, Vector3(0, 0.25, 0))
		MeshFactory.add_mesh(r, MeshFactory.sphere(0.12), moss, Vector3(0.15, 0.45, 0.08))
		add_child(r)
		i += 1


func _build_cottage() -> void:
	var house := Node3D.new()
	house.name = "FairyCottage"
	house.position = Vector3(-0.5, 0, -11.8)
	var wall := MeshFactory.mat(Color(0.93, 0.84, 0.7), 0.88)
	var beam := MeshFactory.mat(Color(0.42, 0.28, 0.16), 0.9)
	var roof := MeshFactory.mat_textured(_roof_tex, Color(1, 1, 1), 0.85)
	var window := MeshFactory.mat(Color(0.75, 0.92, 1.0), 0.25, 0.0, Color(1.0, 0.95, 0.7), 0.85)
	var door := MeshFactory.mat(Color(0.52, 0.3, 0.18), 0.85)

	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(4.4, 2.5, 3.5)), wall, Vector3(0, 1.25, 0))
	# Belki fachwerk
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(4.45, 0.12, 0.12)), beam, Vector3(0, 1.9, 1.76))
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(0.12, 2.4, 0.12)), beam, Vector3(-2.1, 1.2, 1.76))
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(0.12, 2.4, 0.12)), beam, Vector3(2.1, 1.2, 1.76))
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(5.0, 0.28, 2.3)), roof, Vector3(0, 2.85, -0.75), Vector3.ONE, Vector3(30, 0, 0))
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(5.0, 0.28, 2.3)), roof, Vector3(0, 2.85, 0.75), Vector3.ONE, Vector3(-30, 0, 0))
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(1.05, 1.65, 0.12)), door, Vector3(0, 0.85, 1.78))
	MeshFactory.add_mesh(house, MeshFactory.sphere(0.05), MeshFactory.mat(Color(0.95, 0.8, 0.3), 0.4, 0.2), Vector3(0.38, 0.9, 1.86))
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(0.75, 0.75, 0.08)), window, Vector3(-1.35, 1.55, 1.78))
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(0.75, 0.75, 0.08)), window, Vector3(1.35, 1.55, 1.78))
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(0.6, 1.35, 0.6)), beam, Vector3(1.5, 3.25, -0.35))
	# Donice
	MeshFactory.add_mesh(house, MeshFactory.box(Vector3(1.1, 0.22, 0.38)), beam, Vector3(-1.35, 1.08, 1.9))
	MeshFactory.add_mesh(house, MeshFactory.sphere(0.14), MeshFactory.mat(Color(1.0, 0.4, 0.55), 0.55, 0.0, Color(1, 0.4, 0.5), 0.4), Vector3(-1.35, 1.3, 1.9))
	MeshFactory.add_mesh(house, MeshFactory.sphere(0.12), MeshFactory.mat(Color(1.0, 0.85, 0.3), 0.55, 0.0, Color(1, 0.8, 0.3), 0.35), Vector3(-1.15, 1.28, 1.95))
	add_child(house)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.4, 2.5, 3.5)
	cs.shape = box
	cs.position = Vector3(0, 1.25, 0)
	body.add_child(cs)
	house.add_child(body)


func _build_fence() -> void:
	var wood := MeshFactory.mat(Color(0.48, 0.32, 0.18), 0.9)
	var posts_z := -10.0
	for x in range(-4, 5):
		var px := float(x) * 1.1
		if absf(px) < 0.8:
			continue # furtka
		var post := Node3D.new()
		post.position = Vector3(px - 0.5, 0, posts_z)
		MeshFactory.add_mesh(post, MeshFactory.cylinder(0.05, 0.06, 0.9), wood, Vector3(0, 0.45, 0))
		MeshFactory.add_mesh(post, MeshFactory.box(Vector3(1.05, 0.08, 0.06)), wood, Vector3(0.5, 0.55, 0))
		MeshFactory.add_mesh(post, MeshFactory.box(Vector3(1.05, 0.08, 0.06)), wood, Vector3(0.5, 0.3, 0))
		add_child(post)


func _build_lanterns() -> void:
	var spots := [Vector3(-2.2, 0, -6.5), Vector3(2.8, 0, -6.2)]
	for p in spots:
		var L := Node3D.new()
		L.position = p
		var pole := MeshFactory.mat(Color(0.35, 0.28, 0.22), 0.85)
		var glass := MeshFactory.mat(Color(1.0, 0.9, 0.55), 0.3, 0.0, Color(1.0, 0.85, 0.4), 1.2)
		MeshFactory.add_mesh(L, MeshFactory.cylinder(0.05, 0.06, 1.5), pole, Vector3(0, 0.75, 0))
		MeshFactory.add_mesh(L, MeshFactory.box(Vector3(0.35, 0.4, 0.35)), glass, Vector3(0, 1.55, 0))
		MeshFactory.add_mesh(L, MeshFactory.box(Vector3(0.4, 0.08, 0.4)), pole, Vector3(0, 1.78, 0))
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.85, 0.5)
		light.light_energy = 1.4
		light.omni_range = 5.0
		light.position = Vector3(0, 1.55, 0)
		L.add_child(light)
		add_child(L)


func _build_sign() -> void:
	var sign := Node3D.new()
	sign.position = Vector3(0.2, 0, -7.3)
	var wood := MeshFactory.mat(Color(0.5, 0.34, 0.2), 0.9)
	MeshFactory.add_mesh(sign, MeshFactory.cylinder(0.06, 0.07, 1.65), wood, Vector3(0, 0.82, 0))
	MeshFactory.add_mesh(sign, MeshFactory.box(Vector3(1.9, 0.75, 0.14)), wood, Vector3(0, 1.65, 0))
	var label := Label3D.new()
	# Dekoracyjny znak — bez tekstu dla dziecka (rodzic i tak widzi polanę).
	label.text = ""
	label.visible = false
	label.font_size = 44
	label.outline_size = 12
	label.position = Vector3(0, 1.65, 0.1)
	label.modulate = Color(1.0, 0.95, 0.8)
	sign.add_child(label)
	add_child(sign)


func _build_sparkles() -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 55
	particles.lifetime = 5.0
	particles.position = Vector3(0, 1.8, -2)
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(9, 2.5, 9)
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 50.0
	mat.initial_velocity_min = 0.04
	mat.initial_velocity_max = 0.28
	mat.gravity = Vector3(0, 0.04, 0)
	mat.scale_min = 0.05
	mat.scale_max = 0.12
	mat.color = Color(1.0, 0.92, 0.7, 0.9)
	particles.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.09
	draw.height = 0.18
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(1.0, 0.95, 0.7)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(1.0, 0.85, 0.45)
	draw_mat.emission_energy_multiplier = 1.6
	draw.material = draw_mat
	particles.draw_pass_1 = draw
	add_child(particles)


func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
