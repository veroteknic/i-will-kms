extends Area2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft

@export var health: int = 3  # Example health value for the enemy

const SPEED = 100



# Call this when the enemy is hit by the sword
func kill():
	queue_free()  # Remove the enemy from the scene
