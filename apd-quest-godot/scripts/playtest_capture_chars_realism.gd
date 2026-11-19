extends SceneTree
## Full-body character realism shots: girl front/back + Echo NPC.
## Env:
##   APD_QUEST_SHOT_FRONT / APD_QUEST_SHOT_BACK / APD_QUEST_SHOT_NPC


func _initialize() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.25
	light.shadow_enabled = true
	light.rotation_degrees = Vector3(-42, 35, 0)
	world.add_child(light)

	var fill := OmniLight3D.new()
	fill.light_energy = 0.65
	fill.omni_range = 10.0
	fill.position = Vector3(-1.4, 1.8, 2.2)
	world.add_child(fill)

	var rim := OmniLight3D.new()
	rim.light_energy = 0.4
	rim.light_color = Color(1.0, 0.92, 0.85)
	rim.omni_range = 8.0
	rim.position = Vector3(1.2, 1.5, -1.5)
	world.add_child(rim)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.52, 0.68, 0.58)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.8, 0.74)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.05
	env.environment = e
	world.add_child(env)

	# Soft ground plane for scale
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.35, 0.52, 0.32)
	ground.material_override = gm
	ground.position = Vector3(0, 0, 0)
	world.add_child(ground)

	var builder = load("res://scripts/art/stylized_character_builder.gd")
	var girl: Node3D = builder.build(builder.Style.GIRL)
	girl.name = "GirlVisual"
	girl.position = Vector3(0, 0, 0)
	world.add_child(girl)

	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 38.0
	world.add_child(cam)

	await process_frame
	await process_frame

	# Front (+Z face toward camera) — imported child ~1.45 m after scale
	_aim_fullbody(cam, Vector3(0.0, 0.9, 2.9), Vector3(0.0, 0.85, 0.0))
	await process_frame
	await create_timer(0.35).timeout
	_save_shot(OS.get_environment("APD_QUEST_SHOT_FRONT"), "front")

	# Back — hair/backpack only; no face
	girl.rotation.y = PI
	await process_frame
	await create_timer(0.3).timeout
	_save_shot(OS.get_environment("APD_QUEST_SHOT_BACK"), "back")

	# Girl 3/4 + Echo NPC (imported Quaternius Woman in Dress, scaled down)
	girl.rotation.y = -0.35
	girl.position = Vector3(-0.95, 0, 0)
	var echo: Node3D = builder.build(builder.Style.ECHO)
	echo.name = "EchoVisual"
	echo.position = Vector3(0.95, 0, 0)
	echo.rotation.y = 0.15
	world.add_child(echo)
	_aim_fullbody(cam, Vector3(0.0, 0.95, 3.4), Vector3(0.0, 0.85, 0.0))
	await process_frame
	await create_timer(0.35).timeout
	_save_shot(OS.get_environment("APD_QUEST_SHOT_NPC"), "npc")

	quit(0)


func _aim_fullbody(cam: Camera3D, cam_pos: Vector3, look: Vector3) -> void:
	cam.transform = Transform3D(Basis.looking_at(look - cam_pos, Vector3.UP), cam_pos)


func _save_shot(path: String, label: String) -> void:
	if path == "":
		print("[capture-chars] skip %s (no path)" % label)
		return
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("[capture-chars] no image for %s" % label)
		return
	img.save_png(path)
	print("[capture-chars] saved %s -> %s size=%sx%s" % [label, path, img.get_width(), img.get_height()])
