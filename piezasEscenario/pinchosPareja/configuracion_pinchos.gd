@tool
extends Resource
class_name ConfiguracionPinchosPareja

## Distancia entre las dos bocas. Cada pincho alcanza exactamente la mitad.
@export_range(96.0, 2400.0, 1.0, "or_greater", "suffix:px") var separacion := 360.0:
	set(valor):
		separacion = maxf(valor, 96.0)
		emit_changed()
@export_range(12.0, 160.0, 1.0, "suffix:px") var altura_pincho := 48.0:
	set(valor):
		altura_pincho = maxf(valor, 12.0)
		emit_changed()
@export_range(0.0, 100.0, 1.0, "suffix:px") var longitud_retraida := 12.0:
	set(valor):
		longitud_retraida = maxf(valor, 0.0)
		emit_changed()

@export_group("Ciclo")
@export_range(0.05, 10.0, 0.05, "suffix:s") var tiempo_abierto := 1.6:
	set(valor):
		tiempo_abierto = maxf(valor, 0.05)
		emit_changed()
@export_range(0.05, 5.0, 0.05, "suffix:s") var tiempo_aviso := 0.5:
	set(valor):
		tiempo_aviso = maxf(valor, 0.05)
		emit_changed()
@export_range(0.05, 5.0, 0.05, "suffix:s") var tiempo_extension := 0.35:
	set(valor):
		tiempo_extension = maxf(valor, 0.05)
		emit_changed()
@export_range(0.05, 10.0, 0.05, "suffix:s") var tiempo_cerrado := 0.65:
	set(valor):
		tiempo_cerrado = maxf(valor, 0.05)
		emit_changed()
@export_range(0.05, 5.0, 0.05, "suffix:s") var tiempo_retraccion := 0.6:
	set(valor):
		tiempo_retraccion = maxf(valor, 0.05)
		emit_changed()
@export_range(0.0, 10.0, 0.05, "suffix:s") var retraso_inicial := 0.4:
	set(valor):
		retraso_inicial = maxf(valor, 0.0)
		emit_changed()

@export_group("Daño")
@export_range(1, 100, 1) var danio := 20
@export_range(0.05, 5.0, 0.05, "suffix:s") var intervalo_danio := 0.6
