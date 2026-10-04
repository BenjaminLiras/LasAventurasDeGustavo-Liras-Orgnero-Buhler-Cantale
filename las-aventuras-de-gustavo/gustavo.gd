extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ataqueSimpleEscena = preload("res://ataqueBase.tscn")
const SPRITE_SHEET = preload("res://assets/asstesgustavo_sin_fondo.png")
const DASH_DURATION = 0.3
const UMBRAL_STICK = 0.2
const FRAME_WIDTH = 112
const FRAME_HEIGHT = 160

const FRAMES_IDLE = [Rect2i(218, 110, 96, 160), Rect2i(314, 110, 96, 160), Rect2i(410, 110, 96, 160), Rect2i(506, 110, 96, 160), Rect2i(602, 110, 96, 160)]
const FRAMES_RUN = [Rect2i(758, 110, 120, 160), Rect2i(878, 110, 100, 160), Rect2i(978, 110, 98, 160), Rect2i(1076, 110, 100, 160), Rect2i(1176, 110, 84, 160), Rect2i(1256, 110, 90, 160), Rect2i(1346, 110, 90, 160), Rect2i(1436, 110, 100, 160)]
const FRAMES_JUMP = [Rect2i(32, 400, 96, 100), Rect2i(117, 355, 96, 120), Rect2i(227, 325, 96, 135), Rect2i(437, 365, 96, 135)]
const FRAMES_ATTACK = [Rect2i(620, 350, 96, 150), Rect2i(736, 350, 96, 150), Rect2i(852, 350, 96, 150), Rect2i(966, 350, 104, 150), Rect2i(1085, 350, 102, 150), Rect2i(1207, 350, 96, 150), Rect2i(1324, 350, 96, 150), Rect2i(1410, 350, 100, 150)]
var vidaMaxima: int = 100
var duracion_invulnerabilidad: float = 0.5

var DASH_DIRECTION : Vector2
var direction: Vector2 = Vector2(0,0)
var ultimaDireccionDeApuntado: Vector2 = Vector2.RIGHT
var dashActivo = false
var dashEnCooldown = false
var vida: int
var invulnerable := false

func _ready() -> void:
	vida = vidaMaxima
	$AnimatedSprite2D.sprite_frames = crear_animaciones()
	$AnimatedSprite2D.play("quieto")
	actualizar_vida_ui()


func _process(delta: float) -> void:
	$Camera2D/Velocidad.text = "velocidad:" + str(Global.getVelocidad())
	$Camera2D/Dash.text = "Dash:" + str(Global.getDash())
	$Camera2D/Direccion.text = "Direccion:x" + str(Global.getDireccion().x) + "y" + str(Global.getDireccion().y)
	actualizar_vida_ui()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

	
	direction = obtenerDireccionDeMovimiento()
	# Actualiza continuamente el apuntado y conserva la última dirección al soltar el stick.
	obtenerDireccionDeApuntado()

	if Input.is_action_just_pressed("dash") :
		dash()
		
	if Input.is_action_just_pressed("ataqueSimple") :
		ataqueSimple()
	if !dashEnCooldown:
		if direction:
			velocity.x = direction.x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	actualizar_animacion()
	Global.setVelocidad(velocity)
	Global.setDireccion(direction)
	Global.setDash(dashActivo)


func dash() -> void:
	if dashActivo or dashEnCooldown:
		return	
	dashActivo = true
	dashEnCooldown = true
	DASH_DIRECTION = obtenerDireccionDeApuntado()
	velocity = DASH_DIRECTION * 700.0
	await get_tree().create_timer(DASH_DURATION).timeout
	dashActivo = false
	await get_tree().create_timer(0.2).timeout
	dashEnCooldown = false

func ataqueSimple() -> void:
	var ataqueDireccion := obtenerDireccionDeApuntado()
	$AnimatedSprite2D.play("ataque")
	$AnimatedSprite2D.flip_h = ataqueDireccion.x < 0.0
	var ataqueSimple := ataqueSimpleEscena.instantiate() as Area2D
	add_child(ataqueSimple)
	ataqueSimple.position = ataqueDireccion * 20.0
	ataqueSimple.global_rotation = ataqueDireccion.angle()


func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or invulnerable or vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	actualizar_vida_ui()
	if vida == 0:
		queue_free()
		return
	invulnerable = true
	await get_tree().create_timer(duracion_invulnerabilidad).timeout
	invulnerable = false


func actualizar_vida_ui() -> void:
	var indicador: Label = get_node_or_null("Camera2D/Vida")
	if indicador != null:
		indicador.text = "Vida: %d/%d" % [vida, vidaMaxima]


func obtenerDireccionDeApuntado() -> Vector2:
	var mandos := Input.get_connected_joypads()
	if not mandos.is_empty():
		var mando := mandos[0]
		var direccionStick := Vector2(
			Input.get_joy_axis(mando, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(mando, JOY_AXIS_RIGHT_Y)
		)
		if direccionStick.length() >= UMBRAL_STICK:
			ultimaDireccionDeApuntado = direccionStick.normalized()
		return ultimaDireccionDeApuntado

	var direccionRaton := (get_global_mouse_position() - global_position).normalized()
	if direccionRaton != Vector2.ZERO:
		ultimaDireccionDeApuntado = direccionRaton
	return ultimaDireccionDeApuntado


func obtenerDireccionDeMovimiento() -> Vector2:
	var direccionTeclado := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var mandos := Input.get_connected_joypads()
	if mandos.is_empty():
		return direccionTeclado

	var mando := mandos[0]
	var stickIzquierdo := Vector2(
		Input.get_joy_axis(mando, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(mando, JOY_AXIS_LEFT_Y)
	)
	if stickIzquierdo.length() >= UMBRAL_STICK:
		return stickIzquierdo.limit_length()
	return direccionTeclado


func actualizar_animacion() -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.animation == "ataque" and sprite.is_playing():
		return
	var animacion := "quieto"
	if not is_on_floor():
		animacion = "salto"
	elif absf(velocity.x) > 10.0:
		animacion = "correr"
	if sprite.animation != animacion:
		sprite.play(animacion)
	sprite.flip_h = ultimaDireccionDeApuntado.x < 0.0 if animacion == "quieto" else velocity.x < 0.0


func crear_animaciones() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.clear_all()
	var imagen_original: Image = SPRITE_SHEET.get_image()
	agregar_animacion(frames, imagen_original, "quieto", FRAMES_IDLE, 7.0, true)
	agregar_animacion(frames, imagen_original, "correr", FRAMES_RUN, 12.0, true)
	agregar_animacion(frames, imagen_original, "salto", FRAMES_JUMP, 8.0, true)
	agregar_animacion(frames, imagen_original, "ataque", FRAMES_ATTACK, 24.0, false)
	return frames


func agregar_animacion(frames: SpriteFrames, imagen_original: Image, nombre: String, regiones: Array, fps: float, en_bucle: bool) -> void:
	frames.add_animation(nombre)
	frames.set_animation_speed(nombre, fps)
	frames.set_animation_loop(nombre, en_bucle)

	for region in regiones:
		var imagen_cuadro := imagen_original.get_region(region)
		var limites := imagen_cuadro.get_used_rect()
		var imagen_normalizada := Image.create(FRAME_WIDTH, FRAME_HEIGHT, false, Image.FORMAT_RGBA8)
		imagen_normalizada.fill(Color.TRANSPARENT)
		var destino := Vector2i(floori(float(FRAME_WIDTH - limites.size.x) / 2.0), FRAME_HEIGHT - limites.size.y - 3)
		imagen_normalizada.blit_rect(imagen_cuadro, limites, destino)
		frames.add_frame(nombre, ImageTexture.create_from_image(imagen_normalizada))
func _on_area_2d_body_entered(body: Node2D) -> void:
	dashActivo = false
	if body.has_method("obtener_daño_contacto"):
		recibir_golpe(int(body.call("obtener_daño_contacto")))
