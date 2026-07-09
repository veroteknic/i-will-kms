extends Node

# Headless test to instantiate res://main.tscn and report spawn availability.
# Run with: godot -s tools/test_load_main.gd

func _ready():
	print("Starting headless main.tscn load test...")
	var scene = load("res://main.tscn")
	if scene == null:
		print("ERROR: Could not load res://main.tscn")
		get_tree().quit()
		return

	var inst = scene.instantiate()
	if inst == null:
		print("ERROR: instantiate() returned null")
		get_tree().quit()
		return

	print("Instantiated scene root type:", inst.get_class())

	# Try to find a world manager by group
	var world = inst.get_tree().get_first_node_in_group("world_manager")
	if world:
		print("Found world_manager in instance:", world)
		# Report current_room_id if available
		if world.has_method("get_current_room_id"):
			print("world current_room_id:", world.get_current_room_id())
	else:
		print("No world_manager found inside instantiated scene (this may be expected if main.tscn assumes autoloads).")

	# Search for any room_spawn nodes under the instantiated scene
	var spawn_found := false
	for node in inst.get_children():
		if node.is_in_group("room_spawn"):
			print("Found spawn on child:", node, "pos:", node.global_position)
			spawn_found = true

	if not spawn_found:
		print("No room_spawn nodes found directly under scene root; searching recursively...")
		var sp := _find_spawn_recursive(inst)
		if sp:
			print("Found recursive spawn:", sp, "pos:", sp.global_position)
		else:
			print("No spawn nodes found in scene.")

	print("Headless test complete.")
	get_tree().quit()

func _find_spawn_recursive(node: Node) -> Node:
	if node.is_in_group("room_spawn") and node is Node2D:
		return node
	for c in node.get_children():
		var res := _find_spawn_recursive(c)
		if res:
			return res
	return null
