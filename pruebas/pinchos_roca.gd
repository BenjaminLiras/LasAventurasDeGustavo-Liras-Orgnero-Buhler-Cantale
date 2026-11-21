extends SceneTree

var fallos := 0

func _initialize() -> void:
	call_deferred("probar")

func probar() -> void:
	create_timer(10.0).timeout.connect(func(): quit(99))
	for modo in ["normal", "invulnerable", "dash"]:
		var mundo := Node2D.new()
		root.add_child(mundo)
		current_scene = mundo
		var jugador = load("res://PJ/PJprincipal/Gustavo.tscn").instantiate()
		jugador.position = Vector2(300, 270)
		mundo.add_child(jugador)
		jugador.vidaMaxima = 20
		jugador.vida = 20
		jugador.set_physics_process(false)
		if modo == "invulnerable":
			jugador.invulnerable_por_golpe = true
		if modo == "dash":
			jugador.cambiar_intangibilidad_dash(true)
		var pinchos = load("res://piezasEscenario/pinchosRoca/PinchosRoca.tscn").instantiate()
		pinchos.position = Vector2(300, 300)
		mundo.add_child(pinchos)
		for i in 5:
			await physics_frame
			await process_frame
		var correcto: bool = jugador.muerto
		print("OK: " if correcto else "FALLO: ", "Pinchos matan al instante con 20 corazones, modo ", modo)
		if not correcto:
			fallos += 1
		# Completa los temporizadores de muerte antes de retirar el personaje.
		for i in 110:
			await physics_frame
			await process_frame
		mundo.queue_free()
		await process_frame
	print("RESULTADO PINCHOS: ", fallos, " fallos")
	quit(1 if fallos else 0)
