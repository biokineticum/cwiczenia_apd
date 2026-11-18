extends SceneTree
## Headless smoke for 5yo data + sequence builder.
## godot --path apd-quest-godot --headless -s res://scripts/smoke_test.gd

const IconFactory = preload("res://scripts/art/icon_factory.gd")


func _initialize() -> void:
	print("[smoke] start")
	var ok := true
	ok = _check_json("res://data/quests.json", "quests") and ok
	ok = _check_word_pool() and ok
	ok = _check_sentences() and ok
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
	ws.call("_load_pool")
	ws.call("_build_sequence")
	var seq: PackedStringArray = ws.get("sequence")
	print("[smoke] word_sequence sample ids: %s (n=%d)" % [", ".join(seq), seq.size()])
	if seq.is_empty() or seq.size() < 2 or seq.size() > 3:
		push_error("[smoke] zła długość sekwencji (oczekiwane 2–3)")
		ok = false

	var sn: Node = (load("res://scripts/listening/speech_in_noise.gd") as GDScript).new()
	root.add_child(sn)
	sn.call("_pick_item")
	var ill := str(sn.get("target_illustration"))
	var sentence := str(sn.get("target_sentence"))
	print("[smoke] speech_in_noise sample: %s → %s" % [sentence, ill])
	if ill == "" or sentence == "":
		ok = false

	# Icon factory
	var tex = IconFactory.get_icon("dog")
	if tex == null:
		ok = false
	else:
		print("[smoke] IconFactory dog ok")

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
	print("[smoke] ok %s" % path)
	return true


func _check_word_pool() -> bool:
	var path := "res://data/word_pool.json"
	if not FileAccess.file_exists(path):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if int(data.get("default_length_min", 99)) > 2:
		push_error("[smoke] length_min powinno być 2")
		return false
	var words = data.get("words", [])
	if words.is_empty() or typeof(words[0]) != TYPE_DICTIONARY:
		push_error("[smoke] words muszą być obiektami z icon")
		return false
	if not words[0].has("icon"):
		return false
	print("[smoke] ok word_pool (%d słów)" % words.size())
	return true


func _check_sentences() -> bool:
	var path := "res://data/sentences.json"
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var items = data.get("items", [])
	if items.is_empty() or typeof(items[0]) != TYPE_DICTIONARY:
		push_error("[smoke] sentences items muszą mieć illustration")
		return false
	if not items[0].has("illustration"):
		return false
	print("[smoke] ok sentences (%d)" % items.size())
	return true
