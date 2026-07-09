extends Marker2D

@export var spawn_id: String = "spawn_start"

func _ready() -> void:
	add_to_group("room_spawn")
