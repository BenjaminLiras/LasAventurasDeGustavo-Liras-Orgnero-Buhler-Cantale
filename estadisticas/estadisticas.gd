extends CanvasLayer
## Panel con estadísticas de desarrollo (posición, velocidad, dash, FPS...).
## Se muestra u oculta con la casilla de Configuración (menú principal y pausa).
## La elección se guarda en user:// y arranca desactivada.

const ARCHIVO_AJUSTES := "user://ajustes.cfg"
const SECCION := "desarrollo"
const CLAVE_ACTIVAS := "estadisticas"
# Misma capa que CAPA_COLISION_PLATAFORMA en PJ/PJprincipal/gustavo.gd.
const CAPA_PLATAFORMAS := 4

var activas := false
var jugador: CharacterBody2D

@onready var panel: PanelContainer = $Panel
@onready var texto: Label = $Panel/Texto


func _ready() -> void:
	var ajustes := ConfigFile.new()
	ajustes.load(ARCHIVO_AJUSTES)
	establecer_activas(bool(ajustes.get_value(SECCION, CLAVE_ACTIVAS, false)), false)


func _process(_delta: float) -> void:
	_actualizar()


func establecer_activas(valor: bool, guardar: bool = true) -> void:
	activas = valor
	panel.visible = valor
	set_process(valor)
	if valor:
		_actualizar()
	if guardar:
		_guardar()


func _guardar() -> void:
	var ajustes := ConfigFile.new()
	ajustes.load(ARCHIVO_AJUSTES)
	ajustes.set_value(SECCION, CLAVE_ACTIVAS, activas)
	ajustes.save(ARCHIVO_AJUSTES)


func _actualizar() -> void:
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody2D
	var lineas := PackedStringArray([
		"FPS: %d" % Engine.get_frames_per_second(),
		"Escena: %s" % _nombre_escena(),
	])
	if jugador == null:
		lineas.append("Jugador: no hay")
	else:
		lineas.append_array(_lineas_jugador())
	texto.text = "\n".join(lineas)


func _nombre_escena() -> String:
	var escena := get_tree().current_scene
	if escena == null:
		return "-"
	if escena.scene_file_path.is_empty():
		return String(escena.name)
	return escena.scene_file_path.get_file().get_basename()


func _lineas_jugador() -> PackedStringArray:
	var posicion := jugador.global_position
	var velocidad := Global.getVelocidad()
	var direccion := Global.getDireccion()
	var reaparicion := Global.punto_reaparicion
	var invulnerable := " (invulnerable)" if jugador.get("invulnerable") else ""
	var capa_plataformas := "activa" if jugador.get_collision_mask_value(CAPA_PLATAFORMAS) else "desactivada"
	var atravesando_plataforma = jugador.get("cayendo_a_traves_de_plataforma") or jugador.get("atravesando_plataforma_al_subir")
	return PackedStringArray([
		"Posición: %.1f, %.1f" % [posicion.x, posicion.y],
		"Velocidad: %d, %d" % [velocidad.x, velocidad.y],
		"Dirección: %.2f, %.2f" % [direccion.x, direccion.y],
		"En suelo: %s" % _si_no(jugador.is_on_floor()),
		"Dash activo: %s" % _si_no(Global.getDash()),
		"Dash en recarga: %s" % _si_no(jugador.get("dashEnCooldown")),
		"Vida: %s / %s%s" % [jugador.get("vida"), jugador.get("vidaMaxima"), invulnerable],
		"Capa plataformas: %s" % capa_plataformas,
		"Atravesando plataforma: %s" % _si_no(atravesando_plataforma),
		"Reaparición: %d, %d" % [reaparicion.x, reaparicion.y],
	])


func _si_no(valor: Variant) -> String:
	return "sí" if valor else "no"
