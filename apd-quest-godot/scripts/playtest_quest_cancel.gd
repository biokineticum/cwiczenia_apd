extends SceneTree
## PL-37: mid-run cancel (walk red X) for Echo + Burza → active cleared, other quest offerable.
## godot --path apd-quest-godot --resolution 1280x720 -s res://scripts/playtest_quest_cancel.gd


func _initialize() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("[playtest-cancel] nie można wczytać main.tscn: %s" % err)
		quit(1)
		return
	await process_frame
	await create_timer(0.9).timeout
	var qm: Node = root.get_node_or_null("/root/QuestManager")
	if qm == null:
		push_error("[playtest-cancel] brak QuestManager")
		quit(1)
		return
	if not qm.has_method("cancel_active_quest"):
		push_error("[playtest-cancel] brak cancel_active_quest")
		quit(1)
		return

	var ok := true
	ok = await _cancel_echo(qm) and ok
	ok = await _cancel_burza(qm) and ok
	print("[playtest-cancel] RESULT=%s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _cancel_echo(qm: Node) -> bool:
	print("[playtest-cancel] --- Echo cancel ---")
	qm.call("start_quest", "npc_echo_word_seq")
	var overlay := _find(root, "ListeningOverlay")
	var deadline := Time.get_ticks_msec() + 45000
	var module: Node = null
	while Time.get_ticks_msec() < deadline:
		var session := _find_session(overlay)
		if session:
			module = session.get("_module")
			if module != null:
				break
		await create_timer(0.2).timeout
	if module == null:
		push_error("[playtest-cancel] Echo: brak modułu")
		return false

	# Poczekaj na early cancel albo board cancel pad.
	var pad: Node = null
	while Time.get_ticks_msec() < deadline:
		pad = root.find_child("EchoEarlyCancelPad", true, false)
		if pad == null:
			var board = module.get("_board")
			if board:
				pad = board.get_node_or_null("EchoCancelPad")
		if pad != null:
			break
		await create_timer(0.25).timeout
	if pad == null:
		push_error("[playtest-cancel] Echo: brak cancel pad")
		return false
	print("[playtest-cancel] Echo pad=%s" % pad.name)

	if not module.has_method("cancel_run"):
		push_error("[playtest-cancel] Echo: brak cancel_run")
		return false
	module.call("cancel_run")
	await create_timer(0.5).timeout

	var active = qm.get("active_quest")
	var offering := str(qm.get("offering_quest_id"))
	var locked := bool(qm.get("movement_locked"))
	var lifetime := int(qm.get("runs_lifetime").get("npc_echo_word_seq", 0))
	var can_storm := bool(qm.call("can_offer", "npc_storm_speech"))
	print("[playtest-cancel] Echo after: active=%s offering=%s locked=%s lifetime=%d can_storm=%s" % [
		active != null, offering, locked, lifetime, can_storm
	])
	if active != null or offering != "" or locked or lifetime != 0 or not can_storm:
		push_error("[playtest-cancel] Echo cancel state bad")
		return false
	# Early / board pads cleared.
	if root.find_child("EchoEarlyCancelPad", true, false) != null:
		push_error("[playtest-cancel] Echo early pad still alive")
		return false
	if root.find_child("EchoBoard", true, false) != null:
		push_error("[playtest-cancel] EchoBoard still alive")
		return false
	return true


func _cancel_burza(qm: Node) -> bool:
	print("[playtest-cancel] --- Burza cancel ---")
	qm.call("start_quest", "npc_storm_speech")
	var overlay := _find(root, "ListeningOverlay")
	var deadline := Time.get_ticks_msec() + 45000
	var module: Node = null
	while Time.get_ticks_msec() < deadline:
		var session := _find_session(overlay)
		if session:
			module = session.get("_module")
			if module != null:
				break
		await create_timer(0.2).timeout
	if module == null:
		push_error("[playtest-cancel] Burza: brak modułu")
		return false

	var pad: Node = null
	while Time.get_ticks_msec() < deadline:
		pad = root.find_child("BurzaCancelPad", true, false)
		if pad != null:
			break
		await create_timer(0.25).timeout
	if pad == null:
		push_error("[playtest-cancel] Burza: brak cancel pad")
		return false
	print("[playtest-cancel] Burza pad=%s" % pad.name)

	if not module.has_method("cancel_run"):
		push_error("[playtest-cancel] Burza: brak cancel_run")
		return false
	module.call("cancel_run")
	await create_timer(0.5).timeout

	var active = qm.get("active_quest")
	var offering := str(qm.get("offering_quest_id"))
	var locked := bool(qm.get("movement_locked"))
	var lifetime := int(qm.get("runs_lifetime").get("npc_storm_speech", 0))
	var can_echo := bool(qm.call("can_offer", "npc_echo_word_seq"))
	print("[playtest-cancel] Burza after: active=%s offering=%s locked=%s lifetime=%d can_echo=%s" % [
		active != null, offering, locked, lifetime, can_echo
	])
	if active != null or offering != "" or locked or lifetime != 0 or not can_echo:
		push_error("[playtest-cancel] Burza cancel state bad")
		return false
	if root.find_child("BurzaCancelPad", true, false) != null:
		push_error("[playtest-cancel] Burza cancel pad still alive")
		return false
	return true


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
