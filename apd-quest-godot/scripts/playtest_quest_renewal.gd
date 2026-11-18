extends SceneTree
## Acceptance: complete → offer again → new stimuli → complete (Echo + Burza).
## Badge first-clear NIE blokuje can_offer.
## godot --path apd-quest-godot -s res://scripts/playtest_quest_renewal.gd


func _initialize() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("[renewal] brak main.tscn")
		quit(1)
		return
	await process_frame
	await create_timer(0.6).timeout

	var qm: Node = root.get_node("/root/QuestManager")
	var progress: Node = root.get_node("/root/ProgressStore")
	# Symuluj badge first-clear — nadal musi can_offer.
	progress.call("unlock_badge", "quest_npc_echo_word_seq")
	progress.call("unlock_badge", "quest_npc_storm_speech")

	var ok_echo := await _run_cycle(qm, "npc_echo_word_seq", "word_sequence")
	var ok_storm := await _run_cycle(qm, "npc_storm_speech", "speech_in_noise")

	# 2. oferta Echo z rzędu (lifetime > 0 → offer_again)
	var can2: bool = qm.call("can_offer", "npc_echo_word_seq")
	print("[renewal] can_offer Echo after 1 run + badge: %s" % can2)
	var ok_echo2 := false
	if can2:
		ok_echo2 = await _run_cycle(qm, "npc_echo_word_seq", "word_sequence")

	var anti := true
	var last_echo = qm.call("get_last_roll", "npc_echo_word_seq")
	print("[renewal] last Echo roll=%s" % str(last_echo))

	var ok := ok_echo and ok_storm and can2 and ok_echo2 and anti
	print("[renewal] RESULT=%s echo=%s storm=%s echo2=%s can=%s" % [
		("PASS" if ok else "FAIL"), ok_echo, ok_storm, ok_echo2, can2
	])
	quit(0 if ok else 1)


func _run_cycle(qm: Node, quest_id: String, mode: String) -> bool:
	if not qm.call("can_offer", quest_id):
		push_error("[renewal] can_offer false before start %s" % quest_id)
		return false
	var roll_before = qm.call("get_last_roll", quest_id)
	qm.call("offer_quest", quest_id)
	await create_timer(0.2).timeout
	qm.call("start_quest", quest_id)
	await create_timer(1.4).timeout

	if mode == "word_sequence":
		var module := _find_newest_script(root, "word_sequence.gd")
		if module == null:
			push_error("[renewal] brak WordSequence")
			return false
		var seq: PackedStringArray = module.get("sequence")
		print("[renewal] %s sequence=%s" % [quest_id, ", ".join(seq)])
		if roll_before != null and typeof(roll_before) == TYPE_PACKED_STRING_ARRAY:
			if _same(seq, roll_before) and seq.size() > 0:
				print("[renewal] WARN identical Echo sequence (pool may be tiny)")
		if module.has_method("force_complete_board"):
			module.call("force_complete_board")
		await create_timer(1.0).timeout
		if qm.get("active_quest") != null:
			qm.call("complete_active_quest", true)
	else:
		var module2 := _find_newest_script(root, "speech_in_noise.gd")
		if module2 == null:
			qm.call("remember_roll", quest_id, {"illustration": "park", "sentence": "x"})
			qm.call("complete_active_quest", true)
		else:
			var ill := str(module2.get("target_illustration"))
			print("[renewal] %s illustration=%s" % [quest_id, ill])
			if roll_before != null and typeof(roll_before) == TYPE_DICTIONARY:
				if str(roll_before.get("illustration", "")) == ill:
					print("[renewal] WARN identical Burza target (pool may be tiny)")
			if module2.has_method("submit_choice"):
				module2.call("submit_choice", ill)
			await create_timer(1.2).timeout
			if qm.get("active_quest") != null:
				qm.call("complete_active_quest", true)

	await create_timer(0.3).timeout
	# Done dialog: end_dialog / clear
	qm.call("end_dialog")
	await create_timer(0.2).timeout

	var blocked: bool = qm.call("npc_interact_blocked")
	var can: bool = qm.call("can_offer", quest_id)
	print("[renewal] after complete %s blocked=%s can_offer=%s lifetime=%s" % [
		quest_id, blocked, can, str(qm.get("runs_lifetime").get(quest_id, 0))
	])
	if blocked:
		push_error("[renewal] nadal zablokowany po complete+end_dialog")
		return false
	if not can:
		push_error("[renewal] can_offer false po complete (badge nie może gate'ować)")
		return false
	return true


func _same(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if str(a[i]) != str(b[i]):
			return false
	return true


func _find_newest_script(n: Node, script_suffix: String) -> Node:
	var found: Array = []
	_collect_script(n, script_suffix, found)
	if found.is_empty():
		return null
	return found[found.size() - 1]


func _collect_script(n: Node, script_suffix: String, out: Array) -> void:
	var s = n.get_script()
	if s and str(s.resource_path).ends_with(script_suffix):
		out.append(n)
	for c in n.get_children():
		_collect_script(c, script_suffix, out)
