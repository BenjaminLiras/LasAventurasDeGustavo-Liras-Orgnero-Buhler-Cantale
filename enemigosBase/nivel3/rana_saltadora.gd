extends "res://enemigosBase/nivel3/enemigo_nivel3.gd"

enum Estado { ESPERA, PREPARA, SALTO }
@export var mirar_izquierda := false
@export_range(60.0, 350.0, 5.0) var velocidad_salto := 175.0
@export_range(180.0, 600.0, 10.0) var impulso_salto := 400.0
@export_range(0.1, 2.0, 0.05) var descanso := 0.35
@export_range(200.0, 900.0, 20.0) var alcance_activacion := 480.0

var direccion := 1.0
var estado := Estado.ESPERA
var espera := 0.6


func _ready() -> void:
	super._ready()
	direccion = -1.0 if mirar_izquierda else 1.0
	$Visual.play("quieto")


func _physics_process(delta: float) -> void:
	if muerto:
		return
	buscar_jugador()
	velocity.y += get_gravity().y * delta
	if is_on_floor() and estado == Estado.SALTO:
		estado = Estado.ESPERA
		espera = descanso
		$Visual.play("quieto")
		$Visual.scale = Vector2.ONE
	if estado != Estado.SALTO:
		velocity.x = 0.0
		var cerca := puede_ver_jugador(alcance_activacion)
		if is_on_floor() and cerca:
			espera -= delta
			if espera <= 0.0:
				if estado == Estado.ESPERA:
					estado = Estado.PREPARA
					espera = 0.15
					$Visual.scale = Vector2(1.1, 0.85)
				else:
					if not hay_suelo_delante():
						direccion *= -1.0
					velocity = Vector2(direccion * velocidad_salto, -impulso_salto)
					estado = Estado.SALTO
					$Visual.scale = Vector2.ONE
					$Visual.play("saltar")
	else:
		velocity.x = direccion * velocidad_salto
	$Visual.flip_h = direccion < 0.0
	move_and_slide()
	for i in get_slide_collision_count():
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.x) > 0.7 and normal.x * direccion < 0.0:
			direccion = signf(normal.x)
			velocity.x = direccion * velocidad_salto
			break
	procesar_contacto(delta)


func hay_suelo_delante() -> bool:
	var excluidos: Array[RID] = [get_rid()]
	if is_instance_valid(jugador):
		excluidos.append(jugador.get_rid())
	var desde := global_position + Vector2(direccion * 45.0, 8.0)
	var consulta := PhysicsRayQueryParameters2D.create(desde, desde + Vector2(0, 75), 13, excluidos)
	return not get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()
