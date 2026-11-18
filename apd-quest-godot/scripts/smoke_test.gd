extends SceneTree
## Headless smoke: ładuje dane questów i buduje sekwencję / zdanie bez UI.
## Uruchomienie:
##   godot --path apd-quest-godot --headless -s res://scripts/smoke_test.gd


func _initialize() -> void:
	print("[smoke] start")
	var ok := true
	ok = _check_json("res://data/quests.json", "quests") and ok
	ok = _check_json("res://data/word_pool.json", "words") and ok
	ok = _check_json("res://data/sentences.json", "items") and ok
	ok = _check_json("res://data/noise_presets.json", "types") and ok

	var qm_script: GDScript = load("res://scripts/quest/quest_manager.gd") as GDScript
	var qm: Node = qm_script.new()
	root.add_child(qm)
	await process_frame
	var echo = qm.call("get_quest_for_npc", "npc_echo")
	var storm = qm.call("get_quest_for_npc", "npc_storm")
	if echo == null or storm == null:
		push_error("[smoke] brak questów NPC")
		ok = false
	else:
		print("[smoke] echo=%s storm=%s" % [echo.id, storm.id])

	var ws: Node = (load("res://scripts/listening/word_sequence.gd") as GDScript).new()
	root.add_child(ws)
	var seq: PackedStringArray = ws.call("_build_sequence")
	print("[smoke] word_sequence sample: %s" % ", ".join(seq))
	if seq.is_empty():
		ok = false

	var sn: Node = (load("res://scripts/listening/speech_in_noise.gd") as GDScript).new()
	root.add_child(sn)
	var sentence: String = sn.call("_pick_sentence")
	print("[smoke] speech_in_noise sample: %s" % sentence)
	if sentence == "":
		ok = false

	print("[smoke] RESULT=%s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _check_json(path: String, key: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("[smoke] missing %s" % path)
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY or not data.has(key):
		push_error("[smoke] bad json %s key=%s" % [path, key])
		return false
	print("[smoke] ok %s (%s=%s)" % [path, key, data[key].size() if typeof(data[key]) in [TYPE_ARRAY] else typeof(data[key])])
	return true
