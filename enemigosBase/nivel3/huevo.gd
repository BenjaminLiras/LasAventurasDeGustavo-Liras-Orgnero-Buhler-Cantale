extends CharacterBody2D

@export var rapidez := 240.0
@export var danio := 20
@export var duracion := 4.0
var direccion := Vector2.LEFT
var tiempo := 0.0
var roto := false


func _physics_process(delta: float) -> void:
	if roto:
		return
	tiempo += delta
	if tiempo >= duracion:
		queue_free()
		return
	velocity = direccion.normalized() * rapidez
	$Visual.rotation += delta * 3.0
	var impacto := move_and_collide(velocity * delta)
	if impacto == null:
		return
	var cuerpo := impacto.get_collider()
	if cuerpo.is_in_group("jugador"):
		if cuerpo.get("intangible_por_dash"):
			add_collision_exception_with(cuerpo)
			return
		cuerpo.call("recibir_golpe", danio)
	romper()


func romper() -> void:
	roto = true
	$Visual.modulate = Color(1.0, 0.85, 0.35)
	var tween := create_tween().set_parallel(true)
	tween.tween_property($Visual, "scale", Vector2(1.8, 0.6), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(queue_free)
