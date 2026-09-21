extends Area2D


func _ready() -> void:
	await get_tree().create_timer(0.2).timeout
	queue_free()
