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
	MUERTO,
	TRANSICION_FASE
}

enum TipoAtaque {
	BARRIDO_RASANTE,
	CAIDA_DIRIGIDA,
	DASH_AEREO,
	REBOTE_PARED,
	BOMBA_EXPANSIVA,
	PROYECTIL_RAPIDO,
	RAFAGA_RADIAL
}

const ESCENA_PROYECTIL_TIAGO: PackedScene = preload("res://jefes/jefeDos/Proyectiles/proyectilTiago.tscn")
const VIDA_MAXIMA: int = 24
const CAPA_PLATAFORMAS: int = 4
const DANIO_BARRIDO: int = 18
const DANIO_CAIDA: int = 18
const DANIO_DASH: int = 18
const DANIO_REBOTE: int = 18
const DANIO_PROYECTIL_RAPIDO: int = 18
const DANIO_PROYECTIL_RADIAL: int = 16
const DANIO_ONDA_BOMBA: int = 18
const VELOCIDAD_CARRERA: float = 245.0
const VELOCIDAD_BARRIDO: float = 500.0
const VELOCIDAD_CAIDA: float = 620.0
const VELOCIDAD_DASH: float = 580.0
const VELOCIDAD_SALTO_HORIZONTAL: float = 280.0
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
const ESPERA_SALTO_CRUZADO: float = 0.9
const ESPERA_SALTO_FASE_DOS: float = 0.7
const DURACION_PREPARACION_DASH: float = 0.28
const DURACION_PREPARACION_REBOTE: float = 0.32
const DURACION_MAXIMA_REBOTE: float = 1.8
const IMPULSO_REBOTE_PARED: float = -500.0
const VELOCIDAD_MAXIMA_REBOTE: float = 390.0
const DISTANCIA_MINIMA_DASH: float = 160.0
const DISTANCIA_MAXIMA_DASH: float = 520.0
const DISTANCIA_PASAR_JUGADOR: float = 90.0
const ESPERA_DASH: float = 2.5
const ESPERA_DASH_FASE_DOS: float = 1.9
const ESPERA_REINTENTO_DASH: float = 0.8
const PROBABILIDAD_DASH: float = 0.5
const DISTANCIA_MAXIMA_REBOTE: float = 340.0
const DISTANCIA_PROYECTIL_RAPIDO: float = 440.0
const DISTANCIA_ATAQUE_CERCANO: float = 210.0
const DISTANCIA_BOMBA_MINIMA: float = 100.0
const DISTANCIA_BOMBA_MAXIMA: float = 280.0
const DISTANCIA_RADIAL_MINIMA: float = 120.0
const DISTANCIA_RADIAL_MAXIMA: float = 420.0
const DURACION_PREPARACION_BARRIDO: float = 0.4
const DURACION_PREPARACION_BARRIDO_CERCANO: float = 0.28
const DURACION_PREPARACION_CAIDA: float = 0.68
const DURACION_OBSERVACION_CAIDA: float = 0.28
const DURACION_PREPARACION_BOMBA: float = 0.55
const DURACION_PREPARACION_BOMBA_CERCANA: float = 0.42
const DURACION_OBSERVACION_BOMBA: float = 0.25
const DURACION_PREPARACION_PROYECTIL: float = 0.24
const DURACION_PREPARACION_RADIAL: float = 0.34
const DURACION_RETIRADA_RADIAL: float = 0.42
const DURACION_BOMBA_MAXIMA: float = 1.8
const DURACION_RECUPERACION: float = 0.7
const DURACION_HERIDO: float = 0.32
const DURACION_MUERTE: float = 0.42
const DURACION_TRANSICION_FASE: float = 0.6
const MULTIPLICADOR_VELOCIDAD_FASE_DOS: float = 1.15
const MULTIPLICADOR_PREPARACION_FASE_DOS: float = 0.85
const ESPERA_ATAQUE_NORMAL: float = 1.2
const ESPERA_ATAQUE_FASE_DOS: float = 0.95
const ESPERA_ATAQUE_CERCANO: float = 0.72
const ESPERA_ATAQUE_CERCANO_FASE_DOS: float = 0.55
const ESPERA_BOMBA_NORMAL: float = 4.5
const ESPERA_BOMBA_FASE_DOS: float = 3.5
const ESPERA_PROYECTIL_NORMAL: float = 2.4
const ESPERA_PROYECTIL_FASE_DOS: float = 1.8
const ESPERA_RADIAL_NORMAL: float = 7.0
const ESPERA_RADIAL_FASE_DOS: float = 5.5
const IMPULSO_SALTO_BOMBA: float = -720.0
const VELOCIDAD_CAIDA_BOMBA: float = 900.0
const VELOCIDAD_PROYECTIL_RAPIDO: float = 700.0
const VELOCIDAD_PROYECTIL_RADIAL: float = 180.0
const VELOCIDAD_ONDA_BOMBA: float = 360.0
const VELOCIDAD_RETIRADA_RADIAL: float = 330.0
const CANTIDAD_PROYECTILES_RADIALES: int = 24

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var barra_vida: ProgressBar = $BarraVida
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var zona_ataque: Area2D = $ZonaAtaque
@onready var forma_zona_ataque: CollisionShape2D = $ZonaAtaque/CollisionShape2D
@onready var indicador_caida: Line2D = $IndicadorCaida
@onready var detector_suelo: RayCast2D = $DetectorSuelo
@onready var detector_pared_izquierda: RayCast2D = $DetectorParedIzquierda
@onready var detector_pared_derecha: RayCast2D = $DetectorParedDerecha

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
var espera_bomba: float = 0.0
var espera_proyectil: float = 0.0
var espera_radial: float = 7.0
var direccion: float = 1.0
var direccion_ataque: float = 1.0
var ataque_cercano: bool = false
var patron_ataque: int = 0
var ultima_accion_ofensiva: TipoAtaque = TipoAtaque.CAIDA_DIRIGIDA
var acciones_cadena: int = 0
var ataque_pendiente: TipoAtaque = TipoAtaque.BARRIDO_RASANTE
var hay_ataque_pendiente: bool = false
var objetivo_salto_x: float = 0.0
var objetivo_caida: Vector2 = Vector2.ZERO
var objetivo_dash_x: float = 0.0
var objetivo_rebote: Vector2 = Vector2.ZERO
var direccion_rebote: float = 0.0
var velocidad_horizontal_rebote: float = 0.0
var objetivo_bomba: Vector2 = Vector2.ZERO
var objetivo_proyectil: Vector2 = Vector2.ZERO
var objetivo_caida_fijado: bool = false
var objetivo_bomba_fijado: bool = false
var bomba_detonada: bool = false
var proyectil_lanzado: bool = false
var rafaga_lanzada: bool = false
var golpe_aplicado: bool = false
var zona_ataque_activa: bool = false
var muerto: bool = false
var segunda_fase: bool = false
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
	detector_pared_izquierda.exclude_parent = true
	detector_pared_derecha.exclude_parent = true
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
		Estado.TRANSICION_FASE:
			procesar_transicion_fase(delta)
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
		detector_pared_izquierda.remove_exception(jugador_excluido_rayo)
		detector_pared_derecha.remove_exception(jugador_excluido_rayo)
	detector_suelo.add_exception(jugador_colision)
	detector_pared_izquierda.add_exception(jugador_colision)
	detector_pared_derecha.add_exception(jugador_colision)
	jugador_excluido_rayo = jugador_colision


func actualizar_relojes(delta: float) -> void:
	espera_dash = maxf(espera_dash - delta, 0.0)
	espera_ataque = maxf(espera_ataque - delta, 0.0)
	espera_salto_cruzado = maxf(espera_salto_cruzado - delta, 0.0)
	espera_bomba = maxf(espera_bomba - delta, 0.0)
	espera_proyectil = maxf(espera_proyectil - delta, 0.0)
	espera_radial = maxf(espera_radial - delta, 0.0)


func ajustar_velocidad(valor: float) -> float:
	if segunda_fase:
		return valor * MULTIPLICADOR_VELOCIDAD_FASE_DOS
	return valor


func ajustar_preparacion(duracion: float) -> float:
	if segunda_fase:
		return duracion * MULTIPLICADOR_PREPARACION_FASE_DOS
	return duracion


func obtener_espera_ataque() -> float:
	if ataque_cercano:
		if segunda_fase:
			return ESPERA_ATAQUE_CERCANO_FASE_DOS
		return ESPERA_ATAQUE_CERCANO
	if segunda_fase:
		return ESPERA_ATAQUE_FASE_DOS
	return ESPERA_ATAQUE_NORMAL


func obtener_preparacion_barrido() -> float:
	var duracion: float = DURACION_PREPARACION_BARRIDO
	if ataque_cercano:
		duracion = DURACION_PREPARACION_BARRIDO_CERCANO
	return ajustar_preparacion(duracion)


func obtener_espera_dash() -> float:
	if segunda_fase:
		return ESPERA_DASH_FASE_DOS
	return ESPERA_DASH


func obtener_espera_salto_cruzado() -> float:
	if segunda_fase:
		return ESPERA_SALTO_FASE_DOS
	return ESPERA_SALTO_CRUZADO


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
	if is_on_floor() and not atravesando_plataformas_hacia_abajo and espera_ataque <= 0.0:
		if distancia_x >= DISTANCIA_PROYECTIL_RAPIDO and espera_proyectil <= 0.0:
			iniciar_ataque(TipoAtaque.PROYECTIL_RAPIDO)
			return
		if distancia_x >= DISTANCIA_RADIAL_MINIMA and distancia_x <= DISTANCIA_RADIAL_MAXIMA and espera_radial <= 0.0:
			iniciar_ataque(TipoAtaque.RAFAGA_RADIAL)
			return
		if distancia_x >= DISTANCIA_BOMBA_MINIMA and distancia_x <= DISTANCIA_BOMBA_MAXIMA and absf(diferencia.y) <= DIFERENCIA_PLATAFORMA and espera_bomba <= 0.0:
			iniciar_ataque(TipoAtaque.BOMBA_EXPANSIVA)
			return
		if patron_ataque == 2 and iniciar_rebote_pared(diferencia, distancia_x):
			return
		if espera_salto_cruzado <= 0.0:
			if distancia_x <= DISTANCIA_SALTO_CRUZADO or is_on_wall() or diferencia.y < -DIFERENCIA_PLATAFORMA:
				if iniciar_salto_cruzado(diferencia, distancia_x):
					return
	if intentar_dash_aleatorio(distancia_x):
		return
	if is_on_floor() and espera_ataque <= 0.0 and distancia_x <= DISTANCIA_ATAQUE and absf(diferencia.y) <= DIFERENCIA_PLATAFORMA:
		iniciar_siguiente_ataque(diferencia)
		return
	if distancia_x < DISTANCIA_MINIMA:
		moverse_hacia(-direccion, VELOCIDAD_CARRERA * 0.9)
		return
	moverse_hacia(direccion, velocidad)


func intentar_dash_aleatorio(distancia_x: float) -> bool:
	if not is_on_floor() or atravesando_plataformas_hacia_abajo or espera_dash > 0.0 or espera_ataque > 0.0:
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
	velocity.x = sentido * ajustar_velocidad(velocidad_movimiento)


func iniciar_salto_cruzado(diferencia: Vector2, distancia_x: float) -> bool:
	var diferencia_x: float = jugador.global_position.x - global_position.x
	if not is_zero_approx(diferencia_x):
		direccion = signf(diferencia_x)
	objetivo_salto_x = jugador.global_position.x + direccion * 54.0
	if not hay_suelo_en_posicion(objetivo_salto_x, jugador.global_position.y):
		return false
	espera_salto_cruzado = obtener_espera_salto_cruzado()
	ataque_pendiente = elegir_ataque_encadenado(diferencia, distancia_x)
	hay_ataque_pendiente = true
	acciones_cadena = 1
	velocity.x = direccion * ajustar_velocidad(VELOCIDAD_SALTO_HORIZONTAL)
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
		var velocidad_salto: float = ajustar_velocidad(VELOCIDAD_SALTO_HORIZONTAL)
		velocity.x = clampf(diferencia_x * 2.0, -velocidad_salto, velocidad_salto)
	if tiempo_estado >= DURACION_SALTO_CRUZADO:
		velocity.x = 0.0


func iniciar_siguiente_ataque(diferencia: Vector2) -> void:
	var distancia_x: float = absf(diferencia.x)
	iniciar_ataque(elegir_ataque_encadenado(diferencia, distancia_x))


func elegir_ataque_encadenado(diferencia: Vector2, distancia_x: float) -> TipoAtaque:
	if segunda_fase and patron_ataque == 1 and espera_dash <= 0.0:
		if distancia_x >= DISTANCIA_MINIMA_DASH and distancia_x <= DISTANCIA_MAXIMA_DASH:
			return TipoAtaque.DASH_AEREO
	if diferencia.y > 35.0 and ultima_accion_ofensiva != TipoAtaque.CAIDA_DIRIGIDA:
		return TipoAtaque.CAIDA_DIRIGIDA
	if ultima_accion_ofensiva == TipoAtaque.BARRIDO_RASANTE:
		return TipoAtaque.CAIDA_DIRIGIDA
	return TipoAtaque.BARRIDO_RASANTE


func iniciar_rebote_pared(diferencia: Vector2, distancia_x: float) -> bool:
	if distancia_x > DISTANCIA_MAXIMA_REBOTE or distancia_x < 80.0:
		return false
	if not is_instance_valid(jugador):
		return false
	var sentido_salida: float = obtener_direccion_salida_pared(diferencia.x)
	if is_zero_approx(sentido_salida):
		return false
	var posicion_objetivo: Vector2 = jugador.global_position
	if not hay_suelo_en_posicion(posicion_objetivo.x, posicion_objetivo.y):
		return false
	var gravedad: float = maxf(get_gravity().y, 1.0)
	var tiempo_vuelo: float = absf(IMPULSO_REBOTE_PARED) * 2.0 / gravedad
	var velocidad_horizontal: float = (posicion_objetivo.x - global_position.x) / tiempo_vuelo
	if velocidad_horizontal * sentido_salida <= 0.0 or absf(velocidad_horizontal) < 80.0:
		return false
	direccion_rebote = sentido_salida
	velocidad_horizontal_rebote = clampf(velocidad_horizontal, -VELOCIDAD_MAXIMA_REBOTE, VELOCIDAD_MAXIMA_REBOTE)
	objetivo_rebote = posicion_objetivo
	ataque_pendiente = elegir_ataque_rebote(distancia_x)
	hay_ataque_pendiente = true
	direccion_ataque = direccion_rebote
	direccion = direccion_rebote
	iniciar_ataque(TipoAtaque.REBOTE_PARED)
	return true


func elegir_ataque_rebote(distancia_x: float) -> TipoAtaque:
	if segunda_fase and distancia_x >= DISTANCIA_MINIMA_DASH and espera_dash <= 0.0:
		return TipoAtaque.DASH_AEREO
	if ultima_accion_ofensiva == TipoAtaque.BARRIDO_RASANTE:
		return TipoAtaque.CAIDA_DIRIGIDA
	return TipoAtaque.BARRIDO_RASANTE


func obtener_direccion_salida_pared(diferencia_x: float) -> float:
	if diferencia_x > 0.0:
		return obtener_normal_pared(detector_pared_izquierda)
	if diferencia_x < 0.0:
		return obtener_normal_pared(detector_pared_derecha)
	return 0.0


func obtener_normal_pared(detector: RayCast2D) -> float:
	detector.force_raycast_update()
	if not detector.is_colliding():
		return 0.0
	var superficie: Object = detector.get_collider()
	if not (superficie is StaticBody2D or superficie is TileMapLayer):
		return 0.0
	var normal: Vector2 = detector.get_collision_normal()
	if absf(normal.x) < 0.9:
		return 0.0
	return signf(normal.x)


func iniciar_ataque(tipo: TipoAtaque) -> void:
	acciones_cadena = mini(acciones_cadena + 1, 2)
	ataque_actual = tipo
	golpe_aplicado = false
	objetivo_caida_fijado = false
	ataque_cercano = is_instance_valid(jugador) and absf(jugador.global_position.x - global_position.x) <= DISTANCIA_ATAQUE_CERCANO
	espera_ataque = obtener_espera_ataque()
	if tipo == TipoAtaque.DASH_AEREO:
		espera_dash = obtener_espera_dash()
	elif tipo == TipoAtaque.BOMBA_EXPANSIVA:
		espera_bomba = ESPERA_BOMBA_FASE_DOS if segunda_fase else ESPERA_BOMBA_NORMAL
		objetivo_bomba_fijado = false
		bomba_detonada = false
	elif tipo == TipoAtaque.PROYECTIL_RAPIDO:
		espera_proyectil = ESPERA_PROYECTIL_FASE_DOS if segunda_fase else ESPERA_PROYECTIL_NORMAL
		proyectil_lanzado = false
		if is_instance_valid(jugador):
			objetivo_proyectil = jugador.global_position
			fijar_direccion_jugador()
	elif tipo == TipoAtaque.RAFAGA_RADIAL:
		espera_radial = ESPERA_RADIAL_FASE_DOS if segunda_fase else ESPERA_RADIAL_NORMAL
		rafaga_lanzada = false
		if is_instance_valid(jugador):
			var diferencia_x: float = jugador.global_position.x - global_position.x
			if not is_zero_approx(diferencia_x):
				direccion_ataque = -signf(diferencia_x)
			else:
				direccion_ataque = -direccion
	if tipo != TipoAtaque.REBOTE_PARED:
		ultima_accion_ofensiva = tipo
	actualizar_zona_ataque(false)
	indicador_caida.hide()
	cambiar_estado(Estado.PREPARAR_ATAQUE)
	if ataque_actual == TipoAtaque.CAIDA_DIRIGIDA:
		velocity.y = IMPULSO_SALTO_CAIDA
	elif ataque_actual == TipoAtaque.DASH_AEREO:
		velocity.x = 0.0
		velocity.y = -140.0
	elif ataque_actual == TipoAtaque.REBOTE_PARED:
		velocity = Vector2.ZERO
	elif ataque_actual == TipoAtaque.BOMBA_EXPANSIVA:
		velocity.x = 0.0
		velocity.y = IMPULSO_SALTO_BOMBA
	else:
		velocity.x = 0.0


func procesar_preparacion_ataque(delta: float) -> void:
	tiempo_estado += delta
	if ataque_actual == TipoAtaque.BARRIDO_RASANTE:
		velocity.x = 0.0
		if tiempo_estado >= obtener_preparacion_barrido():
			fijar_direccion_jugador()
			configurar_zona_ataque(ataque_actual)
			cambiar_estado(Estado.ATACAR)
		return
	if ataque_actual == TipoAtaque.DASH_AEREO:
		preparar_dash_aereo()
		return
	if ataque_actual == TipoAtaque.REBOTE_PARED:
		preparar_rebote_pared()
		return
	if ataque_actual == TipoAtaque.BOMBA_EXPANSIVA:
		preparar_bomba_expansiva()
		return
	if ataque_actual == TipoAtaque.PROYECTIL_RAPIDO:
		velocity.x = 0.0
		if tiempo_estado >= ajustar_preparacion(DURACION_PREPARACION_PROYECTIL):
			cambiar_estado(Estado.ATACAR)
		return
	if ataque_actual == TipoAtaque.RAFAGA_RADIAL:
		velocity.x = 0.0
		if tiempo_estado >= ajustar_preparacion(DURACION_PREPARACION_RADIAL):
			cambiar_estado(Estado.ATACAR)
		return
	preparar_caida()
	if tiempo_estado >= ajustar_preparacion(DURACION_PREPARACION_CAIDA):
		if not objetivo_caida_fijado:
			terminar_ataque()
			return
		configurar_zona_ataque(ataque_actual)
		if objetivo_caida.y > global_position.y + DIFERENCIA_PLATAFORMA:
			iniciar_descenso_plataformas(objetivo_caida.y - 24.0)
		cambiar_estado(Estado.ATACAR)


func preparar_bomba_expansiva() -> void:
	if not objetivo_bomba_fijado and tiempo_estado < DURACION_OBSERVACION_BOMBA:
		if is_instance_valid(jugador):
			var diferencia_x: float = jugador.global_position.x - global_position.x
			velocity.x = clampf(diferencia_x * 1.2, -220.0, 220.0)
			indicador_caida.global_position = jugador.global_position
			indicador_caida.show()
		else:
			velocity.x = 0.0
		return
	if not objetivo_bomba_fijado:
		if not is_instance_valid(jugador):
			terminar_ataque()
			return
		objetivo_bomba = jugador.global_position
		objetivo_bomba_fijado = hay_suelo_en_posicion(objetivo_bomba.x, objetivo_bomba.y)
		if not objetivo_bomba_fijado:
			terminar_ataque()
			return
		indicador_caida.global_position = objetivo_bomba
		indicador_caida.show()
	var diferencia_objetivo: float = objetivo_bomba.x - global_position.x
	velocity.x = clampf(diferencia_objetivo, -240.0, 240.0)
	var duracion_preparacion: float = DURACION_PREPARACION_BOMBA
	if ataque_cercano:
		duracion_preparacion = DURACION_PREPARACION_BOMBA_CERCANA
	if tiempo_estado < ajustar_preparacion(duracion_preparacion):
		return
	velocity.x = ajustar_velocidad(clampf(diferencia_objetivo * 1.5, -380.0, 380.0))
	velocity.y = ajustar_velocidad(VELOCIDAD_CAIDA_BOMBA)
	cambiar_estado(Estado.ATACAR)


func preparar_dash_aereo() -> void:
	if not is_instance_valid(jugador):
		terminar_ataque()
		return
	velocity.x = 0.0
	fijar_direccion_jugador()
	if tiempo_estado < ajustar_preparacion(DURACION_PREPARACION_DASH):
		return
	objetivo_dash_x = jugador.global_position.x + direccion_ataque * DISTANCIA_PASAR_JUGADOR
	desactivar_colision_jugador()
	configurar_zona_ataque(ataque_actual)
	velocity.x = direccion_ataque * ajustar_velocidad(VELOCIDAD_DASH)
	velocity.y = 0.0
	actualizar_zona_ataque(true)
	cambiar_estado(Estado.ATACAR)


func preparar_rebote_pared() -> void:
	if not hay_pared_en_direccion(direccion_rebote) or not hay_suelo_en_posicion(objetivo_rebote.x, objetivo_rebote.y):
		cancelar_rebote_pared()
		return
	velocity = Vector2.ZERO
	if tiempo_estado < ajustar_preparacion(DURACION_PREPARACION_REBOTE):
		return
	velocity.x = ajustar_velocidad(velocidad_horizontal_rebote)
	velocity.y = IMPULSO_REBOTE_PARED
	configurar_zona_ataque(ataque_actual)
	cambiar_estado(Estado.ATACAR)


func cancelar_rebote_pared() -> void:
	if not hay_ataque_pendiente:
		terminar_ataque()
		return
	var ataque_reemplazo: TipoAtaque = ataque_pendiente
	hay_ataque_pendiente = false
	acciones_cadena = 0
	iniciar_ataque(ataque_reemplazo)


func hay_pared_en_direccion(sentido: float) -> bool:
	var normal: float = 0.0
	if sentido > 0.0:
		normal = obtener_normal_pared(detector_pared_izquierda)
	elif sentido < 0.0:
		normal = obtener_normal_pared(detector_pared_derecha)
	return not is_zero_approx(normal) and signf(normal) == sentido


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
	elif ataque_actual == TipoAtaque.DASH_AEREO:
		procesar_dash_aereo()
	elif ataque_actual == TipoAtaque.REBOTE_PARED:
		procesar_rebote_pared()
	elif ataque_actual == TipoAtaque.BOMBA_EXPANSIVA:
		procesar_bomba_expansiva()
	elif ataque_actual == TipoAtaque.PROYECTIL_RAPIDO:
		procesar_proyectil_rapido()
	else:
		procesar_rafaga_radial()


func procesar_barrido() -> void:
	var borde_sin_suelo: bool = is_on_floor() and not hay_suelo_en_posicion(global_position.x + direccion_ataque * 34.0, global_position.y)
	if is_on_wall() or tiempo_estado >= DURACION_BARRIDO or borde_sin_suelo:
		velocity.x = 0.0
		terminar_ataque()
		return
	velocity.x = direccion_ataque * ajustar_velocidad(VELOCIDAD_BARRIDO)
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
		velocity.x = ajustar_velocidad(clampf(diferencia_x * 1.8, -220.0, 220.0))
	velocity.y = ajustar_velocidad(VELOCIDAD_CAIDA)
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
	velocity.x = direccion_ataque * ajustar_velocidad(VELOCIDAD_DASH)
	velocity.y = 0.0
	actualizar_zona_ataque(true)


func procesar_rebote_pared() -> void:
	var distancia_objetivo_x: float = (objetivo_rebote.x - global_position.x) * direccion_rebote
	if tiempo_estado >= DURACION_MAXIMA_REBOTE:
		terminar_ataque()
		return
	if is_on_wall() or distancia_objetivo_x <= 0.0:
		velocity.x = 0.0
	else:
		velocity.x = ajustar_velocidad(velocidad_horizontal_rebote)
	actualizar_zona_ataque(tiempo_estado >= 0.04 and tiempo_estado <= 0.42)


func procesar_bomba_expansiva() -> void:
	if not objetivo_bomba_fijado or tiempo_estado >= DURACION_BOMBA_MAXIMA:
		terminar_ataque()
		return
	var diferencia_x: float = objetivo_bomba.x - global_position.x
	if is_on_wall() or absf(diferencia_x) <= 8.0:
		velocity.x = 0.0
	else:
		velocity.x = ajustar_velocidad(clampf(diferencia_x * 1.5, -300.0, 300.0))
	velocity.y = ajustar_velocidad(VELOCIDAD_CAIDA_BOMBA)


func procesar_proyectil_rapido() -> void:
	if proyectil_lanzado:
		return
	proyectil_lanzado = true
	var origen: Vector2 = global_position + Vector2(direccion_ataque * 12.0, -44.0)
	var direccion_proyectil: Vector2 = (objetivo_proyectil - origen).normalized()
	if direccion_proyectil == Vector2.ZERO:
		direccion_proyectil = Vector2(direccion_ataque, 0.0)
	crear_proyectil(direccion_proyectil, ajustar_velocidad(VELOCIDAD_PROYECTIL_RAPIDO), DANIO_PROYECTIL_RAPIDO, Color(0.35, 0.88, 0.92), Vector2.ONE, origen)
	terminar_ataque()


func procesar_rafaga_radial() -> void:
	if tiempo_estado < DURACION_RETIRADA_RADIAL:
		var sin_suelo_delante: bool = is_on_floor() and not hay_suelo_en_posicion(global_position.x + direccion_ataque * 36.0, global_position.y)
		if is_on_wall() or sin_suelo_delante:
			velocity.x = 0.0
		else:
			velocity.x = direccion_ataque * ajustar_velocidad(VELOCIDAD_RETIRADA_RADIAL)
		return
	velocity.x = 0.0
	if not rafaga_lanzada:
		rafaga_lanzada = true
		lanzar_rafaga_radial()
	terminar_ataque()


func lanzar_rafaga_radial() -> void:
	var origen: Vector2 = global_position + Vector2(0.0, -42.0)
	for indice in range(CANTIDAD_PROYECTILES_RADIALES):
		var angulo: float = TAU * float(indice) / float(CANTIDAD_PROYECTILES_RADIALES)
		var direccion_proyectil: Vector2 = Vector2.from_angle(angulo)
		crear_proyectil(direccion_proyectil, ajustar_velocidad(VELOCIDAD_PROYECTIL_RADIAL), DANIO_PROYECTIL_RADIAL, Color(0.56, 0.82, 1.0), Vector2(0.75, 0.75), origen)


func lanzar_ondas_bomba() -> void:
	var origen_izquierda: Vector2 = global_position + Vector2(-12.0, -8.0)
	var origen_derecha: Vector2 = global_position + Vector2(12.0, -8.0)
	crear_proyectil(Vector2.LEFT, ajustar_velocidad(VELOCIDAD_ONDA_BOMBA), DANIO_ONDA_BOMBA, Color(1.0, 0.52, 0.24), Vector2(1.5, 0.7), origen_izquierda)
	crear_proyectil(Vector2.RIGHT, ajustar_velocidad(VELOCIDAD_ONDA_BOMBA), DANIO_ONDA_BOMBA, Color(1.0, 0.52, 0.24), Vector2(1.5, 0.7), origen_derecha)


func crear_proyectil(direccion_proyectil: Vector2, rapidez: float, danio: int, color: Color, escala: Vector2, origen: Vector2) -> void:
	var proyectil: Area2D = ESCENA_PROYECTIL_TIAGO.instantiate() as Area2D
	if not is_instance_valid(proyectil):
		return
	proyectil.call("configurar", direccion_proyectil, rapidez, danio, color, escala)
	add_child(proyectil)
	proyectil.global_position = origen


func terminar_ataque() -> void:
	actualizar_zona_ataque(false)
	indicador_caida.hide()
	restaurar_colision_jugador()
	velocity.x = 0.0
	finalizar_cadena()
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


func procesar_transicion_fase(delta: float) -> void:
	tiempo_estado += delta
	velocity.x = move_toward(velocity.x, 0.0, VELOCIDAD_CARRERA * delta)
	if tiempo_estado >= DURACION_TRANSICION_FASE:
		cambiar_estado(Estado.PERSEGUIR)


func iniciar_segunda_fase() -> void:
	if segunda_fase:
		return
	segunda_fase = true
	acciones_cadena = 0
	hay_ataque_pendiente = false
	actualizar_zona_ataque(false)
	restaurar_colision_jugador()
	indicador_caida.hide()
	velocity.x = 0.0
	cambiar_estado(Estado.TRANSICION_FASE)


func revisar_movimiento() -> void:
	if estado == Estado.SALTAR and is_on_floor() and tiempo_estado > 0.18:
		velocity.x = 0.0
		iniciar_ataque_pendiente()
	elif estado == Estado.ATACAR and ataque_actual == TipoAtaque.BOMBA_EXPANSIVA and is_on_floor() and tiempo_estado > 0.12:
		velocity.x = 0.0
		if not bomba_detonada:
			bomba_detonada = true
			lanzar_ondas_bomba()
		terminar_ataque()
	elif estado == Estado.ATACAR and ataque_actual == TipoAtaque.REBOTE_PARED and is_on_floor() and tiempo_estado > 0.18:
		velocity.x = 0.0
		iniciar_ataque_pendiente()
	elif estado == Estado.ATACAR and ataque_actual == TipoAtaque.CAIDA_DIRIGIDA and is_on_floor() and tiempo_estado > 0.12:
		velocity.x = 0.0
		terminar_ataque()
	elif estado == Estado.ATACAR and ataque_actual == TipoAtaque.BARRIDO_RASANTE and is_on_wall():
		velocity.x = 0.0
		terminar_ataque()


func iniciar_ataque_pendiente() -> void:
	if hay_ataque_pendiente and acciones_cadena < 2:
		var tipo: TipoAtaque = ataque_pendiente
		hay_ataque_pendiente = false
		iniciar_ataque(tipo)
		return
	finalizar_cadena()
	cambiar_estado(Estado.RECUPERAR)


func finalizar_cadena() -> void:
	acciones_cadena = 0
	hay_ataque_pendiente = false
	patron_ataque = (patron_ataque + 1) % 3


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
		TipoAtaque.REBOTE_PARED:
			danio = DANIO_REBOTE
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
	var color: Color = Color(0.82, 1.0, 0.78) if segunda_fase else Color.WHITE
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
			elif ataque_actual == TipoAtaque.DASH_AEREO:
				escala = Vector2(0.68, 0.52)
				sprite.rotation = -0.14 * direccion
				color = Color(0.68, 0.9, 1.0)
			elif ataque_actual == TipoAtaque.REBOTE_PARED:
				escala = Vector2(0.55, 0.68)
				sprite.rotation = -0.12 * direccion_rebote
				color = Color(1.0, 0.88, 0.45)
			elif ataque_actual == TipoAtaque.BOMBA_EXPANSIVA:
				escala = Vector2(0.62, 0.72)
				color = Color(1.0, 0.56, 0.26)
			elif ataque_actual == TipoAtaque.PROYECTIL_RAPIDO:
				escala = Vector2(0.66, 0.58)
				sprite.rotation = -0.1 * direccion_ataque
				color = Color(0.36, 0.88, 0.92)
			else:
				escala = Vector2(0.76, 0.68)
				sprite.rotation = -0.08 * direccion_ataque
				color = Color(0.58, 0.82, 1.0)
		Estado.ATACAR:
			nombre_animacion = "atacar"
			if ataque_actual == TipoAtaque.BARRIDO_RASANTE:
				escala = Vector2(0.7, 0.48)
				color = Color(1.0, 0.88, 0.72)
			elif ataque_actual == TipoAtaque.CAIDA_DIRIGIDA:
				escala = Vector2(0.54, 0.65)
			elif ataque_actual == TipoAtaque.DASH_AEREO:
				escala = Vector2(0.72, 0.48)
				sprite.rotation = 0.12 * direccion
			elif ataque_actual == TipoAtaque.REBOTE_PARED:
				escala = Vector2(0.62, 0.54)
				sprite.rotation = 0.08 * direccion_rebote
			elif ataque_actual == TipoAtaque.BOMBA_EXPANSIVA:
				escala = Vector2(0.66, 0.72)
				color = Color(1.0, 0.68, 0.3)
			elif ataque_actual == TipoAtaque.PROYECTIL_RAPIDO:
				escala = Vector2(0.74, 0.48)
				sprite.rotation = 0.12 * direccion_ataque
			else:
				escala = Vector2(0.82, 0.66)
				sprite.rotation = 0.1 * direccion_ataque
				color = Color(0.62, 0.86, 1.0)
		Estado.RECUPERAR:
			nombre_animacion = "quieto"
			escala = Vector2(0.52, 0.48)
			color = Color(0.8, 1.0, 0.8) if segunda_fase else Color(0.78, 0.93, 0.86)
		Estado.HERIDO:
			nombre_animacion = "herido"
			color = Color(1.0, 0.48, 0.48)
		Estado.TRANSICION_FASE:
			nombre_animacion = "quieto"
			escala = Vector2(0.68, 0.72)
			color = Color(0.8, 1.0, 0.4)
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
	if not segunda_fase and vida <= VIDA_MAXIMA / 2:
		iniciar_segunda_fase()
		return
	actualizar_zona_ataque(false)
	restaurar_colision_jugador()
	indicador_caida.hide()
	velocity.x = -direccion * 90.0
	finalizar_cadena()
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
