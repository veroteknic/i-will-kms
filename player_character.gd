extends CharacterBody2D

# movement
var movement_speed = 900.0
const AIR_ACCEL = 5000.0
const GROUND_ACCEL = 12000.0
const FRICTION = 8000.0

# jump / slam
const JUMP_FORCE = -1700.0
const SLAM_SPEED = 3500.0
const MIN_SLAM_HEIGHT = 50.0

# slide
const SLIDE_SPEED = 1600.0
const SLIDE_DECAY = 0.80
const SLIDE_MIN_SPEED = 150.0
var sliding = false

#  dash
const DASH_SPEED = 2000
const DASH_DURATION = 0.5
const DASH_COOLDOWN = 0.3
var dashes = 3
var dash_available = true
var dashing = false
var last_facing_direction = 1.0
var run_available = true
@onready var arm: Node2D = $Node2D
@onready var dash: AudioStreamPlayer2D = $dash
# jumpy shit
var jump_count = 0
func _physics_process(delta: float) -> void: 
	var input_x = Input.get_axis("left", "right")
	if dashing == true:
		$Sprite2D.visible = true
		$"Sprite-0002".visible = false
		# orient dash sprite to face movement direction
		var dash_sx = abs($Sprite2D.scale.x)
		if last_facing_direction < 0:
			$Sprite2D.scale.x = -dash_sx
		else:
			$Sprite2D.scale.x = dash_sx
		# disable arm while dashing
		if arm:
			arm.visible = false
			arm.set_process(false)
	else:
		$Sprite2D.visible = false
		$"Sprite-0002".visible = true

		# re-enable arm when not dashing
		if arm:
			arm.visible = true
			arm.set_process(true)
	
	# Track facing direction
	if input_x != 0:
		last_facing_direction = input_x

	# Running (hold 'run' to sprint while on the ground)
	
	# Dash
	if Input.is_action_just_pressed("dash") and dash_available and dashes == 3:
		dash.play()
		start_dash()
		dashes = 2
	if Input.is_action_just_pressed("dash") and dash_available and dashes == 2:
		dash.play()
		start_dash()
		dashes = 1
	if Input.is_action_just_pressed("dash") and dash_available and dashes == 1:
		dash.play()
		start_dash()
		dashes = 0
		$"dash reset".start()
	if Input.is_action_just_pressed("dash") and dash_available and dashes == 0:
		pass
	if dashing:
		# During dash, move in dash direction and bypass other movement
		pass
	else:
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
					var target_speed = input_x * (movement_speed)
					velocity.x = move_toward(velocity.x, target_speed, GROUND_ACCEL * delta)
				else:
					velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			else:
				var target = input_x * movement_speed
				velocity.x = move_toward(velocity.x, target, AIR_ACCEL * delta)

	move_and_slide()


func start_dash() -> void:
	dashing = true
	dash_available = false
	velocity.x = last_facing_direction * DASH_SPEED
	velocity.y = 0
	await get_tree().create_timer(DASH_DURATION).timeout
	dashing = false
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	dash_available = true


func _on_dash_reset_timeout() -> void:
	print("you can dash again")
	dashes = 3
