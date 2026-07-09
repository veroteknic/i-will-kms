extends Node
class_name BossShield

@export var shield_max_health: int = 5
@export var shield_regen_enabled: bool = true
@export var shield_regen_delay: float = 3.0
@export var shield_regen_rate: float = 1.0  # HP per second after delay

var shield_health: int
var time_since_damage: float = 0.0
var regen_progress: float = 0.0

signal shield_damaged(remaining: int)
signal shield_broken
signal shield_restored


func _ready() -> void:
	shield_health = shield_max_health


func _process(delta: float) -> void:
	if shield_regen_enabled and shield_health < shield_max_health:
		time_since_damage += delta
		if time_since_damage >= shield_regen_delay:
			regen_progress += shield_regen_rate * delta
			while regen_progress >= 1.0 and shield_health < shield_max_health:
				regen_progress -= 1.0
				shield_health += 1
				shield_damaged.emit(shield_health)
				if shield_health >= shield_max_health:
					shield_health = shield_max_health
					shield_restored.emit()
					regen_progress = 0.0


func take_damage(damage: int) -> bool:
	"""Apply damage to shield. Returns true if shield absorbed it all."""
	if shield_health <= 0:
		return false
	
	time_since_damage = 0.0
	regen_progress = 0.0
	shield_health -= damage
	
	if shield_health <= 0:
		shield_health = 0
		shield_broken.emit()
		return true
	
	shield_damaged.emit(shield_health)
	return true


func restore_shield() -> void:
	shield_health = shield_max_health
	time_since_damage = 0.0
	regen_progress = 0.0
	shield_restored.emit()


func is_active() -> bool:
	return shield_health > 0
