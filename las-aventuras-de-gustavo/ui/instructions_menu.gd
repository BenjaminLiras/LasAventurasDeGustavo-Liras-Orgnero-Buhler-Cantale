extends Control

## Pantalla con los controles del juego.

const MAIN_MENU_SCENE := "res://ui/MainMenu.tscn"

@onready var back_button: Button = $Panel/Controls/BackButton


func _ready() -> void:
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
