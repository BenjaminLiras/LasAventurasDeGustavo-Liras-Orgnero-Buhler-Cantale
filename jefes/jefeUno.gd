extends CharacterBody2D

enum Estado { ESPERA, PERSEGUIR, ATACAR, HERIDO, MUERTO }

const DURACION_HERIDO: float = 0.5
const ALCANCE_ATAQUE: float = 72.0
const ALTURA_ATAQUE: float = 40.0
const DANIO_ATAQUE: int = 10
const ANTICIPACION_ATAQUE: float = 0.3
const VENTANA_GOLPE: float = 0.15
const DURACION_ATAQUE: float = 0.5
const ESPERA_ATAQUE: float = 1.0

var vida: int = 10
var velocidad: float = 60.0
var distancia_minima: float = 60.0
var jugador: Node2D
var direccion: float = 1.0
var estado: Estado = Estado.PERSEGUIR
var tiempo_herido: float = 0.0
var tiempo_ataque: float = 0.0
var espera_ataque: float = 0.0
var golpe_aplicado: bool = false


func _ready() -> void:
	reproducir_animacion("quieto")
	jugador = get_tree().get_first_node_in_group("jugador") as Node2D


func _physics_process(delta: float) -> void:
	if estado != Estado.MUERTO:
		espera_ataque = maxf(espera_ataque - delta, 0.0)
	match estado:
		Estado.ESPERA:
			detenerse()
		Estado.PERSEGUIR:
			if not is_instance_valid(jugador):
				jugador = get_tree().get_first_node_in_group("jugador") as Node2D
			if is_instance_valid(jugador):
				perseguir_jugador()
			else:
				detenerse()
		Estado.ATACAR:
			procesar_ataque(delta)
		Estado.HERIDO:
			detenerse()
			tiempo_herido -= delta
			if tiempo_herido <= 0.0:
				estado = Estado.PERSEGUIR
		Estado.MUERTO:
			return
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	$AnimatedSprite2D.flip_h = direccion < 0.0
	actualizar_animacion()
	move_and_slide()


func perseguir_jugador() -> void:
	var diferencia: Vector2 = jugador.global_position - global_position
	if diferencia.x != 0.0:
		direccion = signf(diferencia.x)
	if jugador_en_alcance():
		detenerse()
		if espera_ataque <= 0.0:
			tiempo_ataque = 0.0
			golpe_aplicado = false
			estado = Estado.ATACAR
	elif absf(diferencia.x) > distancia_minima:
		velocity.x = direccion * velocidad
	else:
		detenerse()


func procesar_ataque(delta: float) -> void:
	detenerse()
	tiempo_ataque += delta
	if tiempo_ataque >= ANTICIPACION_ATAQUE and tiempo_ataque < ANTICIPACION_ATAQUE + VENTANA_GOLPE and not golpe_aplicado and jugador_en_alcance():
		if jugador.has_method("recibir_golpe"):
			jugador.call("recibir_golpe", DANIO_ATAQUE)
			golpe_aplicado = true
	if tiempo_ataque >= DURACION_ATAQUE:
		estado = Estado.PERSEGUIR
		espera_ataque = ESPERA_ATAQUE


func jugador_en_alcance() -> bool:
	if not is_instance_valid(jugador):
		return false
	var diferencia: Vector2 = jugador.global_position - global_position
	return absf(diferencia.x) <= ALCANCE_ATAQUE and absf(diferencia.y) <= ALTURA_ATAQUE


func detenerse() -> void:
	velocity.x = 0.0


func actualizar_animacion() -> void:
	match estado:
		Estado.ESPERA:
			reproducir_animacion("quieto")
		Estado.PERSEGUIR:
			reproducir_animacion("quieto")
		Estado.ATACAR:
			reproducir_animacion("atacar")
		Estado.HERIDO:
			reproducir_animacion("herido")
		Estado.MUERTO:
			reproducir_animacion("morir")


func reproducir_animacion(nombre: String) -> void:
	if $AnimatedSprite2D.animation != nombre:
		$AnimatedSprite2D.play(nombre)


func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or vida <= 0 or estado == Estado.MUERTO:
		return
	vida = maxi(vida - cantidad, 0)
	if vida == 0:
		estado = Estado.MUERTO
		reproducir_animacion("morir")
		await $AnimatedSprite2D.animation_finished
		queue_free()
	else:
		estado = Estado.HERIDO
		tiempo_herido = DURACION_HERIDO
		reproducir_animacion("herido")
