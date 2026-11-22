extends CharacterBody2D

signal derrotado

enum Estado { ESPERA, PERSEGUIR, PREPARAR_ATAQUE, RECUPERAR, HERIDO, MUERTO }

const VIDA_MAXIMA: int = 36
const VELOCIDAD: float = 280.0
const ACELERACION: float = 1800.0
const DISTANCIA_MINIMA: float = 84.0
const ALCANCE_LANZAMIENTO: float = 320.0
const ALTURA_LANZAMIENTO: float = 100.0
const DURACION_PREPARACION: float = 0.4
const DURACION_RECUPERACION: float = 0.35
const DURACION_HERIDO: float = 0.16
const DURACION_MUERTE: float = 0.4
const ESPERA_LANZAMIENTO: float = 0.65
const ESCENA_LATA: PackedScene = preload("res://jefes/jefeTres/Proyectiles/lataNico.tscn")
const SCRIPT_LATA = preload("res://jefes/jefeTres/Proyectiles/lataNico.gd")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var barra_vida: ProgressBar = $BarraVida
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var punto_lanzamiento: Marker2D = $PuntoLanzamiento
@onready var aviso_lata: Sprite2D = $PuntoLanzamiento/AvisoLata
@onready var proyectiles: Node2D = $Proyectiles

var vida: int = VIDA_MAXIMA
var jugador: Node2D
var direccion: float = 1.0
var estado: Estado = Estado.ESPERA
var tiempo_estado: float = 0.0
var espera_lanzamiento: float = 0.0
var objetivo_lanzamiento: Vector2


func _ready() -> void:
	actualizar_barra_vida()


func _physics_process(delta: float) -> void:
	tiempo_estado += delta
	if estado == Estado.MUERTO:
		sprite.modulate.a = 1.0 - clampf(tiempo_estado / DURACION_MUERTE, 0.0, 1.0)
		if tiempo_estado >= DURACION_MUERTE:
			queue_free()
		return
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	espera_lanzamiento = maxf(espera_lanzamiento - delta, 0.0)
	var velocidad_objetivo: float = 0.0
	match estado:
		Estado.ESPERA:
			if jugador_disponible():
				cambiar_estado(Estado.PERSEGUIR)
		Estado.PERSEGUIR:
			velocidad_objetivo = perseguir_jugador(delta)
		Estado.PREPARAR_ATAQUE:
			procesar_preparacion()
		Estado.RECUPERAR:
			if tiempo_estado >= DURACION_RECUPERACION:
				cambiar_estado(Estado.PERSEGUIR)
		Estado.HERIDO:
			if tiempo_estado >= DURACION_HERIDO:
				cambiar_estado(Estado.PERSEGUIR)
	velocity.x = move_toward(velocity.x, velocidad_objetivo, ACELERACION * delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	actualizar_animacion()


func jugador_disponible() -> bool:
	return is_instance_valid(jugador) and not jugador.is_queued_for_deletion() and jugador.get("muerto") != true


func perseguir_jugador(delta: float) -> float:
	if not jugador_disponible():
		cambiar_estado(Estado.ESPERA)
		return 0.0
	var diferencia: Vector2 = jugador.global_position - global_position
	var distancia: float = absf(diferencia.x)
	if not is_zero_approx(diferencia.x):
		direccion = signf(diferencia.x)
	if espera_lanzamiento == 0.0 and is_on_floor() and distancia <= ALCANCE_LANZAMIENTO and absf(diferencia.y) <= ALTURA_LANZAMIENTO:
		objetivo_lanzamiento = jugador.global_position
		cambiar_estado(Estado.PREPARAR_ATAQUE)
		return 0.0
	var margen: float = maxf(distancia - DISTANCIA_MINIMA, 0.0)
	var velocidad_segura: float = sqrt(2.0 * ACELERACION * margen)
	velocity.x = clampf(velocity.x, -margen / delta, margen / delta)
	return direccion * minf(VELOCIDAD, minf(velocidad_segura, margen / delta))


func procesar_preparacion() -> void:
	if not jugador_disponible():
		cambiar_estado(Estado.ESPERA)
	elif tiempo_estado >= DURACION_PREPARACION:
		lanzar_lata()
		espera_lanzamiento = ESPERA_LANZAMIENTO
		cambiar_estado(Estado.RECUPERAR)


func lanzar_lata() -> void:
	var lata := ESCENA_LATA.instantiate() as SCRIPT_LATA
	lata.position = proyectiles.to_local(punto_lanzamiento.global_position)
	lata.configurar(direccion, punto_lanzamiento.global_position, objetivo_lanzamiento, jugador)
	proyectiles.add_child(lata)


func cambiar_estado(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	tiempo_estado = 0.0
	aviso_lata.visible = estado == Estado.PREPARAR_ATAQUE


func actualizar_animacion() -> void:
	sprite.flip_h = direccion < 0.0
	punto_lanzamiento.position.x = 20.0 * direccion
	sprite.position.y = -46.0
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	match estado:
		Estado.PERSEGUIR:
			if is_on_floor() and absf(get_real_velocity().x) > 10.0:
				sprite.position.y -= absf(sin(tiempo_estado * 20.0)) * 3.0
				sprite.rotation = 0.07 * direccion
		Estado.PREPARAR_ATAQUE:
			sprite.rotation = -0.16 * direccion
			sprite.modulate = Color(0.93, 0.72, 1.0)
			aviso_lata.rotation = -0.45 * direccion
		Estado.RECUPERAR:
			sprite.rotation = 0.18 * direccion * (1.0 - tiempo_estado / DURACION_RECUPERACION)
		Estado.HERIDO:
			sprite.modulate = Color(1.0, 0.48, 0.48)
			sprite.rotation = -0.1 * direccion


func recibir_golpe(cantidad: int = 1) -> void:
	if estado == Estado.MUERTO or cantidad <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	actualizar_barra_vida()
	if vida == 0:
		morir()
	else:
		cambiar_estado(Estado.HERIDO)


func actualizar_barra_vida() -> void:
	barra_vida.max_value = VIDA_MAXIMA
	barra_vida.value = vida


func morir() -> void:
	if estado == Estado.MUERTO:
		return
	vida = 0
	velocity = Vector2.ZERO
	cambiar_estado(Estado.MUERTO)
	actualizar_barra_vida()
	colision.set_deferred("disabled", true)
	for lata in proyectiles.get_children():
		lata.queue_free()
	derrotado.emit()
