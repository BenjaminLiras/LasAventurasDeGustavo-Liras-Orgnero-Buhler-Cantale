extends StaticBody2D

@export var vida: int = 1
@export var daño_contacto: int = 1

func recibir_golpe(cantidad: int = 1) -> void:
	if cantidad <= 0 or vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	if vida <= 0:
		romper()

func romper():
	queue_free()

func obtener_daño_contacto() -> int:
	return maxi(daño_contacto, 0)
