extends SceneTree
## Zrzut ekranu w fazie odpowiedzi (ikony). APD_QUEST_SCREENSHOT + APD_QUEST_KIND=echo|storm


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(0.9).timeout
	var qm: Node = root.get_node("/root/QuestManager")
	var kind := OS.get_environment("APD_QUEST_KIND")
	if kind == "":
		kind = "echo"
	var qid := "npc_echo_word_seq" if kind == "echo" else "npc_storm_speech"
	qm.call("start_quest", qid)
	await create_timer(0.4).timeout
	var overlay := _find(root, "ListeningOverlay")
	var deadline := Time.get_ticks_msec() + 30000
	var session: Node = null
	var module: Node = null
	while Time.get_ticks_msec() < deadline:
		session = _find_session(overlay)
		if session:
			module = session.get("_module")
			if module and module.get("_presenting") == false:
				var grid := overlay.get_node_or_null("Panel/VBox/Choices")
				if grid and grid.get_child_count() > 0:
					break
		await create_timer(0.25).timeout
	await create_timer(0.35).timeout
	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture] saved %s" % shot)
	# Dokończ poprawnie żeby nie zostawiać locked state
	if module and session:
		if kind == "echo":
			for w in module.get("sequence"):
				session.call("submit_choice", str(w))
				await create_timer(0.15).timeout
		else:
			session.call("submit_choice", str(module.get("target_illustration")))
	await create_timer(1.2).timeout
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
