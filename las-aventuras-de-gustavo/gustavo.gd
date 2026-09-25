extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ataqueSimpleEscena = preload("res://ataqueBase.tscn")
const SPRITE_SHEET = preload("res://assets/asstesgustavo.png")
const DASH_DURATION = 0.3
const FRAME_WIDTH = 112
const FRAME_HEIGHT = 160

const FRAMES_IDLE = [Rect2i(218, 110, 96, 160), Rect2i(314, 110, 96, 160), Rect2i(410, 110, 96, 160), Rect2i(506, 110, 96, 160), Rect2i(602, 110, 96, 160)]
const FRAMES_RUN = [Rect2i(758, 110, 120, 160), Rect2i(878, 110, 100, 160), Rect2i(978, 110, 98, 160), Rect2i(1076, 110, 100, 160), Rect2i(1176, 110, 84, 160), Rect2i(1256, 110, 90, 160), Rect2i(1346, 110, 90, 160), Rect2i(1436, 110, 100, 160)]
const FRAMES_JUMP = [Rect2i(32, 400, 96, 100), Rect2i(117, 355, 96, 120), Rect2i(227, 325, 96, 135), Rect2i(437, 365, 96, 135)]
const FRAMES_ATTACK = [Rect2i(620, 350, 96, 150), Rect2i(736, 350, 96, 150), Rect2i(852, 350, 96, 150), Rect2i(966, 350, 104, 150), Rect2i(1085, 350, 102, 150), Rect2i(1207, 350, 96, 150), Rect2i(1324, 350, 96, 150), Rect2i(1410, 350, 100, 150)]

var DASH_DIRECTION : Vector2
var direction: Vector2 = Vector2(0,0)
var ultimaDireccionDeApuntado: Vector2 = Vector2.RIGHT
var dashActivo = false
var dashEnCooldown = false

func _ready() -> void:
	$AnimatedSprite2D.sprite_frames = crear_animaciones()
	$AnimatedSprite2D.play("quieto")


func _process(delta: float) -> void:
	$Camera2D/Velocidad.text = "velocidad:" + str(Global.getVelocidad())
	$Camera2D/Dash.text = "Dash:" + str(Global.getDash())
	$Camera2D/Direccion.text = "Direccion:x" + str(Global.getDireccion().x) + "y" + str(Global.getDireccion().y)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

	
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

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


func obtenerDireccionDeApuntado() -> Vector2:
	var direccionStick := Input.get_vector("apuntar_izquierda", "apuntar_derecha", "apuntar_arriba", "apuntar_abajo")
	if direccionStick.length() >= 0.25:
		ultimaDireccionDeApuntado = direccionStick.normalized()
		return ultimaDireccionDeApuntado

	if not Input.get_connected_joypads().is_empty():
		return ultimaDireccionDeApuntado
	var direccionRaton := (get_global_mouse_position() - global_position).normalized()
	if direccionRaton != Vector2.ZERO:
		ultimaDireccionDeApuntado = direccionRaton
	return ultimaDireccionDeApuntado


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
		imagen_cuadro.convert(Image.FORMAT_RGBA8)
		hacer_fondo_transparente(imagen_cuadro)
		quitar_componentes_separados(imagen_cuadro)
		var limites := imagen_cuadro.get_used_rect()
		var imagen_normalizada := Image.create(FRAME_WIDTH, FRAME_HEIGHT, false, Image.FORMAT_RGBA8)
		imagen_normalizada.fill(Color.TRANSPARENT)
		var destino := Vector2i(floori(float(FRAME_WIDTH - limites.size.x) / 2.0), FRAME_HEIGHT - limites.size.y - 3)
		imagen_normalizada.blit_rect(imagen_cuadro, limites, destino)
		frames.add_frame(nombre, ImageTexture.create_from_image(imagen_normalizada))


func quitar_componentes_separados(imagen: Image) -> void:
	var ancho := imagen.get_width()
	var alto := imagen.get_height()
	var identificadores: Array[int] = []
	identificadores.resize(ancho * alto)
	identificadores.fill(0)
	var identificador_mayor := 0
	var tamano_mayor := 0
	var proximo_identificador := 0

	for indice_inicial in ancho * alto:
		var color_inicial := imagen.get_pixel(indice_inicial % ancho, floori(float(indice_inicial) / float(ancho)))
		if color_inicial.a == 0.0 or identificadores[indice_inicial] != 0:
			continue
		proximo_identificador += 1
		var tamano_componente := 1
		var cola: Array[int] = [indice_inicial]
		identificadores[indice_inicial] = proximo_identificador
		var siguiente := 0
		while siguiente < cola.size():
			var indice := cola[siguiente]
			siguiente += 1
			var x := indice % ancho
			var y: int = floori(float(indice) / float(ancho))
			if x > 0:
				tamano_componente += agregar_pixel_de_componente(imagen, x - 1, y, ancho, proximo_identificador, identificadores, cola)
			if x < ancho - 1:
				tamano_componente += agregar_pixel_de_componente(imagen, x + 1, y, ancho, proximo_identificador, identificadores, cola)
			if y > 0:
				tamano_componente += agregar_pixel_de_componente(imagen, x, y - 1, ancho, proximo_identificador, identificadores, cola)
			if y < alto - 1:
				tamano_componente += agregar_pixel_de_componente(imagen, x, y + 1, ancho, proximo_identificador, identificadores, cola)

		if tamano_componente > tamano_mayor:
			tamano_mayor = tamano_componente
			identificador_mayor = proximo_identificador

	for indice in ancho * alto:
		if identificadores[indice] != 0 and identificadores[indice] != identificador_mayor:
			imagen.set_pixel(indice % ancho, floori(float(indice) / float(ancho)), Color.TRANSPARENT)


func agregar_pixel_de_componente(imagen: Image, x: int, y: int, ancho: int, identificador: int, identificadores: Array[int], cola: Array[int]) -> int:
	var indice := y * ancho + x
	if identificadores[indice] != 0 or imagen.get_pixel(x, y).a == 0.0:
		return 0
	identificadores[indice] = identificador
	cola.append(indice)
	return 1


func hacer_fondo_transparente(imagen: Image) -> void:
	var ancho := imagen.get_width()
	var alto := imagen.get_height()
	var color_fondo := obtener_color_del_fondo(imagen)
	var cola: Array[int] = []

	for x in ancho:
		agregar_pixel_de_fondo(imagen, x, 0, color_fondo, cola)
		agregar_pixel_de_fondo(imagen, x, alto - 1, color_fondo, cola)
	for y in alto:
		agregar_pixel_de_fondo(imagen, 0, y, color_fondo, cola)
		agregar_pixel_de_fondo(imagen, ancho - 1, y, color_fondo, cola)

	var siguiente := 0
	while siguiente < cola.size():
		var indice := cola[siguiente]
		siguiente += 1
		var x := indice % ancho
		var y: int = floori(float(indice) / float(ancho))
		if x > 0:
			agregar_pixel_de_fondo(imagen, x - 1, y, color_fondo, cola)
		if x < ancho - 1:
			agregar_pixel_de_fondo(imagen, x + 1, y, color_fondo, cola)
		if y > 0:
			agregar_pixel_de_fondo(imagen, x, y - 1, color_fondo, cola)
		if y < alto - 1:
			agregar_pixel_de_fondo(imagen, x, y + 1, color_fondo, cola)


func obtener_color_del_fondo(imagen: Image) -> Color:
	var rojos: Array[float] = []
	var verdes: Array[float] = []
	var azules: Array[float] = []
	var ancho := imagen.get_width()
	var alto := imagen.get_height()

	for x in range(0, ancho, 4):
		agregar_color_borde(imagen, x, 0, rojos, verdes, azules)
		agregar_color_borde(imagen, x, alto - 1, rojos, verdes, azules)
	for y in range(0, alto, 4):
		agregar_color_borde(imagen, 0, y, rojos, verdes, azules)
		agregar_color_borde(imagen, ancho - 1, y, rojos, verdes, azules)

	rojos.sort()
	verdes.sort()
	azules.sort()
	var medio := floori(float(rojos.size()) / 2.0)
	return Color(rojos[medio], verdes[medio], azules[medio])


func agregar_color_borde(imagen: Image, x: int, y: int, rojos: Array[float], verdes: Array[float], azules: Array[float]) -> void:
	var color := imagen.get_pixel(x, y)
	rojos.append(color.r)
	verdes.append(color.g)
	azules.append(color.b)


func agregar_pixel_de_fondo(imagen: Image, x: int, y: int, color_fondo: Color, cola: Array[int]) -> void:
	var color := imagen.get_pixel(x, y)
	if color.a > 0.0 and Vector3(color.r - color_fondo.r, color.g - color_fondo.g, color.b - color_fondo.b).length() < 0.085:
		imagen.set_pixel(x, y, Color.TRANSPARENT)
		cola.append(y * imagen.get_width() + x)





func _on_area_2d_body_entered(body: Node2D) -> void:
	dashActivo = false
