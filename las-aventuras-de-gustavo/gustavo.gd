extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var doubleSalto = true
var direction
var dashActivo = false


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("ui_accept") and !is_on_floor() and doubleSalto:
		velocity.y = JUMP_VELOCITY 
		doubleSalto = false
	if is_on_floor() and !Input.is_action_just_pressed("ui_accept"):
		doubleSalto = true
	direction = Input.get_axis("ui_left", "ui_right")
	if !dashActivo:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	if Input.is_action_just_pressed("dash"):
		dash()
	move_and_slide()
	Global.setVelocidad(velocity)
	Global.setDireccion(direction)
	Global.setDash(dashActivo)





func dash() -> void:
	if !dashActivo:
		velocity.x = velocity.x + 150
		dashActivo = true	
	await get_tree().create_timer(3)
	dashActivo = false
	velocity = Vector2.ZERO	
