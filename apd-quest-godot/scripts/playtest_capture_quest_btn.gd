extends SceneTree
## Zrzut: zielone play (walk_confirm) PRZED meshem NPC — dowód depth fix.
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

	var player := root.find_child("PlayerGirl", true, false)
	var npc := _find_named(root, "NpcEcho")
	if npc == null:
		npc = _find_named(root, "npc_echo")
	if npc == null:
		# Fallback: pierwszy NPC w grupie / CharacterBody poza graczem.
		npc = _find_npc_fallback(root)

	if player == null:
		push_error("[capture-quest-btn] brak PlayerGirl")
		quit(1)
		return

	var npos := zone.global_position
	if npc:
		npos = (npc as Node3D).global_position
		# Pad tuż przed NPC (między kamerą a postacią).
		zone.global_position = npos + Vector3(0.0, 0.0, 0.85)
	# Kamera: patrzy w NPC; zielone play na środku kadru, postać zaraz za ikoną.
	player.global_position = zone.global_position + Vector3(0.0, 0.4, 2.2)
	player.set("_yaw", 0.0)
	player.set("_pitch", -0.28)
	if player.has_method("_apply_camera"):
		player.call("_apply_camera")
	await create_timer(0.2).timeout
	# Jeszcze jedna klatka process — bias kamery na Sprite3D.
	await process_frame
	await process_frame
	await create_timer(0.25).timeout

	var spr := _find_sprite3d(zone)
	var ok_flags := false
	if spr:
		ok_flags = bool(spr.no_depth_test) and int(spr.render_priority) >= 1
		print(
			"[capture-quest-btn] sprite no_depth_test=%s render_priority=%s sorting_offset=%.1f y=%.2f"
			% [spr.no_depth_test, spr.render_priority, spr.sorting_offset, spr.position.y]
		)
	else:
		print("[capture-quest-btn] WARN: brak Sprite3D w strefie")

	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-quest-btn] saved %s" % shot)

	var ok: bool = zone != null and ok_flags
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


func _find_named(n: Node, want: String) -> Node:
	if n.name == want:
		return n
	for c in n.get_children():
		var f := _find_named(c, want)
		if f:
			return f
	return null


func _find_npc_fallback(n: Node) -> Node:
	if n.is_in_group("npc"):
		return n
	for c in n.get_children():
		var f := _find_npc_fallback(c)
		if f:
			return f
	return null
