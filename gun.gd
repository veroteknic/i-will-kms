extends Node2D
const BOOLET = preload("res://boolet.tscn")
@onready var muzzle: Marker2D = $Marker2D
@onready var timer: Timer = $Timer

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
var flipped = false
func _ready() -> void:
	$"Sprite-0001".hide()
func _process(delta: float) -> void:
	var mouse = get_global_mouse_position()
	look_at(mouse)

	# normalize angle to 0–360 always
	rotation_degrees = fposmod(rotation_degrees, 360)
	var deg = rotation_degrees

	# Determine flipped state with hysteresis to avoid flickering
	if not flipped and deg > 100 and deg < 260:
		flipped = true
	elif flipped and (deg < 80 or deg > 280):
		flipped = false

	# Apply scale and animation based on flipped
	if flipped:
		scale.y = -7
		animation_player.play("gun left")
	else:
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


func _on_timer_timeout() -> void:
	$"Sprite-0001".hide()
