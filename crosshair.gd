extends CharacterBody2D

@export_range(1.0, 40.0, 0.1) var follow_lerp_speed: float = 16.0
@export_flags_2d_physics var avoid_collision_mask: int = 2
@export_range(0.0, 64.0, 0.1) var outline_padding: float = 2.0
@export_range(0.0, 1.0, 0.01) var avoidance_strength: float = 0.45
@export_range(0.0, 2000.0, 1.0, "suffix:px/s") var max_avoid_push_speed: float = 520.0
@export_range(0.0, 1.0, 0.01) var shot_alignment_strength: float = 1.0
@export_flags_2d_physics var hit_preview_mask: int = 2
@export var hit_preview_enabled: bool = true
@export_range(100.0, 20000.0, 10.0, "suffix:px") var hit_preview_distance: float = 8000.0
@export var visual_crosshair_offset: Vector2 = Vector2(0.0, -13.0)

@onready var crosshair_shape_node: CollisionShape2D = $CollisionShape2D
@onready var crosshair_sprite: Sprite2D = $Sprite2D

var _crosshair_radius: float = 8.0

const COLOR_HIT: Color = Color(1.0, 0.35, 0.35, 1.0)
const COLOR_CLEAR: Color = Color(1.0, 1.0, 1.0, 1.0)


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Ensure this cursor never participates in gameplay collision/pathing.
	collision_layer = 0
	collision_mask = 0
	if crosshair_shape_node:
		crosshair_shape_node.disabled = true

	if crosshair_shape_node and crosshair_shape_node.shape is CircleShape2D:
		_crosshair_radius = (crosshair_shape_node.shape as CircleShape2D).radius
	if crosshair_sprite:
		crosshair_sprite.offset = visual_crosshair_offset


func _physics_process(delta: float) -> void:
	if crosshair_sprite and crosshair_sprite.offset != visual_crosshair_offset:
		crosshair_sprite.offset = visual_crosshair_offset

	var mouse_pos: Vector2 = get_global_mouse_position()
	var t: float = 1.0 - exp(-follow_lerp_speed * delta)
	var desired_pos: Vector2 = global_position.lerp(mouse_pos, t)
	var avoided_pos: Vector2 = _resolve_enemy_outline_overlap(desired_pos, delta)
	var ray_aligned_pos: Vector2 = _align_to_shot_ray(avoided_pos)
	global_position = avoided_pos.lerp(ray_aligned_pos, clampf(shot_alignment_strength, 0.0, 1.0))
	_update_hit_preview()


func _resolve_enemy_outline_overlap(target_pos: Vector2, delta: float) -> Vector2:
	var query_shape := CircleShape2D.new()
	query_shape.radius = maxf(_crosshair_radius, 0.1)

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.transform = Transform2D(0.0, target_pos)
	query.collision_mask = avoid_collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [self.get_rid()]

	var space_state := get_world_2d().direct_space_state
	var hits: Array = space_state.intersect_shape(query, 16)
	if hits.is_empty():
		return target_pos

	var hard_resolved: Vector2 = target_pos
	for hit in hits:
		var collider: CollisionObject2D = hit.get("collider") as CollisionObject2D
		if collider == null:
			continue

		var collider_center: Vector2 = collider.global_position
		var push_dir: Vector2 = hard_resolved - collider_center
		if push_dir.length_squared() <= 0.0001:
			push_dir = Vector2.RIGHT
		else:
			push_dir = push_dir.normalized()

		var approx_radius: float = _approx_collider_radius(collider)
		var min_dist: float = approx_radius + _crosshair_radius + outline_padding
		hard_resolved = collider_center + push_dir * min_dist

	# Softly move away from overlap instead of snapping to boundary to avoid "lock-on" feel.
	var push: Vector2 = (hard_resolved - target_pos) * clampf(avoidance_strength, 0.0, 1.0)
	var max_push_this_frame: float = max_avoid_push_speed * maxf(delta, 0.0)
	if max_push_this_frame > 0.0 and push.length() > max_push_this_frame:
		push = push.normalized() * max_push_this_frame

	return target_pos + push


func _approx_collider_radius(collider: CollisionObject2D) -> float:
	var max_radius: float = 16.0
	for i in range(collider.get_shape_owners().size()):
		var owner_id = collider.get_shape_owners()[i]
		if not collider.is_shape_owner_disabled(owner_id):
			var shape_count: int = collider.shape_owner_get_shape_count(owner_id)
			for j in range(shape_count):
				var shape: Shape2D = collider.shape_owner_get_shape(owner_id, j)
				if shape is CircleShape2D:
					max_radius = maxf(max_radius, (shape as CircleShape2D).radius)
				elif shape is RectangleShape2D:
					var half: Vector2 = (shape as RectangleShape2D).size * 0.5
					max_radius = maxf(max_radius, half.length())
				elif shape is CapsuleShape2D:
					var cap: CapsuleShape2D = shape as CapsuleShape2D
					max_radius = maxf(max_radius, cap.radius + cap.height * 0.5)
	return max_radius * maxf(collider.global_scale.length() * 0.5, 1.0)


func _align_to_shot_ray(point: Vector2) -> Vector2:
	var shooter: Node2D = get_parent() as Node2D
	if shooter == null:
		return point

	var muzzle: Marker2D = shooter.get_node_or_null("Node2D/Marker2D") as Marker2D
	var gun_node: Node2D = shooter.get_node_or_null("Node2D") as Node2D
	if muzzle == null or gun_node == null:
		return point

	var shot_dir: Vector2 = Vector2.RIGHT.rotated(gun_node.global_rotation)
	if shot_dir.length_squared() <= 0.0001:
		return point
	shot_dir = shot_dir.normalized()

	var projected_distance: float = maxf((point - muzzle.global_position).dot(shot_dir), 0.0)
	return muzzle.global_position + shot_dir * projected_distance


func _update_hit_preview() -> void:
	if not hit_preview_enabled or not crosshair_sprite:
		return

	var shooter: Node2D = get_parent() as Node2D
	if shooter == null:
		crosshair_sprite.modulate = COLOR_CLEAR
		return

	var muzzle: Marker2D = shooter.get_node_or_null("Node2D/Marker2D") as Marker2D
	if muzzle == null:
		crosshair_sprite.modulate = COLOR_CLEAR
		return
	var gun_node: Node2D = shooter.get_node_or_null("Node2D") as Node2D
	if gun_node == null:
		crosshair_sprite.modulate = COLOR_CLEAR
		return

	var shot_dir: Vector2 = Vector2.RIGHT.rotated(gun_node.global_rotation)
	if shot_dir.length_squared() <= 0.0001:
		crosshair_sprite.modulate = COLOR_CLEAR
		return

	var ray_end: Vector2 = muzzle.global_position + shot_dir.normalized() * hit_preview_distance
	var params := PhysicsRayQueryParameters2D.create(muzzle.global_position, ray_end)
	params.collision_mask = hit_preview_mask
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = [self.get_rid(), shooter.get_rid()]

	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(params)
	if result.is_empty():
		crosshair_sprite.modulate = COLOR_CLEAR
		return

	var collider: Object = result.get("collider")
	var is_hurtbox_hit: bool = collider is HurtBox
	crosshair_sprite.modulate = COLOR_HIT if is_hurtbox_hit else COLOR_CLEAR
