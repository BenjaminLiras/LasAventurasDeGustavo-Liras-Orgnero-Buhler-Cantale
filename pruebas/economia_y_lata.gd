extends SceneTree

class Blanco extends CharacterBody2D:
	var vida := 5
	func recibir_golpe(cantidad: int) -> void:
		vida -= cantidad

var fallos := 0
var g: Node
var mundo: Node2D
var jugador: CharacterBody2D

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

func comprobar() -> void:
	create_timer(25.0).timeout.connect(func(): quit(99))
	g = root.get_node("Global")
	g.reiniciar_partida()
	mundo = Node2D.new()
	root.add_child(mundo)
	current_scene = mundo
	var suelo := StaticBody2D.new()
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 30)
	forma.shape = rect
	suelo.add_child(forma)
	mundo.add_child(suelo)
	suelo.position = Vector2(0, 215)
	jugador = load("res://PJ/PJprincipal/Gustavo.tscn").instantiate()
	mundo.add_child(jugador)
	jugador.position = Vector2(0, 100)
	jugador.set_physics_process(false)
	await pasos(3)
	verificar(jugador.vidaMaxima == 5, "Cinco corazones iniciales")
	verificar(not g.comprar("vitalidad"), "No compra sin monedas")
	g.agregar_monedas(55)
	var tienda = load("res://economia/Tienda.tscn").instantiate()
	mundo.add_child(tienda)
	tienda._entrar(jugador)
	var tecla := InputEventKey.new()
	tecla.physical_keycode = KEY_E
	tecla.pressed = true
	tienda._unhandled_input(tecla)
	verificar(paused and tienda.abierta, "Tienda abre y pausa el combate")
	tienda._comprar("alcance")
	tienda._comprar("vitalidad")
	verificar(g.monedas == 0 and g.amuleto_alcance and g.amuleto_vitalidad, "Ambos espíritus descuentan el precio exacto")
	verificar(jugador.vidaMaxima == 7 and jugador.vida == 7, "Amuleto agrega dos corazones")
	g.agregar_monedas(100)
	verificar(not g.comprar("vitalidad") and g.monedas == 100, "Compra repetida no cobra ni acumula vida")
	tienda.cerrar()
	verificar(not paused, "Cerrar tienda reanuda el juego")
	var pausa = load("res://ui/PauseMenu.tscn").instantiate()
	mundo.add_child(pausa)
	# La tienda se procesa primero en el orden inverso de entrada del árbol.
	mundo.move_child(tienda, mundo.get_child_count() - 1)
	tienda._unhandled_input(tecla)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	verificar(not paused and not tienda.abierta and not pausa.overlay.visible, "Escape cierra tienda sin abrir pausa encima")
	pausa.queue_free()
	jugador.ataqueSimple()
	var ataque := jugador.get_child(jugador.get_child_count() - 1)
	verificar(is_equal_approx(ataque.scale.x, 1.25), "Alcance aumenta un 25 por ciento")
	for i in 4:
		jugador.obtener_fragmento_vida()
	verificar(jugador.vidaMaxima == 8 and g.fragmentos_vida == 0, "Cuatro fragmentos agregan un corazón permanente")
	jugador.obtener_pintura()
	jugador.ataque_pintura()
	await pasos(1)
	var lata := get_first_node_in_group("latas_lanzadas") as CharacterBody2D
	verificar(lata != null and lata.velocity.y < 0 and not g.lata_disponible, "Lanzamiento asciende en parábola y bloquea otra lata")
	jugador.cooldown_pintura = 0.0
	jugador.ataque_pintura()
	verificar(get_nodes_in_group("latas_lanzadas").size() == 1, "No duplica el arrojadizo")
	var blanco := Blanco.new()
	blanco.collision_layer = 2
	blanco.collision_mask = 0
	var col := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = Vector2(40, 80)
	col.shape = caja
	blanco.add_child(col)
	mundo.add_child(blanco)
	blanco.position = Vector2(200, 35)
	await pasos(85)
	verificar(blanco.vida == 5 - g.BALANCE.danio_lata, "Lata aplica el daño configurado una sola vez")
	verificar(is_instance_valid(lata) and lata.recuperable and lata.position.y < 201, "Lata queda como item al impactar y descansa sobre el suelo")
	jugador.position = lata.position + Vector2(-20, 0)
	await pasos(10)
	verificar(g.lata_disponible and get_nodes_in_group("latas_lanzadas").is_empty(), "Recoger permite reutilizar sin duplicar item")
	jugador.cooldown_pintura = 0
	jugador.ataque_pintura()
	verificar(not g.lata_disponible, "Se puede volver a lanzar después de recoger")
	var lata_perdida = get_first_node_in_group("latas_lanzadas")
	lata_perdida.global_position.y = jugador.global_position.y + 1801.0
	lata_perdida.velocity = Vector2(0, 500)
	await pasos(2)

	verificar(lata_perdida.recuperable and lata_perdida.global_position.y < g.punto_reaparicion.y + 200 and not g.lata_disponible, "Vacío devuelve la lata al checkpoint como objeto para recoger")
	jugador.morir()
	await pasos(65)
	verificar(g.lata_disponible and get_nodes_in_group("latas_lanzadas").is_empty() and jugador.vida == 8, "Reaparecer recupera lata y vida sin perder mejoras")
	for objeto in get_nodes_in_group("latas_lanzadas"):
		objeto.queue_free()
	var navajero = load("res://enemigosBase/pibeNavaja/pibeConNavaja.tscn").instantiate()
	mundo.add_child(navajero)
	navajero.position = Vector2(600, 130)
	navajero.recibir_golpe(100)
	navajero.recibir_golpe(100)
	await pasos(3)
	var monedas := get_nodes_in_group("monedas")
	verificar(monedas.size() == 1 and monedas[0].valor == 4, "Enemigo deja recompensa una sola vez")
	jugador.position = monedas[0].position
	await pasos(40)
	verificar(g.monedas == 104, "Recoger recompensa suma monedas")
	jugador.free()
	jugador = load("res://PJ/PJprincipal/Gustavo.tscn").instantiate()
	mundo.add_child(jugador)
	jugador.set_physics_process(false)
	verificar(jugador.vidaMaxima == 8 and g.amuleto_alcance and g.monedas == 104, "Progreso persiste al recrear jugador entre niveles")
	g.reiniciar_partida()
	verificar(g.monedas == 0 and g.vida_maxima() == 5 and not g.pintura_desbloqueada, "Nueva partida reinicia progreso")
	mundo.queue_free()
	await pasos(2)
	print("RESULTADO: ", fallos, " fallos")
	quit(0 if fallos == 0 else 1)

