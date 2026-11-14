extends CharacterBody2D

var direccion := 1.0
var lanzador: CollisionObject2D
var recuperable := false
var recogida := false
var edad := 0.0


func _ready() -> void:
	velocity = Vector2(direccion * Global.BALANCE.velocidad_lata, -Global.BALANCE.impulso_lata)
	for jugador in get_tree().get_nodes_in_group("jugador"):
		add_collision_exception_with(jugador)


func _physics_process(delta: float) -> void:
	edad += delta
	velocity.y = minf(velocity.y + Global.BALANCE.gravedad_lata * delta, 1000.0)
	if not recuperable:
		$Visual.rotation += direccion * 8.0 * delta
	var impacto := move_and_collide(velocity * delta)
	if impacto != null:
		if not recuperable:
			var cuerpo := impacto.get_collider()
			if cuerpo.has_method("recibir_golpe"):
				cuerpo.call("recibir_golpe", Global.BALANCE.danio_lata)
				Sonido.reproducir("impacto")
			recuperable = true
			collision_mask = 13
			$Visual.rotation = 0.0
			$Recoger.show()
		velocity = velocity.slide(impacto.get_normal())
		velocity.x = 0.0
	if recuperable and edad > 0.3:
		for cuerpo in $Recogida.get_overlapping_bodies():
			if cuerpo.is_in_group("jugador") and not cuerpo.get("muerto"):
				recoger(cuerpo)
				return
	# Si cae al vacío, vuelve como objeto al punto de control.
	var referencia_y: float = lanzador.global_position.y if is_instance_valid(lanzador) else Global.punto_reaparicion.y
	if global_position.y > referencia_y + 1800.0 or (not recuperable and edad > 8.0):
		global_position = Global.punto_reaparicion + Vector2(50.0, -15.0)
		velocity = Vector2.ZERO
		recuperable = true
		collision_mask = 13
		$Visual.rotation = 0.0
		$Recoger.show()


func recoger(jugador: Node) -> void:
	if recogida:
		return
	recogida = true
	Global.lata_disponible = true
	jugador.set("cooldown_pintura", 0.2)
	queue_free()
