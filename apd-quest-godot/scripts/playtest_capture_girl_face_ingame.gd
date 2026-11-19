extends SceneTree
## In-game orbit: front + back of girl head in main scene.
## APD_QUEST_SHOT_FRONT / APD_QUEST_SHOT_BACK


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(0.6).timeout

	var player := root.find_child("PlayerGirl", true, false) as Node3D
	if player == null:
		push_error("[capture-girl-face-ingame] PlayerGirl missing")
		quit(1)
		return

	player.global_position = Vector3(0.0, 0.2, 0.0)
	player.set("_yaw", 0.0)
	player.set("_pitch", -0.08)
	if player.has_method("_apply_camera"):
		player.call("_apply_camera")

	var visual: Node3D = player.get_node_or_null("Visual")
	if visual:
		visual.rotation.y = 0.0

	var pivot: Node3D = player.get_node_or_null("CameraPivot")
	var cam: Camera3D = player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if pivot:
		pivot.position = Vector3(0.0, 1.32, 0.0)
	if cam:
		cam.position = Vector3(0.0, 0.02, 1.4)
		cam.fov = 38.0

	await create_timer(0.25).timeout
	_save(OS.get_environment("APD_QUEST_SHOT_FRONT"), "front")

	if visual:
		visual.rotation.y = PI
	await create_timer(0.3).timeout
	_save(OS.get_environment("APD_QUEST_SHOT_BACK"), "back")
	quit(0)


func _save(path: String, label: String) -> void:
	if path == "":
		return
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(path)
		print("[capture-girl-face-ingame] saved %s -> %s" % [label, path])
