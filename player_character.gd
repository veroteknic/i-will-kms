extends CharacterBody2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# Wall cling
const WALL_SLIDE_SPEED = 500.0
var wall_clinging = false
var wall_dir = 0  # -1 = left wall, 1 = right wall
var footstep_timer := 0.0
const FOOTSTEP_INTERVAL := 0.25
enum AnimState { IDLE, RUN, JUMP, FALL, DASH }
var anim_state: AnimState = AnimState.IDLE
var was_wall_clinging := false
const AMBIENT_SOUNDS = [
	preload("res://br_metal_randoms_grn_01.wav"),
	preload("res://br_metal_randoms_grn_02.wav")
]

const MIN_DELAY := 0.8
const MAX_DELAY := 2.5

var ambient_timer := 0.0

# movement
var movement_speed = 900.0
const AIR_ACCEL = 5000.0
const GROUND_ACCEL = 12000.0
const FRICTION = 8000.0
const MIN_JUMP_FORCE = -900.0
var jump_held = false

# jump / slam
const JUMP_FORCE = -1700.0
const SLAM_SPEED = 3500.0
const MIN_SLAM_HEIGHT = 50.0

# slide
const SLIDE_SPEED = 1600.0
const SLIDE_DECAY = 0.80
const SLIDE_MIN_SPEED = 150.0
var sliding = false

# dash
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
var jump_count = 0

func _physics_process(delta: float) -> void: 
	ambient_timer -= delta

	if ambient_timer <= 0:
		$AmbientPlayer.stream = AMBIENT_SOUNDS.pick_random()
		$AmbientPlayer.play()
		ambient_timer = randf_range(MIN_DELAY, MAX_DELAY)

	var input_x = Input.get_axis("left", "right")
	# After wall cling detection
	if wall_clinging and not was_wall_clinging:
		$falling.play()

	if not wall_clinging and was_wall_clinging:
		$falling.stop()

	was_wall_clinging = wall_clinging

	if dashing:
		if arm:
			arm.visible = false
			arm.set_process(false)
	else:
		if arm:
			arm.visible = true
			arm.set_process(true)
	
	# Track facing direction
	if input_x != 0:
		last_facing_direction = input_x

	# Dash input
	if Input.is_action_just_pressed("dash") and dash_available and dashes > 0:
		dash.play()
		start_dash()
		dashes -= 1
		if dashes == 0:
			$"dash reset".start()
	if is_on_floor() and abs(velocity.x) > 800:
		footstep_timer -= delta
		if footstep_timer <= 0:
			$FootstepPlayer.play()
			footstep_timer = FOOTSTEP_INTERVAL
	else:
		footstep_timer = 0
	if dashing:
		# During dash, ignore other movement
		pass
	else:
		# Gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Jump / Wall jump
		if Input.is_action_just_pressed("jump"):
			if is_on_floor():
				velocity.y = JUMP_FORCE
				jump_held = true
				$Jump.play()
			elif wall_clinging:
				# Wall jump
				velocity.y = JUMP_FORCE
				velocity.x = -wall_dir * movement_speed
				wall_clinging = false

		# Stop holding jump early
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y = max(velocity.y, MIN_JUMP_FORCE)
			jump_held = false

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
					var target_speed = input_x * movement_speed
					velocity.x = move_toward(velocity.x, target_speed, GROUND_ACCEL * delta)
				else:
					velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			else:
				var target = input_x * movement_speed
				velocity.x = move_toward(velocity.x, target, AIR_ACCEL * delta)

	# Move character
	move_and_slide()

	# Wall cling detection after movement
	wall_clinging = false
	if not is_on_floor():
		for i in range(get_slide_collision_count()):
			var col: KinematicCollision2D = get_slide_collision(i)
			if col and abs(col.get_normal().x) > 0.9:  # left/right wall
				wall_clinging = true
				wall_dir = col.get_normal().x
				velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
				break

	update_animation()


func update_animation() -> void:
	resolve_anim_state()
	apply_anim_state()

func resolve_anim_state() -> void:
	if dashing:
		anim_state = AnimState.DASH
		return
	if not is_on_floor():
		if velocity.y < 0:
			anim_state = AnimState.JUMP
		else:
			anim_state = AnimState.FALL
		return
	if abs(velocity.x) > 0.1:
		anim_state = AnimState.RUN
	else:
		anim_state = AnimState.IDLE

func apply_anim_state() -> void:
	match anim_state:
		AnimState.DASH:
			play_anim("dash")
		AnimState.RUN:
			play_anim("walking")
		AnimState.IDLE:
			play_anim("idle")
		AnimState.JUMP:
			play_anim("jump")
		AnimState.FALL:
			play_anim("jump")

func play_anim(name: String) -> void:
	if sprite.animation != name:
		sprite.play(name)

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
func play_footstep():
	if not is_on_floor():
		return
	$FootstepPlayer.play()
