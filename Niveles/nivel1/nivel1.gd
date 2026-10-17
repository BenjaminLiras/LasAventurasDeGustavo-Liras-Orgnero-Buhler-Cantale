extends Node2D

const MENU_ESCENA := "res://ui/MainMenu.tscn"
const DESPLAZAMIENTO_REAPARICION := Vector2(0.0, -56.0)
const COLOR_SALIDA_BLOQUEADA := Color(0.55, 0.55, 0.65, 0.6)

@export_file("*.tscn") var siguiente_nivel: String = ""

@onready var jugador: CharacterBody2D = $CharacterBody2D
@onready var salida: Area2D = $Salida
@onready var arco_salida: Node2D = $ArcoSalida
@onready var panel_final: ColorRect = $Resultados/PantallaFinal
@onready var boton_siguiente: Button = $Resultados/PantallaFinal/CenterContainer/Panel/Contenido/Siguiente
@onready var boton_reintentar: Button = $Resultados/PantallaFinal/CenterContainer/Panel/Contenido/Reintentar
@onready var aviso: Label = $Resultados/Aviso

var salida_bloqueada := false
var avisos_activos := 0

func _ready() -> void:
	Global.punto_reaparicion = jugador.global_position
	for nodo in get_tree().get_nodes_in_group("checkpoints"):
		var checkpoint := nodo as Area2D
		checkpoint.body_entered.connect(_on_checkpoint_body_entered.bind(checkpoint))
	for nodo in get_tree().get_nodes_in_group("fragmentos_vida"):
		var fragmento := nodo as Area2D
		fragmento.body_entered.connect(_on_fragmento_vida_body_entered.bind(fragmento))
	salida.body_entered.connect(_on_salida_body_entered)
	$ZonaCaida.body_entered.connect(_on_zona_caida_body_entered)
	boton_siguiente.visible = not siguiente_nivel.is_empty()
	boton_siguiente.pressed.connect(_on_siguiente_pressed)
	boton_reintentar.pressed.connect(_on_reintentar_pressed)
	$Resultados/PantallaFinal/CenterContainer/Panel/Contenido/Menu.pressed.connect(_on_menu_pressed)
	var jefe := get_node_or_null("Benjamin")
	if jefe != null:
		salida_bloqueada = true
		arco_salida.modulate = COLOR_SALIDA_BLOQUEADA
		jefe.connect("derrotado", _on_jefe_derrotado)
	Sonido.reproducir_musica("nivel1")


func _exit_tree() -> void:
	Sonido.detener_musica()


func _on_checkpoint_body_entered(body: Node2D, checkpoint: Area2D) -> void:
	var punto := checkpoint.global_position + DESPLAZAMIENTO_REAPARICION
	if body != jugador or Global.punto_reaparicion == punto:
		return
	Global.punto_reaparicion = punto
	Sonido.reproducir("checkpoint")
	mostrar_aviso("PUNTO DE CONTROL")


func _on_fragmento_vida_body_entered(body: Node2D, fragmento: Area2D) -> void:
	if body != jugador:
		return
	jugador.call("obtener_fragmento_vida")
	fragmento.queue_free()
	Sonido.reproducir("fragmento")
	mostrar_aviso("FRAGMENTO DE VIDA: +20")


func _on_zona_caida_body_entered(body: Node2D) -> void:
	if body == jugador:
		jugador.call("morir")


func _on_jefe_derrotado() -> void:
	salida_bloqueada = false
	Sonido.reproducir("victoria")
	create_tween().tween_property(arco_salida, "modulate", Color.WHITE, 0.5)
	mostrar_aviso("JEFE DERROTADO: SALIDA ABIERTA")


func _on_salida_body_entered(body: Node2D) -> void:
	if body != jugador:
		return
	if salida_bloqueada:
		Sonido.reproducir("bloqueado")
		mostrar_aviso("DERROTA AL JEFE PARA SALIR")
		return
	completar_nivel()


func completar_nivel() -> void:
	if panel_final.visible:
		return
	Sonido.reproducir("victoria")
	$PauseMenu.set_process_unhandled_input(false)
	get_tree().paused = true
	panel_final.show()
	var boton_inicial := boton_siguiente if boton_siguiente.visible else boton_reintentar
	boton_inicial.grab_focus()


func mostrar_aviso(texto: String) -> void:
	aviso.text = texto
	aviso.show()
	avisos_activos += 1
	await get_tree().create_timer(1.5).timeout
	avisos_activos -= 1
	if avisos_activos == 0 and is_instance_valid(aviso):
		aviso.hide()


func _on_siguiente_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(siguiente_nivel)


func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_ESCENA)