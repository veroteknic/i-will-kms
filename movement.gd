extends CharacterBody2D

const GRAVITY = 2500.0
const JUMP_VELOCITY = -900.0
const MOVE_SPEED = 400.0
const SLAM_SPEED = 2600.0
const MIN_IMPACT_SPEED = 800.0

var is_slamming = false
var slam_ready = true
var was_on_floor = false

func _physics_process(delta):
	# apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# move left/right
	var dir = Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * MOVE_SPEED

	# jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("jump"):
		$Jump.play()

	# start slam
	if Input.is_action_just_pressed("slam") and not is_on_floor() and slam_ready:
		is_slamming = true
		slam_ready = false
		velocity.y = SLAM_SPEED
		if $SlamStart: 
			$SlamStart.play()
		print("Slam initiated")

	# landing logic
	if not was_on_floor and is_on_floor():
		_handle_landing()

	move_and_slide()
	was_on_floor = is_on_floor()


func _handle_landing():
	if is_slamming:
		is_slamming = false
		var impact_speed = abs(velocity.y)
		if impact_speed > MIN_IMPACT_SPEED:
			if $ImpactSlam: 
				$ImpactSlam.play()
			print("BIG BOY landed")
		else:
			if $SlamSound: 
				$SlamSound.play()
			print("Smol goober bonk")
		_reset_slam_ready()
	else:
		# Normal fall impact (no slam)
		var impact_speed = abs(velocity.y)
		if impact_speed > MIN_IMPACT_SPEED:
			if $SlamSound:
				$SlamSound.play()
			print("Normal thud")

	# zero out Y velocity after deciding what to play
	velocity.y = 0


func _reset_slam_ready():
	await get_tree().create_timer(0.2).timeout
	slam_ready = true
