extends Area2D

@export_enum("oro", "azul", "rojo", "gris") var tono := "oro"
@export var texto_destino := "SIGUIENTE NIVEL"


func _ready() -> void:
	$Visual/Portal.play(tono)
	establecer_bloqueada(false)


func establecer_bloqueada(bloqueada: bool) -> void:
	$Visual/Nombre.text = "DERROTA AL JEFE PARA PASAR" if bloqueada else texto_destino
