extends CharacterBody2D

# --- Movement Settings ---
@export var move_speed := 750.0
@export var accel := 50.0
@export var friction := 15.0
@export var jump_force := -1000.0
@export var gravity := 2500.0
@export var max_fall_speed := 2200.0

# --- Dash Settings ---
@export var dash_speed := 3000.0
@export var dash_time := 0.15
@export var dash_cooldown_time := 0.5

# --- Slam Settings ---
@export var slam_force := 2900.0
@export var slam_storage_time := 1.0

# --- Wall Movement Settings ---
@export var wall_slide_speed := 230.0
@export var wall_climb_speed := 290.0
@export var wall_jump_force := Vector2(-300, -900)
@export var max_wall_jumps := 3

# --- Slide Settings ---
@export var slide_speed := 1200.0
@export var slide_friction := 5.0

# --- State Variables ---
var input_dir := Vector2.ZERO
var is_dashing := false
var can_dash := true
var is_slam_stored := false
var on_wall := false
var wall_dir := 0
var wall_jumps_used := 0
var is_sliding := false
var wall_friction := friction

# --- Nodes ---
@onready var dash_timer = $dash_timer
@onready var dash_cooldown = $dash_cooldown
@onready var slam_timer = $slamtimer
@onready var dash_sound = $DashSound
@onready var landing_sound = $landing
@onready var falling_sound = $falling

func _ready():
	dash_timer.timeout.connect(_on_dash_end)
	dash_cooldown.timeout.connect(_on_dash_cooldown)
	slam_timer.timeout.connect(_on_slam_timeout)

func _physics_process(delta):
	handle_input()
	handle_gravity(delta)
	handle_wall()
	handle_movement(delta)
	handle_slam(delta)
	handle_slide(delta)
	move_and_slide()
	check_landing_sounds()

# --- Input ---
func handle_input():
	input_dir = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"), 0)

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_force
			wall_jumps_used = 0
		elif on_wall and wall_jumps_used < max_wall_jumps:
			velocity = Vector2(wall_jump_force.x * -wall_dir, wall_jump_force.y)
			wall_jumps_used += 1
			wall_friction = friction / 2  # reduce friction after wall jump

	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash()

	if Input.is_action_just_pressed("slam") and not is_on_floor():
		if not is_slam_stored:
			is_slam_stored = true
			slam_timer.start(slam_storage_time)
		
# --- Movement ---
func handle_gravity(delta):
	if not is_on_floor() and not is_dashing:
		velocity.y += gravity * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed

func handle_movement(delta):
	if not is_dashing:
		var target = input_dir.x * move_speed
		velocity.x = lerp(velocity.x, target, accel * delta if input_dir.x != 0 else wall_friction * delta)
func handle_wall():
	on_wall = false
	if not is_on_floor():
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			if col.get_normal().x != 0:
				on_wall = true
				wall_dir = sign(col.get_normal().x)
				break

	if on_wall:
		var current_wall_speed = wall_slide_speed
		if wall_jumps_used >= max_wall_jumps:
			current_wall_speed *= 3  # slide down faster after wall jumps used

		if Input.is_action_pressed("up"):
			velocity.y = -wall_climb_speed
		elif velocity.y > current_wall_speed:
			velocity.y = current_wall_speed

# --- Dash ---
func start_dash():
	is_dashing = true
	can_dash = false
	dash_sound.play()
	velocity = Vector2(input_dir.x if input_dir.x != 0 else 1, 0) * dash_speed
	dash_timer.start(dash_time)

func _on_dash_end():
	is_dashing = false
	dash_cooldown.start(dash_cooldown_time)

func _on_dash_cooldown():
	can_dash = true

# --- Slam ---
func handle_slam(delta):
	if is_slam_stored and Input.is_action_just_pressed("slam") and not is_on_floor():
		is_slam_stored = false
		slam_timer.stop()
		velocity.y = slam_force
		falling_sound.play()

func _on_slam_timeout():
	is_slam_stored = false

# --- Slide ---
func handle_slide(delta):
	if is_on_floor() and Input.is_action_pressed("slide"):
		if not is_sliding:
			is_sliding = true
			velocity.x = input_dir.x * slide_speed
	else:
		is_sliding = false

	if is_sliding:
		# apply slide friction
		velocity.x = lerp(velocity.x, 0, slide_friction * delta)

# --- Sounds ---
func check_landing_sounds():
	if is_on_floor() and abs(velocity.y) > 400:
		landing_sound.play()
