extends Area2D

const VELOCIDAD: float = 260.0
const DANIO: int = 10
const DISTANCIA_EMPUJE: float = 22.0
const DURACION_MAXIMA: float = 3.0

var direccion: Vector2 = Vector2.RIGHT
var direccion_empuje_x: float = 1.0
var tiempo_activo: float = 0.0
var impacto_aplicado: bool = false


func apuntar_a(posicion_objetivo: Vector2) -> void:
	direccion = (posicion_objetivo - global_position).normalized()
	if direccion == Vector2.ZERO:
		direccion = Vector2.RIGHT
	direccion_empuje_x = signf(posicion_objetivo.x - global_position.x)
	if direccion_empuje_x == 0.0:
		direccion_empuje_x = 1.0
	rotation = direccion.angle()


func _physics_process(delta: float) -> void:
	global_position += direccion * VELOCIDAD * delta
	tiempo_activo += delta
	if tiempo_activo >= DURACION_MAXIMA:
		queue_free()


func _on_body_entered(cuerpo: Node2D) -> void:
	if impacto_aplicado or bool(cuerpo.get("intangible_por_dash")):
		return
	impacto_aplicado = true
	if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_golpe"):
		if not bool(cuerpo.get("invulnerable")) and int(cuerpo.get("vida")) > 0:
			cuerpo.call("recibir_golpe", DANIO)
			if int(cuerpo.get("vida")) > 0 and cuerpo is CharacterBody2D:
				var cuerpo_fisico: CharacterBody2D = cuerpo as CharacterBody2D
				cuerpo_fisico.call_deferred("move_and_collide", Vector2(direccion_empuje_x * DISTANCIA_EMPUJE, 0.0))
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
