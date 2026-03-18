extends Node2D
const BOOLET = preload("res://boolet.tscn")
const GRENADE = preload("res://grenade.tscn")
const LOOK_DEAD_ZONE = 30.0  # Minimum distance to look at target
const GRENADE_THROW_FORCE = 600.0
const GRENADE_COOLDOWN = 1.5
const GRENADE_VELOCITY_INHERIT = 0.6
const AIM_FLIP_DEADZONE = 8.0
const ARM_POS_RIGHT = Vector2(37.7953, -114.961)
const ARM_POS_LEFT = Vector2(-47.63, -114.961)
@onready var muzzle: Marker2D = $Marker2D
@onready var timer: Timer = $Timer
@onready var gun_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")
var flipped = false
var facing_left = false
var grenade_cooldown_timer = 0.0

func _ready() -> void:
	if gun_sprite:
		gun_sprite.play("idle")
		gun_sprite.animation_finished.connect(_on_animation_finished)

func _process(_delta: float) -> void:
	# Update grenade cooldown
	grenade_cooldown_timer = max(0.0, grenade_cooldown_timer - _delta)
	
	var mouse = get_global_mouse_position()
	var distance_to_mouse = global_position.distance_to(mouse)
	
	if distance_to_mouse > LOOK_DEAD_ZONE:
		look_at(mouse)

	# Normalize angle to 0-360
	if rotation_degrees > 360:
		rotation_degrees -= 360
	if rotation_degrees < 0:
		rotation_degrees += 360
	var deg = rotation_degrees
	

	var x_delta: float = mouse.x - global_position.x
	var should_flip = facing_left
	if x_delta > AIM_FLIP_DEADZONE:
		should_flip = false
	elif x_delta < -AIM_FLIP_DEADZONE:
		should_flip = true
	facing_left = should_flip

	if should_flip != flipped:
		flipped = should_flip

	# Apply flip to player sprite and arm position only; let gun rotation handle pointing
	if player_sprite:
		player_sprite.flip_h = flipped
	
	if flipped:
		position = ARM_POS_LEFT
	else:
		position = ARM_POS_RIGHT
	
	if Input.is_action_just_pressed("pewpew"):
		$AudioStreamPlayer2D.play()
		if get_parent() and get_parent().has_method("add_screenshake"):
			get_parent().add_screenshake(get_parent().screenshake_shoot_amount)
		if gun_sprite:
			gun_sprite.play("shoot")
		var bullet_instance = BOOLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation
	
	if Input.is_action_just_pressed("grenade") and grenade_cooldown_timer <= 0.0:
		var grenade_instance = GRENADE.instantiate()
		get_tree().root.add_child(grenade_instance)
		grenade_instance.global_position = muzzle.global_position
		var throw_direction = Vector2(cos(rotation), sin(rotation))
		var inherited_velocity := Vector2.ZERO
		var player_body := get_parent() as CharacterBody2D
		if player_body:
			inherited_velocity = player_body.velocity * GRENADE_VELOCITY_INHERIT
		grenade_instance.linear_velocity = throw_direction * GRENADE_THROW_FORCE + inherited_velocity
		grenade_cooldown_timer = GRENADE_COOLDOWN


func _on_animation_finished() -> void:
	if gun_sprite and gun_sprite.animation == "shoot":
		gun_sprite.play("idle")
