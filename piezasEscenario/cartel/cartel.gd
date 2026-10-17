extends Node2D

@export_multiline var texto: String = ""


func _ready() -> void:
	$Tablero/Texto.text = texto
