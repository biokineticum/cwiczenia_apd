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
		# Widok z góry na dwie linie (symbole przód, sloty tył)
		player.global_position = board.global_position + Vector3(0.0, 0.2, 6.5)
		player.set("_yaw", 0.0)
		player.set("_pitch", -0.55)
		player.call("_apply_camera")
	await create_timer(0.4).timeout
	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-board] saved %s" % shot)
	# Drugi zrzut bez uruchamiania evaluate/TTS (odłącz complete).
	var shot2 := OS.get_environment("APD_QUEST_SCREENSHOT_ARRANGED")
	if shot2 == "" and shot != "":
		shot2 = shot.replace(".png", "-arranged.png")
	var board = module.get("_board") if module else null
	if board and board.has_method("force_arrange"):
		if board.arrangement_complete.is_connected(module._on_board_complete):
			board.arrangement_complete.disconnect(module._on_board_complete)
		if board.arrangement_changed.is_connected(module._on_board_changed):
			board.arrangement_changed.disconnect(module._on_board_changed)
		board.call("force_arrange", module.get("sequence"))
	await create_timer(0.3).timeout
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
