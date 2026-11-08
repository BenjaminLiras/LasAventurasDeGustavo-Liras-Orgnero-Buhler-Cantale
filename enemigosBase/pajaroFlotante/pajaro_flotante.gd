extends CharacterBody2D

@export_range(1, 20, 1) var vida := 1
@export_range(1, 100, 1) var danio_contacto := 10
@export_range(0.0, 120.0, 1.0) var amplitud_vertical := 48.0
@export_range(0.0, 240.0, 1.0) var velocidad_horizontal := 70.0
@export_range(0.5, 10.0, 0.1) var periodo := 3.0
@export_range(0.0, 6.28, 0.05) var fase_inicial := 0.0
@export var mirar_izquierda := false

var origen := Vector2.ZERO
var tiempo := 0.0
var muerto := false
var proximos_golpes: Dictionary = {}
var direccion := 1.0
var jugadores_ignorados: Dictionary = {}


func _ready() -> void:
	origen = global_position
	direccion = -1.0 if mirar_izquierda else 1.0
	_ignorar_jugadores()
	$AnimatedSprite2D.flip_h = mirar_izquierda
	$AnimatedSprite2D.play("volar")


func _physics_process(delta: float) -> void:
	if muerto:
		return
	tiempo += delta
	var fase := tiempo * TAU / maxf(periodo, 0.5) + fase_inicial
	_ignorar_jugadores()
	var objetivo_y := origen.y + (sin(fase) - sin(fase_inicial)) * amplitud_vertical
	velocity = Vector2(direccion * velocidad_horizontal, (objetivo_y - global_position.y) / maxf(delta, 0.001))
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.x) > 0.7 and normal.x * direccion < 0.0:
			direccion = signf(normal.x)
			break
	$AnimatedSprite2D.flip_h = direccion < 0.0
	for cuerpo in $AreaDeContacto.get_overlapping_bodies():
		if not cuerpo.is_in_group("jugador") or not cuerpo.has_method("recibir_golpe"):
			continue
		var id: int = cuerpo.get_instance_id()
		if tiempo < float(proximos_golpes.get(id, 0.0)):
			continue
		proximos_golpes[id] = tiempo + 0.6
		cuerpo.call("recibir_golpe", danio_contacto)


func _ignorar_jugadores() -> void:
	# El escenario y el jugador comparten la capa 1 en estos niveles.
	for jugador: Node2D in get_tree().get_nodes_in_group("jugador"):
		if not jugador is PhysicsBody2D:
			continue
		var id := jugador.get_instance_id()
		if not jugadores_ignorados.has(id):
			add_collision_exception_with(jugador)
			jugadores_ignorados[id] = true


func obtener_daño_contacto() -> int:
	return 0 if muerto else danio_contacto


func recibir_golpe(cantidad: int = 1) -> void:
	if muerto or cantidad <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	if vida > 0:
		return
	muerto = true
	set_deferred("collision_layer", 0)
	$CollisionShape2D.set_deferred("disabled", true)
	$AreaDeContacto.set_deferred("monitoring", false)
	$AnimatedSprite2D.speed_scale = 0.4
	var tween := create_tween().set_parallel(true)
	tween.tween_property($AnimatedSprite2D, "position:y", 28.0, 0.3)
	tween.tween_property($AnimatedSprite2D, "rotation", 0.6, 0.3)
	tween.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
