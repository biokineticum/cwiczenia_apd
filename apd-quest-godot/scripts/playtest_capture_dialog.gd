extends SceneTree
## Zrzut dialogu z walk-zone (zielone/czerwone kółka), bez klikania.
## APD_QUEST_SCREENSHOT=path.png


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(0.8).timeout
	var qm: Node = root.get_node("/root/QuestManager")
	qm.call("offer_quest", "npc_echo_word_seq")
	# Poczekaj aż strefy walk pojawią się po TTS
	var zone: Node = null
	for _i in 40:
		await create_timer(0.35).timeout
		zone = _find_walk_zone(root)
		if zone:
			break
	var player := root.find_child("PlayerGirl", true, false)
	if player and zone:
		player.global_position = (zone as Node3D).global_position + Vector3(0.0, 0.2, 3.2)
		player.set("_yaw", 0.0)
		player.set("_pitch", -0.45)
		if player.has_method("_apply_camera"):
			player.call("_apply_camera")
		await create_timer(0.25).timeout
	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-dialog] saved %s zones=%s" % [shot, zone != null])
	if zone:
		zone.emit_signal("walked_in", zone)
	await create_timer(0.4).timeout
	quit(0)


func _find_walk_zone(n: Node) -> Node:
	var s = n.get_script()
	if s and str(s.resource_path).ends_with("walk_confirm_zone.gd"):
		if str(n.get("kind")) == "accept":
			return n
	for c in n.get_children():
		var f := _find_walk_zone(c)
		if f:
			return f
	return null
