extends SceneTree
## Zrzut dialogu głosowego (ikony play/close, bez tekstu dziecka).
## APD_QUEST_SCREENSHOT=path.png


func _initialize() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(0.8).timeout
	var qm: Node = root.get_node("/root/QuestManager")
	qm.call("offer_quest", "npc_echo_word_seq")
	await create_timer(1.6).timeout
	var shot := OS.get_environment("APD_QUEST_SCREENSHOT")
	if shot != "":
		var img := root.get_viewport().get_texture().get_image()
		if img:
			img.save_png(shot)
			print("[capture-dialog] saved %s" % shot)
	await create_timer(0.4).timeout
	quit(0)
