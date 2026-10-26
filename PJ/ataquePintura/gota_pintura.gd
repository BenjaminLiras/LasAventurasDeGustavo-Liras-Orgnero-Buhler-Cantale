extends Node2D

const VELOCIDAD := 760.0
const ALCANCE := 900.0
const DANIO := 3
var direccion := 1.0
var lanzador: CollisionObject2D
var distancia := 0.0
var exclusiones: Array[RID] = []
var explotando := false


func _ready() -> void:
	z_index = 3
	if is_instance_valid(lanzador):
		exclusiones.append(lanzador.get_rid())
	$Visual.rotation = -PI * 0.5 * direccion


func _physics_process(delta: float) -> void:
	if explotando:
		return
	var paso := minf(VELOCIDAD * delta, ALCANCE - distancia)
	var destino := global_position + Vector2(direccion * paso, 0.0)
	# Barre todo el trayecto para que la gota no atraviese enemigos ni paredes.
	var consulta := PhysicsRayQueryParameters2D.create(global_position, destino, 14, exclusiones)
	var impacto := get_world_2d().direct_space_state.intersect_ray(consulta)
	while not impacto.is_empty():
		var cuerpo: Object = impacto["collider"]
		if cuerpo.has_method("recibir_golpe"):
			cuerpo.call("recibir_golpe", DANIO)
			exclusiones.append(impacto["rid"])
			consulta.exclude = exclusiones
			Sonido.reproducir("impacto")
			impacto = get_world_2d().direct_space_state.intersect_ray(consulta)
		else:
			global_position = impacto["position"]
			salpicar()
			return
	global_position = destino
	distancia += paso
	if distancia >= ALCANCE:
		salpicar()


func salpicar() -> void:
	explotando = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 2.2), 0.14)
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(queue_free)
