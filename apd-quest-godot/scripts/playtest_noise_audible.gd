extends SceneTree
## PL-31: verify noise plays when enabled (Echo + Burza).
## godot --path apd-quest-godot --audio-driver WASAPI -s res://scripts/playtest_noise_audible.gd


func _initialize() -> void:
	await process_frame
	await create_timer(0.15).timeout
	var out_dir := "res://.capture"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# --- Unit: NoisePlayer WAV loop ---
	var bus := AudioServer.get_bus_index("Noise")
	if bus < 0:
		push_error("[playtest-noise] Noise bus missing after AudioBusSetup")
		quit(1)
		return
	var fx := AudioEffectRecord.new()
	AudioServer.add_bus_effect(bus, fx)
	var np = (load("res://scripts/audio/noise_player.gd") as GDScript).new()
	root.add_child(np)
	await process_frame
	await np.call("start", "pink", 0.55)
	await create_timer(0.1).timeout
	fx.set_recording_active(true)
	await create_timer(1.0).timeout
	fx.set_recording_active(false)
	var rec: AudioStreamWAV = fx.get_recording()
	if rec == null or rec.data.size() < 1000:
		push_error("[playtest-noise] unit record empty")
		quit(1)
		return
	var rms := _rms16(rec.data)
	rec.save_to_wav("user://pl31_noise_unit.wav")
	print("[playtest-noise] unit pink@0.55 playing=%s rms=%.4f (need >0.05)" % [
		np.call("is_playing"), rms
	])
	if rms < 0.05:
		push_error("[playtest-noise] unit RMS too quiet")
		quit(1)
		return
	np.call("stop")
	np.queue_free()
	await process_frame

	# --- Echo: enable mid-session like parent toggle ---
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("[playtest-noise] main fail")
		quit(1)
		return
	await process_frame
	await create_timer(0.8).timeout
	var qm: Node = root.get_node_or_null("/root/QuestManager")
	qm.call("start_quest", "npc_echo_word_seq")
	var overlay := _find(root, "ListeningOverlay")
	var module: Node = null
	var deadline := Time.get_ticks_msec() + 25000
	while Time.get_ticks_msec() < deadline:
		var session: Variant = overlay.get("_session") if overlay else null
		if session:
			module = session.get("_module")
			if module and module.get("_noise") != null and module.get("_speech") != null:
				break
		await create_timer(0.2).timeout
	if module == null:
		push_error("[playtest-noise] no Echo module")
		quit(1)
		return
	print("[playtest-noise] Echo initial noise_on=%s" % module.get("_noise_on"))
	if bool(module.get("_noise_on")):
		push_error("[playtest-noise] Echo should start with noise OFF")
		quit(1)
		return
	fx.set_recording_active(true)
	await module.set_noise_enabled(true)
	await create_timer(1.1).timeout
	fx.set_recording_active(false)
	rec = fx.get_recording()
	rms = _rms16(rec.data) if rec else 0.0
	if rec:
		rec.save_to_wav("user://pl31_noise_echo.wav")
	var echo_noise: Node = module.get("_noise") as Node
	var playing: bool = bool(echo_noise.call("is_playing")) if echo_noise else false
	print("[playtest-noise] Echo after enable playing=%s rms=%.4f" % [playing, rms])
	if not playing or rms < 0.05:
		push_error("[playtest-noise] Echo noise not audible after enable")
		quit(1)
		return
	# Finish / clear for Burza
	if is_instance_valid(module):
		module.call("set_noise_enabled", false)
	qm.call("complete_active_quest", true)
	await create_timer(0.5).timeout

	# --- Burza: should start with noise ON ---
	qm.call("start_quest", "npc_storm_speech")
	module = null
	deadline = Time.get_ticks_msec() + 25000
	while Time.get_ticks_msec() < deadline:
		overlay = _find(root, "ListeningOverlay")
		var session2: Variant = overlay.get("_session") if overlay else null
		if session2:
			module = session2.get("_module")
			if module and module.get("_noise") != null:
				break
		await create_timer(0.2).timeout
	if module == null:
		push_error("[playtest-noise] no Burza module")
		quit(1)
		return
	await create_timer(0.4).timeout
	var burza_on: bool = bool(module.get("_noise_on"))
	var burza_noise: Node = module.get("_noise") as Node
	var burza_playing: bool = bool(burza_noise.call("is_playing")) if burza_noise else false
	print("[playtest-noise] Burza noise_on=%s playing=%s" % [burza_on, burza_playing])
	if not burza_on or not burza_playing:
		push_error("[playtest-noise] Burza should start with audible noise")
		quit(1)
		return
	fx.set_recording_active(true)
	await create_timer(1.0).timeout
	fx.set_recording_active(false)
	rec = fx.get_recording()
	rms = _rms16(rec.data) if rec else 0.0
	if rec:
		rec.save_to_wav("user://pl31_noise_burza.wav")
	print("[playtest-noise] Burza rms=%.4f" % rms)
	if rms < 0.05:
		push_error("[playtest-noise] Burza noise RMS too quiet")
		quit(1)
		return

	print("[playtest-noise] OK")
	quit(0)


func _rms16(data: PackedByteArray) -> float:
	if data.is_empty():
		return 0.0
	var sum := 0.0
	var n := 0
	var i := 0
	while i + 1 < data.size():
		var lo := data[i]
		var hi := data[i + 1]
		var s := int(lo) | (int(hi) << 8)
		if s >= 32768:
			s -= 65536
		var f := float(s) / 32768.0
		sum += f * f
		n += 1
		i += 2
	return sqrt(sum / maxf(1.0, float(n)))


func _find(n: Node, name: String) -> Node:
	if n.name == name:
		return n
	for c in n.get_children():
		var f := _find(c, name)
		if f:
			return f
	return null
