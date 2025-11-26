extends CharacterBody2D

const SPEED = 1100.0
const JUMP_VELOCITY = -1000.0
const AIR_SPEED_MULTIPLIER = 1.5
const AIR_CONTROL = 8.0   # nice and sane

func _physics_process(delta: float) -> void:
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# ground jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# get horizontal input
	var x_input = Input.get_axis("left", "right")

	if is_on_floor():
		# normal ground movement
		if x_input != 0:
			velocity.x = x_input * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# in air, give limited control
		var target_x = x_input * SPEED * AIR_SPEED_MULTIPLIER
		velocity.x = lerp(velocity.x, target_x, AIR_CONTROL * delta)

	move_and_slide()
