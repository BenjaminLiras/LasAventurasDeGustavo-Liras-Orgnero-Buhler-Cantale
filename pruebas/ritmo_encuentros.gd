extends SceneTree

class Objetivo extends CharacterBody2D:
	var muerto := false
	func recibir_golpe(_cantidad: int) -> void:
		pass

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
	var mundo := Node2D.new()
	root.add_child(mundo)
	current_scene = mundo
	var objetivo := Objetivo.new()
	objetivo.position = Vector2(0, 220)
	objetivo.add_to_group("jugador")
	mundo.add_child(objetivo)
	var aves: Array[Node] = []
	for posicion in [Vector2(300, 120), Vector2(350, 80)]:
		var ave = load("res://enemigosBase/nivel3/PajaroPrimigenio.tscn").instantiate()
		ave.position = posicion
		mundo.add_child(ave)
		ave.recarga = 0.0
		aves.append(ave)
	await pasos(40)
	verificar(get_nodes_in_group("huevos_enemigos").is_empty() and not aves[0].preparando and not aves[1].preparando, "Hay tiempo para leer el enemigo antes del primer aviso")
	var simultaneos := false
	var rafagas := 0
	var ultimo := -100.0
	var separacion_minima := 100.0
	for i in 360:
		var antes := [aves[0].desde_ultimo_disparo, aves[1].desde_ultimo_disparo]
		await pasos(1)
		simultaneos = simultaneos or (aves[0].preparando and aves[1].preparando)
		for j in 2:
			if aves[j].desde_ultimo_disparo < antes[j]:
				var ahora := float(i) / 60.0
				separacion_minima = minf(separacion_minima, ahora - ultimo)
				ultimo = ahora
				rafagas += 1
	verificar(not simultaneos, "Dos aves cercanas no preparan abanicos simultáneos")
	verificar(rafagas >= 3 and separacion_minima >= 0.89, "Continúan atacando con al menos 0,9 segundos entre ráfagas")
	objetivo.position = Vector2(3000, 220)
	await pasos(2)
	verificar(not aves[0].preparando and not aves[1].preparando and not aves[0].dentro_del_territorio(), "Abandonar la sala cancela ataques y persecución")
	var distancia: float = aves[0].global_position.distance_to(aves[0].origen)
	await pasos(120)
	verificar(aves[0].global_position.distance_to(aves[0].origen) < maxf(distancia, 60.0), "El ave vuelve a su zona después del encuentro")
	mundo.free()
	# Verifica los espacios de descanso en las escenas finales, antes de mover enemigos.
	for numero in [2, 3]:
		var nivel = load("res://Niveles/nivel%d/nivel%d.tscn" % [numero, numero]).instantiate()
		root.add_child(nivel)
		current_scene = nivel
		for checkpoint in get_nodes_in_group("checkpoints"):
			var libre := true
			for enemigo in get_nodes_in_group("enemigo"):
				if enemigo is Node2D and enemigo.global_position.distance_to(checkpoint.global_position) < 480.0:
					libre = false
			verificar(libre, "Nivel %d: margen de 480 px alrededor de %s" % [numero, checkpoint.name])
		nivel.free()
	print("RESULTADO RITMO: ", fallos, " fallos")
	quit(1 if fallos else 0)
