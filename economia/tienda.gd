extends Area2D

var jugador_cerca: Node2D
var abierta := false
var pausado_previo := false
@onready var pantalla: Control = $Interfaz/Fondo
@onready var contenido: VBoxContainer = $Interfaz/Fondo/Centro/Panel/Contenido

func _ready() -> void:
	body_entered.connect(_entrar)
	body_exited.connect(_salir)
	contenido.get_node("Alcance").pressed.connect(_comprar.bind("alcance"))
	contenido.get_node("Vitalidad").pressed.connect(_comprar.bind("vitalidad"))
	contenido.get_node("Cerrar").pressed.connect(cerrar)
	Global.economia_cambiada.connect(actualizar)
	Global.mejoras_cambiadas.connect(actualizar)
	actualizar()

func _entrar(cuerpo: Node2D) -> void:
	if cuerpo.is_in_group("jugador"):
		jugador_cerca = cuerpo
		$Ayuda.text = "E / SELECT: TIENDA"

func _salir(cuerpo: Node2D) -> void:
	if cuerpo == jugador_cerca:
		jugador_cerca = null
		$Ayuda.text = "ESPÍRITUS VIAJEROS"

func _unhandled_input(evento: InputEvent) -> void:
	var interactuar: bool = (evento is InputEventKey and evento.pressed and not evento.echo and evento.physical_keycode == KEY_E) or (evento is InputEventJoypadButton and evento.pressed and evento.button_index == JOY_BUTTON_BACK)
	if abierta and (evento.is_action_pressed("ui_cancel") or interactuar):
		cerrar()
		get_viewport().set_input_as_handled()
	elif interactuar and is_instance_valid(jugador_cerca) and not jugador_cerca.get("muerto") and not get_tree().paused:
		abierta = true
		pausado_previo = get_tree().paused
		pantalla.show()
		get_tree().paused = true
		actualizar()
		contenido.get_node("Cerrar").grab_focus()
		get_viewport().set_input_as_handled()

func cerrar() -> void:
	if not abierta:
		return
	abierta = false
	pantalla.hide()
	get_tree().paused = pausado_previo

func _exit_tree() -> void:
	if abierta:
		get_tree().paused = pausado_previo

func _comprar(tipo: String) -> void:
	if Global.comprar(tipo):
		Sonido.reproducir("fragmento")
		contenido.get_node("Mensaje").text = "Espíritu adquirido. Su mejora ya está activa."
		contenido.get_node("Cerrar").grab_focus()

func actualizar() -> void:
	contenido.get_node("Monedas").text = "Tus monedas: %d" % Global.monedas
	var alcance: Button = contenido.get_node("Alcance")
	var vitalidad: Button = contenido.get_node("Vitalidad")
	alcance.text = "ESPÍRITU DEL ALCANCE · +%d%% de alcance del bate\n%s" % [roundi((Global.BALANCE.multiplicador_alcance - 1.0) * 100.0), "ADQUIRIDO" if Global.amuleto_alcance else "%d monedas" % Global.BALANCE.precio_alcance]
	vitalidad.text = "ESPÍRITU VITAL · +%d corazones permanentes\n%s" % [Global.BALANCE.corazones_amuletos, "ADQUIRIDO" if Global.amuleto_vitalidad else "%d monedas" % Global.BALANCE.precio_vitalidad]
	alcance.disabled = Global.amuleto_alcance or Global.monedas < Global.BALANCE.precio_alcance
	vitalidad.disabled = Global.amuleto_vitalidad or Global.monedas < Global.BALANCE.precio_vitalidad
