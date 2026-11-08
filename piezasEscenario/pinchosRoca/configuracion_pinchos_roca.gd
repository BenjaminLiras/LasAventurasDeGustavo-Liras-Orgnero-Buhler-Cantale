@tool
extends Resource
class_name ConfiguracionPinchosRoca

@export_range(0, 128, 1) var cantidad := 6:
	set(valor):
		cantidad = clampi(valor, 0, 128)
		emit_changed()
@export_range(1.0, 256.0, 1.0, "suffix:px") var separacion := 40.0:
	set(valor):
		separacion = maxf(valor, 1.0)
		emit_changed()
@export_range(8.0, 256.0, 1.0, "suffix:px") var ancho := 40.0:
	set(valor):
		ancho = maxf(valor, 8.0)
		emit_changed()
@export_range(8.0, 256.0, 1.0, "suffix:px") var altura := 56.0:
	set(valor):
		altura = maxf(valor, 8.0)
		emit_changed()
@export_enum("Arriba", "Abajo", "Izquierda", "Derecha") var orientacion := 0:
	set(valor):
		orientacion = clampi(valor, 0, 3)
		emit_changed()
@export_range(1, 100, 1) var danio := 20
@export_range(0.05, 5.0, 0.05, "suffix:s") var intervalo_danio := 0.6
