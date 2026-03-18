extends CharacterBody2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_ui = $HealthUI
@onready var respawn_label: Label = get_node_or_null("RespawnUI/RespawnLabel") as Label
@onready var debug_label: Label = get_node_or_null("DebugUI/DebugLabel") as Label
@onready var player_hurt_box: HurtBox = $HurtBox
@onready var slam_hit_box: Area2D = get_node_or_null("SlamHitBox") as Area2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var killcam_sfx: AudioStreamPlayer2D = get_node_or_null("hampter") as AudioStreamPlayer2D
@onready var hurt_sfx: AudioStreamPlayer2D = get_node_or_null("hurt") as AudioStreamPlayer2D
@onready var hurt_screen: CanvasLayer = get_node_or_null("HurtScreen") as CanvasLayer
@onready var wall_cling_sfx: AudioStreamPlayer2D = get_node_or_null("falling") as AudioStreamPlayer2D
@onready var fall_whoosh_player: AudioStreamPlayer2D = get_node_or_null("FallWhoosh") as AudioStreamPlayer2D
@onready var landing_sfx_player: AudioStreamPlayer2D = get_node_or_null("LandingSfx") as AudioStreamPlayer2D
@onready var landing_heavy_sfx_player: AudioStreamPlayer2D = get_node_or_null("LandingHeavySfx") as AudioStreamPlayer2D

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

@export_group("Death Killcam")
@export var death_killcam_enabled: bool = true
@export_range(1.0, 4.0, 0.01) var death_killcam_zoom_mult: float = 1.8
@export_range(0.0, 5.0, 0.01, "suffix:s") var death_killcam_in_time: float = 1.2
@export_range(0.0, 5.0, 0.01, "suffix:s") var death_killcam_delay_after_sound: float = 0.0
@export var death_killcam_wait_for_sfx_finish: bool = true
@export var death_killcam_pause_time: bool = true
@export_range(0.0, 2.0, 0.01) var death_killcam_offset_strength: float = 0.5
@export_range(0, 10000, 10, "suffix:ms") var death_killcam_memory_ms: int = 3000

@export_group("Respawn")
@export_range(1, 10, 1, "suffix:s") var respawn_countdown_seconds: int = 3

@export_group("Debug HUD")
@export var debug_text_enabled: bool = true

@export_group("Fall Whoosh")
@export var fall_whoosh_enabled: bool = true
@export var fall_whoosh_stream: AudioStream
@export_range(100.0, 5000.0, 10.0, "suffix:px/s") var fall_whoosh_start_speed: float = 900.0
@export_range(200.0, 8000.0, 10.0, "suffix:px/s") var fall_whoosh_max_speed: float = 3000.0
@export_range(-60.0, 6.0, 0.1, "suffix:dB") var fall_whoosh_min_db: float = -20.0
@export_range(-40.0, 6.0, 0.1, "suffix:dB") var fall_whoosh_max_db: float = 0.0

@export_group("Landing Sounds")
@export var landing_light_stream: AudioStream
@export var landing_heavy_stream: AudioStream
@export_range(100.0, 5000.0, 10.0, "suffix:px/s") var landing_min_speed: float = 700.0
@export_range(100.0, 8000.0, 10.0, "suffix:px/s") var landing_heavy_speed: float = 1600.0
@export_range(10.0, 5000.0, 10.0, "suffix:px") var landing_heavy_min_height: float = 350.0

@export_group("Blood")
@export var blood_enabled: bool = true
@export_range(4, 120, 1) var player_hurt_blood_amount: int = 28

@export_group("Screen Shake")
@export var screenshake_enabled: bool = true
@export_range(0.0, 720.0, 0.5, "suffix:px") var screenshake_max_offset: float = 108.0
@export_range(0.0, 30.0, 0.1) var screenshake_decay: float = 8.0
@export_range(0.0, 1.0, 0.01) var screenshake_jump_amount: float = 0.18
@export_range(0.0, 1.0, 0.01) var screenshake_wall_jump_amount: float = 0.32
@export_range(0.0, 1.0, 0.01) var screenshake_dash_amount: float = 0.48
@export_range(0.0, 1.0, 0.01) var screenshake_slide_amount: float = 0.28
@export_range(0.0, 1.0, 0.01) var screenshake_wall_cling_amount: float = 0.16
@export_range(0.0, 1.0, 0.01) var screenshake_land_amount: float = 0.34
@export_range(0.0, 1.0, 0.01) var screenshake_shoot_amount: float = 0.84
@export_range(0.0, 1.0, 0.01) var screenshake_hurt_amount: float = 1.0
@export_range(0.0, 1.0, 0.01) var screenshake_slam_amount: float = 1.0
@export_range(0.0, 1.0, 0.01) var screenshake_death_amount: float = 1.0
@export_range(0.0, 1.0, 0.01) var screenshake_enemy_hit_amount: float = 0.2
@export_range(0.0, 1.0, 0.01) var screenshake_enemy_death_amount: float = 0.42
@export_range(0.0, 1.0, 0.01) var screenshake_grenade_amount: float = 1.0
@export_range(50.0, 5000.0, 10.0, "suffix:px") var screenshake_enemy_event_radius: float = 1200.0
@export_range(50.0, 5000.0, 10.0, "suffix:px") var screenshake_grenade_radius: float = 1600.0

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
const SLAM_DAMAGE = 2
const SLAM_INVINCIBILITY = 0.3
var is_slamming = false
var was_on_floor = false

# slide
const SLIDE_SPEED = 1600.0
const SLIDE_DECAY = 0.80
const SLIDE_MIN_SPEED = 150.0
var sliding = false

# dash - ULTRAKILL style
const DASH_SPEED = 2000
const DASH_DURATION = 0.2  # 0.2s like ULTRAKILL
const STAMINA_MAX = 3
const STAMINA_REGEN_RATE = 1.5  # Bars per second (rapid regen)
var stamina: float = 3.0
var dashing = false
var dash_direction = Vector2.ZERO
var run_available = true
@onready var arm: Node2D = $Node2D
@onready var dash: AudioStreamPlayer2D = $dash
@onready var health_component: Health = $Health
var jump_count = 0
const MAX_WALL_JUMPS = 3
var wall_jump_count = 0
var is_dead = false
var last_damage_source_position: Vector2 = Vector2.ZERO
var last_damage_time_ms: int = -1
var fall_start_y: float = 0.0
var peak_fall_speed: float = 0.0
var _killcam_saved_time_scale: float = 1.0
var _camera_base_offset: Vector2 = Vector2.ZERO
var _screenshake_strength: float = 0.0
var _screenshake_rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Save each frame as PNG
	if not killcam_sfx:
		killcam_sfx = get_node_or_null("AudioStreamPlayer2D2") as AudioStreamPlayer2D
	_screenshake_rng.randomize()
	if camera_2d and is_instance_valid(camera_2d):
		_camera_base_offset = camera_2d.offset
	_set_slam_hitbox_active(false)
	if not fall_whoosh_player:
		fall_whoosh_player = AudioStreamPlayer2D.new()
		fall_whoosh_player.name = "FallWhoosh"
		if fall_whoosh_stream:
			fall_whoosh_player.stream = fall_whoosh_stream
		add_child(fall_whoosh_player)
	if fall_whoosh_player and is_instance_valid(fall_whoosh_player):
		if fall_whoosh_stream:
			fall_whoosh_player.stream = fall_whoosh_stream
		fall_whoosh_player.max_distance = 100000.0
		fall_whoosh_player.attenuation = 1.0
		fall_whoosh_player.volume_db = fall_whoosh_min_db
		fall_whoosh_player.autoplay = false
	if not landing_sfx_player:
		landing_sfx_player = AudioStreamPlayer2D.new()
		landing_sfx_player.name = "LandingSfx"
		add_child(landing_sfx_player)
	if landing_sfx_player and is_instance_valid(landing_sfx_player):
		if landing_light_stream:
			landing_sfx_player.stream = landing_light_stream
		landing_sfx_player.max_distance = 100000.0
		landing_sfx_player.attenuation = 1.0
	if not landing_heavy_sfx_player:
		landing_heavy_sfx_player = AudioStreamPlayer2D.new()
		landing_heavy_sfx_player.name = "LandingHeavySfx"
		add_child(landing_heavy_sfx_player)
	if landing_heavy_sfx_player and is_instance_valid(landing_heavy_sfx_player):
		if landing_heavy_stream:
			landing_heavy_sfx_player.stream = landing_heavy_stream
		landing_heavy_sfx_player.max_distance = 100000.0
		landing_heavy_sfx_player.attenuation = 1.0
	if respawn_label and is_instance_valid(respawn_label):
		respawn_label.visible = false
	if health_component:
		health_component.health_depleted.connect(_on_health_depleted)
		health_component.health_changed.connect(_on_health_changed)
		
		# Initial heart state
		update_hearts()
	if player_hurt_box:
		player_hurt_box.received_hit.connect(_on_hurt_box_received_hit)
	if killcam_sfx and is_instance_valid(killcam_sfx):
		killcam_sfx.max_distance = 100000.0
		killcam_sfx.attenuation = 1.0


func _process(delta: float) -> void:
	_update_screenshake(delta)
	_update_debug_text()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Track previous floor state for slam detection
	was_on_floor = is_on_floor()
	
	ambient_timer -= delta

	if ambient_timer <= 0:
		$AmbientPlayer.stream = AMBIENT_SOUNDS.pick_random()
		$AmbientPlayer.play()
		ambient_timer = randf_range(MIN_DELAY, MAX_DELAY)

	var input_x = Input.get_axis("left", "right")
	
	# Regenerate stamina when not dashing
	if not dashing and stamina < STAMINA_MAX:
		stamina = min(stamina + STAMINA_REGEN_RATE * delta, STAMINA_MAX)
	
	# Reset wall-jump counter when touching the ground
	if is_on_floor():
		wall_jump_count = 0
	was_wall_clinging = wall_clinging

	if dashing:
		if arm:
			arm.visible = false
			arm.set_process(false)
	else:
		if arm:
			arm.visible = true
			arm.set_process(true)
	
	# Dash input - ULTRAKILL style (horizontal only)
	if Input.is_action_just_pressed("dash") and stamina >= 1.0:
		# Get dash direction from horizontal input only
		var dash_dir = Vector2(input_x, 0)
		if abs(input_x) > 0:
			dash_dir = dash_dir.normalized()
		else:
			# Default to forward if no input
			dash_dir = Vector2(1 if not sprite.flip_h else -1, 0)
		
		dash.play()
		start_dash(dash_dir)
		stamina -= 1.0
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
			is_slamming = false  # Cancel slam when jumping
			_set_slam_hitbox_active(false)
			if is_on_floor():
				velocity.y = JUMP_FORCE
				jump_held = true
				add_screenshake(screenshake_jump_amount)
				$Jump.play()
			elif wall_clinging:
				# Wall jump (limited)
				if wall_jump_count < MAX_WALL_JUMPS:
					velocity.y = JUMP_FORCE
					velocity.x = -wall_dir * movement_speed
					wall_clinging = false
					wall_jump_count += 1
					add_screenshake(screenshake_wall_jump_amount)
					$Jump.play()

		# Stop holding jump early
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y = max(velocity.y, MIN_JUMP_FORCE)
			jump_held = false

		# Slam - works any time in air
		if Input.is_action_just_pressed("slam") and not is_on_floor():
			velocity.y = SLAM_SPEED
			is_slamming = true
			if health_component:
				health_component.set_temporary_immortality(SLAM_INVINCIBILITY)

		# Slide
		if Input.is_action_just_pressed("slam") and is_on_floor():
			is_slamming = false  # Ensure slam is off when sliding
			_set_slam_hitbox_active(false)
			sliding = true
			velocity.x = input_x * SLIDE_SPEED
			add_screenshake(screenshake_slide_amount)

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
	wall_clinging = false
	if not is_on_floor():
		for i in range(get_slide_collision_count()):
			var col: KinematicCollision2D = get_slide_collision(i)
			if col and abs(col.get_normal().x) > 0.9:  # left/right wall
				wall_clinging = true
				wall_dir = col.get_normal().x
				if not was_wall_clinging:
					add_screenshake(screenshake_wall_cling_amount)
					$Jump.play()
				velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
				# Cancel slam if wall clinging
				is_slamming = false
				_set_slam_hitbox_active(false)
				break

	if wall_cling_sfx and is_instance_valid(wall_cling_sfx):
		if wall_clinging and not was_wall_clinging and not wall_cling_sfx.playing:
			wall_cling_sfx.play()
		elif not wall_clinging and was_wall_clinging and wall_cling_sfx.playing:
			wall_cling_sfx.stop()
	# Move character
	move_and_slide()
	var slam_landed_this_frame := is_slamming and (not was_on_floor) and is_on_floor()

	if not is_on_floor():
		if was_on_floor:
			fall_start_y = global_position.y
			peak_fall_speed = maxf(velocity.y, 0.0)
		else:
			peak_fall_speed = maxf(peak_fall_speed, velocity.y)
	elif not was_on_floor:
		var fall_distance := maxf(global_position.y - fall_start_y, 0.0)
		if slam_landed_this_frame:
			_play_heavy_landing_sound()
		else:
			_play_landing_sound(peak_fall_speed, fall_distance)
	
	# Sync slam hitbox with slamming state
	_set_slam_hitbox_active(is_slamming)
	
	# Cancel slam if moving upward
	if is_slamming and velocity.y < 0:
		is_slamming = false
		_set_slam_hitbox_active(false)
	
	# Check for slam impact
	if slam_landed_this_frame:
		# Slam landed
		is_slamming = false
		_set_slam_hitbox_active(false)
		add_screenshake(screenshake_slam_amount)

	_update_fall_whoosh()

	# Wall cling detection after movement


	update_animation()


func update_animation() -> void:
	resolve_anim_state()
	apply_anim_state()


func _update_debug_text() -> void:
	if not debug_label or not is_instance_valid(debug_label):
		return
	debug_label.visible = debug_text_enabled
	if not debug_text_enabled:
		return
	var health_text := "-"
	if health_component and is_instance_valid(health_component):
		health_text = "%d/%d" % [health_component.health, health_component.max_health]
	debug_label.text = "FPS: %d\nPos: %.0f, %.0f\nVel: %.0f, %.0f\nState: %s\nGrounded: %s\nHealth: %s\nStamina: %.2f\nShake: %.2f" % [
		Engine.get_frames_per_second(),
		global_position.x,
		global_position.y,
		velocity.x,
		velocity.y,
		AnimState.keys()[anim_state],
		str(is_on_floor()),
		health_text,
		stamina,
		_screenshake_strength
	]

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

func play_anim(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func start_dash(direction: Vector2) -> void:
	dashing = true
	dash_direction = direction
	is_slamming = false  # Cancel slam when dashing
	_set_slam_hitbox_active(false)
	add_screenshake(screenshake_dash_amount)
	
	# Reset velocity and apply dash momentum
	velocity = direction * DASH_SPEED
	
	# Enable invincibility and ignore enemy collisions
	if health_component:
		health_component.set_temporary_immortality(DASH_DURATION)
	collision_layer = 0  # Temporarily disable collision layer
	
	await get_tree().create_timer(DASH_DURATION).timeout
	
	dashing = false
	collision_layer = 2  # Restore collision layer

func _on_dash_reset_timeout() -> void:
	pass  # No longer needed with stamina regen
func play_footstep():
	if not is_on_floor():
		return
	$FootstepPlayer.play()







func _on_health_depleted() -> void:
	is_dead = true
	add_screenshake(screenshake_death_amount)
	velocity = Vector2.ZERO
	$AnimatedSprite2D.hide()
	$Node2D.hide()
	$Node2D.set_process(false)
	$CPUParticles2D.emitting = true
	$death.play()
	await $death.finished
	if death_killcam_delay_after_sound > 0.0:
		await get_tree().create_timer(death_killcam_delay_after_sound).timeout
	await _start_death_killcam()
	if death_killcam_wait_for_sfx_finish and killcam_sfx and is_instance_valid(killcam_sfx) and killcam_sfx.playing:
		await killcam_sfx.finished
	await _show_respawn_countdown_and_reload()

func _on_health_changed(diff: int) -> void:
	if diff < 0 and hurt_sfx and is_instance_valid(hurt_sfx):
		hurt_sfx.stop()
		hurt_sfx.play()
	if diff < 0:
		add_screenshake(screenshake_hurt_amount)
	if diff < 0 and hurt_screen and hurt_screen.has_method("flash"):
		hurt_screen.flash()
	if diff < 0 and blood_enabled:
		_spawn_player_hurt_blood()
	update_hearts()

func update_hearts() -> void:
	if health_component and health_ui:
		health_ui.update_hearts(health_component.health)


func _on_hurt_box_received_hit(source: Area2D) -> void:
	if source and is_instance_valid(source):
		last_damage_source_position = source.global_position
		last_damage_time_ms = Time.get_ticks_msec()


func _start_death_killcam() -> void:
	var paused_time := false
	if death_killcam_pause_time:
		_set_killcam_time_paused(true)
		paused_time = true

	if killcam_sfx and is_instance_valid(killcam_sfx):
		killcam_sfx.global_position = global_position
		killcam_sfx.stop()
		killcam_sfx.play()
	if not death_killcam_enabled:
		if paused_time:
			_set_killcam_time_paused(false)
		return
	if not camera_2d or not is_instance_valid(camera_2d):
		if paused_time:
			_set_killcam_time_paused(false)
		return

	var now_ms := Time.get_ticks_msec()
	var use_last_source := last_damage_time_ms >= 0 and (now_ms - last_damage_time_ms) <= death_killcam_memory_ms
	var focus_position := last_damage_source_position if use_last_source else global_position

	var original_zoom := camera_2d.zoom
	var original_offset := _camera_base_offset
	var zoom_mult := clampf(death_killcam_zoom_mult, 1.0, 10.0)
	var target_zoom := original_zoom * zoom_mult
	var to_focus := focus_position - global_position
	var target_offset := original_offset + (to_focus * death_killcam_offset_strength)

	var duration_ms := int(maxf(death_killcam_in_time, 0.001) * 1000.0)
	var start_ms := Time.get_ticks_msec()
	while true:
		var elapsed_ms := Time.get_ticks_msec() - start_ms
		var t := clampf(float(elapsed_ms) / float(duration_ms), 0.0, 1.0)
		if camera_2d and is_instance_valid(camera_2d):
			camera_2d.zoom = original_zoom.lerp(target_zoom, t)
			_camera_base_offset = original_offset.lerp(target_offset, t)
			_apply_camera_offset()
		if t >= 1.0:
			break
		await get_tree().process_frame

	if paused_time:
		_set_killcam_time_paused(false)


func _set_killcam_time_paused(paused: bool) -> void:
	if paused:
		_killcam_saved_time_scale = Engine.time_scale
		Engine.time_scale = 0.0
	else:
		Engine.time_scale = _killcam_saved_time_scale


func add_screenshake(amount: float) -> void:
	if not screenshake_enabled or not camera_2d or not is_instance_valid(camera_2d):
		return
	_screenshake_strength = maxf(_screenshake_strength, clampf(amount, 0.0, 1.0))
	_apply_camera_offset()


func add_screenshake_at_position(amount: float, world_position: Vector2, max_distance: float) -> void:
	if not screenshake_enabled or max_distance <= 0.0:
		return
	var distance_to_event := global_position.distance_to(world_position)
	if distance_to_event >= max_distance:
		return
	var t := 1.0 - (distance_to_event / max_distance)
	add_screenshake(amount * t * t)


func _update_screenshake(delta: float) -> void:
	if not camera_2d or not is_instance_valid(camera_2d):
		return
	_screenshake_strength = move_toward(_screenshake_strength, 0.0, screenshake_decay * delta)
	_apply_camera_offset()


func _apply_camera_offset() -> void:
	if not camera_2d or not is_instance_valid(camera_2d):
		return
	var shake_offset := Vector2.ZERO
	if screenshake_enabled and _screenshake_strength > 0.001:
		shake_offset = Vector2(
			_screenshake_rng.randf_range(-1.0, 1.0),
			_screenshake_rng.randf_range(-1.0, 1.0)
		) * screenshake_max_offset * _screenshake_strength
	camera_2d.offset = _camera_base_offset + shake_offset


func _set_slam_hitbox_active(active: bool) -> void:
	if not slam_hit_box or not is_instance_valid(slam_hit_box):
		return
	slam_hit_box.monitoring = active
	slam_hit_box.monitorable = active
	for child in slam_hit_box.get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = not active


func _play_landing_sound(fall_speed: float, fall_distance: float) -> void:
	if fall_speed < landing_min_speed:
		return
	var use_heavy := fall_speed >= landing_heavy_speed and fall_distance >= landing_heavy_min_height
	if use_heavy:
		_play_heavy_landing_sound()
		return
	add_screenshake(screenshake_land_amount)
	if landing_sfx_player and is_instance_valid(landing_sfx_player) and landing_sfx_player.stream:
		landing_sfx_player.stop()
		landing_sfx_player.play()


func _play_heavy_landing_sound() -> void:
	add_screenshake(screenshake_slam_amount)
	if landing_heavy_sfx_player and is_instance_valid(landing_heavy_sfx_player) and landing_heavy_sfx_player.stream:
		landing_heavy_sfx_player.stop()
		landing_heavy_sfx_player.play()


func _spawn_player_hurt_blood() -> void:
	var from_position := last_damage_source_position
	if last_damage_time_ms < 0:
		from_position = global_position - Vector2(1, 0)
	var spray_direction := (global_position - from_position).normalized()
	if spray_direction.length_squared() <= 0.0001:
		spray_direction = Vector2(1, 0)

	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.amount = player_hurt_blood_amount
	particles.lifetime = 0.8
	particles.explosiveness = 1.0
	particles.randomness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 7.5
	particles.spread = 40.0
	particles.direction = spray_direction
	particles.gravity = Vector2(0, 950)
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 320.0
	particles.damping_min = 8.0
	particles.damping_max = 28.0
	particles.scale_amount_min = 3.9
	particles.scale_amount_max = 9.3
	particles.color = Color(0.78, 0.03, 0.03, 1.0)
	particles.top_level = true
	particles.global_position = global_position
	var target_parent := get_tree().current_scene if get_tree().current_scene else get_tree().root
	target_parent.add_child(particles)
	particles.finished.connect(func() -> void:
		if particles and is_instance_valid(particles):
			particles.queue_free()
	)
	particles.emitting = true


func _update_fall_whoosh() -> void:
	if not fall_whoosh_player or not is_instance_valid(fall_whoosh_player):
		return
	if not fall_whoosh_player.stream:
		if fall_whoosh_player.playing:
			fall_whoosh_player.stop()
		return
	if not fall_whoosh_enabled:
		if fall_whoosh_player.playing:
			fall_whoosh_player.stop()
		return

	var down_speed: float = maxf(velocity.y, 0.0)
	var is_fast_falling := (not is_on_floor()) and (not wall_clinging) and down_speed >= fall_whoosh_start_speed
	if not is_fast_falling:
		if fall_whoosh_player.playing:
			fall_whoosh_player.stop()
		return

	var speed_t: float = inverse_lerp(fall_whoosh_start_speed, fall_whoosh_max_speed, down_speed)
	speed_t = clampf(speed_t, 0.0, 1.0)
	fall_whoosh_player.volume_db = lerpf(fall_whoosh_min_db, fall_whoosh_max_db, speed_t)
	if not fall_whoosh_player.playing:
		fall_whoosh_player.play()


func _show_respawn_countdown_and_reload() -> void:
	var seconds_left: int = maxi(respawn_countdown_seconds, 1)
	while seconds_left > 0:
		if respawn_label and is_instance_valid(respawn_label):
			respawn_label.text = "Respawn in %d" % seconds_left
			respawn_label.visible = true
		await get_tree().create_timer(1.0).timeout
		seconds_left -= 1
	if respawn_label and is_instance_valid(respawn_label):
		respawn_label.text = "Respawning..."
		respawn_label.visible = true
	get_tree().reload_current_scene()
