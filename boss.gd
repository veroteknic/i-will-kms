extends CharacterBody2D
class_name Boss

@onready var sprite: AnimatedSprite2D = $BossVisual/AnimatedSprite2D
@onready var shield_visual: Sprite2D = $BossVisual/ShieldVisual
@onready var health_component: Node = $Health
@onready var hurt_box: Area2D = $BasicHurtBox2D
@onready var shield: BossShield = $Shield

@export var projectile_scene: PackedScene = preload("res://boss_projectile.tscn")
@export var projectile_damage: int = 1

# Boss movement
@export var move_speed: float = 150.0
@export var move_range: float = 300.0

# Attack patterns
@export var attack_pattern: String = "cycle"  # "straight", "spread", "burst", "cycle"
@export var shoot_cooldown: float = 0.6
@export var spread_count: int = 3
@export var spread_angle: float = 45.0
@export var pattern_cycle: Array[String] = ["straight", "spread", "burst"]
@export var close_range: float = 220.0
@export var far_range: float = 420.0

var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float
var player: CharacterBody2D = null
var time_since_last_shot: float = 0.0
var attack_timer: float = 0.0
var attack_duration: float = 3.0
var attack_cycle_index: int = 0
var default_shoot_cooldown: float = 0.6

enum State { IDLE, ATTACKING, VULNERABLE }
var current_state: State = State.IDLE
var attack_direction: int = 1


func _ready() -> void:
	# Connect health signal
	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)
	
	# Connect shield signals
	if shield:
		shield.shield_damaged.connect(_on_shield_damaged)
		shield.shield_broken.connect(_on_shield_broken)
		shield.shield_restored.connect(_on_shield_restored)
	
	if hurt_box:
		hurt_box.received_hit.connect(_on_hurt_box_received_hit)
	default_shoot_cooldown = shoot_cooldown
	
	# Find player
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
	# Default animation
	if sprite:
		sprite.play("idle")
	if shield_visual:
		shield_visual.visible = shield.is_active() if shield else false


func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	
	# Update timers
	time_since_last_shot += delta
	attack_timer += delta
	
	# State machine
	if player and is_instance_valid(player):
		var distance_to_player = global_position.distance_to(player.global_position)
		
		match current_state:
			State.IDLE:
				idle_behavior(delta)
				if distance_to_player < 600:
					current_state = State.ATTACKING
					attack_timer = 0.0
			
			State.ATTACKING:
				attack_behavior(delta)
				if attack_timer >= attack_duration:
					current_state = State.IDLE
					attack_timer = 0.0
			
			State.VULNERABLE:
				vulnerable_behavior(delta)
	else:
		idle_behavior(delta)
	
	move_and_slide()


func idle_behavior(delta: float) -> void:
	"""Idle state - slow hover movement."""
	if sprite and sprite.animation != "idle":
		sprite.play("idle")
	
	# Gentle movement
	velocity.x = sin(Time.get_ticks_msec() * 0.002) * move_speed * 0.25
	if player and is_instance_valid(player):
		var distance_to_player = abs(global_position.x - player.global_position.x)
		if distance_to_player > far_range:
			velocity.x = sign(player.global_position.x - global_position.x) * move_speed


func attack_behavior(delta: float) -> void:
	"""Attacking state - face player and execute attack pattern."""
	if not player:
		return
	
	# Face player
	var dir_to_player = sign(player.global_position.x - global_position.x)
	attack_direction = int(dir_to_player)
	sprite.flip_h = attack_direction < 0
	
	# Play shooting animation
	if sprite and sprite.animation != "shoot":
		sprite.play("shoot")
	
	# Keep some distance
	var distance_to_player = abs(global_position.x - player.global_position.x)
	if distance_to_player < close_range:
		velocity.x = -attack_direction * move_speed
	elif distance_to_player > far_range:
		velocity.x = attack_direction * move_speed
	else:
		velocity.x = 0.0
	
	# Execute attack pattern
	if time_since_last_shot >= shoot_cooldown:
		var pattern := attack_pattern
		if pattern == "cycle" and not pattern_cycle.is_empty():
			pattern = pattern_cycle[attack_cycle_index % pattern_cycle.size()]
			attack_cycle_index += 1
		match pattern:
			"straight":
				_shoot_straight()
			"spread":
				_shoot_spread()
			"burst":
				_shoot_burst()
		time_since_last_shot = 0.0


func vulnerable_behavior(delta: float) -> void:
	"""Vulnerable state - after shield breaks."""
	if sprite and sprite.animation != "down":
		sprite.play("down")
	
	velocity.x = 0.0


func _shoot_straight() -> void:
	"""Single projectile straight at player."""
	if not player:
		return
	
	var projectile = projectile_scene.instantiate() as BossProjectile
	get_parent().add_child(projectile)
	projectile.setup(_get_muzzle_position(), player.global_position, projectile_damage)


func _shoot_spread() -> void:
	"""Multiple projectiles in spread pattern."""
	if not player:
		return
	
	var center_direction = (player.global_position - global_position).normalized()
	var center_angle = center_direction.angle()
	
	for i in range(spread_count):
		var angle_offset = (i - spread_count / 2.0) * (spread_angle / spread_count)
		var angle = center_angle + angle_offset
		var direction = Vector2(cos(angle), sin(angle))
		var target_pos = _get_muzzle_position() + direction * 500
		
		var projectile = projectile_scene.instantiate() as BossProjectile
		get_parent().add_child(projectile)
		projectile.setup(_get_muzzle_position(), target_pos, projectile_damage)


func _shoot_burst() -> void:
	"""Rapid-fire burst."""
	if not player or time_since_last_shot > shoot_cooldown * 0.5:
		return
	
	for _i in range(2):
		var projectile = projectile_scene.instantiate() as BossProjectile
		get_parent().add_child(projectile)
		projectile.setup(_get_muzzle_position(), player.global_position, projectile_damage)


func _on_hurt_box_received_hit(source: Area2D) -> void:
	"""Handle incoming damage."""
	# Check if shield absorbs the hit
	if shield and shield.is_active():
		shield.take_damage(1)
		return
	
	# If shield is down, health takes damage
	if health_component and "health" in health_component:
		health_component.health -= 1
		
		# Enter vulnerable state briefly when hit
		if current_state != State.VULNERABLE:
			current_state = State.VULNERABLE
			await get_tree().create_timer(0.5).timeout
			if current_state == State.VULNERABLE:
				current_state = State.IDLE


func _on_health_depleted() -> void:
	"""Boss defeated."""
	queue_free()


func _on_shield_damaged(remaining: int) -> void:
	"""Shield took damage - could play animation."""
	if shield_visual:
		shield_visual.visible = true
		shield_visual.modulate = Color(0.6, 0.9, 1.0, 0.5)
	if sprite:
		sprite.modulate = Color.WHITE.lerp(Color.RED, 0.3)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = Color.WHITE


func _on_shield_broken() -> void:
	"""Shield broke - visual feedback."""
	if shield_visual:
		shield_visual.visible = false
	if sprite:
		sprite.modulate = Color.ORANGE
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = Color.WHITE
	attack_pattern = "burst"
	shoot_cooldown = 0.28
	current_state = State.ATTACKING


func _on_shield_restored() -> void:
	"""Shield regenerated."""
	if shield_visual:
		shield_visual.visible = true
		shield_visual.modulate = Color(0.45, 0.9, 1.0, 0.28)
	if sprite:
		sprite.modulate = Color.CYAN
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = Color.WHITE
	attack_pattern = "cycle"
	shoot_cooldown = default_shoot_cooldown


func _get_muzzle_position() -> Vector2:
	if sprite:
		var offset_x := 42.0 if not sprite.flip_h else -42.0
		return global_position + Vector2(offset_x, -6.0)
	return global_position
