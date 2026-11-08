extends Area2D

const DURACION := 0.22
const INICIO_IMPACTO := 0.035
const FIN_IMPACTO := 0.18

@export var daño: int = 1
var lanzador: CharacterBody2D
var direccion_golpe := Vector2.RIGHT
var objetivos_golpeados: Dictionary = {}
var tiempo := 0.0
var activo := false
var retroceso_aplicado := false


func _ready() -> void:
	_actualizar_visual()


func _physics_process(delta: float) -> void:
	tiempo += delta
	if tiempo >= DURACION:
		queue_free()
		return
	var siguiente_activo := tiempo >= INICIO_IMPACTO and tiempo < FIN_IMPACTO
	if siguiente_activo != activo:
		activo = siguiente_activo
		$Colision.set_deferred("disabled", not activo)
	_actualizar_visual()


func _actualizar_visual() -> void:
	var progreso := clampf(tiempo / FIN_IMPACTO, 0.0, 1.0)
	$Bate.rotation = lerpf(-1.15, 1.15, smoothstep(0.0, 1.0, progreso))
	$Arco.visible = activo
	$Arco.modulate.a = sin(progreso * PI) * 0.85
	modulate.a = clampf((DURACION - tiempo) / (DURACION - FIN_IMPACTO), 0.0, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if not activo or body == lanzador:
		return
	var id_objetivo := body.get_instance_id()
	if objetivos_golpeados.has(id_objetivo) or not body.has_method("recibir_golpe"):
		return
	objetivos_golpeados[id_objetivo] = true
	body.call("recibir_golpe", daño)
	Sonido.reproducir("impacto")
	# Un solo retroceso por barrido, aunque alcance varios enemigos.
	if not retroceso_aplicado and is_instance_valid(lanzador) and lanzador.has_method("aplicar_retroceso_batazo"):
		retroceso_aplicado = true
		lanzador.call("aplicar_retroceso_batazo", direccion_golpe)
