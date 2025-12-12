extends CharacterBody2D
@onready var ray_cast_right: RayCast2D = $right
@onready var ray_cast_left: RayCast2D = $left
@onready var right_wall: RayCast2D = $"right wall"
@onready var left_wall: RayCast2D = $"left wall"

var direction = 1
const SPEED = 300
func _physics_process(delta: float) -> void:
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
	position.x += direction * SPEED * delta
