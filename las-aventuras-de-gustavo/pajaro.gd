extends CharacterBody2D


enum Estado { PATRULLA, AVISO, PICADA, REGRESO, HERIDO, MUERTO }

const SPRITES = preload("res://assets/Bird/Bird_v002_blue_and_yellow_small.png")
const ANCHO_CUADRO := 32
const ALTO_CUADRO := 21

var vida_maxima := 3
var dano_picada := 12
var alcance_patrulla := 150.0
var velocidad_patrulla := 95.0
var velocidad_picada := 390.0
var distancia_alerta := 260.0

var vida := 3
var estado := Estado.PATRULLA
var origen := Vector2.ZERO
var direccion := 1.0
var tiempo := 0.0
var tiempo_total := 0.0
var espera_ataque := 0.0
var destino_picada := Vector2.ZERO
var golpeo_en_picada := false
var jugador: Node2D


func _ready() -> void:
	vida = vida_maxima
	origen = global_position
	$AnimatedSprite2D.sprite_frames = crear_animaciones()
	$AnimatedSprite2D.play("volar")
	jugador = get_tree().get_first_node_in_group("jugador") as Node2D


func _physics_process(delta: float) -> void:
	if estado == Estado.MUERTO:
		return
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D

	tiempo += delta
	tiempo_total += delta
	espera_ataque = maxf(espera_ataque - delta, 0.0)

	match estado:
		Estado.PATRULLA:
			patrullar(delta)
		Estado.AVISO:
			avisar(delta)
		Estado.PICADA:
			hacer_picada(delta)
		Estado.REGRESO:
			regresar(delta)
		Estado.HERIDO:
			if tiempo >= 0.28:
				$AnimatedSprite2D.modulate = Color.WHITE
				$AnimatedSprite2D.play("volar")
				cambiar_estado(Estado.REGRESO)


func patrullar(delta: float) -> void:
	global_position.x += direccion * velocidad_patrulla * delta
	if absf(global_position.x - origen.x) >= alcance_patrulla:
		global_position.x = clampf(global_position.x, origen.x - alcance_patrulla, origen.x + alcance_patrulla)
		direccion *= -1.0
	global_position.y = origen.y + sin(tiempo_total * 4.0) * 8.0
	$AnimatedSprite2D.flip_h = direccion < 0.0

	if espera_ataque <= 0.0 and is_instance_valid(jugador):
		var separacion := jugador.global_position - global_position
		if absf(separacion.x) <= distancia_alerta and absf(separacion.y) <= 170.0:
			cambiar_estado(Estado.AVISO)


func avisar(delta: float) -> void:
	global_position.y = move_toward(global_position.y, origen.y - 20.0, 70.0 * delta)
	$AnimatedSprite2D.modulate = Color(1.0, 0.55, 0.35) if int(tiempo * 12.0) % 2 == 0 else Color.WHITE
	if tiempo >= 0.55:
		if not is_instance_valid(jugador):
			$AnimatedSprite2D.modulate = Color.WHITE
			cambiar_estado(Estado.REGRESO)
			return
		destino_picada = Vector2(
			clampf(jugador.global_position.x, origen.x - alcance_patrulla - 100.0, origen.x + alcance_patrulla + 100.0),
			jugador.global_position.y - 12.0
		)
		$AnimatedSprite2D.modulate = Color.WHITE
		$AnimatedSprite2D.flip_h = destino_picada.x < global_position.x
		golpeo_en_picada = false
		cambiar_estado(Estado.PICADA)


func hacer_picada(delta: float) -> void:
	global_position = global_position.move_toward(destino_picada, velocidad_picada * delta)
	if not golpeo_en_picada:
		for cuerpo in $AreaDeContacto.get_overlapping_bodies():
			if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_golpe"):
				cuerpo.recibir_golpe(dano_picada)
				golpeo_en_picada = true
				break
	if golpeo_en_picada or global_position.distance_to(destino_picada) < 8.0 or tiempo >= 0.9:
		espera_ataque = 1.4
		cambiar_estado(Estado.REGRESO)


func regresar(delta: float) -> void:
	global_position = global_position.move_toward(origen, velocidad_patrulla * 1.6 * delta)
	if global_position.distance_to(origen) < 6.0:
		cambiar_estado(Estado.PATRULLA)


func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or vida <= 0 or estado == Estado.HERIDO:
		return
	vida = maxi(vida - cantidad, 0)
	if vida == 0:
		morir()
		return
	$AnimatedSprite2D.modulate = Color(1.0, 0.35, 0.35)
	$AnimatedSprite2D.play("herido")
	espera_ataque = 0.9
	cambiar_estado(Estado.HERIDO)


func obtener_daño_contacto() -> int:
	return dano_picada if estado == Estado.PICADA and not golpeo_en_picada else 0


func morir() -> void:
	cambiar_estado(Estado.MUERTO)
	collision_layer = 0
	$AreaDeContacto.collision_mask = 0
	$AnimatedSprite2D.modulate = Color.WHITE
	$AnimatedSprite2D.play("morir")
	await $AnimatedSprite2D.animation_finished
	queue_free()


func cambiar_estado(nuevo_estado: Estado) -> void:
	estado = nuevo_estado
	tiempo = 0.0


func crear_animaciones() -> SpriteFrames:
	var animaciones := SpriteFrames.new()
	animaciones.clear_all()
	agregar_animacion(animaciones, "volar", 7, 4, 12.0, true)
	agregar_animacion(animaciones, "herido", 0, 3, 12.0, false)
	agregar_animacion(animaciones, "morir", 0, 9, 14.0, false)
	return animaciones


func agregar_animacion(animaciones: SpriteFrames, nombre: String, fila: int, cuadros: int, fps: float, repetir: bool) -> void:
	animaciones.add_animation(nombre)
	animaciones.set_animation_speed(nombre, fps)
	animaciones.set_animation_loop(nombre, repetir)
	for columna in cuadros:
		var cuadro := AtlasTexture.new()
		cuadro.atlas = SPRITES
		cuadro.region = Rect2(columna * ANCHO_CUADRO, fila * ALTO_CUADRO, ANCHO_CUADRO, ALTO_CUADRO)
		animaciones.add_frame(nombre, cuadro)
