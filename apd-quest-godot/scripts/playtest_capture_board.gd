extends SceneTree
## Zrzut planszy Echo 3D w fazie układania.
## APD_QUEST_SCREENSHOT=path.png


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(0.9).timeout
	var qm: Node = root.get_node("/root/QuestManager")
	qm.call("start_quest", "npc_echo_word_seq")
	var overlay := _find(root, "ListeningOverlay")
	var deadline := Time.get_ticks_msec() + 55000
	var module: Node = null
	while Time.get_ticks_msec() < deadline:
		var session := _find_session(overlay)
		if session:
			module = session.get("_module")
			if module and module.get("_board") != null and module.get("_presenting") == false:
				break
		await create_timer(0.3).timeout
	await create_timer(0.5).timeout
	var player := root.find_child("PlayerGirl", true, false)
	if player and module and module.get("_board"):
		var board: Node3D = module.get("_board")
		# Widok z góry-przodu na sloty 1–4 i rozrzucone symbole
		player.global_position = board.global_position + Vector3(0.0, 0.2, 4.0)
		player.set("_yaw", 0.0)
		player.set("_pitch", -0.48)
		player.call("_apply_camera")
	await create_timer(0.4).timeout
	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-board] saved %s" % shot)
	# Drugi zrzut: ułóż na boardzie synchronicznie (bez czekania na TTS sukcesu).
	var shot2 := OS.get_environment("APD_QUEST_SCREENSHOT_ARRANGED")
	if shot2 == "" and shot != "":
		shot2 = shot.replace(".png", "-arranged.png")
	if module and module.get("_board") and module.get("_board").has_method("force_arrange"):
		var seq: PackedStringArray = module.get("sequence")
		module.get("_board").call("force_arrange", seq)
		# Odłącz sygnał finished żeby capture nie wisiał na dialogu
		if module.has_signal("finished"):
			for c in module.finished.get_connections():
				module.finished.disconnect(c.callable)
	await create_timer(0.35).timeout
	if shot2 != "":
		var img2 := root.get_viewport().get_texture().get_image()
		if img2:
			img2.save_png(shot2)
			print("[capture-board] arranged %s" % shot2)
	quit(0)


func _find(n: Node, name: String) -> Node:
	if n.name == name:
		return n
	for c in n.get_children():
		var f := _find(c, name)
		if f:
			return f
	return null


func _find_session(n: Node) -> Node:
	if n == null:
		return null
	var s = n.get_script()
	if s and str(s.resource_path).ends_with("listening_session.gd"):
		return n
	for c in n.get_children():
		var f := _find_session(c)
		if f:
			return f
	return null
