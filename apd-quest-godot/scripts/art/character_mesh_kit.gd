extends RefCounted
class_name CharacterMeshKit
## ArrayMesh builders for child-proportion characters — no PrimitiveMesh stacks.
## Front of character = +Z (matches FaceFront / +Z-forward yaw).


static func lathed_body(
	profile: PackedVector2Array,
	segments: int = 20,
	y0: float = 0.0
) -> ArrayMesh:
	## profile: (radius, y) pairs from bottom to top.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := profile.size()
	for ri in rings - 1:
		var r0 := profile[ri].x
		var y_a := y0 + profile[ri].y
		var r1 := profile[ri + 1].x
		var y_b := y0 + profile[ri + 1].y
		var v0 := float(ri) / float(rings - 1)
		var v1 := float(ri + 1) / float(rings - 1)
		for i in segments:
			var a0 := float(i) / float(segments) * TAU
			var a1 := float(i + 1) / float(segments) * TAU
			# XZ plane: angle 0 → +X; rotate so +Z is front (a=0 at +Z for clothing facing cam).
			var a0z := a0 - PI * 0.5
			var a1z := a1 - PI * 0.5
			var p00 := Vector3(cos(a0z) * r0, y_a, sin(a0z) * r0)
			var p10 := Vector3(cos(a1z) * r0, y_a, sin(a1z) * r0)
			var p01 := Vector3(cos(a0z) * r1, y_b, sin(a0z) * r1)
			var p11 := Vector3(cos(a1z) * r1, y_b, sin(a1z) * r1)
			var u0 := float(i) / float(segments)
			var u1 := float(i + 1) / float(segments)
			_tri(st, p00, p10, p11, Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1))
			_tri(st, p00, p11, p01, Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1))
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func folded_skirt(
	bottom_r: float,
	top_r: float,
	height: float,
	segments: int = 28,
	folds: int = 10,
	fold_amp: float = 0.07
) -> ArrayMesh:
	## Flared skirt with vertical fabric folds (silhouette, not a cone).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 14
	for yi in rings:
		var t0 := float(yi) / float(rings)
		var t1 := float(yi + 1) / float(rings)
		# Ease out flare near hem (smooth curve, not stepped cone)
		var flare0 := pow(1.0 - t0, 0.78)
		var flare1 := pow(1.0 - t1, 0.78)
		var y0 := t0 * height
		var y1 := t1 * height
		var r0 := lerpf(bottom_r, top_r, 1.0 - flare0)
		var r1 := lerpf(bottom_r, top_r, 1.0 - flare1)
		for i in segments:
			var a0 := float(i) / float(segments) * TAU
			var a1 := float(i + 1) / float(segments) * TAU
			var w0 := 1.0 + fold_amp * sin(a0 * float(folds)) * (0.35 + 0.65 * flare0)
			var w1 := 1.0 + fold_amp * sin(a1 * float(folds)) * (0.35 + 0.65 * flare0)
			var a0z := a0 - PI * 0.5
			var a1z := a1 - PI * 0.5
			var p00 := Vector3(cos(a0z) * r0 * w0, y0, sin(a0z) * r0 * w0)
			var p10 := Vector3(cos(a1z) * r0 * w1, y0, sin(a1z) * r0 * w1)
			var p01 := Vector3(cos(a0z) * r1 * w0, y1, sin(a0z) * r1 * w0)
			var p11 := Vector3(cos(a1z) * r1 * w1, y1, sin(a1z) * r1 * w1)
			var u0 := float(i) / float(segments)
			var u1 := float(i + 1) / float(segments)
			st.set_smooth_group(0)
			_tri(st, p00, p10, p11, Vector2(u0, t0), Vector2(u1, t0), Vector2(u1, t1))
			st.set_smooth_group(0)
			_tri(st, p00, p11, p01, Vector2(u0, t0), Vector2(u1, t1), Vector2(u0, t1))
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func sculpted_head(rx: float, ry: float, rz: float, segments: int = 22, rings: int = 16) -> ArrayMesh:
	## Soft child head: slightly wider cheeks, gentler chin, flat-ish occiput.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	for ring in rings + 1:
		var v := float(ring) / float(rings)
		var phi := v * PI
		for seg in segments:
			var u := float(seg) / float(segments)
			var theta := u * TAU
			# Sphere → ellipsoid; theta 0 at +X, shift so face (+Z) gets cheek width
			var nrm := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
			var cheek := 1.0 + 0.06 * maxf(0.0, nrm.z) * sin(phi) # wider toward face
			var chin := 1.0
			if nrm.y < -0.15:
				chin = 1.0 - 0.12 * (-nrm.y - 0.15) # softer chin point
			var back := 1.0
			if nrm.z < -0.2:
				back = 1.0 - 0.04 * (-nrm.z - 0.2)
			var p := Vector3(nrm.x * rx * cheek * back, nrm.y * ry * chin, nrm.z * rz * cheek)
			verts.append(p)
			uvs.append(Vector2(u, v))
	for ring in rings:
		for seg in segments:
			var i0 := ring * segments + seg
			var i1 := ring * segments + ((seg + 1) % segments)
			var i2 := (ring + 1) * segments + seg
			var i3 := (ring + 1) * segments + ((seg + 1) % segments)
			_tri(st, verts[i0], verts[i1], verts[i3], uvs[i0], uvs[i1], uvs[i3])
			_tri(st, verts[i0], verts[i3], verts[i2], uvs[i0], uvs[i3], uvs[i2])
	st.generate_normals()
	st.generate_tangents()
	return st.commit()


static func tapered_limb(
	length: float,
	r_top: float,
	r_bot: float,
	segments: int = 12,
	bend: float = 0.0
) -> ArrayMesh:
	## Limb along +Y from 0..length; optional soft bend toward +Z (elbow/knee hint).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 8
	for yi in rings:
		var t0 := float(yi) / float(rings)
		var t1 := float(yi + 1) / float(rings)
		var y0 := t0 * length
		var y1 := t1 * length
		var r0 := lerpf(r_top, r_bot, t0)
		var r1 := lerpf(r_top, r_bot, t1)
		# Slight bulge mid-limb
		r0 *= 1.0 + 0.08 * sin(t0 * PI)
		r1 *= 1.0 + 0.08 * sin(t1 * PI)
		var z0 := bend * sin(t0 * PI)
		var z1 := bend * sin(t1 * PI)
		for i in segments:
			var a0 := float(i) / float(segments) * TAU
			var a1 := float(i + 1) / float(segments) * TAU
			var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0 + z0)
			var p10 := Vector3(cos(a1) * r0, y0, sin(a1) * r0 + z0)
			var p01 := Vector3(cos(a0) * r1, y1, sin(a0) * r1 + z1)
			var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1 + z1)
			var u0 := float(i) / float(segments)
			var u1 := float(i + 1) / float(segments)
			_tri(st, p00, p10, p11, Vector2(u0, t0), Vector2(u1, t0), Vector2(u1, t1))
			_tri(st, p00, p11, p01, Vector2(u0, t0), Vector2(u1, t1), Vector2(u0, t1))
	st.generate_normals()
	return st.commit()


static func tube_along(
	points: PackedVector3Array,
	r_start: float,
	r_end: float,
	radial: int = 8
) -> ArrayMesh:
	## Smooth tube along a polyline (hair strands, braids).
	if points.size() < 2:
		return ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := points.size()
	var frames: Array[Basis] = []
	for i in n:
		var tang: Vector3
		if i == 0:
			tang = (points[1] - points[0]).normalized()
		elif i == n - 1:
			tang = (points[n - 1] - points[n - 2]).normalized()
		else:
			tang = (points[i + 1] - points[i - 1]).normalized()
		var up := Vector3.UP
		if absf(tang.dot(up)) > 0.92:
			up = Vector3.RIGHT
		var right := tang.cross(up).normalized()
		up = right.cross(tang).normalized()
		frames.append(Basis(right, tang, up))
	for i in n - 1:
		var t0 := float(i) / float(n - 1)
		var t1 := float(i + 1) / float(n - 1)
		var r0 := lerpf(r_start, r_end, t0)
		var r1 := lerpf(r_start, r_end, t1)
		for s in radial:
			var a0 := float(s) / float(radial) * TAU
			var a1 := float(s + 1) / float(radial) * TAU
			var o00 := frames[i].x * cos(a0) * r0 + frames[i].z * sin(a0) * r0
			var o10 := frames[i].x * cos(a1) * r0 + frames[i].z * sin(a1) * r0
			var o01 := frames[i + 1].x * cos(a0) * r1 + frames[i + 1].z * sin(a0) * r1
			var o11 := frames[i + 1].x * cos(a1) * r1 + frames[i + 1].z * sin(a1) * r1
			var p00 := points[i] + o00
			var p10 := points[i] + o10
			var p01 := points[i + 1] + o01
			var p11 := points[i + 1] + o11
			var u0 := float(s) / float(radial)
			var u1 := float(s + 1) / float(radial)
			_tri(st, p00, p10, p11, Vector2(u0, t0), Vector2(u1, t0), Vector2(u1, t1))
			_tri(st, p00, p11, p01, Vector2(u0, t0), Vector2(u1, t1), Vector2(u0, t1))
	st.generate_normals()
	return st.commit()


static func hair_cap(rx: float, ry: float, rz: float, segments: int = 20, rings: int = 10) -> ArrayMesh:
	## Upper hemisphere hair volume (not a full balloon sphere).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts: Array[Vector3] = []
	var uvs: Array[Vector2] = []
	for ring in rings + 1:
		var v := float(ring) / float(rings)
		# 0 at crown → ~110° down sides (covers skull, leaves face open)
		var phi := v * (PI * 0.58)
		for seg in segments:
			var u := float(seg) / float(segments)
			var theta := u * TAU
			var nrm := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
			# Pull hair back off the face (+Z)
			var face_pull := 1.0
			if nrm.z > 0.15:
				face_pull = 1.0 - 0.35 * (nrm.z - 0.15)
				nrm.y += 0.08 * (nrm.z - 0.15) # bangs sit higher
			var p := Vector3(nrm.x * rx, nrm.y * ry, nrm.z * rz * face_pull)
			# Slight crown lift
			p.y += 0.02
			verts.append(p)
			uvs.append(Vector2(u, v))
	for ring in rings:
		for seg in segments:
			var i0 := ring * segments + seg
			var i1 := ring * segments + ((seg + 1) % segments)
			var i2 := (ring + 1) * segments + seg
			var i3 := (ring + 1) * segments + ((seg + 1) % segments)
			_tri(st, verts[i0], verts[i1], verts[i3], uvs[i0], uvs[i1], uvs[i3])
			_tri(st, verts[i0], verts[i3], verts[i2], uvs[i0], uvs[i3], uvs[i2])
	st.generate_normals()
	return st.commit()


static func shoe_mesh(length: float = 0.2, width: float = 0.1, height: float = 0.07) -> ArrayMesh:
	## Soft rounded shoe pointing +Z.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 12
	var rings := 6
	for ring in rings:
		var t0 := float(ring) / float(rings)
		var t1 := float(ring + 1) / float(rings)
		var y0 := t0 * height
		var y1 := t1 * height
		var squash0 := 1.0 - 0.35 * t0
		var squash1 := 1.0 - 0.35 * t1
		for i in segs:
			var a0 := float(i) / float(segs) * TAU
			var a1 := float(i + 1) / float(segs) * TAU
			var sx0 := width * 0.5 * squash0
			var sx1 := width * 0.5 * squash1
			var toe0a := 1.0 + 0.25 * maxf(0.0, sin(a0))
			var toe0b := 1.0 + 0.25 * maxf(0.0, sin(a1))
			var toe1a := 1.0 + 0.25 * maxf(0.0, sin(a0))
			var toe1b := 1.0 + 0.25 * maxf(0.0, sin(a1))
			var sz0a := length * 0.5 * squash0 * toe0a
			var sz0b := length * 0.5 * squash0 * toe0b
			var sz1a := length * 0.5 * squash1 * toe1a
			var sz1b := length * 0.5 * squash1 * toe1b
			var off := length * 0.12
			var p00 := Vector3(cos(a0 - PI * 0.5) * sx0, y0, sin(a0 - PI * 0.5) * sz0a + off)
			var p10 := Vector3(cos(a1 - PI * 0.5) * sx0, y0, sin(a1 - PI * 0.5) * sz0b + off)
			var p01 := Vector3(cos(a0 - PI * 0.5) * sx1, y1, sin(a0 - PI * 0.5) * sz1a + off)
			var p11 := Vector3(cos(a1 - PI * 0.5) * sx1, y1, sin(a1 - PI * 0.5) * sz1b + off)
			var u0 := float(i) / float(segs)
			var u1 := float(i + 1) / float(segs)
			_tri(st, p00, p10, p11, Vector2(u0, t0), Vector2(u1, t0), Vector2(u1, t1))
			_tri(st, p00, p11, p01, Vector2(u0, t0), Vector2(u1, t1), Vector2(u0, t1))
	st.generate_normals()
	return st.commit()


static func soft_skin_mat(base: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.albedo_texture = _skin_tex(base)
	m.roughness = 0.52
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.55
	return m


static func soft_cloth_mat(base: Color, roughness: float = 0.78) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE
	m.albedo_texture = _fabric_tex(base)
	m.roughness = roughness
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return m


static func soft_hair_mat(base: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.albedo_texture = _hair_tex(base)
	m.roughness = 0.62
	m.metallic = 0.02
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.rim_enabled = true
	m.rim = 0.2
	m.rim_tint = 0.3
	return m


static func _skin_tex(base: Color) -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 41
	n.frequency = 0.14
	for y in size:
		for x in size:
			var v := n.get_noise_2d(x, y) * 0.5 + 0.5
			var c := base.lightened(0.04 * (v - 0.5))
			# Soft freckle hint
			if v > 0.78 and (x + y) % 7 == 0:
				c = c.lerp(Color(0.86, 0.55, 0.42), 0.18)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _fabric_tex(base: Color) -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var weave := 0.0
			if x % 4 == 0 or y % 4 == 0:
				weave = 0.04
			if (x + y) % 8 == 0:
				weave += 0.03
			var fold := sin(float(x) * 0.4) * sin(float(y) * 0.15) * 0.05
			var c := base.darkened(weave).lightened(maxf(0.0, fold))
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _hair_tex(base: Color) -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var strand := sin(float(x) * 1.2 + sin(float(y) * 0.35) * 2.0) * 0.5 + 0.5
			var c := base.lerp(base.lightened(0.18), strand * 0.35)
			if x % 5 == 0:
				c = c.darkened(0.08)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


static func _tri(
	st: SurfaceTool,
	a: Vector3, b: Vector3, c: Vector3,
	uva: Vector2, uvb: Vector2, uvc: Vector2
) -> void:
	st.set_uv(uva)
	st.add_vertex(a)
	st.set_uv(uvb)
	st.add_vertex(b)
	st.set_uv(uvc)
	st.add_vertex(c)
