extends CharacterBody2D

signal derrotado

enum Estado {
	ESPERA,
	PERSEGUIR,
	SALTAR,
	PREPARAR_ATAQUE,
	ATACAR,
	RECUPERAR,
	HERIDO,
	MUERTO
}

enum TipoAtaque {
	BARRIDO_RASANTE,
	CAIDA_DIRIGIDA,
	DASH_AEREO
}

const VIDA_MAXIMA: int = 24
const CAPA_PLATAFORMAS: int = 4
const DANIO_BARRIDO: int = 10
const DANIO_CAIDA: int = 14
const DANIO_DASH: int = 12
const VELOCIDAD_CARRERA: float = 225.0
const VELOCIDAD_BARRIDO: float = 500.0
const VELOCIDAD_CAIDA: float = 620.0
const VELOCIDAD_DASH: float = 580.0
const VELOCIDAD_SALTO_HORIZONTAL: float = 255.0
const IMPULSO_SALTO_CRUZADO: float = -720.0
const IMPULSO_SALTO_CAIDA: float = -670.0
const DISTANCIA_MINIMA: float = 86.0
const DISTANCIA_SALTO_CRUZADO: float = 158.0
const DISTANCIA_ATAQUE: float = 340.0
const DISTANCIA_ACTIVACION: float = 700.0
const DIFERENCIA_PLATAFORMA: float = 76.0
const DURACION_BARRIDO: float = 0.36
const DURACION_DASH: float = 1.1
const DURACION_SALTO_CRUZADO: float = 1.65
const ESPERA_SALTO_CRUZADO: float = 1.2
const DURACION_PREPARACION_DASH: float = 0.28
const DISTANCIA_MINIMA_DASH: float = 180.0
const DISTANCIA_MAXIMA_DASH: float = 520.0
const DISTANCIA_PASAR_JUGADOR: float = 90.0
const ESPERA_DASH: float = 3.0
const ESPERA_REINTENTO_DASH: float = 0.8
const PROBABILIDAD_DASH: float = 0.4
const DURACION_PREPARACION_BARRIDO: float = 0.4
const DURACION_PREPARACION_CAIDA: float = 0.68
const DURACION_OBSERVACION_CAIDA: float = 0.28
const DURACION_RECUPERACION: float = 0.6
const DURACION_HERIDO: float = 0.32
const DURACION_MUERTE: float = 0.42

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var barra_vida: ProgressBar = $BarraVida
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var zona_ataque: Area2D = $ZonaAtaque
@onready var forma_zona_ataque: CollisionShape2D = $ZonaAtaque/CollisionShape2D
@onready var indicador_caida: Line2D = $IndicadorCaida
@onready var detector_suelo: RayCast2D = $DetectorSuelo

var vida: int = VIDA_MAXIMA
var velocidad: float = VELOCIDAD_CARRERA
var jugador: Node2D
var jugador_excluido_rayo: CollisionObject2D
var estado: Estado = Estado.ESPERA
var ataque_actual: TipoAtaque = TipoAtaque.BARRIDO_RASANTE
var tiempo_estado: float = 0.0
var tiempo_animacion: float = 0.0
var espera_dash: float = 0.0
var espera_ataque: float = 0.0
var espera_salto_cruzado: float = 0.0
var direccion: float = 1.0
var direccion_ataque: float = 1.0
var patron_ataque: int = 0
var objetivo_salto_x: float = 0.0
var objetivo_caida: Vector2 = Vector2.ZERO
var objetivo_dash_x: float = 0.0
var objetivo_caida_fijado: bool = false
var golpe_aplicado: bool = false
var zona_ataque_activa: bool = false
var muerto: bool = false
var jugador_excepcionado: PhysicsBody2D
var excepcion_jugador_preexistente: bool = false
var mascara_plataformas_anterior: bool = true
var atravesando_plataformas_hacia_arriba: bool = false
var atravesando_plataformas_hacia_abajo: bool = false
var destino_descenso_plataformas: float = 0.0
var tiempo_descenso_plataformas: float = 0.0


func _ready() -> void:
	actualizar_jugador()
	if is_instance_valid(detector_suelo):
		detector_suelo.exclude_parent = true
	if is_instance_valid(indicador_caida):
		indicador_caida.top_level = true
		indicador_caida.hide()
	actualizar_barra_vida()
	actualizar_animacion()


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		procesar_muerte(delta)
		return
	tiempo_animacion += delta
	actualizar_jugador()
	actualizar_relojes(delta)
	match estado:
		Estado.ESPERA:
			procesar_espera(delta)
		Estado.PERSEGUIR:
			perseguir_jugador(delta)
		Estado.SALTAR:
			procesar_salto_cruzado(delta)
		Estado.PREPARAR_ATAQUE:
			procesar_preparacion_ataque(delta)
		Estado.ATACAR:
			procesar_ataque(delta)
		Estado.RECUPERAR:
			procesar_recuperacion(delta)
		Estado.HERIDO:
			procesar_herido(delta)
	if muerto:
		return
	var dash_aereo_activo: bool = estado == Estado.ATACAR and ataque_actual == TipoAtaque.DASH_AEREO
	if not is_on_floor() and not dash_aereo_activo:
		velocity.y += get_gravity().y * delta
	actualizar_colision_plataformas(delta)
	move_and_slide()
	revisar_movimiento()
	actualizar_animacion()


func actualizar_jugador() -> void:
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	if not is_instance_valid(jugador) or not (jugador is CollisionObject2D):
		return
	var jugador_colision: CollisionObject2D = jugador as CollisionObject2D
	if jugador_excluido_rayo == jugador_colision:
		return
	if is_instance_valid(jugador_excluido_rayo):
		detector_suelo.remove_exception(jugador_excluido_rayo)
	detector_suelo.add_exception(jugador_colision)
	jugador_excluido_rayo = jugador_colision


func actualizar_relojes(delta: float) -> void:
	espera_dash = maxf(espera_dash - delta, 0.0)
	espera_ataque = maxf(espera_ataque - delta, 0.0)
	espera_salto_cruzado = maxf(espera_salto_cruzado - delta, 0.0)


func procesar_espera(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD_CARRERA * delta)
	if not is_instance_valid(jugador):
		return
	if global_position.distance_to(jugador.global_position) <= DISTANCIA_ACTIVACION:
		cambiar_estado(Estado.PERSEGUIR)


func perseguir_jugador(delta: float) -> void:
	if not is_instance_valid(jugador):
		velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD_CARRERA * delta)
		cambiar_estado(Estado.ESPERA)
		return
	var diferencia: Vector2 = jugador.global_position - global_position
	var distancia_x: float = absf(diferencia.x)
	if not is_zero_approx(diferencia.x):
		direccion = signf(diferencia.x)
	if is_on_floor() and diferencia.y > DIFERENCIA_PLATAFORMA and not atravesando_plataformas_hacia_abajo:
		iniciar_descenso_plataformas(jugador.global_position.y - 24.0)
	if is_on_floor() and not atravesando_plataformas_hacia_abajo and espera_salto_cruzado <= 0.0:
		if distancia_x <= DISTANCIA_SALTO_CRUZADO or is_on_wall() or diferencia.y < -DIFERENCIA_PLATAFORMA:
			if iniciar_salto_cruzado():
				return
	if intentar_dash_aleatorio(distancia_x):
		return
	if is_on_floor() and espera_ataque <= 0.0 and distancia_x <= DISTANCIA_ATAQUE and absf(diferencia.y) <= DIFERENCIA_PLATAFORMA:
		iniciar_siguiente_ataque(diferencia)
		return
	if distancia_x < DISTANCIA_MINIMA:
		moverse_hacia(-direccion, VELOCIDAD_CARRERA * 0.65)
		return
	moverse_hacia(direccion, velocidad)


func intentar_dash_aleatorio(distancia_x: float) -> bool:
	if not is_on_floor() or atravesando_plataformas_hacia_abajo or espera_dash > 0.0:
		return false
	if distancia_x < DISTANCIA_MINIMA_DASH or distancia_x > DISTANCIA_MAXIMA_DASH:
		return false
	if randf() < PROBABILIDAD_DASH:
		espera_dash = ESPERA_DASH
		iniciar_ataque(TipoAtaque.DASH_AEREO)
		return true
	espera_dash = ESPERA_REINTENTO_DASH
	return false


func moverse_hacia(sentido: float, velocidad_movimiento: float) -> void:
	if is_on_floor() and not hay_suelo_en_posicion(global_position.x + sentido * 34.0, global_position.y):
		velocity.x = 0.0
		return
	if is_on_wall() and sentido == direccion:
		velocity.x = 0.0
		return
	velocity.x = sentido * velocidad_movimiento


func iniciar_salto_cruzado() -> bool:
	var diferencia_x: float = jugador.global_position.x - global_position.x
	if not is_zero_approx(diferencia_x):
		direccion = signf(diferencia_x)
	objetivo_salto_x = jugador.global_position.x + direccion * 54.0
	if not hay_suelo_en_posicion(objetivo_salto_x, jugador.global_position.y):
		return false
	espera_salto_cruzado = ESPERA_SALTO_CRUZADO
	velocity.x = direccion * VELOCIDAD_SALTO_HORIZONTAL
	velocity.y = IMPULSO_SALTO_CRUZADO
	cambiar_estado(Estado.SALTAR)
	return true


func procesar_salto_cruzado(delta: float) -> void:
	tiempo_estado += delta
	var diferencia_x: float = objetivo_salto_x - global_position.x
	if is_on_wall() or absf(diferencia_x) <= 8.0:
		velocity.x = 0.0
	else:
		direccion = signf(diferencia_x)
		velocity.x = clampf(diferencia_x * 2.0, -VELOCIDAD_SALTO_HORIZONTAL, VELOCIDAD_SALTO_HORIZONTAL)
	if tiempo_estado >= DURACION_SALTO_CRUZADO:
		velocity.x = 0.0
		cambiar_estado(Estado.PERSEGUIR)


func iniciar_siguiente_ataque(diferencia: Vector2) -> void:
	var tipo: TipoAtaque = TipoAtaque.BARRIDO_RASANTE
	if diferencia.y > 35.0 or (patron_ataque % 2 == 1 and diferencia.y >= -35.0):
		tipo = TipoAtaque.CAIDA_DIRIGIDA
	patron_ataque += 1
	iniciar_ataque(tipo)


func iniciar_ataque(tipo: TipoAtaque) -> void:
	ataque_actual = tipo
	golpe_aplicado = false
	objetivo_caida_fijado = false
	espera_ataque = 1.8
	actualizar_zona_ataque(false)
	indicador_caida.hide()
	cambiar_estado(Estado.PREPARAR_ATAQUE)
	if ataque_actual == TipoAtaque.CAIDA_DIRIGIDA:
		velocity.y = IMPULSO_SALTO_CAIDA
	elif ataque_actual == TipoAtaque.DASH_AEREO:
		velocity.x = 0.0
		velocity.y = -140.0
	else:
		velocity.x = 0.0


func procesar_preparacion_ataque(delta: float) -> void:
	tiempo_estado += delta
	if ataque_actual == TipoAtaque.BARRIDO_RASANTE:
		velocity.x = 0.0
		if tiempo_estado >= DURACION_PREPARACION_BARRIDO:
			fijar_direccion_jugador()
			configurar_zona_ataque(ataque_actual)
			cambiar_estado(Estado.ATACAR)
		return
	if ataque_actual == TipoAtaque.DASH_AEREO:
		preparar_dash_aereo()
		return
	preparar_caida()
	if tiempo_estado >= DURACION_PREPARACION_CAIDA:
		if not objetivo_caida_fijado:
			terminar_ataque()
			return
		configurar_zona_ataque(ataque_actual)
		if objetivo_caida.y > global_position.y + DIFERENCIA_PLATAFORMA:
			iniciar_descenso_plataformas(objetivo_caida.y - 24.0)
		cambiar_estado(Estado.ATACAR)


func preparar_dash_aereo() -> void:
	if not is_instance_valid(jugador):
		terminar_ataque()
		return
	velocity.x = 0.0
	fijar_direccion_jugador()
	if tiempo_estado < DURACION_PREPARACION_DASH:
		return
	objetivo_dash_x = jugador.global_position.x + direccion_ataque * DISTANCIA_PASAR_JUGADOR
	desactivar_colision_jugador()
	configurar_zona_ataque(ataque_actual)
	velocity.x = direccion_ataque * VELOCIDAD_DASH
	velocity.y = 0.0
	actualizar_zona_ataque(true)
	cambiar_estado(Estado.ATACAR)


func preparar_caida() -> void:
	if not objetivo_caida_fijado and tiempo_estado < DURACION_OBSERVACION_CAIDA:
		if is_instance_valid(jugador):
			var diferencia_x: float = jugador.global_position.x - global_position.x
			if not is_zero_approx(diferencia_x):
				direccion = signf(diferencia_x)
			velocity.x = clampf(diferencia_x * 1.2, -120.0, 120.0)
		return
	if not objetivo_caida_fijado:
		if not is_instance_valid(jugador):
			velocity.x = 0.0
			return
		objetivo_caida = jugador.global_position
		objetivo_caida_fijado = hay_suelo_en_posicion(objetivo_caida.x, objetivo_caida.y)
		if objetivo_caida_fijado:
			indicador_caida.global_position = objetivo_caida
			indicador_caida.show()
	velocity.x = 0.0


func procesar_ataque(delta: float) -> void:
	tiempo_estado += delta
	if ataque_actual == TipoAtaque.BARRIDO_RASANTE:
		procesar_barrido()
	elif ataque_actual == TipoAtaque.CAIDA_DIRIGIDA:
		procesar_caida_dirigida()
	else:
		procesar_dash_aereo()


func procesar_barrido() -> void:
	var borde_sin_suelo: bool = is_on_floor() and not hay_suelo_en_posicion(global_position.x + direccion_ataque * 34.0, global_position.y)
	if is_on_wall() or tiempo_estado >= DURACION_BARRIDO or borde_sin_suelo:
		velocity.x = 0.0
		terminar_ataque()
		return
	velocity.x = direccion_ataque * VELOCIDAD_BARRIDO
	actualizar_zona_ataque(tiempo_estado >= 0.04 and tiempo_estado <= 0.29)


func procesar_caida_dirigida() -> void:
	if not objetivo_caida_fijado:
		velocity.x = 0.0
		terminar_ataque()
		return
	var diferencia_x: float = objetivo_caida.x - global_position.x
	if is_on_wall() or absf(diferencia_x) <= 8.0:
		velocity.x = 0.0
	else:
		velocity.x = clampf(diferencia_x * 1.8, -220.0, 220.0)
	velocity.y = VELOCIDAD_CAIDA
	var distancia_vertical: float = objetivo_caida.y - global_position.y
	actualizar_zona_ataque(distancia_vertical <= 36.0 and distancia_vertical >= -54.0)
	if tiempo_estado >= 1.25:
		terminar_ataque()


func procesar_dash_aereo() -> void:
	var distancia_hasta_objetivo: float = (objetivo_dash_x - global_position.x) * direccion_ataque
	var sin_suelo_delante: bool = not hay_suelo_en_posicion(global_position.x + direccion_ataque * 34.0, global_position.y)
	if tiempo_estado >= DURACION_DASH or distancia_hasta_objetivo <= 0.0 or is_on_wall() or sin_suelo_delante:
		terminar_ataque()
		return
	velocity.x = direccion_ataque * VELOCIDAD_DASH
	velocity.y = 0.0
	actualizar_zona_ataque(true)


func terminar_ataque() -> void:
	actualizar_zona_ataque(false)
	indicador_caida.hide()
	restaurar_colision_jugador()
	velocity.x = 0.0
	cambiar_estado(Estado.RECUPERAR)


func procesar_recuperacion(delta: float) -> void:
	tiempo_estado += delta
	velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD_BARRIDO * delta)
	if tiempo_estado >= DURACION_RECUPERACION:
		cambiar_estado(Estado.PERSEGUIR)


func procesar_herido(delta: float) -> void:
	tiempo_estado += delta
	velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD_BARRIDO * delta)
	if tiempo_estado >= DURACION_HERIDO:
		cambiar_estado(Estado.PERSEGUIR)


func revisar_movimiento() -> void:
	if estado == Estado.SALTAR and is_on_floor() and tiempo_estado > 0.18:
		velocity.x = 0.0
		cambiar_estado(Estado.PERSEGUIR)
	elif estado == Estado.ATACAR and ataque_actual == TipoAtaque.CAIDA_DIRIGIDA and is_on_floor() and tiempo_estado > 0.12:
		velocity.x = 0.0
		terminar_ataque()
	elif estado == Estado.ATACAR and ataque_actual == TipoAtaque.BARRIDO_RASANTE and is_on_wall():
		velocity.x = 0.0
		terminar_ataque()


func actualizar_colision_plataformas(delta: float) -> void:
	if atravesando_plataformas_hacia_abajo:
		tiempo_descenso_plataformas += delta
		if global_position.y >= destino_descenso_plataformas or tiempo_descenso_plataformas >= 1.3:
			set_collision_mask_value(CAPA_PLATAFORMAS, mascara_plataformas_anterior)
			atravesando_plataformas_hacia_abajo = false
		return
	if velocity.y < 0.0:
		if not atravesando_plataformas_hacia_arriba:
			mascara_plataformas_anterior = get_collision_mask_value(CAPA_PLATAFORMAS)
			set_collision_mask_value(CAPA_PLATAFORMAS, false)
			atravesando_plataformas_hacia_arriba = true
	elif atravesando_plataformas_hacia_arriba:
		set_collision_mask_value(CAPA_PLATAFORMAS, mascara_plataformas_anterior)
		atravesando_plataformas_hacia_arriba = false


func iniciar_descenso_plataformas(destino_y: float) -> void:
	if atravesando_plataformas_hacia_abajo:
		return
	if atravesando_plataformas_hacia_arriba:
		set_collision_mask_value(CAPA_PLATAFORMAS, mascara_plataformas_anterior)
		atravesando_plataformas_hacia_arriba = false
	mascara_plataformas_anterior = get_collision_mask_value(CAPA_PLATAFORMAS)
	if not mascara_plataformas_anterior:
		return
	set_collision_mask_value(CAPA_PLATAFORMAS, false)
	atravesando_plataformas_hacia_abajo = true
	tiempo_descenso_plataformas = 0.0
	destino_descenso_plataformas = destino_y
	velocity.y = maxf(velocity.y, 160.0)


func hay_suelo_en_posicion(posicion_x: float, posicion_y: float) -> bool:
	detector_suelo.position = Vector2(posicion_x - global_position.x, posicion_y - global_position.y - 100.0)
	detector_suelo.target_position = Vector2(0.0, 155.0)
	detector_suelo.force_raycast_update()
	return detector_suelo.is_colliding()


func configurar_zona_ataque(tipo: TipoAtaque) -> void:
	var forma: RectangleShape2D = forma_zona_ataque.shape as RectangleShape2D
	if tipo == TipoAtaque.BARRIDO_RASANTE:
		forma.size = Vector2(68.0, 18.0)
		zona_ataque.position = Vector2(direccion_ataque * 30.0, -8.0)
	elif tipo == TipoAtaque.CAIDA_DIRIGIDA:
		forma.size = Vector2(44.0, 44.0)
		zona_ataque.position = Vector2(0.0, -18.0)
	else:
		forma.size = Vector2(80.0, 48.0)
		zona_ataque.position = Vector2(direccion_ataque * 12.0, -44.0)


func actualizar_zona_ataque(activa: bool) -> void:
	if zona_ataque_activa == activa:
		return
	zona_ataque_activa = activa
	forma_zona_ataque.set_deferred("disabled", not activa)


func desactivar_colision_jugador() -> void:
	if not is_instance_valid(jugador) or not (jugador is PhysicsBody2D):
		return
	jugador_excepcionado = jugador as PhysicsBody2D
	excepcion_jugador_preexistente = get_collision_exceptions().has(jugador_excepcionado)
	if not excepcion_jugador_preexistente:
		add_collision_exception_with(jugador_excepcionado)


func restaurar_colision_jugador() -> void:
	if is_instance_valid(jugador_excepcionado) and not excepcion_jugador_preexistente:
		remove_collision_exception_with(jugador_excepcionado)
	jugador_excepcionado = null
	excepcion_jugador_preexistente = false


func _on_zona_ataque_body_entered(cuerpo: Node2D) -> void:
	if estado != Estado.ATACAR or golpe_aplicado or not cuerpo.is_in_group("jugador"):
		return
	if not cuerpo.has_method("recibir_golpe"):
		return
	golpe_aplicado = true
	if cuerpo.get("invulnerable") == true or cuerpo.get("muerto") == true:
		return
	var danio: int = DANIO_CAIDA
	match ataque_actual:
		TipoAtaque.BARRIDO_RASANTE:
			danio = DANIO_BARRIDO
		TipoAtaque.CAIDA_DIRIGIDA:
			danio = DANIO_CAIDA
		TipoAtaque.DASH_AEREO:
			danio = DANIO_DASH
	cuerpo.call("recibir_golpe", danio)


func fijar_direccion_jugador() -> void:
	if not is_instance_valid(jugador):
		return
	var diferencia_x: float = jugador.global_position.x - global_position.x
	if not is_zero_approx(diferencia_x):
		direccion = signf(diferencia_x)
	direccion_ataque = direccion


func cambiar_estado(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	tiempo_estado = 0.0


func actualizar_animacion() -> void:
	var nombre_animacion: String = "quieto"
	var escala: Vector2 = Vector2(0.58, 0.58)
	var posicion_y: float = -56.0
	var color: Color = Color.WHITE
	sprite.flip_h = direccion < 0.0
	sprite.rotation = 0.0
	match estado:
		Estado.ESPERA:
			nombre_animacion = "quieto"
		Estado.PERSEGUIR:
			if absf(velocity.x) > 10.0:
				nombre_animacion = "correr"
				if is_on_floor() and int(tiempo_animacion * 12.0) % 2 == 0:
					posicion_y -= 2.0
		Estado.SALTAR:
			nombre_animacion = "saltar"
			sprite.rotation = -0.08 * direccion
		Estado.PREPARAR_ATAQUE:
			nombre_animacion = "preparar_ataque"
			if ataque_actual == TipoAtaque.BARRIDO_RASANTE:
				escala = Vector2(0.69, 0.42)
				color = Color(1.0, 0.78, 0.58)
			elif ataque_actual == TipoAtaque.CAIDA_DIRIGIDA:
				escala = Vector2(0.54, 0.65)
				color = Color(0.8, 0.95, 1.0)
			else:
				escala = Vector2(0.68, 0.52)
				sprite.rotation = -0.14 * direccion
				color = Color(0.68, 0.9, 1.0)
		Estado.ATACAR:
			nombre_animacion = "atacar"
			if ataque_actual == TipoAtaque.BARRIDO_RASANTE:
				escala = Vector2(0.7, 0.48)
				color = Color(1.0, 0.88, 0.72)
			elif ataque_actual == TipoAtaque.CAIDA_DIRIGIDA:
				escala = Vector2(0.54, 0.65)
			else:
				escala = Vector2(0.72, 0.48)
				sprite.rotation = 0.12 * direccion
		Estado.RECUPERAR:
			nombre_animacion = "quieto"
		Estado.HERIDO:
			nombre_animacion = "herido"
			color = Color(1.0, 0.48, 0.48)
		Estado.MUERTO:
			nombre_animacion = "morir"
	if sprite.animation != nombre_animacion:
		sprite.play(nombre_animacion)
	sprite.scale = escala
	sprite.position.y = posicion_y
	sprite.modulate = color


func procesar_muerte(delta: float) -> void:
	tiempo_estado += delta
	var progreso: float = clampf(tiempo_estado / DURACION_MUERTE, 0.0, 1.0)
	sprite.play("morir")
	sprite.scale = Vector2(0.58, 0.58) * (1.0 - progreso * 0.45)
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0 - progreso)
	if tiempo_estado >= DURACION_MUERTE:
		queue_free()


func recibir_golpe(cantidad: int = 1) -> void:
	if muerto or vida <= 0 or cantidad <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	actualizar_barra_vida()
	if vida == 0:
		morir()
		return
	actualizar_zona_ataque(false)
	restaurar_colision_jugador()
	indicador_caida.hide()
	velocity.x = -direccion * 90.0
	cambiar_estado(Estado.HERIDO)


func actualizar_barra_vida() -> void:
	if not is_instance_valid(barra_vida):
		return
	barra_vida.min_value = 0.0
	barra_vida.max_value = VIDA_MAXIMA
	barra_vida.value = vida


func morir() -> void:
	if muerto:
		return
	muerto = true
	vida = 0
	velocity = Vector2.ZERO
	cambiar_estado(Estado.MUERTO)
	actualizar_zona_ataque(false)
	restaurar_colision_jugador()
	indicador_caida.hide()
	actualizar_barra_vida()
	if is_instance_valid(colision):
		colision.set_deferred("disabled", true)
	derrotado.emit()
