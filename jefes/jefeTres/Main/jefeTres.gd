extends CharacterBody2D

signal derrotado

enum Estado { ESPERA, PERSEGUIR, PREPARAR, DESLIZAR, RAFAGA, SALTAR, RECUPERAR, HERIDO, MUERTO }
enum Ataque { NINGUNO, CRUZADO, DESLIZAMIENTO, LLUVIA, RAFAGA }

const VIDA_MAXIMA: int = 36
const VELOCIDAD: float = 280.0
const VELOCIDAD_DESLIZAMIENTO: float = 620.0
const VELOCIDAD_AEREA: float = 340.0
const ACELERACION: float = 1800.0
const DISTANCIA_MINIMA: float = 84.0
const ALCANCE_LANZAMIENTO: float = 340.0
const IMPULSO_SALTO: float = -680.0
const IMPULSO_LLUVIA: float = -750.0
const DURACION_PREPARACION: float = 0.4
const DURACION_DESLIZAMIENTO: float = 0.28
const INTERVALO_RAFAGA: float = 0.18
const DURACION_RECUPERACION: float = 0.35
const DURACION_HERIDO: float = 0.16
const DURACION_MUERTE: float = 0.4
const MAXIMO_LATAS: int = 8
const ESCENA_LATA: PackedScene = preload("res://jefes/jefeTres/Proyectiles/lataNico.tscn")
const SCRIPT_LATA = preload("res://jefes/jefeTres/Proyectiles/lataNico.gd")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var barra_vida: ProgressBar = $BarraVida
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var punto_lanzamiento: Marker2D = $PuntoLanzamiento
@onready var aviso_lata: Sprite2D = $PuntoLanzamiento/AvisoLata
@onready var proyectiles: Node2D = $Proyectiles
@onready var detector_suelo: RayCast2D = $DetectorSuelo
@onready var marcas_lluvia: Node2D = $MarcasLluvia

var vida: int = VIDA_MAXIMA
var jugador: CharacterBody2D
var direccion: float = 1.0
var estado: Estado = Estado.ESPERA
var ataque: Ataque = Ataque.NINGUNO
var ultimo_ataque: Ataque = Ataque.NINGUNO
var tiempo_estado: float = 0.0
var espera_ataque: float = 0.0
var espera_lluvia: float = 0.0
var tiempo_gesto: float = 0.0
var momento_lanzamiento: float = 0.0
var destino_salto: float = 0.0
var sentido_movimiento: float = 1.0
var objetivo_lanzamiento: Vector2
var objetivos_lluvia: Array[Vector2] = []
var latas_lanzadas: int = 0
var retroceder: bool = false


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
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody2D
	espera_ataque = maxf(espera_ataque - delta, 0.0)
	espera_lluvia = maxf(espera_lluvia - delta, 0.0)
	tiempo_gesto = maxf(tiempo_gesto - delta, 0.0)
	var velocidad_objetivo: float = 0.0
	match estado:
		Estado.ESPERA:
			if jugador_disponible():
				cambiar_estado(Estado.PERSEGUIR)
		Estado.PERSEGUIR:
			velocidad_objetivo = perseguir_jugador(delta)
		Estado.PREPARAR:
			procesar_preparacion()
		Estado.DESLIZAR:
			velocidad_objetivo = procesar_deslizamiento()
		Estado.RAFAGA:
			procesar_rafaga()
		Estado.SALTAR:
			velocidad_objetivo = procesar_salto(delta)
		Estado.RECUPERAR:
			velocidad_objetivo = procesar_recuperacion()
		Estado.HERIDO:
			if tiempo_estado >= DURACION_HERIDO:
				cambiar_estado(Estado.PERSEGUIR)
	if estado == Estado.DESLIZAR or estado == Estado.SALTAR:
		velocity.x = velocidad_objetivo
	else:
		velocity.x = move_toward(velocity.x, velocidad_objetivo, ACELERACION * delta)
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
	if not is_zero_approx(diferencia.x):
		direccion = signf(diferencia.x)
	if is_on_floor() and espera_ataque == 0.0:
		if diferencia.y >= 52.0 and absf(diferencia.x) <= 110.0 and iniciar_bajada():
			return 0.0
		if elegir_ataque(diferencia):
			return 0.0
	var margen: float = maxf(absf(diferencia.x) - DISTANCIA_MINIMA, 0.0)
	if is_on_floor() and not camino_seguro(direccion, VELOCIDAD, clampf(diferencia.y, 40.0, 145.0)):
		velocity.x = 0.0
		return 0.0
	velocity.x = clampf(velocity.x, -margen / delta, margen / delta)
	return direccion * minf(VELOCIDAD, minf(sqrt(2.0 * ACELERACION * margen), margen / delta))


func elegir_ataque(diferencia: Vector2) -> bool:
	var distancia: float = absf(diferencia.x)
	if distancia > ALCANCE_LANZAMIENTO or absf(diferencia.y) > 205.0:
		return false
	if espera_lluvia == 0.0 and ultimo_ataque != Ataque.LLUVIA and preparar_lluvia(diferencia):
		iniciar_ataque(Ataque.LLUVIA)
		return true
	if ultimo_ataque != Ataque.CRUZADO and absf(diferencia.y) < 110.0 and distancia <= 290.0:
		if preparar_cruce():
			iniciar_ataque(Ataque.CRUZADO)
			return true
	if ultimo_ataque != Ataque.DESLIZAMIENTO and absf(diferencia.y) < 90.0 and distancia >= 105.0:
		if camino_seguro(direccion, VELOCIDAD_DESLIZAMIENTO, 42.0):
			iniciar_ataque(Ataque.DESLIZAMIENTO)
			return true
	if absf(diferencia.y) <= 130.0:
		iniciar_ataque(Ataque.RAFAGA)
		return true
	return false


func preparar_cruce() -> bool:
	var destino_x: float = jugador.global_position.x + direccion * 64.0
	var suelo := buscar_suelo(destino_x, jugador.global_position.y - 42.0, jugador.global_position.y + 98.0)
	if suelo == Vector2.INF or absf(suelo.y - global_position.y) > 150.0:
		return false
	if absf(destino_x - global_position.x) > VELOCIDAD_AEREA * 1.1:
		return false
	destino_salto = destino_x
	return true


func iniciar_bajada() -> bool:
	var altura: float = global_position.y
	for sentido: float in [direccion, -direccion]:
		var x: float = global_position.x + sentido * 132.0
		var suelo := buscar_suelo(x, altura - 12.0, altura + 185.0)
		if suelo != Vector2.INF and suelo.y >= altura + 52.0:
			destino_salto = x
			sentido_movimiento = sentido
			direccion = sentido
			ataque = Ataque.NINGUNO
			velocity.y = -280.0
			cambiar_estado(Estado.SALTAR)
			return true
	return false


func preparar_lluvia(diferencia: Vector2) -> bool:
	var altura: float = global_position.y
	var plataforma := buscar_suelo(global_position.x + direccion * 148.0, altura - 205.0, altura - 44.0)
	if plataforma == Vector2.INF:
		plataforma = buscar_suelo(global_position.x + direccion * 240.0, altura - 205.0, altura - 44.0)
	if plataforma == Vector2.INF and (diferencia.y < -28.0 or absf(diferencia.x) < 180.0):
		return false
	destino_salto = plataforma.x if plataforma != Vector2.INF else global_position.x
	objetivos_lluvia.clear()
	var centro: float = jugador.global_position.x
	for separacion: float in [-128.0, 0.0, 128.0, -240.0, 240.0]:
		var suelo := buscar_suelo(centro + separacion, altura - 245.0, jugador.global_position.y + 140.0)
		if suelo != Vector2.INF and suelo.y >= altura - 205.0:
			objetivos_lluvia.append(suelo)
		if objetivos_lluvia.size() == 3:
			return true
	return false


func buscar_suelo(x: float, desde_y: float, hasta_y: float) -> Vector2:
	detector_suelo.position = to_local(Vector2(x, desde_y))
	detector_suelo.target_position = Vector2(0.0, hasta_y - desde_y)
	detector_suelo.force_raycast_update()
	if detector_suelo.is_colliding() and detector_suelo.get_collision_normal().y < -0.6:
		return detector_suelo.get_collision_point()
	return Vector2.INF


func camino_seguro(sentido: float, rapidez: float, profundidad: float) -> bool:
	var altura: float = global_position.y
	var x: float = global_position.x + sentido * (28.0 + rapidez * 0.035)
	return buscar_suelo(x, altura - 8.0, altura + profundidad) != Vector2.INF


func iniciar_ataque(nuevo_ataque: Ataque) -> void:
	ataque = nuevo_ataque
	ultimo_ataque = nuevo_ataque
	sentido_movimiento = direccion
	velocity.x = 0.0
	objetivo_lanzamiento = jugador.global_position
	if ataque == Ataque.CRUZADO:
		objetivo_lanzamiento.x += clampf(jugador.velocity.x * 0.25, -72.0, 72.0)
	elif ataque == Ataque.LLUVIA:
		espera_lluvia = 4.0
	cambiar_estado(Estado.PREPARAR)


func procesar_preparacion() -> void:
	if not jugador_disponible():
		cambiar_estado(Estado.ESPERA)
		return
	if tiempo_estado < DURACION_PREPARACION:
		return
	match ataque:
		Ataque.DESLIZAMIENTO:
			cambiar_estado(Estado.DESLIZAR)
		Ataque.RAFAGA:
			iniciar_rafaga()
		Ataque.CRUZADO, Ataque.LLUVIA:
			velocity.y = IMPULSO_SALTO if ataque == Ataque.CRUZADO else IMPULSO_LLUVIA
			latas_lanzadas = 0
			cambiar_estado(Estado.SALTAR)


func procesar_deslizamiento() -> float:
	if tiempo_estado < DURACION_DESLIZAMIENTO and not is_on_wall() and camino_seguro(sentido_movimiento, VELOCIDAD_DESLIZAMIENTO, 42.0):
		return sentido_movimiento * VELOCIDAD_DESLIZAMIENTO
	velocity.x = 0.0
	if jugador_disponible() and global_position.distance_to(jugador.global_position) <= ALCANCE_LANZAMIENTO:
		direccion = signf(jugador.global_position.x - global_position.x)
		if is_zero_approx(direccion):
			direccion = sentido_movimiento
		objetivo_lanzamiento = jugador.global_position
		iniciar_rafaga()
	else:
		iniciar_recuperacion(false)
	return 0.0


func iniciar_rafaga() -> void:
	latas_lanzadas = 0
	momento_lanzamiento = 0.20
	cambiar_estado(Estado.RAFAGA)


func procesar_rafaga() -> void:
	if tiempo_estado < momento_lanzamiento:
		return
	if latas_lanzadas == 3:
		iniciar_recuperacion(true)
		return
	var objetivo := objetivo_lanzamiento + Vector2((latas_lanzadas - 1) * 70.0 * direccion, 0.0)
	lanzar_lata(objetivo, 0.44 + 0.12 * latas_lanzadas)
	latas_lanzadas += 1
	momento_lanzamiento += INTERVALO_RAFAGA


func procesar_salto(delta: float) -> float:
	if (tiempo_estado > 0.06 and is_on_floor()) or tiempo_estado >= 1.85:
		iniciar_recuperacion(ataque == Ataque.LLUVIA)
		return 0.0
	if ataque == Ataque.LLUVIA:
		if tiempo_estado >= 0.15 and latas_lanzadas == 0 and not marcas_lluvia.visible:
			mostrar_marcas()
		if tiempo_estado >= 0.49 and latas_lanzadas == 0:
			for i in objetivos_lluvia.size():
				lanzar_lata(objetivos_lluvia[i], 0.47 + 0.065 * i)
			latas_lanzadas = objetivos_lluvia.size()
	elif ataque == Ataque.CRUZADO and tiempo_estado >= 0.34 and latas_lanzadas == 0:
		lanzar_lata(objetivo_lanzamiento, 0.43)
		latas_lanzadas = 1
	var distancia: float = destino_salto - global_position.x
	return clampf(distancia / delta, -VELOCIDAD_AEREA, VELOCIDAD_AEREA)


func mostrar_marcas() -> void:
	marcas_lluvia.show()
	for i in objetivos_lluvia.size():
		var marca := marcas_lluvia.get_child(i) as Line2D
		marca.global_position = objetivos_lluvia[i] - Vector2(0.0, 3.0)


func lanzar_lata(objetivo: Vector2, tiempo_vuelo: float) -> void:
	if proyectiles.get_child_count() >= MAXIMO_LATAS:
		return
	var origen := Vector2(global_position.x, punto_lanzamiento.global_position.y)
	var sentido: float = signf(objetivo.x - origen.x)
	if not is_zero_approx(sentido):
		origen.x += sentido * minf(absf(punto_lanzamiento.position.x), absf(objetivo.x - origen.x))
		if ataque != Ataque.LLUVIA:
			direccion = sentido
	var lata := ESCENA_LATA.instantiate() as SCRIPT_LATA
	var diferencia: Vector2 = objetivo - origen
	var velocidad_inicial := diferencia / tiempo_vuelo
	velocidad_inicial.y -= 0.5 * SCRIPT_LATA.GRAVEDAD * tiempo_vuelo
	lata.position = proyectiles.to_local(origen)
	lata.configurar(velocidad_inicial, jugador)
	proyectiles.add_child(lata)
	tiempo_gesto = 0.13


func iniciar_recuperacion(con_retroceso: bool) -> void:
	retroceder = con_retroceso
	espera_ataque = 0.55
	cambiar_estado(Estado.RECUPERAR)


func procesar_recuperacion() -> float:
	if tiempo_estado >= DURACION_RECUPERACION:
		cambiar_estado(Estado.PERSEGUIR)
	elif tiempo_estado < 0.19 and retroceder and is_on_floor() and camino_seguro(-direccion, 225.0, 34.0):
		return -direccion * 225.0
	return 0.0


func cambiar_estado(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	tiempo_estado = 0.0
	aviso_lata.hide()
	if estado != Estado.SALTAR:
		marcas_lluvia.hide()


func actualizar_animacion() -> void:
	sprite.flip_h = direccion < 0.0
	punto_lanzamiento.position.x = 20.0 * direccion
	sprite.position.y = -46.0
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	aviso_lata.visible = false
	match estado:
		Estado.PERSEGUIR:
			if is_on_floor() and absf(get_real_velocity().x) > 10.0:
				sprite.position.y -= absf(sin(tiempo_estado * 23.0)) * 4.0
				sprite.rotation = 0.09 * direccion
		Estado.PREPARAR:
			sprite.rotation = -0.17 * direccion
			sprite.modulate = Color(0.93, 0.72, 1.0)
			aviso_lata.visible = ataque == Ataque.RAFAGA
			if ataque == Ataque.DESLIZAMIENTO:
				sprite.scale = Vector2(1.12, 0.78)
				sprite.position.y = -36.0
				sprite.modulate = Color(1.0, 0.76, 0.47)
		Estado.DESLIZAR:
			sprite.scale = Vector2(1.17, 0.68)
			sprite.position.y = -31.0
			sprite.rotation = 0.26 * direccion
		Estado.SALTAR:
			sprite.rotation = -0.14 * sentido_movimiento
			sprite.scale = Vector2(0.94, 1.06)
			aviso_lata.visible = ataque != Ataque.NINGUNO and latas_lanzadas == 0
		Estado.RAFAGA:
			aviso_lata.visible = tiempo_gesto == 0.0 and latas_lanzadas < 3
			sprite.rotation = -0.12 * direccion
		Estado.RECUPERAR:
			sprite.rotation = 0.15 * direccion * (1.0 - tiempo_estado / DURACION_RECUPERACION)
		Estado.HERIDO:
			sprite.modulate = Color(1.0, 0.48, 0.48)
			sprite.rotation = -0.1 * direccion
	if tiempo_gesto > 0.0 and (estado == Estado.SALTAR or estado == Estado.RAFAGA):
		sprite.rotation = 0.24 * direccion
	aviso_lata.rotation = -0.45 * direccion

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
