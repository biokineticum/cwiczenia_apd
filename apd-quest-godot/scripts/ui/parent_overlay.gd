extends Control
## Warstwa rodzica: tekst bodźca, szum, disclaimer. Wejście: long-press ikony rodzica.

signal noise_toggled(enabled: bool)
signal closed

@onready var panel: PanelContainer = $Panel
@onready var stimulus_label: Label = $Panel/VBox/Stimulus
@onready var blurb_label: Label = $Panel/VBox/Blurb
@onready var noise_toggle: CheckButton = $Panel/VBox/NoiseToggle
@onready var close_btn: Button = $Panel/VBox/Close


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.pressed.connect(_on_close)
	noise_toggle.toggled.connect(func(on: bool): noise_toggled.emit(on))


func open_with(stimulus: String, blurb: String, noise_on: bool) -> void:
	stimulus_label.text = "Bodziec: %s" % stimulus
	blurb_label.text = blurb if blurb != "" else "Trening wspomagający — nie diagnostyka. Poziom szumu jest względny (nie kliniczny SNR)."
	noise_toggle.set_pressed_no_signal(noise_on)
	noise_toggle.text = "Szum (względny poziom)"
	visible = true


func _on_close() -> void:
	visible = false
	closed.emit()
