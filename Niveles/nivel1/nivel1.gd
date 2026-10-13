extends Node2D

const MENU_ESCENA := "res://ui/MainMenu.tscn"

@onready var jugador: CharacterBody2D = $CharacterBody2D
@onready var salida: Area2D = $Salida
@onready var panel_final: ColorRect = $Resultados/PantallaFinal
@onready var boton_reintentar: Button = $Resultados/PantallaFinal/CenterContainer/Panel/Contenido/Reintentar
@onready var aviso: Label = $Resultados/Aviso

func _ready() -> void:
	Global.punto_reaparicion = jugador.global_position
	$Checkpoint.body_entered.connect(_on_checkpoint_body_entered)
	$FragmentoVida.body_entered.connect(_on_fragmento_vida_body_entered)
	salida.body_entered.connect(_on_salida_body_entered)
	boton_reintentar.pressed.connect(_on_reintentar_pressed)
	$Resultados/PantallaFinal/CenterContainer/Panel/Contenido/Menu.pressed.connect(_on_menu_pressed)


func _on_checkpoint_body_entered(body: Node2D) -> void:
	if body != jugador or Global.punto_reaparicion == $Checkpoint.global_position:
		return
	Global.punto_reaparicion = $Checkpoint.global_position
	mostrar_aviso("PUNTO DE CONTROL")


func _on_fragmento_vida_body_entered(body: Node2D) -> void:
	if body != jugador:
		return
	jugador.call("obtener_fragmento_vida")
	$FragmentoVida.queue_free()
	mostrar_aviso("FRAGMENTO DE VIDA: +20")


func _on_salida_body_entered(body: Node2D) -> void:
	if body != jugador:
		return
	completar_nivel()


func completar_nivel() -> void:
	if panel_final.visible:
		return
	$PauseMenu.set_process_unhandled_input(false)
	get_tree().paused = true
	panel_final.show()
	boton_reintentar.grab_focus()


func mostrar_aviso(texto: String) -> void:
	aviso.text = texto
	aviso.show()
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(aviso):
		aviso.hide()


func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_ESCENA)