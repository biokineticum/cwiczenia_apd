extends SceneTree
## PL-30: wrong place → walk reset pad → clear → correct arrange.
## godot --path apd-quest-godot --resolution 1280x720 -s res://scripts/playtest_echo_reset.gd
## Optional: APD_QUEST_SCREENSHOT / APD_QUEST_SCREENSHOT_RESET / APD_QUEST_SCREENSHOT_OK


func _initialize() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("[playtest-reset] nie można wczytać main.tscn: %s" % err)
		quit(1)
		return
	await process_frame
	await create_timer(0.9).timeout
	var qm: Node = root.get_node_or_null("/root/QuestManager")
	if qm == null:
		push_error("[playtest-reset] brak QuestManager")
		quit(1)
		return
	qm.call("start_quest", "npc_echo_word_seq")
	var overlay := _find(root, "ListeningOverlay")
	var deadline := Time.get_ticks_msec() + 60000
	var module: Node = null
	var board: Node3D = null
	while Time.get_ticks_msec() < deadline:
		var session := _find_session(overlay)
		if session:
			module = session.get("_module")
			if module and module.get("_board") != null and module.get("_presenting") == false:
				board = module.get("_board")
				break
		await create_timer(0.3).timeout
	if board == null:
		push_error("[playtest-reset] timeout — brak EchoBoard")
		quit(1)
		return
	print("[playtest-reset] board ok, reset pad=%s" % str(board.get_node_or_null("EchoResetPad") != null))
	await create_timer(0.35).timeout

	var player := root.find_child("PlayerGirl", true, false) as Node3D
	if player:
		player.global_position = board.global_position + Vector3(0.0, 0.2, 5.8)
		player.set("_yaw", 0.0)
		player.set("_pitch", -0.5)
		player.call("_apply_camera")

	# 1) Wrong / partial placement (first two sequence ids swapped into slots 0–1).
	var seq: PackedStringArray = module.get("sequence")
	if seq.size() < 2:
		push_error("[playtest-reset] sekwencja za krótka")
		quit(1)
		return
	var wrong := PackedStringArray()
	wrong.append(str(seq[1]))
	wrong.append(str(seq[0]))
	if board.arrangement_complete.is_connected(module._on_board_complete):
		board.arrangement_complete.disconnect(module._on_board_complete)
	board.call("force_arrange", wrong)
	await create_timer(0.35).timeout
	var placed_before: PackedStringArray = board.call("get_placed_ids")
	print("[playtest-reset] after wrong place: %s" % ", ".join(placed_before))
	var shot_wrong := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot_wrong != "":
		_save_shot(shot_wrong, "wrong")

	# 2) Walk-style reset (same path as orange pad).
	if not board.has_method("reset_board"):
		push_error("[playtest-reset] brak reset_board")
		quit(1)
		return
	board.call("reset_board")
	await create_timer(0.35).timeout
	var placed_after: PackedStringArray = board.call("get_placed_ids")
	var cleared := true
	for id in placed_after:
		if str(id) != "":
			cleared = false
			break
	var progress := bool(board.call("has_attempt_progress"))
	print("[playtest-reset] after reset ids=%s progress=%s" % [", ".join(placed_after), progress])
	var shot_reset := OS.get_environment("APD_QUEST_SCREENSHOT_RESET")
	if shot_reset == "" and shot_wrong != "":
		shot_reset = shot_wrong.replace(".png", "-reset.png")
	if shot_reset != "":
		_save_shot(shot_reset, "reset")

	# 3) Correct arrange again.
	board.call("force_arrange", seq)
	await create_timer(0.35).timeout
	var placed_ok: PackedStringArray = board.call("get_placed_ids")
	var ok_order := placed_ok.size() == seq.size()
	if ok_order:
		for i in seq.size():
			if str(placed_ok[i]) != str(seq[i]):
				ok_order = false
				break
	print("[playtest-reset] after correct: %s" % ", ".join(placed_ok))
	var shot_ok := OS.get_environment("APD_QUEST_SCREENSHOT_OK")
	if shot_ok == "" and shot_wrong != "":
		shot_ok = shot_wrong.replace(".png", "-ok.png")
	if shot_ok != "":
		_save_shot(shot_ok, "ok")

	var pad_ok := board.get_node_or_null("EchoResetPad") != null
	var all_ok := cleared and (not progress) and ok_order and pad_ok
	print("[playtest-reset] RESULT=%s cleared=%s pad=%s order=%s" % [
		"PASS" if all_ok else "FAIL", cleared, pad_ok, ok_order
	])
	quit(0 if all_ok else 1)


func _save_shot(path: String, tag: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(path)
		print("[playtest-reset] screenshot %s → %s" % [tag, path])


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
