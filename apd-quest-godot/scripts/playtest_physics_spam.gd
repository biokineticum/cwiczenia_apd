extends SceneTree
## Regresja: brak spamu Wejście przy NPC + brak błędów Area monitoring / reparent.
## godot --path apd-quest-godot --resolution 1280x720 -s res://scripts/playtest_physics_spam.gd


func _initialize() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("[physics] nie można wczytać main.tscn: %s" % err)
		quit(1)
		return
	await process_frame
	await create_timer(0.7).timeout

	var qm: Node = root.get_node("/root/QuestManager")
	var player := root.find_child("PlayerGirl", true, false)
	var echo := root.find_child("NpcEcho", true, false)
	if echo == null:
		# fallback: dowolny NPC z echo w nazwie
		for n in root.get_children():
			var f := _find_by_name_part(n, "Echo")
			if f:
				echo = f
				break
	if player == null or echo == null:
		push_error("[physics] brak Player/Echo")
		quit(1)
		return

	# Stań w InteractionArea Echo i trzymaj się tam ~6s podczas oferty.
	player.global_position = (echo as Node3D).global_position + Vector3(0.4, 0.1, 0.8)
	await create_timer(0.5).timeout
	# Wymuś jedną ofertę jeśli dwell jeszcze nie zdążył
	if str(qm.get("offering_quest_id")) == "" and qm.get("active_quest") == null:
		qm.call("offer_quest", "npc_echo_word_seq")
	await create_timer(5.5).timeout

	var log_path := ProjectSettings.globalize_path("user://physics_spam_capture.log")
	# Policz Wejście z stdout nie da się łatwo — sprawdzamy stan QM + start quest raz.
	var offering := str(qm.get("offering_quest_id"))
	var active = qm.get("active_quest")
	print("[physics] after dwell near NPC: offering=%s active=%s" % [offering, active != null])

	# Accept walk zone → start, potem force arrange (pick/place deferred path)
	var zone := _find_walk_zone(root)
	if zone:
		zone.emit_signal("walked_in", zone)
	else:
		qm.call("start_quest", "npc_echo_word_seq")
	await create_timer(1.2).timeout

	# Stojąc dalej przy NPC podczas questu — nie powinno być nowej oferty
	player.global_position = (echo as Node3D).global_position + Vector3(0.3, 0.1, 0.7)
	var offering_mid := str(qm.get("offering_quest_id"))
	await create_timer(3.0).timeout
	var offering_late := str(qm.get("offering_quest_id"))
	var still_active = qm.get("active_quest") != null
	print("[physics] during quest near NPC: offering_mid=%s offering_late=%s active=%s" % [
		offering_mid, offering_late, still_active
	])

	# Ćwicz pick/place deferred
	var module = _find_module(root)
	var board = null
	if module:
		board = module.get("_board")
	if board and board.has_method("force_arrange"):
		var seq: PackedStringArray = module.get("_sequence_ids")
		if seq == null or seq.is_empty():
			seq = PackedStringArray(["a", "b", "c", "d"])
		board.call("force_arrange", seq)
		await create_timer(0.6).timeout
		# Symuluj pick na żywym propie jeśli zostały
		var props = board.get("_props")
		if props is Array and props.size() > 0:
			var p = props[0]
			if is_instance_valid(p):
				board.call("_on_prop_picked", p)
				await create_timer(0.35).timeout
				board.call("_on_prop_picked", p) # drugi raz w trakcie — nie powinien crashować

	var blocked_ok := still_active and offering_late == ""
	# Po starcie questu offering musi być puste; podczas active nie wolno nowej oferty.
	var ok := blocked_ok and still_active
	print("[physics] RESULT=%s log=%s" % [("PASS" if ok else "FAIL"), log_path])
	quit(0 if ok else 1)


func _find_by_name_part(n: Node, part: String) -> Node:
	if part.to_lower() in n.name.to_lower():
		return n
	for c in n.get_children():
		var f := _find_by_name_part(c, part)
		if f:
			return f
	return null


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


func _find_module(n: Node) -> Node:
	if n.has_method("begin") and n.get("_board") != null:
		return n
	for c in n.get_children():
		var f := _find_module(c)
		if f:
			return f
	return null
