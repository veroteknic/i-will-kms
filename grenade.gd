extends RigidBody2D

const EXPLOSION_DAMAGE = 3
const EXPLOSION_RADIUS = 150.0
const FUSE_TIME = 2.0

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
	



func _on_body_entered(body: Node) -> void:
	# Explode on contact with walls/ground (not player)
	if body != get_parent():
		explode()


func _on_timer_timeout() -> void:
	if not exploded:
		queue_free()
