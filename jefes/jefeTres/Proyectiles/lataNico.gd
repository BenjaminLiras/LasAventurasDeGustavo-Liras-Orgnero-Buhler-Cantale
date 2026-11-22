extends CharacterBody2D

const DANIO: int = 16
const GRAVEDAD: float = 1050.0
const DURACION_MAXIMA: float = 2.5
const VELOCIDAD_GIRO: float = 9.0
const CAPA_JUGADOR: int = 1

@onready var visual: Sprite2D = $Visual

var direccion: float = 1.0
var tiempo_activo: float = 0.0
var impacto_aplicado: bool = false
var jugador: Node2D


func configurar(velocidad_inicial: Vector2, jugador_objetivo: Node2D) -> void:
	velocity = velocidad_inicial
	if not is_zero_approx(velocity.x):
		direccion = signf(velocity.x)
	jugador = jugador_objetivo


func _physics_process(delta: float) -> void:
	if impacto_aplicado or is_queued_for_deletion():
		return
	tiempo_activo += delta
	if tiempo_activo >= DURACION_MAXIMA:
		queue_free()
		return
	var jugador_intangible: bool = is_instance_valid(jugador) and jugador.get("intangible_por_dash") == true
	set_collision_mask_value(CAPA_JUGADOR, not jugador_intangible)
	visual.rotation += direccion * VELOCIDAD_GIRO * delta
	var movimiento: Vector2 = velocity * delta + Vector2.DOWN * (0.5 * GRAVEDAD * delta * delta)
	velocity.y += GRAVEDAD * delta
	var impacto := move_and_collide(movimiento)
	if impacto != null:
		procesar_impacto(impacto.get_collider())


func procesar_impacto(cuerpo: Object) -> void:
	if impacto_aplicado:
		return
	impacto_aplicado = true
	queue_free()
	if not cuerpo is Node2D or not cuerpo.is_in_group("jugador"):
		return
	if cuerpo.get("invulnerable") == true or cuerpo.get("intangible_por_dash") == true or cuerpo.get("muerto") == true:
		return
	if cuerpo.has_method("recibir_golpe"):
		cuerpo.call("recibir_golpe", DANIO)
