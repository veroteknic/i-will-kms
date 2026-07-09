extends RigidBody2D

const EXPLOSION_DAMAGE = 3
const EXPLOSION_RADIUS = 150.0
const FUSE_TIME = 2.0

@export_range(0.0, 5000.0, 10.0, "suffix:px/s") var grenade_jump_force: float = 1850.0
@export_range(0.0, 1.0, 0.01) var grenade_jump_min_falloff: float = 0.2
@export_range(0.0, 1.0, 0.01) var grenade_jump_upward_bias: float = 0.35
@export_range(0, 10, 1) var grenade_jump_self_damage: int = 1

var exploded = false

@onready var explosion_collision_shape: CollisionShape2D = get_node_or_null("HitBox/CollisionShape2D")
@onready var explosion_audio: AudioStreamPlayer2D = get_node_or_null("AudioStreamPlayer2D")
@onready var explosion_particles: CPUParticles2D = get_node_or_null("CPUParticles2D")
@onready var grenade_sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	if explosion_collision_shape:
		explosion_collision_shape.disabled = true
	else:
		push_warning("[GRENADE] Missing 'HitBox/CollisionShape2D' - explosion hitbox is disabled.")

	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(FUSE_TIME).timeout
	if not exploded:
		explode()


func explode() -> void:
	if exploded:
		return
	
	exploded = true
	print_debug("[GRENADE] Exploded at %s" % global_position)
	_shake_player_cameras()
	_apply_grenade_jump_to_players()
	if grenade_sprite:
		grenade_sprite.visible = false
	for child in get_children():
		if child is Sprite2D:
			(child as Sprite2D).visible = false
	for child in get_children():
		if child is CollisionShape2D and child.get_parent() == self:
			(child as CollisionShape2D).disabled = true
	
	# Play explosion sound
	if explosion_audio:
		explosion_audio.play()

	if explosion_collision_shape:
		explosion_collision_shape.disabled = false

	if explosion_particles:
		explosion_particles.emitting = true

	await get_tree().create_timer(0.1).timeout
	if explosion_collision_shape:
		explosion_collision_shape.disabled = true

	if explosion_particles:
		await explosion_particles.finished
	else:
		await get_tree().create_timer(0.2).timeout

	if explosion_audio and explosion_audio.playing:
		await explosion_audio.finished

	queue_free()


func _shake_player_cameras() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if node and is_instance_valid(node) and node.has_method("add_screenshake_at_position"):
			node.add_screenshake_at_position(node.screenshake_grenade_amount, global_position, node.screenshake_grenade_radius)


func _apply_grenade_jump_to_players() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as CharacterBody2D
		if not player or not is_instance_valid(player):
			continue

		var to_player: Vector2 = player.global_position - global_position
		var distance: float = to_player.length()
		if distance > EXPLOSION_RADIUS:
			continue

		var direction: Vector2 = Vector2.UP if distance <= 0.001 else to_player.normalized()
		if direction.y > -grenade_jump_upward_bias:
			direction.y = -grenade_jump_upward_bias
		direction = direction.normalized()

		var raw_falloff: float = 1.0 - (distance / EXPLOSION_RADIUS)
		var falloff: float = clampf(raw_falloff, grenade_jump_min_falloff, 1.0)
		var launch_force: float = _get_grenade_jump_force_for_player(player)
		player.velocity += direction * launch_force * falloff

		_apply_grenade_jump_self_damage(player)


func _get_grenade_jump_force_for_player(player: CharacterBody2D) -> float:
	var script_resource: Script = player.get_script()
	if script_resource:
		var constants: Dictionary = script_resource.get_script_constant_map()
		if constants.has("JUMP_FORCE"):
			return absf(float(constants["JUMP_FORCE"])) * 2.0
	return grenade_jump_force


func _apply_grenade_jump_self_damage(player: Node) -> void:
	if grenade_jump_self_damage <= 0:
		return

	var health_node: Node = player.get_node_or_null("Health")
	if not health_node:
		return

	var had_immortality: bool = false
	var had_immortality_prop: bool = health_node.get("immortality") != null
	if had_immortality_prop:
		had_immortality = bool(health_node.get("immortality"))
		if had_immortality:
			health_node.set("immortality", false)

	var current_health_value = health_node.get("health")
	if current_health_value != null:
		health_node.set("health", int(current_health_value) - grenade_jump_self_damage)

	if had_immortality_prop and had_immortality:
		health_node.set("immortality", true)
	



func _on_body_entered(body: Node) -> void:
	# Explode on contact with walls/ground (not player)
	if body != get_parent():
		explode()


func _on_timer_timeout() -> void:
	if not exploded:
		queue_free()
