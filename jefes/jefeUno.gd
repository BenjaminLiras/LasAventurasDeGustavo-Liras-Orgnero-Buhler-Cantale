extends CharacterBody2D

var vida: int = 10
var velocidad: float = 80.0


func _ready() -> void:
	$AnimatedSprite2D.play("reposo")


func _physics_process(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, velocidad * delta)
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	move_and_slide()


func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	if vida == 0:
		queue_free()