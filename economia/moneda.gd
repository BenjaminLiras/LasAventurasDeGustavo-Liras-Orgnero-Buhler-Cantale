extends CharacterBody2D

@export var valor: int = 1
var edad := 0.0
var recogida := false


func _ready() -> void:
	$Valor.text = str(valor)
	velocity = Vector2(randf_range(-60.0, 60.0), -190.0)
	for jugador in get_tree().get_nodes_in_group("jugador"):
		add_collision_exception_with(jugador)


func _physics_process(delta: float) -> void:
	edad += delta
	velocity.y = minf(velocity.y + 650.0 * delta, 650.0)
	velocity.x = move_toward(velocity.x, 0.0, 100.0 * delta)
	var jugador := get_tree().get_first_node_in_group("jugador") as Node2D
	if is_instance_valid(jugador) and not jugador.get("muerto") and edad > 0.25:
		var distancia := global_position.distance_to(jugador.global_position)
		var consulta := PhysicsRayQueryParameters2D.create(global_position, jugador.global_position, 13, [get_rid(), jugador.get_rid()])
		if distancia < 140.0 and get_world_2d().direct_space_state.intersect_ray(consulta).is_empty():
			velocity = global_position.direction_to(jugador.global_position) * 420.0
			if distancia < 28.0 and not recogida:
				recogida = true
				Global.agregar_monedas(valor)
				queue_free()
				return
	move_and_slide()
	var referencia_y: float = jugador.global_position.y if is_instance_valid(jugador) else Global.punto_reaparicion.y
	if edad > 8.0 and global_position.y > referencia_y + 1800.0:
		global_position = Global.punto_reaparicion
		velocity = Vector2.ZERO
