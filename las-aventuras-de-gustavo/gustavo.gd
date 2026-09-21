extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ataqueSimpleEscena = preload("res://ataqueBase.tscn")
const DASH_DURATION = 0.3
var DASH_DIRECTION : Vector2
var direction: Vector2 = Vector2(0,0)
var dashActivo = false
var dashEnCooldown = false

func _process(delta: float) -> void:
	$Camera2D/Velocidad.text = "velocidad:" + str(Global.getVelocidad())
	$Camera2D/Dash.text = "Dash:" + str(Global.getDash())
	$Camera2D/Direccion.text = "Direccion:x" + str(Global.getDireccion().x) + "y" + str(Global.getDireccion().y)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

	
	direction.x = Input.get_axis("ui_left", "ui_right")

	if Input.is_action_just_pressed("dash") :
		dash()
		
	if Input.is_action_just_pressed("ataqueSimple") :
		ataqueSimple()
	if !dashEnCooldown:
		if direction:
			velocity.x = direction.x * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	Global.setVelocidad(velocity)
	Global.setDireccion(direction)
	Global.setDash(dashActivo)


func dash() -> void:
	if dashActivo or dashEnCooldown:
		return	
	dashActivo = true
	dashEnCooldown = true
	DASH_DIRECTION = (get_global_mouse_position() - global_position).normalized()
	velocity = DASH_DIRECTION * 700.0
	await get_tree().create_timer(DASH_DURATION).timeout
	await get_tree().create_timer(0.2).timeout
	dashEnCooldown = false

func ataqueSimple() -> void:

	var ataqueDireccion := (get_global_mouse_position() - global_position).normalized()
	if ataqueDireccion == Vector2.ZERO:
		ataqueDireccion = Vector2.RIGHT
	var ataqueSimple := ataqueSimpleEscena.instantiate() as Area2D
	add_child(ataqueSimple)
	ataqueSimple.position = ataqueDireccion * 20.0
	ataqueSimple.global_rotation = ataqueDireccion.angle()





func _on_area_2d_body_entered(body: Node2D) -> void:
	dashActivo = false
