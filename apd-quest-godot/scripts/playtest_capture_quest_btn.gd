extends SceneTree
## Chase-cam: child player approaching Echo; green play BESIDE her (same depth), face visible.


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(0.8).timeout
	var qm: Node = root.get_node_or_null("/root/QuestManager")
	if qm == null:
		push_error("[capture-quest-btn] brak QuestManager")
		quit(1)
		return
	qm.call("offer_quest", "npc_echo_word_seq")

	var zone: Node3D = null
	for _i in 55:
		await create_timer(0.3).timeout
		zone = _find_walk_zone(root)
		if zone:
			break
	if zone == null:
		push_error("[capture-quest-btn] brak walk_confirm accept zone")
		quit(1)
		return

	var player := root.find_child("PlayerGirl", true, false) as Node3D
	var npc := root.find_child("NpcEcho", true, false) as Node3D
	if player == null or npc == null:
		push_error("[capture-quest-btn] brak PlayerGirl / NpcEcho")
		quit(1)
		return

	# Podejście od +Z: Echo (lewo) i play (prawo od niej) na tej samej głębokości kadru.
	var look_at := Vector3(
		(npc.global_position.x + zone.global_position.x) * 0.5,
		1.05,
		npc.global_position.z
	)
	player.global_position = Vector3(look_at.x + 0.6, 0.35, npc.global_position.z + 7.2)
	var look := look_at - player.global_position
	player.set("_yaw", atan2(-look.x, -look.z))
	player.set("_pitch", -0.06)
	if player.has_method("_apply_camera"):
		player.call("_apply_camera")

	var vis := player.get_node_or_null("Visual")
	if vis:
		vis.visible = true
		vis.rotation.y = atan2(look.x, look.z)

	var nvis := npc.get_node_or_null("Visual") as Node3D
	if nvis:
		var to_cam := player.global_position - npc.global_position
		nvis.rotation.y = atan2(to_cam.x, to_cam.z)

	var cam := player.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if cam:
		cam.current = true
		cam.fov = 48.0
		cam.position = Vector3(0.35, 1.05, 4.4)

	await process_frame
	await create_timer(0.5).timeout

	var spr := _find_sprite3d(zone)
	var ok_depth := spr != null and not bool(spr.no_depth_test)
	var lateral := Vector2(
		zone.global_position.x - npc.global_position.x,
		zone.global_position.z - npc.global_position.z
	).length()
	print("[capture-quest-btn] lateral=%.2fm zone=%s npc=%s" % [
		lateral, zone.global_position, npc.global_position
	])
	var storm := root.find_child("NpcStorm", true, false) as Node3D
	var sep := npc.global_position.distance_to(storm.global_position) if storm else 0.0
	print("[capture-quest-btn] echo_storm_sep=%.1fm" % sep)

	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-quest-btn] saved %s" % shot)

	var ok := ok_depth and lateral >= 2.5 and lateral <= 4.5 and sep >= 30.0
	print("[capture-quest-btn] RESULT=%s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _find_walk_zone(n: Node) -> Node3D:
	var s = n.get_script()
	if s and str(s.resource_path).ends_with("walk_confirm_zone.gd"):
		if str(n.get("kind")) == "accept":
			return n as Node3D
	for c in n.get_children():
		var f := _find_walk_zone(c)
		if f:
			return f
	return null


func _find_sprite3d(n: Node) -> Sprite3D:
	if n is Sprite3D:
		return n as Sprite3D
	for c in n.get_children():
		var f := _find_sprite3d(c)
		if f:
			return f
	return null
