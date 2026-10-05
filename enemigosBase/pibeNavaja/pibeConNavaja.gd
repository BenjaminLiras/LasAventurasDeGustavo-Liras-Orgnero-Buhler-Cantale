extends CharacterBody2D

const SPRITE_SHEET = preload("res://assets/EnemigoNavajero/sprite_navajero_sin_fondo.png")
const FRAME_SIZE := Vector2i(32, 32)
const VELOCIDAD := 75.0
const ALCANCE_ATAQUE := 54.0
const DANIO := 10
const DURACION_ATAQUE := 0.34
const ESPERA_ATAQUE := 0.85

var vida := 3
var jugador: Node2D
var direccion := 1.0
var tiempo_ataque := 0.0
var espera_ataque := 0.0
var golpe_aplicado := false


func _ready() -> void:
	$AnimatedSprite2D.sprite_frames = crear_animaciones()
	$AnimatedSprite2D.play("quieto")
	jugador = get_tree().get_first_node_in_group("jugador") as Node2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		velocity.x = 0.0
		reproducir_animacion("quieto")
		move_and_slide()
		return

	espera_ataque = maxf(espera_ataque - delta, 0.0)
	if tiempo_ataque > 0.0:
		procesar_ataque(delta)
	elif enemigo_en_camara():
		perseguir_o_atacar()
	else:
		velocity.x = 0.0
		reproducir_animacion("quieto")

	$AnimatedSprite2D.flip_h = direccion < 0.0
	move_and_slide()


func perseguir_o_atacar() -> void:
	direccion = signf(jugador.global_position.x - global_position.x)
	if direccion == 0.0:
		direccion = 1.0
	if absf(jugador.global_position.x - global_position.x) > ALCANCE_ATAQUE:
		velocity.x = direccion * VELOCIDAD
		reproducir_animacion("caminar")
	elif espera_ataque == 0.0:
		velocity.x = 0.0
		tiempo_ataque = DURACION_ATAQUE
		golpe_aplicado = false
		reproducir_animacion("quieto")
	else:
		velocity.x = 0.0
		reproducir_animacion("quieto")


func procesar_ataque(delta: float) -> void:
	tiempo_ataque -= delta
	$Navaja.visible = tiempo_ataque <= DURACION_ATAQUE * 0.55 and tiempo_ataque > 0.0
	$Navaja.scale.x = direccion
	$Navaja.position.x = direccion * 9.0
	velocity.x = direccion * VELOCIDAD * 1.6 if $Navaja.visible else 0.0
	reproducir_animacion("caminar" if $Navaja.visible else "quieto")

	if $Navaja.visible and not golpe_aplicado:
		var diferencia := jugador.global_position - global_position
		if absf(diferencia.x) <= ALCANCE_ATAQUE and absf(diferencia.y) <= 40.0:
			if jugador.has_method("recibir_golpe"):
				jugador.call("recibir_golpe", DANIO)
			golpe_aplicado = true

	if tiempo_ataque <= 0.0:
		$Navaja.visible = false
		espera_ataque = ESPERA_ATAQUE


func reproducir_animacion(nombre: String) -> void:
	if $AnimatedSprite2D.animation != nombre:
		$AnimatedSprite2D.play(nombre)


func enemigo_en_camara() -> bool:
	var camara := get_viewport().get_camera_2d()
	if camara == null:
		return false
	var posicion_pantalla := get_viewport().get_canvas_transform() * global_position
	return get_viewport().get_visible_rect().has_point(posicion_pantalla)


func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	if vida == 0:
		queue_free()


func crear_animaciones() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	agregar_animacion(frames, "quieto", [0], 1.0, true)
	agregar_animacion(frames, "caminar", [0, 1], 6.0, true)
	return frames


func agregar_animacion(frames: SpriteFrames, nombre: String, indices: Array, fps: float, repetir: bool) -> void:
	frames.add_animation(nombre)
	frames.set_animation_speed(nombre, fps)
	frames.set_animation_loop(nombre, repetir)
	for indice in indices:
		var cuadro := AtlasTexture.new()
		cuadro.atlas = SPRITE_SHEET
		cuadro.region = Rect2(indice * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(nombre, cuadro)
