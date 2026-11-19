extends RefCounted
class_name MeshFactory
## Materiały, tekstury proceduralne i mesh’e do bajkowego stylu.


static func mat(color: Color, roughness: float = 0.85, metallic: float = 0.0, emission: Color = Color(0, 0, 0, 0), emission_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, 1.0)
	m.roughness = roughness
	m.metallic = metallic
	# Single-sided opaque — prevents face/eyes reading through hair from behind.
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	if emission.a > 0.0 or emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = Color(emission.r, emission.g, emission.b)
		m.emission_energy_multiplier = emission_energy
	return m


static func mat_textured(tex: Texture2D, color: Color = Color.WHITE, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color(color.r, color.g, color.b, 1.0)
	m.roughness = roughness
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


## Single-sided disc in XY, normal +Z. Godot front faces are clockwise; cull back → invisible from behind.
static func face_disc(radius: float, segments: int = 16) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal := Vector3(0, 0, 1)
	for i in segments:
		var a0 := float(i) / float(segments) * TAU
		var a1 := float(i + 1) / float(segments) * TAU
		var p0 := Vector3(0, 0, 0)
		var p1 := Vector3(cos(a0) * radius, sin(a0) * radius, 0)
		var p2 := Vector3(cos(a1) * radius, sin(a1) * radius, 0)
		# Clockwise when viewed from +Z: center → a1 → a0
		st.set_normal(normal)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(p0)
		st.set_normal(normal)
		st.set_uv(Vector2(cos(a1) * 0.5 + 0.5, sin(a1) * 0.5 + 0.5))
		st.add_vertex(p2)
		st.set_normal(normal)
		st.set_uv(Vector2(cos(a0) * 0.5 + 0.5, sin(a0) * 0.5 + 0.5))
		st.add_vertex(p1)
	return st.commit()


## Single-sided smile rect in XY, normal +Z (clockwise front faces).
static func face_quad(size: Vector2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var normal := Vector3(0, 0, 1)
	var verts := [
		Vector3(-hx, -hy, 0), Vector3(hx, hy, 0), Vector3(hx, -hy, 0),
		Vector3(-hx, -hy, 0), Vector3(-hx, hy, 0), Vector3(hx, hy, 0),
	]
	var uvs := [
		Vector2(0, 1), Vector2(1, 0), Vector2(1, 1),
		Vector2(0, 1), Vector2(0, 0), Vector2(1, 0),
	]
	for i in verts.size():
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])
	return st.commit()


static func add_mesh(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3 = Vector3.ZERO, scale := Vector3.ONE, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.scale = scale
	mi.rotation_degrees = rot_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


static func sphere(radius: float = 0.5, segments: int = 18) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = segments
	s.rings = maxi(8, segments / 2)
	return s


static func capsule(radius: float = 0.25, height: float = 0.8) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = height
	c.radial_segments = 14
	return c


static func cylinder(top: float, bottom: float, height: float, segments: int = 14) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = segments
	return c


static func box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


static func cone(radius: float, height: float) -> CylinderMesh:
	return cylinder(0.02, radius, height, 16)


static func flared_skirt(bottom_r: float, top_r: float, height: float, segments: int = 20) -> ArrayMesh:
	## Spódnica z lekkim „falowaniem” krawędzi — nie czysty stożek.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 6
	for yi in rings:
		var t0 := float(yi) / float(rings)
		var t1 := float(yi + 1) / float(rings)
		var y0 := t0 * height
		var y1 := t1 * height
		var r0 := lerpf(bottom_r, top_r, t0)
		var r1 := lerpf(bottom_r, top_r, t1)
		for i in segments:
			var a0 := float(i) / float(segments) * TAU
			var a1 := float(i + 1) / float(segments) * TAU
			var wave0 := 1.0 + 0.06 * sin(a0 * 5.0 + t0 * 3.0)
			var wave1 := 1.0 + 0.06 * sin(a1 * 5.0 + t0 * 3.0)
			var p00 := Vector3(cos(a0) * r0 * wave0, y0, sin(a0) * r0 * wave0)
			var p10 := Vector3(cos(a1) * r0 * wave1, y0, sin(a1) * r0 * wave1)
			var p01 := Vector3(cos(a0) * r1 * wave0, y1, sin(a0) * r1 * wave0)
			var p11 := Vector3(cos(a1) * r1 * wave1, y1, sin(a1) * r1 * wave1)
			st.set_uv(Vector2(float(i) / segments, t0))
			st.add_vertex(p00)
			st.set_uv(Vector2(float(i + 1) / segments, t0))
			st.add_vertex(p10)
			st.set_uv(Vector2(float(i + 1) / segments, t1))
			st.add_vertex(p11)
			st.set_uv(Vector2(float(i) / segments, t0))
			st.add_vertex(p00)
			st.set_uv(Vector2(float(i + 1) / segments, t1))
			st.add_vertex(p11)
			st.set_uv(Vector2(float(i) / segments, t1))
			st.add_vertex(p01)
	st.generate_normals()
	return st.commit()


static func bumpy_rock(radius: float = 0.6, seed: int = 1) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var segments := 12
	var rings := 8
	var verts: Array[Vector3] = []
	for ring in rings + 1:
		var v := float(ring) / float(rings)
		var phi := v * PI
		for seg in segments:
			var u := float(seg) / float(segments)
			var theta := u * TAU
			var nrm := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
			var bump := 1.0 + rng.randf_range(-0.18, 0.22)
			# Spłaszcz spód
			if nrm.y < -0.2:
				bump *= 0.55
			verts.append(nrm * radius * bump)
	for ring in rings:
		for seg in segments:
			var i0 := ring * segments + seg
			var i1 := ring * segments + ((seg + 1) % segments)
			var i2 := (ring + 1) * segments + seg
			var i3 := (ring + 1) * segments + ((seg + 1) % segments)
			st.add_vertex(verts[i0])
			st.add_vertex(verts[i1])
			st.add_vertex(verts[i3])
			st.add_vertex(verts[i0])
			st.add_vertex(verts[i3])
			st.add_vertex(verts[i2])
	st.generate_normals()
	return st.commit()


static func make_noise_texture(size: int, c1: Color, c2: Color, scale: float = 6.0, seed: int = 7) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = seed
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.08
	for y in size:
		for x in size:
			var v := n.get_noise_2d(x * scale / float(size), y * scale / float(size))
			var t := clampf(v * 0.5 + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, c1.lerp(c2, t))
	return ImageTexture.create_from_image(img)


static func make_grass_texture(size: int = 128) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 21
	n.frequency = 0.11
	var n2 := FastNoiseLite.new()
	n2.seed = 77
	n2.frequency = 0.35
	var c1 := Color(0.28, 0.52, 0.24)
	var c2 := Color(0.58, 0.82, 0.32)
	var c3 := Color(0.2, 0.42, 0.18)
	for y in size:
		for x in size:
			var a := n.get_noise_2d(x, y) * 0.5 + 0.5
			var b := n2.get_noise_2d(x, y) * 0.5 + 0.5
			var col := c1.lerp(c2, pow(a, 0.85))
			if b > 0.55:
				col = col.lerp(c3, 0.55)
			# Kępki / źdźbła
			if (x + y * 3) % 11 == 0:
				col = col.lightened(0.18)
			if (x * 2 + y) % 29 == 0:
				col = col.darkened(0.12)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func make_bark_texture(size: int = 64) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var stripe := sin(float(x) * 0.55 + sin(float(y) * 0.2) * 1.5) * 0.5 + 0.5
			var c := Color(0.38, 0.24, 0.14).lerp(Color(0.55, 0.38, 0.22), stripe)
			if y % 9 == 0:
				c = c.darkened(0.12)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func make_roof_texture(size: int = 64) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var tile := ((x / 8) + (y / 5)) % 2
			var c := Color(0.72, 0.32, 0.38) if tile == 0 else Color(0.8, 0.4, 0.42)
			if y % 5 == 0:
				c = c.darkened(0.15)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func make_checker_blend(size: int, c1: Color, c2: Color) -> ImageTexture:
	return make_grass_texture(size)
