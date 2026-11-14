extends "res://enemigosBase/nivel3/enemigo_nivel3.gd"

const HUEVO = preload("res://enemigosBase/nivel3/Huevo.tscn")
@export_range(100.0, 1000.0, 10.0) var alcance_deteccion := 620.0
@export_range(120.0, 400.0, 10.0) var distancia_preferida := 240.0
@export_range(20.0, 220.0, 5.0) var velocidad_vuelo := 110.0
@export_range(0.2, 2.0, 0.05) var tiempo_aviso := 0.55
@export_range(0.5, 5.0, 0.1) var intervalo_disparos := 2.1
@export_range(80.0, 500.0, 10.0) var velocidad_huevo := 240.0
@export_range(5.0, 60.0, 1.0) var angulo_abanico := 35.0

var origen := Vector2.ZERO
var tiempo := 0.0
var recarga := 1.2
var preparando := false
var aviso_restante := 0.0


func _ready() -> void:
	super._ready()
	origen = global_position
	$Visual.play("volar")


func _physics_process(delta: float) -> void:
	if muerto:
		return
	tiempo += delta
	recarga = maxf(recarga - delta, 0.0)
	var visible_jugador := puede_ver_jugador(alcance_deteccion)
	if preparando:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		aviso_restante -= delta
		$Preparacion.show()
		$Visual.modulate = Color(1.0, 0.65, 0.25)
		if not visible_jugador:
			cancelar_disparo()
		elif aviso_restante <= 0.0:
			disparar()
	else:
		$Preparacion.hide()
		var objetivo := origen + Vector2(sin(tiempo * 1.5) * 45.0, sin(tiempo * 3.0) * 18.0)
		if visible_jugador and jugador.global_position.distance_to(origen) < alcance_deteccion * 1.5:
			var lado := -1.0 if jugador.global_position.x > global_position.x else 1.0
			objetivo = jugador.global_position + Vector2(lado * distancia_preferida, -120.0 + sin(tiempo * 3.0) * 12.0)
			$Visual.flip_h = jugador.global_position.x < global_position.x
			if recarga <= 0.0:
				preparando = true
				aviso_restante = tiempo_aviso
		velocity = (objetivo - global_position).limit_length(velocidad_vuelo)
	move_and_slide()
	procesar_contacto(delta)


func cancelar_disparo() -> void:
	preparando = false
	recarga = intervalo_disparos
	$Preparacion.hide()
	$Visual.modulate = Color.WHITE


func disparar() -> void:
	if muerto or not puede_ver_jugador(alcance_deteccion):
		cancelar_disparo()
		return
	var apuntado := global_position.direction_to(jugador.global_position)
	var salida := global_position + apuntado * 28.0
	for angulo in [-angulo_abanico, 0.0, angulo_abanico]:
		var huevo := HUEVO.instantiate()
		huevo.direccion = apuntado.rotated(deg_to_rad(angulo))
		huevo.rapidez = velocidad_huevo
		# Fuera del árbol de física: no crear cuerpos durante una consulta.
		_agregar_huevo.call_deferred(huevo, salida)
	Sonido.reproducir("ataque", -7.0)
	cancelar_disparo()


func _agregar_huevo(huevo: CharacterBody2D, salida: Vector2) -> void:
	if muerto or not is_inside_tree():
		huevo.free()
		return
	get_parent().add_child(huevo)
	huevo.global_position = salida
