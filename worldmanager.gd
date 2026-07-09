extends Node2D

signal room_changed(room_id: String)

@export var start_room: PackedScene
@export var start_room_id: String = "room_start"
@export var start_spawn_id: String = "spawn_start"
@export var room_container_path: NodePath
@export var player_path: NodePath

var current_room: Node = null
var current_room_id: String = ""
var visited_rooms: Dictionary = {}

@onready var room_container: Node = get_node(room_container_path)
@onready var player: Node2D = get_node(player_path)

func _ready() -> void:
	add_to_group("world_manager")
	if start_room != null:
		load_room(start_room, start_room_id, start_spawn_id)

func load_room(room_scene: PackedScene, room_id: String, spawn_id: String = "") -> void:
	if room_scene == null:
		push_warning("load_room called with null room_scene")
		return

	if current_room and is_instance_valid(current_room):
		current_room.queue_free()
		await get_tree().process_frame

	current_room = room_scene.instantiate()
	room_container.add_child(current_room)

	current_room_id = room_id
	visited_rooms[room_id] = true
	emit_signal("room_changed", room_id)

	if spawn_id != "":
		_place_player_at_spawn(spawn_id)
	else:
		_place_player_at_first_available()

func is_room_visited(room_id: String) -> bool:
	return visited_rooms.has(room_id)

func _place_player_at_spawn(spawn_id: String) -> void:
	if player == null or current_room == null:
		return

	var spawns := current_room.get_tree().get_nodes_in_group("room_spawn")
	for spawn in spawns:
		if spawn is Node2D and String(spawn.get("spawn_id")) == spawn_id:
			player.global_position = (spawn as Node2D).global_position
			return

	push_warning("Spawn id not found: " + spawn_id)

func _place_player_at_first_available() -> void:
	if player == null or current_room == null:
		return

	var first_spawn := _find_first_spawn_in_node(current_room)
	if first_spawn != null:
		player.global_position = first_spawn.global_position
		return

	push_warning("No spawn nodes found in room; player not moved")

func _find_first_spawn_in_node(root: Node) -> Node:
	if root.is_in_group("room_spawn") and root is Node2D:
		return root
	for child in root.get_children():
		var res := _find_first_spawn_in_node(child)
		if res != null:
			return res
	return null
