extends SceneTree
## Headless sanity: rigged GLBs expose walk/run + CharacterAnimator resolves clips.
## Usage: godot --path apd-quest-godot --headless -s res://scripts/playtest_capture_anim.gd


func _initialize() -> void:
	var builder = load("res://scripts/art/stylized_character_builder.gd")
	var ok := true
	for style_name in ["GIRL", "ECHO", "STORM"]:
		var style = builder.Style.get(style_name)
		var visual: Node3D = builder.build(style)
		root.add_child(visual)
		await process_frame
		await process_frame
		var anim := visual.get_node_or_null("CharacterAnimator")
		if anim == null:
			push_error("[anim] missing CharacterAnimator for %s" % style_name)
			ok = false
			continue
		# Force setup if deferred not done yet.
		if anim.has_method("setup"):
			anim.call("setup", visual)
		await process_frame
		var walk: String = str(anim.get("_clip_walk"))
		var run: String = str(anim.get("_clip_run"))
		var skel = anim.get("_skeleton")
		print("[anim] %s walk=%s run=%s skeleton=%s" % [style_name, walk, run, skel != null])
		if walk == "" and run == "":
			push_error("[anim] no locomotion clips for %s" % style_name)
			ok = false
		if skel == null:
			push_error("[anim] no skeleton for %s" % style_name)
			ok = false
		# Drive walk briefly
		if anim.has_method("set_locomotion_speed"):
			anim.call("set_locomotion_speed", 2.0)
			await process_frame
			anim.call("set_locomotion_speed", 0.0)
		visual.queue_free()
		await process_frame

	# Wind sway constructs
	var wind_script = load("res://scripts/art/wind_sway.gd")
	var w = wind_script.new()
	root.add_child(w)
	await process_frame
	print("[anim] WindSway ok")
	w.queue_free()

	if ok:
		print("[anim] PASS")
		quit(0)
	else:
		print("[anim] FAIL")
		quit(1)
