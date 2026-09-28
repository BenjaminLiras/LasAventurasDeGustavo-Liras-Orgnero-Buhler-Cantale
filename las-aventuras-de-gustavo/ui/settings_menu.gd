extends Control

const MAIN_MENU_SCENE := "res://ui/MainMenu.tscn"

@onready var volume_slider: HSlider = $Panel/Options/VolumeRow/VolumeSlider
@onready var fullscreen_check: CheckButton = $Panel/Options/FullscreenRow/FullscreenCheck
@onready var back_button: Button = $Panel/Options/BackButton


func _ready() -> void:
	var bus := AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus))
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	back_button.grab_focus()


func _on_volume_slider_value_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.0001)))


func _on_fullscreen_check_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
