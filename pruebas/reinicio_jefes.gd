extends SceneTree

var fallos := 0

func _initialize() -> void:
	call_deferred("comprobar")

func pasos(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func verificar(condicion: bool, mensaje: String) -> void:
	print("OK: " if condicion else "FALLO: ", mensaje)
	if not condicion:
		fallos += 1

func comprobar() -> void:
	create_timer(60.0).timeout.connect(func(): quit(99))
	for numero in [1, 2]:
		root.get_node("Global").reiniciar_partida()
		var nivel = load("res://Niveles/nivel%d/nivel%d.tscn" % [numero, numero]).instantiate()
		root.add_child(nivel)
		current_scene = nivel
		var jefe = nivel.get_node(nivel.ruta_jefe)
		var origen: Vector2 = jefe.position
		var activacion = jefe.get("distancia_activacion")
		for intento in 2:
			jefe.set_physics_process(false)
			jefe.vida = 1
			jefe.actualizar_barra_vida()
			jefe.position += Vector2(128, -64)
			if numero == 2:
				jefe.segunda_fase = true
				jefe.hay_ataque_pendiente = true
			else:
				jefe.estrategia_defensiva_activa = true
				jefe.golpes_pendientes.append(5)
			var ruta := "res://jefes/jefeUno/Ataques/proyectil/proyectilBenjamin.tscn" if numero == 1 else "res://jefes/jefeDos/Proyectiles/proyectilTiago.tscn"
			var proyectil = load(ruta).instantiate()
			jefe.add_child(proyectil)
			proyectil.set_physics_process(false)
			var identidad: int = jefe.get_instance_id()
			nivel.jugador.morir()
			await pasos(50)
			jefe = nivel.get_node(nivel.ruta_jefe)
			verificar(not nivel.jugador.muerto and jefe.get_instance_id() != identidad, "Nivel %d intento %d: la muerte real reinicia el encuentro" % [numero, intento])
			verificar(jefe.vida == jefe.VIDA_MAXIMA and jefe.barra_vida.value == jefe.VIDA_MAXIMA, "Vida y barra del jefe completas")
			verificar(absf(jefe.position.x - origen.x) < 1.0 and absf(jefe.position.y - origen.y) < 80.0, "Jefe regresa a su posición inicial")
			verificar(not is_instance_valid(proyectil), "El intento nuevo no conserva proyectiles anteriores")
			verificar(jefe.get("distancia_activacion") == activacion and jefe.is_connected("derrotado", nivel._on_jefe_derrotado), "Conserva ajustes del nivel y conexión de la salida")
			if numero == 2:
				verificar(not jefe.segunda_fase and not jefe.hay_ataque_pendiente, "Tiago reinicia fase y ataques pendientes")
			else:
				verificar(not jefe.estrategia_defensiva_activa and jefe.golpes_pendientes.is_empty(), "Benjamín reinicia defensa y golpes pendientes")
		jefe.emit_signal("derrotado")
		var ganador: int = jefe.get_instance_id()
		nivel.jugador.morir()
		await pasos(50)
		verificar(not nivel.salida_bloqueada and nivel.get_node(nivel.ruta_jefe).get_instance_id() == ganador, "Un jefe ya derrotado no reinicia ni vuelve a cerrar la salida")
		nivel.queue_free()
		await pasos(3)
	print("RESULTADO JEFES: ", fallos, " fallos")
	quit(1 if fallos else 0)
