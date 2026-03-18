extends AnimatableBody2D

@export_range(1.0, 1200.0, 1.0, "suffix:px/s") var move_speed: float = 140.0
@export_range(0.0, 5.0, 0.01, "suffix:s") var endpoint_pause_time: float = 0.1
@export var start_moving_right: bool = true

@onready var _ray_left: RayCast2D = $RayCastLeft
@onready var _ray_right: RayCast2D = $RayCastRight

var _direction: float = 1.0
var _pause_timer: float = 0.0

func _ready() -> void:
	_direction = 1.0 if start_moving_right else -1.0
	_ray_left.enabled = true
	_ray_right.enabled = true


func _physics_process(delta: float) -> void:
	if _pause_timer > 0.0:
		_pause_timer = maxf(_pause_timer - delta, 0.0)
		return

	var active_ray := _ray_right if _direction > 0.0 else _ray_left
	active_ray.force_raycast_update()
	if active_ray.is_colliding():
		_direction *= -1.0
		_pause_timer = endpoint_pause_time
		return

	global_position.x += _direction * move_speed * delta
