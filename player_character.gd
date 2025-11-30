extends CharacterBody2D

# movement
const MOVE_SPEED = 900.0
const AIR_ACCEL = 5000.0
const GROUND_ACCEL = 12000.0
const FRICTION = 8000.0

# jump / slam
const JUMP_FORCE = -1500.0
const SLAM_SPEED = 3500.0
const MIN_SLAM_HEIGHT = 50.0

# slide
const SLIDE_SPEED = 1600.0
const SLIDE_DECAY = 0.80
const SLIDE_MIN_SPEED = 150.0
var sliding = false

func _physics_process(delta: float) -> void: 
	var input_x = Input.get_axis("left", "right")

	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_FORCE

	# Slam
	if Input.is_action_just_pressed("slam") and not is_on_floor() and velocity.y < MIN_SLAM_HEIGHT:
		velocity.y = SLAM_SPEED

	# Slide
	if Input.is_action_just_pressed("slam") and is_on_floor():
		sliding = true
		velocity.x = input_x * SLIDE_SPEED

	if sliding:
		velocity.x *= SLIDE_DECAY
		if abs(velocity.x) < SLIDE_MIN_SPEED or not Input.is_action_pressed("slam"):
			sliding = false
	else:
		if is_on_floor():
			if input_x != 0:
				velocity.x = move_toward(velocity.x, input_x * MOVE_SPEED, GROUND_ACCEL * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		else:
			var target = input_x * MOVE_SPEED
			velocity.x = move_toward(velocity.x, target, AIR_ACCEL * delta)

	move_and_slide()
