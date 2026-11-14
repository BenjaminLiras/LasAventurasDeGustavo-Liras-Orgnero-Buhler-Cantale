extends CharacterBody2D

@export_range(1, 30, 1) var vida: int = 4
@export_range(1, 60, 1) var danio_contacto: int = 20
@export_range(0, 30, 1) var monedas: int = 6

var muerto := false
var jugador: CharacterBody2D
var espera_contacto := 0.0


func _ready() -> void:
	buscar_jugador()


func buscar_jugador() -> void:
	if is_instance_valid(jugador):
		return
	jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody2D
	if is_instance_valid(jugador):
		add_collision_exception_with(jugador)


func puede_ver_jugador(alcance: float) -> bool:
	buscar_jugador()
	if not is_instance_valid(jugador) or jugador.get("muerto"):
		return false
	if global_position.distance_to(jugador.global_position) > alcance:
		return false
	var consulta := PhysicsRayQueryParameters2D.create(global_position, jugador.global_position, 13, [get_rid(), jugador.get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()


func procesar_contacto(delta: float) -> void:
	espera_contacto = maxf(espera_contacto - delta, 0.0)
	if espera_contacto > 0.0 or obtener_daño_contacto() == 0:
		return
	for cuerpo in $Contacto.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador") and cuerpo.has_method("recibir_golpe"):
			cuerpo.call("recibir_golpe", obtener_daño_contacto())
			espera_contacto = 0.7
			break


func obtener_daño_contacto() -> int:
	return 0 if muerto else danio_contacto


func recibir_golpe(cantidad: int = 1) -> void:
	if muerto or cantidad <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	if vida == 0:
		morir()
	else:
		$Visual.modulate = Color(1.0, 0.4, 0.3)
		create_tween().tween_property($Visual, "modulate", Color.WHITE, 0.15)


func morir() -> void:
	if muerto:
		return
	muerto = true
	velocity = Vector2.ZERO
	Global.soltar_monedas(self, monedas)
	set_deferred("collision_layer", 0)
	$Contacto.set_deferred("monitoring", false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_property($Visual, "position:y", 20.0, 0.25)
	tween.chain().tween_callback(queue_free)
