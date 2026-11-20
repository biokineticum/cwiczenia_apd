extends SceneTree
## Wide/elevated proof: BOTH Echo and Burza + pads in one frame (distance readable).
## APD_QUEST_SCREENSHOT=path.png


const WalkZone = preload("res://scripts/world/walk_confirm_zone.gd")


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(1.0).timeout

	var echo := root.find_child("NpcEcho", true, false) as Node3D
	var storm := root.find_child("NpcStorm", true, false) as Node3D
	var player := root.find_child("PlayerGirl", true, false) as Node3D
	var scene: Node = current_scene
	if echo == null or storm == null or player == null or scene == null:
		push_error("[capture-layout-wide] brak NpcEcho / NpcStorm / PlayerGirl / scene")
		quit(1)
		return

	var sep := echo.global_position.distance_to(storm.global_position)
	print("[capture-layout-wide] echo=%s storm=%s sep=%.1fm" % [
		echo.global_position, storm.global_position, sep
	])

	# Padd'y obu questów naraz — dwie osobne polanki.
	_spawn_pads_for(scene, echo, Vector3.RIGHT)
	_spawn_pads_for(scene, storm, Vector3.LEFT)

	# Graczka na ścieżce między NPC (widoczna w wide).
	player.global_position = Vector3(0.0, 0.25, 7.0)
	var pvis := player.get_node_or_null("Visual")
	if pvis:
		pvis.visible = true
		pvis.rotation.y = 0.0

	var mid := (echo.global_position + storm.global_position) * 0.5
	mid.y = 1.2
	var cam := Camera3D.new()
	cam.name = "WideProofCam"
	cam.fov = 72.0
	cam.far = 220.0
	scene.add_child(cam)
	cam.global_position = Vector3(mid.x, 24.0, mid.z + 30.0)
	cam.look_at(mid, Vector3.UP)
	cam.current = true

	await process_frame
	await process_frame
	await create_timer(0.5).timeout

	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-layout-wide] saved %s" % shot)

	var ok := sep >= 30.0
	print("[capture-layout-wide] RESULT=%s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _spawn_pads_for(parent: Node, npc: Node3D, inward: Vector3) -> void:
	const INWARD := 3.2
	const ALONG_GO := 0.0
	const ALONG_LEAVE := -2.8
	var anchor := npc.global_position
	var go := WalkZone.new()
	parent.add_child(go)
	var go_pos := anchor + inward * INWARD + Vector3(0, 0, ALONG_GO)
	go_pos.y = anchor.y + 0.02
	go.setup("accept", "play", go_pos, Color(0.35, 0.78, 0.45))
	var leave := WalkZone.new()
	parent.add_child(leave)
	var leave_pos := anchor + inward * INWARD + Vector3(0, 0, ALONG_LEAVE)
	leave_pos.y = anchor.y + 0.02
	leave.setup("dismiss", "close", leave_pos, Color(0.75, 0.45, 0.4))
