extends SceneTree
## Playtest Echo (ikony) → punkty.
## godot --path apd-quest-godot --resolution 1280x720 -s res://scripts/playtest_slice.gd


func _initialize() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("[playtest] nie można wczytać main.tscn: %s" % err)
		quit(1)
		return
	await process_frame
	await process_frame
	await create_timer(1.0).timeout

	var quest_manager: Node = root.get_node_or_null("/root/QuestManager")
	var progress: Node = root.get_node_or_null("/root/ProgressStore")
	if quest_manager == null or progress == null:
		push_error("[playtest] brak autoloadów")
		quit(1)
		return

	var points_before: int = int(progress.get("points"))
	print("[playtest] start quest Echo (5yo icons)")
	quest_manager.call("start_quest", "npc_echo_word_seq")
	await create_timer(0.6).timeout

	var overlay := _find_node_by_name(root, "ListeningOverlay")
	if overlay == null:
		push_error("[playtest] brak ListeningOverlay")
		quit(1)
		return

	var deadline := Time.get_ticks_msec() + 35000
	var module: Node = null
	var session: Node = null
	while Time.get_ticks_msec() < deadline:
		session = _find_listening_session(overlay)
		if session != null:
			module = session.get("_module")
			if module != null and module.get("_presenting") == false:
				var seq: PackedStringArray = module.get("sequence")
				if seq.size() >= 4:
					break
		await create_timer(0.25).timeout

	if module == null:
		push_error("[playtest] timeout — brak modułu")
		quit(1)
		return

	while module.get("_presenting") == true and Time.get_ticks_msec() < deadline:
		await create_timer(0.2).timeout

	var seq2: PackedStringArray = module.get("sequence")
	print("[playtest] sequence ids=%s" % ", ".join(seq2))
	for w in seq2:
		session.call("submit_choice", str(w))
		await create_timer(0.25).timeout

	await create_timer(2.5).timeout
	var points: int = int(progress.get("points"))
	print("[playtest] points %d → %d" % [points_before, points])
	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[playtest] screenshot %s" % shot)
	var ok := points > points_before
	print("[playtest] RESULT=%s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _find_node_by_name(n: Node, target: String) -> Node:
	if n.name == target:
		return n
	for c in n.get_children():
		var found := _find_node_by_name(c, target)
		if found:
			return found
	return null


func _find_listening_session(n: Node) -> Node:
	var script_res = n.get_script()
	if script_res and str(script_res.resource_path).get_file() == "listening_session.gd":
		return n
	for c in n.get_children():
		var found := _find_listening_session(c)
		if found:
			return found
	return null
