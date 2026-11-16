extends CharacterBody2D

signal derrotado

const VIDA_MAXIMA: int = 24

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var barra_vida: ProgressBar = $BarraVida
@onready var colision: CollisionShape2D = $CollisionShape2D

var vida: int = VIDA_MAXIMA
var velocidad: float = 180.0
var jugador: Node2D
var muerto: bool = false


func _ready() -> void:
	jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	if is_instance_valid(sprite):
		sprite.play("quieto")
	actualizar_barra_vida()


func _physics_process(delta: float) -> void:
	if muerto:
		return
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	velocity.x = 0.0
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	move_and_slide()


func recibir_golpe(cantidad: int = 1) -> void:
	if muerto or vida <= 0 or cantidad <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	actualizar_barra_vida()
	if vida == 0:
		morir()


func actualizar_barra_vida() -> void:
	if not is_instance_valid(barra_vida):
		return
	barra_vida.min_value = 0.0
	barra_vida.max_value = VIDA_MAXIMA
	barra_vida.value = vida


func morir() -> void:
	if muerto:
		return
	muerto = true
	vida = 0
	velocity = Vector2.ZERO
	set_physics_process(false)
	actualizar_barra_vida()
	if is_instance_valid(sprite):
		sprite.stop()
	if is_instance_valid(colision):
		colision.set_deferred("disabled", true)
	derrotado.emit()
	queue_free()
