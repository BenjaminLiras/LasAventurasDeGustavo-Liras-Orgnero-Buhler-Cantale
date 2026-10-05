extends Control

const MAIN_MENU_SCENE := "res://ui/MainMenu.tscn"

@onready var back_button: Button = $Panel/Content/BackButton


func _ready() -> void:
	back_button.grab_focus()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
