extends Node2D
const BOOLET = preload("res://boolet.tscn")
const GRENADE = preload("res://grenade.tscn")
const LOOK_DEAD_ZONE = 30.0  # Minimum distance to look at target
const GRENADE_THROW_FORCE = 600.0
const GRENADE_COOLDOWN = 1.5
@onready var muzzle: Marker2D = $Marker2D
@onready var timer: Timer = $Timer

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
var flipped = false
var grenade_cooldown_timer = 0.0

func _ready() -> void:
	$"Sprite-0001".hide()

func _process(_delta: float) -> void:
	# Update grenade cooldown
	grenade_cooldown_timer = max(0.0, grenade_cooldown_timer - _delta)
	
	var mouse = get_global_mouse_position()
	var distance_to_mouse = global_position.distance_to(mouse)
	
	# Only look at mouse if it's far enough away to avoid spazzing
	if distance_to_mouse > LOOK_DEAD_ZONE:
		look_at(mouse)

	# Normalize angle to 0-360
	rotation_degrees = fposmod(rotation_degrees, 360)
	var deg = rotation_degrees
	
	# Determine flipped state: flip when pointing left (120-240 degrees)
	# This avoids the 90/270 degree zones to prevent spazzing
	var should_flip = (deg > 120 and deg < 239)
	
	if should_flip != flipped:
		flipped = should_flip

	# Apply scale and animation based on flipped
	if flipped:
		$"../AnimatedSprite2D".flip_h = true
		scale.y = -7
		animation_player.play("gun left")
	else:
		$"../AnimatedSprite2D".flip_h = false
		scale.y = 7
		animation_player.play("gun right")
	
	if Input.is_action_just_pressed("pewpew"):
		$AudioStreamPlayer2D.play()
		$"Sprite-0001".show()
		$Timer.start()
		var bullet_instance = BOOLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation
	
	if Input.is_action_just_pressed("grenade") and grenade_cooldown_timer <= 0.0:
		var grenade_instance = GRENADE.instantiate()
		get_tree().root.add_child(grenade_instance)
		grenade_instance.global_position = muzzle.global_position
		var throw_direction = Vector2(cos(rotation), sin(rotation))
		grenade_instance.linear_velocity = throw_direction * GRENADE_THROW_FORCE
		grenade_cooldown_timer = GRENADE_COOLDOWN


func _on_timer_timeout() -> void:
	$"Sprite-0001".hide()
