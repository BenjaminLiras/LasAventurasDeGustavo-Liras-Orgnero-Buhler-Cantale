extends Area2D

const DURACION_MAXIMA: float = 4.5

@onready var forma_visual: Polygon2D = $FormaVisual

var direccion: Vector2 = Vector2.RIGHT
var velocidad: float = 300.0
var danio: int = 14
var color_proyectil: Color = Color.WHITE
var escala_visual: Vector2 = Vector2.ONE
var tiempo_activo: float = 0.0
var impacto_aplicado: bool = false


func configurar(nueva_direccion: Vector2, nueva_velocidad: float, nuevo_danio: int, nuevo_color: Color, nueva_escala: Vector2) -> void:
	direccion = nueva_direccion.normalized()
	if direccion == Vector2.ZERO:
		direccion = Vector2.RIGHT
	velocidad = nueva_velocidad
	danio = nuevo_danio
	color_proyectil = nuevo_color
	escala_visual = nueva_escala


func _ready() -> void:
	forma_visual.color = color_proyectil
	scale = escala_visual
	rotation = direccion.angle()


func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta
	tiempo_activo += delta
	if tiempo_activo >= DURACION_MAXIMA:
		queue_free()


func _on_cuerpo_entrado(cuerpo: Node2D) -> void:
	if impacto_aplicado:
		return
	if not cuerpo.is_in_group("jugador"):
		queue_free()
		return
	impacto_aplicado = true
	if cuerpo.has_method("recibir_golpe") and cuerpo.get("invulnerable") != true and cuerpo.get("muerto") != true:
		cuerpo.call("recibir_golpe", danio)
	queue_free()
