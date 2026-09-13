extends Node

var dash
var direccion
var velocidad
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setDireccion(direccionParametro : float) -> void :
	direccion = direccionParametro
	
func setVelocidad(velocidadParametro : Vector2) -> void :
	velocidad = velocidadParametro
	
func setDash(dashParametro : bool) -> void :
	dash = dashParametro

func getDireccion() -> float :
	return direccion
	
func getVelocidad() -> Vector2 :
	return velocidad
	
func getDash() -> bool :
	return dash
