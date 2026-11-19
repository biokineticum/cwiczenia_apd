extends SceneTree
## Isolated girl head: front + back close-ups (no world clutter).
## APD_QUEST_SHOT_FRONT=path.png APD_QUEST_SHOT_BACK=path.png


func _initialize() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.15
	light.rotation_degrees = Vector3(-35, 40, 0)
	world.add_child(light)

	var fill := OmniLight3D.new()
	fill.light_energy = 0.55
	fill.omni_range = 8.0
	fill.position = Vector3(-1.2, 1.6, 2.0)
	world.add_child(fill)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.72, 0.55)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.7)
	e.ambient_light_energy = 0.55
	env.environment = e
	world.add_child(env)

	var builder = load("res://scripts/art/stylized_character_builder.gd")
	var visual: Node3D = builder.build(builder.Style.GIRL)
	visual.name = "GirlVisual"
	visual.position = Vector3(0, 0, 0)
	world.add_child(visual)

	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 35.0
	# Eye-level, looking at head center (~y 1.32); avoid look_at before fully in tree
	var cam_pos := Vector3(0.0, 1.32, 1.35)
	var head := Vector3(0.0, 1.32, 0.0)
	cam.transform = Transform3D(Basis.looking_at(head - cam_pos, Vector3.UP), cam_pos)
	world.add_child(cam)

	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	_save_shot(OS.get_environment("APD_QUEST_SHOT_FRONT"), "front")

	# 180° — occiput toward camera; face discs ( +Z ) must not appear
	visual.rotation.y = PI
	await process_frame
	await create_timer(0.3).timeout
	_save_shot(OS.get_environment("APD_QUEST_SHOT_BACK"), "back")

	quit(0)


func _save_shot(path: String, label: String) -> void:
	if path == "":
		print("[capture-girl-face] skip %s (no path)" % label)
		return
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("[capture-girl-face] no image for %s" % label)
		return
	img.save_png(path)
	print("[capture-girl-face] saved %s -> %s size=%sx%s" % [label, path, img.get_width(), img.get_height()])
