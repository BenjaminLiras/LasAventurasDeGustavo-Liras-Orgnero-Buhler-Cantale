@tool
extends Node2D

const DatosPinchos = preload("res://piezasEscenario/pinchosPareja/configuracion_pinchos.gd")
enum Estado { ABIERTO, AVISO, EXTENDIENDO, CERRADO, RETRAYENDO }

@export var configuracion: DatosPinchos:
	set(valor):
		if configuracion != null and configuracion.changed.is_connected(_reiniciar):
			configuracion.changed.disconnect(_reiniciar)
		configuracion = valor
		if configuracion != null:
			configuracion.changed.connect(_reiniciar)
		if is_node_ready():
			_reiniciar()

var estado := Estado.ABIERTO
var tiempo_estado := 0.0
var longitud_actual := 0.0
var retraso_restante := 0.0
var reloj := 0.0
var proximos_golpes: Dictionary = {}


func _ready() -> void:
	if configuracion == null:
		configuracion = DatosPinchos.new()
	_reiniciar()


func _reiniciar() -> void:
	if not is_node_ready() or configuracion == null:
		return
	estado = Estado.ABIERTO
	tiempo_estado = 0.0
	retraso_restante = configuracion.retraso_inicial
	reloj = 0.0
	proximos_golpes.clear()
	$Izquierdo.position.x = -configuracion.separacion * 0.5
	$Derecho.position.x = configuracion.separacion * 0.5
	$GuiaCentro.visible = Engine.is_editor_hint()
	$GuiaCentro.points = PackedVector2Array([$Izquierdo.position, $Derecho.position])
	longitud_actual = configuracion.separacion * 0.5 if Engine.is_editor_hint() else _longitud_minima()
	_actualizar_geometria()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or configuracion == null:
		return
	reloj += delta
	if retraso_restante > 0.0:
		var espera := minf(retraso_restante, delta)
		retraso_restante -= espera
		delta -= espera
		if delta <= 0.0:
			return
	tiempo_estado += delta
	while tiempo_estado >= _duracion_estado():
		tiempo_estado -= _duracion_estado()
		estado = (estado + 1) % Estado.size()
	var progreso := clampf(tiempo_estado / _duracion_estado(), 0.0, 1.0)
	var alcance := configuracion.separacion * 0.5
	match estado:
		Estado.ABIERTO, Estado.AVISO:
			longitud_actual = _longitud_minima()
		Estado.EXTENDIENDO:
			longitud_actual = lerpf(_longitud_minima(), alcance, progreso * progreso)
		Estado.CERRADO:
			longitud_actual = alcance
		Estado.RETRAYENDO:
			longitud_actual = lerpf(alcance, _longitud_minima(), smoothstep(0.0, 1.0, progreso))
	_actualizar_geometria()
	_aplicar_danio()


func _duracion_estado() -> float:
	match estado:
		Estado.ABIERTO:
			return configuracion.tiempo_abierto
		Estado.AVISO:
			return configuracion.tiempo_aviso
		Estado.EXTENDIENDO:
			return configuracion.tiempo_extension
		Estado.CERRADO:
			return configuracion.tiempo_cerrado
	return configuracion.tiempo_retraccion


func _longitud_minima() -> float:
	return clampf(configuracion.longitud_retraida, 1.0, configuracion.separacion * 0.5 - 1.0)


func _actualizar_geometria() -> void:
	for lado in [1.0, -1.0]:
		var brazo: Node2D = $Izquierdo if lado > 0.0 else $Derecho
		var pincho: Sprite2D = brazo.get_node("Pincho")
		pincho.rotation = PI * 0.5 * lado
		pincho.position = Vector2(longitud_actual * 0.5 * lado, 0.0)
		pincho.scale = Vector2(configuracion.altura_pincho / 30.0, longitud_actual / 13.0)
		# Cuatro puntas del asset, con sus cuatro colisiones triangulares.
		for i in range(4):
			var centro := (-10.5 + float(i) * 7.0) * configuracion.altura_pincho / 30.0
			var mitad_base := configuracion.altura_pincho * 3.5 / 30.0
			var nombre := "Peligro/Colision" if i == 0 else "Peligro/Colision%d" % (i + 1)
			brazo.get_node(nombre).polygon = PackedVector2Array([
				Vector2(0.0, centro - mitad_base), Vector2(longitud_actual * lado, centro),
				Vector2(0.0, centro + mitad_base)
			])
		var base: Sprite2D = brazo.get_node("Base")
		base.rotation = PI * 0.5 * lado
		base.position = Vector2(-7.0 * lado, 0.0)
		base.scale = Vector2(configuracion.altura_pincho * 1.15 / 30.0, 2.0)
		var aviso := estado == Estado.AVISO
		base.modulate = Color(1.0, 0.45, 0.18) if aviso else Color(0.72, 0.9, 0.9)


func _aplicar_danio() -> void:
	if longitud_actual <= _longitud_minima() + 0.1:
		return
	for zona: Area2D in [$Izquierdo/Peligro, $Derecho/Peligro]:
		for cuerpo in zona.get_overlapping_bodies():
			if not cuerpo.is_in_group("jugador") or not cuerpo.has_method("recibir_golpe"):
				continue
			var id := cuerpo.get_instance_id()
			if reloj < float(proximos_golpes.get(id, 0.0)):
				continue
			proximos_golpes[id] = reloj + maxf(configuracion.intervalo_danio, 0.05)
			cuerpo.call("recibir_golpe", configuracion.danio)
