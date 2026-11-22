extends CharacterBody2D

signal derrotado

enum Estado {
	ESPERA, PERSEGUIR, PREPARAR, DESLIZAR, RAFAGA, SALTAR, RECUPERAR, HERIDO,
	REGRESAR, CARGAR_EXPLOSION, EXPLOTAR, MUERTO
}
enum Ataque { NINGUNO, CRUZADO, DESLIZAMIENTO, LLUVIA, RAFAGA, LANZAMIENTO, TORMENTA }

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
const PAUSA_ATAQUE: float = 0.20
const DURACION_HERIDO: float = 0.16
const INTERVALO_INTERRUPCION: float = 1.10
const DISTANCIA_PRESION_CERCANA: float = 105.0
const DURACION_MUERTE: float = 0.4
const DURACION_REGRESO: float = 0.65
const DURACION_CARGA: float = 2.4
const DURACION_EXPLOSION: float = 0.42
const DANIO_EXPLOSION: int = 35
const COLOR_SEGUNDA_FASE := Color(1.0, 0.73, 0.53)
const MULTIPLICADOR_CARRERA_FASE_DOS: float = 1.18
const MULTIPLICADOR_DESLIZAMIENTO_FASE_DOS: float = 1.08
const MULTIPLICADOR_SALTO_FASE_DOS: float = 1.10
const MULTIPLICADOR_PREPARACION_FASE_DOS: float = 0.90
const MAXIMO_ACCIONES_CADENA: int = 3
const DURACION_RECUPERACION_FASE_DOS: float = 0.30
const DURACION_RECUPERACION_CADENA: float = 0.55
const PAUSA_ATAQUE_FASE_DOS: float = 0.15
const ALCANCE_LANZAMIENTO_LEJANO: float = 570.0
const DURACION_PREPARACION_TORMENTA: float = 0.52
const DURACION_RECUPERACION_TORMENTA: float = 0.85
const ESPERA_TORMENTA: float = 6.0
const TIEMPOS_TORMENTA := [0.24, 0.49, 0.67]
const LATAS_POR_RAFAGA_TORMENTA: int = 12
const PUNTOS_RASTRO_TORMENTA: int = 9
const MAXIMO_LATAS: int = 8
const ESCENA_LATA: PackedScene = preload("res://jefes/jefeTres/Proyectiles/lataNico.tscn")
const SCRIPT_LATA = preload("res://jefes/jefeTres/Proyectiles/lataNico.gd")

@export_range(16.0, 1000.0, 1.0, "or_greater") var radio_explosion: float = 260.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var barra_vida: ProgressBar = $BarraVida
@onready var colision: CollisionShape2D = $CollisionShape2D
@onready var punto_lanzamiento: Marker2D = $PuntoLanzamiento
@onready var aviso_lata: Sprite2D = $PuntoLanzamiento/AvisoLata
@onready var proyectiles: Node2D = $Proyectiles
@onready var detector_suelo: RayCast2D = $DetectorSuelo
@onready var marcas_lluvia: Node2D = $MarcasLluvia
@onready var efecto_explosion: Node2D = $EfectoExplosion
@onready var resplandor_explosion: Polygon2D = $EfectoExplosion/Resplandor
@onready var circulo_explosion: Line2D = $EfectoExplosion/Circulo
@onready var onda_explosion: Line2D = $EfectoExplosion/Onda
@onready var aviso_tormenta: Node2D = $AvisoTormenta
@onready var rastro_tormenta: Line2D = $RastroTormenta

var vida: int = VIDA_MAXIMA
var posicion_inicial: Vector2
var inicio_regreso: Vector2
var radio_activo: float
var transicion_activada: bool = false
var segunda_fase: bool = false
var colision_suspendida: bool = false
var jugador: CharacterBody2D
var direccion: float = 1.0
var estado: Estado = Estado.ESPERA
var ataque: Ataque = Ataque.NINGUNO
var ultimo_ataque: Ataque = Ataque.NINGUNO
var tiempo_estado: float = 0.0
var espera_ataque: float = 0.0
var espera_lluvia: float = 0.0
var espera_tormenta: float = 0.0
var espera_interrupcion: float = 0.0
var presion_cercana: bool = false
var tiempo_gesto: float = 0.0
var tiempo_destello_golpe: float = 0.0
var momento_lanzamiento: float = 0.0
var destino_salto: float = 0.0
var destino_regreso_tormenta: float
var sentido_movimiento: float = 1.0
var objetivo_lanzamiento: Vector2
var objetivos_lluvia: Array[Vector2] = []
var latas_lanzadas: int = 0
var acciones_cadena: int = 0
var retroceder: bool = false
var duracion_recuperacion: float = DURACION_RECUPERACION
var jugador_exento_deslizamiento: CharacterBody2D


func _ready() -> void:
	posicion_inicial = global_position
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
		if is_instance_valid(jugador):
			detector_suelo.add_exception(jugador)
	if en_transicion():
		procesar_transicion()
		actualizar_animacion()
		return
	espera_ataque = maxf(espera_ataque - delta, 0.0)
	espera_lluvia = maxf(espera_lluvia - delta, 0.0)
	espera_tormenta = maxf(espera_tormenta - delta, 0.0)
	espera_interrupcion = maxf(espera_interrupcion - delta, 0.0)
	if espera_interrupcion == 0.0:
		presion_cercana = false
	tiempo_gesto = maxf(tiempo_gesto - delta, 0.0)
	tiempo_destello_golpe = maxf(tiempo_destello_golpe - delta, 0.0)
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
	actualizar_excepcion_deslizamiento()
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
		if presion_cercana and responder_presion_cercana(diferencia):
			return 0.0
		if diferencia.y >= 52.0 and absf(diferencia.x) <= 110.0 and iniciar_bajada():
			return 0.0
		if elegir_ataque(diferencia):
			return 0.0
	var margen: float = maxf(absf(diferencia.x) - DISTANCIA_MINIMA, 0.0)
	var rapidez: float = VELOCIDAD * MULTIPLICADOR_CARRERA_FASE_DOS if segunda_fase else VELOCIDAD
	if is_on_floor() and not camino_seguro(direccion, rapidez, clampf(diferencia.y, 40.0, 145.0)):
		velocity.x = 0.0
		return 0.0
	velocity.x = clampf(velocity.x, -margen / delta, margen / delta)
	return direccion * minf(rapidez, minf(sqrt(2.0 * ACELERACION * margen), margen / delta))


func responder_presion_cercana(diferencia: Vector2) -> bool:
	if absf(diferencia.x) > DISTANCIA_PRESION_CERCANA or absf(diferencia.y) > 90.0:
		return false
	presion_cercana = false
	if segunda_fase and intentar_deslizamiento(direccion):
		return true
	var destino: float = global_position.x - direccion * 146.0
	if not pared_en_direccion(-direccion) and hay_aterrizaje_cercano(destino):
		destino_salto = destino
		direccion = -direccion
		iniciar_ataque(Ataque.CRUZADO)
		return true
	if not pared_en_direccion(direccion) and preparar_cruce():
		iniciar_ataque(Ataque.CRUZADO)
		return true
	return false


func elegir_ataque(diferencia: Vector2) -> bool:
	if segunda_fase:
		return elegir_ataque_segunda_fase(diferencia)
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


func elegir_ataque_segunda_fase(diferencia: Vector2) -> bool:
	var distancia: float = absf(diferencia.x)
	var altura: float = absf(diferencia.y)
	if distancia > ALCANCE_LANZAMIENTO:
		return presionar_desde_lejos(distancia, altura)
	if altura > 205.0:
		return false
	if distancia <= DISTANCIA_PRESION_CERCANA and altura <= 90.0 and ultimo_ataque != Ataque.DESLIZAMIENTO:
		if intentar_deslizamiento(direccion):
			return true
	if distancia >= 105.0 and altura <= 120.0 and espera_tormenta == 0.0 and ultimo_ataque != Ataque.TORMENTA:
		if preparar_tormenta():
			iniciar_ataque(Ataque.TORMENTA)
			return true
	if espera_lluvia == 0.0 and ultimo_ataque != Ataque.LLUVIA and (altura > 65.0 or ultimo_ataque == Ataque.RAFAGA):
		if preparar_lluvia(diferencia):
			iniciar_ataque(Ataque.LLUVIA)
			return true
	if distancia >= 105.0 and altura <= 130.0 and ultimo_ataque != Ataque.RAFAGA:
		iniciar_ataque(Ataque.RAFAGA)
		return true
	if ultimo_ataque != Ataque.CRUZADO and altura < 110.0 and preparar_cruce():
		iniciar_ataque(Ataque.CRUZADO)
		return true
	if altura <= 90.0 and ultimo_ataque != Ataque.DESLIZAMIENTO and intentar_deslizamiento(direccion):
		return true
	if altura <= 130.0:
		iniciar_ataque(Ataque.RAFAGA)
		return true
	return false


func presionar_desde_lejos(distancia: float, altura: float) -> bool:
	if distancia > ALCANCE_LANZAMIENTO_LEJANO or altura > 135.0:
		return false
	if ultimo_ataque != Ataque.CRUZADO:
		var x: float = global_position.x + direccion * 240.0
		if hay_aterrizaje_cercano(x) and not pared_en_direccion(direccion):
			destino_salto = x
			iniciar_ataque(Ataque.CRUZADO)
			return true
	if ultimo_ataque != Ataque.DESLIZAMIENTO and altura < 90.0 and intentar_deslizamiento(direccion):
		return true
	if ultimo_ataque != Ataque.LANZAMIENTO:
		iniciar_ataque(Ataque.LANZAMIENTO)
		return true
	return false


func preparar_cruce() -> bool:
	var destino_x: float = jugador.global_position.x + direccion * 64.0
	var suelo := buscar_suelo(destino_x, jugador.global_position.y - 42.0, jugador.global_position.y + 98.0)
	if suelo == Vector2.INF or absf(suelo.y - global_position.y) > 150.0:
		return false
	if absf(destino_x - global_position.x) > velocidad_aerea() * 1.1:
		return false
	destino_salto = destino_x
	return true


func preparar_tormenta() -> bool:
	var origen_x: float = global_position.x
	for sentido: float in [direccion, -direccion]:
		var salida: float = origen_x + sentido * 150.0
		if pared_en_direccion(sentido) or not hay_aterrizaje_cercano(salida):
			continue
		destino_salto = salida
		destino_regreso_tormenta = origen_x
		var regreso: float = origen_x - sentido * 110.0
		if hay_aterrizaje_cercano(regreso):
			destino_regreso_tormenta = regreso
		direccion = sentido
		return true
	return false


func hay_aterrizaje_cercano(x: float) -> bool:
	var altura: float = global_position.y
	return buscar_suelo(x, altura - 54.0, altura + 94.0) != Vector2.INF


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
	if acciones_cadena == 0:
		ultimo_ataque = nuevo_ataque
	if segunda_fase:
		acciones_cadena += 1
	sentido_movimiento = direccion
	velocity.x = 0.0
	objetivo_lanzamiento = jugador.global_position
	if ataque == Ataque.CRUZADO:
		objetivo_lanzamiento.x += clampf(jugador.velocity.x * 0.25, -72.0, 72.0)
	elif ataque == Ataque.LLUVIA:
		espera_lluvia = 4.0
	elif ataque == Ataque.TORMENTA:
		espera_tormenta = ESPERA_TORMENTA
	cambiar_estado(Estado.PREPARAR)


func procesar_preparacion() -> void:
	if not jugador_disponible():
		acciones_cadena = 0
		cambiar_estado(Estado.ESPERA)
		return
	if tiempo_estado < duracion_preparacion():
		return
	match ataque:
		Ataque.DESLIZAMIENTO:
			cambiar_estado(Estado.DESLIZAR)
		Ataque.RAFAGA, Ataque.LANZAMIENTO:
			iniciar_rafaga()
		Ataque.CRUZADO, Ataque.LLUVIA, Ataque.TORMENTA:
			velocity.y = IMPULSO_LLUVIA if ataque == Ataque.LLUVIA else IMPULSO_SALTO
			latas_lanzadas = 0
			cambiar_estado(Estado.SALTAR)


func duracion_preparacion() -> float:
	if ataque == Ataque.TORMENTA:
		return DURACION_PREPARACION_TORMENTA
	return DURACION_PREPARACION * MULTIPLICADOR_PREPARACION_FASE_DOS if segunda_fase else DURACION_PREPARACION


func velocidad_deslizamiento() -> float:
	return VELOCIDAD_DESLIZAMIENTO * MULTIPLICADOR_DESLIZAMIENTO_FASE_DOS if segunda_fase else VELOCIDAD_DESLIZAMIENTO


func velocidad_aerea() -> float:
	return VELOCIDAD_AEREA * MULTIPLICADOR_SALTO_FASE_DOS if segunda_fase else VELOCIDAD_AEREA


func pared_en_direccion(sentido: float) -> bool:
	return is_on_wall() and get_wall_normal().x * sentido < 0.0


func intentar_deslizamiento(sentido: float) -> bool:
	if pared_en_direccion(sentido) or not camino_seguro(sentido, velocidad_deslizamiento(), 42.0):
		return false
	direccion = sentido
	iniciar_ataque(Ataque.DESLIZAMIENTO)
	return true


func procesar_deslizamiento() -> float:
	var rapidez := velocidad_deslizamiento()
	if tiempo_estado < DURACION_DESLIZAMIENTO and not pared_en_direccion(sentido_movimiento) and camino_seguro(sentido_movimiento, rapidez, 42.0):
		return sentido_movimiento * rapidez
	velocity.x = 0.0
	if segunda_fase:
		terminar_ataque(false)
	elif jugador_disponible() and global_position.distance_to(jugador.global_position) <= ALCANCE_LANZAMIENTO:
		direccion = signf(jugador.global_position.x - global_position.x)
		if is_zero_approx(direccion):
			direccion = sentido_movimiento
		objetivo_lanzamiento = jugador.global_position
		iniciar_rafaga()
	else:
		iniciar_recuperacion(false)
	return 0.0


func actualizar_excepcion_deslizamiento() -> void:
	if segunda_fase and estado == Estado.DESLIZAR and jugador_disponible():
		if not get_collision_exceptions().has(jugador):
			add_collision_exception_with(jugador)
			jugador_exento_deslizamiento = jugador
		return
	if is_instance_valid(jugador_exento_deslizamiento) and jugador_exento_deslizamiento.get("intangible_por_dash") != true:
		retirar_excepcion_deslizamiento()


func retirar_excepcion_deslizamiento() -> void:
	if is_instance_valid(jugador_exento_deslizamiento):
		remove_collision_exception_with(jugador_exento_deslizamiento)
	jugador_exento_deslizamiento = null


func iniciar_rafaga() -> void:
	latas_lanzadas = 0
	sentido_movimiento = direccion
	momento_lanzamiento = 0.14 if segunda_fase else 0.20
	cambiar_estado(Estado.RAFAGA)


func procesar_rafaga() -> void:
	if tiempo_estado < momento_lanzamiento:
		return
	if latas_lanzadas == cantidad_rafaga():
		terminar_ataque(ataque != Ataque.LANZAMIENTO)
		return
	if ataque == Ataque.LANZAMIENTO:
		lanzar_lata(objetivo_lanzamiento, 0.72)
	else:
		var objetivo := objetivo_lanzamiento + Vector2((latas_lanzadas - 1) * 70.0 * sentido_movimiento, 0.0)
		lanzar_lata(objetivo, 0.44 + 0.12 * latas_lanzadas)
	latas_lanzadas += 1
	momento_lanzamiento += INTERVALO_RAFAGA


func cantidad_rafaga() -> int:
	return 1 if ataque == Ataque.LANZAMIENTO else 3


func procesar_salto(delta: float) -> float:
	if (tiempo_estado > 0.06 and is_on_floor()) or tiempo_estado >= 1.85:
		if ataque == Ataque.NINGUNO:
			iniciar_recuperacion(false)
		else:
			terminar_ataque(ataque == Ataque.LLUVIA)
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
	elif ataque == Ataque.TORMENTA:
		procesar_tormenta()
	var distancia: float = destino_salto - global_position.x
	if pared_en_direccion(signf(distancia)):
		return 0.0
	return clampf(distancia / delta, -velocidad_aerea(), velocidad_aerea())


func procesar_tormenta() -> void:
	var rafaga: int = floori(float(latas_lanzadas) / LATAS_POR_RAFAGA_TORMENTA)
	if rafaga >= TIEMPOS_TORMENTA.size() or tiempo_estado < TIEMPOS_TORMENTA[rafaga]:
		return
	lanzar_rafaga_tormenta(rafaga)
	latas_lanzadas += LATAS_POR_RAFAGA_TORMENTA
	if rafaga == 0:
		destino_salto = destino_regreso_tormenta
		direccion = -sentido_movimiento


func lanzar_rafaga_tormenta(rafaga: int) -> void:
	var origen := Vector2(global_position.x, punto_lanzamiento.global_position.y)
	var paso: float = TAU / LATAS_POR_RAFAGA_TORMENTA
	var desfase: float = paso * rafaga / TIEMPOS_TORMENTA.size()
	var limite: int = MAXIMO_LATAS + LATAS_POR_RAFAGA_TORMENTA * TIEMPOS_TORMENTA.size()
	for i in LATAS_POR_RAFAGA_TORMENTA:
		var angulo: float = paso * i + desfase
		var rapidez: float = 360.0 + 45.0 * ((i + rafaga) % 3)
		crear_lata(origen, Vector2.from_angle(angulo) * rapidez, limite)


func mostrar_marcas() -> void:
	marcas_lluvia.show()
	for i in objetivos_lluvia.size():
		var marca := marcas_lluvia.get_child(i) as Line2D
		marca.global_position = objetivos_lluvia[i] - Vector2(0.0, 3.0)


func lanzar_lata(objetivo: Vector2, tiempo_vuelo: float) -> void:
	var origen := Vector2(global_position.x, punto_lanzamiento.global_position.y)
	var sentido: float = signf(objetivo.x - origen.x)
	if not is_zero_approx(sentido):
		origen.x += sentido * minf(absf(punto_lanzamiento.position.x), absf(objetivo.x - origen.x))
	var diferencia: Vector2 = objetivo - origen
	var velocidad_inicial := diferencia / tiempo_vuelo
	velocidad_inicial.y -= 0.5 * SCRIPT_LATA.GRAVEDAD * tiempo_vuelo
	if crear_lata(origen, velocidad_inicial) and ataque != Ataque.LLUVIA and not is_zero_approx(sentido):
		direccion = sentido


func crear_lata(origen: Vector2, velocidad_inicial: Vector2, limite: int = MAXIMO_LATAS) -> bool:
	if en_transicion() or estado == Estado.MUERTO or proyectiles.get_child_count() >= limite:
		return false
	var lata := ESCENA_LATA.instantiate() as SCRIPT_LATA
	lata.position = proyectiles.to_local(origen)
	lata.configurar(velocidad_inicial, jugador)
	proyectiles.add_child(lata)
	tiempo_gesto = 0.13
	return true


func terminar_ataque(con_retroceso: bool) -> void:
	if not segunda_fase:
		iniciar_recuperacion(con_retroceso)
		return
	if ataque == Ataque.TORMENTA:
		iniciar_recuperacion(false, DURACION_RECUPERACION_TORMENTA, PAUSA_ATAQUE_FASE_DOS)
		return
	if acciones_cadena < MAXIMO_ACCIONES_CADENA and is_on_floor() and encadenar_ataque():
		return
	if acciones_cadena == MAXIMO_ACCIONES_CADENA:
		iniciar_recuperacion(false, DURACION_RECUPERACION_CADENA, PAUSA_ATAQUE_FASE_DOS)
	else:
		iniciar_recuperacion(con_retroceso, DURACION_RECUPERACION_FASE_DOS, PAUSA_ATAQUE_FASE_DOS)


func encadenar_ataque() -> bool:
	if not jugador_disponible():
		return false
	var diferencia: Vector2 = jugador.global_position - global_position
	var sentido: float = direccion if is_zero_approx(diferencia.x) else signf(diferencia.x)
	match ataque:
		Ataque.CRUZADO, Ataque.RAFAGA, Ataque.LLUVIA:
			if absf(diferencia.x) <= ALCANCE_LANZAMIENTO and absf(diferencia.y) <= 90.0:
				return intentar_deslizamiento(sentido)
		Ataque.DESLIZAMIENTO:
			if absf(diferencia.x) <= ALCANCE_LANZAMIENTO_LEJANO and absf(diferencia.y) <= 130.0:
				direccion = sentido
				iniciar_ataque(Ataque.LANZAMIENTO)
				return true
	return false


func iniciar_recuperacion(con_retroceso: bool, duracion: float = DURACION_RECUPERACION, pausa: float = PAUSA_ATAQUE) -> void:
	acciones_cadena = 0
	retroceder = con_retroceso
	duracion_recuperacion = duracion
	espera_ataque = duracion + pausa
	cambiar_estado(Estado.RECUPERAR)


func procesar_recuperacion() -> float:
	if tiempo_estado >= duracion_recuperacion:
		cambiar_estado(Estado.PERSEGUIR)
	elif tiempo_estado < 0.19 and retroceder and is_on_floor() and camino_seguro(-direccion, 225.0, 34.0):
		return -direccion * 225.0
	return 0.0


func cambiar_estado(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	tiempo_estado = 0.0
	aviso_lata.hide()
	aviso_tormenta.hide()
	if estado != Estado.SALTAR:
		marcas_lluvia.hide()
		rastro_tormenta.clear_points()


func en_transicion() -> bool:
	return estado == Estado.REGRESAR or estado == Estado.CARGAR_EXPLOSION or estado == Estado.EXPLOTAR


func iniciar_transicion() -> void:
	transicion_activada = true
	acciones_cadena = 0
	presion_cercana = false
	espera_interrupcion = 0.0
	tiempo_destello_golpe = 0.0
	ataque = Ataque.NINGUNO
	latas_lanzadas = 0
	objetivos_lluvia.clear()
	tiempo_gesto = 0.0
	retroceder = false
	velocity = Vector2.ZERO
	inicio_regreso = global_position
	if not is_zero_approx(posicion_inicial.x - inicio_regreso.x):
		direccion = signf(posicion_inicial.x - inicio_regreso.x)
	limpiar_proyectiles()
	colision_suspendida = not colision.disabled
	if colision_suspendida:
		colision.set_deferred("disabled", true)
	cambiar_estado(Estado.REGRESAR)


func procesar_transicion() -> void:
	match estado:
		Estado.REGRESAR:
			procesar_regreso()
		Estado.CARGAR_EXPLOSION:
			if tiempo_estado >= DURACION_CARGA:
				cambiar_estado(Estado.EXPLOTAR)
				actualizar_onda(0.0)
				aplicar_explosion()
			else:
				actualizar_carga()
		Estado.EXPLOTAR:
			if tiempo_estado >= DURACION_EXPLOSION:
				efecto_explosion.hide()
				segunda_fase = true
				sprite.self_modulate = COLOR_SEGUNDA_FASE
				iniciar_recuperacion(false)
			else:
				actualizar_onda(tiempo_estado / DURACION_EXPLOSION)


func procesar_regreso() -> void:
	var avance: float = clampf(tiempo_estado / DURACION_REGRESO, 0.0, 1.0)
	if avance >= 1.0:
		global_position = posicion_inicial
		restaurar_colision_regreso()
		iniciar_carga()
		return
	var altura: float = minf(inicio_regreso.distance_to(posicion_inicial) * 0.2, 90.0)
	global_position = inicio_regreso.lerp(posicion_inicial, smoothstep(0.0, 1.0, avance))
	global_position.y -= sin(PI * avance) * altura


func restaurar_colision_regreso() -> void:
	if colision_suspendida:
		colision_suspendida = false
		colision.set_deferred("disabled", false)


func iniciar_carga() -> void:
	radio_activo = maxf(radio_explosion, 16.0)
	efecto_explosion.global_position = colision.global_position
	var contorno := PackedVector2Array()
	for i in 96:
		contorno.append(Vector2.from_angle(TAU * i / 96.0))
	resplandor_explosion.polygon = contorno
	resplandor_explosion.scale = Vector2.ONE * radio_activo
	circulo_explosion.points = contorno
	circulo_explosion.scale = Vector2.ONE * radio_activo
	onda_explosion.points = contorno
	onda_explosion.hide()
	efecto_explosion.show()
	cambiar_estado(Estado.CARGAR_EXPLOSION)
	actualizar_carga()


func actualizar_carga() -> void:
	var avance: float = tiempo_estado / DURACION_CARGA
	var pulso: float = pulso_carga()
	circulo_explosion.default_color = Color(1.0, 0.46 + 0.36 * avance, 0.12, 0.55 + 0.25 * avance + 0.18 * pulso)
	resplandor_explosion.color = Color(0.97, 0.30, 0.07, 0.09 + 0.15 * avance + 0.06 * pulso)


func pulso_carga() -> float:
	return 0.5 + 0.5 * sin(TAU * tiempo_estado * (1.2 + 0.48 * tiempo_estado))


func actualizar_onda(avance: float) -> void:
	var intensidad: float = 1.0 - avance
	onda_explosion.show()
	onda_explosion.scale = Vector2.ONE * radio_activo * lerpf(0.08, 1.0, ease(avance, 0.35))
	onda_explosion.default_color = Color(1.0, 0.91, 0.49, intensidad)
	circulo_explosion.default_color = Color(1.0, 0.64, 0.15, intensidad)
	resplandor_explosion.color = Color(1.0, 0.68, 0.22, intensidad * 0.56)


func aplicar_explosion() -> void:
	if not jugador_disponible() or not jugador.has_method("recibir_golpe"):
		return
	if jugador.get("invulnerable") == true or jugador.get("intangible_por_dash") == true:
		return
	var distancia: float = efecto_explosion.global_position.distance_squared_to(jugador.global_position)
	if distancia <= radio_activo * radio_activo:
		jugador.call("recibir_golpe", DANIO_EXPLOSION)


func limpiar_proyectiles() -> void:
	for lata in proyectiles.get_children():
		lata.queue_free()


func actualizar_animacion() -> void:
	sprite.flip_h = direccion < 0.0
	punto_lanzamiento.position.x = 20.0 * direccion
	sprite.position = Vector2(0.0, -46.0)
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
			aviso_lata.visible = ataque == Ataque.RAFAGA or ataque == Ataque.LANZAMIENTO
			if ataque == Ataque.DESLIZAMIENTO:
				sprite.scale = Vector2(1.12, 0.78)
				sprite.position.y = -36.0
				sprite.modulate = Color(1.0, 0.76, 0.47)
			elif ataque == Ataque.TORMENTA:
				mostrar_preparacion_tormenta()
		Estado.DESLIZAR:
			sprite.scale = Vector2(1.17, 0.68)
			sprite.position.y = -31.0
			sprite.rotation = 0.26 * direccion
		Estado.SALTAR:
			sprite.rotation = -0.14 * sentido_movimiento
			sprite.scale = Vector2(0.94, 1.06)
			aviso_lata.visible = ataque != Ataque.NINGUNO and latas_lanzadas == 0
			if ataque == Ataque.TORMENTA:
				mostrar_rastro_tormenta()
		Estado.RAFAGA:
			aviso_lata.visible = tiempo_gesto == 0.0 and latas_lanzadas < cantidad_rafaga()
			sprite.rotation = -0.12 * direccion
		Estado.RECUPERAR:
			sprite.rotation = 0.15 * direccion * (1.0 - tiempo_estado / duracion_recuperacion)
			if ataque == Ataque.TORMENTA:
				sprite.position.y = -40.0
				sprite.scale = Vector2(1.03, 0.87)
		Estado.HERIDO:
			sprite.modulate = Color(1.0, 0.48, 0.48)
			sprite.rotation = -0.1 * direccion
		Estado.REGRESAR:
			sprite.scale = Vector2(1.14, 0.86)
			sprite.rotation = 0.2 * direccion
			sprite.modulate = Color(1.0, 0.74, 0.36, 0.72)
		Estado.CARGAR_EXPLOSION:
			var brillo: float = pulso_carga() * tiempo_estado / DURACION_CARGA
			sprite.modulate = Color(1.0, 0.44 + brillo * 0.52, 0.22 + brillo * 0.62)
			sprite.position.x = sin(tiempo_estado * 46.0) * brillo * 3.0
		Estado.EXPLOTAR:
			sprite.modulate = Color(1.0, 0.92, 0.65)
			sprite.scale = Vector2.ONE * lerpf(1.15, 1.0, tiempo_estado / DURACION_EXPLOSION)
	if tiempo_gesto > 0.0 and (estado == Estado.SALTAR or estado == Estado.RAFAGA):
		sprite.rotation = 0.24 * direccion
	if tiempo_destello_golpe > 0.0:
		var intensidad: float = tiempo_destello_golpe / DURACION_HERIDO
		sprite.modulate = sprite.modulate.lerp(Color(1.0, 0.36, 0.36), intensidad)
	aviso_lata.rotation = -0.45 * direccion


func mostrar_preparacion_tormenta() -> void:
	var avance: float = clampf(tiempo_estado / DURACION_PREPARACION_TORMENTA, 0.0, 1.0)
	aviso_tormenta.show()
	aviso_tormenta.scale = Vector2.ONE * lerpf(0.78, 1.15, avance)
	aviso_tormenta.rotation = sin(avance * TAU) * 0.14
	sprite.modulate = Color(0.72, 0.90, 1.0)
	sprite.scale = Vector2(1.08, 0.88)
	sprite.position.y = -40.0


func mostrar_rastro_tormenta() -> void:
	sprite.modulate = Color(0.82, 0.94, 1.0)
	if absf(get_real_velocity().x) > 20.0 and tiempo_gesto == 0.0:
		direccion = signf(get_real_velocity().x)
		sprite.flip_h = direccion < 0.0
		sprite.rotation = 0.21 * direccion
	rastro_tormenta.add_point(rastro_tormenta.to_local(colision.global_position))
	if rastro_tormenta.get_point_count() > PUNTOS_RASTRO_TORMENTA:
		rastro_tormenta.remove_point(0)


func recibir_golpe(cantidad: int = 1) -> void:
	if estado == Estado.MUERTO or en_transicion() or cantidad <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	actualizar_barra_vida()
	if vida == 0:
		morir()
	elif not transicion_activada and vida <= VIDA_MAXIMA * 0.5:
		iniciar_transicion()
	else:
		reaccionar_al_golpe()


func reaccionar_al_golpe() -> void:
	tiempo_destello_golpe = DURACION_HERIDO
	if estado == Estado.RECUPERAR or (ataque == Ataque.TORMENTA and (estado == Estado.PREPARAR or estado == Estado.SALTAR)):
		return
	if jugador_disponible():
		var diferencia: Vector2 = jugador.global_position - global_position
		if absf(diferencia.x) <= DISTANCIA_PRESION_CERCANA and absf(diferencia.y) <= 90.0:
			presion_cercana = true
	if espera_interrupcion > 0.0:
		return
	espera_interrupcion = INTERVALO_INTERRUPCION
	acciones_cadena = 0
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
	colision_suspendida = false
	colision.set_deferred("disabled", true)
	retirar_excepcion_deslizamiento()
	efecto_explosion.hide()
	limpiar_proyectiles()
	derrotado.emit()
