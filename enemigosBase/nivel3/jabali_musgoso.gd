extends "res://enemigosBase/nivel3/enemigo_nivel3.gd"

enum Estado { OCULTO, AVISO, EMBESTIDA, HUIDA }
const NORMAL = preload("res://assets/enemigos_nivel3/jabali.png")
const DESCUBIERTO = preload("res://assets/enemigos_nivel3/jabali_herido.png")
@export_range(80.0, 600.0, 10.0) var alcance_deteccion := 340.0
@export_range(80.0, 500.0, 10.0) var velocidad_embestida := 280.0
@export_range(80.0, 600.0, 10.0) var velocidad_huida := 340.0
@export_range(0.2, 2.0, 0.05) var tiempo_aviso := 0.45
@export_range(0.5, 5.0, 0.1) var tiempo_oculto := 2.3

var estado := Estado.OCULTO
var armado := true
var direccion := -1.0
var tiempo_estado := 0.0
var recarga := 1.0


func _ready() -> void:
	super._ready()
	ocultarse()
	recarga = 1.0


func _physics_process(delta: float) -> void:
	if muerto:
		return
	buscar_jugador()
	tiempo_estado += delta
	recarga = maxf(recarga - delta, 0.0)
	velocity.y += get_gravity().y * delta
	velocity.x = 0.0
	match estado:
		Estado.OCULTO:
			$Musgo.position.y = -8.0 + sin(tiempo_estado * 4.0) * 1.5
			if recarga <= 0.0 and is_on_floor() and puede_ver_jugador(alcance_deteccion) and absf(jugador.global_position.y - global_position.y) < 65.0:
				direccion = -1.0 if jugador.global_position.x < global_position.x else 1.0
				estado = Estado.AVISO
				cambiar_hitbox(true)
				tiempo_estado = 0.0
				$Visual.show()
				$Musgo.scale = Vector2.ONE
		Estado.AVISO:
			$Musgo.position.x = sin(tiempo_estado * 50.0) * 2.0
			if tiempo_estado >= tiempo_aviso:
				estado = Estado.EMBESTIDA
				tiempo_estado = 0.0
				$Musgo.position.x = 0.0
		Estado.EMBESTIDA, Estado.HUIDA:
			if is_on_floor() and not hay_suelo_delante():
				ocultarse()
			else:
				velocity.x = direccion * (velocidad_huida if estado == Estado.HUIDA else velocidad_embestida)
				$Visual.position.y = -10.0 + sin(tiempo_estado * 35.0) * 2.0
				if tiempo_estado > (1.1 if estado == Estado.HUIDA else 1.2):
					ocultarse()
	$Visual.flip_h = direccion > 0.0
	move_and_slide()
	if is_on_wall() and estado in [Estado.EMBESTIDA, Estado.HUIDA]:
		ocultarse()
	procesar_contacto(delta)
	if global_position.y > 9000.0:
		queue_free()


func hay_suelo_delante() -> bool:
	var excluidos: Array[RID] = [get_rid()]
	if is_instance_valid(jugador):
		excluidos.append(jugador.get_rid())
	var desde := global_position + Vector2(direccion * 44.0, 10.0)
	var consulta := PhysicsRayQueryParameters2D.create(desde, desde + Vector2(0.0, 50.0), 13, excluidos)
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func ocultarse() -> void:
	estado = Estado.OCULTO
	armado = true
	tiempo_estado = 0.0
	recarga = tiempo_oculto
	velocity.x = 0.0
	cambiar_hitbox(false)
	$Visual.hide()
	$Visual.texture = NORMAL
	$Visual.position.y = -10.0
	$Musgo.show()
	$Musgo.scale = Vector2(0.7, 0.55)
	$Musgo.position = Vector2(0.0, -8.0)


func cambiar_hitbox(activa: bool) -> void:
	# Conserva la forma del cuerpo para apoyarse en el suelo, pero deja de
	# pertenecer a la capa de enemigos: ni el bate ni la lata pueden tocarlo.
	set_deferred("collision_layer", 2 if activa else 0)
	$Contacto.set_deferred("monitoring", activa)
	$Contacto/CollisionShape2D.set_deferred("disabled", not activa)


func obtener_daño_contacto() -> int:
	return 0 if muerto or estado in [Estado.OCULTO, Estado.AVISO] else danio_contacto


func recibir_golpe(cantidad: int = 1) -> void:
	if muerto or cantidad <= 0 or estado == Estado.OCULTO:
		return
	if armado:
		# Como el Musgoagresor: el primer golpe retira la cobertura sin dañar al animal.
		armado = false
		estado = Estado.HUIDA
		tiempo_estado = 0.0
		$Musgo.hide()
		$Visual.texture = DESCUBIERTO
		if is_instance_valid(jugador):
			direccion = -1.0 if jugador.global_position.x >= global_position.x else 1.0
		Sonido.reproducir("impacto", -5.0)
		return
	super.recibir_golpe(cantidad)
