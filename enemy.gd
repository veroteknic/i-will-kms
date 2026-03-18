extends CharacterBody2D
@onready var ray_cast_right: RayCast2D = $right
@onready var ray_cast_left: RayCast2D = $left
@onready var right_wall: RayCast2D = $"right wall"
@onready var left_wall: RayCast2D = $"left wall"
@onready var health_component: Health = $Health
@onready var enemy_hurt_box: HurtBox = $HurtBox

var direction = 1
const SPEED = 300
const CHASE_SPEED = 450
const DETECTION_RANGE = 800
const ATTACK_RANGE = 150
var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float

enum State { PATROL, CHASE, ATTACK }
var current_state = State.PATROL
var player: CharacterBody2D = null
var raycast_to_player: RayCast2D
var last_blood_spawn_ms: int = -1000
var last_hit_was_slam: bool = false

@export_group("Blood")
@export var blood_enabled: bool = true
@export_range(0.0, 1.0, 0.01, "suffix:s") var blood_hit_cooldown: float = 0.06
@export_range(4, 80, 1) var blood_hit_amount: int = 18
@export_range(8, 120, 1) var blood_slam_amount: int = 36
@export_range(16, 220, 1) var blood_death_amount: int = 96
@export_range(16, 260, 1) var blood_slam_death_amount: int = 140


func _ready() -> void:
	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)
	if enemy_hurt_box:
		enemy_hurt_box.received_hit.connect(_on_hurt_box_received_hit)
	
	# Create raycast for player detection
	raycast_to_player = RayCast2D.new()
	raycast_to_player.collision_mask = 2  # Player layer
	raycast_to_player.enabled = true
	add_child(raycast_to_player)
	
	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func _physics_process(delta: float) -> void:
	velocity.x = 0.0
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# Check for player
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		var can_see_player = check_line_of_sight_to_player()
		
		# State machine
		match current_state:
			State.PATROL:
				if can_see_player and distance_to_player < DETECTION_RANGE:
					current_state = State.CHASE
				else:
					patrol_behavior(delta)
			
			State.CHASE:
				if not can_see_player or distance_to_player > DETECTION_RANGE * 1.5:
					current_state = State.PATROL
				elif distance_to_player < ATTACK_RANGE:
					current_state = State.ATTACK
				else:
					chase_behavior(delta)
			
			State.ATTACK:
				if distance_to_player > ATTACK_RANGE * 1.2:
					current_state = State.CHASE
				else:
					attack_behavior(delta)
	else:
		patrol_behavior(delta)

	move_and_slide()


func patrol_behavior(delta: float) -> void:
	# Original patrol logic
	if not ray_cast_right.is_colliding():
		direction = -1
		$Icon.flip_h = true
	if not ray_cast_left.is_colliding():
		direction = 1
		$Icon.flip_h = false
	if right_wall.is_colliding():
		direction = -1
		$Icon.flip_h = true
	if left_wall.is_colliding():
		direction = 1
		$Icon.flip_h = false
	velocity.x = direction * SPEED


func chase_behavior(delta: float) -> void:
	if player:
		# Move toward player
		var dir_to_player = sign(player.global_position.x - global_position.x)
		direction = dir_to_player
		$Icon.flip_h = direction < 0
		
		# Stop chasing across gaps or into walls
		if not _has_floor_ahead(direction) or _is_blocked_by_wall(direction):
			current_state = State.PATROL
			direction *= -1
		else:
			velocity.x = direction * CHASE_SPEED


func attack_behavior(_delta: float) -> void:
	if player:
		# Face player but don't move
		var dir_to_player = sign(player.global_position.x - global_position.x)
		$Icon.flip_h = dir_to_player < 0
	velocity.x = 0.0


func _has_floor_ahead(move_direction: int) -> bool:
	if move_direction > 0:
		return ray_cast_right.is_colliding()
	if move_direction < 0:
		return ray_cast_left.is_colliding()
	return true


func _is_blocked_by_wall(move_direction: int) -> bool:
	if move_direction > 0:
		return right_wall.is_colliding()
	if move_direction < 0:
		return left_wall.is_colliding()
	return false


func check_line_of_sight_to_player() -> bool:
	if not player or not raycast_to_player:
		return false
	
	raycast_to_player.target_position = to_local(player.global_position)
	raycast_to_player.force_raycast_update()
	
	if raycast_to_player.is_colliding():
		var collider = raycast_to_player.get_collider()
		# Check if we hit the player directly
		return collider and collider.is_in_group("player")
	
	return false


func _on_hurt_box_received_damage(_damage: int) -> void:
	pass


func _on_hurt_box_received_hit(source: Area2D) -> void:
	if not blood_enabled:
		return

	var now_ms := Time.get_ticks_msec()
	var cooldown_ms := int(maxf(blood_hit_cooldown, 0.0) * 1000.0)
	if now_ms - last_blood_spawn_ms < cooldown_ms:
		return
	last_blood_spawn_ms = now_ms

	var spray_direction := Vector2(float(direction), 0.0)
	if source and is_instance_valid(source):
		spray_direction = (global_position - source.global_position).normalized()
	if spray_direction.length_squared() <= 0.0001:
		spray_direction = Vector2(float(direction), 0.0)

	var is_slam := source and is_instance_valid(source) and source.name == "SlamHitBox"
	last_hit_was_slam = is_slam
	_shake_player_cameras(0.45 if is_slam else 0.2)
	_spawn_blood_spray(spray_direction, blood_slam_amount if is_slam else blood_hit_amount, 35.0 if is_slam else 25.0)


func _on_health_depleted() -> void:
	_shake_player_cameras(0.65 if last_hit_was_slam else 0.42)
	if blood_enabled:
		_spawn_blood_spray(Vector2(0, -1), blood_death_amount, 180.0)
		if last_hit_was_slam:
			_spawn_blood_spray(Vector2(0, -1), blood_slam_death_amount, 210.0)
	queue_free()


func _shake_player_cameras(default_amount: float) -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if not node or not is_instance_valid(node) or not node.has_method("add_screenshake_at_position"):
			continue
		var amount := default_amount
		var radius := 1200.0
		if "screenshake_enemy_hit_amount" in node:
			amount = node.screenshake_enemy_hit_amount if default_amount <= 0.45 else node.screenshake_enemy_death_amount
		if "screenshake_enemy_event_radius" in node:
			radius = node.screenshake_enemy_event_radius
		node.add_screenshake_at_position(amount, global_position, radius)


func _spawn_blood_spray(direction_2d: Vector2, amount: int, spread: float) -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.amount = amount
	particles.lifetime = 0.85
	particles.explosiveness = 1.0
	particles.randomness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	particles.spread = spread
	particles.direction = direction_2d
	particles.gravity = Vector2(0, 900)
	particles.initial_velocity_min = 160.0
	particles.initial_velocity_max = 480.0
	particles.damping_min = 12.0
	particles.damping_max = 32.0
	particles.scale_amount_min = 4.8
	particles.scale_amount_max = 11.7
	particles.color = Color(0.75, 0.02, 0.02, 1.0)
	particles.top_level = true
	particles.global_position = global_position
	var target_parent := get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(particles)
	particles.finished.connect(func() -> void:
		if particles and is_instance_valid(particles):
			particles.queue_free()
	)
	particles.emitting = true
