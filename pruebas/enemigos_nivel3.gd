extends SceneTree

class Objetivo extends CharacterBody2D:
	var muerto := false
	var intangible_por_dash := false
	var danio_recibido := 0
	func recibir_golpe(cantidad: int) -> void:
		if not intangible_por_dash:
			danio_recibido += cantidad

var fallos := 0
var mundo: Node2D
var jugador: Objetivo

func _initialize() -> void:
	call_deferred("comprobar")

func pasos(cantidad: int) -> void:
	for i in cantidad:
		await physics_frame
		await process_frame

func verificar(condicion: bool, mensaje: String) -> void:
	print("OK: " if condicion else "FALLO: ", mensaje)
	if not condicion:
		fallos += 1

func pared(posicion: Vector2, dimensiones: Vector2) -> StaticBody2D:
	var cuerpo := StaticBody2D.new()
	var colision := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = dimensiones
	colision.shape = forma
	cuerpo.add_child(colision)
	mundo.add_child(cuerpo)
	cuerpo.position = posicion
	return cuerpo

func comprobar() -> void:
	create_timer(35.0).timeout.connect(func(): quit(99))
	var g := root.get_node("Global")
	g.reiniciar_partida()
	mundo = Node2D.new()
	root.add_child(mundo)
	current_scene = mundo
	pared(Vector2(0, 315), Vector2(2000, 30))
	jugador = Objetivo.new()
	jugador.add_to_group("jugador")
	jugador.collision_mask = 0
	var colision := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = 16
	colision.shape = forma
	jugador.add_child(colision)
	mundo.add_child(jugador)
	jugador.position = Vector2(0, 220)
	var ave = load("res://enemigosBase/nivel3/PajaroPrimigenio.tscn").instantiate()
	mundo.add_child(ave)
	ave.position = Vector2(400, 120)
	ave.set_physics_process(false)
	await pasos(3)
	ave.disparar()
	await pasos(2)
	var huevos := get_nodes_in_group("huevos_enemigos")
	verificar(huevos.size() == 3, "Pájaro dispara exactamente tres huevos")
	var apuntado: Vector2 = ave.global_position.direction_to(jugador.global_position)
	verificar(huevos[1].direccion.dot(apuntado) > 0.999, "Huevo central apunta al personaje")
	verificar(is_equal_approx(absf(rad_to_deg(huevos[0].direccion.angle_to(apuntado))), 35.0) and is_equal_approx(absf(rad_to_deg(huevos[2].direccion.angle_to(apuntado))), 35.0), "Laterales se abren 35 grados")
	var direccion_anterior: Vector2 = huevos[1].direccion
	jugador.position.x = -50
	await pasos(2)
	verificar(huevos[1].direccion == direccion_anterior, "Huevos no persiguen al jugador tras dispararse")
	var obstaculo := pared(Vector2(200, 100), Vector2(24, 400))
	await pasos(2)
	verificar(not ave.puede_ver_jugador(620.0), "Pared bloquea visión del pájaro")
	ave.preparando = true
	ave.aviso_restante = 0.01
	ave._physics_process(0.02)
	verificar(not ave.preparando and ave.recarga > 0, "Interrumpir la visión cancela el aviso de disparo")
	await pasos(80)
	verificar(get_nodes_in_group("huevos_enemigos").is_empty(), "Los huevos se rompen contra paredes")
	obstaculo.queue_free()
	jugador.position = Vector2(0, 220)
	var huevo = load("res://enemigosBase/nivel3/Huevo.tscn").instantiate()
	huevo.position = Vector2(80, 220)
	huevo.direccion = Vector2.LEFT
	huevo.rapidez = 720.0
	mundo.add_child(huevo)
	await pasos(20)
	verificar(jugador.danio_recibido == 20 and not is_instance_valid(huevo), "Impacto hace un solo golpe y elimina el huevo")
	jugador.danio_recibido = 0
	jugador.intangible_por_dash = true
	var esquivable = load("res://enemigosBase/nivel3/Huevo.tscn").instantiate()
	esquivable.position = Vector2(80, 220)
	esquivable.direccion = Vector2.LEFT
	esquivable.rapidez = 720.0
	mundo.add_child(esquivable)
	await pasos(20)
	verificar(jugador.danio_recibido == 0 and is_instance_valid(esquivable), "Dash intangible atraviesa los huevos sin daño")
	esquivable.duracion = 0.1
	await pasos(3)
	verificar(not is_instance_valid(esquivable), "Huevos sin impacto caducan")
	jugador.intangible_por_dash = false
	var jabali = load("res://enemigosBase/nivel3/JabaliMusgoso.tscn").instantiate()
	mundo.add_child(jabali)
	jabali.position = Vector2(220, 280)
	jabali.recarga = 0.0
	await pasos(35)
	verificar(jabali.estado == jabali.Estado.EMBESTIDA and jabali.velocity.x < 0, "Jabalí avisa y embiste hacia el jugador")
	jabali.recibir_golpe(2)
	verificar(jabali.vida == 2 and not jabali.armado and jabali.estado == jabali.Estado.HUIDA and jabali.direccion > 0, "Primer golpe quita cobertura y provoca huida sin restar vida")
	jabali.recibir_golpe(1)
	verificar(jabali.vida == 1, "Animal descubierto recibe daño")
	jabali.recibir_golpe(1)
	jabali.recibir_golpe(10)
	await pasos(2)
	verificar(jabali.muerto and get_nodes_in_group("monedas").size() == 1, "Jabalí muere y entrega monedas una sola vez")
	var otro = load("res://enemigosBase/nivel3/JabaliMusgoso.tscn").instantiate()
	mundo.add_child(otro)
	otro.position = Vector2(970, 280)
	await pasos(3)
	otro.estado = otro.Estado.EMBESTIDA
	otro.direccion = 1.0
	await pasos(2)
	verificar(otro.estado == otro.Estado.OCULTO and otro.armado and otro.velocity.x == 0, "Jabalí se detiene y se camufla antes del borde")
	ave.preparando = true
	ave.recibir_golpe(100)
	ave.disparar()
	await pasos(2)
	verificar(get_nodes_in_group("huevos_enemigos").is_empty(), "Ave muerta no termina un disparo pendiente")
	mundo.free()
	# Verifica que el nivel tenga personaje, enemigos colocados sobre zonas libres,
	# checkpoints y salida conectada al flujo común.
	var nivel = load("res://Niveles/nivel3/nivel3.tscn").instantiate()
	root.add_child(nivel)
	current_scene = nivel
	await pasos(5)
	verificar(get_nodes_in_group("pajaros_primigenios").size() == 4 and get_nodes_in_group("jabalies_musgosos").size() == 4, "Nivel 3 contiene cuatro aves y cuatro jabalíes")
	verificar(is_instance_valid(nivel.jugador) and nivel.salida.body_entered.is_connected(nivel._on_salida_body_entered), "Nivel 3 es jugable y tiene salida conectada")
	for enemigo in get_nodes_in_group("enemigo"):
		var consulta := PhysicsShapeQueryParameters2D.new()
		var circulo := CircleShape2D.new()
		circulo.radius = 12.0
		consulta.shape = circulo
		consulta.transform = Transform2D(0.0, enemigo.global_position)
		consulta.collision_mask = 13
		consulta.exclude = [nivel.jugador.get_rid(), enemigo.get_rid()]
		verificar(nivel.get_world_2d().direct_space_state.intersect_shape(consulta).is_empty(), "Enemigo fuera del terreno: " + enemigo.name)
	nivel.jugador.position = Vector2(700, 550)
	await pasos(60)
	verificar(nivel.jugador.is_on_floor() and not nivel.jugador.muerto, "Gustavo aparece sobre suelo seguro en el nivel 3")
	nivel._on_salida_body_entered(nivel.jugador)
	verificar(paused and nivel.panel_final.visible and not nivel.boton_siguiente.visible, "Salida del nivel 3 muestra el final de la demo")
	paused = false
	nivel.queue_free()
	await pasos(3)
	var anterior = load("res://Niveles/nivel2/nivel2.tscn").instantiate()
	root.add_child(anterior)
	current_scene = anterior
	anterior._on_siguiente_pressed()
	await pasos(5)
	verificar(current_scene != null and current_scene.scene_file_path == "res://Niveles/nivel3/nivel3.tscn" and get_nodes_in_group("pajaros_primigenios").size() == 4, "Completar nivel 2 permite entrar al nivel 3 con sus enemigos")
	current_scene.queue_free()
	await pasos(3)
	print("RESULTADO: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)
