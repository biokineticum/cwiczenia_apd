extends SceneTree
## Zrzut: zielone play OBOK NPC — twarz i przycisk czytelne obok siebie.
## APD_QUEST_SCREENSHOT=path.png


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
	for _i in 50:
		await create_timer(0.35).timeout
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

	var mid := (zone.global_position + npc.global_position) * 0.5
	var across := zone.global_position - npc.global_position
	across.y = 0.0
	if across.length_squared() < 0.01:
		across = Vector3.RIGHT
	else:
		across = across.normalized()
	# Kamera prostopadle do osi NPC↔pad → w kadrze stoją OBOK siebie, nie jeden za drugim.
	var back := Vector3(-across.z, 0.0, across.x)
	if back.dot(Vector3(0, 0, 1)) < 0.0:
		back = -back
	player.global_position = mid + back * 4.6 + Vector3(0.0, 0.4, 0.0)
	var look := mid - player.global_position
	# pivot yaw: kamera patrzy −Z lokalnie → yaw = atan2(-look.x, -look.z)
	player.set("_yaw", atan2(-look.x, -look.z))
	player.set("_pitch", -0.12)
	if player.has_method("_apply_camera"):
		player.call("_apply_camera")
	var vis := player.get_node_or_null("Visual")
	if vis:
		vis.visible = false
	await process_frame
	await create_timer(0.4).timeout

	var spr := _find_sprite3d(zone)
	var ok_flags := false
	if spr:
		ok_flags = not bool(spr.no_depth_test)
		print(
			"[capture-quest-btn] sprite no_depth_test=%s render_priority=%s y=%.2f"
			% [spr.no_depth_test, spr.render_priority, spr.position.y]
		)
	var lateral := Vector2(
		zone.global_position.x - npc.global_position.x,
		zone.global_position.z - npc.global_position.z
	).length()
	print("[capture-quest-btn] pad_lateral_from_npc=%.2fm" % lateral)

	var storm := root.find_child("NpcStorm", true, false) as Node3D
	var npc_sep := 0.0
	if storm:
		npc_sep = npc.global_position.distance_to(storm.global_position)
		print("[capture-quest-btn] echo_storm_sep=%.1fm" % npc_sep)

	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-quest-btn] saved %s" % shot)

	var ok: bool = zone != null and ok_flags and lateral >= 2.5 and npc_sep >= 12.0
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
