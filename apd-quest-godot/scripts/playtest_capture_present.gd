extends SceneTree
## Zrzut fazy present — EarFlash MUSI być ukryty; TTS działa bez abstrakcyjnego ucha.
## APD_QUEST_SCREENSHOT=path.png


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(0.9).timeout
	var qm: Node = root.get_node_or_null("/root/QuestManager")
	if qm == null:
		push_error("[capture-present] brak QuestManager")
		quit(1)
		return
	qm.call("start_quest", "npc_echo_word_seq")
	var overlay := _find(root, "ListeningOverlay")
	var deadline := Time.get_ticks_msec() + 25000
	var saw_present := false
	while Time.get_ticks_msec() < deadline:
		if overlay and overlay.visible:
			saw_present = true
			break
		await create_timer(0.2).timeout
	await create_timer(0.55).timeout
	var ear = overlay.get_node_or_null("Panel/VBox/EarFlash") if overlay else null
	var panel = overlay.get_node_or_null("Panel") if overlay else null
	var controls = overlay.get_node_or_null("Panel/VBox/Controls") if overlay else null
	var parent_center = overlay.get_node_or_null("Panel/VBox/Controls/Parent") if overlay else null
	var corner = overlay.get_node_or_null("CornerControls") if overlay else null
	var ear_vis: bool = ear != null and ear.visible
	var panel_vis: bool = panel != null and panel.visible
	var controls_vis: bool = controls != null and controls.visible
	var parent_center_vis: bool = parent_center != null and parent_center.visible
	var corner_vis: bool = corner != null and corner.visible
	print(
		"[capture-present] saw=%s ear=%s panel=%s controls=%s parent_center=%s corner=%s"
		% [saw_present, ear_vis, panel_vis, controls_vis, parent_center_vis, corner_vis]
	)
	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-present] saved %s" % shot)
	# PASS: present widoczny, EarFlash ukryty, brak centralnych kontrolek.
	var ok: bool = saw_present and (not ear_vis) and (not controls_vis) and (not parent_center_vis)
	print("[capture-present] RESULT=%s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _find(n: Node, name: String) -> Node:
	if n.name == name:
		return n
	for c in n.get_children():
		var f := _find(c, name)
		if f:
			return f
	return null
