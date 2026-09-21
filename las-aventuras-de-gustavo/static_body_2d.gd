extends StaticBody2D

@export var vida: int = 1

func recibir_golpe(daño: int = 1):
	vida -= daño
	if vida <= 0:
		romper()

func romper():
	queue_free()
