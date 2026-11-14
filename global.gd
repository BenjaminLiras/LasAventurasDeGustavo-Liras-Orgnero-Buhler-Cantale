extends Node

signal economia_cambiada
signal mejoras_cambiadas

const BALANCE = preload("res://economia/balance.tres")
const MONEDA = preload("res://economia/Moneda.tscn")
var monedas: int = 0
var amuleto_alcance := false
var amuleto_vitalidad := false
var corazones_base: int = 5
var fragmentos_vida: int = 0
var fragmentos_recogidos: Dictionary = {}
var lata_disponible := true


func reiniciar_partida() -> void:
	monedas = 0
	amuleto_alcance = false
	amuleto_vitalidad = false
	corazones_base = 5
	fragmentos_vida = 0
	fragmentos_recogidos.clear()
	pintura_desbloqueada = false
	escalada_desbloqueada = false
	lata_disponible = true
	economia_cambiada.emit()
	mejoras_cambiadas.emit()


func vida_maxima() -> int:
	return corazones_base + (BALANCE.corazones_amuletos if amuleto_vitalidad else 0)


func comprar(tipo: String) -> bool:
	if tipo not in ["alcance", "vitalidad"]:
		return false
	var adquirido := amuleto_alcance if tipo == "alcance" else amuleto_vitalidad
	var precio: int = BALANCE.precio_alcance if tipo == "alcance" else BALANCE.precio_vitalidad
	if adquirido or monedas < precio:
		return false
	monedas -= precio
	if tipo == "alcance":
		amuleto_alcance = true
	else:
		amuleto_vitalidad = true
	economia_cambiada.emit()
	mejoras_cambiadas.emit()
	return true


func agregar_monedas(cantidad: int) -> void:
	monedas += maxi(cantidad, 0)
	economia_cambiada.emit()


func soltar_monedas(enemigo: Node2D, cantidad: int) -> void:
	# Diferido: las muertes suelen ocurrir durante una consulta física.
	_crear_moneda.call_deferred(enemigo.global_position, cantidad, enemigo.get_parent())


func _crear_moneda(posicion: Vector2, cantidad: int, contenedor: Node) -> void:
	if not is_instance_valid(contenedor) or not contenedor.is_inside_tree() or cantidad <= 0:
		return
	var moneda := MONEDA.instantiate()
	moneda.valor = cantidad
	contenedor.add_child(moneda)
	moneda.global_position = posicion

var punto_reaparicion: Vector2 = Vector2.ZERO
var dash: bool = false
var direccion: Vector2 = Vector2.ZERO
var velocidad: Vector2 = Vector2.ZERO
var pintura_desbloqueada := false
var escalada_desbloqueada := false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setDireccion(direccionParametro : Vector2) -> void :
	direccion = direccionParametro
	
func setVelocidad(velocidadParametro : Vector2) -> void :
	velocidad = velocidadParametro
	
func setDash(dashParametro : bool) -> void :
	dash = dashParametro

func getDireccion() -> Vector2 :
	return direccion
	
func getVelocidad() -> Vector2 :
	return velocidad
	
func getDash() -> bool :
	return dash
