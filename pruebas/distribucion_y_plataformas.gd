extends SceneTree

class Objetivo extends CharacterBody2D:
	var muerto := false
	var intangible_por_dash := false
	func recibir_golpe(_cantidad: int) -> void:
		pass

var fallos := 0
var mundo: Node2D

func _initialize() -> void:
	call_deferred("comprobar")

func verificar(condicion: bool, mensaje: String) -> void:
	print("OK: " if condicion else "FALLO: ", mensaje)
	if not condicion:
		fallos += 1

func pasos(cantidad: int) -> void:
	for i in cantidad:
		await physics_frame
		await process_frame

func rectangulo(posicion: Vector2, tamano: Vector2, capa: int = 1) -> StaticBody2D:
	var cuerpo := StaticBody2D.new()
	cuerpo.collision_layer = capa
	var colision := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = tamano
	colision.shape = forma
	cuerpo.add_child(colision)
	mundo.add_child(cuerpo)
	cuerpo.position = posicion
	return cuerpo

func comprobar() -> void:
	create_timer(120.0).timeout.connect(func(): quit(99))
	var g := root.get_node("Global")
	g.reiniciar_partida()
	mundo = Node2D.new()
	root.add_child(mundo)
	current_scene = mundo
	rectangulo(Vector2(600, 315), Vector2(3200, 30))
	var objetivo := Objetivo.new()
	objetivo.add_to_group("jugador")
	mundo.add_child(objetivo)
	objetivo.position = Vector2(0, 260)
	var jabali = load("res://enemigosBase/nivel3/JabaliMusgoso.tscn").instantiate()
	mundo.add_child(jabali)
	jabali.position = Vector2(200, 280)
	jabali.recarga = 20.0
	await pasos(10)
	var consulta := PhysicsRayQueryParameters2D.create(Vector2(100, 275), Vector2(300, 275), 2)
	verificar(mundo.get_world_2d().direct_space_state.intersect_ray(consulta).is_empty(), "Camuflado oculto no intercepta ataques ni proyectiles")
	verificar(jabali.collision_layer == 0 and not jabali.get_node("Contacto").monitoring, "Camuflado oculto no tiene hitbox ni área de daño")
	verificar(jabali.apoyado_oculto and jabali.get_node("CollisionShape2D").disabled, "Camuflado se apoya en el suelo sin forma física activa")
	jabali.recarga = 0.0
	await pasos(4)
	verificar(jabali.estado == jabali.Estado.AVISO and jabali.collision_layer == 0 and jabali.get_node("CollisionShape2D").disabled, "El aviso previo a la embestida también es intangible")
	jabali.recibir_golpe(100)
	verificar(jabali.armado and jabali.vida == 2, "El aviso no permite quitar cobertura ni vida")
	var bate_aviso = load("res://PJ/ataqueSimple/ataqueBase.tscn").instantiate()
	bate_aviso.position = Vector2(150, 275)
	mundo.add_child(bate_aviso)
	var lata_aviso = load("res://PJ/ataquePintura/GotaPintura.tscn").instantiate()
	lata_aviso.position = Vector2(140, 275)
	mundo.add_child(lata_aviso)
	lata_aviso.velocity = Vector2(1200, 0)
	await pasos(6)
	verificar(bate_aviso.objetivos_golpeados.is_empty() and not bate_aviso.retroceso_aplicado, "Un batazo real atraviesa el aviso sin registrar impacto ni retroceso")
	verificar(lata_aviso.position.x > 250.0 and not lata_aviso.recuperable and jabali.armado, "Una lata real cruza el aviso sin frenarse ni descubrir al jabalí")
	lata_aviso.queue_free()
	await pasos(30)
	var impacto := mundo.get_world_2d().direct_space_state.intersect_ray(consulta)
	verificar(impacto.get("collider") == jabali and jabali.get_node("Contacto").monitoring, "Al emerger recupera la hitbox")
	jabali.ocultarse()
	jabali.recarga = 20.0
	await pasos(3)
	verificar(mundo.get_world_2d().direct_space_state.intersect_ray(consulta).is_empty(), "Volver a esconderse vuelve a quitar la hitbox")
	var rana = load("res://enemigosBase/nivel3/RanaSaltadora.tscn").instantiate()
	objetivo.position = Vector2(600, 260)
	mundo.add_child(rana)
	rana.position = Vector2(600, 280)
	rectangulo(Vector2(850, 200), Vector2(20, 200))
	var altura_minima := 280.0
	var giro := false
	for i in 250:
		await pasos(1)
		altura_minima = minf(altura_minima, rana.position.y)
		giro = giro or rana.direccion < 0.0
	verificar(altura_minima < 240.0, "Nueva rana avisa y salta repetidamente")
	verificar(giro, "Nueva rana cambia de dirección al tocar una pared")
	rana.recibir_golpe(100)
	verificar(rana.muerto, "Nueva rana recibe daño y puede ser derrotada")
	await pasos(2) # Completa la entrega diferida de monedas antes de retirar el mundo.
	mundo.free()
	# El dash no debe borrar la intangibilidad física permanente del camuflado.
	mundo = Node2D.new()
	root.add_child(mundo)
	current_scene = mundo
	rectangulo(Vector2(400, 315), Vector2(2000, 30))
	var pj_camuflado = load("res://PJ/PJprincipal/Gustavo.tscn").instantiate()
	pj_camuflado.position = Vector2(100, 260)
	mundo.add_child(pj_camuflado)
	var oculto = load("res://enemigosBase/nivel3/JabaliMusgoso.tscn").instantiate()
	oculto.position = Vector2(260, 280)
	mundo.add_child(oculto)
	oculto.recarga = 999.0
	await pasos(5)
	pj_camuflado.cambiar_intangibilidad_dash(true)
	pj_camuflado.cambiar_intangibilidad_dash(false)
	verificar(oculto.get_collision_exceptions().has(pj_camuflado), "Terminar el dash conserva la intangibilidad del camuflado")
	var vida_antes: int = pj_camuflado.vida
	Input.action_press("ui_right")
	await pasos(60)
	Input.action_release("ui_right")
	verificar(pj_camuflado.position.x > 350.0 and pj_camuflado.vida == vida_antes and oculto.position.distance_to(Vector2(260, 280)) < 5.0, "Gustavo atraviesa al camuflado escondido sin daño ni empujarlo después del dash")
	oculto.recibir_golpe(100)
	verificar(oculto.vida == 2 and oculto.armado, "El camuflado escondido ignora golpes sin perder cobertura")
	var lata = load("res://PJ/ataquePintura/GotaPintura.tscn").instantiate()
	lata.position = Vector2(180, 240)
	mundo.add_child(lata)
	lata.velocity = Vector2(800, 0)
	await pasos(14)
	verificar(lata.position.x > 300.0 and not lata.recuperable and oculto.vida == 2, "La lata atraviesa físicamente al camuflado sin frenarse ni dañarlo")
	mundo.free()
	mundo = Node2D.new()
	root.add_child(mundo)
	current_scene = mundo
	rectangulo(Vector2(600, 615), Vector2(2000, 30))
	rectangulo(Vector2(300, 300), Vector2(400, 20), 4)
	rectangulo(Vector2(800, 460), Vector2(200, 20), 4)
	var pj = load("res://PJ/PJprincipal/Gustavo.tscn").instantiate()
	mundo.add_child(pj)
	pj.position = Vector2(300, 150)
	await pasos(65)
	verificar(pj.is_on_floor() and pj.position.y < 300.0, "Gustavo aterriza sobre las plataformas")
	Input.action_press("ui_down")
	await pasos(3)
	Input.action_release("ui_down")
	await pasos(55)
	verificar(pj.is_on_floor() and pj.position.y > 500.0, "S permite bajar de la plataforma y el suelo sólido detiene la caída")
	Input.action_press("ui_right")
	await pasos(95)
	Input.action_release("ui_right")
	Input.action_press("ui_accept")
	await pasos(70)
	Input.action_release("ui_accept")
	verificar(pj.is_on_floor() and pj.position.y < 450.0, "Se puede saltar desde abajo y quedar sobre otra plataforma")
	mundo.free()
	for numero in [1, 2, 3]:
		var inicio := Time.get_ticks_usec()
		var nivel = load("res://Niveles/nivel%d/nivel%d.tscn" % [numero, numero]).instantiate()
		root.add_child(nivel)
		current_scene = nivel
		await pasos(5)
		print("CARGA NIVEL ", numero, " ms=", (Time.get_ticks_usec() - inicio) / 1000.0)
		verificar(nivel.salida.has_method("establecer_bloqueada") and nivel.salida.get_node("CollisionShape2D").shape != null, "Salida con asset y colisión en nivel %d" % numero)
		var rayo := PhysicsRayQueryParameters2D.create(nivel.salida.global_position + Vector2(0, -2), nivel.salida.global_position + Vector2(0, 100), 13, [nivel.jugador.get_rid()])
		var suelo: Dictionary = nivel.get_world_2d().direct_space_state.intersect_ray(rayo)
		verificar(not suelo.is_empty() and absf(suelo["position"].y - nivel.salida.global_position.y) < 8.0, "Salida apoyada en suelo accesible en nivel %d" % numero)
		if numero == 2:
			var picadas := 0
			var flotantes := 0
			for hijo in nivel.get_children():
				if hijo.scene_file_path == "res://enemigosBase/pajaroPicada/Pajaro.tscn":
					picadas += 1
				if hijo.scene_file_path == "res://enemigosBase/pajaroFlotante/PajaroFlotante.tscn":
					flotantes += 1
			verificar(picadas >= 2 and flotantes >= 2, "Nivel 2 mantiene varias instancias de sus dos tipos de pájaro exclusivos")
			verificar(get_nodes_in_group("jabalies_musgosos").is_empty(), "El arbusto del nivel 3 no aparece en el nivel 2")
			verificar(nivel.salida_bloqueada and nivel.get_node("Tiago").is_connected("derrotado", nivel._on_jefe_derrotado), "Salida del nivel 2 espera la derrota de Tiago")
			nivel.get_node("Tiago").emit_signal("derrotado")
			verificar(not nivel.salida_bloqueada, "Evento de derrota de Tiago habilita la salida")
		if numero == 3:
			verificar(get_nodes_in_group("saltadores").size() == 4, "Cuatro ranas distribuidas en el nivel 3")
		for enemigo in get_nodes_in_group("enemigo"):
			var colision := enemigo.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if colision == null:
				continue
			var q := PhysicsShapeQueryParameters2D.new()
			q.shape = colision.shape
			q.transform = colision.global_transform.scaled_local(Vector2(0.8, 0.8))
			q.collision_mask = 13
			q.exclude = [enemigo.get_rid(), nivel.jugador.get_rid()]
			verificar(nivel.get_world_2d().direct_space_state.intersect_shape(q).is_empty(), "Enemigo fuera de paredes: %d/%s" % [numero, enemigo.name])
		nivel.queue_free()
		await pasos(3)
	print("RESULTADO: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)
