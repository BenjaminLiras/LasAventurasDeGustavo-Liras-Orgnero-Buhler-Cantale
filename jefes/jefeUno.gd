extends CharacterBody2D

var vida: int = 10
var velocidad: float = 45.0
var distancia_minima: float = 60.0
var jugador: Node2D
var direccion: float = 1.0


func _ready() -> void:
	$AnimatedSprite2D.play("reposo")
	jugador = get_tree().get_first_node_in_group("jugador") as Node2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	if is_instance_valid(jugador):
		perseguir_jugador()
	else:
		detenerse()
	$AnimatedSprite2D.flip_h = direccion < 0.0
	move_and_slide()


func perseguir_jugador() -> void:
	var diferencia_x: float = jugador.global_position.x - global_position.x
	if diferencia_x != 0.0:
		direccion = signf(diferencia_x)
	if absf(diferencia_x) > distancia_minima:
		velocity.x = direccion * velocidad
	else:
		detenerse()


func detenerse() -> void:
	velocity.x = 0.0


func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	if vida == 0:
		queue_free()