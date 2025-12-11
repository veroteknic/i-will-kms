extends RigidBody2D

const EXPLOSION_DAMAGE = 3
const EXPLOSION_RADIUS = 150.0
const FUSE_TIME = 2.0

var exploded = false

func _ready() -> void:
	$BasicHitBox2D/CollisionShape2D.disabled = true
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(FUSE_TIME).timeout
	if not exploded:
		explode()


func explode() -> void:
	if exploded:
		return
	
	exploded = true
	print_debug("[GRENADE] Exploded at %s" % global_position)
	
	# Play explosion sound
	if has_node("AudioStreamPlayer2D"):
		$AudioStreamPlayer2D.play()
		$BasicHitBox2D/CollisionShape2D.disabled = false
		$CPUParticles2D.emitting = true
	# Remove grenade after explosion
	await get_tree().create_timer(0.5).timeout
	$Timer.start()
	



func _on_body_entered(body: Node) -> void:
	# Explode on contact with walls/ground (not player)
	if body != get_parent():
		explode()


func _on_timer_timeout() -> void:
		queue_free()
