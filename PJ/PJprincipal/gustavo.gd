extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ataqueSimpleEscena = preload("res://PJ/ataqueSimple/ataqueBase.tscn")
const SPRITE_SHEET = preload("res://assets/asstesgustavo_sin_fondo.png")
const DASH_DURATION = 0.3
const UMBRAL_STICK = 0.2
const FRAME_WIDTH = 112
const FRAME_HEIGHT = 160
const CAPA_COLISION_PLATAFORMA = 4
const TIEMPO_MAXIMO_CAIDA_PLATAFORMA = 0.75
const CAPA_COLISION_ENEMIGOS = 2
const VENTANA_COMBO = 0.1
const COOLDOWN_ATAQUE_SIMPLE = 0.2
const DANIO_ATAQUE_COMBO = 3
const ESCALA_ATAQUE_COMBO = 1.5

const FRAMES_IDLE = [Rect2i(218, 110, 96, 160), Rect2i(314, 110, 96, 160), Rect2i(410, 110, 96, 160), Rect2i(506, 110, 96, 160), Rect2i(602, 110, 96, 160)]
const FRAMES_RUN = [Rect2i(758, 110, 120, 160), Rect2i(878, 110, 100, 160), Rect2i(978, 110, 98, 160), Rect2i(1076, 110, 100, 160), Rect2i(1176, 110, 84, 160), Rect2i(1256, 110, 90, 160), Rect2i(1346, 110, 90, 160), Rect2i(1436, 110, 100, 160)]
const FRAMES_JUMP = [Rect2i(32, 400, 96, 100), Rect2i(117, 355, 96, 120), Rect2i(227, 325, 96, 135), Rect2i(437, 365, 96, 135)]
const FRAMES_ATTACK = [Rect2i(620, 350, 96, 150), Rect2i(736, 350, 96, 150), Rect2i(852, 350, 96, 150), Rect2i(966, 350, 104, 150), Rect2i(1085, 350, 102, 150), Rect2i(1207, 350, 96, 150), Rect2i(1324, 350, 96, 150), Rect2i(1410, 350, 100, 150)]
var vidaMaxima: int = 100
var duracion_invulnerabilidad: float = 0.5

var DASH_DIRECTION : Vector2
var direction: Vector2 = Vector2(0,0)
var ultimaDireccionDeApuntado: Vector2 = Vector2.RIGHT
var dashActivo: bool = false
var dashEnCooldown: bool = false
var dash_salio_del_suelo: bool = false
var vida: int
var invulnerable_por_golpe := false
var intangible_por_dash := false
var tiempo_desde_dash: float = INF
var cooldown_ataque_simple := 0.0
var invulnerable: bool:
	get:
		return invulnerable_por_golpe or intangible_por_dash
	set(valor):
		invulnerable_por_golpe = valor
var muerto := false
var cayendo_a_traves_de_plataforma: bool = false
var objetivo_y_caida: float = 0.0
var tiempo_caida: float = 0.0
var capa_plataforma_estaba_activada: bool = false
var atravesando_plataforma_al_subir: bool = false
var mascara_enemigos_antes_del_dash := false
var mascara_area_enemigos_antes_del_dash := false

func _ready() -> void:
	vida = vidaMaxima
	$AnimatedSprite2D.sprite_frames = crear_animaciones()
	$AnimatedSprite2D.play("quieto")
	actualizar_vida_ui()


func _process(_delta: float) -> void:
	actualizar_vida_ui()


func _physics_process(delta: float) -> void:
	if muerto:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_down") and is_on_floor():
		iniciar_caida_de_plataforma()
	elif Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			Sonido.reproducir("salto")

	
	direction = obtenerDireccionDeMovimiento()
	# Actualiza continuamente el apuntado y conserva la última dirección al soltar el stick.
	obtenerDireccionDeApuntado()

	cooldown_ataque_simple = maxf(cooldown_ataque_simple - delta, 0.0)
	tiempo_desde_dash += delta
	if Input.is_action_just_pressed("dash"):
		dash()
		
	if Input.is_action_just_pressed("ataqueSimple"):
		var es_combo := tiempo_desde_dash <= VENTANA_COMBO
		if es_combo:
			tiempo_desde_dash = INF
		ataqueSimple(es_combo)
	if !dashEnCooldown:
		if direction:
			velocity.x = direction.x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	if not cayendo_a_traves_de_plataforma:
		if velocity.y < 0.0:
			set_collision_mask_value(CAPA_COLISION_PLATAFORMA, false)
			atravesando_plataforma_al_subir = true
		elif atravesando_plataforma_al_subir:
			set_collision_mask_value(CAPA_COLISION_PLATAFORMA, true)
			atravesando_plataforma_al_subir = false

	move_and_slide()
	if dashEnCooldown:
		if not is_on_floor():
			dash_salio_del_suelo = true
		elif dash_salio_del_suelo:
			dashEnCooldown = false
			dash_salio_del_suelo = false
	if cayendo_a_traves_de_plataforma:
		tiempo_caida += delta
		if global_position.y >= objetivo_y_caida or tiempo_caida >= TIEMPO_MAXIMO_CAIDA_PLATAFORMA:
			set_collision_mask_value(CAPA_COLISION_PLATAFORMA, capa_plataforma_estaba_activada)
			cayendo_a_traves_de_plataforma = false
	actualizar_animacion()
	Global.setVelocidad(velocity)
	Global.setDireccion(direction)
	Global.setDash(dashActivo)


func iniciar_caida_de_plataforma() -> void:
	if cayendo_a_traves_de_plataforma:
		return
	capa_plataforma_estaba_activada = get_collision_mask_value(CAPA_COLISION_PLATAFORMA)
	if not capa_plataforma_estaba_activada:
		return
	set_collision_mask_value(CAPA_COLISION_PLATAFORMA, false)
	objetivo_y_caida = global_position.y + $CollisionShape2D.shape.get_rect().size.y + 2.0
	tiempo_caida = 0.0
	cayendo_a_traves_de_plataforma = true


func dash() -> void:
	if dashActivo or dashEnCooldown:
		return	
	dashActivo = true
	dashEnCooldown = true
	Sonido.reproducir("dash")
	dash_salio_del_suelo = not is_on_floor()
	DASH_DIRECTION = obtenerDireccionDeApuntado()
	velocity = DASH_DIRECTION * 700.0
	tiempo_desde_dash = 0.0
	cambiar_intangibilidad_dash(true)
	await get_tree().create_timer(DASH_DURATION).timeout
	dashActivo = false
	cambiar_intangibilidad_dash(false)

func ataqueSimple(combo: bool = false) -> void:
	if cooldown_ataque_simple > 0.0:
		return
	cooldown_ataque_simple = COOLDOWN_ATAQUE_SIMPLE
	Sonido.reproducir("combo" if combo else "ataque")
	var ataqueDireccion := obtenerDireccionDeApuntado()
	$AnimatedSprite2D.play("ataque")
	$AnimatedSprite2D.flip_h = ataqueDireccion.x < 0.0
	var ataqueSimple := ataqueSimpleEscena.instantiate() as Area2D
	if combo:
		ataqueSimple.set("daño", DANIO_ATAQUE_COMBO)
		ataqueSimple.scale = Vector2.ONE * ESCALA_ATAQUE_COMBO
	add_child(ataqueSimple)
	ataqueSimple.position = ataqueDireccion * 20.0
	ataqueSimple.global_rotation = ataqueDireccion.angle()


func cambiar_intangibilidad_dash(activa: bool) -> void:
	if activa:
		mascara_enemigos_antes_del_dash = get_collision_mask_value(CAPA_COLISION_ENEMIGOS)
		mascara_area_enemigos_antes_del_dash = $Area2D.get_collision_mask_value(CAPA_COLISION_ENEMIGOS)
	intangible_por_dash = activa
	# Las mascaras de los enemigos incluyen al jugador: sin la excepcion empujan al jugador durante el dash.
	for enemigo in get_tree().get_nodes_in_group("enemigo"):
		if activa:
			enemigo.add_collision_exception_with(self)
		else:
			enemigo.remove_collision_exception_with(self)
	set_collision_mask_value(CAPA_COLISION_ENEMIGOS, false if activa else mascara_enemigos_antes_del_dash)
	$Area2D.set_collision_mask_value(CAPA_COLISION_ENEMIGOS, false if activa else mascara_area_enemigos_antes_del_dash)
	$AnimatedSprite2D.modulate.a = 0.45 if activa else 1.0


func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or invulnerable or vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	actualizar_vida_ui()
	if vida == 0:
		morir()
		return
	Sonido.reproducir("dano")
	invulnerable = true
	animar_impacto()
	await get_tree().create_timer(duracion_invulnerabilidad).timeout
	if not muerto:
		invulnerable = false


func morir() -> void:
	if muerto:
		return
	muerto = true
	Sonido.reproducir("muerte")
	velocity = Vector2.ZERO
	dashActivo = false
	$AnimatedSprite2D.modulate = Color(0.8, 0.25, 0.25, 0.7)
	await get_tree().create_timer(0.65).timeout
	if not is_inside_tree():
		return
	global_position = Global.punto_reaparicion
	velocity = Vector2.ZERO
	vida = vidaMaxima
	dashEnCooldown = false
	var tiempo_recarga_dash = 0.0
	invulnerable = true
	muerto = false
	$AnimatedSprite2D.modulate = Color.WHITE
	actualizar_vida_ui()
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		invulnerable = false


func animar_impacto() -> void:
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.35, 0.35), 0.06)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.72, 0.48), 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.14)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.6, 0.6), 0.14)


func obtener_fragmento_vida() -> void:
	vidaMaxima += 20
	vida = vidaMaxima
	actualizar_vida_ui()


func actualizar_vida_ui() -> void:
	var barra: ProgressBar = get_node_or_null("Camera2D/HUD/Vida")
	var texto_vida: Label = get_node_or_null("Camera2D/HUD/VidaTexto")
	var texto_dash: Label = get_node_or_null("Camera2D/HUD/Dash")
	if barra != null:
		barra.max_value = vidaMaxima
		barra.value = vida
	if texto_vida != null:
		texto_vida.text = "VIDA %d / %d" % [vida, vidaMaxima]
	if texto_dash != null:
		if dashActivo:
			texto_dash.text = "DASH: EN USO"
		elif dashEnCooldown:
			texto_dash.text = "DASH: RECARGANDO"
		else:
			texto_dash.text = "DASH: LISTO"


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
