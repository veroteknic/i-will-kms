extends Area2D

@export var target_room: PackedScene
@export var target_room_id: String = ""
@export var target_spawn_id: String = ""
@export var one_shot: bool = false

var _used := false

func _get_world() -> Node:
	return get_tree().get_first_node_in_group("world_manager")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _used and one_shot:
		return
	if not body.is_in_group("player"):
		return
	if target_room == null:
		return

	var world = _get_world()
	if world == null:
		push_warning("No world_manager found (room trigger cannot load room)")
		return

	_used = true
	world.load_room(target_room, target_room_id, target_spawn_id)
