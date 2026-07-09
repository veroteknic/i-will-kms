extends Area2D
class_name BossProjectile

@export var speed: float = 300.0
@export var damage: int = 1
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0
var max_distance: float = 2000.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	set_as_top_level(true)
	area_entered.connect(_on_area_entered)
	
	# Fire and forget - disappear after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	global_position += movement
	traveled_distance += movement.length()
	
	# Destroy if traveled too far
	if traveled_distance > max_distance:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	# Hit player
	if area is HurtBox:
		var hurt_box := area as HurtBox
		if hurt_box.health and "health" in hurt_box.health:
			hurt_box.health.health -= damage
		queue_free()
	# Hit terrain/walls
	elif area.collision_layer & 1:  # Collision layer 1 is terrain
		queue_free()


func setup(spawn_pos: Vector2, target_pos: Vector2, dmg: int = 1) -> void:
	"""Configure projectile to fire toward target."""
	global_position = spawn_pos
	direction = (target_pos - spawn_pos).normalized()
	damage = dmg
	
	# Rotate to face direction
	rotation = direction.angle()
