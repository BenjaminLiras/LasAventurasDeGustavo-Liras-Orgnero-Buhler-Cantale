extends Area2D

const FRAMES_PUNETAZO: Array[Texture2D] = [
	preload("res://assets/PunchEffect/punch_00.png"),
	preload("res://assets/PunchEffect/punch_01.png"),
	preload("res://assets/PunchEffect/punch_02.png"),
	preload("res://assets/PunchEffect/punch_03.png"),
	preload("res://assets/PunchEffect/punch_04.png")
]
@export var daño: int = 1
var objetivos_golpeados: Dictionary = {}


func _ready() -> void:
	var cuadros := SpriteFrames.new()
	cuadros.clear_all()
	cuadros.add_animation("golpe")
	cuadros.set_animation_speed("golpe", 25.0)
	cuadros.set_animation_loop("golpe", false)
	for imagen in FRAMES_PUNETAZO:
		cuadros.add_frame("golpe", imagen)
	$AnimatedSprite2D.sprite_frames = cuadros
	$AnimatedSprite2D.play("golpe")
	await get_tree().create_timer(0.2).timeout
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	var id_objetivo := body.get_instance_id()
	if objetivos_golpeados.has(id_objetivo):
		return
	if body.has_method("recibir_golpe"):
		objetivos_golpeados[id_objetivo] = true
		body.call("recibir_golpe", daño)
