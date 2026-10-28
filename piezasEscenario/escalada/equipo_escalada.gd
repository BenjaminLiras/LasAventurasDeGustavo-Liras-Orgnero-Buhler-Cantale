extends Area2D

var recogido := false


func _ready() -> void:
	if Global.escalada_desbloqueada:
		queue_free()
		return
	body_entered.connect(_recoger)
	var flotacion := create_tween().set_loops()
	flotacion.tween_property($Visual, "position:y", -6.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flotacion.tween_property($Visual, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _recoger(body: Node2D) -> void:
	if recogido or not body.is_in_group("jugador") or not body.has_method("obtener_equipo_escalada"):
		return
	recogido = true
	body.call("obtener_equipo_escalada")
	Sonido.reproducir("fragmento")
	var nivel := get_tree().current_scene
	if nivel.has_method("mostrar_aviso"):
		nivel.call("mostrar_aviso", "EQUIPO DE ESCALADA: MANTENE HACIA LA PARED Y PRESIONA SALTO")
	queue_free()
