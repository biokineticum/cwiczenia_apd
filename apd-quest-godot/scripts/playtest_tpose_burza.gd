extends SceneTree
## PL-39/PL-40: T-pose idle + Burza interact/pads sanity.
## godot --path apd-quest-godot --headless -s res://scripts/playtest_tpose_burza.gd


func _initialize() -> void:
	var ok := true
	ok = await _check_idle_not_bind_pose() and ok
	ok = await _check_burza_interact_and_pads() and ok
	if ok:
		print("[pl39-40] PASS")
		quit(0)
	else:
		print("[pl39-40] FAIL")
		quit(1)


func _check_idle_not_bind_pose() -> bool:
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
			push_error("[pl39] missing animator %s" % style_name)
			ok = false
			visual.queue_free()
			await process_frame
			continue
		if anim.has_method("setup"):
			anim.call("setup", visual)
		await process_frame
		await process_frame
		# Force idle (standing).
		if anim.has_method("play_idle"):
			anim.call("play_idle", true)
		await process_frame
		await process_frame
		var skel: Skeleton3D = anim.get("_skeleton") as Skeleton3D
		var player: AnimationPlayer = anim.get("_anim") as AnimationPlayer
		if skel == null:
			push_error("[pl39] no skeleton %s" % style_name)
			ok = false
		else:
			var la := skel.find_bone("LeftArm")
			var ra := skel.find_bone("RightArm")
			if la < 0 or ra < 0:
				push_error("[pl39] missing arm bones %s" % style_name)
				ok = false
			else:
				var q_rest_l := skel.get_bone_rest(la).basis.get_rotation_quaternion()
				var q_pose_l := skel.get_bone_pose_rotation(la)
				var q_rest_r := skel.get_bone_rest(ra).basis.get_rotation_quaternion()
				var q_pose_r := skel.get_bone_pose_rotation(ra)
				# Pose rotation near identity ⇒ still at bind/rest (T-pose).
				var left_near_rest := q_pose_l.dot(Quaternion.IDENTITY) > 0.98
				var right_near_rest := q_pose_r.dot(Quaternion.IDENTITY) > 0.98
				# Also compare absolute pose vs rest orientation delta.
				var left_delta := q_rest_l.inverse() * (q_rest_l * q_pose_l)
				var ang_l := q_pose_l.get_angle()
				var ang_r := q_pose_r.get_angle()
				var holding := bool(anim.get("_idle_from_clip"))
				print(
					"[pl39] %s idle LeftArm pose_ang=%.3f RightArm=%.3f holding=%s clip=%s"
					% [
						style_name,
						ang_l,
						ang_r,
						holding,
						player.current_animation if player else "",
					]
				)
				# Idle must NOT leave arms at bind (tiny procedural ~0.05–0.1 rad).
				if ang_l < 0.25 and ang_r < 0.25:
					push_error(
						"[pl39] %s still near bind/T-pose (arm pose angles too small)" % style_name
					)
					ok = false
				elif not holding and (_clip_expected(anim)):
					push_error("[pl39] %s idle not held from walk/idle clip" % style_name)
					ok = false
		# Walk should engage clip.
		if anim.has_method("set_locomotion_speed"):
			anim.call("set_locomotion_speed", 2.0)
			await process_frame
			await process_frame
			if player == null or not player.is_playing():
				push_error("[pl39] %s walk clip not playing" % style_name)
				ok = false
			else:
				print("[pl39] %s walk ok clip=%s" % [style_name, player.current_animation])
			anim.call("set_locomotion_speed", 0.0)
			await process_frame
			await process_frame
		visual.queue_free()
		await process_frame
	return ok


func _check_burza_interact_and_pads() -> bool:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("[pl40] cannot load main.tscn err=%s" % err)
		return false
	await process_frame
	await process_frame
	await create_timer(0.6).timeout
	var scene := root.get_child(root.get_child_count() - 1)
	# Autoloads + main; find Main.
	var main := root.get_node_or_null("/root/Main")
	if main == null:
		main = root.find_child("Main", true, false)
	if main == null:
		push_error("[pl40] Main missing")
		return false
	var storm := main.get_node_or_null("NpcStorm") as Node3D
	var echo := main.get_node_or_null("NpcEcho") as Node3D
	var player := main.get_node_or_null("PlayerGirl") as CharacterBody3D
	if storm == null or echo == null or player == null:
		push_error("[pl40] missing NpcStorm/NpcEcho/PlayerGirl")
		return false
	print(
		"[pl40] positions echo=%s storm=%s player=%s"
		% [echo.global_position, storm.global_position, player.global_position]
	)
	var area := storm.get_node_or_null("InteractionArea") as Area3D
	if area == null or not area.monitoring:
		push_error("[pl40] Burza InteractionArea missing/off")
		return false
	# Stand inside Burza interact sphere.
	player.global_position = storm.global_position + Vector3(0.6, 0.2, 0.8)
	player.velocity = Vector3.ZERO
	for i in 20:
		player.move_and_slide()
		await process_frame
	await create_timer(0.45).timeout
	var qm = root.get_node_or_null("/root/QuestManager")
	if qm == null:
		push_error("[pl40] QuestManager missing")
		return false
	# Offer may await TTS; force offer if dwell didn't fire (headless has no audio).
	if str(qm.get("offering_quest_id")) == "" and qm.get("active_quest") == null:
		print("[pl40] dwell did not offer — calling offer_quest directly after proximity")
		if not bool(qm.call("can_offer", "npc_storm_speech")):
			push_error("[pl40] cannot offer npc_storm_speech")
			return false
		qm.call("offer_quest", "npc_storm_speech")
	await create_timer(0.2).timeout
	if str(qm.get("offering_quest_id")) != "npc_storm_speech":
		push_error("[pl40] offering_quest_id=%s" % qm.get("offering_quest_id"))
		return false
	print("[pl40] Burza offer ok")
	# Spawn dialog pads the same way DialogPanel does, with Y check.
	var dialog := main.find_child("DialogPanel", true, false)
	if dialog and dialog.has_method("_spawn_walk_zones"):
		# Simulate post-TTS pad spawn without waiting for speech.
		dialog.set("_quest_id", "npc_storm_speech")
		dialog.set("_phase", "offer")
		dialog.call("_spawn_walk_zones")
		await process_frame
		await process_frame
	var zones: Array = []
	if dialog:
		zones = dialog.get("_zones") as Array
	if zones.is_empty():
		push_error("[pl40] no walk zones after Burza offer spawn")
		return false
	var ok := true
	for z in zones:
		if not (z is Area3D):
			continue
		var zone := z as Area3D
		var y := zone.global_position.y
		var xz := Vector2(zone.global_position.x, zone.global_position.z)
		var storm_xz := Vector2(storm.global_position.x, storm.global_position.z)
		var dist := xz.distance_to(storm_xz)
		print(
			"[pl40] pad kind=%s pos=%s y=%.3f dist_npc=%.2f"
			% [zone.get("kind"), zone.global_position, y, dist]
		)
		# Pad must sit near ground (not buried under rim hills).
		if y < -0.2 or y > 1.2:
			push_error("[pl40] pad Y out of range: %.3f" % y)
			ok = false
		# Cylinder must be able to overlap player capsule on this terrain.
		var hit_y := _ray_ground_y(zone.global_position)
		if hit_y < INF:
			var dy := absf(y - hit_y)
			print("[pl40] pad terrain_y=%.3f dy=%.3f" % [hit_y, dy])
			if dy > 0.35:
				push_error("[pl40] pad floating/buried vs terrain dy=%.3f" % dy)
				ok = false
		# Player overlap smoke: place on pad.
		player.global_position = zone.global_position + Vector3(0.0, 0.25, 0.0)
		for i in 8:
			player.move_and_slide()
			await process_frame
		await create_timer(0.25).timeout
	return ok


func _clip_expected(anim: Node) -> bool:
	var walk: String = str(anim.get("_clip_walk"))
	var idle: String = str(anim.get("_clip_idle"))
	return walk != "" or idle != ""


func _ray_ground_y(at: Vector3) -> float:
	var world := root.get_viewport().world_3d
	if world == null:
		return INF
	var space := world.direct_space_state
	if space == null:
		return INF
	var q := PhysicsRayQueryParameters3D.create(
		at + Vector3(0, 20, 0), at + Vector3(0, -40, 0)
	)
	q.collision_mask = 1
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return INF
	return float(hit.position.y)
