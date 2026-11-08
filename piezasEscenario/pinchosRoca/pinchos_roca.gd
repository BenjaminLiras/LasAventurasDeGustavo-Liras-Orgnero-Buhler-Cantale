@tool
extends Area2D

const DatosRocas = preload("res://piezasEscenario/pinchosRoca/configuracion_pinchos_roca.gd")
const ROCA = preload("res://assets/pinchos_roca/roca_puntiaguda.tres")

@export var configuracion: DatosRocas:
	set(valor):
		if configuracion != null and configuracion.changed.is_connected(_solicitar_reconstruccion):
			configuracion.changed.disconnect(_solicitar_reconstruccion)
		configuracion = valor
		if configuracion != null:
			configuracion.changed.connect(_solicitar_reconstruccion)
		_solicitar_reconstruccion()

var reconstruccion_pendiente := false
var reloj := 0.0
var proximos_golpes: Dictionary = {}


func _ready() -> void:
	if configuracion == null:
		configuracion = DatosRocas.new()
	_reconstruir()


func _solicitar_reconstruccion() -> void:
	if is_node_ready() and not reconstruccion_pendiente:
		reconstruccion_pendiente = true
		_reconstruir.call_deferred()


func _reconstruir() -> void:
	reconstruccion_pendiente = false
	if not is_node_ready() or configuracion == null:
		return
	for hijo in $Visuales.get_children():
		$Visuales.remove_child(hijo)
		hijo.queue_free()
	for hijo in get_children():
		if hijo is CollisionPolygon2D:
			remove_child(hijo)
			hijo.queue_free()
	proximos_golpes.clear()
	var angulos := [0.0, PI, -PI * 0.5, PI * 0.5]
	var angulo: float = angulos[configuracion.orientacion]
	for i in range(configuracion.cantidad):
		var x := (float(i) - float(configuracion.cantidad - 1) * 0.5) * configuracion.separacion
		var espejo := -1.0 if i % 2 else 1.0
		var sprite := Sprite2D.new()
		sprite.name = "Roca%d" % (i + 1)
		sprite.texture = ROCA
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(x, -configuracion.altura * 0.5).rotated(angulo)
		sprite.rotation = angulo
		sprite.scale = Vector2(configuracion.ancho / 16.0, configuracion.altura / 16.0)
		sprite.flip_h = espejo < 0.0
		$Visuales.add_child(sprite)
		var forma := CollisionPolygon2D.new()
		forma.name = "ColisionRoca%d" % (i + 1)
		var puntos := PackedVector2Array([
			Vector2(x - configuracion.ancho * 0.5 * espejo, 0.0),
			Vector2(x - configuracion.ancho * 0.0625 * espejo, -configuracion.altura),
			Vector2(x + configuracion.ancho * 0.375 * espejo, 0.0)
		])
		for j in range(puntos.size()):
			puntos[j] = puntos[j].rotated(angulo)
		forma.polygon = puntos
		add_child(forma)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or configuracion == null:
		return
	reloj += delta
	for cuerpo in get_overlapping_bodies():
		if not cuerpo.is_in_group("jugador") or not cuerpo.has_method("recibir_golpe"):
			continue
		var id: int = cuerpo.get_instance_id()
		if reloj < float(proximos_golpes.get(id, 0.0)):
			continue
		proximos_golpes[id] = reloj + maxf(configuracion.intervalo_danio, 0.05)
		cuerpo.call("recibir_golpe", configuracion.danio)
