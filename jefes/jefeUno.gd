extends CharacterBody2D

enum Estado {
	ESPERA,
	PERSEGUIR,
	ATACAR,
	RECUPERAR_ATAQUE,
	PREPARAR_EMBESTIDA,
	EMBESTIR,
	RECUPERAR_EMBESTIDA,
	PREPARAR_DESPLAZAMIENTO,
	DESPLAZARSE_RAPIDO,
	RECUPERAR_DESPLAZAMIENTO,
	PREPARAR_BRAZO,
	ATACAR_BRAZO,
	RECUPERAR_BRAZO,
	DEFENDERSE,
	PREPARAR_ATAQUE_DISTANCIA,
	ATACAR_A_DISTANCIA,
	RECUPERAR_ATAQUE_DISTANCIA,
	HERIDO,
	MUERTO
}

const VIDA_MAXIMA: int = 30
const DURACION_HERIDO: float = 0.5
const ALCANCE_ATAQUE: float = 72.0
const ALTURA_ATAQUE: float = 40.0
const DANIO_ATAQUE: int = 12
const DANIO_DASH: int = 30
const EMPUJE_JUGADOR: float = 22.0
const ANTICIPACION_ATAQUE: float = 0.1
const VENTANA_GOLPE: float = 0.15
const DURACION_ATAQUE: float = 0.4
const ESPERA_ATAQUE: float = 0.2
const DURACION_REACCION_BRAZO: float = 0.2
const DURACION_RECUPERACION_ATAQUE: float = 0.12
const DISTANCIA_MAXIMA_EMBESTIDA: float = 220.0
const DISTANCIA_MAXIMA_DESPLAZAMIENTO: float = 205.0
const ANTICIPACION_EMBESTIDA: float = 0.3
const DURACION_EMBESTIDA: float = 0.5
const VELOCIDAD_EMBESTIDA: float = 430.0
const DURACION_RECUPERACION_EMBESTIDA: float = 0.45
const ESPERA_EMBESTIDA: float = 0.65
const ALCANCE_EMBESTIDA: float = 40.0
const ALTURA_EMBESTIDA: float = 48.0
const ANTICIPACION_DESPLAZAMIENTO: float = 0.15
const DURACION_DESPLAZAMIENTO: float = 0.45
const VELOCIDAD_DESPLAZAMIENTO: float = 600.0
const DURACION_RECUPERACION_DESPLAZAMIENTO: float = 0.4
const ESPERA_DESPLAZAMIENTO: float = 0.65
const ALCANCE_DESPLAZAMIENTO: float = 38.0
const ALTURA_DESPLAZAMIENTO: float = 48.0
const ANTICIPACION_BRAZO: float = 0.15
const DURACION_ATAQUE_BRAZO: float = 0.35
const VENTANA_GOLPE_BRAZO: float = 0.15
const ALCANCE_ATAQUE_BRAZO: float = 88.0
const ALTURA_ATAQUE_BRAZO: float = 45.0
const DANIO_ATAQUE_BRAZO: int = 15
const DURACION_RECUPERACION_BRAZO: float = 0.2
const ESPERA_ATAQUE_BRAZO: float = 0.3
const ANTICIPACION_ATAQUE_DISTANCIA: float = 0.45
const DURACION_EJECUCION_ATAQUE_DISTANCIA: float = 0.16
const DURACION_RECUPERACION_ATAQUE_DISTANCIA: float = 0.65
const ESPERA_ATAQUE_DISTANCIA: float = 1.0
const ESCENA_PROYECTIL_DISTANCIA: PackedScene = preload("res://jefes/proyectilBenjamin.tscn")

@export var danio_extra_brazo: int = 1
@export var danio_extra_vulnerable: int = 1
@export var duracion_vulnerable: float = 1.25
@export var golpes_para_defenderse: int = 4
@export var distancia_defensiva: float = 240.0
@export var velocidad_retroceso: float = 700.0
@export var distancia_maxima_retroceso: float = 280.0
@export var duracion_defensiva: float = 8.0

@onready var barra_vida: ProgressBar = $BarraVida

var vida: int = VIDA_MAXIMA
var velocidad: float = 60.0
var distancia_minima: float = 60.0
var jugador: Node2D
var direccion: float = 1.0
var estado: Estado = Estado.PERSEGUIR
var tiempo_herido: float = 0.0
var tiempo_ataque: float = 0.0
var tiempo_estado_ataque: float = 0.0
var espera_ataque: float = 0.0
var golpe_aplicado: bool = false
var direccion_ataque: float = 1.0
var patron_ataques: int = 0
var tiempo_vulnerable: float = 0.0
var tiempo_reaccion_brazo: float = 0.0
var golpes_pendientes: Array[int] = []
var ataques_cuerpo_pendientes: Dictionary = {}
var ataques_brazo_pendientes: Dictionary = {}
var ataques_procesados: Dictionary = {}
var procesamiento_golpes_pendiente: bool = false
var golpes_recibidos: int = 0
var estrategia_defensiva_pendiente: bool = false
var estrategia_defensiva_activa: bool = false
var inmune_hasta_alejarse: bool = false
var tiempo_estrategia_defensiva: float = 0.0
var distancia_retrocedida: float = 0.0
var posicion_anterior_retroceso_x: float = 0.0
var proyectil_lanzado: bool = false
var proyectiles_activos: Array[Area2D] = []


func _ready() -> void:
	reproducir_animacion("quieto")
	jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	actualizar_barra_vida()
	actualizar_zona_brazo()


func _physics_process(delta: float) -> void:
	if estado != Estado.MUERTO:
		espera_ataque = maxf(espera_ataque - delta, 0.0)
		tiempo_vulnerable = maxf(tiempo_vulnerable - delta, 0.0)
		tiempo_reaccion_brazo = maxf(tiempo_reaccion_brazo - delta, 0.0)
		if estrategia_defensiva_activa:
			tiempo_estrategia_defensiva = maxf(tiempo_estrategia_defensiva - delta, 0.0)
		if tiempo_reaccion_brazo <= 0.0:
			$AnimatedSprite2D.modulate = Color.WHITE
	iniciar_ataque_cercano_durante_recuperacion()
	limpiar_ataques_procesados()
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
		Estado.DEFENDERSE:
			procesar_defensa()
		Estado.ATACAR:
			procesar_ataque(delta)
		Estado.RECUPERAR_ATAQUE:
			procesar_recuperacion_ataque(delta)
		Estado.PREPARAR_EMBESTIDA:
			procesar_preparacion_embestida(delta)
		Estado.EMBESTIR:
			procesar_embestida(delta)
		Estado.RECUPERAR_EMBESTIDA:
			procesar_recuperacion_embestida(delta)
		Estado.PREPARAR_DESPLAZAMIENTO:
			procesar_preparacion_desplazamiento(delta)
		Estado.DESPLAZARSE_RAPIDO:
			procesar_desplazamiento_rapido(delta)
		Estado.RECUPERAR_DESPLAZAMIENTO:
			procesar_recuperacion_desplazamiento(delta)
		Estado.PREPARAR_BRAZO:
			procesar_preparacion_brazo(delta)
		Estado.ATACAR_BRAZO:
			procesar_ataque_brazo(delta)
		Estado.RECUPERAR_BRAZO:
			procesar_recuperacion_brazo(delta)
		Estado.PREPARAR_ATAQUE_DISTANCIA:
			procesar_preparacion_ataque_distancia(delta)
		Estado.ATACAR_A_DISTANCIA:
			procesar_ataque_distancia(delta)
		Estado.RECUPERAR_ATAQUE_DISTANCIA:
			procesar_recuperacion_ataque_distancia(delta)
		Estado.HERIDO:
			detenerse()
			tiempo_herido -= delta
			if tiempo_herido <= 0.0:
				if estrategia_defensiva_pendiente:
					iniciar_estrategia_defensiva()
				elif estrategia_defensiva_activa:
					if tiempo_estrategia_defensiva > 0.0:
						estado = Estado.DEFENDERSE
					else:
						terminar_estrategia_defensiva()
				else:
					estado = Estado.PERSEGUIR
		Estado.MUERTO:
			return
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	$AnimatedSprite2D.flip_h = direccion < 0.0
	actualizar_zona_brazo()
	actualizar_animacion()
	move_and_slide()
	if estado == Estado.EMBESTIR or estado == Estado.DESPLAZARSE_RAPIDO:
		revisar_colision_dash()


func perseguir_jugador() -> void:
	var diferencia: Vector2 = jugador.global_position - global_position
	if diferencia.x != 0.0:
		direccion = signf(diferencia.x)
	if absf(diferencia.y) <= ALTURA_ATAQUE and jugador_en_alcance():
		if espera_ataque <= 0.0:
			iniciar_ataque_segun_distancia(absf(diferencia.x))
		else:
			iniciar_ataque_cuerpo_a_cuerpo()
		detenerse()
		return
	if estrategia_defensiva_pendiente:
		iniciar_estrategia_defensiva()
		return
	if espera_ataque <= 0.0 and absf(diferencia.y) <= ALTURA_ATAQUE and iniciar_ataque_segun_distancia(absf(diferencia.x)):
		detenerse()
		return
	elif absf(diferencia.x) > distancia_minima:
		velocity.x = direccion * velocidad
	else:
		detenerse()


func iniciar_ataque_cercano_durante_recuperacion() -> void:
	if not jugador_en_alcance_sin_direccion():
		return
	match estado:
		Estado.RECUPERAR_ATAQUE, Estado.RECUPERAR_EMBESTIDA, Estado.RECUPERAR_DESPLAZAMIENTO, Estado.RECUPERAR_BRAZO, Estado.RECUPERAR_ATAQUE_DISTANCIA:
			iniciar_ataque_cuerpo_a_cuerpo()


func iniciar_estrategia_defensiva() -> void:
	estrategia_defensiva_pendiente = false
	estrategia_defensiva_activa = true
	tiempo_estrategia_defensiva = maxf(duracion_defensiva, 0.0)
	distancia_retrocedida = 0.0
	posicion_anterior_retroceso_x = global_position.x
	estado = Estado.DEFENDERSE
	detenerse()


func procesar_defensa() -> void:
	if not is_instance_valid(jugador) or tiempo_estrategia_defensiva <= 0.0:
		terminar_estrategia_defensiva()
		return
	var diferencia: Vector2 = jugador.global_position - global_position
	var direccion_hacia_jugador: float = signf(diferencia.x)
	if direccion_hacia_jugador == 0.0:
		direccion_hacia_jugador = direccion
	var direccion_retroceso: float = -direccion_hacia_jugador
	distancia_retrocedida += absf(global_position.x - posicion_anterior_retroceso_x)
	posicion_anterior_retroceso_x = global_position.x
	var retroceso_maximo_alcanzado: bool = distancia_retrocedida >= distancia_maxima_retroceso
	var pared_bloquea_retroceso: bool = is_on_wall() and get_wall_normal().x * direccion_retroceso < 0.0
	if absf(diferencia.x) < distancia_defensiva and not retroceso_maximo_alcanzado and not pared_bloquea_retroceso:
		direccion = direccion_retroceso
		velocity.x = direccion_retroceso * velocidad_retroceso
		return
	inmune_hasta_alejarse = false
	detenerse()
	direccion = direccion_hacia_jugador
	if espera_ataque <= 0.0:
		iniciar_ataque_distancia()


func terminar_estrategia_defensiva() -> void:
	estrategia_defensiva_activa = false
	inmune_hasta_alejarse = false
	tiempo_estrategia_defensiva = 0.0
	estado = Estado.PERSEGUIR
	detenerse()


func revisar_activacion_defensiva() -> void:
	if golpes_recibidos < maxi(golpes_para_defenderse, 1):
		return
	golpes_recibidos = 0
	estrategia_defensiva_pendiente = true
	inmune_hasta_alejarse = true


func iniciar_ataque_segun_distancia(distancia_horizontal: float) -> bool:
	if jugador_en_alcance():
		if patron_ataques % 3 == 2:
			iniciar_ataque_brazo()
		else:
			iniciar_ataque_cuerpo_a_cuerpo()
	elif distancia_horizontal <= DISTANCIA_MAXIMA_EMBESTIDA and patron_ataques % 2 == 0:
		iniciar_embestida()
	elif distancia_horizontal <= DISTANCIA_MAXIMA_DESPLAZAMIENTO:
		iniciar_desplazamiento_rapido()
	else:
		return false
	patron_ataques += 1
	return true


func iniciar_ataque_cuerpo_a_cuerpo() -> void:
	fijar_direccion_ataque()
	tiempo_ataque = 0.0
	golpe_aplicado = false
	estado = Estado.ATACAR


func procesar_ataque(delta: float) -> void:
	detenerse()
	tiempo_ataque += delta
	if tiempo_ataque >= ANTICIPACION_ATAQUE and tiempo_ataque < ANTICIPACION_ATAQUE + VENTANA_GOLPE:
		intentar_golpear_jugador(DANIO_ATAQUE, ALCANCE_ATAQUE, ALTURA_ATAQUE)
	if tiempo_ataque >= DURACION_ATAQUE:
		cambiar_fase_ataque(Estado.RECUPERAR_ATAQUE)


func procesar_recuperacion_ataque(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= DURACION_RECUPERACION_ATAQUE:
		terminar_ataque(ESPERA_ATAQUE)


func iniciar_embestida() -> void:
	fijar_direccion_ataque()
	golpe_aplicado = false
	cambiar_fase_ataque(Estado.PREPARAR_EMBESTIDA)


func procesar_preparacion_embestida(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= ANTICIPACION_EMBESTIDA:
		cambiar_fase_ataque(Estado.EMBESTIR)


func procesar_embestida(delta: float) -> void:
	tiempo_estado_ataque += delta
	velocity.x = direccion_ataque * VELOCIDAD_EMBESTIDA
	intentar_golpear_jugador(DANIO_DASH, ALCANCE_EMBESTIDA, ALTURA_EMBESTIDA)
	if tiempo_estado_ataque >= DURACION_EMBESTIDA or is_on_wall():
		cambiar_fase_ataque(Estado.RECUPERAR_EMBESTIDA)
		detenerse()


func procesar_recuperacion_embestida(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= DURACION_RECUPERACION_EMBESTIDA:
		terminar_ataque(ESPERA_EMBESTIDA)


func iniciar_desplazamiento_rapido() -> void:
	fijar_direccion_ataque()
	golpe_aplicado = false
	cambiar_fase_ataque(Estado.PREPARAR_DESPLAZAMIENTO)


func procesar_preparacion_desplazamiento(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= ANTICIPACION_DESPLAZAMIENTO:
		cambiar_fase_ataque(Estado.DESPLAZARSE_RAPIDO)


func procesar_desplazamiento_rapido(delta: float) -> void:
	tiempo_estado_ataque += delta
	velocity.x = direccion_ataque * VELOCIDAD_DESPLAZAMIENTO
	intentar_golpear_jugador(DANIO_DASH, ALCANCE_DESPLAZAMIENTO, ALTURA_DESPLAZAMIENTO)
	if tiempo_estado_ataque >= DURACION_DESPLAZAMIENTO or is_on_wall():
		cambiar_fase_ataque(Estado.RECUPERAR_DESPLAZAMIENTO)
		detenerse()


func procesar_recuperacion_desplazamiento(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= DURACION_RECUPERACION_DESPLAZAMIENTO:
		terminar_ataque(ESPERA_DESPLAZAMIENTO)


func iniciar_ataque_brazo() -> void:
	fijar_direccion_ataque()
	golpe_aplicado = false
	cambiar_fase_ataque(Estado.PREPARAR_BRAZO)


func procesar_preparacion_brazo(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= ANTICIPACION_BRAZO:
		cambiar_fase_ataque(Estado.ATACAR_BRAZO)


func procesar_ataque_brazo(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= DURACION_ATAQUE_BRAZO - VENTANA_GOLPE_BRAZO:
		intentar_golpear_jugador(DANIO_ATAQUE_BRAZO, ALCANCE_ATAQUE_BRAZO, ALTURA_ATAQUE_BRAZO)
	if tiempo_estado_ataque >= DURACION_ATAQUE_BRAZO:
		cambiar_fase_ataque(Estado.RECUPERAR_BRAZO)


func procesar_recuperacion_brazo(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= DURACION_RECUPERACION_BRAZO:
		terminar_ataque(ESPERA_ATAQUE_BRAZO)


func iniciar_ataque_distancia() -> void:
	fijar_direccion_ataque()
	proyectil_lanzado = false
	cambiar_fase_ataque(Estado.PREPARAR_ATAQUE_DISTANCIA)


func procesar_preparacion_ataque_distancia(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= ANTICIPACION_ATAQUE_DISTANCIA:
		cambiar_fase_ataque(Estado.ATACAR_A_DISTANCIA)


func procesar_ataque_distancia(delta: float) -> void:
	detenerse()
	if not proyectil_lanzado:
		fijar_direccion_ataque()
		proyectil_lanzado = true
		lanzar_proyectil_distancia()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= DURACION_EJECUCION_ATAQUE_DISTANCIA:
		cambiar_fase_ataque(Estado.RECUPERAR_ATAQUE_DISTANCIA)


func procesar_recuperacion_ataque_distancia(delta: float) -> void:
	detenerse()
	tiempo_estado_ataque += delta
	if tiempo_estado_ataque >= DURACION_RECUPERACION_ATAQUE_DISTANCIA:
		espera_ataque = maxf(espera_ataque, ESPERA_ATAQUE_DISTANCIA)
		if tiempo_estrategia_defensiva > 0.0:
			cambiar_fase_ataque(Estado.DEFENDERSE)
		else:
			terminar_estrategia_defensiva()


func lanzar_proyectil_distancia() -> void:
	if not is_instance_valid(jugador):
		return
	var proyectil: Area2D = ESCENA_PROYECTIL_DISTANCIA.instantiate() as Area2D
	proyectil.top_level = true
	add_child(proyectil)
	proyectil.global_position = global_position + Vector2(0.0, -56.0)
	proyectiles_activos.append(proyectil)
	proyectil.call("apuntar_a", jugador.global_position)


func detener_proyectiles() -> void:
	for proyectil in proyectiles_activos:
		if is_instance_valid(proyectil):
			proyectil.queue_free()
	proyectiles_activos.clear()


func cambiar_fase_ataque(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	tiempo_estado_ataque = 0.0


func terminar_ataque(tiempo_espera: float) -> void:
	estado = Estado.PERSEGUIR
	tiempo_estado_ataque = 0.0
	espera_ataque = maxf(espera_ataque, tiempo_espera)
	detenerse()


func fijar_direccion_ataque() -> void:
	if not is_instance_valid(jugador):
		return
	var diferencia_x: float = jugador.global_position.x - global_position.x
	if diferencia_x != 0.0:
		direccion_ataque = signf(diferencia_x)
	else:
		direccion_ataque = direccion
	direccion = direccion_ataque


func intentar_golpear_jugador(cantidad: int, alcance_x: float, altura_y: float) -> void:
	if golpe_aplicado or not jugador_en_alcance_con(alcance_x, altura_y):
		return
	aplicar_golpe_jugador(cantidad)


func revisar_colision_dash() -> void:
	if golpe_aplicado or not is_instance_valid(jugador):
		return
	for indice in range(get_slide_collision_count()):
		var colision: KinematicCollision2D = get_slide_collision(indice)
		if colision.get_collider() == jugador:
			aplicar_golpe_jugador(DANIO_DASH)
			return


func aplicar_golpe_jugador(cantidad: int) -> void:
	if golpe_aplicado or not is_instance_valid(jugador) or not jugador.has_method("recibir_golpe"):
		return
	golpe_aplicado = true
	if bool(jugador.get("invulnerable")) or int(jugador.get("vida")) <= 0:
		return
	jugador.call("recibir_golpe", cantidad)
	if int(jugador.get("vida")) > 0:
		empujar_jugador()


func empujar_jugador() -> void:
	if jugador is CharacterBody2D:
		var jugador_fisico: CharacterBody2D = jugador as CharacterBody2D
		var direccion_empuje: float = signf(jugador.global_position.x - global_position.x)
		if direccion_empuje == 0.0:
			direccion_empuje = direccion_ataque
		jugador_fisico.call_deferred("move_and_collide", Vector2(direccion_empuje * EMPUJE_JUGADOR, 0.0))


func jugador_en_alcance() -> bool:
	return jugador_en_alcance_con(ALCANCE_ATAQUE, ALTURA_ATAQUE)


func jugador_en_alcance_sin_direccion() -> bool:
	if not is_instance_valid(jugador):
		return false
	var diferencia: Vector2 = jugador.global_position - global_position
	return absf(diferencia.x) <= ALCANCE_ATAQUE and absf(diferencia.y) <= ALTURA_ATAQUE


func jugador_en_alcance_con(alcance_x: float, altura_y: float) -> bool:
	if not is_instance_valid(jugador):
		return false
	var diferencia: Vector2 = jugador.global_position - global_position
	return absf(diferencia.x) <= alcance_x and absf(diferencia.y) <= altura_y and diferencia.x * direccion >= 0.0


func detenerse() -> void:
	velocity.x = 0.0


func actualizar_animacion() -> void:
	match estado:
		Estado.ESPERA:
			reproducir_animacion("quieto")
		Estado.PERSEGUIR:
			reproducir_animacion("quieto")
		Estado.DEFENDERSE:
			reproducir_animacion("quieto")
		Estado.ATACAR, Estado.EMBESTIR, Estado.DESPLAZARSE_RAPIDO, Estado.ATACAR_BRAZO:
			reproducir_animacion("atacar")
		Estado.ATACAR_A_DISTANCIA:
			reproducir_animacion("atacar")
		Estado.PREPARAR_EMBESTIDA, Estado.PREPARAR_DESPLAZAMIENTO, Estado.PREPARAR_BRAZO, Estado.RECUPERAR_BRAZO:
			reproducir_animacion("herido")
		Estado.PREPARAR_ATAQUE_DISTANCIA:
			reproducir_animacion("herido")
		Estado.RECUPERAR_ATAQUE, Estado.RECUPERAR_EMBESTIDA, Estado.RECUPERAR_DESPLAZAMIENTO:
			reproducir_animacion("quieto")
		Estado.RECUPERAR_ATAQUE_DISTANCIA:
			reproducir_animacion("quieto")
		Estado.HERIDO:
			reproducir_animacion("herido")
		Estado.MUERTO:
			reproducir_animacion("morir")
	if tiempo_reaccion_brazo > 0.0:
		return
	var color_actual: Color = Color.WHITE
	match estado:
		Estado.PREPARAR_EMBESTIDA, Estado.EMBESTIR:
			color_actual = Color(1.0, 0.78, 0.62)
		Estado.PREPARAR_DESPLAZAMIENTO, Estado.DESPLAZARSE_RAPIDO:
			color_actual = Color(0.72, 0.88, 1.0)
		Estado.PREPARAR_ATAQUE_DISTANCIA, Estado.ATACAR_A_DISTANCIA:
			color_actual = Color(0.82, 0.9, 1.0)
		Estado.PREPARAR_BRAZO, Estado.ATACAR_BRAZO, Estado.RECUPERAR_BRAZO:
			color_actual = Color(1.0, 0.72, 0.55)
	$AnimatedSprite2D.modulate = color_actual


func reproducir_animacion(nombre: String) -> void:
	if $AnimatedSprite2D.animation != nombre:
		$AnimatedSprite2D.play(nombre)


func actualizar_zona_brazo() -> void:
	$BrazoDerechoDebil.position.x = -20.0 * direccion
	if estado == Estado.RECUPERAR_BRAZO:
		$BrazoDerechoDebil.scale = Vector2(1.7, 1.25)
	else:
		$BrazoDerechoDebil.scale = Vector2.ONE


func actualizar_barra_vida() -> void:
	barra_vida.min_value = 0.0
	barra_vida.max_value = VIDA_MAXIMA
	barra_vida.value = vida


func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or vida <= 0 or estado == Estado.MUERTO or inmune_hasta_alejarse:
		return
	golpes_pendientes.append(cantidad)
	solicitar_procesamiento_golpes()


func _on_zona_cuerpo_area_entered(area: Area2D) -> void:
	registrar_ataque_en_zona(area, ataques_cuerpo_pendientes)


func _on_brazo_derecho_debil_area_entered(area: Area2D) -> void:
	registrar_ataque_en_zona(area, ataques_brazo_pendientes)


func registrar_ataque_en_zona(ataque: Area2D, ataques_zona: Dictionary) -> void:
	if not is_instance_valid(ataque) or vida <= 0 or estado == Estado.MUERTO or inmune_hasta_alejarse:
		return
	var id_ataque: int = ataque.get_instance_id()
	if ataques_procesados.has(id_ataque) or ataques_zona.has(id_ataque):
		return
	var valor_danio: Variant = ataque.get("daño")
	if typeof(valor_danio) != TYPE_INT or valor_danio <= 0:
		return
	ataques_zona[id_ataque] = {
		"referencia": weakref(ataque),
		"cantidad": int(valor_danio)
	}
	solicitar_procesamiento_golpes()


func solicitar_procesamiento_golpes() -> void:
	if procesamiento_golpes_pendiente:
		return
	procesamiento_golpes_pendiente = true
	call_deferred("procesar_golpes_pendientes")


func procesar_golpes_pendientes() -> void:
	procesamiento_golpes_pendiente = false
	if vida <= 0 or estado == Estado.MUERTO:
		golpes_pendientes.clear()
		ataques_cuerpo_pendientes.clear()
		ataques_brazo_pendientes.clear()
		return

	var golpes_restantes: Array[int] = []
	for cantidad in golpes_pendientes:
		golpes_restantes.append(cantidad)
	golpes_pendientes.clear()

	for id_ataque in ataques_cuerpo_pendientes.keys():
		if ataques_procesados.has(id_ataque):
			continue
		var datos_ataque: Dictionary = ataques_cuerpo_pendientes[id_ataque]
		var danio: int = int(datos_ataque["cantidad"])
		var indice_golpe: int = golpes_restantes.find(danio)
		if indice_golpe == -1:
			continue
		var referencia: WeakRef = datos_ataque["referencia"]
		var ataque: Area2D = referencia.get_ref() as Area2D
		if not is_instance_valid(ataque):
			continue
		golpes_restantes.remove_at(indice_golpe)
		ataques_procesados[id_ataque] = weakref(ataque)
		aplicar_danio(danio, ataques_brazo_pendientes.has(id_ataque))

	for cantidad in golpes_restantes:
		aplicar_danio(cantidad, false)

	for id_ataque in ataques_brazo_pendientes.keys():
		if ataques_procesados.has(id_ataque):
			continue
		var datos_ataque: Dictionary = ataques_brazo_pendientes[id_ataque]
		var referencia: WeakRef = datos_ataque["referencia"]
		var ataque: Area2D = referencia.get_ref() as Area2D
		if not is_instance_valid(ataque):
			continue
		ataques_procesados[id_ataque] = weakref(ataque)
		aplicar_danio(int(datos_ataque["cantidad"]), true)

	ataques_cuerpo_pendientes.clear()
	ataques_brazo_pendientes.clear()


func aplicar_danio(cantidad: int, golpe_en_brazo: bool) -> void:
	if cantidad <= 0 or vida <= 0 or estado == Estado.MUERTO or inmune_hasta_alejarse:
		return
	var danio_final: int = cantidad
	if golpe_en_brazo:
		danio_final += maxi(danio_extra_brazo, 0)
		tiempo_vulnerable = maxf(duracion_vulnerable, 0.0)
		tiempo_reaccion_brazo = DURACION_REACCION_BRAZO
		$AnimatedSprite2D.modulate = Color(1.0, 0.65, 0.35)
	elif tiempo_vulnerable > 0.0:
		danio_final += maxi(danio_extra_vulnerable, 0)
	vida = maxi(vida - danio_final, 0)
	golpes_recibidos += 1
	actualizar_barra_vida()
	if vida == 0:
		estado = Estado.MUERTO
		tiempo_vulnerable = 0.0
		estrategia_defensiva_activa = false
		estrategia_defensiva_pendiente = false
		inmune_hasta_alejarse = false
		tiempo_estrategia_defensiva = 0.0
		detener_proyectiles()
		reproducir_animacion("morir")
		await $AnimatedSprite2D.animation_finished
		queue_free()
	else:
		if estado != Estado.HERIDO:
			estado = Estado.HERIDO
			tiempo_herido = DURACION_HERIDO
		espera_ataque = maxf(espera_ataque, ESPERA_ATAQUE)
		reproducir_animacion("herido")
		revisar_activacion_defensiva()


func limpiar_ataques_procesados() -> void:
	for id_ataque in ataques_procesados.keys():
		var referencia: WeakRef = ataques_procesados[id_ataque]
		if not is_instance_valid(referencia.get_ref()):
			ataques_procesados.erase(id_ataque)
