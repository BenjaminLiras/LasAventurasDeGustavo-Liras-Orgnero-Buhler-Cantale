extends Control

# Cambia estas rutas si mueves las escenas.
const GAME_SCENE := "res://nivel1.tscn"
const SETTINGS_SCENE := "res://ui/SettingsMenu.tscn"
const INSTRUCTIONS_SCENE := "res://ui/InstructionsMenu.tscn"

@onready var menu_buttons: VBoxContainer = $MenuButtons
@onready var play_button: Button = $MenuButtons/PlayButton


func _ready() -> void:
	# El mouse mueve el foco para que teclado y mouse muestren la misma selección.
	for button in menu_buttons.get_children():
		button.mouse_entered.connect(button.grab_focus)
	play_button.grab_focus()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_instructions_button_pressed() -> void:
	get_tree().change_scene_to_file(INSTRUCTIONS_SCENE)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
