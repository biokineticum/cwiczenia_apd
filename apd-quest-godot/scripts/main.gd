extends Node3D
## Bootstrap sceny głównej — vertical slice polany.

@export var auto_screenshot_path: String = ""
@export var auto_quit_after_sec: float = 0.0


func _ready() -> void:
	print("=== APD Quest — vertical slice (Godot 4) ===")
	print("Polana Echo · WASD ruch · PPM+mysz kamera · E rozmowa")
	print("NPC: Echo (sekwencje słów), Burza (mowa w szumie)")
	print("Trening wspomagający — nie diagnostyka.")
	if OS.get_environment("APD_QUEST_SCREENSHOT") != "":
		auto_screenshot_path = OS.get_environment("APD_QUEST_SCREENSHOT")
	if OS.get_environment("APD_QUEST_QUIT_AFTER") != "":
		auto_quit_after_sec = float(OS.get_environment("APD_QUEST_QUIT_AFTER"))
	if auto_screenshot_path != "" or auto_quit_after_sec > 0.0:
		_run_capture_flow()


func _run_capture_flow() -> void:
	await get_tree().create_timer(1.2).timeout
	if auto_screenshot_path != "":
		var img := get_viewport().get_texture().get_image()
		if img:
			var err := img.save_png(auto_screenshot_path)
			print("[Main] screenshot → %s (err=%s)" % [auto_screenshot_path, err])
	if auto_quit_after_sec > 0.0:
		var remaining := maxf(0.0, auto_quit_after_sec - 1.2)
		if remaining > 0.0:
			await get_tree().create_timer(remaining).timeout
		get_tree().quit()
