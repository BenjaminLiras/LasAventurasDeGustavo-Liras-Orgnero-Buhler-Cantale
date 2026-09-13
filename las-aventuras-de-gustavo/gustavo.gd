extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_DURATION = 0.15

var doubleSalto = true
var direction: float = 0.0
var dashActivo = false
var dashEnCooldown = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("ui_accept") and !is_on_floor() and doubleSalto:
		velocity.y = JUMP_VELOCITY
		doubleSalto = false

	if is_on_floor() and !Input.is_action_just_pressed("ui_accept"):
		doubleSalto = true

	direction = Input.get_axis("ui_left", "ui_right")

	if Input.is_action_just_pressed("dash") and !dashActivo and !dashEnCooldown:
		dash()

	if !dashActivo:
		if direction:
			velocity.x = direction * SPEED
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
	velocity.x = direction * 700.0
	await get_tree().create_timer(DASH_DURATION).timeout
	dashActivo = false
	await get_tree().create_timer(0.2).timeout
	dashEnCooldown = false
