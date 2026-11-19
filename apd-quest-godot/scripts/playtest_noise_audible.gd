extends SceneTree
## PL-35: noise under speech — quiet but present; A/B vs PL-31 loud mix; duck during TTS.
## godot --path apd-quest-godot --audio-driver WASAPI -s res://scripts/playtest_noise_audible.gd

const LEVEL_NEW := 0.18
const LEVEL_OLD_LOUD := 0.55
## Faint but measurable on Noise bus (PL-31 was ~0.25 @ 0.55).
const RMS_MIN_AUDIBLE := 0.015
const RMS_MAX_UNDER_SPEECH := 0.12


func _initialize() -> void:
	await process_frame
	await create_timer(0.15).timeout
	var out_dir := "res://.capture"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var bus := AudioServer.get_bus_index("Noise")
	if bus < 0:
		push_error("[playtest-noise] Noise bus missing after AudioBusSetup")
		quit(1)
		return
	var fx := AudioEffectRecord.new()
	AudioServer.add_bus_effect(bus, fx)

	# --- A/B unit: old loud vs new under-speech ---
	var np = (load("res://scripts/audio/noise_player.gd") as GDScript).new()
	root.add_child(np)
	await process_frame

	var rms_loud := await _record_rms(fx, np, "pink", LEVEL_OLD_LOUD, 1.0)
	print("[playtest-noise] A/B loud pink@%.2f rms=%.4f vol=%.2f" % [
		LEVEL_OLD_LOUD, rms_loud, np.call("get_volume_linear")
	])
	np.call("stop")
	await process_frame

	var rms_new := await _record_rms(fx, np, "pink", LEVEL_NEW, 1.0)
	var vol_new: float = float(np.call("get_volume_linear"))
	print("[playtest-noise] A/B new pink@%.2f rms=%.4f vol=%.2f (need %.3f..%.3f)" % [
		LEVEL_NEW, rms_new, vol_new, RMS_MIN_AUDIBLE, RMS_MAX_UNDER_SPEECH
	])
	if not bool(np.call("is_playing")) or rms_new < RMS_MIN_AUDIBLE:
		push_error("[playtest-noise] new mix too quiet / not playing")
		quit(1)
		return
	if rms_new > RMS_MAX_UNDER_SPEECH:
		push_error("[playtest-noise] new mix still too loud for under-speech")
		quit(1)
		return
	if vol_new > 0.25:
		push_error("[playtest-noise] player vol_linear too high (got %.2f)" % vol_new)
		quit(1)
		return
	if rms_loud > 0.0 and rms_new >= rms_loud * 0.75:
		push_error("[playtest-noise] A/B: new RMS not clearly quieter than PL-31 loud")
		quit(1)
		return
	var ratio := rms_new / maxf(rms_loud, 0.0001)
	print("[playtest-noise] A/B ratio new/loud=%.3f (expect ~0.25–0.45)" % ratio)

	# --- Duck: TTS lowers Noise bus gain (EffectRecord is pre-volume; check bus dB) ---
	var bus_setup: Node = root.get_node_or_null("/root/AudioBusSetup")
	if bus_setup == null:
		push_error("[playtest-noise] AudioBusSetup missing")
		quit(1)
		return
	var db_before := AudioServer.get_bus_volume_db(bus)
	bus_setup.call("duck_noise", true)
	await create_timer(0.05).timeout
	var db_duck := AudioServer.get_bus_volume_db(bus)
	bus_setup.call("duck_noise", false)
	var db_after := AudioServer.get_bus_volume_db(bus)
	print("[playtest-noise] duck bus_db before=%.2f ducked=%.2f after=%.2f" % [db_before, db_duck, db_after])
	if db_duck > db_before - 6.0:
		push_error("[playtest-noise] duck did not drop Noise bus by ≥6 dB")
		quit(1)
		return
	if absf(db_after - db_before) > 0.5:
		push_error("[playtest-noise] duck did not restore Noise bus")
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
	var rec: AudioStreamWAV = fx.get_recording()
	var rms := _rms16(rec.data) if rec else 0.0
	if rec:
		rec.save_to_wav("user://pl35_noise_echo.wav")
	var echo_noise: Node = module.get("_noise") as Node
	var playing: bool = bool(echo_noise.call("is_playing")) if echo_noise else false
	var echo_vol: float = float(echo_noise.call("get_volume_linear")) if echo_noise else -1.0
	print("[playtest-noise] Echo after enable playing=%s rms=%.4f vol=%.2f" % [playing, rms, echo_vol])
	if not playing or rms < RMS_MIN_AUDIBLE:
		push_error("[playtest-noise] Echo noise not audible after enable")
		quit(1)
		return
	if rms > RMS_MAX_UNDER_SPEECH or echo_vol > 0.25:
		push_error("[playtest-noise] Echo noise too loud (rms=%.4f vol=%.2f)" % [rms, echo_vol])
		quit(1)
		return
	if is_instance_valid(module):
		module.call("set_noise_enabled", false)
	qm.call("complete_active_quest", true)
	await create_timer(0.5).timeout

	# --- Burza: should start with noise ON (quiet under speech) ---
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
		rec.save_to_wav("user://pl35_noise_burza.wav")
	var burza_vol: float = float(burza_noise.call("get_volume_linear")) if burza_noise else -1.0
	print("[playtest-noise] Burza rms=%.4f vol=%.2f" % [rms, burza_vol])
	if rms < RMS_MIN_AUDIBLE:
		push_error("[playtest-noise] Burza noise RMS too quiet")
		quit(1)
		return
	if rms > RMS_MAX_UNDER_SPEECH or burza_vol > 0.25:
		push_error("[playtest-noise] Burza noise too loud (rms=%.4f vol=%.2f)" % [rms, burza_vol])
		quit(1)
		return

	print("[playtest-noise] OK PL-35 under-speech mix")
	quit(0)


func _record_rms(fx: AudioEffectRecord, np: Node, noise_type: String, level: float, seconds: float) -> float:
	await np.call("start", noise_type, level)
	await create_timer(0.1).timeout
	fx.set_recording_active(true)
	await create_timer(seconds).timeout
	fx.set_recording_active(false)
	var rec: AudioStreamWAV = fx.get_recording()
	if rec == null or rec.data.size() < 1000:
		return 0.0
	return _rms16(rec.data)


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
