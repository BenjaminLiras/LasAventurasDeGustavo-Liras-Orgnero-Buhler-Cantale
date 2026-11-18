extends SceneTree
# Navegación con controles reales e invulnerabilidad: no verifica la dificultad
# ni simula la derrota de Tiago. No cambia posiciones durante el recorrido.
var nivel: Node2D
var pj: CharacterBody2D
func _initialize() -> void:
 call_deferred("probar")
func accion(nombre: String, pulsada: bool) -> void:
 if Input.is_action_pressed(nombre) == pulsada: return
 if pulsada: Input.action_press(nombre)
 else: Input.action_release(nombre)
func soltar() -> void:
 for tecla in ["ui_left", "ui_right", "ui_up", "ui_down", "ui_accept", "dash", "ataqueSimple"]:
  accion(tecla, false)
func pasos(n: int) -> void:
 for i in n:
  await physics_frame
  await process_frame
func llegar(destino: Vector2, etiqueta: String) -> bool:
 var ultima := Vector2.INF
 var quieto := 0
 for t in 2600:
  if paused:
   print("RECORRIDO FINAL ", etiqueta, " ", pj.global_position)
   return true
  var dx := destino.x - pj.global_position.x
  var dy := destino.y - pj.global_position.y
  if absf(dx) < 25 and absf(dy) < 85 and pj.is_on_floor():
   soltar()
   print("RECORRIDO OK ", etiqueta, " ", pj.global_position, " pasos=", t)
   return true
  accion("ui_left", dx < -15)
  accion("ui_right", dx > 15)
  accion("ui_down", (absf(dx) < 140 or pj.is_on_wall()) and dy > 160 and pj.is_on_floor() and t % 30 == 0)
  if pj.global_position.distance_to(ultima) < 0.3:
   quieto += 1
  else:
   quieto = 0
  if quieto > 150:
   print("RECORRIDO BLOQUEADO ", etiqueta, " posicion=", pj.global_position, " objetivo=", destino, " suelo=", pj.is_on_floor(), " mascara=", pj.collision_mask)
   soltar()
   return false
  ultima = pj.global_position
  await pasos(1)
 print("RECORRIDO TIEMPO ", etiqueta, " ", pj.global_position)
 soltar()
 return false
func probar() -> void:
 create_timer(360.0).timeout.connect(func(): quit(99))
 var g := root.get_node("Global")
 var rutas := {
  2:[Vector2(6200,1880),Vector2(7800,2072),Vector2(8050,4248),Vector2(2700,6808),Vector2(500,8344),Vector2(-2050,8344)],
  3:[Vector2(2350,2520),Vector2(1500,3800),Vector2(3000,5144),Vector2(2350,6168),Vector2(5350,6808),Vector2(1500,7576),Vector2(1400,7576)]
 }
 var fallos := 0
 for numero in [2,3]:
  g.reiniciar_partida()
  g.pintura_desbloqueada = true
  g.escalada_desbloqueada = true
  nivel = load("res://Niveles/nivel%d/nivel%d.tscn" % [numero,numero]).instantiate()
  root.add_child(nivel)
  current_scene = nivel
  pj = nivel.get_node("CharacterBody2D")
  pj.invulnerable_por_golpe = true
  await pasos(5)
  print("INICIO RECORRIDO ", numero, " ", pj.global_position)
  for i in rutas[numero].size():
   if not await llegar(rutas[numero][i], "%d.%d" % [numero,i+1]):
    fallos += 1
    break
  paused = false
  soltar()
  nivel.queue_free()
  await pasos(3)
 print("RESULTADO RECORRIDOS: ", fallos)
 quit(0 if fallos == 0 else 1)
